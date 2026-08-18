# V41 NVP Ephemeral Digital Trace Report

## 1. Executive summary

One non-Git, observer-only diagnostic image was built from an exact archive of
the accepted Phase-2 functional source. It passed simulation, one-way observer
safety, timing, DRC, CDC, bus-skew, reset/fanout, resource, AXI-Lite-map, XDMA,
and v40B/AXIS gates. It was programmed once, its frozen trace was retrieved
read-only after the required warm reboot, and the exact accepted formal
Phase-2 image was then restored once and verified after a second warm reboot.

The trace reproduced the NVP failure at the address ACK for operation `0x0E`.
At the exact decision strobe, SDA stage 1, stage 2, and the stable-filter output
were all HIGH, so the literal decision-tree result is D3. The pre-trigger trace
provides a more specific and important timing fact: all three SDA stages were
LOW for 618 samples (9.888 microseconds) while SCL was observed HIGH and both
lines were released by the master. The master then drove SCL LOW; SDA returned
HIGH, and the FSM made its NACK decision 10.000 microseconds later while it was
still actively driving SCL LOW.

Thus, the FPGA did not see ACK at its current decision instant, but it did see
a sustained ACK-like LOW during the preceding SCL-HIGH ownership window. The
evidence strongly supports an ACK-decision timing/phase limitation. It does not
provide analog voltage, threshold, edge-rate, ringing, or rail information and
does not by itself exclude an electrical contribution.

No functional correction was made. Phase 3 remains paused.

## 2. Formal baseline and repository isolation

The formal repository remained on branch `v41/xdma-v40.1.0-base` at
`c89e88bcdf389614c884fb129e8b2d42a585bccb`. The immutable
`v41.0.0-phase2-p2` tag still resolves to that commit and its original annotated
tag object. The complete before/after branch and tag ref sets match; status,
tracked diff, staged diff, and untracked inventory remain empty.

The diagnostic source was exported from functional commit
`fd32fcb65be3f1a59c569874195d1faeaf7d27e9` into a non-Git ASCII-only tree.
No branch, worktree, commit, push, tag, merge, or repository configuration
change occurred.

## 3. Observer design and offline qualification

The recorder sampled the existing synchronized/filtered SDA and SCL stages,
open-drain drive enables, exact ACK-decision and first-NACK events, FSM/phase/
operation/byte context, reset/power enables, and init state at 62.5 MHz. It used
a 4096 x 64-bit frozen circular trace with 3072 pre-trigger and 1024
post-trigger samples. Its BRAM and trigger metadata were independent of PCIe
`user_reset` and were proven byte-identical across that reset in simulation.

The new host window was read-only and non-aliased:

```text
STATUS=0x02000..0x020FF
TRACE=0x03000..0x0AFFF
BAR0=0x00000..0x1FFFF
```

Two local build cycles were used. Cycle 1 stopped at RTL elaboration because
two observer-only VHDL-2008 constructs were incompatible with the preserved
project mode. Cycle 2 used the smallest syntax-only observer correction and
passed all gates:

```text
FULLY_ROUTED=YES
WNS_NS=0.617
TNS_NS=0
WHS_NS=0.019
THS_NS=0
DRC_ERRORS=0
DRC_CRITICAL_WARNINGS=0
CRITICAL_CDC_RULE_TYPES=0
BUS_SKEW_VIOLATIONS=0
TRACE_TO_FUNCTIONAL_FANOUT=0
RAW_SDA_PROTOCOL_FANOUT_CHANGED=0
RAW_SCL_PROTOCOL_FANOUT_CHANGED=0
PROHIBITED_NVP_RST_FANIN=0
EXISTING_53_REGISTER_OFFSETS_CHANGED=0
EXISTING_53_REGISTER_SEMANTICS_CHANGED=0
XDMA_CONFIGURATION_CHANGED=0
V40B_AXIS_CONTRACT_CHANGED=0
RESOURCE_DECISION=PROCEED_DIAGNOSTIC
```

## 4. Hardware measurement

The diagnostic image programmed on its only authorized attempt with EOS HIGH
and DONE 1. The required warm reboot produced boot ID
`fbb23d86-fecd-40ed-8ac1-df3cbcf6185b`; A35T identity/DONE, endpoint, BARs,
Gen1 x1 link, pinned XDMA driver, and nodes all passed.

