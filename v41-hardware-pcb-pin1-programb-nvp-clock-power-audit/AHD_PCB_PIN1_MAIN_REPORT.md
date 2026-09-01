# AHD PCB-PIN-1 PROGRAM_B and NVP Clock/Power Architecture Audit

Audit date: 2026-09-01  
Primary workspace: `C:/FPGA/FPGA_AHD`  
Primary source revision: `be94f88ee8d179f12928ab791bdae27c22cd1762`  
Audit mode: offline/read-only architecture audit

## Executive decisions

| Item | Decision |
|---|---|
| Exact Vivado part | `xc7a35tcsg325-2` |
| PROGRAM_B historical loop | `PARTIAL` |
| PROGRAM_B self-reset | `REMOVE` |
| Replacement FPGA GPIO | `NO` |
| Internal self-reconfiguration | `SUPPORTED` |
| D13 27 MHz input | `VALID` |
| A14 NVP clock output | `VALID_WITH_CONSTRAINT` |
| Clock forwarding | `ODDR/OLOGIC_RECOMMENDED` |
| Glitch-free clock gating | `FEASIBLE_WITH_CONSTRAINTS` |
| A14 preconfiguration state | `WEAK_PULLUP_EXPECTED` |
| NVP CLK external pull-down | `REQUIRED` |
| FPGA-gated 27 MHz to NVP | `APPROVE_WITH_CHANGES` |
| I2C pull-up domain | `NVP_SWITCHED_3V3_RECOMMENDED` |
| NVP power-domain review | `PASS_WITH_CONSTRAINTS` |
| PCB routing points 10-11 | `APPROVE_WITH_CHANGES` |

The board may proceed without routing the T12-to-PROGRAM_B loop and without finding a replacement GPIO. The D13/A14 NVP clock architecture may proceed only with the pin-conflict, passive-safe-state, power-domain, clock-gating, and datasheet/SI closure actions stated below.

`FPGA_GATED_27MHZ_TO_NVP = APPROVE_WITH_CHANGES`

## 1. Device and electrical identity

The governed project declares the exact target `xc7a35tcsg325-2` in `scripts/project_common.tcl`. Vivado recognizes that exact Artix-7, CSG325, speed-grade -2 part.

The designer-provided board rail assignments and audit classifications are:

- `VCCO_14 = 3.3V_CONFIRMED`;
- `VCCO_15 = 3.3V_CONFIRMED`; and
- `VCCO_34 = 3.3V_CONFIRMED`.

D13 and A14 are both HR I/O in Bank 15, so a 3.3 V LVCMOS input at D13 and a 3.3 V LVCMOS output at A14 are legal when the confirmed VCCO_15 rail is present. Permanent FPGA 3.3 V and switched NVP 3.3 V remain separate power domains despite their equal nominal voltage.

## 2. Point 10: PROGRAM_B prototype loop

`PROGRAM_B historical loop = PARTIAL` because the task supplies the prototype schematic path `FPGA user output -> T12 -> PROGRAM_B_0`, but accessible implementation evidence does not retain its signal name. Current RTL/XDC contains no loop. A pre-Git routed report shows P10 as dedicated `PROGRAM_B_0` and T12 as unused Bank-14 `IO_L22P_T3_A05_D21_14`, with its signal and direction blank. No current product or recovery block depends on T12.

PROGRAM_B is an active-low dedicated configuration-reset input. Its assertion clears FPGA configuration and starts a complete reload after release; it is not an ordinary RTL reset. AMD specifies a PROGRAM_B pull-up of no more than 4.7 kOhm to VCCO_0 and a minimum low pulse of 250 ns.

A direct FPGA-output feedback path is not robust. Once reconfiguration starts, GTS makes the driving user I/O high-Z, so the feedback pulse is self-terminating and its duration cannot be assumed to satisfy the minimum. A credible external implementation would need low-only/open-drain drive, the mandatory pull-up, a tolerance-proven pulse-stretching/one-shot/supervisor mechanism, and contention/boot-loop protection.

