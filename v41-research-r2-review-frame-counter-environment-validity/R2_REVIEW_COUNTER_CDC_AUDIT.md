# R2 Review — Counter and CDC Audit

## Verdict

`PASS_SOURCE_LEVEL — COHERENT_SINGLE_WORD_DESTINATION_SNAPSHOT; TORN_READ_REJECTED`

The 25-versus-26 result is not evidence of a torn asynchronous counter. The frame counter crosses through a held bundled-data request/ack mailbox and is exposed as one registered 32-bit MMIO word. A read near an event can legitimately observe the old or new complete value; that ordinary endpoint choice is exactly the one-event sampling quantization under review.

## Source basis

The clean exact-C3/R1i tree at commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`, was inspected read-only.

Key source bindings:

| Source | SHA-256 |
|---|---|
| `rtl/record/bt656_record_producer.sv` | `96ECA58AC2FE6D9A2E0A390076FA02370B85409F1F1353CB9F41784D2ED363EE` |
| `rtl/record/capture_mailbox.sv` | `91A55EC1DEE546F026E3DC92F04A788A779F8A3F8D9D3D8DABEF08F089CA3FF5` |
| `rtl/video/video_capture.sv` | `7DFB7253C6649885665DB8449E33CE2F31D584811586DAEAA746DE04DF4AFFC9` |
| `rtl/top/ahd_capture_top_xdma.sv` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| `rtl/v41/control_status_regs.sv` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` |
| `scripts/v41/r1i_build.tcl` | `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F` |

C1 and C2 bind the same frame/CDC sources; their candidate-specific RTL change is outside this path.

## Frame counter source domain

`frame_seq_v` is a 32-bit counter in `nvp_clk`. In steady state it increments at the vertical-blank-to-active SAV transition (`bt656_record_producer.sv:276-295`) and resets at lines 157-170 under the video/NVP application reset and FPGA reconfiguration. The reset branch initializes `prev_sav_v=1` at line 173, so the first valid post-reset `H=0,V=0` SAV increments even without an observed `V=1` SAV. That initial absolute count cancels from a later T1−T0 window unless reset occurs inside it. Top-level NVP application reset is derived at `ahd_capture_top_xdma.sv:403-410`, with PCIe user reset incorporated in `video_capture.sv:67-97`. The frame counter is not cleared by an MMIO command or a dedicated video-lock edge.

## Bundled-data mailbox crossing

The frame counter is not Gray-coded because it is not presented as a continuously changing, unqualified asynchronous bus.

`capture_mailbox.sv` implements this sequence:

1. source logic captures the entire 324-bit telemetry bundle, including `frame_seq_v` in bits `[131:100]`;
2. the source holds that bundle stable;
3. a request toggle crosses through two synchronizer stages;
4. the destination captures the held bundle as one PCIe-domain register set;
5. an acknowledgement toggle crosses back through two stages before the source may replace the bundle.

This is a coherent bundled-data handshake. It prevents a mixed-bit frame-counter value from being assembled during a multi-bit transition.

## MMIO atomicity

`control_status_regs.sv` exposes frame sequence at byte offset `0x0060` as one registered 32-bit AXI/MMIO response. The host executes one four-byte little-endian `pread` for the word. There is:

- no low/high word split;
- no two-read software reconstruction;
- no host-triggered partial snapshot;
- no opportunity for a conventional torn 64-bit read.

A read coincident with a coherent mailbox update may return either the previous or the next complete 32-bit value. That is valid discrete-event sampling, not tearing.

## VCLK and SAV crossings

The VCLK edge counter and the counter internally named `active_sav_candidate_count` use Gray encoding plus two-stage synchronization before MMIO exposure. The latter increments every valid `H=0` SAV regardless of `V`, so this report calls it the all-SAV counter. Each host rate uses that counter's own before/after `pread` midpoint timestamps.

The three counters are not captured by one simultaneous host-triggered snapshot; they are read sequentially during each inventory. This does not corrupt an individual rate denominator, but cross-counter comparisons have microsecond-scale skew and are corroborative rather than phase-exact.

## Implemented constraints and routed-build evidence

