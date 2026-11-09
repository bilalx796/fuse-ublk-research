#!/usr/bin/env bash
# Run 2, phase 5 (8 Nov 2026, extended reservation): close three loose ends from p1-p3.
# Run as root after run-2.sh p1..p4. Output: results/run2/p5/ (and raw/B2-brd-rerun/).
#
#   sudo scripts/run-2-p5.sh rerun    # B2 multi-job 128 KB reads, 5 fresh repeats   (~5 min)
#   sudo scripts/run-2-p5.sh wakeups  # who gets woken per write: B3 raw vs F2 ext4   (~3 min)
#   sudo scripts/run-2-p5.sh nocache  # FUSE --nocache read collapse: requests, depth (~3 min)
#
# wakeups and nocache need these kprobes (added once per boot):
#   perf probe -a fuse_do_getattr; perf probe -a fuse_direct_IO; perf probe -a fuse_simple_request
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
M="$root/scripts/run-matrix.sh"
HP="$root/third_party/libfuse/build/example/passthrough_hp"
SERVER_CPUS=8,10,12,14
out="$root/results/run2/p5"; mkdir -p "$out"
log() { echo "$(date +%T) $*"; }

# One short fio run, same settings as run-matrix.sh (CPU placement, io_uring, O_DIRECT).
fio_short() {  # <target-dir-or-dev> <rw> <qd> <secs> <json-out>
  local t="$1" rw="$2" qd="$3" secs="$4" o="$5" where
  if [[ -b "$t" ]]; then where=(--filename="$t"); else where=(--directory="$t" --filename=fio.dat); fi
  fio --name=p5 "${where[@]}" --size=4g --rw="$rw" --bs=4k --iodepth="$qd" --numjobs=1 \
      --ioengine=io_uring --direct=1 --time_based --runtime="$secs" \
      --cpus_allowed=0,2,4,6 --cpus_allowed_policy=split --randrepeat=0 --norandommap \
      --lat_percentiles=1 --output-format=json --output="$o"
}


mount_f1() {
  if grep -q ' /mnt/bench/f1 ' /proc/mounts; then umount /mnt/bench/f1; fi
  sleep 1; taskset -c "$SERVER_CPUS" "$HP" "$@" /mnt/bench/f0/data /mnt/bench/f1; sleep 1
  log "F1 mounted with: ${*:-defaults}"
}

case "${1:?rerun|wakeups|nocache}" in
rerun)
  log "rerun start"
  OUTROOT="$root/results/run2/raw" \
  CONFIGS="read-128k-qd1-j4:read:128k:1:4 read-128k-qd8-j4:read:128k:8:4" \
    "$M" B2-brd-rerun /dev/ram0 5
  log "rerun done" ;;

wakeups)
  log "wakeups start"
  grep -q ' /mnt/bench/f2 ' /proc/mounts && umount /mnt/bench/f2
  # B3 raw first: writing the raw device would corrupt a filesystem on it.
  perf record -q -a -e sched:sched_wakeup -o "$out/B3-randwrite.perf" -- \
    bash -c "$(declare -f fio_short); fio_short /dev/ublkb1 randwrite 1 3 $out/B3-randwrite.json"
  mkdir -p /mnt/bench/f2
  mkfs.ext4 -q -F -E lazy_itable_init=0,lazy_journal_init=0 /dev/ublkb1
  mount /dev/ublkb1 /mnt/bench/f2
  fio --name=prefill --directory=/mnt/bench/f2 --filename=fio.dat --size=4g --rw=write --bs=1m \
      --direct=1 --ioengine=io_uring --output=/dev/null
  for rw in randwrite randread; do
    perf record -q -a -e sched:sched_wakeup -o "$out/F2-$rw.perf" -- \
      bash -c "$(declare -f fio_short); fio_short /mnt/bench/f2 $rw 1 3 $out/F2-$rw.json"
  done
  umount /mnt/bench/f2
  for n in B3-randwrite F2-randwrite F2-randread; do
    # woken task names, with per-CPU / numeric suffixes folded (kworker/3:1H -> kworker/H)
    perf script -i "$out/$n.perf" -F trace 2>/dev/null \
      | sed -E 's/^comm=([^ ]+) .*/\1/; s#^(kworker)/[0-9]+:[0-9]+(H?)$#\1\2#; s/-?[0-9]+$//' \
      | sort | uniq -c | sort -rn | head -12 > "$out/$n.wakeups.txt"
    rm -f "$out/$n.perf"
  done
  log "wakeups done" ;;

nocache)
  log "nocache start"
  [[ -f /mnt/bench/f0/data/fio.dat ]] || \
    fio --name=prefill --directory=/mnt/bench/f0/data --filename=fio.dat --size=4g --rw=write \
        --bs=1m --direct=1 --ioengine=io_uring --output=/dev/null
  ev=probe:fuse_do_getattr,probe:fuse_direct_IO,probe:fuse_simple_request
  ev+=,io_uring:io_uring_queue_async_work,context-switches
  for opt in defaults nocache; do
    if [[ $opt == nocache ]]; then mount_f1 --nocache; else mount_f1; fi
    conn=$(ls -d /sys/fs/fuse/connections/*/ | tail -1)
    for wl in randread:8 randread:1 randwrite:8; do
      rw=${wl%:*}; qd=${wl#*:}; n="F1-$opt-$rw-qd$qd"
      # sample requests outstanding in the FUSE connection every 5 ms during the run
      ( while :; do cat "$conn/waiting"; sleep 0.005; done ) > "$out/$n.waiting" & s=$!
      perf stat -a -x, -e "$ev" -o "$out/$n.perfstat" -- \
        bash -c "$(declare -f fio_short); fio_short /mnt/bench/f1 $rw $qd 8 $out/$n.json"
      kill $s; wait $s 2>/dev/null || true
      log "$n done"
    done
  done
  mount_f1   # back to defaults
  log "nocache done" ;;
*) echo "unknown step $1" >&2; exit 2 ;;
esac
