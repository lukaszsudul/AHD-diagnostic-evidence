# Future action readiness

| Action | Status | Reason |
|---|---|---|
| APPLY_AHD1080P25_MODE | NOT_IMPLEMENTED_NOT_AUTHORIZED | Full mode action remains outside COMPAT0. |
| INIT_EQ_AHD1080P25 | NOT_IMPLEMENTED_NOT_AUTHORIZED | EQ remains outside COMPAT0. |
| RESTORE_PRODUCT_BASELINE | BLOCKED_INCOMPLETE | The inseparable Bank5/0x05 baseline and write authority are absent. |
| ABORT_AND_RESTORE | BLOCKED_INCOMPLETE | Complete touched-register rollback cannot be proven. |

This is a read-only design assessment, not permission to execute any action. First blocker: `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET`.
