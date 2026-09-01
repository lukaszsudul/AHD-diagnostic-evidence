# AHD PCB-PWR-0 PUDC_B / Flash / Peripheral Back-Power Safety Audit

## Gate result

`ENGINEERING_GATE = PASS`

PASS means the requested analysis is adequate and the PUDC decision has been reduced to an implementable, testable architecture. It does not mean that the current Flash/VCCO topology has electrical signoff, that the archived Rev 0.1 schematic is the released A35T schematic, that every powered-off limit has been proven, or that PUDC_B=HIGH has already been tested on AHD hardware. Routing release remains blocked on the applicable designer actions.

The recommended PCB disposition is:

- `PUDC_B_RECOMMENDATION = CONFIGURABLE_0R_OPTION`
- default assembly: PUDC_B pulled HIGH to **VCCO_14** through one documented 0-ohm (or AMD-compliant <=1 kOhm) population option;
- alternate assembly: mutually exclusive pull to GND, normally DNP;
- never allow both options to be populated;
- provide explicit external safe states for NVP enables, reset, clock, and switched-domain I2C; and
- close the independent Flash-to-unpowered-VCCO issue before declaring the power sequence safe.

`PUDC_CONFIGURABLE_OPTION = RECOMMENDED`

## Evidence boundary

The exact FPGA used by the active project and by the Vivado device-database check is `xc7a35tcsg325-2`: device `xc7a35t`, package `csg325`, speed grade `-2`. No Artix-7 substitute was used.

The active FPGA repository contains no PCB source, no Flash part selection, no M[2:0] strap description, and no product `SPI_BUSWIDTH` property. The only locally available board source is an archived AHD Rev 0.1 design dated 2020-09-10. It uses an XC7A15T in the same CSG325 package and is therefore used only as `HISTORICAL_ARCHIVED_BOARD_EVIDENCE`. Configuration ball functions were rechecked against the exact A35T device database. Retention of the old rail and Flash topology on the routing-final A35T/NVP board requires schematic confirmation.

The active XDC is also not the routing-final PCB-PIN mapping. It still assigns A14 to VDO1, T17/T18 to SCL/SDA, and U/V16/17 to MPP. PCB-PIN-0/1 instead frees A14 for SYS_CLK, moves SCL/SDA to N17/M17, and reuses several MPP balls for channel 2. Every mapping statement in this audit is labeled active, proposed, or archived; no XDC was changed.

Authoritative previous evidence was read at the required commits:

- PCB-PIN-0: `a7db236b56340095f3521ec195d2a3b49d10f956`;
- PCB-PIN-1: `6b39355b5b20f14242158c1ecd7a1c0487f09b33`.

PCB-PIN-0 did not approve a J18 resistor; it recorded `J18_PULLDOWN_REVIEW=NEEDS_SCHEMATIC_CONTEXT`. PCB-PIN-1's later PUDC_B LOW / 1 kOhm-to-GND assumption is reviewed here rather than treated as frozen.

Local AMD DocNav metadata identifies UG470 and DS181, but the actual local PDFs were not available. PUDC_B semantics and pull-current ranges are therefore supported by the locally published PCB-PIN-1 transcription of UG470 v1.17 and DS181 v1.27.1. A non-durable secondary extraction suggests Figure 2-14 is the 7-series Master SPI x4 reference topology, and the designer reports its PUDC_B connection is GND; both figure details require the original UG470 PDF for authoritative confirmation. Table 2-4 separately allows HIGH to VCCO_14 or LOW to GND, so the reported drawing is not evidence that grounding is mandatory. The exact DS181 `TVCCO2VCCAUX` condition could not be independently read offline and is explicitly left for document confirmation.

## Configuration architecture found

The archived AHD configuration sheet labels `M[2:0]=001` and `Master SPI`. The physical straps are M0=1, M1=0, M2=0; M2 also has an FTDI-controlled override path whose reset state must be checked. The archived Flash is `S25FL064L`, powered at 3.3 V, with all four DQ paths wired. Historical A15T project evidence used `BITSTREAM.CONFIG.SPI_BUSWIDTH 4` and successfully programmed an x1/x2/x4-capable cfgmem part.

This proves historical A15T Master-SPI-x4 build/programming evidence, not autonomous cold boot and not the active A35T product width. The active repository has no `SPI_BUSWIDTH` setting. Accordingly:

