# FPGA first-error versus frozen digital trace

## Runtime first-error telemetry

The diagnostic status window and the unchanged formal telemetry agree on the
first failure tuple:

```text
INIT_DONE=1
INIT_ERROR=1
NACK_COUNT=16
TIMEOUT_COUNT=0
FIRST_ERROR_VALID=1
FIRST_ERROR_PHASE=ADDRESS_BYTE_NACK
FIRST_ERROR_STEP=0x0E
FIRST_ERROR_META_BANK=0x05
FIRST_ERROR_PHYSICAL_BANK=0x05
FIRST_ERROR_REGISTER=0x08
FIRST_ERROR_VALUE=0x50
WIRE_ADDRESS_BYTE=0x60
```

Two bounded formal-map snapshots approximately one second apart produced:

```text
VCLK_T0=1262943167
VCLK_T1=1301142140
VCLK_DELTA=38198973
SAV_DELTA=0
FRAME_DELTA=0
```

## ACK-window chronology

The observer clock is 62.5 MHz, so one sample is 16 ns. The following facts
come directly from `TRACE_DECODED.csv` and do not infer analog voltage:

1. During samples 1829 through 2446 (618 cycles, 9.888 microseconds), the
   master had released both SDA and SCL. All synchronized/filtered SCL stages
   were HIGH and all synchronized/filtered SDA stages were LOW. This is a clear
   digital ACK-like LOW during the SCL-HIGH slave-ACK ownership interval.
2. At sample 2447 the master began driving SCL LOW. The synchronized SCL path
   then went LOW. SDA stage 1 became HIGH at sample 2451, stage 2 at 2452, and
   the stable-filter output at 2455, 128 ns after the master began the SCL-LOW
   phase.
3. The unchanged FSM did not assert its qualified ACK-decision/first-NACK event
   until sample 3072, 625 cycles (10.000 microseconds) after sample 2447.
4. At sample 3072 the master was actively driving SCL LOW, every observed SCL
   stage was LOW, SDA was released, every observed SDA stage was HIGH, and the
   FSM used NACK (`ACK_VALUE_USED_BY_FSM=0`).

The exact tap definition states that the decision strobe is asserted on the
qualified clock where the unchanged FSM evaluates `sda_filtered_r` in an
`ACK_*_HIGH` state. The trace and first-error tuple match phase `0x01`, operation
index `0x0E`, and byte `0x60`.

## Decision-tree result and qualification

At the exact decision strobe, all three SDA stages are HIGH. The literal
decision-tree classification is therefore D3:

```text
PRIMARY_CLASSIFICATION=NO_DIGITAL_ACK_OBSERVED_AT_FPGA_INPUT_PATH_AT_DECISION
TRACE_TELEMETRY_CORRELATION=PASS
```

That label must not be broadened to mean that no ACK-like digital LOW occurred
anywhere in the transaction. The frozen pre-trigger history proves the
opposite: all three SDA stages were LOW throughout a substantial SCL-HIGH ACK
window, then returned HIGH after the master drove SCL LOW, before the FSM made
its decision.

The trace therefore strongly supports this narrower scientific conclusion:

```text
DIGITAL_ACK_LIKE_LOW_PRESENT_DURING_SCL_HIGH=YES
SDA_RELEASED_BY_MASTER_DURING_ACK=YES
SCL_DRIVEN_LOW_BY_MASTER_AT_DECISION=YES
ACK_DECISION_OCCURS_AFTER_OBSERVED_ACK_WINDOW=STRONGLY_SUPPORTED
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
```

The dump tool also emitted a conservative secondary SCL-release heuristic. The
observed post-trigger transition reached SCL stage 1, stage 2, and filtered
HIGH after release; the filter reached HIGH in 128 ns. This digital trace does
not by itself prove clock stretching, excessive analog rise time, or an
electrical fault, so no such claim is made.

No functional correction, retry, ACK-timing change, I2C write, AXI-Lite write,
or DMA operation was performed.
