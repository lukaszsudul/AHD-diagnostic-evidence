# MODE1 product-baseline reconstruction gap report

## Disposition

`MODE1_RECOVERY_AUTHORITY_INCOMPLETE`

Current v41 has a deterministic, compiled, one-shot autoinit table and fixes the
boot selection to CH1 / AHD 1080p25 / VDO1 / AUTO disabled / stage 2.  This is
useful product-source evidence, but it is not a callable recovery transaction and
does not establish the pre-MODE1 value of every touched byte.

| Required reconstruction element | Offline finding |
|---|---|
| controlled NVP reset | reset behavior exists in bring-up, but no MODE1 callable recovery action is governed |
| exact product-equivalent autoinit | static boot table exists; re-entry, exclusivity and completion contract are absent |
| chip ID/revision | observable evidence exists, but not integrated into a post-reconstruction all-or-fatal verifier |
| autoinit done/error/NACK | status exists; no recovery action/result retention contract exists |
| NVP reset released | observable, but no complete recovery transaction proof |
| channel protected mode/configuration | no complete protected-field list/readback authority for all 113 targets |
| VDO1 route | deterministic boot setting exists; recovery verification is incomplete |
| BGDCOL | no complete post-reconstruction protected verification in a callable flow |
| VDO1/VCLK1 enables | deterministic boot setting exists; recovery verification is incomplete |
| entry bank | snapshot/restore model exists, but reset persistence and final verification are not governed |
| SCAN1 protected configuration | no frozen integrated reconstruction verifier |
| transport disabled | no callable MODE1/recovery architecture exists, so this invariant is not jointly proven |
| scanner exclusion | required by the model, but no implemented whole-action arbitration exists |
| partial-state abandonment | cannot be proven without reset/autoinit action and complete verifier |

Therefore no touched register may be promoted to
`PRODUCT_BASELINE_RECONSTRUCTION` on the present authority.  The exact blocker is:

`ACQ1_REFERENCE_ONLY_FUNCTIONAL_WRITES_LACK_NVP6134C_COMPATIBILITY_AND_COMPLETE_BASELINE_READBACK_AUTHORITY`

