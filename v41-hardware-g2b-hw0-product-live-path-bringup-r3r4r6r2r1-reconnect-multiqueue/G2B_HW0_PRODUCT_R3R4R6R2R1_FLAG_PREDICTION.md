# Frozen finite-run flag prediction

Recorded before any hardware run. First primary record: VALID=1, DISCONTINUITY=0 or 1, OVERFLOW_OCCURRED=0, MALFORMED_PRECEDING=0. Remaining primary records: VALID=1, OVERFLOW_OCCURRED=0, MALFORMED_PRECEDING=0, and DISCONTINUITY=0 after any initial transition. Qualified frame: SOF at line 0 and all lines 0..1079 free of discontinuity, overflow, malformed-preceding, and integrity failures.

No finite run occurred, so comparison status is NOT_REACHED.
