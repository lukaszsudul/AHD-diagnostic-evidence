# RC-A versus formal Phase-2 power breakdown

This report answers where Vivado's estimated power difference resides when the
exact passing RC-A and exact failing formal Phase-2 routed checkpoints are
analyzed with the same unmodified, default/vectorless assumptions. It is an
offline model comparison, not board-level electrical proof.

| Rail or total | RC-A (W) | Formal Phase 2 (W) | Phase2 − RC-A (W) | Delta vs RC-A | Confidence | Availability / method |
|---|---:|---:|---:|---:|---|---|
| Total on-chip | 0.401 | 0.631 | +0.230 | +57.36% | Low | Direct `report_power` total |
| Dynamic | 0.323 | 0.552 | +0.229 | +70.90% | Low | Direct `report_power` total |
| Device static | 0.077 | 0.078 | +0.001 | +1.30% | Low | Direct `report_power` total |
| VCCINT | 0.0890 | 0.1720 | +0.0830 | +93.26% | Low | Reported voltage × reported current |
| VCCAUX | 0.1296 | 0.2754 | +0.1458 | +112.50% | Low | Reported voltage × reported current |
| VCCBRAM | 0.0010 | 0.0020 | +0.0010 | Not meaningful | Low | One displayed current quantum |
| VCCO bank 14 | N/A | N/A | N/A | N/A | N/A | Not available from the unmodified DCP |
| VCCO bank 16 | N/A | N/A | N/A | N/A | N/A | Not available from the unmodified DCP |
| Aggregate Vcco33 | 0.0033 | 0.0033 | 0.0000 | Not meaningful | Low I/O | Aggregate voltage class, not per-bank |
| Vcco25 | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| Vcco18 | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| Vcco15 | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| Vcco135 | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| Vcco12 | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| Vccaux_io | 0.0000 | 0.0000 | 0.0000 | Not meaningful | Low I/O | Reported row |
| MGTAVcc | 0.0680 | 0.0680 | 0.0000 | 0.00% | Low overall | Reported voltage × reported current |
| MGTAVtt | 0.0744 | 0.0744 | 0.0000 | 0.00% | Low overall | Reported voltage × reported current |
| Vccadc | 0.0360 | 0.0360 | 0.0000 | 0.00% | Low overall | Reported voltage × reported current |

## Executive finding

The estimated difference resides predominantly on the core/auxiliary rails,
not in the reported MGT supply rows or aggregate 3.3-V VCCO class:

- VCCAUX rises by 0.1458 W and VCCINT rises by 0.0830 W.
- MGTAVcc plus MGTAVtt is 0.1424 W in both images.
- Aggregate Vcco33 is equal at the report's 0.001-A precision.
- The model does not expose bank-14 or bank-16 power/current, so aggregate
  Vcco33 equality cannot classify the NVP bank's DC loading.

In the mutually exclusive hierarchy/resource view, the 0.229-W dynamic delta
is accounted by:

| Exclusive category | RC-A (W) | Formal Phase 2 (W) | Delta (W) |
|---|---:|---:|---:|
| Clocking IP | 0.107 | 0.224 | +0.117 |
| Transport excluding embedded clock IP | 0.193 | 0.270 | +0.077 |
| NVP physical frontend excluding embedded clock IP | 0.001 | 0.032 | +0.031 |
| Capture | 0.017 | 0.019 | +0.002 |
| NVP autoinit | 0.002 | 0.002 | 0.000 |
| Control / host bridge | 0.002 | 0.002 | 0.000 |
| Other / rounding remainder | 0.001 | 0.003 | +0.002 |
| **Reconciled dynamic total** | **0.323** | **0.552** | **+0.229** |

The largest resource-sliced contribution is the extra clocking/IP context,
followed by the non-clock transport delta and then the NVP physical-frontend
delta. Exact source context identifies the formal frontend's additional
MMCM/IDELAY clocking chain; the NVP autoinit hierarchy itself is unchanged at
0.002 W in both models.

## Exact inputs and report sequence

