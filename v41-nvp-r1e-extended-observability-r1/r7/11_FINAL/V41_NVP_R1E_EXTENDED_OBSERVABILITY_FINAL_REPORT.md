# V41 NVP R1e extended-observability final report — R7

## Authoritative outcome

R7 completed the frozen R1e campaign and left the board in the required exact
formal Phase-2 state. The task used the selected
`Xilinx/80802026a98b01` JTAG adapter throughout, consumed exactly the three
authorized program invocations, performed exactly three warm reboots and
three exact pinned-driver loads, and used no retry. All programming operations
reported vendor startup HIGH, same-session DONE=1, independent immediate
DONE=1, and final DONE=1.

Both new scientific samples are infrastructure-valid. Arm A, the exact R1e
25-kHz image, and Arm B, the exact formal 50-kHz control, both reached
`INIT_DONE=1` but returned functional NVP failure. Arm A recorded 13 autoinit
NACKs and its independent post-init address probe recorded 29 NACKs in 10,000
attempts. Arm B recorded 15 autoinit NACKs. This is a complete valid paired
sample, not an infrastructure-inconclusive result.

The terminal state is exact formal Phase 2 with runtime identity
`A40A0C07 / 0000400B / 00031002`, diagnostic magic zero, the exact pinned
XDMA driver loaded and bound, the deterministic R1e page zero, and selected-
JTAG DONE=1.

## Frozen implementation and evidence lineage

R3 completed the immutable R1e implementation and bitstream. R4 preserved the
completed image but stopped after its single bootstrap program returned vendor
startup LOW. R5 established a post-cold-reset kernel-29 baseline but stopped at
the legacy-HS2 target gate. R6 adopted the selected Xilinx adapter and proved
ten stable read-only samples at DONE=0, then stopped before programming because
the inherited observer required pre-program DONE=1 for every role. R7 preserves
all those historical outcomes unchanged.

