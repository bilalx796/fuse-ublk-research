# The Research So Far, in Plain Language

*Written 8 November 2026, after two rounds of experiments (31 October and 8 November).
No technical background needed. Technical details: [`notes/`](notes/) and [`results/`](results/).*

---

## 1. What is this research about?

Every time a program saves or opens a file, the request goes to the **operating system**: the core
software that runs the computer (here, Linux). Normally the operating system handles the whole
request itself, very quickly, in its own protected "inner room".

Linux also allows a different arrangement: it can **pass the request out to an ordinary program**,
let that program deal with it, and pass the answer back. There are two ways to do this:

- **FUSE**: the outside program pretends to be a *filing system* (it deals with files and folders).
- **ublk**: the outside program pretends to be a *disk* (it deals with raw blocks of data).

**Why would anyone do this?** Writing an ordinary program is much easier and safer than changing
the operating system's inner room. Companies use this approach to build new kinds of storage quickly.

**What's the catch?** Every request now has to leave the inner room, go to the outside program,
and come back. That trip costs **time** and **computer effort (CPU)**.

> **An analogy.** Think of a restaurant kitchen. Normally the chef cooks every dish. With FUSE or
> ublk, the chef hands each order through a window to an outside cook, waits, and takes the dish
> back. The outside cook may be very good, but every order now pays for the trip through the
> window.

**The research question:** *How much does that trip cost, where exactly does the cost come from,
and when does it matter?*

---

## 2. How did we test it?

- **We used a rented research computer** (from Emulab, a shared research facility). Each rental
  lasts a few hours and the machine is wiped afterwards, so everything is saved to GitHub as we go.
- **We used a standard testing tool (fio)** that fires storage requests as fast as it can and
  records how long each one takes. Requests were either **small** (4 KB, like a short note) or
  **large** (128 KB, like a photo), sent **one at a time** or **many at once**.
- **We kept all the data in memory instead of on a real disk.** A real disk is slow, and its
  slowness would hide the small cost we want to see, the way a long highway drive hides a
  10-second toll booth.
- **Every test was compared with a "no outside program" version** of the same setup. The
  difference between the two is the cost of the trip.
- **We measured three things:** how long each request takes, how many requests per second get
  done, and how much computer effort each request uses in total.
- Each test ran for 20 seconds and was repeated 3–5 times to check the results are consistent.

**Round 1 (31 October)** measured the basic cost for 7 different setups and looked inside the
computer to see where the time goes. **Round 2 (8 November, today)** followed up on the open
questions from round 1.

---

## 3. What did we find?

### Finding 1: Both approaches add a cost. FUSE's is about three times bigger.

For one small request, the time taken was roughly:

| Path | Time per request |
|---|---|
| Operating system alone | about 2–3 millionths of a second |
| Through ublk (outside "disk") | about 12–16 millionths |
| Through FUSE (outside "filing system") | about 38 millionths |

These are tiny numbers for one request, but storage systems handle **millions** of requests, so it
adds up. Round 2, on a different machine, got the same numbers within about 5%, so they are reliable.

### Finding 2: The cost comes mostly from the "hand-off" itself.

Each request makes the computer switch back and forth between programs about **4 times**
(the app waits → the outside program wakes up → it answers → the app wakes up again).
Without the outside program there are no such switches. FUSE costs more because its outside program
also has to do the real file work afterwards, and spends extra time preparing memory for each request.

### Finding 3: Sending many requests at once hides the delay, but not the effort.

When many requests are sent together, the outside program can work on them in parallel, and the
**speed nearly catches up** with the operating system alone. But each request **still uses more
computer effort**: in round 2, FUSE used about **4.5 times** as much effort per small request as
the normal path, and ublk about **twice** as much.

> **In restaurant terms:** with many orders at once, food still comes out on time, but you need
> more staff in the kitchen to manage it. On a busy computer, that lost effort is effort that
> other programs can't use.

