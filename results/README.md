# Results Overview: Run 1 (31 Oct 2026)

## What we're testing

Linux can hand storage requests to a normal program instead of handling them inside the kernel.
Two ways to do this:

- **FUSE**: a program acts as a *filesystem*. Every file read or write goes to that program.
- **ublk**: a program acts as a *disk* (block device). Every block read or write goes to that program.

This is useful because storage software can be written as a normal program. But passing each
request out to a program and back costs time and CPU. **We measured how much, and why.**

## Why

Before deciding whether to build storage on FUSE or ublk, we need to know what the extra layer
costs, where the cost comes from, and in which situations it matters.

## How

- **Tool:** fio, a standard storage benchmark. It sends reads and writes of a chosen size
  (4 KB or 128 KB), either one at a time or several at once, and measures the results.
  (RocksDB put/get tests are planned but not done yet.)
- **Fair comparison:** each FUSE or ublk setup is compared with the same setup without that
  layer (kernel only). The difference is the cost of the layer.
- **Storage in RAM:** all data lives in memory, so a slow disk doesn't hide the cost.
- **What we measured:** speed (requests per second), latency (time per request),
  and CPU time per request, counting every process involved.
- **Machine:** one Emulab d430 server, Linux 6.8. Each test ran 20 seconds, repeated 3 times.

## Findings

**1. Both layers add overhead. FUSE adds about 3× more than ublk.**
For one small (4 KB) read:

| Path | Time per read |
|---|---|
| Kernel only | ~2–3 µs |
| Through ublk | ~12–16 µs |
| Through FUSE | ~38 µs |

**2. The main cause is the round trip to the program.**
Every request makes the system switch between programs about 4 times (the app waits, the
storage program wakes up, handles it, replies, the app wakes up). The kernel-only path doesn't
switch at all. FUSE costs more because its program also does a second, real read into the
filesystem underneath, and because it spends surprising time preparing fresh memory for each
request.

**3. It matters most for small requests sent one at a time.**
Here FUSE reaches only about 1/15 of the kernel's speed, and ublk about 1/5.
When many requests are sent at once, speed nearly catches up, but **each request still uses
more CPU** (FUSE ~4× the kernel's, ublk ~2×). So on a busy machine, the cost shows up as lost
CPU even when speed looks fine.

**4. A FUSE setting (splice) is a trade-off, not a fix.**
Turning it off makes small reads ~20% cheaper but large reads up to 10× slower, and breaks
direct writes.

## Caveats

- One machine, short runs, 3 repeats. Some baselines varied a lot between repeats.
- Writes through ext4 on ublk were unexpectedly slow. Not explained yet.
- Linux 6.8 lacks newer features that may reduce these costs (FUSE passthrough,
  FUSE over io_uring, ublk zero-copy).

## Next

Tune FUSE and ublk settings, explain the slow ublk writes, test more parallel workloads,
and run RocksDB put/get.

---
Charts: [`figures/run1-charts.html`](figures/run1-charts.html) (download and open in a browser) ·
Full tables: [`summary.md`](summary.md) · Detailed notes: [`../notes/2026-10-31-run1-findings.md`](../notes/2026-10-31-run1-findings.md)
