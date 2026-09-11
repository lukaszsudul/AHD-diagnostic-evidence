# Current-v41 gap decision

All 15 required capability rows are populated. Current v41 proves power/reset, a fixed one-time AHD1080p25 CH1 profile, a 25-kHz master, bounded status sampling, BGDCOL/route control and exact restore. It does not implement reference detection, campaign reset/debounce, slice search, governed dynamic mode transition, or reference-equivalent initial EQ as action IDs.

Decision: freeze SCAN1 as a separate read-only compile-time profile. Do not retrofit functional writes into SCAN1. Freeze ACQ1 separately and block the four reference-only functional action families until a controlled NVP6134C compatibility test is Owner-authorized after SCAN1 qualification. Overall classification: `PASS_SCAN1_READ_MANIFEST_READY_ACQ1_REFERENCE_COMPATIBILITY_TEST_REQUIRED`.
