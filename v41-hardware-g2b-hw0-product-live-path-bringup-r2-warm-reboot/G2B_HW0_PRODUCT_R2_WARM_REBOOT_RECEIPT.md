# G2B-HW0-PRODUCT-R2 Warm-Reboot Receipt

Result: `PASS`

| Field | Value |
|---|---|
| Authorized maximum | `1` |
| Warm reboots executed | `1` |
| Pre-reboot boot ID | `37131b8d-0e38-4b4e-b77a-b3bda55b4e97` |
| Post-reboot boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Remote command deliveries | `1` |
| Schedule acknowledgements | `1` |
| SSH disconnect observed | `YES` |
| Exact-IP TCP reconnect | `PASS` |
| Authenticated boot-ID change | `PASS` |
| Exactly one boot transition | `PASS` |
| Second reboot attempted | `NO` |
| Power cycle attempted | `NO` |
| Controller lock held throughout | `YES` |

The first local wrapper was rejected before password-file creation, child
process launch, Plink, SSH, remote command delivery, or acknowledgement. Its
original log and supervisor are preserved. A classification receipt proved the
same pre-reboot boot ID and corrected the live lock to zero deliveries and zero
reboots before the authorized delivery.

The only delivered reboot used one transient `systemd-run` timer invoking
unforced `/usr/bin/systemctl reboot`. The helper passed argument auditing and
host-key pinning. Disconnect occurred at
`2026-09-06T07:07:54.9070207Z`; reconnect at exact IP occurred at
`2026-09-06T07:08:25.1682075Z`. Authentication then proved boot ID
`52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` and recent uptime. The one-reboot budget remained consumed and
no retry was attempted.
