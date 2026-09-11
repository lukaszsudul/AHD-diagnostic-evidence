# ACQ1 rollback contract

Before the first functional write, ACQ1 must read and persist the entry bank and every unique register its selected action can modify. The derived AHD1080p25 path touches `137` unique non-bank-select registers for CH1 and `137` for CH3. The exact target lists and every write appear in the action JSON/CSV; CH1 replay is `1C83F7F1DD20328A301D992CC21A12DEEF76AB85CDDF82F82F17D05DE717D18F` and CH3 replay is `CBED701E4E510BF84C13C850B6F60898059FF22BD4D45063ABC0F15DFBA6EEC4`.

Mandatory ledger fields: campaign generation, channel, action, sequence index, bank, register, operation, old raw value, new value/mask, source authority, result, readback, and timestamp. Bank1 `0xED` and Bank9 `0x44` retain symbolic old bits and clear only the target bit.

Rollback is reverse-ledger order, followed by critical-group readback, whole-baseline equality, entry-bank restore/readback and open-drain release. Any NACK, timeout, readback mismatch, stale generation, host ABORT or internal error invokes rollback. A baseline register that cannot be proven safely readable blocks the action before its first write. No reset, reboot, power-cycle, arbitrary write or guessed reset value substitutes for equality.

Readiness is `PARTIAL`: the contract is frozen, but baseline readability and NVP6134C compatibility of reference-only write targets must be closed before implementation can become READY.
