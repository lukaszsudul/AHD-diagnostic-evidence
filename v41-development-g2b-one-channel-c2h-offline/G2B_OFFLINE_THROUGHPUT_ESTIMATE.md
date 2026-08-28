# AHD v41 G2B Offline Throughput Estimate

## Classification

`SIMULATION_MEASUREMENT: NOT_RUN`

`HARDWARE_QUALIFICATION: NOT PERFORMED`

The figures below are arithmetic limits from the accepted G2A interface and
the provisional G1 v41D plan. They are not results from implemented G2B RTL
and do not qualify DMA, video capture, Gen2 negotiation, or the 288 MB/s
product requirement.

## Nominal inputs

| Quantity | Nominal value | Authority boundary |
|---|---:|---|
| Effective AXI/application clock | 62.5 MHz | measured in accepted G2A route |
| AXI4-Stream width | 64 bits = 8 bytes | accepted G2A/XDMA interface |
| Transport-record size | 4,096 bytes | provisional G1 v41D plan |
| Useful payload | 3,840 bytes | provisional G1 v41D plan |
| Beats per record | 512 | derived from 4,096 / 8 |
| Accepted beats per stall-free cycle | 1 | theoretical target, not measured |

## Stall-free arithmetic ceiling

At one accepted 8-byte beat on every 62.5 MHz cycle:

```text
raw transport capacity = 8 bytes/cycle × 62,500,000 cycles/s
                       = 500,000,000 bytes/s
                       = 500.000 MB/s decimal

cycles per record      = 4,096 bytes / 8 bytes/cycle
                       = 512 cycles

time per record        = 512 / 62,500,000
                       = 8.192 microseconds

record rate            = 62,500,000 / 512
                       = 122,070.3125 records/s

useful payload rate    = 122,070.3125 × 3,840
                       = 468,750,000 bytes/s
                       = 468.750 MB/s decimal
```

The nominal useful fraction is `3,840 / 4,096 = 93.75%`. Header plus tail
consume 256 bytes, or 6.25% of transport capacity. The arithmetic useful-rate
ceiling exceeds 288 MB/s by 180.75 MB/s, but this comparison proves only that
the interface width and clock are not an arithmetic bottleneck under ideal
continuous acceptance.

With an accepted-beat duty factor `d` after backpressure and bubbles, the
corresponding nominal useful ceiling is `468.75 × d MB/s`. G2B did not
measure `d`, record-to-record bubbles, source availability, or reset/drop
effects.

## Required measurements not produced

| Measurement | Result |
|---|---|
| Implemented cycles per record | NOT_RUN |
| Implemented bubble cycles | NOT_RUN |
| Stall-free effective payload rate | NOT_RUN |
| Backpressured effective payload rate | NOT_RUN |
| Formatter sustained one-beat/cycle proof | NOT_RUN |
| Source-to-C2H sustained delivery | NOT_RUN |
| Hardware DMA throughput | PROHIBITED; NOT_RUN |

## Conclusion

`OFFLINE_THROUGHPUT_ESTIMATE = THEORETICAL_ONLY`

No throughput acceptance may be inferred while the record ABI is unfrozen
and no G2B formatter exists.

