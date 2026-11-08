#!/usr/bin/env bash
# Run 2 (8 Nov 2026). Same node type, kernel 6.8, RAM-backed devices only, same fio settings as
# run 1 (io_uring, direct, 20 s + 5 s ramp, CPU placement). Results go to results/run2/raw/.
# Assumes bringup.sh already ran (devices + F0/F1 mounts up). Run as root, one phase at a time:
#
#   sudo scripts/run-2.sh p1   # multi-job 128 KB + qd32 on B0-B3, F0, F1     (~60 min)
#   sudo scripts/run-2.sh p2   # FUSE settings: nocache, single, 4 threads, clone-fd  (~35 min)
#   sudo scripts/run-2.sh p3   # ext4-on-ublk writes: device write counts, no-journal  (~15 min)
#   sudo scripts/run-2.sh p4   # 5 more repeats on B1, B2 (standard 10 configs)       (~42 min)
#
# p3 runs mkfs on /dev/ublkb1, destroying B3's raw contents, so it must come after p1.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
M="$root/scripts/run-matrix.sh"
HP="$root/third_party/libfuse/build/example/passthrough_hp"
SERVER_CPUS=8,10,12,14
export OUTROOT="$root/results/run2/raw"
log() { echo "$(date +%T) $*"; }

# (Re)mount F1 = passthrough_hp over /mnt/bench/f0/data with the given extra options.
mount_f1() {
  if grep -q ' /mnt/bench/f1 ' /proc/mounts; then umount /mnt/bench/f1; fi
  sleep 1
  taskset -c "$SERVER_CPUS" "$HP" "$@" /mnt/bench/f0/data /mnt/bench/f1
  sleep 1
  log "F1 mounted with: ${*:-defaults} (pid $(pgrep -f "$HP" | tr '\n' ' '))"
}

mkdir -p "$OUTROOT"
case "${1:?phase p1|p2|p3|p4}" in
p1)
  export CONFIGS="read-128k-qd1-j4:read:128k:1:4 read-128k-qd8-j4:read:128k:8:4
    write-128k-qd1-j4:write:128k:1:4 write-128k-qd8-j4:write:128k:8:4
    randread-4k-qd32-j1:randread:4k:32:1 randwrite-4k-qd32-j1:randwrite:4k:32:1
    read-128k-qd32-j1:read:128k:32:1 write-128k-qd32-j1:write:128k:32:1"
  log "p1 start"
  "$M" B0-null_blk         /dev/nullb0
  "$M" B1-ublk-null        /dev/ublkb0
  "$M" B2-brd              /dev/ram0
  "$M" B3-ublk-loop-brd    /dev/ublkb1
  "$M" F0-ext4-brd         /mnt/bench/f0
  rm -f /mnt/bench/f0/fio.dat          # free ram1 for F1's file
  "$M" F1-fuse-hp-ext4-brd /mnt/bench/f1   # default options, as bring-up mounted it
  log "p1 done" ;;
p2)
  export CONFIGS="randread-4k-qd1-j1:randread:4k:1:1 randread-4k-qd8-j1:randread:4k:8:1
    randwrite-4k-qd1-j1:randwrite:4k:1:1 randwrite-4k-qd8-j1:randwrite:4k:8:1
    read-128k-qd1-j1:read:128k:1:1 read-128k-qd8-j1:read:128k:8:1"
  log "p2 start"
  [[ -f /mnt/bench/f0/data/fio.dat ]] && export SKIP_PREFILL=1
  mount_f1 --nocache;          "$M" F1c-fuse-hp-nocache    /mnt/bench/f1; export SKIP_PREFILL=1
  mount_f1 --single;           "$M" F1s-fuse-hp-single     /mnt/bench/f1
  mount_f1 --num-threads 4;    "$M" F1t4-fuse-hp-4threads  /mnt/bench/f1
  mount_f1 --clone-fd;         "$M" F1cf-fuse-hp-clonefd   /mnt/bench/f1
  mount_f1                     # back to defaults
  log "p2 done" ;;
p3)
  export CONFIGS="randwrite-4k-qd1-j1:randwrite:4k:1:1 randwrite-4k-qd8-j1:randwrite:4k:8:1
    randwrite-4k-qd1-j4:randwrite:4k:1:4 write-128k-qd1-j1:write:128k:1:1
    write-128k-qd8-j1:write:128k:8:1"
  log "p3 start"
  mkdir -p /mnt/bench/f2
  if grep -q ' /mnt/bench/f2 ' /proc/mounts; then umount /mnt/bench/f2; fi
  # Same F2 as run 1, but record ublkb1's own write counters (journal + metadata traffic).
  mkfs.ext4 -q -F -E lazy_itable_init=0,lazy_journal_init=0 /dev/ublkb1
  mount /dev/ublkb1 /mnt/bench/f2
  BLKSTAT_DEV=ublkb1 "$M" F2-ext4-ublk-loop-brd /mnt/bench/f2
  umount /mnt/bench/f2
  # No journal: if the gap to B3 closes, the journal's extra ublk round trips explain it.
  mkfs.ext4 -q -F -O ^has_journal -E lazy_itable_init=0 /dev/ublkb1
  mount /dev/ublkb1 /mnt/bench/f2
  BLKSTAT_DEV=ublkb1 "$M" F2nj-ext4-nojournal-ublk-loop-brd /mnt/bench/f2
  umount /mnt/bench/f2
  # Control: F0 (ext4 on brd, journal on) with the same device counters on ram1.
  # Free ram1 first: drop F1's 4 GiB file and remount F1 so the daemon lets go of it.
  rm -f /mnt/bench/f0/data/fio.dat /mnt/bench/f0/fio.dat
  mount_f1
  BLKSTAT_DEV=ram1 "$M" F0-ext4-brd /mnt/bench/f0
  rm -f /mnt/bench/f0/fio.dat
  log "p3 done" ;;
p4)
  unset CONFIGS
  log "p4 start"
  "$M" B1-ublk-null /dev/ublkb0 5
  "$M" B2-brd       /dev/ram0   5
  log "p4 done" ;;
*) echo "unknown phase $1" >&2; exit 2 ;;
esac
