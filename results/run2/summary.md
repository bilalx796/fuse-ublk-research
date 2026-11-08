# fio summary (medians across repeats)

Latency = fio total latency (submit+complete). CPU = system-wide busy time per I/O.

### IOPS

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 457,377 | 425,998 | 388,245 | 333,337 | 332,633 | 347,561 |
| randwrite-4k-qd32-j1 | 441,047 | 388,843 | 344,976 | 300,847 | 279,719 | 314,064 |
| read-128k-qd1-j4 | 235,364 | 59,111 | 148,159 | 25,243 | 144,047 | 47,881 |
| read-128k-qd32-j1 | 88,239 | 81,859 | 37,515 | 27,242 | 37,408 | 71,309 |
| read-128k-qd8-j4 | 301,964 | 56,300 | 143,410 | 22,164 | 139,109 | 68,340 |
| write-128k-qd1-j4 | 239,359 | 43,424 | 109,986 | 19,584 | 106,968 | 37,363 |
| write-128k-qd32-j1 | 84,263 | 83,027 | 27,532 | 21,762 | 27,095 | 62,874 |
| write-128k-qd8-j4 | 292,285 | 51,440 | 106,790 | 16,894 | 104,583 | 60,091 |

### Latency p50 (µs)

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 69.1 | 74.2 | 81.4 | 96.8 | 95.7 | 78.3 |
| randwrite-4k-qd32-j1 | 71.2 | 81.4 | 91.6 | 107.0 | 113.2 | 88.6 |
| read-128k-qd1-j4 | 16.5 | 66.0 | 26.2 | 156.7 | 27.0 | 82.4 |
| read-128k-qd32-j1 | 366.6 | 387.1 | 847.9 | 1105.9 | 856.1 | 370.7 |
| read-128k-qd8-j4 | 107.0 | 569.3 | 220.2 | 1417.2 | 228.4 | 399.4 |
| write-128k-qd1-j4 | 16.2 | 81.4 | 35.6 | 201.7 | 36.6 | 105.0 |
| write-128k-qd32-j1 | 419.8 | 403.5 | 1155.1 | 1466.4 | 1171.5 | 419.8 |
| write-128k-qd8-j4 | 120.3 | 643.1 | 297.0 | 1925.1 | 305.2 | 456.7 |

### Latency p99 (µs)

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 74.2 | 88.6 | 86.5 | 111.1 | 99.8 | 136.2 |
| randwrite-4k-qd32-j1 | 89.6 | 96.8 | 96.8 | 116.2 | 124.4 | 146.4 |
| read-128k-qd1-j4 | 19.8 | 72.2 | 36.1 | 175.1 | 37.1 | 89.6 |
| read-128k-qd32-j1 | 383.0 | 419.8 | 872.4 | 1728.5 | 872.4 | 3424.3 |
| read-128k-qd8-j4 | 127.5 | 626.7 | 242.7 | 2039.8 | 250.9 | 3489.8 |
| write-128k-qd1-j4 | 19.6 | 136.2 | 40.2 | 214.0 | 43.8 | 116.2 |
| write-128k-qd32-j1 | 440.3 | 505.9 | 1187.8 | 1712.1 | 1204.2 | 3489.8 |
| write-128k-qd8-j4 | 136.2 | 970.8 | 309.2 | 2056.2 | 317.4 | 3620.9 |

### System-wide CPU µs per I/O

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 2.28 | 4.68 | 2.68 | 5.58 | 3.11 | 14.01 |
| randwrite-4k-qd32-j1 | 2.43 | 4.94 | 3.01 | 6.44 | 3.69 | 15.71 |
| read-128k-qd1-j4 | 17.14 | 35.61 | 27.25 | 60.01 | 28.04 | 88.56 |
| read-128k-qd32-j1 | 11.72 | 21.21 | 27.76 | 54.38 | 27.71 | 62.55 |
| read-128k-qd8-j4 | 13.36 | 35.85 | 28.18 | 64.77 | 28.98 | 67.63 |
| write-128k-qd1-j4 | 16.91 | 43.55 | 36.68 | 73.35 | 37.73 | 109.94 |
| write-128k-qd32-j1 | 12.25 | 20.87 | 37.55 | 63.25 | 38.29 | 72.12 |
| write-128k-qd8-j4 | 13.85 | 37.62 | 37.79 | 81.06 | 38.52 | 83.95 |