Artix-7 supports the cleaner ICAPE2/WBSTAR/IPROG route for intentional reconfiguration from a working image, including MultiBoot/fallback architecture. This does not replace external PROGRAM_B service access or an external supervisor when recovery must work without any live image.

Decision:

`PROGRAM_B_SELF_RESET = REMOVE`

Preserve the independent dedicated PROGRAM_B pull-up and service/recovery path. No T12 replacement is required.

PROGRAM_B and PUDC_B are independent. PROGRAM_B controls configuration reset/reload. PUDC_B controls SelectIO pull behavior before and during configuration.

## 3. D13 input and A14 output

| Pin | Bank | Exact I/O name | Site | Use | Result |
|---|---:|---|---|---|---|
| D13 | 15 | `IO_L11P_T1_SRCC_15` | `IOB_X0Y78` | 27.000 MHz LVCMOS33 input | `VALID` |
| A14 | 15 | `IO_L8N_T1_AD10N_15` | `IOB_X0Y83` | 27.000 MHz LVCMOS33 NVP clock output | `VALID_WITH_CONSTRAINT` |

D13 is a single-region clock-capable P-side input. Its SRCC role provides legal regional BUFR access within its clock region and legal routing through IBUF to BUFG and fabric; prior PCB-PIN-0 routed evidence already established the corrected D13-to-BUFG route without a dedicated-clock exception.

A14 is an ordinary user output after configuration and has the paired OLOGIC/ODDR resource needed for deterministic forwarding. Its `AD10N` configuration-bus multifunction role is not consumed by the reviewed Master-SPI M[2:0]=001 plan. The active v40 XDC presently assigns A14 to `vdo1_data[0]`; therefore A14 can become NVP SYS_CLK only after the accepted PCB-PIN-0 channel-1 remap frees it. This audit does not alter that XDC.

## 4. Required 27 MHz forwarding architecture

Use:

```text
oscillator -> D13 IBUF -> continuous BUFG -> internal clk27
enable request -> two-stage clk27 synchronizer -> registered run
clk27/run -> A14 ODDR (CE=1, D1=run, D2=0, INIT=0) -> OBUF -> NVP SYS_CLK
```

This uses the dedicated OLOGIC output path. It does not toggle a fabric GPIO and does not combinationally AND a clock.

The later implementation contract is:

- synchronize the enable request to the continuously running 27 MHz domain;
- update only a registered run state;
- keep ODDR D2 at zero and CE enabled;
- initialize run and Q low;
- never asynchronously reset the ODDR during a high pulse;
- acknowledge stop only after A14 reaches and remains low;
- keep NVP reset asserted across clock start and stop; and
- apply complete primary/generated-clock and output timing constraints.

With that contract, start begins on a defined rising edge, every high interval ends on a falling edge, stop permits only a final complete pulse, and disabled output remains low. A BUFGCE with synchronized CE and fixed ODDR D1=1/D2=0 is a legal alternative, but unsynchronized CE and dynamic ODDR CE alone are not approved low-forcing mechanisms.

`GLITCH_FREE_CLOCK_GATING = FEASIBLE_WITH_CONSTRAINTS`

## 5. A14 configuration-stage state

The reviewed PCB proposal holds J18/PUDC_B low with 1 kOhm. UG470 states that PUDC_B low enables internal weak pull-ups on SelectIO during power-up/configuration. A14 is therefore high-Z under GTS but weakly pulled toward VCCO_15; it must not be assumed low.

`A14_PRECONFIG_STATE = WEAK_PULLUP_EXPECTED`

To guarantee NVP SYS_CLK low until intentional start, fit an external A14/NVP-clock pull-down or an equivalent powered-off isolating/low-forcing circuit. The value must satisfy the NVP input-low threshold against the Artix-7 330 microamp worst-case configuration pull-up plus leakage. It must also preserve A14 VOH, duty cycle, rise/fall time, SI margin, and the unpowered-NVP current limit. No exact resistor is approved without the NVP electrical data and final topology analysis.

