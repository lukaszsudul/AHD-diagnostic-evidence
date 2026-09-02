# G2B-LUT1 Recovery 2 Offline Throughput Summary

## Result

- `OFFLINE_THROUGHPUT = PASS`
- Required application payload: `288 MB/s`
- Stall-free useful-payload ceiling: `468.750 MB/s`
- Arithmetic margin: `180.750 MB/s`
- Minimum accepted-beat duty: `61.44%`
- `HARDWARE_THROUGHPUT_PROVEN = NO`
- `HARDWARE_ACCESSED = NO`

The governed transport remains one 64-bit C2H stream at a configured 62.5 MHz.
Each 4,096-byte record carries 3,840 application bytes, for 93.75% transport
efficiency. The exact offline ceiling is therefore:

```text
62,500,000 beats/s × 8 bytes/beat × (3,840 / 4,096)
= 468,750,000 application bytes/s
= 468.750 MB/s
```

Meeting 288 MB/s requires 38,400,000 accepted beats/s, or 61.44% of the
configured beat capacity. The Group-13 source change is constraints-only and
does not alter stream width, record format, clock configuration, backpressure,
or ABI. This is an offline capacity proof, not PCIe/DMA hardware evidence.

