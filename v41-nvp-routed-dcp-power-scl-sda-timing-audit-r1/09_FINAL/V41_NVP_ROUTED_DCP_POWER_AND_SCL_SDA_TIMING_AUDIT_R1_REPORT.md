# V41 NVP Routed-DCP Power and SCL/SDA Timing Audit R1

## Outcome

The exact R1 routed checkpoint and two exact, provenance-qualified control checkpoints were audited read-only in Vivado 2025.2. No hardware, implementation, build, source, or formal-repository operation occurred.

The routed checkpoints prove that the SCL/SDA pins and electrical properties are identical across R1, formal Phase-2, and passing RC-A, while register placement, route topology, and physical path delays differ. The passing RC-A image often has the longest direct FPGA paths, so the comparison does **not** support a simple “longer digital path caused the v41 failure” explanation. It does support implementation sensitivity as a remaining hypothesis.

Under identical unchanged vectorless/default power assumptions, R1 and formal Phase-2 are nearly equal, while both v41-family images are materially higher-power than passing RC-A. This supports ranking image-dependent on-chip power/switching context as a hypothesis. Overall report confidence is Low, and no bank-14-only power estimate is available, so the DCP evidence cannot prove board-level Vcco droop, ground bounce, SCL/SDA rise time, or VIH margin.

## Scope and owner decision

The historical R1 configuration-to-T0 cycle-deficit calculation remains `AMBIGUOUS_STOPWATCH_EPOCH`. Separately, the owner closes the temporal causal-overlap hypothesis based on event ordering: NVP init completed at cycle 113144494, while the first AXI reset-high and link-up observations occurred at cycles 2326716859 and 2326717002, with no subsequent reset-low event. This task does not reopen A1, A2, shared-clocking, CFGMCLK, or ODIV2 experiments.

## Exact input identities

| Image | Source | Routed DCP SHA-256 | Bit SHA-256 | Provenance |
|---|---|---|---|---|
| R1 measurement | `0af44dee3bc091eaff805704dd5c687eeaa01bbd` | `182BC87220251ADFD849CB13B582CCD626E00A893F596D7F2D4EF9150108D08A` | `4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB` | Exact retained package; all member hashes pass |
| Formal Phase-2 | `fd32fcb65be3f1a59c569874195d1faeaf7d27e9` | `788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460` | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | Build log reopens this routed DCP and writes the exact bit |
| Passing RC-A | `55ce0df41552bb74e0923f89eff43977b040f2e5` | `584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3` | `A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6` | Build log writes the routed DCP and byte-identical accepted RC-A bit |

The R1 package SHA-256 is `D1075B48A37B449FDF7B4A1D7DB8AD80F85339560C0D9CC342280E9A5A9CDC23`. The filename prefix `PHASE3_` on the R1 checkpoints is historical packaging only; Phase 3 was not resumed.

## Report-only method

All DCP work used the installed supported wrapper `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`, which reports Vivado 2025.2 build 6299465. The duplicated launcher path written in the task did not exist and the raw internal executable was never invoked directly.

Vivado help was captured before the reports. Vivado 2025.2 has no `report_delay_calculation` command; its documented report-only `get_net_delays` query was used for direct OEN-Q→OBUFT-T and IBUF-O→sync0-D physical delays. No exception or checkpoint property was altered. All scripts contain only checkpoint open, object queries, reports, text output, and close-without-save operations.

The R1 checkpoint opens with top property `ahd_capture_top_xdma`, part `xc7a35tcsg325-2`, and 25,333 of 25,333 routable nets fully routed with zero routing errors.

## SCL/SDA connectivity and electrical identity

Connectivity-first discovery proves one input buffer and one open-drain output buffer per port. In each image, the OBUFT data input is constant zero and the output control is the T pin. The intended sync0/sync1 stages are present with `ASYNC_REG=TRUE` and `SHREG_EXTRACT=NO`; protocol decisions consume synchronized/filtered signals.

All images report:

