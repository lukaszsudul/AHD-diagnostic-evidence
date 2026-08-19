# AHD v41 Phase-3 NVP/I2C ACK shadow-monitor R2 evidence

## Purpose

This directory preserves the independently reviewable evidence from one
ephemeral observer-only R2 measurement. R2 retained the unchanged Phase-2 NVP
I2C behavior and added read-only observation of complete transaction context
and early/mid/late samples during the actual SCL-HIGH slave-ACK opportunity.

## Sealed identities

```text
FORMAL_BASELINE_TAG=v41.0.0-phase2-p2
FORMAL_CHECKPOINT_COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
OBSERVER_R2_PATCH_SHA256=78C2D4099A20F1A8C81D15CBE7E7AB15E7F041FBA9C03A07AE83593CCD2F0E51
OBSERVER_R2_BIT_SHA256=FCAE29F83904F69487545400AB83756ADA9FFC99A78C0A387DD4604A130CD43A
R2_BUILD_PACKAGE_SHA256=72F72F7F81B160F0DCFEB5E9C6C4DB67E77C0B5C79484B154A7122CC6F9FBC79
R2_MEASUREMENT_PACKAGE_SHA256=39C914F06865A140C1F6EA0D651A2DC257561F401CC184F89E1942BF1F5C2634
```

## Result

The valid first-NACK sample was address-write byte `0x60`, operation `0x1F`,
bank `5`, pending register `0x58`, value `0x00`.

The unchanged functional FSM recorded NACK while SCL was LOW. During the
subsequent valid SCL-HIGH ACK interval, the master had released both lines and
SDA stayed HIGH at early, midpoint and late observations. All synchronized and
filtered SDA/SCL stages agreed.

```text
R2_FALSE_NACK_COUNT=0
R2_REAL_DIGITAL_NACK_COUNT=1
R2_INVALID_ACK_WINDOWS=0
R2_PRIMARY_CLASSIFICATION=REAL_DIGITAL_NACK_AT_CORRECT_ACK_PHASE_CONFIRMED
TRACE_TELEMETRY_CORRELATION=PASS
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
```

This proves a real digital NACK at the FPGA input path for the captured
correct-phase ACK opportunity. It does not distinguish actual NVP refusal from
analog threshold, rail/reset readiness, or another physical-chain condition.
It also does not make the separately proven early functional decision phase
architecturally correct.

## Safety and scope

```text
FUNCTIONAL_I2C_CHANGE=NO
AXIL_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHASE3_RESUMED=NO
PRODUCTION_FIX_INTEGRATED=NO
FORMAL_PROJECT_REPOSITORY_MUTATIONS=0
```

The build package is stored with Git LFS. The raw trace and all decoded CSV
files remain normal Git objects for direct review.
