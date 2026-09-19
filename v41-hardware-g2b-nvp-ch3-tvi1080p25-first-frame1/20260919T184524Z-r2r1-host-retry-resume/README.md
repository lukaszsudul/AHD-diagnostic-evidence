# AHD v41 CH3 TVI1080p25 FIRST-FRAME1 R2R1 host-only resume

Engineering result: `FAIL_CONTAINED_AT_PRE_SCAN_3`.

The exact Candidate 2 runtime passed identity and VIRGIN loader admission. PRE
scan 1 and PRE scan 2 were valid recovered-read-retry observations and were
persisted before validation. They did not count toward the required clean
streak. PRE scan 3 reached a hard bank-restore error. Its raw snapshot was
persisted before rejection and was not acknowledged.

No PN profile was applied, no route or C2H gate was entered, and no frame or
PNG was produced. Cleanup could not be proven after the hard error, so the
task-owned driver and DUT/controller locks were preserved in containment.

This evidence makes no PRODUCT, 10,000-scan, synchronization, frame, or
cleanup-PASS claim. Private raw snapshots, sideband, profiles, host source,
firmware, and pixels are excluded.