- SCL: T17, bank 14, IOB_X0Y18.
- SDA: T18, bank 14, IOB_X0Y19.
- LVCMOS33, DRIVE 12, SLOW, `DIFF_TERM=0`, `IN_TERM=NONE`.
- `PULLTYPE` blank/unset; it is not coerced to `NONE`.
- No proven IOB packing for the OEN or synchronizer registers.
- Vivado off-chip termination model `FP_VTT_50`.

The owner-supplied board context is a 4.7-kΩ pull-up per line to 3.3 V, approximately 0.702 mA when low. The DCP does not contain the board capacitance or a complete analog model, and `FP_VTT_50` is not evidence that the external 4.7-kΩ network is fully modeled.

## Physical placement and delay results

The IOB sites are identical, but the OEN and synchronizer/filter registers occupy materially different fabric locations in all three designs. Each image co-locates sync0, sync1, and filter registers within a slice, but that slice moves by image.

Direct physical FULL max/min delays are:

| Path (ns) | R1 | Formal Phase-2 | Passing RC-A |
|---|---:|---:|---:|
| SCL OEN Q → OBUFT T | 2.303 / 1.090 | 3.256 / 1.658 | 4.273 / 2.077 |
| SDA OEN Q → OBUFT T | 1.709 / 0.767 | 3.017 / 1.532 | 5.696 / 2.924 |
| SCL IBUF O → sync0 D | 1.246 / 0.626 | 2.134 / 1.128 | 3.788 / 2.024 |
| SDA IBUF O → sync0 D | 2.004 / 1.080 | 2.418 / 1.311 | 3.987 / 2.058 |

For R1, the absolute SCL/SDA max-delay difference is 0.594 ns on OEN→T and 0.758 ns on pad→sync0. Those are 3.71% and 4.74% of the 16-ns AXI clock, but only 0.011861% and 0.015136% of the 5.008-µs I²C midpoint.

The R1 synchronous worst path-index-0 results remain below the 16-ns period:

| R1 path | Max (ns) | Min (ns) |
|---|---:|---:|
| SCL sync0 → sync1 | 0.523 | 0.196 |
| SDA sync0 → sync1 | 0.577 | 0.219 |
| SCL filtered → timeout/state decision | 2.202 | 0.781 |
| SDA filtered → ACK decision | 4.258 | 0.643 |
| SCL control → OEN D | 6.077 | 0.528 |
| SDA control → OEN D | 4.315 | 0.348 |

The asynchronous input paths are unconstrained; their physical delay is reported, but setup slack is not treated as analog margin. The passing RC-A control is often the longest direct-path implementation. Thus the evidence establishes implementation differences, not a directionally causal FPGA timing defect.

## Power results

All three reports use the same Vivado build, part, routed-state method, report commands, and unchanged vectorless/default activity class. No SAIF, setting file, or manual switching activity was supplied. Overall confidence is Low; clock activity is High-confidence, internal activity Medium, and I/O activity Low.

| Metric (W) | R1 | Formal Phase-2 | Passing RC-A | R1 vs formal | R1 vs RC-A |
|---|---:|---:|---:|---:|---:|
| Total on-chip | 0.636 | 0.631 | 0.401 | +0.005 (+0.79%) | +0.235 (+58.60%) |
| Dynamic | 0.557 | 0.552 | 0.323 | +0.005 (+0.91%) | +0.234 (+72.45%) |
| Device static | 0.078 | 0.078 | 0.077 | 0.000 | +0.001 (+1.30%) |
| Clocks | 0.048 | 0.044 | 0.018 | +0.004 | +0.030 (+166.67%) |
| Signals | 0.030 | 0.029 | 0.008 | +0.001 | +0.022 (+275.00%) |
| Slice logic | 0.023 | 0.022 | 0.004 | +0.001 | +0.019 (+475.00%) |
| Block RAM | 0.028 | 0.028 | 0.012 | 0.000 | +0.016 (+133.33%) |
| MMCM | 0.224 | 0.224 | 0.107 | 0.000 | +0.117 (+109.35%) |
| I/O | 0.031 | 0.031 | 0.001 | 0.000 | +0.030; Low-confidence I/O activity |
| GTP | 0.149 | 0.149 | 0.149 | 0.000 | 0.000 |
| PCIe hard IP | 0.025 | 0.025 | 0.025 | 0.000 | 0.000 |

