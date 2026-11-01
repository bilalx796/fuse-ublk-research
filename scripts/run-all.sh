#!/usr/bin/env bash
# Run the matrix over every setup, in order. Assumes bring-up already done:
#   null_blk (nullb0), brd (ram0, ram1), ublk null = ublkb0, ublk loop on ram0 = ublkb1,
#   F0 = ext4 on ram1 at /mnt/bench/f0, F1 = passthrough_hp(/mnt/bench/f0/data) at /mnt/bench/f1.
# F2 (ext4 on ublkb1) is created here, after B3, because mkfs destroys B3's raw data.
# Run as root.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
M="$root/scripts/run-matrix.sh"
log() { echo "$(date +%T) $*"; }

log start
"$M" B0-null_blk          /dev/nullb0
"$M" B1-ublk-null         /dev/ublkb0
"$M" B2-brd               /dev/ram0
"$M" B3-ublk-loop-brd     /dev/ublkb1
"$M" F0-ext4-brd          /mnt/bench/f0
"$M" F1-fuse-hp-ext4-brd  /mnt/bench/f1

mkfs.ext4 -q -F -E lazy_itable_init=0,lazy_journal_init=0 /dev/ublkb1
mkdir -p /mnt/bench/f2 && mount /dev/ublkb1 /mnt/bench/f2
"$M" F2-ext4-ublk-loop-brd /mnt/bench/f2
log done
