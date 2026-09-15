# Warm reboot and reconnect

Result: `PASS`

- graceful warm reboots: `1`
- power-cycles: `0`
- boot before: `ad08ab8c-30f8-4ff7-80ed-531bfef73896`
- boot after: `0c8657ab-9167-48db-9e97-92081c427c99`
- reconnect endpoint: `192.168.1.57:22`
- retired endpoint contacted: `NO`
- reconnect attempts: `2/3 maximum`

The first post-reboot check reached the endpoint but its task-local identity command attempted an unprivileged DMI read and stopped before lock creation. The corrected minimal stable-identity check then passed and atomically reacquired the DUT lock. No second reboot was issued.
