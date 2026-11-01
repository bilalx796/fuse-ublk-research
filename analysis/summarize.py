#!/usr/bin/env python3
"""Summarize fio JSON + /proc/stat CPU deltas from results/raw/ into tables.

Usage: python3 -I analysis/summarize.py [results/raw] [out-dir]

Writes:
  <out>/summary.csv      one row per (setup, config): medians across repeats
  <out>/summary.md       readable tables + layer differences

Metric notes:
  * Latency is fio TOTAL latency (lat_ns = submission + completion), not clat.
    null_blk/brd complete inline during submit, so clat alone would hide their cost.
  * cpu_us_per_io is SYSTEM-WIDE busy CPU time (user+sys+irq+softirq on all CPUs,
    from /proc/stat) divided by I/Os completed. It includes fio, the FUSE/ublk server
    and kernel work. The CPU window includes the 5 s ramp, so busy time is scaled by
    runtime/(runtime+ramp). Idle-system background (~few us/s) is not subtracted.
  * ctx_per_io = system-wide context switches per I/O, same scaling.
"""
import csv, glob, json, os, re, statistics as st, sys

raw = sys.argv[1] if len(sys.argv) > 1 else "results/raw"
out = sys.argv[2] if len(sys.argv) > 2 else "results"
RUNTIME, RAMP = 20, 5

def load(path):
    j = json.load(open(path))["jobs"][0]
    d = "read" if j["read"]["io_bytes"] > 0 else "write"
    r = j[d]
    pct = r["lat_ns"]["percentile"]
    cpu = dict(kv.split("=") for kv in open(path[:-5] + ".cpu").read().split())
    cpu = {k: int(v) for k, v in cpu.items()}
    frac = RUNTIME / cpu["wall_s"]
    busy_us = cpu["busy_jiffies"] / cpu["hz"] * 1e6 * frac
    ios = r["total_ios"] or 1
    return {
        "iops": r["iops"],
        "bw_mib": r["bw_bytes"] / 2**20,
        "lat_mean_us": r["lat_ns"]["mean"] / 1000,
        "lat_p50_us": pct["50.000000"] / 1000,
        "lat_p99_us": pct["99.000000"] / 1000,
        "lat_p999_us": pct["99.900000"] / 1000,
        "cpu_us_per_io": busy_us / ios,
        "ctx_per_io": cpu["ctxt"] * frac / ios,
        "cpus_busy": busy_us / 1e6 / RUNTIME,
    }

rows = {}
for f in sorted(glob.glob(f"{raw}/*/*.json")):
    setup = f.split("/")[-2]
    m = re.match(r"(.+)-r(\d+)\.json$", os.path.basename(f))
    if not m:
        continue
    rows.setdefault((setup, m.group(1)), []).append(load(f))

keys = ["iops", "bw_mib", "lat_mean_us", "lat_p50_us", "lat_p99_us", "lat_p999_us",
        "cpu_us_per_io", "ctx_per_io", "cpus_busy"]
summary = {}
for k, reps in rows.items():
    s = {m: st.median(r[m] for r in reps) for m in keys}
    iops = [r["iops"] for r in reps]
    s["iops_spread_pct"] = (max(iops) - min(iops)) / st.median(iops) * 100
    s["reps"] = len(reps)
    summary[k] = s

os.makedirs(out, exist_ok=True)
with open(f"{out}/summary.csv", "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["setup", "config", *keys, "iops_spread_pct", "reps"])
    for (s, c), v in sorted(summary.items()):
        w.writerow([s, c, *(f"{v[m]:.3f}" for m in keys), f"{v['iops_spread_pct']:.1f}", v["reps"]])

setups = sorted({s for s, _ in summary})
configs = sorted({c for _, c in summary}, key=lambda c: (not c.startswith("rand"), c))

def table(metric, fmt, title):
    lines = [f"### {title}", "", "| config | " + " | ".join(setups) + " |",
             "|---|" + "---:|" * len(setups)]
    for c in configs:
        cells = [fmt.format(summary[(s, c)][metric]) if (s, c) in summary else "–" for s in setups]
        lines.append(f"| {c} | " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"

# Layer differences. Wording follows review points B and C.
pairs = [
    ("B1-ublk-null", "B0-null_blk", "ublk interface (null target vs null_blk)"),
    ("B3-ublk-loop-brd", "B2-brd", "ublk + loop backend (not ublk alone)"),
    ("F1-fuse-hp-ext4-brd", "F0-ext4-brd", "conventional FUSE (passthrough_hp) over ext4"),
    ("F2-ext4-ublk-loop-brd", "F0-ext4-brd", "ublk loop stack under ext4"),
]
def diff_table(metric, title):
    lines = [f"### {title}", "", "| config | " + " | ".join(p[2] for p in pairs) + " |",
             "|---|" + "---:|" * len(pairs)]
    for c in configs:
        cells = []
        for a, b, _ in pairs:
            if (a, c) in summary and (b, c) in summary:
                cells.append(f"{summary[(a, c)][metric] - summary[(b, c)][metric]:+.2f}")
            else:
                cells.append("–")
        lines.append(f"| {c} | " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"

md = ["# fio summary (medians across repeats)", "",
      "Latency = fio total latency (submit+complete). CPU = system-wide busy time per I/O.", "",
      table("iops", "{:,.0f}", "IOPS"),
      table("lat_p50_us", "{:.1f}", "Latency p50 (µs)"),
      table("lat_p99_us", "{:.1f}", "Latency p99 (µs)"),
      table("cpu_us_per_io", "{:.2f}", "System-wide CPU µs per I/O"),
      table("ctx_per_io", "{:.2f}", "Context switches per I/O"),
      table("iops_spread_pct", "{:.1f}", "IOPS spread across repeats (max-min)/median %"),
      "## Layer differences (A − B)", "",
      diff_table("lat_p50_us", "Δ latency p50 (µs)"),
      diff_table("cpu_us_per_io", "Δ CPU µs per I/O"),
      diff_table("ctx_per_io", "Δ context switches per I/O")]
open(f"{out}/summary.md", "w").write("\n".join(md))
print(f"{len(summary)} (setup, config) cells -> {out}/summary.csv, {out}/summary.md")
