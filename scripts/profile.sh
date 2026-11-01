#!/usr/bin/env bash
# Phase 4: where does the time go? System-wide perf counters + call-graph profile
# for one workload on one setup. Run as root, after the fio matrix (not concurrently).
#
# Usage: scripts/profile.sh <setup-name> <target> [rw] [bs]
# Output: results/profile/<setup>/{fio.json, perf-stat.txt, perf-report-*.txt}
set -euo pipefail
setup="${1:?setup}"; target="${2:?target}"; rw="${3:-randread}"; bs="${4:-4k}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/results/profile/$setup-$rw-$bs"; mkdir -p "$out"
SECS="${SECS:-10}"

if [[ -b "$target" ]]; then where=(--filename="$target"); else where=(--directory="$target" --filename=fio.dat); fi
fio_cmd=(fio --name=prof "${where[@]}" --size="${SIZE:-2g}" --rw="$rw" --bs="$bs" --iodepth=1 --numjobs=1
         --ioengine=io_uring --direct=1 --time_based --runtime="$SECS" --cpus_allowed=0
         --randrepeat=0 --norandommap --lat_percentiles=1 --output-format=json)

# 1) counters, all CPUs, for exactly the fio run
perf stat -a -e cycles,instructions,context-switches,cpu-migrations,page-faults \
  -e 'syscalls:sys_enter_read,syscalls:sys_enter_writev,syscalls:sys_enter_io_uring_enter' \
  -o "$out/perf-stat.txt" -- "${fio_cmd[@]}" --output="$out/fio-stat.json"

# 2) call-graph sampling, all CPUs (pipefail off: head closing the pipe is not an error)
perf record -q -a -g -F 999 -o "$out/perf.data" -- "${fio_cmd[@]}" --output="$out/fio-record.json"
set +o pipefail
perf report -i "$out/perf.data" --no-children --sort comm --stdio 2>/dev/null | grep -v '^$' | head -40 > "$out/perf-report-comm.txt"
perf report -i "$out/perf.data" --no-children --sort sym --stdio -g none 2>/dev/null | grep -v '^#' | grep -v '^$' | head -50 > "$out/perf-report-sym.txt"
perf report -i "$out/perf.data" --no-children --sort comm,sym --stdio -g none 2>/dev/null | grep -v '^#' | grep -v '^$' | head -60 > "$out/perf-report-comm-sym.txt"
rm -f "$out/perf.data"   # large; text reports are kept
echo "[$setup] profile -> $out"
