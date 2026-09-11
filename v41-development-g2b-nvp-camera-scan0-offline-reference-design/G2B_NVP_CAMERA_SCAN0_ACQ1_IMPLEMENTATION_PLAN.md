# ACQ1 implementation plan

No executor is implemented by SCAN0. Generic host `(bank,register,value)` commands remain prohibited.

- READY: `READ_DETECTION_SNAPSHOT, RESET_FORMAT_DETECTOR_STATE, VERIFY_AHD1080P25_LOCK, ROUTE_CHANNEL_TO_VDO1`.
- PARTIAL: `RESTORE_PRODUCT_BASELINE, ABORT_AND_RESTORE`.
- BLOCKED_BY_NVP6134C_COMPATIBILITY: `ENTER_NOVIDEO_AHD1080P25, STEP_NOVIDEO_SLICE, APPLY_AHD1080P25_MODE, INIT_EQ_AHD1080P25`.
- BLOCKED_BY_REGISTER_AUTHORITY: the blocked functional actions also remain blocked if any touched register lacks safe baseline-read/readback authority.
- DEFERRED: adaptive EQ, EQ recovery, loss/mode recovery loops, CH2/CH4 live output, non-AHD1080p25 configuration, autonomous watch mode and generic bus recovery.

Order after SCAN1 qualification: close baseline-read authority for every touched register; obtain Owner authorization for one controlled compatibility campaign; implement action-ID decode with CH1/CH3 only; bind each ID to immutable transaction/delay/readback ROM; implement ledger and reverse restore; fault-inject every operation; verify no unlisted write is reachable; then perform one first-failed-gate hardware campaign. Promote an action from BLOCKED/PARTIAL to READY only with NVP6134C-specific evidence and commit-pinned artifacts.
