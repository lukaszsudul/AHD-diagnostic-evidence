# AHD v41 G2B-LUT1 Offline Throughput Summary

## Gate result

- `OFFLINE_THROUGHPUT_GATE = PASS`
- `REQUIRED_PAYLOAD = 288 MB/s`
- `HARDWARE_THROUGHPUT_PROVEN = NO`
- `HARDWARE_ACCESSED = NO`

This is an offline arithmetic gate only. It does not claim measured PCIe, DMA, host-parser, memory-system, or FPGA hardware throughput.

## Governed transport inputs

| Input | Value |
|---|---:|
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1` |
| ABI version | `1` |
| Application payload per record | `3,840 bytes` |
| Transport bytes per record | `4,096 bytes` |
| AXI stream width | `64 bits = 8 bytes/beat` |
| Configured user clock | `62.5 MHz` |
| XDMA link setting | `Gen2, 5.0 GT/s, x1` |
| Implemented C2H channels | `1` |
| Mandatory H2C channel | permanently backpressured |
| XDMA XCI SHA-256 | `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` |

The XDMA configuration is unchanged. The configured `62.5 MHz` value is used only for this offline bound; the routed clock gate must independently report the effective implemented clock.

## Exact arithmetic

Transport efficiency:

```text
3,840 payload bytes / 4,096 transport bytes = 0.9375 = 93.75%
```

Required record rate:

```text
288,000,000 payload bytes/s / 3,840 payload bytes/record
= 75,000 records/s
```

Required transport rate:

```text
75,000 records/s * 4,096 transport bytes/record
= 307,200,000 transport bytes/s
= 307.200 MB/s
```

Required accepted-beat rate:

```text
307,200,000 transport bytes/s / 8 bytes/beat
= 38,400,000 accepted beats/s
```

The stall-free raw AXI-stream byte ceiling is:

```text
62,500,000 beats/s * 8 bytes/beat
= 500,000,000 transport bytes/s
```

The corresponding stall-free useful-payload ceiling is:

```text
500,000,000 transport bytes/s * (3,840 / 4,096)
= 468,750,000 payload bytes/s
= 468.750 MB/s
```

Minimum accepted-beat duty needed to meet the payload requirement:

```text
38,400,000 / 62,500,000
= 0.6144
= 61.44%
```

Equivalent payload comparison and arithmetic margin:

```text
288.000 MB/s / 468.750 MB/s = 61.44%
468.750 MB/s - 288.000 MB/s = 180.750 MB/s
```

## Disposition

The governed offline capacity inequality is satisfied: `468.750 MB/s > 288 MB/s`. Therefore the offline throughput gate is `PASS` with a `180.750 MB/s` arithmetic margin and a minimum accepted-beat duty of `61.44%`.

No DUT was accessed, no FPGA was programmed, and no PCIe/DMA test was performed. Hardware throughput remains `NOT_PROVEN` pending separately authorized hardware qualification.
