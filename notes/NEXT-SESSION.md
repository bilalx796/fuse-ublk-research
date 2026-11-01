# Resume Checklist (read this first on a new node)

Context for whoever picks this up (including Claude in a new session, which will NOT remember
earlier sessions; this file and the notes are the memory).

## Where we are (as of 31 Oct 2026)
- Run 1 done: fio on 7 setups + FUSE nosplice reads. See `results/README.md` (plain summary) and
  `notes/2026-10-31-run1-findings.md` (details, explanations, next-step list).
- Not done: RocksDB put/get, settings sweeps, ublk write investigation, multi-job 128 KB check.
- Plan assumptions still to confirm with Omid: put/get = RocksDB db_bench? RAM-backed only, or a
  real disk too? Move to a newer kernel (6.14+) for FUSE passthrough / FUSE-over-io_uring / ublk zero-copy?

## Practical facts
- Node type: Emulab **d430**, Ubuntu 24.04, kernel 6.8. Same type keeps numbers comparable.
- The node's home directory is on local disk and is wiped when the reservation ends.
  **Commit and push after every phase.**
- Emulab node clocks are Mountain time; the user is on Central (1 hour ahead). Emulab's expiry
  time is shown in the user's time. Get the expiry time at the start and plan around it.
- A 4-hour window fits: ~15 min bring-up, ~90 min full fio matrix (`run-all.sh`), plus follow-ups.

## Steps on a new node
1. **GitHub access** (pick one):
   - Easiest: SSH into the node with agent forwarding (`ssh -A ...`) from a laptop whose key is
     on your GitHub account; then `git clone git@github.com:bilalx796/fuse-ublk-research.git` works.
   - Or a new deploy key: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_fuse_ublk_research`,
     add the `.pub` in repo Settings → Deploy keys (allow write), add an ssh config alias, clone.
     Delete old deploy keys you no longer use.
2. `git config user.name bilalx796; git config user.email bilalx796@gmail.com` (repo-local).
3. `scripts/bringup.sh` (needs sudo; ~15 min). Note: written from the steps run by hand in run 1,
   but not yet run end-to-end on a fresh node; check its output.
4. Check: `lsblk` shows nullb0, ram0, ram1, ublkb0, ublkb1; `/mnt/bench/f0` and `/mnt/bench/f1` mounted.
5. Pick the next experiments from the findings note's list, and push results when done.

## Gotchas found in run 1
- Use fio **total** latency (`lat_percentiles=1`), not clat: null_blk/brd complete inline.
- ublksrv pins its queue threads itself; re-pin with `scripts/pin-server.sh` after creating devices.
- F0 and F1 share the 8 GiB ram1: delete the previous test file before the next setup,
  and remount FUSE if a deleted file is still held open (space isn't freed otherwise).
- `passthrough_hp --nosplice` cannot do O_DIRECT writes (EINVAL); reads only.
- Don't run anything else on the node during measurements: CPU is counted system-wide.