| Object | Exact identity |
|---|---|
| R6 authoritative report | `9978358768EC0A12CEEDC89CC1C22705A2C92B662C9A595966300B3D1020F15E` |
| R6 evidence commit | `636d8e5af51746ff5a439d39e576630d4c0edb02` |
| R6 evidence package | `E01DDA8A7DB7899178AD62E6E4B8F0F0E11FDF8F82FAE7039A37960F271AFCF1` |
| R1e source commit | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` |
| R1e source tree | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| R1e routed DCP | `1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1` |
| R1e bitstream | `0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9` |
| Formal bitstream | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |

Both bitstreams were 2,192,144 bytes. R7 performed no build, synthesis,
implementation, bitstream generation, FPGA-source edit, DCP mutation, or
formal-repository mutation.

## R7 observer correction and offline gates

The task-local observer change is confined to the pre-program contract. Its
SHA-256 is
`55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7`.
Bootstrap mode accepts five readable stable DONE samples of either all zero or
all one. Transition mode accepts only five ones plus the phase-appropriate
configured-image receipt. The selected-target logic, single-invocation logic,
vendor startup parser, post-program DONE gate, process-exit gate, BIT4
prohibition, and no-retry behavior remain unchanged.

All 12 mode-aware fixtures passed, including bootstrap DONE0/DONE1, unstable
and unreadable preconditions, startup LOW after one consumed invocation,
transition receipt failures, duplicate invocation, BIT4, and target mismatch.
The exact R6 evidence replay classified the old observer as blocked and the R7
bootstrap precondition as passing, while retaining R6 program count zero.
Frozen target-selector, BAR-parser, identity, lifecycle, ordered-log, probe,
Wilson-interval, zero-NACK, formal-page-zero, R1e-reader, and transcript-parser
fixtures all passed. All-ones runtime identity was rejected.

## Fresh R7 qualification

Two independent read-only SSH baseline sessions passed over more than three
seconds on boot ID `dd140158-f8dc-46eb-9a05-27bb532713aa`. Both reported
kernel `7.0.0-29-generic`, strictly increasing uptime, and the same proven
next-reboot kernel.

One independent Hardware Manager session then passed five of five refresh
samples on
`localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`. Every sample selected one
target and one `xc7a35t` device with IDCODE `0362D093`; DONE was readable and
stable at zero. The adapter reported its default frequency as 6,000,000 Hz,
which R7 did not change.

The read-only pre-bootstrap host gate passed. The endpoint, XDMA driver, and
nodes were absent and accepted for bootstrap entry; node owners and task DMA
were zero; kernel/AER health passed; the next-boot kernel remained exact; and
all three loader evidence directories were fresh.

## Exact formal bootstrap

The mode-aware bootstrap sampled pre-program DONE as `0,0,0,0,0`, programmed
the exact formal bit once, and passed vendor startup HIGH, same-session DONE=1,
process exit zero, and an independent DONE=1 session. The enforced monotonic
wait was 146.671044300 seconds, exceeding the required five seconds.

One warm reboot changed the boot ID to
`093fec43-4e32-4c5a-87cc-cbaa389662a1`. Kernel 29, Gen1 x1, BAR0 131,072
bytes, and BAR1 65,536 bytes passed. The exact explicit-path module loaded
once, produced the expected 21-node set, and bound to the one expected
endpoint. Both readers proved the exact formal identity and diagnostic magic
zero. Fresh final selected-JTAG DONE was one. The sealed formal-ready receipt
has SHA-256
`1E9F7530C5A0E34CE9CCC299C6CC558AE6C46E4C2A073BAF16D17EC8BBD1D879`.

## Arm A — exact R1e

Arm A entered transition mode using the formal-ready receipt and sampled
pre-program DONE as `1,1,1,1,1`. The exact R1e bit programmed once and passed
startup HIGH, same-session DONE=1, independent DONE=1, and a 148.823942200-
second monotonic wait. One warm reboot changed the boot ID to
`c6cf85f0-0a06-4d2f-8656-5bca7cbb19a3`; kernel, BAR geometry, exact pinned
load, 21 nodes, health, source commit, build flags `0x00000002`, common
identity, lifecycle magic, and final DONE all passed.

Both read-only snapshots were coherent and their required static fields
matched. The lifecycle counter used the frozen pre-increment capture
convention:

```text
ACTUAL_CNT_AT_INIT_DONE=132688568
EXPECTED_CNT_AT_INIT_DONE=132584734
SIGNED_COUNT_ERROR_CYCLES=+103834
SHORTENING_CYCLES=0
EXTENSION_CYCLES=103834
EXTENSION_TICKS_EXACT=83.00079936051159
EXTENSION_TICKS_NEAREST=83
EXTENSION_RESIDUAL_CYCLES=1
```

Arm A recorded 13 aggregate autoinit NACKs and zero timeouts. The ordered log
contained eight records with overflow set, so only the first eight are known:

```text
0x0003000000440229  0x0003000000440329
0x000305053026013B  0x000305053026023B
0x000305053026033B  0x0003020900FF0156
0x0003020900FF0256  0x0003000018A00169
```

The first-eight phase distribution was write-address ACK 3, register-address
ACK 3, and data ACK 2; operation indices were 41:2, 59:3, 86:2, and 105:1.
The bank/register groups were `(0,0,0x44):2`, `(5,5,0x26):3`,
`(9,2,0xFF):2`, and `(0,0,0xA0):1`. Header and first-error consistency passed.

The valid post-autoinit write-address probe completed all 10,000 attempts:
9,971 ACK, 29 NACK, and zero timeout. Its NACK rate was 0.0029 (0.29%, 2,900
ppm), with Wilson 95% interval
`[0.0020199966335610452, 0.004161774546565626]`, first NACK index 318, last
index 9749, and maximum consecutive NACKs one. The probe establishes only
post-autoinit write-address ACK reliability at 25 kHz.

Arm A reached INIT_DONE but also asserted INIT_ERROR; VCLK advanced while SAV
and frame counters did not. Its classification is `R1E_NVP_FAIL`. The valid
Arm-A receipt has SHA-256
`B74C6B83F9DE583397EDF7A5B7E192401B05D3DEDBDFA9A01E1352809F68AFCB`.

## Arm B — exact formal control and final restoration

Arm B entered transition mode using the valid Arm-A receipt and sampled
pre-program DONE as `1,1,1,1,1`. The exact formal bit programmed once and
passed startup HIGH, same-session DONE=1, independent DONE=1, and a
152.181813900-second wait. One warm reboot changed the boot ID to
`e2a2517a-c275-4ea9-bf11-83c0db94111e`. The exact kernel, Gen1 x1 link, BAR
geometry, explicit pinned load, module identity, 21 nodes, formal runtime
identity, diagnostic magic zero, R1e page zero, health, two coherent snapshots,
and final DONE=1 all passed.

Arm B recorded 15 aggregate autoinit NACKs and zero timeouts. Its ordered log
also contained eight records with overflow set:

```text
0x0003050584500230  0x0003050584500330
0x0003010100C80292  0x0003010100C80392
0x00030909C35602CA  0x00030909C35603CA
0x00030909525B01CF  0x00030909525B02CF
```

The first-eight phase distribution was write-address ACK 1, register-address
ACK 4, and data ACK 3; operation indices 48, 146, 202, and 207 each appeared
twice. The bank/register groups were `(5,5,0x50):2`, `(1,1,0xC8):2`,
`(9,9,0x56):2`, and `(9,9,0x5B):2`. Header and first-error consistency passed.
Arm B reached INIT_DONE but asserted INIT_ERROR; VCLK advanced while SAV and
frame counters did not. Its classification is `FORMAL_NVP_FAIL`.

## Paired scientific interpretation

The paired classification is `COMPLETE_VALID_PAIRED_SAMPLE`: both instruments
and infrastructure were valid, while both images functionally failed. The
NACK observations span both arms, multiple autoinit phases and operations, and
the independent post-init Arm-A address probe. This strongly supports a
stochastic address-or-bus margin phenomenon and weakens an explanation unique
to one autoinit operation. Post-init versus autoinit context dependence remains
unresolved because the post-init probe itself also observed NACKs.

Arm A was extended, not shortened, by 103,834 cycles. Therefore control-flow
shortening reconciliation is not applicable. Both ordered logs overflowed, so
any exact extension decomposition is non-unique and limited to the first eight
records; omitted records are not inferred. The data do not solely prove a root
cause, board VCCO droop, ground bounce, or any directly measured analog margin.
The selected adapter and observer-contract correction are infrastructure
context only and are not treated as an NVP causal variable.

## Audit qualifications and complete accounting

Two bounded task-local evidence-helper corrections were required after live
operations: whitespace in the read-only TCP host-cycle helper, and acceptance
of duplicate-identical (but never conflicting) BAR lines in the configured-
image receipt helper. Neither correction performed a live action or changed
programming, FPGA, driver, telemetry, or scientific semantics. Both original
and corrected hashes and focused audits are preserved.

For Arm B, the one reboot submission passed and the boot ID changed, but the
delayed TCP observer began after the host had returned and saw 296/296 UP
samples. Its retained no-DOWN result is not represented as a direct down/up
observation. The successful single submission plus changed boot ID, returned
kernel-29 host, and passed pre-loader evidence prove the reboot transition. No
second Arm-B reboot occurred.

Actual R7 accounting is three program invocations, three warm reboots, three
exact driver loads, zero retries, zero cold starts, zero physical actions,
zero JTAG-frequency changes, zero kernel/GRUB changes, zero PCI remove/rescan,
zero AXI-Lite writes, and zero DMA transfers. The manifest and package hashes,
and the containing public Git commit, are necessarily non-circular external
receipts: a file cannot embed the hash of a ZIP or commit that includes that
same file. The required final block therefore points to the external sidecar
and publication receipt; the concrete values are published alongside this
report and returned to the owner.

## Required final block

```text
TASK=
    V41_NVP_R1E_MODE_AWARE_BOOTSTRAP_FROM_DONE0_AND_COMPLETE_PAIRED_AB_R7

