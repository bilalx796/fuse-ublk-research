# Run 2 Findings — 2026-11-08

Same node type (Emulab d430), kernel 6.8, RAM-backed devices only, same fio settings as run 1
(io_uring, O_DIRECT, 20 s + 5 s ramp, 3 repeats unless noted, same CPU placement). New node and boot.
Runner: `scripts/run-2.sh p1..p4`. Raw data: `results/run2/raw/`. Tables: `results/run2/summary.md`.
Decisions for this run (from the user): put/get = RocksDB db_bench, later session; RAM disks only;
stay on 6.8.

## Phase 1: multi-job 128 KB and queue depth 32

**The run-1 anomaly (FUSE beating ext4 at 128 KB qd8) is a single-submitter artifact. Settled.**

| 128 KB, IOPS | F0 ext4 | F1 FUSE | F1/F0 | CPU µs/IO F0 → F1 |
|---|---:|---:|---:|---:|
| read qd1 j4 | 144k | 48k | 0.33 | 28 → 89 |
| read qd8 j4 | 139k | 68k | 0.49 | 29 → 68 |
| write qd1 j4 | 107k | 37k | 0.35 | 38 → 110 |
| write qd8 j4 | 105k | 60k | 0.57 | 39 → 84 |
| read qd32 j1 | 37k | 71k | 1.91 | 28 → 63 |

With 4 submitting jobs ext4 scales (copies run on 4 fio CPUs) and FUSE falls to 1/3–1/2 of it.
With one job, ext4 stays at one CPU's copy rate (~37k) at any depth, which is what FUSE "beat".
FUSE's p99 at 128 KB with depth (qd8 j4, qd32) is ~3.5 ms vs ~0.25–0.9 ms for ext4.