| Role | Routed DCP SHA-256 | Source commit | Top | Routed gate |
|---|---|---|---|---|
| Formal Phase-2 fail control | `788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460` | `fd32fcb65be3f1a59c569874195d1faeaf7d27e9` | `ahd_capture_top_xdma` | 24,926/24,926 routable nets fully routed; 0 errors |
| RC-A pass control | `584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3` | `55ce0df41552bb74e0923f89eff43977b040f2e5` | `ahd_capture_top_pcie` | 7,385/7,385 routable nets fully routed; 0 errors |

Both checkpoints were created by Vivado 2025.2 build 6299465 for
`xc7a35tcsg325-2`. The same Tcl script and 25-command report sequence were
used for both roles. The normalized command sequences are byte-equivalent.
No design-changing command is present.

The suite generated standard, full hierarchy/detail, hierarchy-only,
advisory, XML, and RPX power reports. XML is the supported machine-readable
format; no unsupported CSV power format was invented.

## Assumption comparability

`POWER_ASSUMPTIONS_COMPARABLE=YES`.

The following material inputs match:

- Vivado 2025.2 build 6299465, device, routed state, commercial grade,
  typical process, and Production characterization.
- Ambient 25 °C, 250 LFM airflow, the same board/thermal inputs, and identical
  rail voltages.
- No settings file and no SAIF file.
- Default vectorless propagation enabled in both reports.
- Clock activity confidence High (more than 95% specified), internal activity
  confidence Medium (less than 25% specified), I/O activity confidence Low
  (more than 75% of inputs unspecified), and overall confidence Low.

Pre/post core-voltage and default-activity reports are byte-identical. Within
each image, pre/post clock definitions and clock networks are semantically
identical after removing only date/command headers. `report_power` populates
derived junction temperature and vectorless average activity; those result
changes are not assumption writes.

```text
OPERATING_CONDITIONS_CHANGED_DURING_TASK=NO
SWITCHING_ACTIVITY_CHANGED_DURING_TASK=NO
```

## Complete supply-rail result

Vivado reports voltage and total/dynamic/static current per supply. The power
columns in the comparison CSV are explicitly derived as voltage × current.
All emitted rows are preserved in `SUPPLY_RAILS_ALL.csv`; no fixed whitelist
discarded unanticipated rows. No `MGTVCCAUX` row was emitted, so it is recorded
as not reported rather than zero.

The screening classifications are:

- `VCCINT_MODEL_CLASSIFICATION=CLEAR_INCREASE_PHASE2`
- `VCCAUX_MODEL_CLASSIFICATION=CLEAR_INCREASE_PHASE2`
- `MGT_MODEL_CLASSIFICATION=EQUAL_WITHIN_REPORT`
- `AGGREGATE_VCCO33_MODEL_CLASSIFICATION=EQUAL_WITHIN_REPORT`
- VCCBRAM differs by one displayed power quantum and is not a clear model
  increase under the predeclared 10×-resolution rule.

## I/O banks 14 and 16

Bank 14's used-port inventory is identical in the two designs:

| Port | Pin | Direction | I/O standard | Drive | Slew | Functional category |
|---|---|---|---|---:|---|---|
| `nvp_rst` | R17 | Output | LVCMOS33 | 12 | SLOW | NVP autoinit/reset |
| `nvp_scl` | T17 | Bidirectional | LVCMOS33 | 12 | SLOW | NVP I2C |
| `nvp_sda` | T18 | Bidirectional | LVCMOS33 | 12 | SLOW | NVP I2C |
| `nvp_mpp[0]` | V16 | Input | LVCMOS33 | Unset | Unset | NVP observation input |
| `nvp_mpp[1]` | V17 | Input | LVCMOS33 | Unset | Unset | NVP observation input |
| `nvp_mpp[2]` | U16 | Input | LVCMOS33 | Unset | Unset | NVP observation input |
| `nvp_mpp[3]` | U17 | Input | LVCMOS33 | Unset | Unset | NVP observation input |

Bank 16 has no used design ports in either exact DCP. Package pin B16 belongs
to bank 15 and must not be confused with I/O bank 16.

The power text, XML, RPX string inventory, I/O-bank objects, ports, I/O
primitives, and nets expose no documented, unit-bearing, non-overlapping
power/current property from which bank 14 or bank 16 can be summed. `report_io`
does expose VCCO_14 supply pins and voltage, but not bank power.

```text
VCCO_14_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_14_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_16_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_16_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
```

The external 4.7-kΩ SCL/SDA pull-ups, unknown bus capacitance, and board power
distribution impedance are not fully modeled by this DCP analysis.

