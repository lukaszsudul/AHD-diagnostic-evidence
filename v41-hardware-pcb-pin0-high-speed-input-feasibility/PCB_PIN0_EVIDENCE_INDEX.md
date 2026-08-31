# PCB-PIN-0 Evidence Index

## Decision artifacts

| Artifact | Purpose |
|---|---|
| `AHD_PCB_PIN0_MAIN_REPORT.md` | engineering decision, mapping, risks, and routing recommendation |
| `PCB_PIN0_PER_PIN_AUDIT.csv` | required per-pin bank/function/resource/result matrix |
| `PCB_PIN0_CHANNEL1_ANALYSIS.md` | CH1 locality, clocking, SDR/DDR and routing analysis |
| `PCB_PIN0_CHANNEL2_ANALYSIS.md` | CH2 locality, clocking, conflicts and T15/U15 recommendation |
| `PCB_PIN0_27MHZ_CLOCK_ANALYSIS.md` | C13 PLIO-9 finding, required D13 correction, and shared oscillator review |
| `PCB_PIN0_CONTROL_IO_ANALYSIS.md` | IRQ/RST/I2C, MPP and J18 findings |
| `PCB_PIN0_DDR_FEASIBILITY.md` | 297 MT/s and two-channel mux readiness |
| `PCB_PIN0_IDELAY_ISERDES_ARCHITECTURE.md` | hard-resource, IDELAYCTRL and clock-topology requirements |
| `PCB_PIN0_VIVADO_DEVICE_DATABASE_REPORT.md` | exact part, Tcl queries, returned identifiers and sandbox outcomes |
| `PCB_PIN0_ALTERNATIVE_PIN_RECOMMENDATIONS.md` | ranked D13, U15 and optional control alternatives |
| `PCB_PIN0_SOURCE_READONLY_EVIDENCE.md` | current/historical mapping, conflicts and clean-worktree proof |
| `PCB_PIN0_SSOT_IMPACT.md` | no-current-SSOT-change statement and later META requirement |
| `PCB_PIN0_STATE.json` | machine-readable final audit state |
| `PCB_PIN0_SHA256_MANIFEST.txt` | SHA-256 integrity manifest for the evidence payload |

## Raw Vivado device database

| Artifact | Purpose |
|---|---|
| `raw/EXACT_PART.txt` | requested spelling, canonical Vivado part and tool version |
| `raw/PIN_OBJECT_SUMMARY.tsv` | proposed-pin package object/site/bank/function summary |
| `raw/PIN_OBJECT_ALL_PROPERTIES.txt` | complete package-pin, IOB site and bank property dump |
| `raw/ALL_USER_PACKAGE_PINS.tsv` | full package inventory used for alternatives |
| `raw/query_device.tcl` | archived device query script |
| `raw/dummy.v` | minimal design used to open exact device database |
| `raw/CURRENT_ACCEPTED_IO_REPORT.rpt` | read-only accepted AHD report used for before/current ownership |

## Raw primitive-placement evidence

`raw/primitive_placement/` contains the isolated 16-path `IBUF -> IDELAYE2 -> IDDR` test, current T15 placement, controlled U15 placement, clock-utilization reports and post-place DRC reports. Both variants fully placed with no video/clock/delay placement violation. The two reported DRC items are documented sandbox-only UCIO/CFGBVS checks on intentionally incomplete dummy signals/config properties.

## Raw full-pin and C13/D13 evidence

`raw/placement/` contains:

- the dummy top and exact proposed-pin XDC;
- the first retained IDDR-port harness failure;
- the corrected original C13 run showing clean synthesis followed by actual `PLIO-9` at placement;
- the controlled D13 variant reports/result;
- clock utilization, I/O, DRC, route status and timing-summary outputs; and
- no bitstream.

The failed harness attempt is not evidence against the pins. The corrected C13 `PLIO-9` is the objective reason the report requires C13-to-D13.

## Publication verification

Publication is to `lukaszsudul/AHD-diagnostic-evidence`, branch `main`, directory `v41-hardware-pcb-pin0-high-speed-input-feasibility`, without force. Remote read-back is performed by fetching `main`, resolving its commit, listing the committed directory and verifying the committed manifest/content from a clean remote-backed checkout.