**ublk does not scale with submitters at 128 KB.** B1 (null) 59k vs B0 235k at qd1 j4; B3 (loop) 25k
vs B2 148k. The 4 ublk queue threads sit on 4 server CPUs and copy every byte (no zero-copy on 6.8),
so the server CPUs cap throughput. (B2's own multi-job 128 KB numbers are noisy: spread 124–136%.)

**qd32, 4 KB: latency hidden, CPU not.** IOPS within ~10–25% of baseline for all, but CPU per I/O:

| 4 KB randread qd32 | B0 | B1 ublk | B2 | B3 ublk loop | F0 | F1 FUSE |
|---|---:|---:|---:|---:|---:|---:|
| IOPS | 457k | 426k | 388k | 333k | 333k | 348k |
| CPU µs / I/O | 2.3 | 4.7 | 2.7 | 5.6 | 3.1 | 14.0 |

Same picture as run 1 at qd8 (H3: the overhead shows up as CPU before throughput), now at qd32.
FUSE stays ~4.5x ext4's CPU per I/O; ublk ~2x its kernel baseline.

## Phase 2: FUSE (passthrough_hp) options, 4 KB and 128 KB, one job

Compared against run-1 F1 defaults (different boot; treat small differences with care).

| | 4 KB randread qd1 p50 / CPU | 4 KB randread qd8 IOPS | 128 KB read qd8 IOPS |
|---|---:|---:|---:|
| defaults (run 1) | 38.1 µs / 47.7 | 319k | 71k |
| `--single` | **26.5 µs / 30.0** | 113k | 20k |
| `--num-threads 4` | 39.2 µs / 42.7 (p99 108 → 48 µs) | 245k | 70k |
| `--clone-fd` | 41.7 µs / 54.0 | 312k | 71k |
| `--nocache` | 72.2 µs / 82.9 | **29k** | 43k |

- **Single-threaded is ~30% faster per request and uses ~37% less CPU at qd1**, but caps at
  ~110k IOPS (one thread serves everything). The default thread pool trades per-request latency
  for parallelism. Likely the pool's thread handoff/wakeups; not profiled yet.
- **Matching threads to server CPUs (4) tightens the tail a lot** (qd1 p99 108 → 48 µs) at a
  ~20% IOPS cost at qd8.
- `--clone-fd`: no measurable effect here.
- **`--nocache` collapses reads at depth** (qd8 read 319k → 29k, p50 277 µs) while writes are fine
  (291k). Not explained yet. Candidate: with caching disabled, reads lose parallelism somewhere in the
  FUSE read path (e.g. serialized per file); needs a look at the request stream (`--debug-fuse` count
  of in-flight READs) next time.

## Phase 3: why ext4-on-ublk (F2) writes are slow

**Not the journal.** Device-level write counts on ublkb1 (`/sys/block/ublkb1/stat`) equal fio's
writes (ratio 0.96–1.00): overwrites of an already-allocated file generate no journal or metadata
I/O. A no-journal ext4 (`-O ^has_journal`, F2nj) gives identical results:

| 4 KB randwrite | B3 raw ublk loop | F2 ext4 on it | F2nj no journal | F0 ext4 on brd |
|---|---:|---:|---:|---:|
| qd1 IOPS / p50 | 60k / 16.2 µs | 40k / 24.2 µs | 41k / 23.4 µs | 293k / 3.1 µs |
| qd8 IOPS | 277k | 137k | 137k | 290k |
| context switches / I/O (qd1) | 3.9 | **4.9** | **4.8** | 0.0 |

F2 reproduces run 1 (41k → 40k, 141k → 137k), so it is stable. The new clue is **one extra context
switch per write** (3.9 → 4.9) with no extra device I/O; reads through the same stack showed no such
extra switch in run 1 (F2 ≈ B3). **Hypothesis:** ext4's direct-write completion is deferred to a
kernel worker thread (iomap DIO write completions run from a workqueue unless they can complete inline),
adding a wakeup per write when the device completes asynchronously, as ublk does; brd completes inline,
so F0 does not pay it. **Verify next time** with `perf record -e sched:sched_switch` / `perf trace` on
F2 randwrite qd1 and look for `dio/` or `kworker` wakeups per I/O.

Control note: the F0 device counters read zero because brd does not account I/O in
`/sys/block/ram1/stat`; the F0 performance numbers themselves are fine.

## Phase 4: more repeats on B1 and B2 (5 x 20 s, new boot)

Run-1 noise is gone: B2 spread 29–43% → 0.5–10.6%; B1 7–30% → 1.5–9.6% (4 KB qd1 write 20.7% → 1.5%).
Medians reproduce run 1 within ~5% on a different node and boot for nearly every cell
(e.g. B1 4 KB randread qd1 80.0k → 78.5k, p50 12.0 → 12.2 µs; B2 422k → 413k), except B1 4 KB
randwrite qd1 j4 (408k → 327k). So the run-1 headline numbers (ublk interface ≈ +10 µs and ≈ +9 µs
CPU per 4 KB I/O) hold.

## Phase 5: loose ends, same boot (`scripts/run-2-p5.sh`, data in `results/run2/p5/`)

Short diagnostic runs (3–8 s, one job). Absolute IOPS here are lower than in the matrix because
tracing is on; the per-I/O counts are what matter.

**F2 write hypothesis confirmed: one deferred DIO-completion work item per write.**
Counting every task wakeup (`sched:sched_wakeup`) during 4 KB randwrite qd1:

| woken per I/O | B3 raw ublk write | F2 ext4 write | F2 ext4 read |
|---|---:|---:|---:|
| fio | 1.00 | 1.00 | 1.00 |
| ublk.loop server | 1.00 | 1.00 | 1.00 |
| kworker (CPU 12, a ublk server CPU) | 0 | **1.00** | 0 |

`workqueue:workqueue_execute_start` names the work: `iomap_dio_complete_work`, 81,902 times for
81,902 writes. ext4 direct writes complete through iomap's DIO workqueue when the device completes
asynchronously (ublk); reads and inline-completing devices (brd) skip it. That is the extra context
switch (3.9 → 4.9) and the qd1 write gap (B3 → F2, here 21.9 → 34.0 µs p50). A kernel cost of ext4/iomap
on any async device, not of ublk itself.

**FUSE `--nocache` read collapse explained: a synchronous GETATTR before every read.**
kprobes on `fuse_do_getattr` / `fuse_simple_request` / `fuse_direct_IO`, plus the connection's
`waiting` count sampled every 5 ms:

| 4 KB, per I/O | defaults read qd8 | nocache read qd8 | nocache read qd1 | nocache write qd8 |
|---|---:|---:|---:|---:|
| IOPS | 225k | **29k** | 14k | 215k |
| GETATTR round trips | 0 | **1.00** | 1.00 | 0 |
| FUSE requests in flight (mean / max) | 2.9 / 8 | **1.4 / 2** | 0.8 / 1 | 3.1 / 8 |
| context switches | 1.4 | 6.1 | 8.3 | 1.3 |

With attribute timeout 0, the kernel revalidates the file size before every read
(`fuse_cache_read_iter` → `fuse_update_attributes`), as a blocking GETATTR inside io_uring's submit
path (no io-wq punts seen). fio's submitter waits on it, so at most one READ plus one GETATTR are ever
in flight: queue depth 8 becomes ~1, and each read pays two round trips. Writes do not revalidate, so
they are unaffected. Likely fixes (not tested): a non-zero attr timeout, or `direct_io` on open (which bypasses
the cached read path that does the revalidation).

**B2 multi-job 128 KB noise resolved.** 5 fresh repeats (`raw/B2-brd-rerun/`): read qd1 j4
145–147k (CV 0.6%), qd8 j4 142–144k (CV 0.4%). The phase-1 means (215k / 202k, CV ~40%) were inflated by
outlier runs; use ~145k. That is the same as F0 ext4 on brd (139–144k), as expected.

Side note: two Claude Code processes on the node (file watchers, `fs.watch`) were woken ~2–3x per I/O
during these traces. They are not in the I/O path, but stop them before the next timed matrix since
CPU is counted system-wide.

## What is still open
1. Application-level put/get (RocksDB db_bench): not started.
2. Real SSD/NVMe instead of RAM disks: device latency may hide much of the overhead.
3. Newer kernel (6.14+): FUSE passthrough, FUSE-over-io_uring, ublk zero-copy. These target exactly
   the costs measured here (round trips, data copies).
4. Profile `--single` vs the thread pool. (`--nocache` collapse and the F2 write worker: explained in phase 5.)
5. FUSE nosplice writes (needs aligned-buffer patch; from run 1).
6. A FUSE "null" filesystem to isolate the FUSE interface cost like B1 does for ublk.
