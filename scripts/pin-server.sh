#!/usr/bin/env bash
# Pin every thread of the given process names to the server CPU set, round-robin.
# ublksrv queue threads set their own affinity from the blk-mq map (which can land on
# fio's CPUs or NUMA node 1), so we override it after the device is created.
# Usage: scripts/pin-server.sh "<cpu list>" <process-name>...
set -eu
read -ra cpus <<<"${1//,/ }"; shift
i=0
for name in "$@"; do
  for p in $(pgrep -x "$name"); do
    for t in /proc/$p/task/*; do
      tid=$(basename "$t")
      sudo -n taskset -pc "${cpus[$((i % ${#cpus[@]}))]}" "$tid" >/dev/null
      printf '%s tid %s -> cpu %s\n' "$name" "$tid" "${cpus[$((i % ${#cpus[@]}))]}"
      i=$((i+1))
    done
  done
done
