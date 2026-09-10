# Warm reboot receipt

Two preliminary local wrapper invocations were rejected before any SSH process
started; their receipts explicitly record `process_started=false`, so they did
not deliver a reboot command. After the credential-helper false-positive was
corrected, exactly one reboot command was started and acknowledged:

- schedule acknowledged: YES
- delivery start: `2026-09-10T18:54:19.7139650Z`
- first reconnect: timeout (no second reboot issued)
- second/final reconnect: PASS at `2026-09-10T18:55:29.4227255Z`
- boot-ID read or comparison: NO
- power-cycle: NO

Commanded warm reboots: 1.