`NVP_CLK_EXTERNAL_PULLDOWN = REQUIRED`

PUDC_B low also applies configuration pull-ups to RST, SDA, SCL, IRQ, EN_VDD1x, and EN_VDD3x. Each requires an explicit passive default or power-off isolation decision.

## 6. NVP power and reset control

The target safe off state is:

```text
EN_VDD1x = INACTIVE (LOW under the reviewed active-high interface assumption)
EN_VDD3x = INACTIVE (LOW under the reviewed active-high interface assumption)
RST_B     = LOW, or high-Z held LOW
CLK       = LOW and not toggling
SDA/SCL   = high-Z
IRQ       = no permanent-domain pull into the unpowered NVP
```

The active XDC routes `EN_VDD1x` to A9 and `EN_VDD3x` to A10. The present read-only RTL hard-wires both rail enables high and does not implement deterministic rail shutdown. Its 500 ms reset hold and 1.5 s I2C start are implementation constants, not proven codec requirements. A later governed RTL/XDC change is required after architecture acceptance.

The signal names/current RTL imply active-high rail-enable controls and active-low reset, but actual regulator/load-switch polarity and thresholds remain unverified, as do internal pulls, reverse-current behavior, discharge, and power-good behavior. Confirm the power-device polarity first. Deterministic FPGA control then requires future RTL plus passive defaults that hold A9/A10 at the confirmed inactive level before configuration ownership (LOW if active-high) and dominate any opposing FPGA configuration pull and leakage.

Driving reset high while the NVP is unpowered is not approved because its clamp/Ioff behavior is unavailable. Hold it asserted low, or high-Z with a passive low default. This is `REQUIRES_NVP_DATASHEET_CONFIRMATION`.

## 7. Startup and shutdown

The required startup order is:

1. Passive defaults keep both enables inactive (LOW under the reviewed active-high assumption), reset and clock low, and SDA/SCL high-Z.
2. FPGA reaches EOS and owns the controls while retaining those safe states.
3. Enable NVP rails in the NVP/regulator-required order.
4. Wait for power-good or validated stabilization.
5. Start 27 MHz with a clean complete first pulse.
6. Wait the required clock-before-reset interval.
7. Release NVP reset.
8. Wait the required reset-to-I2C interval.
9. Confirm switched-domain pull-ups and idle bus, then initialize over I2C.

The required shutdown order is:

1. Finish/abort I2C and release SDA/SCL high-Z.
2. Assert reset while rails and clock are still valid.
3. Observe required reset assertion time.
4. stop the forwarded clock after a complete final pulse and hold A14 low.
5. Disable rails in the NVP/regulator-required order.
6. Confirm/discover discharge and retain all passive off states.

The logical ordering is `DEFINED`. Exact rail order and reset/clock/I2C delays are `FROM_NVP_DATASHEET_REQUIRED`; ramp and discharge without reliable power-good are `TO_BE_MEASURED`. No unsupported constants are created by this audit.

## 8. I2C and other power-domain crossings

`I2C_PULLUP_DOMAIN = NVP_SWITCHED_3V3_RECOMMENDED`

Switched-domain pull-ups remove the normal SDA/SCL high source when NVP 3.3 V is off and reduce partial-powering risk. The current IOBUF architecture is correctly low-only/open-drain: each output data input is tied low and its tri-state control releases the line. Before the switched rail exists, both lines must remain high-Z, no active-high drive is allowed, and no transaction or bus-recovery clock may start.

This choice does not by itself remove the PUDC_B-low configuration pull-ups. Before schematic release, either disable those configuration pulls, prove NVP Ioff/fail-safe limits for every affected net, or add powered-off isolation/translation. Level translation is conditional rather than proven mandatory because the NVP power-off specifications are unavailable.

The full RST/CLK/SDA/SCL/IRQ/enable review is in `PCB_PIN1_NVP_POWER_DOMAIN_MATRIX.csv`. RST, CLK, SDA, and SCL are safe only with their listed constraints; IRQ remains uncertain pending output-type/Ioff evidence; both rail enables require a passive-default change relative to the current implementation.

