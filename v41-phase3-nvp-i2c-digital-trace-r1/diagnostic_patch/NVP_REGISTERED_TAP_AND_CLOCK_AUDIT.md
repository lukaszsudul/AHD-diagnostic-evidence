# NVP Registered Tap and Clock Audit

Source audited: exact non-Git export of `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`.

## Clock and reset domains

| Item | Exact source evidence | Result |
|---|---|---|
| NVP/I2C clock | `ahd_capture_top_xdma.sv`: `autonomous_clk = axi_aclk`; `NVP_AUTOINIT_CLK_HZ = 62500000` | 62,500,000 Hz |
| I2C target | top passes `I2C_HZ(50000)` | nominal 50 kHz |
| FSM step tick | `DIVIDER = CLK_HZ / (I2C_HZ * 2)` and tick when `tick_cnt = DIVIDER` | divider constant 625; preserved measured/qualified SCL is approximately 49.92 kHz |
| Configuration-local reset | top-local `nvp_por_reset`, initialized asserted and released after 320 autonomous-clock cycles | 5.12 us, independent of PCIe `axi_aresetn` |
| Physical NVP reset | `v40a_nvp_autoinit`: LOW while wrapper reset is asserted or `delay_count < CLK_HZ/2` | approximately 500 ms asserted LOW |
| I2C start | wrapper `C_START_CYCLE = CLK_HZ + CLK_HZ/2` | approximately 1.5 s from local sequence start / approximately 1.0 s after physical reset release |
| PCIe warm-reboot reset | AXI-Lite bridge/register modules use `~axi_aresetn` | must not be connected to trace BRAM/metadata reset |

The recorder will use `autonomous_clk` and only `nvp_por_reset`. It will therefore retain frozen memory and metadata across PCIe `user_reset`/`axi_aresetn`, assuming configuration and target power remain present.

## Exact registered observation points

| Required concept | Exact RTL symbol | Source role |
|---|---|---|
| SDA synchronization stage 1 | `sda_sync_r(0)` | first flip-flop fed only by asynchronous `sda_i` |
| SDA synchronization stage 2 | `sda_sync_r(1)` | second ASYNC_REG stage |
| SDA filtered | `sda_filtered_r` | only SDA value consumed by protocol FSM |
| SCL synchronization stage 1 | `scl_sync_r(0)` | first flip-flop fed only by asynchronous `scl_i` |
| SCL synchronization stage 2 | `scl_sync_r(1)` | second ASYNC_REG stage |
| SCL filtered | `scl_filtered_r` | SCL observation consumed by timeout monitor |
| SDA drive-low enable | logical inverse of `sda_oen_r` | `sda_oen_r=0` drives IOBUF LOW; `1` releases |
| SCL drive-low enable | logical inverse of `scl_oen_r` | `scl_oen_r=0` drives IOBUF LOW; `1` releases |
| ACK decision strobe | `tick='1'` while state is `ACK_W_HIGH`, `ACK_REG_HIGH`, `ACK_DATA_HIGH`, or `ACK_R_HIGH` | exact FSM ACK-decision edge |
| ACK value used | logical inverse of `sda_filtered_r` at decision strobe | `1=ACK`, `0=NACK` |
| First-NACK event | ACK decision strobe AND `sda_filtered_r /= '0'` AND `nack_count_r=0` | exact first increment/latch event of the existing NACK counter; it remains valid even if an earlier non-NACK error already occupied first-error telemetry |
| First-NACK latched | `nack_count_r /= 0` | existing registered NACK count, not a new functional latch |
| FSM state | `t_state'pos(state)` | exact enumerated FSM state, 8-bit diagnostic encoding |
| Byte phase | derived solely from ACK states | `1=write-address`, `2=register`, `3=data`, `4=read-address`, `0=not ACK decision` |
| Bit index | `bit_idx` | 0..7, encoded in 4 bits |
| Operation index | `op_idx` | 0..255, encoded in 8 bits |
| Current transmitted byte | `byte_tx` | exact byte currently being shifted/acknowledged |
| NVP reset output | wrapper `nvp_rst_i` | active-low physical output intent |
| VDD enables | wrapper constants driving `nvp_en_vdd1x` and `nvp_en_vdd3x` | both asserted HIGH |
| Init active | sequence `busy_i` | exact autonomous initializer busy state |
| Init done/error | wrapper `done_latched`, `error_latched` | sticky formal runtime status |

No new fanout from asynchronous `sda_i` or `scl_i` is permitted. Stage 1 is the earliest digital observation and must not be described as analog/raw voltage.

## Functional-decision audit

The existing ACK states decide directly from `sda_filtered_r`:

- `ACK_W_HIGH` records code `0x01` when filtered SDA is not LOW.
- `ACK_REG_HIGH` records code `0x02`.
- `ACK_DATA_HIGH` records code `0x03`.
- `ACK_R_HIGH` records code `0x04`.

The observer will export those already-registered values and a combinational event that exactly mirrors the existing latch predicate. It will not move the decision, insert a delay, change the filter, change the synchronizer, or feed any value back.

```text
SOURCE_AUDIT=PASS
OBSERVED_EARLIEST_SDA_STAGE=SYNC_STAGE1
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
NVP_SAMPLE_CLOCK_HZ=62500000
NEW_RAW_SDA_FANOUT_ALLOWED=NO
NEW_RAW_SCL_FANOUT_ALLOWED=NO
```
