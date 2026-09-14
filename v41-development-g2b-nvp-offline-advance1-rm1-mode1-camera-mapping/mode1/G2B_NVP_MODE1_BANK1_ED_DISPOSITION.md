# MODE1 Bank 1 / 0xED disposition

## Decision

`PROHIBITED_UNRESOLVED`

This is a required functional target in the no-ACP semantic path, not an excluded
operation.  It appears at MODE1 operation 95 in `nvp6134_setchn_common_fhd`.

## Known semantic effect

The pinned reference semantics read the old byte and clear the CH1-owned bit with
mask `0x01`, preserving `0xFE`.  Thus the forward intent is an exact
read-modify-write mask, not a whole-byte zeroing instruction.

## Why recovery is not authorized

- SCAN0 has no NVP6134C-qualified safe-read/no-side-effect authority for Bank 1 /
  `0xED`.
- The public NVP6134C PDF does not define this private-bank byte sufficiently to
  prove stable snapshot/readback behavior.
- Current v41 stage-2 autoinit contains a deterministic whole-byte value, but it is
  a one-shot boot sequence, not a callable recovery action with complete protected
  baseline verification.
- A symbolic old byte is forbidden in a hardware-ready candidate.

`MASKED_READ_MODIFY_RESTORE` remains only a provisional semantic possibility after
safe-read, snapshot-lifetime and stable-bit authority are supplied.
`PRODUCT_BASELINE_RECONSTRUCTION` remains unavailable until reset, callable exact
autoinit and the full protected verifier are governed together.

If operation 95 may have committed, recovery must terminate in
`FATAL_RECOVERY_FAILURE`.

