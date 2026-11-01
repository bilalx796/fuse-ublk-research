# fio summary (medians across repeats)

Latency = fio total latency (submit+complete). CPU = system-wide busy time per I/O.

### IOPS

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 459,909 | 80,038 | 422,031 | 61,273 | 341,288 | 22,304 | 24,322 | 58,611 |
| randread-4k-qd1-j4 | 1,625,605 | 414,793 | 1,532,165 | 213,367 | 1,185,357 | 234,333 | 202,102 | 212,221 |
| randread-4k-qd8-j1 | 405,958 | 423,328 | 403,400 | 300,525 | 333,299 | 318,611 | 254,465 | 297,286 |
| randwrite-4k-qd1-j1 | 447,470 | 82,074 | 358,358 | 59,506 | 286,826 | 16,465 | – | 41,091 |
| randwrite-4k-qd1-j4 | 1,589,192 | 407,758 | 1,318,495 | 143,910 | 1,013,345 | 213,831 | – | 92,369 |
| randwrite-4k-qd8-j1 | 447,694 | 378,579 | 324,296 | 276,558 | 289,118 | 275,049 | – | 141,389 |
| read-128k-qd1-j1 | 67,044 | 23,565 | 38,203 | 13,109 | 37,361 | 6,049 | 3,530 | 12,707 |
| read-128k-qd8-j1 | 85,054 | 69,303 | 37,150 | 26,034 | 36,352 | 71,210 | 6,202 | 25,909 |
| write-128k-qd1-j1 | 67,089 | 24,074 | 27,110 | 10,660 | 27,474 | 4,322 | – | 9,365 |
| write-128k-qd8-j1 | 81,430 | 76,091 | 26,294 | 16,205 | 26,694 | 61,956 | – | 13,663 |

### Latency p50 (µs)

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 1.9 | 12.0 | 2.1 | 15.6 | 2.6 | 38.1 | 34.0 | 16.5 |
| randread-4k-qd1-j4 | 2.2 | 9.0 | 2.4 | 18.0 | 3.1 | 15.4 | 19.1 | 17.8 |
| randread-4k-qd8-j1 | 19.3 | 18.6 | 19.6 | 26.2 | 23.7 | 23.4 | 30.8 | 26.0 |
| randwrite-4k-qd1-j1 | 2.0 | 11.7 | 2.5 | 16.2 | 3.2 | 44.8 | – | 23.2 |
| randwrite-4k-qd1-j4 | 2.3 | 8.9 | 2.7 | 26.5 | 3.6 | 17.3 | – | 41.7 |
| randwrite-4k-qd8-j1 | 17.5 | 20.9 | 24.2 | 28.5 | 27.3 | 30.3 | – | 55.6 |
| read-128k-qd1-j1 | 14.4 | 41.2 | 25.5 | 75.3 | 25.7 | 144.4 | 280.6 | 76.3 |
| read-128k-qd8-j1 | 95.7 | 114.2 | 214.0 | 305.2 | 212.0 | 70.1 | 1237.0 | 325.6 |
| write-128k-qd1-j1 | 14.3 | 40.2 | 36.1 | 92.7 | 35.1 | 232.4 | – | 105.0 |
| write-128k-qd8-j1 | 107.0 | 112.1 | 301.1 | 505.9 | 292.9 | 88.6 | – | 585.7 |

### Latency p99 (µs)

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 2.1 | 14.4 | 2.6 | 18.6 | 3.2 | 108.0 | 99.8 | 19.8 |
| randread-4k-qd1-j4 | 2.4 | 11.2 | 2.7 | 21.6 | 3.7 | 27.5 | 22.9 | 22.9 |
| randread-4k-qd8-j1 | 21.9 | 28.0 | 22.7 | 34.6 | 26.8 | 37.6 | 38.1 | 33.0 |
| randwrite-4k-qd1-j1 | 2.0 | 14.0 | 3.0 | 19.3 | 3.7 | 125.4 | – | 28.3 |
| randwrite-4k-qd1-j4 | 2.4 | 14.7 | 3.2 | 32.1 | 4.3 | 25.0 | – | 48.4 |
| randwrite-4k-qd8-j1 | 20.6 | 25.2 | 33.5 | 38.1 | 33.0 | 40.2 | – | 63.2 |
| read-128k-qd1-j1 | 17.0 | 46.8 | 34.6 | 81.4 | 36.1 | 224.3 | 354.3 | 83.5 |
| read-128k-qd8-j1 | 105.0 | 126.5 | 224.3 | 358.4 | 292.9 | 585.7 | 4751.4 | 358.4 |
| write-128k-qd1-j1 | 17.3 | 46.8 | 45.3 | 100.9 | 46.8 | 264.2 | – | 114.2 |
| write-128k-qd8-j1 | 121.3 | 136.2 | 321.5 | 577.5 | 387.1 | 1155.1 | – | 618.5 |