## Clock-network/domain breakdown

The complete raw clock-network rows are preserved in
`CLOCK_NETWORK_POWER_RAW.csv`. Only depth-zero roots are summed; indented
buffer children are not added to parents.

| Semantic clock domain | RC-A | Formal Phase 2 | Interpretable delta |
|---|---:|---:|---:|
| Combined PCIe user/AXI + NVP autoinit + capture/control (`userclk1`) | 0.004 W | 0.030 W | **+0.026 W** |
| NVP video/physical roots | 0.008 W | 0.007 W + 2×`<0.001` W | Interval overlaps; no clear direction |
| PCIe reference/GT clocking roots | 0.004 W + 4×`<0.001` W | 0.004 W + 4×`<0.001` W | Interval overlaps |
| Reported total clock-network power | 0.018 W | 0.044 W | **+0.026 W** |

`userclk1` is a combined domain and its 0.030 W must not be assigned solely to
XDMA or solely to NVP. The unmodified routed DCP directly reports clock-network
power; it does not directly attribute total sequential/combinational logic
dynamic power by clock membership.

```text
LOGIC_POWER_BY_CLOCK_DOMAIN=NOT_DIRECTLY_AVAILABLE_FROM_UNMODIFIED_DCP
CLOCK_DOMAIN_POWER_CLASSIFICATION=CLEAR_INCREASE_PHASE2_COMBINED_USERCLK1
```

A supplemental, identical read-only connectivity inventory traced every
reported power root to its exact clock object and source pin, captured five
representative sequential sinks and its main hierarchy distribution, and used
the documented `all_registers -clock -cells` query. It found nine exact clock
objects in formal Phase 2 and seven in RC-A. The fallback sequential-cell
membership counts are:

| Domain | RC-A cells | Formal Phase 2 cells | Meaning |
|---|---:|---:|---|
| Combined PCIe user/AXI + NVP autoinit + capture/control | 2,207 | 15,119 | Register-cell memberships; not power |
| NVP video/physical | 1,735 | 1,742 | Deduplicated within domain; not power |
| PCIe reference/GT clocking | 440 | 440 | Deduplicated within domain; not power |

Primitive-type counts are preserved in `UTILIZATION_BY_CLOCK_DOMAIN.csv`.
Cells with multiple clock pins are explicitly flagged as cross-domain shared;
neither utilization nor register counts are presented as power.

## Hierarchy breakdown

The functional-owner view preserves each selected hierarchy total as reported,
including any clock IP owned inside that hierarchy:

| Functional owner | RC-A (W) | Formal Phase 2 (W) | Delta (W) |
|---|---:|---:|---:|
| Legacy transport / XDMA transport | 0.300 | 0.377 | +0.077 |
| Capture | 0.017 | 0.019 | +0.002 |
| NVP autoinit | 0.002 | 0.002 | 0.000 |
| NVP physical frontend | 0.001 | 0.149 | +0.148 |
| Control / PIO or AXI host bridge | 0.002 | 0.002 | 0.000 |
| Other / root remainder | 0.001 | 0.003 | +0.002 |
| **Dynamic total** | **0.323** | **0.552** | **+0.229** |

The raw NVP physical-frontend delta includes 0.117 W of additional embedded
clock IP. The separate mutually exclusive resource-sliced table near the start
removes each selected owner's `Clock IP (W)` column exactly once and assigns it
to `CLOCKING_IP`, preventing double counting.

```text
HIERARCHY_POWER_CLASSIFICATION=CLEAR_INCREASE_PHASE2_NVP_PHYSICAL_TRANSPORT_AND_CLOCKING_IP
```

## Decision matrix

Per-bank VCCO power is unavailable, so the primary classification is Case D:

```text
POWER_BREAKDOWN_DECISION_CASE=CASE_D_INCONCLUSIVE_REPORT_POWER_LIMITATION
STATIC_OR_LOW_FREQUENCY_VCCO_LOADING_HYPOTHESIS=INCONCLUSIVE_REPORT_POWER_LIMITATION
STATIC_FPGA_IO_BANK14_DC_LOAD_DIFFERENCE=INCONCLUSIVE_PER_BANK_VCCO_UNAVAILABLE
ON_CHIP_SWITCHING_RETURN_PATH_CONTEXT=SUPPORTED_BY_CLEAR_CORE_RAIL_CLOCKING_AND_HIERARCHY_DELTAS
```

