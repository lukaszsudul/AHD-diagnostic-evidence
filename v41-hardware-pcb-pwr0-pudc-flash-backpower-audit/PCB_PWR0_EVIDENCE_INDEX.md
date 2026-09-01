# PCB-PWR-0 Evidence Index

## Publication scope

Audit: AHD PCB-PWR-0 PUDC_B / Flash / Peripheral Back-Power and Configuration Safety

Exact FPGA: `xc7a35tcsg325-2`

Required prior evidence commits:

- PCB-PIN-0: `a7db236b56340095f3521ec195d2a3b49d10f956`
- PCB-PIN-1: `6b39355b5b20f14242158c1ecd7a1c0487f09b33`

Primary source baseline: `C:\FPGA\FPGA_AHD` at `be94f88ee8d179f12928ab791bdae27c22cd1762`, read-only.

## Decision summary

- `ENGINEERING_GATE = PASS`
- `CONFIGURATION_MODE = MASTER_SPI; M[2:0]=001 historical/reported; current A35T width UNRESOLVED`
- `PUDC_HIGH_FLASH_BOOT = SUPPORTED_WITH_EXTERNAL_PULL_REQUIREMENTS`
- `CURRENT_FLASH_POWER_SEQUENCE = POTENTIAL_VIOLATION`
- `PUDC_LOW_AGGREGATE_INJECTION_RISK = HIGH`
- `PUDC_B_RECOMMENDATION = CONFIGURABLE_0R_OPTION`
- `PUDC_CONFIGURABLE_OPTION = RECOMMENDED`
- proposed default: HIGH to actual VCCO_14; alternate GND; mutually exclusive population
- `J18/PUDC_B + 1 kOhm GND = SUPERSEDED`
- `27 MHz -> D13 -> FPGA -> A14 -> NVP = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`
- `I2C pull-ups -> switched NVP VDD3x = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`
- `IRQ_POWER_OFF_BEHAVIOR = REQUIRES_NVP_DATASHEET_CONFIRMATION`

## Report files

| File | Purpose |
|---|---|
| `AHD_PCB_PWR0_MAIN_REPORT.md` | Gate result, evidence boundaries, integrated engineering disposition |
| `PCB_PWR0_PUDC_BEHAVIOR.md` | Exact LOW/HIGH semantics, pin categories, related-board observation, Figure 2-14 assessment |
| `PCB_PWR0_PUDC_OPTION_COMPARISON.md` | Objective Option A/Option B comparison |
| `PCB_PWR0_FLASH_BOOT_WITH_PUDC_HIGH.md` | Master-SPI architecture, per-configuration-signal defaults, HIGH boot classification |
| `PCB_PWR0_FLASH_BACKPOWER_ANALYSIS.md` | Flash-to-unpowered-Bank-14 paths and powered-off limit analysis |
| `PCB_PWR0_CONFIGURATION_POWER_SEQUENCE.md` | Bank/rail mapping, VCCINT/VCCAUX/VCCO relationship, DS181 boundary |
| `PCB_PWR0_NVP_BACKPOWER_MATRIX.csv` | Row-wise video/control/enable/MPP preconfiguration and injection matrix |
| `PCB_PWR0_NVP_SAFE_STATE_PLAN.md` | External defaults, start/shutdown policy, 27 MHz, I2C, IRQ |
| `PCB_PWR0_FLASH_POWER_OPTIONS.md` | Flash power/pull/isolation alternatives A-E |
| `PCB_PWR0_FIRST_BOARD_TEST_PLAN.md` | Non-executed LOW/HIGH first-PCB test plan |
| `PCB_PWR0_DESIGNER_ACTION_LIST.md` | Routing, schematic, documentation, and test actions |
| `PCB_PWR0_SSOT_IMPACT.md` | Future Owner-controlled META/architecture changes; no automatic promotion |
| `PCB_PWR0_VIVADO_SANDBOX_REPORT.md` | Exact-part, no-bitstream isolated legality probe and its limitation |
| `PCB_PWR0_STATE.json` | Machine-readable classifications and no-mutation declarations |
| `PCB_PWR0_SHA256_MANIFEST.txt` | SHA-256 integrity list for every payload file except the manifest itself |

## Raw supporting files

| Path | Content |
|---|---|
| `raw/READONLY_EVIDENCE_LEDGER.md` | Source paths, hashes, line/page provenance, evidence classification |
| `raw/SOURCE_READONLY_BASELINE.txt` | Active source Git/no-mutation baseline |
| `raw/CSV_VALIDATION.txt` | NVP matrix schema and row validation |
| `raw/vivado_sandbox/` | Executed HDL/XDC/Tcl, v2 log/journal, I/O report, DRC report, and compact result summary |

Vendor PDFs and complete historical private board/project sources are not republished. Their local SHA-256 values and narrow line/page evidence are recorded in the ledger.

## Evidence hierarchy

1. Exact A35T active-source identity and exact Vivado device/package database.
2. Required immutable PCB-PIN-0/1 published commits.
3. Local NVP6134C Rev 1.0 datasheet with rendered-page visual verification.
4. Archived Rev 0.1 A15T/CSG325 schematic/netlist and historical x4 project logs, labeled historical only.
5. User-supplied related-board measurement, labeled `EXPERIMENTAL_EVIDENCE_FROM_RELATED_BOARD`.
6. Explicit unresolved items where the offline authoritative text or released schematic was unavailable.

## Deliberate unresolved items

- routing-final A35T schematic/BOM and retention of the archived Flash/regulator topology;
- current A35T SPI width and physical M[2:0] implementation;
- exact authoritative DS181 `TVCCO2VCCAUX` wording/application;
- A35T powered-off Bank-14 pad Ioff/injection limits;
- retained Flash powered-host-off behavior;
- NVP output-pad powered-off behavior and IRQ topology;
- D13 oscillator supply/OE domain;
- configuration-role clearance for T17/T18 and final VDO/MPP ownership; and
- actual first-board LOW/HIGH waveforms.

These limitations do not prevent the audit-analysis PASS or the configurable PUDC recommendation. They **do** prevent current-topology electrical signoff and routing release until the applicable designer-action items are closed. The configurable strap preserves verification flexibility; it does not waive the Flash/VCCO or powered-off-I/O limits.
