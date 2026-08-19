# Z8 midpoint experiment trace and telemetry correlation

## Identity and acquisition gate

The read-only host dump tool accepted the diagnostic identity and acquired the
frozen trace exactly once.

```text
DIAG_MAGIC=0x4E565052
TRACE_SCHEMA_VERSION=0x00030000
DIAG_FLAGS=0x00000007
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
COMBINED_R2_Z8_PATCH_SHA256=9D90016FAD1A1B05C9CA53292F035445350A1143FD0214FC04D58AB9975B4440
TRACE_FROZEN=1
TRACE_OVERFLOW=0
TRACE_TRIGGER_REASON=FIRST_NACK
TRACE_TELEMETRY_CORRELATION=PASS
MMIO_READS_DIAGNOSTIC_DUMP=10424
MMIO_WRITES_DIAGNOSTIC_DUMP=0
```

All downloaded raw and decoded artifacts matched the manifest generated on the
Ubuntu host (`REMOTE_MANIFEST_MISMATCHES=0`).

## First functional NACK

The first NACK record is event 15 at operation 2, slot 1, write-address phase,
for wire address byte `0x60`. The functional and shadow context agree:

```text
ACK_EVENT_INDEX=15
OPERATION_INDEX=2
SLOT_INDEX=1
BYTE_PHASE=WRITE_ADDRESS
TX_BYTE=0x60
META_BANK=0x01
PHYSICAL_BANK=0x00
PHYSICAL_BANK_VALID=1

ORIGINAL_R1_ACK_DECISION=NACK_HIGH
FUNCTIONAL_DECISION_SDA=1
FUNCTIONAL_DECISION_SCL=0
FUNCTIONAL_DECISION_SDA_DRIVE_LOW=0
FUNCTIONAL_DECISION_SCL_DRIVE_LOW=1

Z8_SAMPLE_OFFSET_CYCLES=313
Z8_SAMPLE_OFFSET_US=5.008
Z8_SAMPLE_VALID=1
Z8_SAMPLED_SCL=1
Z8_CONSUMED_ACK=NACK_HIGH

SCL_HIGH_OBSERVED=1
SDA_RELEASED_DURING_ACK=1
SCL_RELEASED_DURING_ACK=1
EARLY_HIGH_SDA_STAGE1=1
EARLY_HIGH_SDA_STAGE2=1
EARLY_HIGH_SDA_FILTERED=1
MID_HIGH_SDA_STAGE1=1
MID_HIGH_SDA_STAGE2=1
MID_HIGH_SDA_FILTERED=1
LATE_HIGH_SDA_STAGE1=1
LATE_HIGH_SDA_STAGE2=1
LATE_HIGH_SDA_FILTERED=1
SHADOW_CORRECT_PHASE_ACK=NACK_HIGH
```

The slave ACK opportunity was valid: SCL reached qualified HIGH and the master
released both open-drain lines. SDA remained digitally HIGH at the early,
midpoint, and late samples. Moving the consumed ACK sample to the midpoint did
not convert this event into an ACK.

## Existing NVP/video telemetry

The bounded read-only T0/T1 telemetry window returned:

```text
INIT_DONE=1
INIT_ERROR=1
NACK_COUNT=20
TIMEOUT_COUNT=0
FIRST_ERROR_VALID=1
FIRST_ERROR_PHASE=WRITE_ADDRESS
FIRST_ERROR_STEP=0x02
FIRST_ERROR_META_BANK=0x01
FIRST_ERROR_PHYSICAL_BANK=0x00
FIRST_ERROR_REGISTER=0xFF
FIRST_ERROR_VALUE=0x00
VCLK_DELTA=154940743
SAV_DELTA=0
FRAME_DELTA=0
ENDPOINT_HEALTH=PASS
XDMA_DRIVER_HEALTH=PASS
FINAL_DONE=1
```

The event record matches the FPGA first-error phase and operation index. The
video clock advances, but SAV and frame counters do not advance; the NVP/video
baseline therefore remains failed.

## Classification

```text
Z8_FALSE_NACK_COUNT=0
Z8_REAL_DIGITAL_NACK_COUNT=1
Z8_INVALID_ACK_WINDOWS=0
Z8_PRIMARY_CLASSIFICATION=Z8_INSUFFICIENT_REAL_DIGITAL_NACK_REMAINS
```

This is the controlling Z8-B outcome. It confirms that this reproduced failure
is a real digital NACK at the correct midpoint sample. It does not prove a sole
electrical, device, reset, power, or signal-integrity cause, and no production
correction is authorized by this experiment.

