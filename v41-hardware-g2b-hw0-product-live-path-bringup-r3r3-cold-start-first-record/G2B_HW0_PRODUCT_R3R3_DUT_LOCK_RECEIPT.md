# DUT lock receipt

- Controller prelock inventory: PASS; zero other active Codex hardware tasks and zero matching controller processes.
- Controller lock acquired for thread 01a0784d-110e-7f60-b752-6220966e6c6c and held across programming, reboot, load, MMIO, T3, cleanup, and final JTAG.
- Pre-reboot Linux lock: held on boot 9fec7547-fd31-4592-a9ce-89ea082d2484; invalidated by the authorized reboot as required.
- Post-reboot Linux lock: held on boot 614295f4-c62b-4430-ae67-06013bea7084 through final DUT evidence collection.
- Post-reboot Linux lock release: PASS, exact lock removed, other matching locks 0.
- Controller lock release: 09/06/2026 20:52:20, after Linux release, state RELEASED.
- Final controller processes: 0.