The clear VCCINT/VCCAUX and hierarchy/clocking deltas rank an image-dependent
on-chip switching/return-path context as relevant model evidence. They do not
prove ground bounce, SSN, board VCCO droop, or I2C threshold failure. Aggregate
Vcco33 equality cannot select Case B because it is not a direct bank-14 value.

The conservative next action is owner/auditor review. If a hardware measurement
is separately authorized, the direct discriminator is bank-14 Vcco at J2.1 or
R20.2/R21.1 with approved nearby ground, comparing exact RC-A and formal Phase
2; direct SCL/SDA/ground observation or a separate report-only SSN audit remain
distinct follow-ups.

## Interpretation limits

```text
BOARD_VCCO_DROOP_PROVEN=NO
GROUND_BOUNCE_PROVEN=NO
SSN_PROVEN=NO
ANALOG_I2C_MARGIN_PROVEN=NO
ROOT_CAUSE_SOLELY_PROVEN=NO
```

The model confidence is Low and vectorless. It ranks the location of estimated
on-chip power differences; it does not contain the full PCB analog network or
measured waveform activity.

## Required final block

```text
TASK=
    V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1

TASK_MODE=
    OFFLINE_READ_ONLY_ROUTED_DCP_POWER_FORENSIC

FORMAL_PHASE2_DCP_SHA256=
    788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460

RCA_DCP_SHA256=
    584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3

POWER_ASSUMPTIONS_COMPARABLE=
    YES

FORMAL_PHASE2_POWER_CONFIDENCE=
    LOW
RCA_POWER_CONFIDENCE=
    LOW

FORMAL_PHASE2_ACTIVITY_BASIS=
    DEFAULT_VECTORLESS_NO_SAIF_CLOCK_HIGH_IO_LOW_INTERNAL_MEDIUM
RCA_ACTIVITY_BASIS=
    DEFAULT_VECTORLESS_NO_SAIF_CLOCK_HIGH_IO_LOW_INTERNAL_MEDIUM

VCCINT_RCA_POWER_W=
    0.089000
VCCINT_PHASE2_POWER_W=
    0.172000
VCCINT_DELTA_POWER_W=
    0.083000
VCCINT_RCA_CURRENT_A=
    0.089000
VCCINT_PHASE2_CURRENT_A=
    0.172000
VCCINT_DELTA_CURRENT_A=
    0.083000
VCCINT_MODEL_CLASSIFICATION=
    CLEAR_INCREASE_PHASE2

VCCAUX_RCA_POWER_W=
    0.129600
VCCAUX_PHASE2_POWER_W=
    0.275400
VCCAUX_DELTA_POWER_W=
    0.145800
VCCAUX_RCA_CURRENT_A=
    0.072000
VCCAUX_PHASE2_CURRENT_A=
    0.153000
VCCAUX_DELTA_CURRENT_A=
    0.081000
VCCAUX_MODEL_CLASSIFICATION=
    CLEAR_INCREASE_PHASE2

VCCBRAM_RCA_POWER_W=
    0.001000
VCCBRAM_PHASE2_POWER_W=
    0.002000
VCCBRAM_DELTA_POWER_W=
    0.001000

VCCO_14_DIRECT_BREAKDOWN_AVAILABLE=
    NO
VCCO_14_BREAKDOWN_METHOD=
    NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_14_RCA_POWER_W=
    NOT_AVAILABLE
VCCO_14_PHASE2_POWER_W=
    NOT_AVAILABLE
VCCO_14_DELTA_POWER_W=
    NOT_AVAILABLE
VCCO_14_RCA_CURRENT_A=
    NOT_AVAILABLE
VCCO_14_PHASE2_CURRENT_A=
    NOT_AVAILABLE
VCCO_14_DELTA_CURRENT_A=
    NOT_AVAILABLE
VCCO_14_MODEL_CLASSIFICATION=
    NOT_AVAILABLE

VCCO_16_DIRECT_BREAKDOWN_AVAILABLE=
    NO
VCCO_16_BREAKDOWN_METHOD=
    NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_16_RCA_POWER_W=
    NOT_AVAILABLE
VCCO_16_PHASE2_POWER_W=
    NOT_AVAILABLE
VCCO_16_DELTA_POWER_W=
    NOT_AVAILABLE
VCCO_16_MODEL_CLASSIFICATION=
    NOT_AVAILABLE

AGGREGATE_VCCO33_RCA_POWER_W=
    0.003300
AGGREGATE_VCCO33_PHASE2_POWER_W=
    0.003300
AGGREGATE_VCCO33_DELTA_POWER_W=
    0.000000

MGT_SUPPLY_ROWS=
    MGTAVcc_MGTAVtt;MGTVCCAUX_NOT_REPORTED
MGT_RCA_POWER_W=
    0.142400
MGT_PHASE2_POWER_W=
    0.142400
MGT_DELTA_POWER_W=
    0.000000
MGT_MODEL_CLASSIFICATION=
    EQUAL_WITHIN_REPORT

CLOCK_NETWORK_POWER_BY_DOMAIN_AVAILABLE=
    YES_CLOCK_NETWORK_POWER_ONLY
LOGIC_POWER_BY_CLOCK_DOMAIN=
    NOT_DIRECTLY_AVAILABLE_FROM_UNMODIFIED_DCP
CLOCK_DOMAIN_POWER_LEADING_DELTA=
    COMBINED_PCIE_USER_AXI_NVP_AUTOINIT_CAPTURE_CONTROL_USERCLK1_PLUS_0.026_W
CLOCK_DOMAIN_POWER_CLASSIFICATION=
    CLEAR_INCREASE_PHASE2_COMBINED_USERCLK1

RCA_TRANSPORT_POWER_W=
    0.300000
PHASE2_XDMA_TRANSPORT_POWER_W=
    0.377000

RCA_CAPTURE_POWER_W=
    0.017000
PHASE2_CAPTURE_POWER_W=
    0.019000

RCA_NVP_AUTOINIT_POWER_W=
    0.002000
PHASE2_NVP_AUTOINIT_POWER_W=
    0.002000

RCA_NVP_PHYSICAL_FRONTEND_POWER_W=
    0.001000
PHASE2_NVP_PHYSICAL_FRONTEND_POWER_W=
    0.149000

RCA_NVP_TOTAL_POWER_W=
    0.003000
PHASE2_NVP_TOTAL_POWER_W=
    0.151000

HIERARCHY_POWER_LEADING_DELTA=
    RAW_NVP_PHYSICAL_FRONTEND_PLUS_0.148_W;RESOURCE_SLICED_CLOCKING_IP_PLUS_0.117_W
HIERARCHY_POWER_CLASSIFICATION=
    CLEAR_INCREASE_PHASE2_NVP_PHYSICAL_TRANSPORT_AND_CLOCKING_IP

STATIC_OR_LOW_FREQUENCY_VCCO_LOADING_HYPOTHESIS=
    INCONCLUSIVE_REPORT_POWER_LIMITATION
STATIC_FPGA_IO_BANK14_DC_LOAD_DIFFERENCE=
    INCONCLUSIVE_PER_BANK_VCCO_UNAVAILABLE
ON_CHIP_SWITCHING_RETURN_PATH_CONTEXT=
    SUPPORTED_BY_CLEAR_CORE_RAIL_CLOCKING_AND_HIERARCHY_DELTAS
POWER_BREAKDOWN_DECISION_CASE=
    CASE_D_INCONCLUSIVE_REPORT_POWER_LIMITATION

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

SSN_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO

ROOT_CAUSE_SOLELY_PROVEN=
    NO

FULL_BUILDS=
    0

SOURCE_CHANGES=
    0

OPERATING_CONDITION_CHANGES=
    0

SWITCHING_ACTIVITY_CHANGES=
    0

HARDWARE_ACTIONS=
    0

FORMAL_REPOSITORY_MUTATIONS=
    0

EVIDENCE_PACKAGE_SHA256=
    RECORDED_IN_RCA_VS_FORMAL_PHASE2_POWER_BREAKDOWN_EVIDENCE_SHA256.txt
EVIDENCE_REPOSITORY_COMMIT=
    SELF_COMMIT_RECORDED_IN_LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_RAIL_DOMAIN_AND_HIERARCHY_BREAKDOWN
```
