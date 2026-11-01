# fuse-ublk-research

Measuring how much overhead the **FUSE** and **ublk** userspace interfaces add on Linux 6.8,
where that overhead comes from, and when it matters.

**Start here:** [results/README.md](results/README.md) is a plain-language overview of what
we tested, how, and what we found.

## Status

| Run | Date | What | Result |
|---|---|---|---|
| 1 | 31 Oct 2026 | fio microbenchmarks, 7 setups + FUSE splice follow-up | Done: [overview](results/README.md), [detailed findings](notes/2026-10-31-run1-findings.md) |
| next | – | FUSE/ublk settings sweeps, slow ublk writes, more parallelism, RocksDB put/get | Planned |

Headline: for one small read, the kernel takes ~2–3 µs, ublk ~12–16 µs and FUSE ~38 µs.
The cost comes mostly from the round trip to the userspace program (~4 context switches per request).

## Repository layout

| Folder | Contents |
|---|---|
| `results/` | Overview (`README.md`), summary tables (`summary.md`, `summary.csv`), charts (`figures/`), raw fio JSON + CPU data (`raw/`), perf profiles (`profile/`) |
| `notes/` | Planning notes, method, and detailed findings, by date |
| `scripts/` | Setup and benchmark scripts (see below) |
| `analysis/` | `summarize.py`: builds the summary tables from `results/raw/` |
| `third_party/` | libfuse and ublksrv sources, built locally (not tracked in git) |

## Reproducing on a fresh node

Tested on an Emulab **d430** node, Ubuntu 24.04, kernel 6.8. Uses only RAM disks and
virtual devices; real disks are never touched.

```bash
git clone git@github.com:bilalx796/fuse-ublk-research.git
cd fuse-ublk-research
scripts/bringup.sh                                 # packages, builds, devices, mounts (~15 min)
sudo scripts/run-all.sh > results/run-all.log 2>&1 # full fio matrix (~90 min)
python3 -I analysis/summarize.py results/raw results
```

| Script | Purpose |
|---|---|
| `bringup.sh` | Install packages, build libfuse 3.14.0 + ublksrv, set CPU governor, create devices and mounts |
| `run-all.sh` | Run the fio matrix on every setup, in order |
| `run-matrix.sh` | Run the matrix on one setup; records system-wide CPU per run |
| `profile.sh` | perf counters + call-graph profile for one workload |
| `pin-server.sh` | Pin ublk/FUSE server threads to fixed CPUs |
| `capture-env.sh` | Record kernel, CPU, mitigations and tool versions with each run |
