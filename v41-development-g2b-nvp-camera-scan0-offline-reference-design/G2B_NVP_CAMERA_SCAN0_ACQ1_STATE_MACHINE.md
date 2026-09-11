# ACQ1 bounded state machine

States: `IDLE`, `BASELINE_SCAN`, `ENTER_NOVIDEO`, `DETECTION_SCAN`, `SLICE_STEP`, `DEBOUNCE`, `FORMAT_CONFIRMED`, `APPLY_MODE`, `INIT_EQ`, `VERIFY_LOCK`, `ROUTE_TO_VDO1`, `READY_FOR_CAM1`, `RESTORE`, `FAILED_SAFE`.

Only `ACTION_ID`, `CHANNEL_ID`, and `CAMPAIGN_GENERATION` cross the host interface. CH1 or CH3 is selected by known connector mapping, otherwise the first stable CH1/CH3 detector candidate. CH2/CH4 are observation-only in the first campaign. Every loop has compile-time attempt/time bounds; no endless detector, slice or EQ loop exists. Every functional failure enters RESTORE, compares the full persisted baseline, restores entry bank, releases I2C and leaves streaming disabled. Blocked actions cannot be dispatched.
