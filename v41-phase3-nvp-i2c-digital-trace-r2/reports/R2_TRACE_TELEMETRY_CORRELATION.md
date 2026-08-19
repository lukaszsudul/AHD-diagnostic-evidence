# R2 physical-phase shadow ACK versus FPGA telemetry correlation

## Identity and validity

```text
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
OBSERVER_R2_PATCH_SHA256=78C2D4099A20F1A8C81D15CBE7E7AB15E7F041FBA9C03A07AE83593CCD2F0E51
R2_BIT_SHA256=FCAE29F83904F69487545400AB83756ADA9FFC99A78C0A387DD4604A130CD43A
DIAG_MAGIC=0x4E565052
DIAG_SCHEMA=0x00020000
DIAG_FLAGS=0x00000003
TRACE_FROZEN=1
TRACE_OVERFLOW=0
TRACE_TRIGGER_REASON=FIRST_NACK
TRACE_TELEMETRY_CORRELATION=PASS
```

The trace, context ring and shadow-event log survived the required PCIe-domain
warm reboot and were accepted by the identity-gated read-only dump tool. The
tool performed 11,456 MMIO reads and zero writes.

## First functional NACK

The first-NACK shadow record is event 144, operation 31 (`0x1F`), slot 30,
`WRITE_ADDRESS`, transmitting wire byte `0x60` for pending register `0x58`,
value `0x00`, meta/physical bank `5`.

At the unchanged functional decision instant:

```text
FUNCTIONAL_ACK_DECISION=NACK_HIGH
FUNCTIONAL_DECISION_SDA=1
FUNCTIONAL_DECISION_SCL=0
FUNCTIONAL_DECISION_SDA_DRIVE_LOW=0
FUNCTIONAL_DECISION_SCL_DRIVE_LOW=1
```

The observer then saw a valid 626-cycle SCL-HIGH interval. The master released
both SDA and SCL, and all synchronized/filtered samples remained HIGH:

| Correct-phase sample | Offset (cycles) | SDA stage 1 | SDA stage 2 | SDA filtered | SCL stage 1 | SCL stage 2 | SCL filtered |
|---|---:|---:|---:|---:|---:|---:|---:|
| Early high | 9 | 1 | 1 | 1 | 1 | 1 | 1 |
| Mid high | 313 | 1 | 1 | 1 | 1 | 1 | 1 |
| Late high | 626 | 1 | 1 | 1 | 1 | 1 | 1 |

```text
SDA_RELEASED_DURING_ACK=1
SCL_RELEASED_DURING_ACK=1
SCL_HIGH_OBSERVED=1
HALF_PHASE_CYCLES=626
MID_HIGH_OFFSET_CYCLES=313
SHADOW_CORRECT_PHASE_ACK=NACK_HIGH
```

The frozen diagnostic first-error tuple and the formal telemetry agree:

```text
FIRST_ERROR_VALID=1
FIRST_ERROR_PHASE=1
FIRST_ERROR_STEP=0x1F
FIRST_ERROR_META_BANK=5
FIRST_ERROR_PHYSICAL_BANK=5
FIRST_ERROR_REGISTER=0x58
FIRST_ERROR_VALUE=0x00
CORRELATION=PASS
```

## Post-capture bounded telemetry

Across a 1.040-second read-only interval:

```text
INIT_DONE=1
INIT_ERROR=1
NACK_COUNT=20
TIMEOUT_COUNT=0
VCLK_DELTA=154470696
SAV_DELTA=0
FRAME_DELTA=0
ENDPOINT=10ee:7011
LINK=Gen1_x1
BAR0=128_KiB
BAR1=64_KiB
XDMA_DRIVER_COMMIT=8721136e74a66500b02d16cb41922d966139cd46
KERNEL_PCIE_XDMA_CRITICAL_ERRORS=0
```

## Classification

```text
R2_FALSE_NACK_COUNT=0
R2_REAL_DIGITAL_NACK_COUNT=1
R2_INVALID_ACK_WINDOWS=0
R2_PRIMARY_CLASSIFICATION=REAL_DIGITAL_NACK_AT_CORRECT_ACK_PHASE_CONFIRMED
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
```

The slave did not drive a digital ACK low during the observed correct-phase
ACK opportunity. This does not distinguish an actual NVP refusal from an
analog threshold, power/reset readiness, or physical-chain issue. It also does
not erase the separately proven architectural defect that the unchanged FSM
decides while SCL is low.

