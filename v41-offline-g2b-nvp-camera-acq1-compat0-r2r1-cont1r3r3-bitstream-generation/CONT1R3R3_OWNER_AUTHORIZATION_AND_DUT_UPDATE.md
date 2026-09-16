# CONT1R3R3 Owner authorization and DUT update

The Owner stated on 2026-09-16:

> Ok, proszę o firmware. Dodatkowo informuję, że DUT mogła przejść warm-reboot ale nic poza tym nie było tam modyfikowane

This authorizes bounded **offline generation** of one full diagnostic `.bit` from the exact CONT1R3R2-accepted DCP. It does not authorize DUT contact, programming, another FPGA implementation, camera work, or an SSOT update.

`OWNER_REPORTED_WARM_REBOOT = POSSIBLE_NOT_CONFIRMED`; `OWNER_REPORTED_OTHER_MODIFICATIONS = NONE`. The Owner supplied no reboot time, occurrence count, or new boot ID. Current FPGA runtime, NVP state and driver state were not surveyed. The prior volatile image is neither guaranteed present nor presumed absent.

For a later separately authorized task, the sole endpoint authority is `10.132.1.111:22`. The former `192.168.1.57:22` is superseded and is not a fallback. CONT1R3R3 made no DUT connection.
