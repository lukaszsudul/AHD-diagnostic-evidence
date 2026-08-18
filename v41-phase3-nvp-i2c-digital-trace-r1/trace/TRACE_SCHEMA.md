# Ephemeral NVP/I2C digital trace schema

Schema version is `0x00010000`. The recorder samples 64 bits at the existing
62.5 MHz NVP/I2C FSM clock. It stores 4096 samples, with 3072 chronological
samples before the trigger and 1024 samples from the trigger through the end
of the frozen record. The nominal window is 49.152 microseconds before and
16.384 microseconds including/after the trigger.

The earliest SDA/SCL observations are the existing first synchronizer stages.
They are digital FPGA observations—not raw analog voltage measurements.

| Bits | Field | Encoding |
|---:|---|---|
| 0 | SDA synchronizer stage 1 | digital level |
| 1 | SDA synchronizer stage 2 | digital level |
| 2 | SDA stable-filter output | digital level used by the FSM |
| 3 | SCL synchronizer stage 1 | digital level |
| 4 | SCL synchronizer stage 2 | digital level |
| 5 | SCL stable-filter output | digital level used by the FSM |
| 6 | SDA drive-low enable | 1 means the FPGA actively pulls SDA low |
| 7 | SCL drive-low enable | 1 means the FPGA actively pulls SCL low |
| 8 | ACK decision strobe | exact qualified clock used by an `ACK_*_HIGH` state |
| 9 | ACK value used by FSM | 1=ACK/LOW, 0=NACK/HIGH |
| 10 | first-NACK event | exact first NACK counter/latch event |
| 11 | first-NACK latched | NACK count is nonzero |
| 12 | physical NVP reset output | 0 asserted, 1 released |
| 13 | VDD1 enable output | digital enable only |
| 14 | VDD3 enable output | digital enable only |
| 15 | init active | I2C sequence busy |
| 19:16 | bit index | current transmit/receive bit index |
| 27:20 | byte phase | 0 none, 1 write address, 2 register, 3 data, 4 read address |
| 35:28 | FSM state | `t_state'pos(state)` |
| 43:36 | operation index | exact `op_idx` |
| 51:44 | current TX byte | exact `byte_tx` |
| 52 | init done | wrapper sticky done |
| 53 | init error | wrapper sticky error |
| 61:54 | first error code | existing telemetry code |
| 62 | first error valid | existing telemetry valid |
| 63 | reserved | forced zero |

The recorder triggers from the exact first-NACK event. If no NACK occurs, it
triggers on clean initialization completion. A completion with an error but no
observed NACK receives reason 3. After the post-trigger window, BRAM and all
metadata freeze until a new FPGA configuration; PCIe `user_reset` cannot clear
them.
