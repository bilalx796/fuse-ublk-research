#!/usr/bin/env bash
# Resume run 1 after F1's prefill hit ENOSPC (F0's 4 GiB file was still on the 8 GiB ram1).
# Runs F1 and F2 with the same parameters as run-all.sh. Run as root.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
M="$root/scripts/run-matrix.sh"
echo "$(date +%T) resume"
"$M" F1-fuse-hp-ext4-brd /mnt/bench/f1
rm -f /mnt/bench/f1/fio.dat
mkfs.ext4 -q -F -E lazy_itable_init=0,lazy_journal_init=0 /dev/ublkb1
mkdir -p /mnt/bench/f2 && mount /dev/ublkb1 /mnt/bench/f2
"$M" F2-ext4-ublk-loop-brd /mnt/bench/f2
echo "$(date +%T) done"