FINAL_REPORT_COUNT=
    1

R6_REPORT_SHA256=
    9978358768EC0A12CEEDC89CC1C22705A2C92B662C9A595966300B3D1020F15E
R6_EVIDENCE_COMMIT=
    636d8e5af51746ff5a439d39e576630d4c0edb02
R6_EVIDENCE_PACKAGE_SHA256=
    E01DDA8A7DB7899178AD62E6E4B8F0F0E11FDF8F82FAE7039A37960F271AFCF1

R6_STOP_CLASSIFICATION=
    BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT

R6_SELECTED_JTAG=
    Xilinx/80802026a98b01

R6_JTAG_TRANSPORT_STABILITY=
    PASS_10_OF_10

R6_PREPROGRAM_DONE=
    STABLE_0

R6_FPGA_PROGRAMS=
    0

R7_OBSERVER_DELTA_CLASSIFICATION=
    PREPROGRAM_DONE_MODE_AND_RECEIPT_ONLY

R7_BOOTSTRAP_PREPROGRAM_DONE_0_ACCEPTED=
    YES

R7_TRANSITION_PREPROGRAM_DONE_0_ACCEPTED=
    NO

R7_POSTPROGRAM_GATES_CHANGED=
    NO

MODE_AWARE_OBSERVER_SHA256=
    55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7
