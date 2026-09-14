# G2B NVP DIAG2-RM1 MMIO and frozen-data contract

This document describes the task-local RM1 RTL candidate. It is an offline
contract, not hardware evidence. The profile is valid only with
`ENABLE_NVP_VIDEO_DIAG2_RM1=1`, `ENABLE_NVP_VIDEO_DIAGNOSTIC=0`, and
`ENABLE_RTRACK_DIAGNOSTICS=0`.

## Identity and address range

| Byte address | Access | Meaning |
|---:|:---:|---|
| `0x3C00` | R | MAGIC = `0x4E524D31` (`NRM1`) |
| `0x3C04` | R | VERSION = `0x00010000` |
| `0x3C08` | R | CAPABILITIES = `0x00000FFF` |
| `0x3C0C` | W | CONTROL: bit 0 CLEAR, bit 1 ARM, bit 2 manual FREEZE, bit 3 ACK |
| `0x3C10` | R | STATUS, described below |
| `0x3C14` | R | BUILD_FLAGS; RM1 build profile uses `0x00000802` |
| `0x3C18` | R/W | CONFIG: channel `[2:0]` (`1..4`), window selector `[9:8]` (`0..2`) |
| `0x3C1C` | R | active session ID `[15:0]` |
| `0x3C20` | R | armed window in milliseconds (`100`, `500`, or `1000`) |
| `0x3C24` | R | route tag: target `[2:0]`, readback `[15:8]`, original `[23:16]` |
| `0x3C28` | R | route error code `[15:0]` |
| `0x3C2C` | R | saturating ARM-rejected count |
| `0x3C30` | R/W | trace index (`0..63`), writable only while DONE and VALID |
| `0x3C34` | R | selected 64-bit trace entry, low word |
| `0x3C38` | R | selected 64-bit trace entry, high word |
| `0x3C3C` | R/W | metadata index (`0..31`), writable only while DONE and VALID |
| `0x3C40` | R | selected 64-bit metadata entry, low word |
| `0x3C44` | R | selected 64-bit metadata entry, high word |
| `0x3C48` | R | saturating protocol-error count |
| `0x3C4C` | R | constant stop code for AXI/source-clock timeout (`4`) |
| `0x3C50` | R | constant stop code for route error (`5`) |

All other addresses in `0x3C00..0x3FFF` read as zero. The range is intercepted
only by a diagnostic profile. A request outside the range is not claimed by
RM1.

STATUS bits are: route busy `[0]`, source armed `[1]`, measurement started
`[2]`, freeze issued `[3]`, public DONE `[4]`, public VALID `[5]`, awaiting ACK
`[6]`, stopped-source timeout `[7]`, route error `[8]`, exact route restored
`[9]`, trace overflow `[10]`, ACK pending `[11]`, persistent AXI-reset/route
abort awaiting source echo `[12]`.

Writes require a full word strobe (`0xF`). CONFIG is accepted only when no
session is owned and the route controller is idle/restored. ARM accepts only
channels `1..4` and window selectors `0..2`. A second ARM before the first ACK
is rejected. The first valid ACK closes the read window immediately; source
release and exact Bank-1/C2 plus entry-bank restoration then complete
internally.

## Frozen metadata RAM (`index 0..31`)

Each entry is 64 bits. Unless stated otherwise the counter is in `[31:0]` and
saturates at `0xFFFFFFFF`.

| Index | Frozen value |
|---:|---|
| 0 | metadata magic `[31:0]=0x524D314D`, generation `[47:32]` |
| 1 | session `[15:0]`, route `[18:16]`, window selector `[20:19]`, valid `[21]`, parser state at freeze `[24:22]` |
| 2 | raw sample count |
| 3 | raw VDO byte-change count |
| 4 | raw `00` byte count |
| 5 | raw `FF` byte count |
| 6 | `FF00` prefix count |
| 7 | `FF0000` prefix count |
| 8 | `FF0000XY` candidate count |
| 9 | full BT.656 XY parity-pass count |
| 10 | full BT.656 XY parity-fail count |
| 11 | legal raw SAV count |
| 12 | legal raw EAV count |
| 13..16 | SAV F/V classes `F0V0`, `F0V1`, `F1V0`, `F1V1` |
| 17..20 | EAV F/V classes `F0V0`, `F0V1`, `F1V0`, `F1V1` |
| 21 | literal qualified SAV count |
| 22 | literal qualified EAV count |
| 23 | parser-reject count |
| 24..26 | min, max, last samples between legal SAV; min is `0xFFFFFFFF` when absent |
| 27..29 | min, max, last SAV-to-EAV distance; min is `0xFFFFFFFF` when absent |
| 30 | trace valid count `[6:0]`, next write pointer `[13:8]`, overflow `[16]` |
| 31 | valid-snapshot stop reason: none `0`, window `1`, manual `2`; reset/timeout/route-error sessions are invalid and their metadata is not host-readable |

