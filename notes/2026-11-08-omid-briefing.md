# Briefing for Omid — 8 Nov 2026

Two runs done (31 Oct, 8 Nov), Emulab d430, Linux 6.8, all data in RAM so device speed doesn't hide
the overhead. Every FUSE/ublk setup is compared against the same path without the userspace layer.

Setups: **B0** null_blk, **B1** ublk null · **B2** brd (RAM disk), **B3** ublk loop over brd ·
**F0** ext4 on brd, **F1** FUSE passthrough_hp over F0 · **F2** ext4 on ublk (B3).

---

## 1. The 30-second version (if he says "sum it up")

> On a 4 KB read, the kernel alone takes about 2 µs, ublk about 12 µs and FUSE about 38 µs. Almost
> all of that is the round trip to the userspace server: about 4 context switches per request,
> versus none in the kernel. With deep queues, throughput nearly catches up, but CPU per I/O doesn't:
> FUSE uses about 4.5x the CPU of ext4 and ublk about 2x its baseline. So on a busy machine the cost
> shows up as lost CPU, not lost IOPS. For large I/O with several submitters, ublk is capped by
> copying data on its server threads, because 6.8 has no zero-copy. These numbers reproduced within
> about 5% on a second node and boot. The next questions are whether this still matters on a real SSD
> and on a newer kernel, where features exist that target exactly these costs.

---

## 2. What we learned, with the evidence

### 1) The overhead per request: ublk ≈ +10 µs, FUSE ≈ +36 µs (4 KB random read, qd1)

| | B0 | B1 ublk | B2 | B3 ublk | F0 | F1 FUSE |
|---|---:|---:|---:|---:|---:|---:|
| p50 latency (µs) | 1.9 | 12.0 | 2.1 | 15.6 | 2.6 | 38.1 |
| IOPS | 460k | 80k | 422k | 61k | 341k | 22k |
| CPU µs / I/O | 2.5 | 11.6 | 2.5 | 15.3 | 3.0 | 47.7 |

*Evidence:* `results/summary.md` (run 1, medians of 3). Run 2 phase 4 re-measured B1/B2 with 5 repeats
on a new node: B1 p50 12.0 → 12.2 µs, 80.0k → 78.5k IOPS; B2 422k → 413k. Within about 5% on nearly
every cell. `notes/2026-11-08-run2-findings.md`, Phase 4.

### 2) The cost is the round trip, about 4 context switches per request

Context switches per I/O at qd1: B1 4.02, B3 3.93, F1 4.13, kernel baselines 0.00. The pattern is:
fio sleeps, the server wakes, the server replies, fio wakes. FUSE costs more because the daemon then
does the real I/O into ext4, and because of page zeroing (`clear_page_erms` was the daemon's top kernel
symbol in the perf profile).

*Evidence:* `results/summary.md` (context-switch table), `notes/2026-10-31-run1-findings.md`
(perf profiles in `results/profile/`).

### 3) Queue depth hides the latency, not the CPU

At 4 KB randread qd32, IOPS are within about 10–25% of baseline, but CPU per I/O is not:

| qd32 | B0 | B1 ublk | B2 | B3 ublk | F0 | F1 FUSE |
|---|---:|---:|---:|---:|---:|---:|
| IOPS | 457k | 426k | 388k | 333k | 333k | 348k |
| CPU µs / I/O | 2.3 | 4.7 | 2.7 | 5.6 | 3.1 | 14.0 |

*Evidence:* run 2 phase 1. The same pattern appeared at qd8 in run 1.

### 4) Large I/O: FUSE falls to 1/3–1/2 of ext4; ublk is capped by data copies

- Run 1 seemed to show FUSE beating ext4 at 128 KB qd8. That was an artifact of having one submitter:
  ext4 was limited to one CPU's copy rate (about 37k). With 4 jobs, ext4 scales (139–144k) and FUSE
  doesn't (48–68k), and FUSE's p99 rises to about 3.5 ms against 0.25–0.9 ms for ext4.
- ublk at 128 KB with 4 jobs: B1 59k against B0 235k, and B3 25k against B2 145k. The 4 ublk queue
  threads copy every byte, because 6.8 has no zero-copy.

*Evidence:* run 2 phase 1; the B2 value was corrected by a 5-repeat rerun in phase 5 (CV < 1%).

