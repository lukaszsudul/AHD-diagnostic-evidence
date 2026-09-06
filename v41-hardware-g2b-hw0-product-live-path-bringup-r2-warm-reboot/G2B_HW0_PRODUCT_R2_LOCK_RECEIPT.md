# G2B-HW0-PRODUCT-R2 Lock Receipt

Result: `PASS`

| Event | Result |
|---|---|
| Fresh controller exclusivity | `PASS` |
| Controller lock acquired | `2026-09-06T06:44:21.3498081Z` |
| Pre-reboot Linux lock | `HELD` |
| Controller lock through disconnect/reconnect | `HELD` |
| Post-reboot fresh exclusivity | `PASS` |
| Post-reboot Linux lock | `HELD` |
| Final state captured with both locks held | `PASS` |
| Linux lock released first | `PASS` |
| Controller lock released last | `PASS` |
| Controller lock release | `2026-09-06T07:34:55.6004821Z` |

The durable controller receipt bound task `G2B-HW0-PRODUCT-R2`, candidate SHA-256
`AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`, controller `NBLSUDUL`, authoritative DUT
`VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`, pre-reboot boot ID
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`, session owner, timestamps, and final release state.

One initial post-reboot lock-acquisition helper stopped before `mkdir` because
its read-only namespace pipeline encountered unreadable systemd-private
directories under `pipefail`. The failure was classified as
`PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION`; zero lock or hardware
mutations occurred. The corrected depth-one inventory retained all guards,
found zero competing processes/locks/users, and acquired the post-reboot lock.
Both the failed attempt and its correction remain in `raw/`.
