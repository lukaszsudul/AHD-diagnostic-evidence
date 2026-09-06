# Controlled warm-reboot receipt

Result: PASS. Exactly one delayed graceful systemctl reboot request was acknowledged. SSH disconnect and authenticated return at the exact pinned DUT were observed.

- Pre-reboot boot ID: 9fec7547-fd31-4592-a9ce-89ea082d2484
- Post-reboot boot ID: 614295f4-c62b-4430-ae67-06013bea7084
- Expected transitions: 1
- Observed transitions: 1
- Later unexpected transitions: 0
- Power cycles: 0
- Second reboot authorization: False
