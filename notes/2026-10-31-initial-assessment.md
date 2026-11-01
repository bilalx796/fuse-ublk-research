# Initial Assessment — 2026-10-31

Status: planning only. No system changes, no benchmarks run.

## Understanding

| | FUSE | ublk |
|---|---|---|
| What it intercepts | Filesystem calls (open, read, write, lookup…) on files | Block requests (read/write N sectors at offset X) |
| What the kernel shows the app | A mounted directory | A block device (/dev/ublkbN) |
| Kernel <-> userspace channel on 6.8 | Daemon reads requests from /dev/fuse, writes replies back (ordinary syscalls) | io_uring commands (fetch / commit-and-fetch): one syscall returns a finished request and picks up the next |
| Page cache position | Above FUSE (if the daemon allows caching) | Above ublk (in whatever filesystem sits on top) |

FUSE vs ublk is not a direct comparison: ublk has no files until a filesystem goes on top;
FUSE usually stores data in another filesystem/device underneath. Every comparison must name the full stack.

## Open technical questions
1. Which stacks to compare (baseline ext4, FUSE passthrough, ext4-on-ublk, null targets, combined).
2. Backing storage: a 7200 RPM HDD (ms per random I/O) would hide µs-scale interface overhead.
   Use RAM/null backends to isolate the interface; HDD only for a "slow media" experiment.
3. Kernel 6.8 predates (VERIFY in changelogs): FUSE passthrough (~6.9), FUSE-over-io_uring (~6.14),
   ublk zero-copy (~6.15).
4. Userspace software: ublksrv vs kublk (kernel selftests) vs rublk; libfuse version (distro may lag, no examples packaged).
5. Meaning of "put/get" (RocksDB db_bench assumed, unconfirmed).
6. Depth of analysis: end-to-end only, or per-layer breakdown (bpftrace/perf/blktrace)?

## Methodology weaknesses
- Backend can hide the effect (biggest risk).
- Page cache (62 GiB RAM): fix O_DIRECT vs buffered policy, FUSE cache modes, drop caches, working set > RAM when buffered.
- fio iodepth is meaningless with psync; need io_uring/libaio + direct=1.
- Server-side knobs missing: FUSE threads, max_pages; ublk queues, queue depth, max I/O size (128 KB splitting).
- Sequential vs random missing.
- CPU cost per I/O not measured.
- NUMA/noise: pinning, governor/turbo, warm-up, repetitions with spread, record mitigations.
- RocksDB confounds: WAL, memtable flush, compaction, block cache, direct-I/O options; 128 KB values unusual (maybe BlobDB).
- Cross-layer attribution: each stack needs its own matching baseline.