MODE_AWARE_OBSERVER_FIXTURES=
    PASS_ALL_12_OF_12
R6_REPLAY_RESULT=
    PASS_EXPECTED_CONTRACT_DIFFERENCE

R7_SELECTED_JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

R7_FULL_JTAG_TARGET_PATH=
    localhost:3121/xilinx_tcf/Xilinx/80802026a98b01

R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

FULL_BUILDS_THIS_TASK=
    0

SYNTHESIS_RUNS_THIS_TASK=
    0

IMPLEMENTATION_RUNS_THIS_TASK=
    0

BITSTREAMS_GENERATED_THIS_TASK=
    0

FPGA_SOURCE_CHANGES_THIS_TASK=
    0

R7_HOST_BASELINE=
    PASS_2_OF_2
R7_BOOT_ID_BASELINE=
    dd140158-f8dc-46eb-9a05-27bb532713aa
NEXT_REBOOT_KERNEL_PROVEN=
    7.0.0-29-generic

READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=
    1

R7_JTAG_RECONFIRMATION_SAMPLES=
    5

R7_PREPROGRAM_DONE_VALUE=
    0
R7_JTAG_RECONFIRMATION_GATE=
    PASS_5_OF_5

PRE_BOOTSTRAP_ENDPOINT_STATE=
    ABSENT_ACCEPTED
PRE_BOOTSTRAP_DRIVER_STATE=
    ABSENT_ACCEPTED
PRE_BOOTSTRAP_NODE_OWNERS=
    0
PRE_BOOTSTRAP_DMA=
    0
PRE_BOOTSTRAP_HOST_SAFETY_GATE=
    PASS

FORMAL_BOOTSTRAP_OBSERVER_MODE=
    BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM

FORMAL_BOOTSTRAP_PREPROGRAM_DONE_SAMPLES=
    0,0,0,0,0
FORMAL_BOOTSTRAP_PREPROGRAM_DONE_VALUE=
    0
FORMAL_BOOTSTRAP_PROGRAM=
    PASS_STARTUP_HIGH_DONE_1
FORMAL_BOOTSTRAP_VENDOR_STARTUP=
    HIGH_LABTOOLS_27_3164
FORMAL_BOOTSTRAP_SAME_SESSION_DONE=
    1
FORMAL_BOOTSTRAP_INDEPENDENT_DONE=
    1
FORMAL_BOOTSTRAP_WAIT_SECONDS=
    146.671044300
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
    YES_093fec43-4e32-4c5a-87cc-cbaa389662a1
FORMAL_BOOTSTRAP_KERNEL=
    7.0.0-29-generic
FORMAL_BOOTSTRAP_BAR0_BYTES=
    131072
FORMAL_BOOTSTRAP_BAR1_BYTES=
    65536
FORMAL_BOOTSTRAP_DRIVER=
    PASS_EXACT_PINNED_XDMA_2025.2.0
FORMAL_BOOTSTRAP_RAW_READER_IDENTITY=
    A40A0C07 / 0000400B / 00031002
