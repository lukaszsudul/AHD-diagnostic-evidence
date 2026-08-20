# Delayed warm reboot

Fresh post-program DONE=1 was established before the delay reference. Stopwatch frequency was 10,000,000 Hz. The measured wait was 3.060054400 seconds, exceeding both the 3.000000-second target and 2.810937-second minimum. No SSH, JTAG, MMIO, NVP or build operation occurred during the wait.

The single `/usr/bin/systemctl reboot` command was accepted through audited Plink/sudo at `2026-08-20T17:25:33.0913012Z`. Direct host disappearance was not sampled while Plink awaited command closure, but the host returned authenticated with a changed boot ID `20ce3f85-63d7-4d02-a3ad-9c87de8ad794`, proving the reboot transition. No second reboot occurred.
