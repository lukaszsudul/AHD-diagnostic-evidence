# Ephemeral R2/Z8 read-only experimental AXI-Lite window

The accepted 53-register control plane remains unchanged at
`0x0000..0x00E0`. With the accepted `SLOT_COUNT=2`, only application slot
windows `0x0000..0x1FFF` are active. The formal decoder returns deterministic
zero for reads of unavailable slot windows `0x2000..0xFFFF`; its next register
region starts at `0x10000`. Static decode inspection therefore constrains R2/Z8 to
the unavailable/reserved-zero slot interval `0x2000..0xEFFF`. All ranges remain
inside the 128 KiB BAR0 aperture.

| Range | Contents | Geometry |
|---:|---|---:|
| `0x2000..0x20FF` | R2/Z8 identity/status | 64 words |
| `0x3000..0xAFFF` | R1-compatible high-resolution trace | 4096 × 64 bits |
| `0xB000..0xCFFF` | FSM-tick context ring | 512 × 128 bits |
| `0xD000..0xEFFF` | correct-phase shadow ACK events | 256 × 256 bits |

The requested 1024-entry context depth would consume all 16 KiB remaining
below the application register boundary and leave no safe event-log window.
R2 therefore uses 512 context entries, which still retains multiple complete
I2C transactions, and reserves the other 8 KiB for 256 rich ACK-event records.
No address at or above `0x10000` is intercepted.

All memories are remapped from physical circular order to chronological order.
Reads before freeze or beyond the frozen valid count return zero. Diagnostic
writes are consumed as no-ops and are never forwarded. No hardware write test
is required. This interception also prevents the formal unavailable-slot write
error counter from changing; the simulation proves the write is neither
forwarded nor stateful in the diagnostic overlay.

## Status/identity words

| Offset | Name |
|---:|---|
| `0x2000` | `DIAG_MAGIC = 0x4E565052` (`NVPR`) |
| `0x2004` | schema `0x00030000` |
| `0x2008` | flags `0x00000007`: bit0 ephemeral, bit1 not release candidate, bit2 functional ACK-sampling experiment; host-write-required is zero |
| `0x200C..0x2088` | R1-compatible trace identity/status and first-error tuple |
| `0x208C` | `HALF_PHASE_CYCLES = 626` |
| `0x2090` | `MID_HIGH_OFFSET_CYCLES = 313` |
| `0x2094` | context depth |
| `0x2098` | context sample width |
| `0x209C` | context status |
| `0x20A0` | context trigger reason |
| `0x20A4` | context valid count |
| `0x20A8` | context final physical write index |
| `0x20AC` | total FSM ticks observed |
| `0x20B0` | shadow-event depth |
| `0x20B4` | shadow-event width |
| `0x20B8` | shadow status |
| `0x20BC` | shadow trigger reason |
| `0x20C0` | shadow valid count |
| `0x20C4` | shadow final physical write index |
| `0x20C8` | total ACK events observed |
| `0x20CC` | false-NACK count |
| `0x20D0` | real-digital-NACK count |
| `0x20D4` | invalid ACK-window count |
| `0x20D8` | context base (`0xB000`) |
| `0x20DC` | shadow-event base (`0xD000`) |

The inclusive functional divider uses `DIVIDER=625`; the FSM sees one tick
every `DIVIDER+1=626` clocks. At 62.5 MHz this is 10.016 microseconds. The R2
shadow and Z8 functional sample are both cycle 313, or 5.008 microseconds after
the original decision instant/SCL-release command. Consumption occurs at the
existing cycle-626 tick, so no SCL half phase or period is added.