### Finding 4 (new): A surprising round-1 result turned out to be a testing quirk.

In round 1, FUSE looked **faster** than the normal path for large requests, which made no sense.
Round 2 showed why: the test used only one sender, which held the normal path back. With **four
senders**, the normal path is **2–3 times faster than FUSE**, as expected. So that result was
caused by how the test was set up, not by FUSE being fast.

### Finding 5 (new): ublk struggles with large requests from several senders.

With four senders and large requests, ublk handled only a **fraction** of what the normal path
could (between a quarter and a sixth). Every byte of data has to be copied to and from the outside program, and
on this version of Linux there's no way to avoid that copy.

### Finding 6 (new): FUSE's settings matter, and each one is a trade-off.

We tried FUSE with different settings:

| Setting | Effect |
|---|---|
| **One worker instead of a team** | Single requests got **30% faster** and used less effort, but it couldn't keep up when many requests came at once (about 3 times slower then). |
| **Exactly 4 workers** | Response times became much **more consistent** (the slowest requests got twice as fast), for a small loss in total speed. |
| **Turning caching off** | Much **worse**, especially for reading many things at once (about 10 times slower). **Solved later the same day:** without caching, Linux first asks the outside program "has this file changed size?" before *every* read, and waits for the answer. That doubles the trips and stops reads from overlapping. |
| "clone-fd" option | No noticeable effect. |

So there's no single "best" setting: it depends on whether the work comes one request at a time or
in bulk.

### Finding 7 (new): We found why writes through ublk with a filing system are slow.

Putting a normal filing system on top of ublk made **writing** noticeably slower than expected
(about half the speed of ublk alone in some tests). The obvious suspect was the filing system's
**journal** (a safety log it keeps of changes). We tested with the journal switched off, and
**nothing changed**. We also counted what reached the outside program: no extra data was being
written. What we did see is **one extra hand-off per write**. We then traced it and **confirmed**
the guess: after every write, Linux hands the "write finished" step to a helper task
(`iomap_dio_complete_work`), exactly once per write, which adds one more switch. Reads don't do this.
This is a cost of the filing system on any device that finishes requests later (like ublk), not of
ublk itself.

---

## 4. What this research does *not* show yet

This is a careful **first study**. It answers "how big is the cost, and why?" for simple tests.
It doesn't yet answer the following:

1. **Real applications.** All tests used a measuring tool, not a real program like a database.
   *Why it matters:* real programs do other work between requests, which could make the cost less
   (or more) noticeable. **Plan:** test with RocksDB, a widely used database, in a later session.

2. **Real disks.** All data was kept in memory on purpose.
   *Why it matters:* a real disk (SSD) takes far longer per request than memory, so the extra cost
   may be a much smaller share of the total in practice. **Plan:** repeat key tests on an SSD.

3. **Newer versions of Linux.** We used Linux 6.8. Newer versions (6.14 and later) add features
   designed to shrink exactly the costs we measured: letting FUSE skip the outside program for plain
   data, a faster "hand-off" channel for FUSE, and copy-free data for ublk.
   *Why it matters:* the costs we measured may be much lower on newer systems. This is probably the
   most interesting comparison for the next step.

4. **More machines and longer tests.** Everything ran on one type of machine, with 20-second tests.
   The results did repeat well across two different machines and days, which is encouraging.

5. **One loose end:** why one FUSE worker is faster than many for single requests. (The caching
   and slow-write questions were answered at the end of run 2.)

---

## 5. The short version

- Passing storage work to an outside program **costs extra time and effort**: a little with
  ublk, about three times more with FUSE.
- The cost comes mainly from **the back-and-forth hand-offs** between programs.
- Sending many requests at once **hides the delay but not the extra effort**.
- Settings matter, and each one is a **trade-off**.
- Next steps: **real database workloads, real disks, and newer Linux versions**, which may change
  the picture.
