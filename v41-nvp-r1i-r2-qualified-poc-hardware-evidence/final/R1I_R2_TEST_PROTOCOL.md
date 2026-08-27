# R1i–R2 Frozen Test Protocol

## Frozen order

```text
Read-only Formal Phase-2 baseline
  -> A1 fixed R1i PoC
  -> B1 exact unmodified R1h control
  -> exact Formal Phase-2 restoration
  -> HARD STOP
```

A1 is the corrected candidate. B1 is the control. Lower NACK incidence in A1 supports the correction; the arm labels must not be interpreted in the conventional candidate-as-B sense.

## Identity gates

- R1i bitstream: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- R1h control bitstream: `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41`
- Formal Phase-2 bitstream: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`

Each volatile program required same-session DONE=1 and an independent read-only DONE receipt. Runtime identity and read-only PCIe/MMIO accessibility were checked after the prescribed warm reboot and pinned-driver load. No configuration flash was changed.

## Measurement denominator

Each arm completed:

- 10,000 WADDR opportunities;
- 10,000 REGADDR opportunities;
- 10,000 DATA opportunities;
- 30,000 total post-init phase observations.

The full A1+B1 campaign completed 20,000 opportunities per phase and 60,000 total post-init phase observations. Hardware counters—not elapsed time—defined completion.

Autoinit counters were recorded separately: 275 WADDR, 275 REGADDR, and 220 DATA opportunities per arm. Autoinit events are not mixed into the 60,000 post-init denominator.

The historical 90,000 value is from the earlier R1h-R4 target-phase investigation and was not the R1i–R2 target.

## Integrity gates

The frozen sample gates included exact runtime identity, `INIT_DONE=1`, complete probe counts, no probe abort or timeout, no failed-log overflow, no bank-invariant error, safe target restoration, and DONE=1. A valid functional failure remained a valid control measurement.

The exact Formal Phase-2 image was restored after B1. The final receipt reports DONE=1, expected PCIe identity and driver binding, `BLOCK_ID=0xA40A0C07`, `PROTOCOL=0x0000400B`, `CAPABILITIES=0x00031002`, and diagnostic magic zero.
