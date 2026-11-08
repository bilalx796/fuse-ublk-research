#!/usr/bin/env bash
# Run the reduced fio matrix against one setup and record system-wide CPU.
#
# Usage: scripts/run-matrix.sh <setup-name> <target> [reps]
#   env: SKIP_PREFILL=1 (file already laid out), ONLY=<regex> (subset of configs),
#        OUTROOT=<dir> (default results/raw), CONFIGS="<name:rw:bs:qd:jobs> ..." (replace list),
#        REP_START=<n> (first repeat number, default 1), BLKSTAT_DEV=<dev> (also record that
#        block device's /sys/block/<dev>/stat delta per run, e.g. to count journal writes)
#   <target> is a block device (/dev/...) or a directory (a file is created in it).
#
# Output: results/raw/<setup>/<config>-r<rep>.json  (fio JSON)
#         results/raw/<setup>/<config>-r<rep>.cpu   (system-wide /proc/stat deltas)
#         results/raw/<setup>/env.txt
#
# CPU accounting (review point D): we diff /proc/stat across each run, so the
# numbers include fio, the FUSE/ublk server, kernel time, irq and softirq on ALL
# CPUs, not just fio's own CPU time.
set -euo pipefail

setup="${1:?setup name}"; target="${2:?target device or directory}"; reps="${3:-3}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${OUTROOT:-$root/results/raw}/$setup"; mkdir -p "$out"

RUNTIME="${RUNTIME:-20}"; RAMP="${RAMP:-5}"; SIZE="${SIZE:-4g}"
FIO_CPUS="${FIO_CPUS:-0,2,4,6}"   # NUMA node 0, distinct physical cores

if [[ -b "$target" ]]; then
  where=(--filename="$target")
else
  where=(--directory="$target" --filename=fio.dat)
fi

# config name : rw : bs : iodepth : numjobs
configs=(
  "randread-4k-qd1-j1:randread:4k:1:1"
  "randread-4k-qd8-j1:randread:4k:8:1"
  "randread-4k-qd1-j4:randread:4k:1:4"
  "randwrite-4k-qd1-j1:randwrite:4k:1:1"
  "randwrite-4k-qd8-j1:randwrite:4k:8:1"
  "randwrite-4k-qd1-j4:randwrite:4k:1:4"
  "read-128k-qd1-j1:read:128k:1:1"
  "read-128k-qd8-j1:read:128k:8:1"
  "write-128k-qd1-j1:write:128k:1:1"
  "write-128k-qd8-j1:write:128k:8:1"
)
[[ -n "${CONFIGS:-}" ]] && read -ra configs <<<"${CONFIGS//$'\n'/ }"

"$root/scripts/capture-env.sh" "$out" >/dev/null

# Lay out the file once for file-based setups so reads hit real data.
if [[ ! -b "$target" && -z "${SKIP_PREFILL:-}" ]]; then
  fio --name=prefill "${where[@]}" --size="$SIZE" --rw=write --bs=1m \
      --direct=1 --ioengine=io_uring --output=/dev/null
fi

cpu_snapshot() {  # prints: busy_jiffies total_jiffies ctxt
  awk '/^cpu /{b=$2+$3+$4+$7+$8+$9; t=b+$5+$6} /^ctxt/{c=$2} END{print b, t, c}' /proc/stat
}

for rep in $(seq "${REP_START:-1}" $(( ${REP_START:-1} + reps - 1 ))); do
  for c in "${configs[@]}"; do
    IFS=: read -r name rw bs qd nj <<<"$c"
    [[ -n "${ONLY:-}" && ! "$name" =~ $ONLY ]] && continue   # optional config filter (regex)
    tag="$name-r$rep"
    [[ -n "${BLKSTAT_DEV:-}" ]] && cp "/sys/block/$BLKSTAT_DEV/stat" "$out/$tag.blk0"
    read -r b0 t0 c0 < <(cpu_snapshot)
    fio --name="$name" "${where[@]}" --size="$SIZE" \
        --rw="$rw" --bs="$bs" --iodepth="$qd" --numjobs="$nj" \
        --ioengine=io_uring --direct=1 --time_based \
        --runtime="$RUNTIME" --ramp_time="$RAMP" \
        --cpus_allowed="$FIO_CPUS" --cpus_allowed_policy=split \
        --group_reporting --randrepeat=0 --norandommap \
        --percentile_list=50:95:99:99.9 --lat_percentiles=1 \
        --output-format=json --output="$out/$tag.json"
    read -r b1 t1 c1 < <(cpu_snapshot)
    # ramp time is included in these deltas; analysis scales by wall time.
    printf 'busy_jiffies=%d total_jiffies=%d ctxt=%d hz=%d wall_s=%d\n' \
      $((b1-b0)) $((t1-t0)) $((c1-c0)) "$(getconf CLK_TCK)" $((RUNTIME+RAMP)) \
      >"$out/$tag.cpu"
    [[ -n "${BLKSTAT_DEV:-}" ]] && cp "/sys/block/$BLKSTAT_DEV/stat" "$out/$tag.blk1"
    echo "[$setup] $tag done"
  done
done
