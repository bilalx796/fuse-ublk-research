# Recommended Research Plan — 2026-10-31

Everything below is a PROPOSAL, not something already done or decided.
Nothing on the system has changed.

## Core idea: compare setups that differ by one layer
A storage setup is a chain of layers: app -> filesystem -> device -> storage. Build pairs of
setups that differ in just one layer. The difference in latency and CPU between them is that
layer's cost.

Store the data in RAM, or on "null" devices that discard it. A 7200 RPM HDD takes
milliseconds per random I/O and would hide costs that are probably microseconds. This also
means we never touch sdb/sdc.

### Block level (fio talks directly to a device)

| Setup | What it is | What the comparison tells us |
|---|---|---|
| B0 | null_blk: kernel device that discards data | Fastest possible block path |
| B1 | ublk null target | B1 - B0 = cost of going through ublk |
| B2 | brd: kernel RAM disk | RAM-backed baseline |
| B3 | ublk loop target, storing its data in brd | B3 - B2 = ublk cost including copying the data |

### Filesystem level (fio reads and writes files)

| Setup | What it is | What the comparison tells us |
|---|---|---|
| F0 | ext4 on brd | Baseline |
| F1 | FUSE passthrough filesystem in front of F0 | F1 - F0 = FUSE cost |
| F2 | ext4 on a ublk device backed by brd | F2 - F0 = ublk cost under a real filesystem |
| F3 (optional) | FUSE on top of ext4 on ublk | Both combined |

WARNING: The B setups are "raw-device fio", which our rules forbid. Here the devices are
virtual, RAM- or null-backed, and hold no real data. Treat that as an exception only if
explicitly approved.

## Phases
0. Reproducibility first: a git repo, plus a script that records kernel version, CPU security
   mitigations, CPU frequency governor, NUMA layout and tool versions with every run.
1. Bring-up: load the modules, install or build the tools, and check each setup works.
   No measurements yet.
2. fio measurements:
   - Settings: io_uring engine, direct=1, 60 s runs after 10 s warm-up, 3-5 repeats each
   - Workloads: random and sequential reads and writes, at 4 KB and 128 KB
   - Queue-depth sweep: depth 1/4/8 with one job
   - Job-count sweep: 1/4/8 jobs at depth 1
   - Measured: IOPS, bandwidth, p50/p95/p99/p99.9 latency, and CPU per I/O
   - Also a few buffered (page-cache) runs, to show how much caching changes the picture
3. Server-side settings:
   - FUSE: daemon threads, max_pages, caching modes
   - ublk: number of queues, queue depth, maximum I/O size
4. Explain WHY (Omid's "get to the bottom"):
   - perf stat for context switches, syscalls and cycles per I/O
   - Flame graphs to see where CPU time goes
   - bpftrace to time each layer
5. RocksDB (db_bench) on F0/F1/F2:
   - Put (fillrandom) and Get (readrandom), 4 KB and 128 KB values, 1/4/8 threads
   - Direct I/O on and a fixed block-cache size
   - Record compaction stats
6. Optional extensions:
   - An HDD run showing whether interface cost still matters on slow storage
     (needs disk approval)
   - A newer kernel, to compare 6.8 against FUSE passthrough, FUSE over io_uring and
     ublk zero-copy. Could give the strongest result, but means a kernel change,
     so discuss first.

## Hypotheses to test (no conclusions yet)
- H1: The per-request overhead matters most for 4 KB I/O at queue depth 1. The gap shrinks
  at 128 KB, because copying the data takes over.
- H2: ublk scales better with queue depth than FUSE on 6.8, because its io_uring path
  batches requests.
- H3: Interface overhead shows up in CPU per I/O before it shows up as lost throughput.
- H4: Tail latency (p99) depends more on where the daemon threads run than the median does.

## Time estimate
Phase 2 is about 40 configurations per setup x 3 repeats x 70 s, roughly 2.5 hours per
setup. About 15-20 hours for all setups, fully automated, so overnight runs work.

## Next step (read-only)
Checks whether the kernel has the null and RAM disk drivers we'd need, and which tool
versions Ubuntu offers. apt-cache policy only looks things up and installs nothing.

    grep -E 'CONFIG_BLK_DEV_(NULL_BLK|RAM)=' /boot/config-$(uname -r); \
    apt-cache policy fio fuse3 libfuse3-dev liburing-dev ublksrv | grep -E '^\S|Installed|Candidate'

Expected: =m or =y for each driver. For each package, an "Installed:" version (or "(none)")
and a "Candidate:" version. ublksrv may not exist in Ubuntu's package list at all; if so,
build it from source.
