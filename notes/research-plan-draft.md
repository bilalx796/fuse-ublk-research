# Research Plan (DRAFT — proposal, not yet confirmed with Omid)

## Core idea: subtraction across matched stacks
Measure stacks that differ by exactly ONE layer; the difference in latency/CPU is that layer's cost.
Use RAM-backed / null devices so the userspace interface — not the disk — dominates.
No real disks (sdb/sdc) are touched in Phases 0–5.

## Stacks
Block level (fio on a block device, direct=1):
- B0  null_blk                      (kernel null device: pure block-layer floor)
- B1  ublk null target              (B1 - B0 = ublk interface cost)
- B2  brd RAM disk                  (kernel RAM disk)
- B3  ublk loop target -> brd       (B3 - B2 = ublk cost incl. data copy)

Filesystem level (fio on files):
- F0  ext4 on brd                   (baseline)
- F1  FUSE passthrough_hp -> F0     (F1 - F0 = FUSE cost)
- F2  ext4 on ublk loop -> brd      (F2 - F0 = ublk cost under a filesystem)
- F3  FUSE -> ext4 on ublk          (optional: combined stack)
- Fn  FUSE null fs vs B1            (optional: interface-only comparison)

NOTE: B-stacks are "raw device" fio, but on virtual RAM/null devices holding no data.
Needs explicit approval as an exception to the "no raw-device fio" rule.

## Phases
0. Reproducibility: git repo, env capture script (kernel, mitigations, governor, NUMA, versions).
1. Bring-up: load modules, build/install tools, smoke-test each stack (no numbers).
2. fio microbenchmarks (io_uring, direct=1, 60 s + 10 s ramp, 3–5 reps):
   rw: randread, randwrite, read, write | bs: 4k, 128k
   sweep A: numjobs=1, iodepth 1/4/8 | sweep B: iodepth=1, numjobs 1/4/8
   metrics: IOPS, BW, p50/p95/p99/p99.9 clat, CPU per I/O (fio + pidstat on daemon)
   + small buffered-I/O subset to show page-cache effects.
3. Server-side knob sensitivity: FUSE threads, max_pages, cache modes;
   ublk nr_queues, queue_depth, max I/O size.
4. Explanation ("get to the bottom"): perf stat (context switches, syscalls, cycles/IO),
   perf record flame graphs, bpftrace per-layer latency.
5. RocksDB db_bench on F0/F1/F2: fillrandom (Put), readrandom (Get), value 4K/128K,
   threads 1/4/8, direct I/O on, block cache fixed; record compaction stats.
6. Optional extensions (need discussion): HDD "slow media" run; newer kernel to study
   FUSE passthrough, FUSE-over-io_uring, ublk zero-copy vs 6.8.

## Hypotheses (to TEST, not conclusions)
H1 Per-request overhead matters most at 4 KB, qd=1; gap shrinks at 128 KB as copy cost dominates.
H2 ublk's batched io_uring path scales better with queue depth than FUSE's /dev/fuse path on 6.8.
H3 Interface overhead appears as CPU per I/O before it appears as throughput loss.
H4 Tail latency (p99+) is more sensitive to daemon thread/CPU placement than the median.

## Repo layout
env/  scripts/  configs/fio/  results/raw/ (fio JSON)  analysis/ (Python)  notes/
