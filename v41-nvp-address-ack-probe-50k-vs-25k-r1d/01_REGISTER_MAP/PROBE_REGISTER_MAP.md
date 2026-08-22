# R1d post-init address-probe register map

The audited diagnostic base is `0x00002200`. It is intercepted only in the
diagnostic image. In exact formal Phase 2, this address is in slot 2 while
`SLOT_COUNT=2`; the preserved target returns deterministic zero because valid
slots are 0 and 1 only.

| Offset | Name | Access | Meaning |
|---:|---|:---:|---|
| `+0x00` | `PROBE_MAGIC` | RO | `0x31425250` (`PRB1`) |
| `+0x04` | `PROBE_VERSION` | RO | `1` |
| `+0x08` | `PROBE_CONTROL` | WO/RAZ | `1` starts 50 kHz; `3` starts 25 kHz |
| `+0x0C` | `PROBE_STATUS` | RO | bits 0 IDLE, 1 BUSY, 2 DONE, 3 ERROR, 4 MODE_25KHZ, 5 INIT_DONE_SEEN, 6 INIT_ERROR_SNAPSHOT, 7 BUS_IDLE_GATE_PASSED, 8 SCL_TIMEOUT, 10:9 CAMPAIGNS_COMPLETED |
| `+0x10` | `PROBE_COUNT` | RO | completed STOP-delimited probes |
| `+0x14` | `PROBE_NACK_COUNT` | RO | completed probes whose address ACK sampled high |
| `+0x18` | `PROBE_TIMEOUT_COUNT` | RO | SCL-release timeout integrity counter |
| `+0x1C` | `PROBE_TARGET_COUNT` | RO | `10000` |
| `+0x20` | `PROBE_DIVIDER` | RO | `625` or `1250` |
| `+0x24` | `PROBE_TICK_CYCLES` | RO | `626` or `1251` |
| `+0x28` | `PROBE_CAMPAIGN_INDEX` | RO | 0, 1, or 2 |

Only a full-word aligned write to `+0x08` reaches the probe engine. Writes to
all other words in this window are ignored and have no downstream effect. The
engine structurally accepts only 50 kHz first and 25 kHz second; a third or
out-of-order trigger sets the integrity error and starts no probe.