### System-wide CPU µs per I/O

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 2.45 | 11.63 | 2.49 | 15.27 | 3.03 | 47.68 | 38.42 | 16.08 |
| randread-4k-qd1-j4 | 2.57 | 7.04 | 2.64 | 11.21 | 3.44 | 21.00 | 20.08 | 11.60 |
| randread-4k-qd8-j1 | 2.64 | 4.79 | 2.57 | 6.08 | 3.12 | 15.18 | 16.36 | 6.51 |
| randwrite-4k-qd1-j1 | 2.34 | 11.31 | 2.91 | 15.70 | 3.60 | 58.47 | – | 22.50 |
| randwrite-4k-qd1-j4 | 2.57 | 7.24 | 3.07 | 14.68 | 3.99 | 22.59 | – | 21.60 |
| randwrite-4k-qd8-j1 | 2.30 | 5.01 | 3.21 | 6.52 | 3.58 | 17.38 | – | 10.87 |
| read-128k-qd1-j1 | 15.60 | 45.93 | 27.14 | 80.61 | 28.28 | 177.30 | 326.77 | 82.53 |
| read-128k-qd8-j1 | 12.18 | 23.37 | 28.02 | 55.26 | 28.54 | 63.38 | 351.60 | 55.86 |
| write-128k-qd1-j1 | 15.42 | 43.83 | 38.51 | 98.38 | 38.08 | 217.68 | – | 110.57 |
| write-128k-qd8-j1 | 12.82 | 22.12 | 39.38 | 80.15 | 38.83 | 75.09 | – | 88.00 |

### Context switches per I/O

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 0.00 | 4.02 | 0.00 | 3.93 | 0.00 | 4.13 | 4.02 | 3.91 |
| randread-4k-qd1-j4 | 0.00 | 1.98 | 0.00 | 2.04 | 0.00 | 3.61 | 3.97 | 2.07 |
| randread-4k-qd8-j1 | 0.00 | 0.01 | 0.00 | 0.42 | 0.00 | 0.66 | 1.64 | 0.19 |
| randwrite-4k-qd1-j1 | 0.00 | 4.02 | 0.00 | 3.92 | 0.00 | 4.14 | – | 5.00 |
| randwrite-4k-qd1-j4 | 0.00 | 2.03 | 0.00 | 2.52 | 0.00 | 3.70 | – | 2.73 |
| randwrite-4k-qd8-j1 | 0.00 | 0.23 | 0.00 | 0.34 | 0.00 | 0.88 | – | 0.62 |
| read-128k-qd1-j1 | 2.00 | 4.04 | 0.01 | 4.02 | 0.01 | 4.17 | 4.37 | 4.00 |
| read-128k-qd8-j1 | 0.37 | 1.93 | 0.01 | 0.54 | 0.01 | 1.40 | 6.53 | 0.64 |
| write-128k-qd1-j1 | 2.00 | 4.10 | 0.01 | 4.07 | 0.01 | 4.15 | – | 5.09 |
| write-128k-qd8-j1 | 0.66 | 0.23 | 0.01 | 0.62 | 0.01 | 1.42 | – | 0.65 |

