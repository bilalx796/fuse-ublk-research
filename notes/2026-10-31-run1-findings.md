# Run 1 Findings — 2026-10-31

Preliminary. One node (Emulab d430), one boot, 3 repeats x 20 s per cell. Full tables:
`results/summary.md` / `results/summary.csv`. Method and caveats: `2026-10-31-run1-method.md`.
All numbers below are medians; latency is fio total latency; CPU is system-wide busy time per I/O.

## 1. What is the overhead? (4 KB, queue depth 1, one job: the per-request cost)

| | p50 latency | IOPS | CPU µs / I/O | context switches / I/O |
|---|---:|---:|---:|---:|
| B0 null_blk | 1.9 µs | 460k | 2.5 | 0.0 |
| B1 ublk null | 12.0 µs | 80k | 11.6 | 4.0 |
| B2 brd | 2.1 µs | 422k | 2.5 | 0.0 |
| B3 ublk loop → brd | 15.6 µs | 61k | 15.3 | 3.9 |
| F0 ext4 on brd | 2.6 µs | 341k | 3.0 | 0.0 |
| F1 FUSE (passthrough_hp) → F0 | 38.1 µs | 22k | 47.7 | 4.1 |
| F2 ext4 on ublk loop → brd | 16.5 µs | 59k | 16.1 | 3.9 |

(4 KB random read; random write is similar: ublk +9.8 µs, FUSE +41.7 µs over its baseline.)

- **ublk interface alone (B1 − B0): ~+10 µs latency, ~+9 µs CPU per 4 KB I/O.**
- **ublk loop stack (B3 − B2): ~+13.5 µs.** Includes the loop target's second I/O into brd (review point C).
- **Conventional FUSE over ext4 (F1 − F0): ~+35–42 µs latency, ~+45–55 µs CPU per 4 KB I/O**,
  about 3x the ublk loop stack's cost. FUSE's p99 is also much wider (108 µs vs 3 µs for ext4).
- Putting ext4 on top of ublk adds little over the raw ublk loop device for reads (F2 ≈ B3).

## 2. Where does it come from? (perf, 4 KB randread qd1, `results/profile/`)

- Every userspace-served request costs **~4 context switches** (fio sleeps → server wakes → server
  sleeps → fio wakes). The kernel paths need ~0. This holds for both ublk and FUSE.
- **ublk:** ~3 `io_uring_enter` calls per I/O system-wide (fio + server commit-and-fetch).
  `ublk_copy_io_pages` shows up even for the null target: 6.8 has no ublk zero-copy.
- **FUSE:** exactly 1 `read` + 1 `writev` on /dev/fuse per I/O (193k each for 193k I/Os), plus the
  daemon's own I/O to ext4. The top daemon kernel symbol is **`clear_page_erms`** (page zeroing),
  above the actual data copy (`copy_from_brd`). Hypothesis: per-request buffer/pipe page allocation
  in libfuse's splice path. **Next step: rerun F1 with `--nosplice` and compare.**
- Idle (`swapper`) is ~50% of samples in both: the round trip is latency-bound, not CPU-saturated.

## 3. When does it matter?

- **Queue depth hides the latency, not the CPU.** At 4 KB qd8, IOPS are near baseline
  (B1 423k vs B0 406k; F1 319k vs F0 333k), but CPU per I/O is still higher:
  ublk +2.2 µs, FUSE +12.1 µs. Supports H3 (overhead shows up as CPU before throughput).
- **Large I/O:** the absolute gap grows (FUSE +119 µs at 128 KB qd1 read) but the relative gap
  shrinks (FUSE has 1/15 of ext4's IOPS at 4 KB qd1, 1/6 at 128 KB). H1 partly supported.
- **Anomaly, explained:** at 128 KB qd8, FUSE beats plain ext4 (71k vs 36k IOPS). passthrough_hp
  opens the backing file with the caller's flags (O_DIRECT kept), so it is not the page cache.
  With one fio job, ext4-on-brd copies all data inline on fio's single CPU (qd8 ≈ qd1 = 36k),
  while FUSE's daemon threads spread the copies over 4 CPUs. This is a single-submitter artifact,
  not FUSE being faster; it still costs 2.2x the CPU per I/O. Needs a multi-job comparison.
- **H2 (ublk scales better with depth than FUSE) is not supported as stated:** at 4 KB qd8 both
  reach near-baseline IOPS, and FUSE writes do better than ext4-on-ublk (275k vs 141k).
  F2's write numbers are low across the board; possibly ext4 journal I/O through ublk. Investigate.

## Data quality

- IOPS spread across repeats (max−min)/median is under 10% for most cells but **brd (B2) is noisy
  at 4 KB (29–43%)**, and B1 has 20–30% in a few cells. Need more repeats and longer runs before
  quoting B2-based differences precisely.
- 20 s runs, 3 repeats. Idle-system CPU background not subtracted (small relative to these values).

## Next session (priority order)
1. F1 `--nosplice` and `--nocache` (tests the clear_page hypothesis; FUSE knob sensitivity).
2. Multi-job (j4/j8) at 128 KB to settle the anomaly; queue depth 32+.
3. Longer runs / 5 repeats on B2, B1 to reduce spread.
4. ext4-on-ublk write investigation (journal, `-q`/`-d` settings).
5. RocksDB db_bench (put/get).
