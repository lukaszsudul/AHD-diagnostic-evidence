# PCB-PIN-1 Evidence Index

## Final classifications

- `PROGRAM_B_SELF_RESET = REMOVE`
- `PROGRAM_B_LOOP_REQUIRED = NO`
- `INTERNAL_RECONFIGURATION_ALTERNATIVE = SUPPORTED`
- `D13_27MHZ_INPUT = VALID`
- `A14_NVP_CLOCK_OUTPUT = VALID_WITH_CONSTRAINT`
- `CLOCK_FORWARDING = ODDR/OLOGIC_RECOMMENDED`
- `GLITCH_FREE_CLOCK_GATING = FEASIBLE_WITH_CONSTRAINTS`
- `A14_PRECONFIG_STATE = WEAK_PULLUP_EXPECTED`
- `NVP_CLK_EXTERNAL_PULLDOWN = REQUIRED`
- `FPGA_GATED_27MHZ_TO_NVP = APPROVE_WITH_CHANGES`
- `I2C_PULLUP_DOMAIN = NVP_SWITCHED_3V3_RECOMMENDED`
- `NVP_POWER_DOMAIN_REVIEW = PASS_WITH_CONSTRAINTS`
- `VIVADO_SANDBOX = PASS`

## Required decision artifacts

| Artifact | Purpose |
|---|---|
| `AHD_PCB_PIN1_MAIN_REPORT.md` | complete engineering gate, point-10/11 decisions, conditions, and audit integrity |
| `PCB_PIN1_PROGRAM_B_EXISTING_IMPLEMENTATION.md` | current/historical T12/PROGRAM_B search and PARTIAL classification |
| `PCB_PIN1_PROGRAM_B_ARCHITECTURE_DECISION.md` | PROGRAM_B semantics, failure modes, REMOVE decision, and ICAPE2/IPROG alternative |
| `PCB_PIN1_27MHZ_CLOCK_FORWARDING_ARCHITECTURE.md` | D13/A14 resources, recommended ODDR gate, timing contract, and SI provisions |
| `PCB_PIN1_A14_STARTUP_STATE_ANALYSIS.md` | PUDC_B-low weak-pull-up behavior and required external low guarantee |
| `PCB_PIN1_NVP_STARTUP_SEQUENCE.md` | deterministic startup order with supported delay classifications |
| `PCB_PIN1_NVP_SHUTDOWN_SEQUENCE.md` | safe shutdown order and off-domain constraints |
| `PCB_PIN1_I2C_POWER_DOMAIN_ANALYSIS.md` | switched-domain pull-up decision and current open-drain compatibility |
| `PCB_PIN1_NVP_POWER_DOMAIN_MATRIX.csv` | RST/CLK/SDA/SCL/IRQ/enable states, pulls, risks, mitigations, and status |
| `PCB_PIN1_VIVADO_SANDBOX_REPORT.md` | exact-part D13-to-BUFGCE-to-ODDR-to-A14 placement/route/DRC result |
| `PCB_PIN1_DESIGNER_ACTION_LIST.md` | exact schematic/routing, component-data, SI, and later implementation actions |
| `PCB_PIN1_STATE.json` | machine-readable final classifications, integrity state, and publication target |
| `PCB_PIN1_EVIDENCE_INDEX.md` | artifact map, provenance, manifest convention, and publication verification method |
| `PCB_PIN1_SSOT_IMPACT.md` | unchanged PROJECT_STATE_REV and future governed META/source impact |
| `PCB_PIN1_SHA256_MANIFEST.txt` | SHA-256 integrity manifest for every other published payload file |

## Read-only source and reference evidence

| Artifact | Purpose |
|---|---|
| `raw/SOURCE_READONLY_BASELINE.txt` | primary Git revision, clean tracked/index baseline, protected-operation attestations, and source hashes |
| `raw/PROGRAM_B_HISTORY_READONLY_EVIDENCE.md` | exact historical paths, line evidence, sizes, hashes, and classification rule |
| `raw/LOCAL_REQUIREMENTS_READONLY_EVIDENCE.md` | hashed local PCB requirements facts used by the audit |
| `raw/OFFICIAL_AMD_REFERENCE_NOTES.md` | UG470/UG471/UG953/DS181 evidence and official document URLs |

## Raw isolated Vivado evidence

`raw/vivado_sandbox/` contains:

- the disposable Verilog harness and XDC;
- the Tcl batch script and complete successful-run log;
- a concise result summary;
- post-route I/O, clock-utilization, route-status, timing-summary, and DRC reports; and
- no DCP, bitstream, BIN, MCS, or other configuration image.

The harness uses T12 only as a disposable enable input for the synchronized BUFGCE alternative. It is not a product assignment or a replacement PROGRAM_B GPIO. The sandbox report discloses the non-probative early `PIN_COUNT=0` query context and relies on post-route I/O/cell placement plus the prior PCB-PIN-0 device-database record.

## Cross-audit dependency

The immutable prior directory `../v41-hardware-pcb-pin0-high-speed-input-feasibility/` supplies the accepted D13 correction, the full device-database pin inventory, and the proposed channel-1 remap that frees A14. PCB-PIN-1 adds only the new directory and does not modify PCB-PIN-0 evidence.

## Source integrity

The primary repository remained at `be94f88ee8d179f12928ab791bdae27c22cd1762`. No tracked source, index, active XDC, PCB, SSOT, G-track, or R-track state was changed. No hardware was accessed and no bitstream was produced. Exact primary-file hashes are recorded in `raw/SOURCE_READONLY_BASELINE.txt`.

## Manifest convention

`PCB_PIN1_SHA256_MANIFEST.txt` covers every other file in this evidence directory and deliberately excludes itself to avoid recursive self-hashing. Paths are relative to the PCB-PIN-1 directory and sorted ordinally.

## Publication verification

Publication is to `lukaszsudul/AHD-diagnostic-evidence`, branch `main`, directory `v41-hardware-pcb-pin1-programb-nvp-clock-power-audit`, using the exact commit message `Audit AHD PROGRAM_B and FPGA-gated NVP 27 MHz architecture` and no force push. Remote read-back is performed from a fresh remote-backed checkout by resolving the containing commit, listing the committed directory, and recomputing every manifest hash.