### IOPS spread across repeats (max-min)/median %

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd | F1n-fuse-hp-nosplice-ext4-brd | F2-ext4-ublk-loop-brd |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| randread-4k-qd1-j1 | 3.6 | 7.4 | 28.5 | 1.6 | 1.2 | 21.1 | 35.2 | 3.7 |
| randread-4k-qd1-j4 | 4.0 | 6.3 | 28.9 | 1.1 | 4.3 | 6.7 | 1.7 | 0.8 |
| randread-4k-qd8-j1 | 16.3 | 4.4 | 43.4 | 1.5 | 3.1 | 6.2 | 8.4 | 2.1 |
| randwrite-4k-qd1-j1 | 2.2 | 20.7 | 10.7 | 3.2 | 3.7 | 6.1 | – | 1.9 |
| randwrite-4k-qd1-j4 | 12.7 | 11.6 | 2.8 | 2.1 | 2.1 | 6.4 | – | 0.8 |
| randwrite-4k-qd8-j1 | 3.6 | 11.1 | 8.8 | 0.4 | 4.8 | 8.1 | – | 2.1 |
| read-128k-qd1-j1 | 0.8 | 29.8 | 0.3 | 1.2 | 1.6 | 0.2 | 0.5 | 1.5 |
| read-128k-qd8-j1 | 3.1 | 23.9 | 1.8 | 0.2 | 0.4 | 0.5 | 0.3 | 0.1 |
| write-128k-qd1-j1 | 2.2 | 7.5 | 0.6 | 0.5 | 1.2 | 1.1 | – | 0.7 |
| write-128k-qd8-j1 | 1.4 | 0.1 | 0.7 | 1.4 | 0.8 | 0.2 | – | 0.1 |

## Layer differences (A − B)

### Δ latency p50 (µs)

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd1-j1 | +10.04 | +13.42 | +35.50 | +13.87 |
| randread-4k-qd1-j4 | +6.83 | +15.70 | +12.37 | +14.74 |
| randread-4k-qd8-j1 | -0.77 | +6.66 | -0.26 | +2.30 |
| randwrite-4k-qd1-j1 | +9.75 | +13.65 | +41.65 | +20.02 |
| randwrite-4k-qd1-j4 | +6.64 | +23.76 | +13.65 | +38.10 |
| randwrite-4k-qd8-j1 | +3.33 | +4.35 | +3.07 | +28.29 |
| read-128k-qd1-j1 | +26.82 | +49.79 | +118.66 | +50.56 |
| read-128k-qd8-j1 | +18.43 | +91.14 | -141.82 | +113.66 |
| write-128k-qd1-j1 | +25.92 | +56.58 | +197.38 | +69.89 |
| write-128k-qd8-j1 | +5.12 | +204.80 | -204.29 | +292.86 |

### Δ CPU µs per I/O

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd1-j1 | +9.18 | +12.78 | +44.65 | +13.05 |
| randread-4k-qd1-j4 | +4.47 | +8.57 | +17.56 | +8.16 |
| randread-4k-qd8-j1 | +2.15 | +3.51 | +12.06 | +3.39 |
| randwrite-4k-qd1-j1 | +8.98 | +12.80 | +54.87 | +18.90 |
| randwrite-4k-qd1-j4 | +4.67 | +11.62 | +18.60 | +17.62 |
| randwrite-4k-qd8-j1 | +2.71 | +3.31 | +13.80 | +7.29 |
| read-128k-qd1-j1 | +30.33 | +53.47 | +149.02 | +54.25 |
| read-128k-qd8-j1 | +11.19 | +27.24 | +34.84 | +27.32 |
| write-128k-qd1-j1 | +28.41 | +59.87 | +179.60 | +72.49 |
| write-128k-qd8-j1 | +9.31 | +40.77 | +36.26 | +49.17 |

### Δ context switches per I/O

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd1-j1 | +4.01 | +3.93 | +4.13 | +3.91 |
| randread-4k-qd1-j4 | +1.98 | +2.04 | +3.61 | +2.07 |
| randread-4k-qd8-j1 | +0.00 | +0.42 | +0.66 | +0.19 |
| randwrite-4k-qd1-j1 | +4.02 | +3.92 | +4.14 | +5.00 |
| randwrite-4k-qd1-j4 | +2.03 | +2.51 | +3.70 | +2.73 |
| randwrite-4k-qd8-j1 | +0.23 | +0.34 | +0.88 | +0.62 |
| read-128k-qd1-j1 | +2.04 | +4.01 | +4.16 | +3.99 |
| read-128k-qd8-j1 | +1.55 | +0.53 | +1.39 | +0.63 |
| write-128k-qd1-j1 | +2.10 | +4.05 | +4.14 | +5.08 |
| write-128k-qd8-j1 | -0.44 | +0.61 | +1.40 | +0.63 |