FORMAL_BOOTSTRAP_ACCEPTED_READER_IDENTITY=
    A40A0C07 / 0000400B / 00031002
FORMAL_BOOTSTRAP_DIAGNOSTIC_MAGIC=
    0x00000000
FORMAL_BOOTSTRAP_FINAL_DONE=
    1
FORMAL_READY_RECEIPT=
    PASS_SHA256_1E9F7530C5A0E34CE9CCC299C6CC558AE6C46E4C2A073BAF16D17EC8BBD1D879

ARM_A_OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE

ARM_A_PREPROGRAM_DONE_SAMPLES=
    1,1,1,1,1
ARM_A_PREPROGRAM_DONE_VALUE=
    1
ARM_A_PROVEN_CONFIGURED_RECEIPT=
    PASS_FORMAL_READY_RECEIPT_SHA256_1E9F7530C5A0E34CE9CCC299C6CC558AE6C46E4C2A073BAF16D17EC8BBD1D879
ARM_A_PROGRAM=
    PASS_STARTUP_HIGH_DONE_1
ARM_A_VENDOR_STARTUP=
    HIGH_LABTOOLS_27_3164
ARM_A_SAME_SESSION_DONE=
    1
ARM_A_INDEPENDENT_DONE=
    1
ARM_A_WAIT_SECONDS=
    148.823942200
ARM_A_BOOT_ID_CHANGED=
    YES_c6cf85f0-0a06-4d2f-8656-5bca7cbb19a3
ARM_A_KERNEL=
    7.0.0-29-generic
ARM_A_BAR0_BYTES=
    131072
ARM_A_BAR1_BYTES=
    65536
ARM_A_DRIVER=
    PASS_EXACT_PINNED_XDMA_2025.2.0
ARM_A_RUNTIME_PROVENANCE=
    PASS_f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd_BUILD_FLAGS_0x00000002
ARM_A_CNT_AT_INIT_DONE=
    132688568
ARM_A_EXPECTED_CNT_AT_INIT_DONE=
    132584734
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
    +103834
ARM_A_SHORTENING_CYCLES=
    0
ARM_A_SHORTENING_TICKS_EXACT=
    0
ARM_A_SHORTENING_TICKS_NEAREST=
    0
ARM_A_SHORTENING_RESIDUAL_CYCLES=
    0
ARM_A_NACK_COUNT=
    13
ARM_A_NACK_LOG_COUNT=
    8
ARM_A_NACK_LOG_OVERFLOW=
    1
ARM_A_ORDERED_NACK_RECORDS=
    0003000000440229,0003000000440329,000305053026013B,000305053026023B,000305053026033B,0003020900FF0156,0003020900FF0256,0003000018A00169_FIRST_8_ONLY
ARM_A_PROBE_COUNT=
    10000
ARM_A_PROBE_ACK_COUNT=
    9971
ARM_A_PROBE_NACK_COUNT=
    29
ARM_A_PROBE_TIMEOUT_COUNT=
    0
ARM_A_PROBE_NACK_RATE=
    0.0029
ARM_A_PROBE_NACK_RATE_PPM=
    2900
ARM_A_PROBE_WILSON95=
    [0.0020199966335610452,0.004161774546565626]
ARM_A_PROBE_FIRST_NACK_INDEX=
    318
ARM_A_PROBE_LAST_NACK_INDEX=
    9749
ARM_A_PROBE_MAX_CONSECUTIVE_NACKS=
    1
ARM_A_NVP_RESULT=
    R1E_NVP_FAIL
ARM_A_FINAL_DONE=
    1
ARM_A_TERMINAL_SAFE_DONE1_RECEIPT=
    PASS_SHA256_F16538E45B86D9D100B047781BA60586CC6A16D1F5FB33DC2480BFB51BC25DEA

ARM_B_OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE

ARM_B_PREPROGRAM_DONE_SAMPLES=
    1,1,1,1,1
ARM_B_PREPROGRAM_DONE_VALUE=
    1
