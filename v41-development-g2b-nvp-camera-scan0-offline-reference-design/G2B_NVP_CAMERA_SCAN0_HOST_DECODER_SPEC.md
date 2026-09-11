# Host snapshot decoder specification

The decoder first validates `MAGIC=NVSC`, `VERSION=0x00010001`, required capability bits, entry count 82, and manifest SHA-256 `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`. It performs the G0/read/G1 generation-stability protocol and rejects DONE=0, generation mismatch, restore-not-verified, duplicate/missing entry indexes, unknown status bits, or a bank/register/channel identity mismatch.

Raw bytes are retained without normalization. Entries are indexed by `(bank, register, channel scope, manifest index)`. Unknown private-register meanings remain raw and receive `REGISTER_SEMANTICS_UNCONFIRMED`; they are never silently filled or coerced. The decoder reports exactly one ordered `PRIMARY_BLOCKER` and every independent `SECONDARY_FINDING`. Source authority and confidence travel with each decoded field.

The output is append-only per host campaign and contains snapshot hashes, raw tuples, A8 bookends, group ticks, failure status and the manifest identity. Only a complete, stable, restored snapshot can update detector stability. A live-status-changed snapshot is retained but cannot authorize a functional action.