The parity matrix is literal BT.656 protection coding:
`P3=V xor H`, `P2=F xor H`, `P1=F xor V`, and
`P0=F xor V xor H`. `QUALIFIED_PARSER` is deliberately the frozen RM1
contract predicate `XY[7] && XY[3:0]==0`; `PARSER_REJECT` means a parity-legal
raw marker that does not satisfy that predicate. Neither field claims the
later state/distance decision of the functional parser.

## Trace RAM (`index 0..63`)

| Bits | Meaning |
|---:|---|
| `[7:0]` | registered VDO1 source byte |
| `[9:8]` | prefix state |
| `[10]` | `FF0000XY` candidate |
| `[11]` | full XY parity valid |
| `[14:12]` | F, V, H |
| `[15]` | legal raw SAV |
| `[16]` | legal raw EAV |
| `[17]` | literal parser-qualified predicate |
| `[18]` | parser-accepted field under the same frozen literal RM1 definition |
| `[21:19]` | atomically registered parser state |
| `[31:22]` | sample distance low 10 bits |
| `[47:32]` | session ID |
| `[50:48]` | route |
| `[52:51]` | window selector |
| `[63:53]` | generation low 11 bits |

Manual and automatic freeze use distinct synchronized toggle commands, so the
stop reason is encoded by the command itself rather than an independently
synchronized payload bit. AXI-reset/route abort uses a persistent request/echo
handshake; repeated AXI reset releases cannot cancel an unseen abort while the
source clock is stopped, and ARM remains blocked until its source echo.

The 64 trace entries and 32 metadata entries share one 128-by-64 synchronous
simple-dual-port XPM block RAM. Source writes cease before DONE publication.
AXI data reads are enabled only while both DONE and VALID are true. Timeout,
reset, or route/interlock failure publishes no valid snapshot and exposes no
old or still-mutating RAM contents.

The read-only constants at `0x3C4C` (`4`) and `0x3C50` (`5`) name the two
AXI-visible invalid terminal classes. They are not metadata-entry-31 values for
a valid snapshot. A route failure is reported by STATUS, `0x3C28`, and
VALID=0; an AXI/source-clock timeout is reported by STATUS timeout and VALID=0.

Route error codes at `0x3C28` are: not-ready `0x0001`, fixed-I2C NACK
`0x0002`, fixed-I2C timeout `0x0003`, target-route mismatch `0x0004`, exact
restore mismatch `0x0005`, transport-quiescence loss `0x0006`, AXI reset while
the route may be dirty `0x0007`, and runtime NVP/autoinit readiness loss
`0x0008`. Runtime readiness is monitored throughout both the forward route and
the exact restore sequence. A loss revokes the session and defers all further
fixed-I2C commands until the environment is ready and the master is idle. If
both entry bank and C2 were captured, both are restored and read back exactly.
If C2 was not captured, a known possibly changed entry bank is still restored
and read back, but `route_restored` remains zero because the overall baseline
is unprovable; a later AXI reset cannot convert that state into PASS.

Source reset recovery drains all independently synchronized command tokens for
four complete source-clock edges before publishing an incomplete invalid DONE.
An ARM absorbed by that drain is treated as a discarded AXI-owned session.
Invalid-session ACK is echoed only after a second four-edge drain, preventing a
late AUTO/MANUAL token from reaching the next ARM. Invalid DONE and timeout
also cancel the AXI measurement/freezing machinery.
