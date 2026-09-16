# SCAN1 entry status encoding

Each entry uses `[31:24] BANK`, `[23:16] REGISTER`, `[15:8] VALUE`, `[7:0] STATUS`.

Status flags are bit0 `VALUE_VALID`, bit1 `RETRIED`, bit2 `BANK_VERIFIED`, bit3 `ENTRY_SKIPPED_AFTER_ABORT`, and bits7:4 `ERROR_CODE`.

| Error code | Meaning | Required behavior |
|---:|---|---|
| 0x0 | NONE | value may be valid |
| 0x1 | WADDR_NACK | stop logical entry after at most one retry |
| 0x2 | REGADDR_NACK | stop logical entry after at most one retry |
| 0x3 | RADDR_NACK | stop logical entry after at most one retry |
| 0x4 | SCL_TIMEOUT | release lines and end operation |
| 0x5 | BUS_IDLE_TIMEOUT | do not start transaction |
| 0x6 | BANK_VERIFY_MISMATCH | no register reads in that group |
| 0x7 | ENTRY_BANK_READ_FAILURE | optional Bank0 fallback is degraded and never configuration-eligible |
| 0x8 | ENTRY_BANK_RESTORE_FAILURE | snapshot cannot be `VALID_COMPLETE` |
| 0x9 | AUTOINIT_PREEMPTED | finish current group, restore, invalidate |
| 0xA | INTERNAL_PROTOCOL_ERROR | release lines, restore if safe, invalidate |

The current fixed master has distinct internal WADDR, REGADDR, and RADDR states but exposes only aggregate success/timeout. SCAN1 implementation therefore adds a diagnostic-only phase-cause result without changing wire timing or transaction behavior.