### Context switches per I/O

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 0.00 | 0.05 | 0.00 | 0.14 | 0.00 | 0.30 |
| randwrite-4k-qd32-j1 | 0.00 | 0.18 | 0.00 | 0.08 | 0.00 | 0.25 |
| read-128k-qd1-j4 | 1.95 | 1.99 | 0.00 | 2.00 | 0.00 | 4.01 |
| read-128k-qd32-j1 | 0.11 | 1.97 | 0.01 | 0.16 | 0.01 | 1.08 |
| read-128k-qd8-j4 | 0.36 | 0.56 | 0.00 | 0.38 | 0.00 | 1.95 |
| write-128k-qd1-j4 | 2.00 | 2.34 | 0.00 | 2.53 | 0.00 | 4.04 |
| write-128k-qd32-j1 | 0.47 | 0.06 | 0.01 | 0.15 | 0.01 | 1.06 |
| write-128k-qd8-j4 | 0.64 | 0.31 | 0.00 | 0.35 | 0.00 | 2.41 |

### IOPS spread across repeats (max-min)/median %

| config | B0-null_blk | B1-ublk-null | B2-brd | B3-ublk-loop-brd | F0-ext4-brd | F1-fuse-hp-ext4-brd |
|---|---:|---:|---:|---:|---:|---:|
| randread-4k-qd32-j1 | 2.5 | 10.5 | 3.7 | 0.7 | 2.3 | 0.5 |
| randwrite-4k-qd32-j1 | 8.7 | 6.9 | 3.3 | 1.0 | 7.3 | 0.6 |
| read-128k-qd1-j4 | 3.1 | 20.3 | 136.2 | 22.5 | 1.1 | 0.3 |
| read-128k-qd32-j1 | 1.6 | 0.3 | 0.2 | 0.5 | 0.8 | 0.3 |
| read-128k-qd8-j4 | 0.8 | 34.2 | 124.2 | 11.5 | 1.2 | 0.2 |
| write-128k-qd1-j4 | 2.0 | 1.4 | 0.4 | 16.3 | 0.4 | 0.9 |
| write-128k-qd32-j1 | 1.5 | 0.5 | 1.3 | 1.2 | 0.8 | 0.2 |
| write-128k-qd8-j4 | 1.5 | 2.0 | 0.2 | 9.8 | 0.3 | 0.0 |

## Layer differences (A − B)

### Δ latency p50 (µs)

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd32-j1 | +5.12 | +15.36 | -17.41 | – |
| randwrite-4k-qd32-j1 | +10.24 | +15.36 | -24.58 | – |
| read-128k-qd1-j4 | +49.54 | +130.43 | +55.42 | – |
| read-128k-qd32-j1 | +20.48 | +258.05 | -485.38 | – |
| read-128k-qd8-j4 | +462.34 | +1197.06 | +171.01 | – |
| write-128k-qd1-j4 | +65.22 | +166.14 | +68.35 | – |
| write-128k-qd32-j1 | -16.38 | +311.30 | -751.62 | – |
| write-128k-qd8-j4 | +522.75 | +1628.16 | +151.55 | – |

### Δ CPU µs per I/O

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd32-j1 | +2.40 | +2.90 | +10.89 | – |
| randwrite-4k-qd32-j1 | +2.51 | +3.43 | +12.02 | – |
| read-128k-qd1-j4 | +18.47 | +32.75 | +60.52 | – |
| read-128k-qd32-j1 | +9.49 | +26.62 | +34.84 | – |
| read-128k-qd8-j4 | +22.49 | +36.59 | +38.65 | – |
| write-128k-qd1-j4 | +26.64 | +36.67 | +72.22 | – |
| write-128k-qd32-j1 | +8.62 | +25.69 | +33.83 | – |
| write-128k-qd8-j4 | +23.76 | +43.27 | +45.42 | – |

### Δ context switches per I/O

| config | ublk interface (null target vs null_blk) | ublk + loop backend (not ublk alone) | conventional FUSE (passthrough_hp) over ext4 | ublk loop stack under ext4 |
|---|---:|---:|---:|---:|
| randread-4k-qd32-j1 | +0.05 | +0.14 | +0.30 | – |
| randwrite-4k-qd32-j1 | +0.18 | +0.07 | +0.24 | – |
| read-128k-qd1-j4 | +0.04 | +1.99 | +4.01 | – |
| read-128k-qd32-j1 | +1.87 | +0.15 | +1.07 | – |
| read-128k-qd8-j4 | +0.19 | +0.38 | +1.94 | – |
| write-128k-qd1-j4 | +0.35 | +2.53 | +4.04 | – |
| write-128k-qd32-j1 | -0.41 | +0.13 | +1.05 | – |
| write-128k-qd8-j4 | -0.33 | +0.35 | +2.40 | – |