ARM_B_PROVEN_CONFIGURED_RECEIPT=
    PASS_VALID_ARM_A_RECEIPT_SHA256_B74C6B83F9DE583397EDF7A5B7E192401B05D3DEDBDFA9A01E1352809F68AFCB
ARM_B_PROGRAM=
    PASS_STARTUP_HIGH_DONE_1
ARM_B_VENDOR_STARTUP=
    HIGH_LABTOOLS_27_3164
ARM_B_SAME_SESSION_DONE=
    1
ARM_B_INDEPENDENT_DONE=
    1
ARM_B_WAIT_SECONDS=
    152.181813900
ARM_B_BOOT_ID_CHANGED=
    YES_e2a2517a-c275-4ea9-bf11-83c0db94111e
ARM_B_KERNEL=
    7.0.0-29-generic
ARM_B_BAR0_BYTES=
    131072
ARM_B_BAR1_BYTES=
    65536
ARM_B_DRIVER=
    PASS_EXACT_PINNED_XDMA_2025.2.0
ARM_B_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002
ARM_B_DIAGNOSTIC_MAGIC=
    0x00000000
ARM_B_R1E_PAGE_ZERO=
    YES_0x2000_TO_0x20FF
ARM_B_NACK_COUNT=
    15
ARM_B_NACK_LOG_COUNT=
    8
ARM_B_NACK_LOG_OVERFLOW=
    1
ARM_B_ORDERED_NACK_RECORDS=
    0003050584500230,0003050584500330,0003010100C80292,0003010100C80392,00030909C35602CA,00030909C35603CA,00030909525B01CF,00030909525B02CF_FIRST_8_ONLY
ARM_B_NVP_RESULT=
    FORMAL_NVP_FAIL
ARM_B_FINAL_DONE=
    1

PAIRED_AB_RESULT=
    COMPLETE_VALID_PAIRED_SAMPLE
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    NOT_APPLICABLE
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
    STRONGLY_SUPPORTED
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
    WEAKENED_AS_OPERATION_SPECIFIC_ONLY
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=
    UNRESOLVED

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002
FINAL_DIAGNOSTIC_MAGIC=
    0x00000000
FINAL_PINNED_DRIVER_LOADED=
    YES_EXACT_XDMA_2025.2.0
FINAL_DONE=
    1

FORMAL_BOOTSTRAP_PROGRAMS=
    1

ARM_A_PROGRAMS=
    1

ARM_B_PROGRAMS=
    1

FPGA_PROGRAM_INVOCATIONS=
    3

FORMAL_BOOTSTRAP_WARM_REBOOTS=
    1
ARM_A_WARM_REBOOTS=
    1
ARM_B_WARM_REBOOTS=
    1
WARM_REBOOTS=
    3

FORMAL_BOOTSTRAP_DRIVER_LOADS=
    1
ARM_A_DRIVER_LOADS=
    1
ARM_B_DRIVER_LOADS=
    1
DRIVER_LOADS=
    3

PROGRAM_RETRIES=
    0

HISTORICAL_PRETASK_COLD_RESET=
    YES_RECORDED_R5

COLD_STARTS_DURING_R7=
    0

PHYSICAL_ACTIONS_DURING_TASK=
    0

JTAG_FREQUENCY_CHANGES=
    0

KERNEL_OR_GRUB_CHANGES=
    0

PCI_REMOVE_RESCAN_RESETS=
    0

AXI_LITE_WRITES=
    0

C2H_TRANSFERS=
    0

H2C_TRANSFERS=
    0

PHASE3_RESUMED=
    NO

XDMA_DEVELOPMENT_CONTINUED=
    NO

FORMAL_REPOSITORY_MUTATIONS=
    0

OWNER_INTERACTIVE_APPROVAL_REQUESTS=
    0

OWNER_PROMPT_SHA256=
    F7DF54CF287B5DC87B83B956989E43F9550167769DD4D3742526AD9E31AF56E5
EVIDENCE_PACKAGE_SHA256=
    SEE_EXTERNAL_NONCIRCULAR_SHA256_SIDECAR
EVIDENCE_REPOSITORY_COMMIT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_COMPLETED_R1E_RESULTS
```
