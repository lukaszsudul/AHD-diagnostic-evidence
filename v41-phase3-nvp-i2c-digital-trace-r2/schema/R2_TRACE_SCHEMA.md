# NVP ACK shadow-monitor R2 schema

R2 preserves the R1 4096×64 high-resolution trace without changing its field
layout. It adds a 512×128 ring sampled only on the exact functional FSM tick and
a 256×256 event ring that observes every functional ACK opportunity through
the first NACK. All three layers freeze autonomously and survive PCIe
`user_reset`.

The earliest SDA/SCL observations are existing FPGA synchronizer stage 1.
They are digital observations, not analog measurements.

## FSM-tick context word (128 bits)

| Bits | Field |
|---:|---|
| `15:0` | global tick sequence |
| `23:16` | current I2C state |
| `31:24` | byte phase |
| `35:32` | bit index |
| `43:36` | operation index |
| `51:44` | table slot index |
| `55:52` | high-level initialization phase |
| `57:56` | preinit action |
| `59:58` | init action |
| `67:60` | metadata bank |
| `75:68` | physical bank |
| `76` | physical-bank valid |
| `77` | read operation |
| `78` | SDA drive-low enable |
| `79` | SCL drive-low enable |
| `80` | filtered SDA |
| `81` | filtered SCL |
| `82` | functional ACK-decision strobe |
| `83` | functional ACK value, 1=ACK |
| `84` | exact first-NACK event |
| `85` | init active |
| `86` | init done |
| `87` | init error |
| `95:88` | pending bank |
| `103:96` | pending register |
| `111:104` | pending data |
| `119:112` | active register |
| `127:120` | active write data |

`previous_state` is derived losslessly by the decoder from the preceding
chronological context record.

## Shadow ACK event word (256 bits)

Each record snapshots the unchanged functional decision, then observes the
real subsequent SCL-high interval. Early-high is the first qualified SCL-high
sample; mid-high is cycle 313; late-high is the final sample before the next
functional tick.

| Bits | Field |
|---:|---|
| `15:0` | ACK event index |
| `23:16` | operation index |
| `31:24` | slot index |
| `39:32` | byte phase |
| `47:40` | transmitted byte |
| `55:48` | active register |
| `63:56` | active write value |
| `71:64` | metadata bank |
| `79:72` | physical bank |
| `80` | physical-bank valid |
| `81` | unchanged functional ACK decision, 1=ACK |
| `82` | filtered SDA at functional decision |
| `83` | filtered SCL at functional decision |
| `84` | SDA drive-low at functional decision |
| `85` | SCL drive-low at functional decision |
| `86` | first-NACK event |
| `87` | qualified SCL high observed |
| `88,89,90` | early/mid/late validity |
| `91,92` | SDA/SCL released throughout ACK high interval |
| `93` | measured half-phase count equals 626 |
| `98:96`, `101:99` | early SDA and SCL stages 1/2/filtered |
| `102,103` | early SDA/SCL drive-low |
| `106:104`, `109:107` | mid SDA and SCL stages 1/2/filtered |
| `110,111` | mid SDA/SCL drive-low |
| `114:112`, `117:115` | late SDA and SCL stages 1/2/filtered |
| `118,119` | late SDA/SCL drive-low |
| `129:120` | early offset cycles |
| `139:130` | mid offset cycles |
| `149:140` | late offset cycles |
| `159:150` | measured half-phase cycles |
| `167:160` | initialization phase |
| `175:168` | preinit action |
| `183:176` | init action |
| `191:184` | pending bank |
| `199:192` | pending register |
| `207:200` | pending data |
| `215:208` | first-error code |
| `223:216` | first-error step |
| `231:224` | first-error metadata bank |
| `239:232` | first-error register |
| `247:240` | first-error value |
| `248,249,250` | init active/done/error |
| `251` | no qualified SCL high |
| `252` | mid-high shadow ACK LOW |
| `253` | mid-high shadow NACK HIGH |
| `254` | invalid mid-high sample |

Trigger reason 1 means first NACK, 2 clean initialization completion, and 3
observer/internal error or completion with a non-NACK error.