### 5) FUSE settings are trade-offs, not free wins

| passthrough_hp option | effect (4 KB randread) |
|---|---|
| `--single` | qd1 p50 38 → 26.5 µs, CPU −37%, but caps at about 113k IOPS at qd8 (against 319k) |
| `--num-threads 4` | qd1 p99 108 → 48 µs, about −20% IOPS at qd8 |
| `--clone-fd` | no measurable effect |
| `--nocache` | qd8 reads 319k → 29k (explained below); writes unaffected |

*Evidence:* run 2 phase 2.

### 6) Two anomalies are explained, with traces

- **ext4-on-ublk writes are slow because of ext4/iomap, not ublk.** It isn't the journal: a no-journal
  run gives identical results, and device write counts match fio's. Each write adds exactly one
  kworker wakeup running `iomap_dio_complete_work` (81,902 work items for 81,902 writes). Reads and
  raw ublk writes have none. Direct-write completions are deferred to a workqueue when the device
  completes asynchronously, which ublk does and brd doesn't.
- **The FUSE `--nocache` read collapse comes from a synchronous GETATTR before every read.** With the
  attribute timeout at 0, the kernel revalidates the file size on each read (1.00 GETATTR per read,
  measured with kprobes). It blocks in io_uring's submit path, so FUSE requests in flight drop from a
  maximum of 8 to 2. qd8 effectively becomes qd1, with two round trips per read.

*Evidence:* run 2 phases 3 and 5, `results/run2/p5/`.

### Honest limits (say these before he asks)

- Microbenchmarks only (fio), with no application yet.
- RAM-backed devices only. A real SSD adds about 10–80 µs of its own, which may hide much of the overhead.
- Linux 6.8 only, which lacks FUSE passthrough, FUSE-over-io_uring and ublk zero-copy.
- One machine type, 20 s runs, 3–5 repeats.
- No "null" FUSE filesystem yet, so FUSE's interface cost isn't isolated the way B1 isolates ublk's.

---

## 3. Questions to ask Omid

**Decisions that block the next run**
1. **Real SSD:** should the next run include an NVMe/SSD node? If so, which Emulab/CloudLab node
   type? The aim would be to show what fraction of the overhead survives real device latency.
2. **Kernel:** should we move to 6.14+ to test FUSE passthrough, FUSE-over-io_uring and ublk
   zero-copy? Should we keep 6.8 as the baseline and compare the two, or switch entirely?
3. **RocksDB:** which db_bench workloads count as "put/get" for us (for example fillrandom,
   readrandom, readwhilewriting)? Which value sizes, and what dataset size relative to RAM?

**Direction and scope**
4. What decision is this research ultimately feeding? Choosing FUSE vs ublk for a system, a paper or
   report, or a class project? That determines what "done" looks like.
5. Which matters more to the audience: latency at low load, or CPU efficiency at high load?
6. Are the two anomaly explanations (the iomap DIO worker and the nocache GETATTR) worth writing up
   as findings, or are they side notes?
7. Should I build a minimal FUSE "null" filesystem to isolate the pure FUSE interface cost?
8. Is one node type enough, or should key results be repeated on a second hardware type?

**Practical**
9. Is there a deadline or a target number of runs or sessions?
10. Can I get longer reservations, or a node where the home directory persists?

---

## 4. Questions he might ask, with short answers

- **"How do you know it's the round trip and not the server's work?"** The B1 ublk null server does
  no I/O at all and still adds about 10 µs, with 4 context switches per request.
- **"Are these numbers stable?"** Run 2 reproduced run 1 within about 5% on a different node and boot,
  and repeat-to-repeat variation is now mostly 0.5–10%.
- **"Why RAM disks?"** To measure the layer itself; an SSD's own latency would hide it. Testing on an
  SSD is the obvious next step (question 1).
- **"Is CPU counted fairly?"** Yes: it's system-wide `/proc/stat` deltas across all CPUs, so it
  includes the server, the kernel, irq and softirq, not just fio.
- **"Does a newer kernel fix this?"** We don't know yet, which is question 2. FUSE passthrough and ublk
  zero-copy target exactly the round-trip and copy costs we measured.

Full detail: `notes/2026-10-31-run1-findings.md`, `notes/2026-11-08-run2-findings.md`,
plain-language version in `RESEARCH-SO-FAR.md`.
