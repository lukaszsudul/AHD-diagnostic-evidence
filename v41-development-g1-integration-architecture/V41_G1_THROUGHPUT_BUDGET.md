# AHD v41 G1 Throughput Budget

## Frozen requirement and ceilings

- Required sustained application payload: **at least 288 MB/s decimal**.
- Acceptance load: exactly two simultaneously active video channels.
- Gen2 x1 transfer rate: 5 GT/s with 8b/10b encoding.
- Raw post-encoding byte-rate ceiling: `5e9 * 0.8 / 8 = 500,000,000 B/s = 500 MB/s`.
- Gen1 x1 raw ceiling: 250 MB/s and therefore architecturally disallowed for final v41.

The absolute minimum end-to-end effective PCIe efficiency is:

```text
288 / 500 = 0.576 = 57.6%
```

That is a mathematical floor, not a prediction or a PASS.

## Record-format cost

Each 4,096-byte record carries 3,840 useful payload bytes:

```text
record efficiency = 3840 / 4096 = 93.75%
required records/s = 288,000,000 / 3840 = 75,000
required transported record bytes/s = 75,000 * 4096 = 307,200,000 B/s
required accepted AXI beats/s = 75,000 * 512 = 38,400,000
```

After accounting for record header/padding alone, all remaining link/XDMA/AXI effects must deliver at least:

```text
307.2 / 500 = 61.44% of the Gen2 x1 raw byte ceiling
```

If the requested 64-bit application stream is actually 62.5 MHz, its theoretical byte rate is 500 MB/s and the same 61.44% accepted-beat duty is required. If it is 125 MHz, the fabric ceiling is 1,000 MB/s but PCIe remains the bottleneck. The actual clock is `TO_BE_VERIFIED_IN_G2/G3`; neither value is assumed here.

## PCIe/XDMA assumptions

The accepted Gen1 host evidence observed MaxPayload 256 bytes and MRRS 512 bytes. With a 256-byte payload, one 4 KiB record can be carried in sixteen maximum-payload transactions. A simplified 20-byte-per-TLP packet overhead would give `256/(256+20)=92.75%` before DLLP, flow-control, replay, alignment, descriptor, DMA-engine, and host effects. The real mix must be captured later.

Planning factors below are deliberately explicit and multiplicative. They are not measurements:

| Factor | Planning case | Conservative sensitivity | Includes |
|---|---:|---:|---|
| PCIe transaction/data-link efficiency | 82% | 75% | TLP headers/LCRC/framing, DLLP/ACK/flow control, replay allowance |
| XDMA/descriptor efficiency | 96% | 94% | descriptor fetch/completion, engine gaps; assumes large host buffers rather than one descriptor per record |
| AXI producer efficiency | 95% | 92% | arbitration/prefetch gaps and `TREADY` stalls |
| Record useful fraction | 93.75% | 93.75% | 3,840 useful bytes in 4,096 transported bytes |
| Host-copy/application efficiency, if inside the measurement path | 92% | 90% | reader scheduling, buffer handoff/copy/parser work |

The planning product is:

```text
500 * 0.82 * 0.96 * 0.95 * 0.9375 * 0.92 = 322.506 MB/s useful
```

The conservative sensitivity is:

```text
500 * 0.75 * 0.94 * 0.92 * 0.9375 * 0.90 = 273.628 MB/s useful
```

The second case misses the requirement. This is why G1 freezes an architecture but does not claim throughput feasibility as a measured PASS.

## Per-channel and buffer planning

At an equal split, each channel contributes 144 MB/s useful and 153.6 MB/s record bytes. A four-record, 16 KiB private ring holds approximately:

```text
16384 / 153,600,000 = 106.7 microseconds
```

Two rings contain 32 KiB total and the same approximately 106.7 microseconds at the aggregate 307.2 MB/s target. This absorbs short scheduler/host gaps only; it cannot absorb millisecond-scale host starvation.

## Efficiency controls

Later implementation and host tests shall:

- keep one 4 KiB record per AXI packet and avoid partial `TKEEP`;
- submit multi-megabyte host reads with several buffers outstanding;
- avoid an interrupt per record; IRQ0 is advisory/edge-of-nonempty only;
- keep the scheduler work-conserving and hide RAM latency with prefetch;
- report MaxPayload, MRRS, negotiated speed/width, AER/replay/recovery events, and CPU scheduling conditions;
- count record bytes and useful bytes separately; and
- report host-copy throughput separately when a copy is not intrinsic to the acceptance boundary.

If host-copy efficiency is 90%, the pre-copy link-to-record/payload chain must reach `57.6%/0.90 = 64.0%`. Without host copy, the universal minimum remains 57.6%.

## G8 boundary

No value in this budget is acceptance. G8 must measure at least 288 MB/s of host-received useful payload over the declared interval with two active channels, zero dropped bytes/records, zero lost frames, zero FIFO overflow, zero DMA error, and zero PCIe reset/recovery events.
