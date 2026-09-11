# Bank atomicity and restore contract

1. Read `0xFF` into `ENTRY_BANK`; failure may use Bank0 only as an explicitly degraded observation that is never configuration-eligible.
2. For each of ten ordered groups, acquire the group grant, write `0xFF=TARGET_BANK`, read `0xFF`, require equality, read all manifest entries, and release the grant.
3. Capture group start/end ticks around the atomic ownership interval.
4. After G0-POST, write `0xFF=ENTRY_BANK`, read `0xFF`, and require equality.
5. Freeze header, group metadata, 82 entries, manifest identity and generation before setting DONE.

A bank-verify mismatch skips the group's data reads. Any restore failure prevents `VALID_COMPLETE`. `A8_PRE != A8_POST` sets `LIVE_STATUS_CHANGED_DURING_SCAN`; the snapshot stays observationally useful but cannot authorize an ACQ1 mode action.
