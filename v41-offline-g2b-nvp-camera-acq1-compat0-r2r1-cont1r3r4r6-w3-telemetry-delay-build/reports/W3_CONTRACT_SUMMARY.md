# W3 additive BAR contract, frozen before RTL

Contract bytes: `W3_CONTRACT.json`, 17,783 bytes, SHA-256 `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7`.

The AXI-Lite bridge carries 17 BAR address bits. The existing G2B router claims `0x03800..0x03BFF`; the diagnostic top selects SCAN1 at `0x12000..0x123FF` and `0x12800..0x137FF`, and ACQ at `0x12400..0x127FF`. The PIO fallback returns zero above `0x12000` when no diagnostic page claims an address. The selected source contains no claim for `0x13800..0x147FF`, so W3 claims that 4 KiB page. The legacy `0x137F0/F4` implementation identity remains exact and W3 adds magic/version/digest at `0x13800/04/60..7C`. The G2B router need not change.

## Layout

| Address | Meaning |
|---|---|
| `0x13800..0x138FF` | Identity, one-hot control, staged and active block identity, configured/effective mode, coherence and overflow status, bases, clock, pause cycles and contract digest. |
| `0x13900..0x1397F` | First failed operation, 32 words and independent valid bit. |
| `0x13980..0x139FF` | Terminal failure, 32 words and independent valid bit. |
| `0x13A00..0x13AFF` | Six operation kinds, each with eight accepted/completed/success/failure/timeout counters split by first/retry. |
| `0x13B00..0x13C3F` | Ten groups, each with one four-word select and one four-word verify attempt. |
| `0x13C40..0x1467F` | Eighty-two entries, each with four-word first and four-word optional retry attempt. |
| `0x14680..0x147FF` | Save/restore attempts, successful same-kind controls and reserved zero. |

Each four-word companion contains the exact accepted master sequence, kind, outcome, retry, raw completion cause, timeout, target bank, register, maximum-wait bit, four 11-bit ACK waits, their validity mask, 11-bit maximum, semantic phase class and saturation. Group/entry slot position supplies its logical index. A separate validity mask is cleared at scan admission and set only when all four words are committed, so an incomplete scan exposes its actual completed attempts without borrowing the old published generation.

First and terminal records retain separate raw first-detected versus completion causes, bit/phase, sequence, complete context, select/verify/restore status and a same-kind successful sample when one existed. They remain valid through retry, restore, legacy ACK_CLEAR and later scans, until accepted W3 clear or reset. The companion page describes the latest admitted scan, including incomplete scans. Counters cover all accepted operations since W3 clear/reset, including partial attempts.

Control writes are one-hot and full-DWORD: `1` configure OFF, `2` ON, `4` arm a nonzero block ID, `8` close it, `16` clear W3 telemetry. Configuration, arm, close and clear require scanner/executor/I2C idle with no pending response or snapshot ownership. Mode is frozen at arm and latched at scan admission. A legacy scan outside an armed block is OFF. Rejected writes leave state unchanged and saturating rejection count/last reason are readable. W3 clear never releases inherited bank-context lockout.

The host reads only while scanner and writer are inactive and validates the same block ID, scan-attempt ID, payload revision and valid bits before and after the complete payload. It rejects reset, identity mismatch, counter wrap or any mutation; a zero after reset cannot be used as historical success. Cycles are primary; microseconds are derived at 62.5 MHz. An SCL wait measures release-to-recognized-HIGH, including input/filter latency, and is not an analog or NVP-specific stretching measurement.