The runtime diagnostic identity matched the sealed source and patch. The trace
was frozen, full, and non-overflowed, with trigger reason FIRST_NACK and trigger
index 3072. The read-only dump performed 8,227 AXI-Lite reads and zero writes.

## 5. Digital ACK analysis

The first-error telemetry was:

```text
INIT_DONE=1
INIT_ERROR=1
NACK_COUNT=16
TIMEOUT_COUNT=0
FIRST_ERROR_PHASE=ADDRESS_BYTE_NACK
FIRST_ERROR_STEP=0x0E
FIRST_ERROR_META_BANK=0x05
FIRST_ERROR_PHYSICAL_BANK=0x05
FIRST_ERROR_REGISTER=0x08
FIRST_ERROR_VALUE=0x50
CURRENT_TX_BYTE=0x60
```

At the exact trigger:

```text
SDA_STAGE1=1
SDA_STAGE2=1
SDA_FILTERED=1
SCL_STAGE1=0
SCL_STAGE2=0
SCL_FILTERED=0
SDA_DRIVE_LOW=0
SCL_DRIVE_LOW=1
ACK_VALUE_USED_BY_FSM=0
BYTE_PHASE=0x01
OPERATION_INDEX=0x0E
```

The trace/telemetry phase and operation correlation passed. The extended
pre-trigger chronology is preserved in
`07_MEASUREMENT/FPGA_FIRST_ERROR_VS_TRACE_CORRELATION.md` and the full CSV.

The dump tool emitted a conservative secondary SCL-release heuristic. The
captured post-trigger path reached synchronized and filtered HIGH after release,
with the filter reaching HIGH in 128 ns. The data do not establish clock
stretching or an analog rise-time violation, so neither is claimed.

## 6. Formal restoration

Only after the measurement ZIP and internal manifest passed was the accepted
formal bit rehashed and programmed once. EOS was HIGH and DONE was 1. The final
warm reboot produced boot ID `6ef0e577-8912-4bec-b3c4-ed9404446b59`.

Formal runtime identity, endpoint, BARs, Gen1 x1, pinned driver/nodes, and final
JTAG DONE passed. The statically proven safe read of formal address `0x2000`
returned `0x00000000`, so diagnostic magic is absent and the diagnostic image
is not active. The contextual formal NVP status remained failed (15 NACKs,
first register-byte NACK at step `0x06`); an NVP pass was explicitly not a
restoration criterion.

## 7. Packages

```text
DIAGNOSTIC_BUILD_PACKAGE_SHA256=91642DBA5F12317EB56FF6C65BD1A3AD582FCA60022E7C0851FB03FFBB7FAADA
DIAGNOSTIC_MEASUREMENT_PACKAGE_SHA256=0C204F94A6C6CE228F60AAD63752F5C7BFAAABF4D9B726CEA615B3ADA2A99732
BUILD_PACKAGE_ZIP_OPENS=YES
BUILD_PACKAGE_MANIFEST_PASS=YES
MEASUREMENT_PACKAGE_ZIP_OPENS=YES
MEASUREMENT_PACKAGE_MANIFEST_PASS=YES
PACKAGE_SECRET_SCAN=NO_MATCHES
```

## 8. Final decision

The observer answered the narrow diagnostic question without changing the
functional I2C path. The next technically justified step is owner/auditor
review followed, only under separate authorization, by a controlled ACK-sample
phase experiment such as the previously described Z8-style mid-SCL-HIGH
sampling. No such change is made here.

