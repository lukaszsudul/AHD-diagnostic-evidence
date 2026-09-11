# V41 NVP diagnostic route-specific VBI-tail contract V1

This task-local host contract separates active-frame and transport integrity
from the route-specific vertical-blanking fingerprint.

- Every non-frame-boundary active-line transition has capture-sequence delta 1.
- A line 1079 to next-frame line 0 transition has capture-sequence delta 1..22.
- The corresponding complete benign vertical-tail interval count is delta - 1,
  so the legal interval count is 0..21.
- Attempt and global sequence deltas remain exactly 1.
- Source malformed and dropped deltas remain exactly 0.
- Line 0 requires VALID and SOF; line 1 must follow with VALID.

The former CH1 value of delta 22 remains a route-specific legacy fingerprint.
It is not a universal structural requirement for channels 2 through 4.