`CONFIGURATION_MODE = MASTER_SPI (M[2:0]=001 historical/reported; final straps require confirmation)`

`CURRENT_A35T_SPI_WIDTH = UNRESOLVED`

It would be incorrect to infer x1, x2, or x4 merely because the Flash and wiring are quad-capable.

## PUDC_B result

With PUDC_B LOW, ordinary/inactive SelectIO are globally three-stated during configuration and weak pull-ups are enabled after the relevant FPGA power is valid and during configuration. This is high-Z **plus a weak pull-up**, not a pull-down. Dedicated configuration pins and pins actively used by the selected configuration mode retain their configuration functions.

With PUDC_B HIGH, those global SelectIO configuration pull-ups are disabled. Ordinary/inactive SelectIO remain high-Z; HIGH does not create internal pull-downs. Dedicated and actively used configuration pins remain functional. Critical user nets therefore require external passive defaults or isolation.

The related HDMI prototype observation—PUDC_B LOW producing about 1.2 V on a nominally off ADV 3.3 V rail and HIGH producing about 0 V—is classified `EXPERIMENTAL_EVIDENCE_FROM_RELATED_BOARD`. It is not direct AHD proof. The mechanism is credible for AHD because many FPGA-connected NVP inputs can simultaneously receive weak pulls from powered FPGA VCCO while NVP VDD3D is absent, and the available NVP datasheet does not specify fail-safe powered-off I/O. The aggregate AHD risk is `HIGH`; an exact current total would be false precision.

## Option decision

PUDC_B LOW has a useful default-high behavior for otherwise floating ordinary SelectIO, but it applies indiscriminately. On AHD it can oppose safe-low enable, reset, and SYS_CLK defaults and can feed unpowered NVP/peripheral inputs. External pull-downs would need to be sized against the worst-case FPGA pull-up current, leakage, receiver thresholds, drive-current loss, and 27 MHz signal integrity.

PUDC_B HIGH removes that global source and permits net-specific safe states. It makes the intended A14 condition clean: unconfigured FPGA -> A14 high-Z -> external pull-down -> NVP SYS_CLK LOW. It does not by itself make the Flash power architecture safe, because the permanent Flash rail and permanent Flash pull-ups are external sources.

`PUDC_HIGH_FLASH_BOOT = SUPPORTED_WITH_EXTERNAL_PULL_REQUIREMENTS`

This classification is architecture-level: the locally published UG470 Table 2-4 transcription defines HIGH as the supported state that disables SelectIO pulls. Exact pin classifications plus that SelectIO-specific wording support the engineering inference that active Master SPI pins continue their configuration roles. The result is conditional on correct mode straps, PROGRAM_B/INIT_B/DONE implementation, Flash deselect and WP/HOLD defaults, rail compatibility, and confirmation of the final schematic. Vivado has no property representing the board PUDC strap, so tool DRC cannot prove this electrical conclusion.

## Flash back-power result

The archived topology strongly corroborates the designer's report:

- Flash VCC is on PCIe-derived permanent `V_3.3V`;
- FCS_B/CS, DQ2/WP, and DQ3/HOLD each have a 4.7 kOhm pull-up to permanent `V_3.3V`;
- each reaches a Bank-14 configuration pad through 22 ohms;
- FPGA Bank 0/14/15/34 VCCO is a separate load-switched 3.3 V `Vcco` rail enabled by a VCCAUX-regulator POR relationship.

Thus there are three explicit passive high sources into Bank 14 while VCCO_14 can be 0 V or ramping: L15/FCS_B, J15/D02, and J16/D03. DQ1 can become an additional driven path if the permanently powered Flash is selected or otherwise drives before VCCO is valid. Neither pull-up resistance nor normal powered leakage proves powered-off pad safety. No authoritative A35T Ioff/powered-off-protection limit was available locally.

`CURRENT_FLASH_POWER_SEQUENCE = POTENTIAL_VIOLATION`

This is a routing gate, not a declaration of measured damage. It means the reported/archived topology cannot be signed SAFE until the final schematic, Flash behavior, AMD powered-off pad/injection limits, and rail timing are proven or the architecture is changed. PUDC_B HIGH does not close this path.

The designer-reported DS181 condition involving an approximately 2.625 V VCCO/VCCAUX relationship and an approximately 800 ms interval at 85 C was not promoted to an exact requirement because the authoritative DS181 page was not locally available. The direction of the inequality, applicability, voltage definition, duration, and temperature note must be transcribed from the applicable DS181 revision. The actual AHD VCCO/VCCAUX waveforms must then be compared. Flash pad injection is a separate question even if the rail-to-rail time requirement passes.

