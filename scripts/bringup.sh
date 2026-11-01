#!/usr/bin/env bash
# Rebuild the run-1 environment on a fresh node (tested on Emulab d430, Ubuntu 24.04, kernel 6.8).
# Needs sudo. Does NOT touch real disks: only null_blk, brd RAM disks and ublk virtual devices.
#
#   scripts/bringup.sh          # packages, builds, governor, modules, devices, mounts
#
# Afterwards: sudo scripts/run-all.sh > results/run-all.log 2>&1
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tp="$root/third_party"
SERVER_CPUS=8,10,12,14

echo "== packages"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  fio libfuse3-dev liburing-dev autoconf automake libtool pkg-config meson ninja-build numactl

echo "== builds"
mkdir -p "$tp"
if [[ ! -x "$tp/libfuse/build/example/passthrough_hp" ]]; then
  git clone -q --depth 1 --branch fuse-3.14.0 https://github.com/libfuse/libfuse.git "$tp/libfuse"
  (cd "$tp/libfuse" && meson setup build >/dev/null && ninja -C build >/dev/null)
fi
if [[ ! -x "$tp/ublksrv/ublk" ]]; then
  git clone -q https://github.com/ublk-org/ublksrv.git "$tp/ublksrv"
  # run 1 used ublksrv commit 6d0d922; pin it for comparability
  git -C "$tp/ublksrv" checkout -q 6d0d922
  (cd "$tp/ublksrv" && autoreconf -i >/dev/null 2>&1 && ./configure >/dev/null && make -j"$(nproc)" >/dev/null)
fi

echo "== governor"
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null

echo "== modules + devices"
sudo modprobe null_blk nr_devices=1 gb=8 bs=4096 queue_mode=2 irqmode=0 hw_queue_depth=128 submit_queues=8
sudo modprobe brd rd_nr=2 rd_size=8388608
sudo modprobe ublk_drv
U="$tp/ublksrv/ublk"
sudo "$U" add -t null -n 0 -q 4 -d 128 >/dev/null
sudo "$U" add -t loop -n 1 -q 4 -d 128 -f /dev/ram0 >/dev/null
sleep 1
"$root/scripts/pin-server.sh" "$SERVER_CPUS" ublk.null ublk.loop >/dev/null

echo "== filesystems"
sudo mkdir -p /mnt/bench/f0 /mnt/bench/f1 /mnt/bench/f2
sudo mkfs.ext4 -q -F -E lazy_itable_init=0,lazy_journal_init=0 /dev/ram1
sudo mount /dev/ram1 /mnt/bench/f0
sudo mkdir -p /mnt/bench/f0/data
sudo taskset -c "$SERVER_CPUS" "$tp/libfuse/build/example/passthrough_hp" /mnt/bench/f0/data /mnt/bench/f1
sleep 1

lsblk -o NAME,SIZE /dev/nullb0 /dev/ublkb0 /dev/ram0 /dev/ublkb1 /dev/ram1
grep /mnt/bench /proc/mounts
echo "bring-up complete"
