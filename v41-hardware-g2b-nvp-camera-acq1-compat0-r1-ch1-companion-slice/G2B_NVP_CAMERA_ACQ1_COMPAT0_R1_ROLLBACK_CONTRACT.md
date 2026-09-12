# Rollback contract

- Owner-approved fallback order: `select/verify Bank5 -> restore/read 0x08 -> restore/read 0x05 -> restore/verify entry bank`
- Full-byte baseline authority for 0x05: `NOT_REACHED`
- Full-byte baseline authority for 0x08: `NOT_REACHED`
- Read-side-effect-free proof: `NOT_REACHED`
- Write-only touched-register count: `NOT_PROVEN`
- Symbolic rollback fields remaining at stop: `2`
- Rollback contract: `NOT_REACHED`

Sequence extraction precedes touched-register closure. The mandatory forward-order contradiction therefore stops the task before the rollback contract can be closed or implemented.
