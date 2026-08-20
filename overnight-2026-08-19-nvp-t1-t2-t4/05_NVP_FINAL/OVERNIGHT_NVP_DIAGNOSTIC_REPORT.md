# Overnight NVP diagnostic report

## Context

This run prioritized NVP/codec startup reliability under a hard `2026-08-20T08:00:00Z` deadline. It used no owner interaction, auditor interaction, physical action, cold start, or parallel hardware process. The campaign was warm-state only by authorization; no warm-state sample could safely begin because authenticated host control was unavailable.

## Inputs

- Formal branch: `v41/xdma-v40.1.0-base`.
- Formal HEAD/tag target: `c89e88bcdf389614c884fb129e8b2d42a585bccb`.
- Formal tree: `417820c69c134161fcafae0947dc5976919814d1`.
- Formal worktree: clean; mutations during NVP: 0.
- Formal Phase-2 bit: 2,192,144 bytes; SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.
- Hardware target: exact HS2 `210241768436`, `xc7a35t`, IDCODE `0362D093`.
- Authoritative start image: `FORMAL_PHASE2_ACCEPTED_REFERENCE`.

## T1 exact bit identity

The exact sealed RC-A was found without rebuilding or substitution:

- Path: `C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\V40_1_0_NVP_PATCH\V40_1_0_FINAL_ACCEPTANCE_R2\BUILD\ARTIFACTS\ahd_capture_v40_1_0_RC_A.bit`.
- Size: 2,192,144 bytes.
- SHA-256: `A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6`.
- Source: `release/v40.1.0-nvp`, commit `55ce0df41552bb74e0923f89eff43977b040f2e5`, tree `11be6461417607667aebf572adeee574c36d71a3`.

An independent copy in the accepted Phase-2 evidence package produced the same size and SHA-256.

## Per-run T1 matrix

| Planned run | Program invoked | Warm reboot | Functional gate | Valid sample | Result |
|---|---:|---:|---|---:|---|
| 01 | 0 | 0 | Not started: authenticated SSH unavailable | 0 | Infrastructure-blocked |
| 02 | 0 | 0 | Not started | 0 | Not run |
| 03 | 0 | 0 | Not started | 0 | Not run |

```text
T1_VALID_RUNS=0
T1_PASS_COUNT=0
T1_FAIL_COUNT=0
T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE
INFRASTRUCTURE_CLASS=INVALID_INFRASTRUCTURE_SSH_AUTHENTICATION
```

The observed ED25519 host fingerprint matched the sealed host identity exactly. The two existing non-interactive owner keys were rejected for `vcdeagent1`; the cached PuTTY path reached the correct server but required an interactive password. Because owner interaction was prohibited, programming RC-A would have made the required warm reboot and final restoration sequence unsafe. No hardware mutation was started.

## Formal restoration proof

RC-A was never programmed, so restoration programming was neither required nor permitted. The accepted formal image was preserved by zero configuration/boot/physical mutation. Fresh read-only JTAG ultimately passed on the exact target with one device, `xc7a35t`, IDCODE `0362D093`, and DONE=1. `FORMAL_PHASE2_ACTIVE_AT_END=YES_PRESERVED_BY_ZERO_MUTATION`; `DIAGNOSTIC_IMAGE_ACTIVE=NO`.

Host runtime identity and diagnostic magic could not be freshly re-read. Their authoritative input values were preserved but are not presented as new observations.

## T2 KiCad findings

The preferred frozen KiCad revision was present and all four expected identity hashes matched. Exact results:

