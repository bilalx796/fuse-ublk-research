#!/usr/bin/env bash
# Record the machine/software state alongside each benchmark run.
# Usage: scripts/capture-env.sh <output-dir>
# Read-only: it only reads system state, never changes it.
set -u
out="${1:?usage: capture-env.sh <output-dir>}"
mkdir -p "$out"
f="$out/env.txt"

section() { printf '\n## %s\n' "$1" >>"$f"; }
run() { printf '$ %s\n' "$*" >>"$f"; "$@" >>"$f" 2>&1 || printf '(exit %d)\n' $? >>"$f"; }

: >"$f"
printf '# Environment capture %s\n' "$(date -Is)" >>"$f"

section host;        run hostname -f; run uname -a; run cat /proc/cmdline
section cpu;         run lscpu
section numa;        run numactl --hardware
section memory;      run free -m
section mitigations; run grep -r . /sys/devices/system/cpu/vulnerabilities/
section frequency
run sh -c 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort | uniq -c'
run sh -c 'cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo "no intel_pstate"'
run sh -c 'cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true'
section smt;         run cat /sys/devices/system/cpu/smt/control
section kernel-config
run sh -c "grep -E 'CONFIG_(BLK_DEV_(NULL_BLK|RAM|UBLK)|FUSE_(FS|PASSTHROUGH)|IO_URING)=' /boot/config-\$(uname -r)"
section modules;     run sh -c "lsmod | grep -E '^(null_blk|brd|ublk_drv|fuse) ' || true"
section block-devices; run lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,SCHED
section mounts;      run sh -c "grep -E 'fuse|/mnt/bench' /proc/mounts || true"
section versions
run fio --version
run sh -c 'pkg-config --modversion fuse3 liburing'
run sh -c 'ublk --version 2>/dev/null || echo "ublk: not installed"'
run perf --version
run gcc --version
section repo
run git -C "$(dirname "$0")/.." rev-parse HEAD
run git -C "$(dirname "$0")/.." status --short

echo "wrote $f"