## NVP safe-state result

The NVP6134C Rev 1.0 local datasheet identifies RSTB as active low, SYS_CLK as a 27 MHz input, SDA/SCL as 3.3-V-tolerant digital pins, and IRQ only as an interrupt output. Its digital-input absolute maximum is expressed relative to VDD3D; it does not grant powered-off fail-safe operation. IRQ output type and powered-off behavior remain unknown.

For the default HIGH assembly:

- EN_VDD1x and EN_VDD3x: pull to their proven inactive state; use pull-downs only after active-high polarity is confirmed on the released regulator circuits;
- RSTB: pull low so NVP is held reset while off and during ramp; release only after power and clock are valid;
- A14/SYS_CLK: pull low; implement ODDR/OLOGIC with configured INIT/disable-low behavior;
- SDA/SCL: open-drain FPGA behavior and pull-ups to switched NVP VDD3D; high-Z while off;
- IRQ: no permanent-domain pull; if the NVP output is open-drain, pull to switched NVP VDD3D or isolate;
- VDO/VCLK: no FPGA-side bias; ensure NVP cannot drive them before FPGA VCCO is valid, or isolate;
- all off-domain controls: do not actively drive high into an unpowered NVP.

Switched I2C pull-ups alone are insufficient with PUDC_B LOW because the FPGA's configuration pull-ups remain an independent source.

## Prior-decision dispositions

`J18_PUDC_B_PLUS_1K_TO_GND = SUPERSEDED`

The low-only decision is replaced by a mutually exclusive configurable footprint with HIGH as the proposed default. This preserves an A/B test escape hatch at negligible PCB cost while preventing an undocumented dual-population state.

`27MHZ_D13_FPGA_A14_NVP = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`

The constraints are: free A14 through the PCB-PIN-0 remap, add a validated A14 pull-down, keep NVP off/reset until FPGA VCCO and configuration are valid, use ODDR/OLOGIC with disabled-low initialization, and validate 27 MHz SI/duty cycle.

`I2C_PULLUPS_TO_SWITCHED_NVP_VDD3X = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`

The constraints are: PUDC_B HIGH or proven isolation/fail-safe behavior, open-drain-only FPGA operation, no transaction while the NVP rail is off, and NVP-powered-off confirmation.

`IRQ_POWER_OFF_BEHAVIOR = REQUIRES_NVP_DATASHEET_CONFIRMATION`

The proposed 27 MHz oscillator's supply/output-enable domain is absent from the current source and final schematic evidence. If the oscillator can drive D13 while VCCO_15 is off, it creates the reciprocal powered-peripheral-to-unpowered-FPGA problem. The clock decision therefore also requires a VCCO-compatible sequenced oscillator rail, output high-Z/low until VCCO_15 is valid, or authoritative powered-off protection/isolation.

`D13_OSCILLATOR_POWER_DOMAIN = UNRESOLVED`

## Offline/tool result

An isolated Vivado 2025.2 sandbox targets `xc7a35tcsg325-2`, uses only D13/A14 plus configuration-voltage properties, and does not write a bitstream. PUDC_B is an external strap and is not modeled as a design property. Therefore a clean implementation/DRC result can establish only that the associated FPGA pin/configuration properties are tool-legal:

`PUDC_HIGH_VIVADO_LEGALITY = NOT_PROVEN`

The classification remains NOT_PROVEN even if the sandbox DRC is clean, because Vivado cannot validate the PUDC resistor, Flash power-off current, or NVP clamp paths.

## Mutation and safety declaration

- `FPGA_AHD_SOURCE_MODIFIED = NO`
- `ACTIVE_XDC_MODIFIED = NO`
- `SSOT_MODIFIED = NO`
- `DUT_ACCESSED = NO`
- `FPGA_PROGRAMMED = NO`
- `PRODUCT_BITSTREAM_GENERATED = NO`
- `G_TRACK_CHANGED = NO`
- `R_TRACK_CHANGED = NO`
- Git cleanup/reset/stash/branch movement: `NO`

The active source baseline was `be94f88ee8d179f12928ab791bdae27c22cd1762`. Pre-existing untracked `.codex_tmp/` and `reports/` content was left untouched.
