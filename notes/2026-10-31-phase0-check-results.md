# Phase 0 Check Results — 2026-10-31

Read-only checks. Nothing installed or changed.

## Kernel 6.8.0-147-generic config
| Option | Value | Meaning |
|---|---|---|
| CONFIG_BLK_DEV_NULL_BLK | m | null_blk available as a module |
| CONFIG_BLK_DEV_RAM | m | brd available as a module |
| CONFIG_BLK_DEV_UBLK | m | ublk driver available as a module |
| CONFIG_FUSE_FS | y | FUSE built in |
| CONFIG_FUSE_PASSTHROUGH | (absent) | Kernel FUSE passthrough NOT available (confirms review point A) |
| CONFIG_IO_URING | y | io_uring available |

## Machine
32 CPUs, Xeon E5-2630 v3, 2 NUMA nodes, 62 GiB RAM.

## Packages / tools
- Installed: fuse3 3.14.0, libfuse3-3 (runtime only), git, gcc, make, perf, python3.
- Missing: fio, bpftrace, libfuse3-dev, liburing-dev, ublk tooling.
- apt-cache returned no candidates because the apt package index is empty
  (/var/lib/apt/lists has no *_Packages files). Getting candidate versions needs
  `sudo apt update`, which changes system state, so it needs approval first.

### After `sudo apt update` (approved, run 2026-10-31; nothing installed)
| Package | Installed | Candidate |
|---|---|---|
| fio | none | 3.36-1ubuntu0.1 |
| libfuse3-dev | none | 3.14.0-5build1 (matches installed runtime) |
| liburing-dev | none | 2.5-1build1 |
| ublksrv | not in Ubuntu repos | build from source (or kublk from kernel selftests) |

## Response to external review (4 points)
A. Correct that CONFIG_FUSE_PASSTHROUGH is absent on 6.8. BUT the plan's F1 is libfuse's
   `passthrough_hp` example: a conventional userspace FUSE server that forwards each op to an
   underlying directory. It does not need the kernel passthrough feature (kernel passthrough
   is an optional mode of passthrough_hp on >=6.9). F1 stays valid on 6.8. Fix: rename F1 to
   "conventional FUSE (passthrough_hp, kernel passthrough off)" to avoid confusion.
B. Agreed. B0 = "null-device baseline (block-layer floor; data discarded)", not "fastest storage".
C. Agreed. B3 - B2 = ublk + loop-target backend (extra read/write into brd, copy).
   B1 - B0 (null target vs null_blk) is the cleaner estimate of ublk interface cost.
   Report both, with B3 - B2 described as "ublk loop stack cost".
D. Agreed, and stronger than the draft's "fio + pidstat on daemon": count system-wide CPU
   (all user + kernel time, incl. softirq and ublk/FUSE server threads), e.g. perf stat -a
   or per-CPU /proc/stat deltas over the run, divided by I/Os completed. Pin fio and the
   server to known CPUs so attribution per process stays possible.

## Adopted framing (from review)
1. What is the overhead? (latency, throughput, CPU per I/O)
2. Where does it come from? (context switches, request handling, copies, scheduling)
3. When does it matter? (small vs large I/O, low vs high concurrency, workloads)
