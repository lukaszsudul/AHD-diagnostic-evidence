# Post-program warm reboot

Exactly one graceful Ubuntu warm reboot was scheduled after successful SRAM programming. The scheduling unit was `g2b-bt656-fix1-r1-warm-reboot`; the first bounded reconnect attempt timed out while the DUT rebooted and the second returned `FIX1_R1_RECONNECTED=YES`. Boot ID was not read or compared. No second reboot or power-cycle was performed.