## 9. PCB clock SI provisions

| Provision | Classification |
|---|---|
| source-series resistor footprint close to A14 | `RECOMMENDED` |
| NVP SYS_CLK pull-down footprint | `RECOMMENDED`; stuffing is required for guaranteed low |
| low-capacitance, low-stub SYS_CLK test access | `RECOMMENDED` |

The local requirements record prior downstream clock degradation and warn against unreviewed load. Select the resistor values and probe topology only after final stackup, trace, driver slew/strength, NVP receiver, pull-down, and IBIS/SI analysis. Verify amplitude, duty cycle, rise/fall time, and receiver margin on the first routed board.

## 10. Isolated Vivado legality check

`VIVADO_SANDBOX = PASS`

Vivado v2025.2 synthesized, placed, and routed an isolated `xc7a35tcsg325-2` path from D13 IBUF through a synchronized BUFGCE/BUFGCTRL and fixed-data ODDR to the A14 OBUF. The placed chain was:

```text
D13 / IOB_X0Y78
  -> BUFGCTRL_X0Y16
  -> ODDR / OLOGIC_X0Y83 / OLOGICE2.OUTFF
  -> A14 / IOB_X0Y83
```

All six routable nets were fully routed. DRC reported zero errors, zero critical warnings, and one expected minimal-sandbox `CFGBVS-1` warning because configuration-bank properties were not imported; the read-only product configuration XDC contains those properties. No bitstream command was present.

The sandbox uses the legal fixed-ODDR/BUFGCE alternative, not the exact preferred continuous-BUFG/dynamic-D1 gate. It proves pin and resource legality; later governed implementation must still verify the preferred enable contract and full timing/SI behavior. Details and raw reports are in `PCB_PIN1_VIVADO_SANDBOX_REPORT.md` and `raw/vivado_sandbox/`.

## 11. Required changes before design release

Approval of point 11 is conditional on all of the following:

1. Free A14 by adopting the compatible channel-1 video remap.
2. Keep D13 as the sole oscillator destination and use legal clock routing.
3. Implement ODDR/OLOGIC forwarding with phase-defined start/stop; no fabric-toggled output.
4. Guarantee A14 low before configuration ownership using a validated external pull-down or equivalent circuit.
5. Guarantee both rail enables and reset safe before/during configuration.
6. Put I2C pull-ups on switched NVP 3.3 V and resolve all remaining PUDC/off-domain injection paths.
7. Confirm NVP SYS_CLK, reset, I2C, IRQ, rail sequencing, and powered-off I/O limits from the actual datasheet.
8. Confirm power-switch/regulator polarity, thresholds, isolation, PG, ramp, and discharge behavior.
9. Complete final clock SI and product-project timing/DRC validation after implementation.

These are design-release conditions, not authorization to edit RTL, XDC, PCB, or SSOT in PCB-PIN-1.

## 12. Audit integrity and SSOT

The primary repository began and ended this audit at the same tracked revision, with no tracked or index change introduced by PCB-PIN-1. Pre-existing untracked `.codex_tmp/` and `reports/` directories were not touched. No source, active XDC, PCB, product-state/SSOT, G-track, or R-track state was modified. No DUT was accessed, FPGA programmed, or bitstream produced.

`PROJECT_STATE_REV` remains unchanged. Future accepted decisions and their source/META impact are listed in `PCB_PIN1_SSOT_IMPACT.md`.

## Overall architecture gate

Engineering gate = `PASS`

Point 10 = `REMOVE`; routing may proceed without a T12 replacement.

Point 11 = `APPROVE_WITH_CHANGES`; route only with the nine conditions above captured in the schematic/PCB review.

First blocker = `NONE`. Missing NVP/regulator data and SI/component selection are explicit pre-release closure actions, not grounds to preserve the unsafe prototype loop or reject the legal D13/A14 architecture.
