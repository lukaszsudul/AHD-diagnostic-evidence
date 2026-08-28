# AHD v41 G2A Clock Receipt

## Gate status

`SOURCE/REQUEST GATE: PASS`

`FIRST CLEAN ROUTED OBSERVATION: 62.500 MHz / 16.000 ns`

`FINAL CLEAN R2 CLOCK GATE: PASS — USER_CLK=62.500 MHz; AXI_ACLK=62.500 MHz`

The final G2A source identity is commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`. Clean R2 completed with `SOURCE_POST_BUILD=PASS`, `SOURCE_TO_BIT_PROVENANCE=PASS`, and `CLOCK_GATE=PASS`. Its routed timing object binds both the protected NVP/autoinit consumers and the AXI bridge to `userclk1` at exactly `16.000000 ns`, or `62.500000 MHz`.

## Frozen source expectations

| Evidence | Value | Disposition |
|---|---:|---|
| XCI requested `CONFIG.axisten_freq` | `62.5` MHz | REQUIRED/PRESERVED |
| Common Tcl read-only invariant | `CONFIG.axisten_freq=62.5` | REQUIRED/PRESERVED |
| Qualified top timing constant | `NVP_AUTOINIT_CLK_HZ=62,500,000` | PROTECTED/PRESERVED |
| Qualified top clock binding | `autonomous_clk = axi_aclk` | PROTECTED/PRESERVED |
| Qualified routed expectation | approximately `62.5` MHz / `16.000 ns` | REQUIRED |

## Metadata ambiguity and authoritative resolution

Static XCI inspection is internally inconsistent and is not used to infer the implemented frequency:

- `ip/v41/xdma_v41_m1.xci:22` requests `axisten_freq=62.5`;
- XCI interface metadata near line `1393` reports `axi_aclk FREQ_HZ=125000000`;
- AXIS interface metadata near lines `1512` and `1539` reports `100000000`.

These metadata values existed in the qualified source representation and do not prove routed behavior. Clean R2 therefore recorded:

- generated clock metadata after IP generation;
- `report_clocks` output;
- timing clock objects associated with `user_clk` and `axi_aclk` pins/nets;
- implemented period and calculated frequency;
- clock interaction/utilization results;
- resolved CDC max-delay and bus-skew constraints.

The routed timing-object result below resolves the ambiguity in favor of the qualified `62.5 MHz` expectation. No interface-metadata frequency was used as implementation proof.

## Mandatory stop condition

If routed/effective `user_clk` or `axi_aclk` is not the qualified 62.5 MHz expectation, the result is `BLOCKED — GEN2_CHANGED_APPLICATION_CLOCK`. No NVP timing constant will be rescaled and no R1i RTL will be retimed.

## Routed result

### First clean routed attempt — reference only

The first clean attempt reached a fully routed design before its CDC harness stopped the flow. Its routed clock evidence is internally consistent with the frozen expectation:

| Evidence | First-run result | Disposition |
|---|---:|---|
| `<SOURCE_ROOT>_BUILD_EVIDENCE\CLOCKS.rpt:36` | `userclk1`, period `16.000 ns` | `62.500 MHz`, expected |
| `<SOURCE_ROOT>_BUILD_EVIDENCE\CLOCKS.rpt:88-90` | generated `userclk1` from XDMA MMCM `CLKOUT2` | expected generated-clock lineage |
| `<SOURCE_ROOT>_BUILD_EVIDENCE\CLOCK_UTILIZATION.rpt:60` | BUFG `userclk1`, period `16.000 ns`, 18,246 clock loads | routed distribution present |
| `<SOURCE_ROOT>_BUILD_EVIDENCE\CLOCK_UTILIZATION.rpt:80` | MMCM `CLKOUT2`, source period `16.000 ns` | matches BUFG clock |
| `<SOURCE_ROOT>_BUILD_EVIDENCE\CHECK_TIMING.rpt:18-25,31-51` | `no_clock=0`, `unconstrained_internal_endpoints=0`, `multiple_clock=0`, `generated_clocks=0` issues | clean clock-coverage reference |

Because `rtl/top/ahd_capture_top_xdma.sv` preserves `autonomous_clk = axi_aclk`, this routed `userclk1`/XDMA user-clock period is the expected physical clock for the AXI-Lite and protected autonomous NVP logic. No NVP timing constant was changed or rescaled.

### Final clean R2 result

| Evidence | Final clean R2 result | Disposition |
|---|---:|---|
| XCI request | `CONFIG.axisten_freq=62.5` | preserved |
| `G2A_CLOCK_OBJECT_RECEIPT.txt` clock-object count | `1` | exact routed application-clock object |
| Routed clock object | `userclk1` | expected |
| Period / waveform | `16.000000 ns` / `{0.000 8.000}` | expected |
| Routed frequency | `62.500000 MHz` | PASS |
| Effective XDMA `user_clk` | `62.500000 MHz` | PASS |
| Effective `axi_aclk` | `62.500000 MHz` | PASS |
| Source pin | XDMA PIPE MMCM `mmcm_i/CLKOUT2` | generated-clock lineage proven |
| Protected NVP/autoinit clock pins | `2247`, all on `userclk1` | PASS |
| AXI bridge clock pins | `110`, all on `userclk1` | PASS |
| `CLOCKS.rpt:36,88-90` | `userclk1`, `16.000 ns`, generated from `CLKOUT2` | PASS |
| `CLOCK_UTILIZATION.rpt:60,80` | BUFG/MMCM distribution at `16.000 ns` | PASS |
| Missing-clock count | `0` | PASS |
| Unconstrained internal endpoints | `0` | PASS |
| Bus-skew constraints | `3` met, `0` violations | PASS |
| Clock gate | `PASS` | PASS |

Final effective user clock: `62.500000 MHz`.  
Final effective AXI clock: `62.500000 MHz`.  
Final clean R2 clock gate: `PASS`.

`BLOCKED — GEN2_CHANGED_APPLICATION_CLOCK` did not occur. No R1i timing constant was changed or rescaled.