The exact `cdc.xdc` applies `6.000 ns` datapath-only maximum delay and `3.000 ns` bus-skew constraints to the held status bundle (`cdc.xdc:6-14`) and to the Gray diagnostic buses (`cdc.xdc:20-27`); request/ack first stages receive the intended false paths at lines 16-18. The build flow includes and hashes the XDC, hard-gates route/timing/DRC (`r1i_build.tcl:243-283`), emits `CDC.rpt`, and fails on CDC rows classified `Critical` or `Unknown` (`r1i_build.tcl:284-290`) before the provenance-bound bitstream gate (`r1i_build.tcl:293-309`).

The exact routed C3 build bound to bitstream `F6A6905D…D3C6` produced:

- `CDC.rpt` SHA-256 `0B2FD64A523737626AF19FFE4EFB6ABF3511CA87366BC33A716F514DDF88C442`; its lines 234-265 list held-bundle bits 100-131, which contain `frame_seq_v`, as `CDC-15` paths with `Max Delay Datapath Only`, and it contains no `Critical` or `Unknown` CDC row;
- `PRE_BITSTREAM_HARD_GATE.txt` SHA-256 `D8C9E3729887616315B737BD92C167A8EF9CDF3B296F27960E23BF8FC8FEA4C3`, with synthesis/place/route/DRC pass, zero unrouted/partially routed nets, `WNS=0.617 ns`, and `WHS=0.036 ns`.

Exact C1 and C2 builds bind the same frame/CDC sources and constraints. Their CDC/pre-gate SHA-256 pairs are respectively `16EBBC29F622617BB79DB5F3FFEFDF91A76B1DE46D00CEED56BB2DB25CA19E33` / `60E1967BC96DC5D189FADC0D26B985EC33C2F287D080F9B989E3217303AD8E12` and `073F7027C888B08DDDC3248947EBF46FF9A03FC9B2E81827CEB9F9E328728B22` / `D81482573C590B3915F71E723DAA00965F74F77C38FA86612A76F36A46799CDF`; both pre-gates report the same positive timing margins and route/DRC pass.

## Reset, stale event, and wrap analysis

- Reprogramming resets FPGA configuration/state.
- NVP/PCIe application reset resets `frame_seq_v`.
- No counter state continues coherently across Formal restoration and candidate programming.
- A stale absolute pre-window count cancels in `(T1-T0) mod 2^32`.
- A frame event that occurs at a T0/T1 boundary may be included or excluded, producing a legitimate one-count difference.
- Host modulo arithmetic handles a single 32-bit wrap; at 25 events/s the natural wrap period is about 5.45 years.

There is no reset behavior that selectively explains the high branch: C1, C2, and C3 occupy it, and C2/C3 also occupy the low branch.

## Observational checks

Across all retained runs:

- frame deltas are only 0, 25, or 26;
- zero frame/SAV deltas coincide with C0 video absence;
- video-positive SAV and VCLK counters remain monotonic and physically plausible;
- no large carry-transition error, wrap anomaly, regression, or random multi-bit magnitude occurs;
- independent raw recalculation reproduces every printed rate.

## Rejected explanations

| Hypothesis | Result | Basis |
|---|---|---|
| split-word torn host read | `REJECTED` | one registered 32-bit word and one four-byte `pread` |
| unqualified asynchronous multibit crossing | `REJECTED` | held bundled-data request/ack mailbox |
| explicit inclusive software `+1` | `REJECTED` | source formula is modulo delta only |
| counter reset between T0/T1 | `REJECTED` | monotonic raw values and normal SAV/VCLK evolution |
| legitimate old/new endpoint value | `CONFIRMED PLAUSIBLE MECHANISM` | coherent discrete-event sampling at boundaries not phase-locked to frame events |

## Residual limitation

No external event timestamp stream was captured, so the exact physical phase of each boundary event cannot be reconstructed. That limitation affects absolute physical-rate certainty, not the source-level coherency finding.

## Conclusion

CDC or host read tearing does not explain the observed bimodality. The evidence supports coherent whole-counter sampling plus ordinary one-event endpoint quantization. The frozen approximately one-second estimator remains under-resolved for a `±0.10 Hz` clean gate even when the CDC path behaves exactly as designed.