- `NVP_SCL`: `U4.T17 ↔ U6.64`, with `R20=4k7` to `Vcco`; three net members, top layer only, 0 vias, approximately 35.259-mm routed path.
- `NVP_SDA`: `U4.T18 ↔ U6.63`, with `R21=4k7` to `Vcco`; three net members. FPGA-to-NVP path is top layer and approximately 32.936 mm; the R21 branch changes to bottom through one via.
- No series resistor, capacitor/filter, ESD part, bus test point, connector crossing, level shifter, additional target, or other bus device exists.
- Pull-up tolerance is not specified. At nominal 3.3 V, static low-level current is approximately 0.702 mA per line.
- Bus capacitance: `UNKNOWN_NOT_MEASURED`; no RC rise time was inferred.
- Rail path: `V_3.3V → F1 → U1.1/U1.6 load switch → Vcco → R20/R21`.
- Schematic/netlists contain `TP1=3,3V` on Vcco; the PCB file has no placed TP1 footprint. Physically placed `J2.1` is a through-hole Vcco point.
- Frozen KiCad maps reset to `U4.R18` and IRQ to `U4.R17`; the current designer declaration controls present hardware and identifies active-LOW reset as R17 with an external 3.3-V pull-up.
- The J2 courtyard is about 6.8 mm from the nearest T17/T18 breakout; the bus does not cross the connector area.

## T3 prepared inspection plan

`T3_PHYSICAL_INSPECTION_CHECKLIST.md` specifies J2, U4.T17/T18, R20, R21, the sole SDA via, U6.63/U6.64, U1, photo angles, exact coordinates, nearby ground references, and all requested visible failure modes. It authorizes no rework or probing.

## T4 result

T4 was not run. Its mandatory `RCA_CURRENT_HARDWARE_PASS_3_OF_3` entry condition was not met. No reset-domain conclusion, build, patch, bitstream, or hardware experiment was produced.

```text
T4_RUN=NO
T4_CLASSIFICATION=NOT_RUN_T1_PASS_3_OF_3_GATE_NOT_MET
```

## Updated hypothesis ranking

1. **Unresolved physical/electrical I2C margin or assembly defect** — still plausible; T2 shows a simple bus with two 0402 pull-ups and one SDA via, giving precise later inspection points but no measured electrical evidence.
2. **v41-specific reset/autoinit integration dependence** — unresolved, not supported or rejected by this run because T1 supplied no comparison samples and T4 was gated off.
3. **Broader changed hardware/cabling state** — unresolved; exact RC-A was not exercised tonight.
4. **Nominal schematic topology error such as a missing designed pull-up or unexpected bus device** — reduced by T2: both 4.7-kΩ pull-ups are present in the design and each bus net has exactly three members.

No result permits the phrase “firmware fully exonerated.”

## Remaining unknowns

- Current-state RC-A functional outcome and repeatability.
- Fresh host boot ID, PCIe/link/BAR state, pinned driver/nodes, runtime identity, diagnostic magic, and NVP/video counters.
- Actual mounted R20/R21 values and solder integrity.
- Actual Vcco level, I2C low levels, rise times, bus capacitance, and waveform quality.
- Whether v41 PCIE/XDMA resets reach or retrigger the NVP sequencer.
- Whether the current board physically matches the older KiCad reset-pin mapping or the controlling current designer declaration at all relevant assembly points.

## Recommended next owner action

Restore a non-interactive, approved SSH authentication path for `vcdeagent1@10.132.1.111`, then rerun the exact three-sample RC-A warm campaign with the sealed bit and read-only baseline. If and only if it passes 3/3, run T4 offline. If RC-A fails or is intermittent, perform the prepared visual inspection first, beginning with R20/R21, the SDA via, U6.63/U6.64, and the J2-to-T17/T18 area; electrical measurement requires separate authorization and suitable equipment.

## Exact operation accounting

```text
RC_A_PROGRAM_OPERATIONS=0
FORMAL_RESTORE_PROGRAM_OPERATIONS=0
OTHER_FPGA_PROGRAM_OPERATIONS=0
SUCCESSFUL_READ_ONLY_JTAG_SESSIONS=1
SOFTWARE_ONLY_JTAG_RECOVERY_ATTEMPTS=2
HW_SERVER_STARTS=1
AUTHENTICATED_SSH_SESSIONS=0
WARM_REBOOTS=0
COLD_STARTS=0
MMIO_READS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
FORMAL_REPOSITORY_MUTATIONS=0
NEW_OFFLINE_BUILDS=0
OWNER_INTERACTIONS=0
AUDITOR_INTERACTIONS=0
```

```text
NVP_SCOPE_COMPLETE=YES
FORMAL_PHASE2_ACTIVE_AT_END=YES_PRESERVED_BY_ZERO_MUTATION
DIAGNOSTIC_IMAGE_ACTIVE=NO
```