```text
BUILD_TYPE=EPHEMERAL_DIAGNOSTIC_OBSERVER_ONLY

FORMAL_BASELINE_TAG=v41.0.0-phase2-p2
FORMAL_BASELINE_CHECKPOINT_COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
FORMAL_PHASE2_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

DIAGNOSTIC_PATCH_SHA256=0D7BD2907296D65401D83EF9F41CF7270940DF4FB392264C32B76E455CD45A6F
DIAGNOSTIC_SOURCE_MANIFEST_SHA256=3C415A97490E723829E6DE3A1B9F2CDE0F3A2A5AE605A1996A613A50CAF597BD
DIAGNOSTIC_BIT_SHA256=DA7489BD3458A0DFD5FC8F86D1E3CD90F2DFCAC8CE7FA87D0CC5AD7307B459E3

TRACE_SCHEMA_VERSION=0x00010000
TRACE_SAMPLE_CLOCK_HZ=62500000
TRACE_SAMPLE_WIDTH_BITS=64
TRACE_SAMPLE_DEPTH=4096
TRACE_PRE_TRIGGER_SAMPLES=3072
TRACE_POST_TRIGGER_SAMPLES=1024

OBSERVED_EARLIEST_SDA_STAGE=SYNC_STAGE1
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO

DIAGNOSTIC_PROGRAM_EOS=HIGH
DIAGNOSTIC_PROGRAM_DONE=1
DIAGNOSTIC_WARM_REBOOT=PASS

DIAG_MAGIC=0x4E565054
DIAG_FLAGS=0x00000003
TRACE_FROZEN=1
TRACE_OVERFLOW=0
TRACE_TRIGGER_REASON=FIRST_NACK
TRACE_TRIGGER_INDEX=3072

FPGA_INIT_DONE=1
FPGA_INIT_ERROR=1
FPGA_NACK_COUNT=16
FPGA_TIMEOUT_COUNT=0
FPGA_FIRST_ERROR_PHASE=ADDRESS_BYTE_NACK
FPGA_FIRST_ERROR_STEP=0x0E
FPGA_FIRST_ERROR_BANK=0x05
FPGA_FIRST_ERROR_REGISTER=0x08
FPGA_FIRST_ERROR_VALUE=0x50

TRACE_SDA_STAGE1_AT_ACK=1
TRACE_SDA_STAGE2_AT_ACK=1
TRACE_SDA_FILTERED_AT_ACK=1
TRACE_SCL_STAGE1_AT_ACK=0
TRACE_SCL_STAGE2_AT_ACK=0
TRACE_SCL_FILTERED_AT_ACK=0
TRACE_SDA_DRIVE_LOW_AT_ACK=0
TRACE_SCL_DRIVE_LOW_AT_ACK=1
TRACE_ACK_VALUE_USED_BY_FSM=0

TRACE_TELEMETRY_CORRELATION=PASS
PRIMARY_CLASSIFICATION=NO_DIGITAL_ACK_OBSERVED_AT_FPGA_INPUT_PATH
DIGITAL_ACK_LIKE_LOW_PRESENT_DURING_PRECEDING_SCL_HIGH=YES
ACK_DECISION_OCCURS_AFTER_OBSERVED_ACK_WINDOW=STRONGLY_SUPPORTED

FORMAL_RESTORE_PROGRAM_EOS=HIGH
FORMAL_RESTORE_PROGRAM_DONE=1
FORMAL_RESTORE_WARM_REBOOT=PASS

FORMAL_RUNTIME_IDENTITY=PASS_A40A0C07_0000400B_00031002
DIAGNOSTIC_MAGIC_PRESENT_AFTER_RESTORE=NO
FORMAL_BASELINE_RESTORED=YES
DIAGNOSTIC_BIT_ACTIVE=NO

FORMAL_REPOSITORY_MUTATION=0
GIT_COMMIT=NO
GIT_PUSH=NO
TAG=NO
RELEASE_CANDIDATE=NO
FUNCTIONAL_I2C_CHANGE=NO

DIAGNOSTIC_LOCAL_BUILD_CYCLES=2
DIAGNOSTIC_SRAM_PROGRAM_ATTEMPTS=1
FORMAL_RESTORE_PROGRAM_ATTEMPTS=1
COLD_STARTS=0
UBUNTU_WARM_REBOOTS=2
AXIL_WRITES=0
PHASE3_STRESS_READS=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHASE3_RESUMED=NO
PHASE4_STARTED=NO

TEMP_DIAGNOSTIC_WORKSPACE_DELETED=YES
DIAGNOSTIC_EVIDENCE_RETAINED_OUTSIDE_REPO=YES

NEXT_ACTION=OWNER_AUDITOR_REVIEW_AND_SEPARATE_CORRECTIVE_AUTHORIZATION
```