The R1 observer contributes approximately 5 mW versus exact formal Phase-2 in this model. Compared with RC-A, estimated R1 VCCINT current is 0.176911 A versus 0.089089 A (+98.58%), and VCCAUX current is 0.152758 A versus 0.071508 A (+113.62%). Aggregate Vcco33 current is effectively identical at report precision (0.001092 A versus 0.001091 A), but it is not a bank-14-only value.

`POWER_CONTEXT_FINDING=SUPPORTED_BY_EXACT_DCP_COMPARISON` is therefore a hypothesis-ranking result under comparable but Low-confidence vectorless assumptions. It is not a board-level electrical diagnosis.

## Scientific classification

```text
IMPLEMENTATION_IO_MARGIN_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

POWER_CONTEXT_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO

ROOT_CAUSE_SOLELY_PROVEN=
    NO
```

No hardware run is recommended automatically. The next action is owner and auditor review.

## Final report block

```text
TASK=
    V41_NVP_ROUTED_DCP_POWER_AND_SCL_SDA_TIMING_AUDIT_R1

TASK_MODE=
    OFFLINE_READ_ONLY_DCP_FORENSIC

HISTORICAL_R1_CYCLE_DEFICIT_MEASUREMENT=
    AMBIGUOUS_STOPWATCH_EPOCH

OWNER_TEMPORAL_CAUSAL_CLASSIFICATION=
    CLOSED

TEMPORAL_EXPERIMENTS_RETIRED=
    A1_A2_SHARED_CLOCKING_CFGMCLK_ODIV2

OPEN_HYPOTHESES=
    D_EXACT_IMPLEMENTATION_IO_MARGIN
    IMAGE_DEPENDENT_POWER_GROUND_VCCO_MARGIN

R1_PACKAGE_SHA256=
    D1075B48A37B449FDF7B4A1D7DB8AD80F85339560C0D9CC342280E9A5A9CDC23

R1_ROUTED_DCP_SHA256=
    182BC87220251ADFD849CB13B582CCD626E00A893F596D7F2D4EF9150108D08A

R1_SOURCE_COMMIT=
    0af44dee3bc091eaff805704dd5c687eeaa01bbd

R1_BIT_SHA256=
    4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB

R1_DCP_OPEN=
    PASS_READ_ONLY_VIVADO_2025_2_BUILD_6299465

R1_DESIGN=
    ahd_capture_top_xdma

R1_PART=
    xc7a35tcsg325-2

R1_IS_ROUTED=
    YES_25333_OF_25333_ZERO_ROUTING_ERRORS

FORMAL_PHASE2_COMPARATOR=
    FOUND_EXACT

FORMAL_PHASE2_DCP_SHA256=
    788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460

FORMAL_PHASE2_DCP_TO_BIT_PROVENANCE=
    PASS_EXPLICIT_BUILD_LOG_CHAIN_TO_7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

RCA_COMPARATOR=
    FOUND_EXACT

RCA_DCP_SHA256=
    584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3

RCA_DCP_TO_BIT_PROVENANCE=
    PASS_EXPLICIT_BUILD_LOG_CHAIN_TO_A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6

SCL_IOBUF_UNIQUE=
    YES_ONE_IBUF_PLUS_ONE_OBUFT

SDA_IOBUF_UNIQUE=
    YES_ONE_IBUF_PLUS_ONE_OBUFT

SCL_IOBUF_I_CONSTANT_ZERO=
    YES

SDA_IOBUF_I_CONSTANT_ZERO=
    YES

SCL_PACKAGE_PIN=
    T17

SDA_PACKAGE_PIN=
    T18

SCL_IO_BANK=
    14

SDA_IO_BANK=
    14

SCL_IOSTANDARD=
    LVCMOS33

SDA_IOSTANDARD=
    LVCMOS33

SCL_DRIVE=
    12

SDA_DRIVE=
    12

SCL_SLEW=
    SLOW

SDA_SLEW=
    SLOW

SCL_PULLTYPE=
    UNSET

SDA_PULLTYPE=
    UNSET

SCL_OEN_REG_TO_IOBUF_T_MAX_NS=
    2.303

SCL_OEN_REG_TO_IOBUF_T_MIN_NS=
    1.090

SDA_OEN_REG_TO_IOBUF_T_MAX_NS=
    1.709

SDA_OEN_REG_TO_IOBUF_T_MIN_NS=
    0.767

SCL_IOBUF_O_TO_SYNC0_MAX_NS=
    1.246

SCL_IOBUF_O_TO_SYNC0_MIN_NS=
    0.626

SDA_IOBUF_O_TO_SYNC0_MAX_NS=
    2.004

SDA_IOBUF_O_TO_SYNC0_MIN_NS=
    1.080

SCL_SYNC0_TO_SYNC1_MAX_NS=
    0.523

SCL_SYNC0_TO_SYNC1_MIN_NS=
    0.196

SDA_SYNC0_TO_SYNC1_MAX_NS=
    0.577

SDA_SYNC0_TO_SYNC1_MIN_NS=
    0.219

SDA_FILTERED_TO_ACK_DECISION_WORST_MAX_NS=
    4.258

SDA_FILTERED_TO_ACK_DECISION_WORST_MIN_NS=
    0.643

SCL_FILTERED_TO_DECISION_WORST_MAX_NS=
    2.202

SCL_FILTERED_TO_DECISION_WORST_MIN_NS=
    0.781

OUTPUT_T_PATH_DELAY_DELTA_MAX_NS=
    0.594

INPUT_PAD_TO_SYNC0_DELAY_DELTA_MAX_NS=
    0.758

R1_TOTAL_ON_CHIP_POWER_W=
    0.636

R1_DYNAMIC_POWER_W=
    0.557

R1_STATIC_POWER_W=
    0.078

R1_VCCINT_POWER_W=
    0.176911

R1_VCCAUX_POWER_W=
    0.274964

R1_RELEVANT_VCCO_BANK_POWER_W=
    NOT_AVAILABLE_FROM_UNMODIFIED_DCP

R1_IO_POWER_W=
    0.031

R1_CLOCK_POWER_W=
    0.048

R1_SIGNAL_POWER_W=
    0.030

R1_LOGIC_POWER_W=
    0.023

R1_BRAM_POWER_W=
    0.028

R1_GT_POWER_W=
    0.149

R1_POWER_CONFIDENCE=
    LOW

R1_POWER_ACTIVITY_BASIS=
    NO_SAIF_DEFAULT_VECTORLESS_PROPAGATION_MIXED_USER_ACTIVITY_CLOCKS_GT95_PERCENT_INTERNAL_LT25_PERCENT_IO_INPUTS_GT75_PERCENT_UNSPECIFIED

IMPLEMENTATION_IO_MARGIN_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

POWER_CONTEXT_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO

ROOT_CAUSE_SOLELY_PROVEN=
    NO

HARDWARE_ACTIONS=
    0

FULL_BUILDS=
    0

IMPLEMENTATION_COMMANDS=
    0

SOURCE_CHANGES=
    0

FORMAL_REPOSITORY_MUTATIONS=
    0

PHASE3_RESUMED=
    NO

XDMA_DEVELOPMENT_CONTINUED=
    NO

EVIDENCE_PACKAGE_SHA256=
    SEE_V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1_EVIDENCE_SHA256_TXT

EVIDENCE_REPOSITORY_COMMIT=
    RECORDED_AFTER_NORMAL_COMMIT_IN_PUBLICATION_RECEIPT

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_BEFORE_ANY_HARDWARE_RUN
```
