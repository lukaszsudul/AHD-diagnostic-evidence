# MODE1 Bank 9 / 0x44 disposition

## Decision

`PROHIBITED_UNRESOLVED`

This is a required functional target in the no-ACP semantic path, not an excluded
operation.  It appears at MODE1 operation 106 in `nvp6134_setchn_common_fhd`.

## Known semantic effect

The pinned reference semantics read the old byte and clear the CH1-owned bit with
mask `0x01`, preserving `0xFE`.  The forward intent is therefore a masked update;
it is not authority to assume the entry byte is `0x00`.

## Why recovery is not authorized

- SCAN0 has no NVP6134C-qualified safe-read/no-side-effect authority for Bank 9 /
  `0x44`.
- Bank 9 is private in the available public NVP6134C material, so stable snapshot
  and exact readback behavior are unproven.
- Current v41 stage-2 autoinit writes a deterministic whole byte, but the boot-only
  sequence is not a callable product reconstruction path and does not prove the
  pre-MODE1 byte.
- A symbolic rollback value cannot be retained in a hardware-ready candidate.

`MASKED_READ_MODIFY_RESTORE` is only provisional until safe-read and stable-bit
authority exist.  `PRODUCT_BASELINE_RECONSTRUCTION` is unavailable until the
governed reset/autoinit/verifier chain is complete.

If operation 106 may have committed, recovery must terminate in
`FATAL_RECOVERY_FAILURE`.

