# Time ledger

- P2 erratum evidence commit: `7adbab1`.
- R1 program start UTC: `2026-08-21T11:15:45Z`.
- R1 same-process return marker UTC: `2026-08-21T11:15:51Z`.
- R1 reboot helper start UTC: `2026-08-21T11:16:19.6411227Z`.
- R1 host disappearance UTC: `2026-08-21T11:16:40.8685837Z`.
- R1 host return UTC: `2026-08-21T11:17:02.1592507Z`.
- R1 T0 remote monotonic timestamp: `147227556840 ns`.
- R1 T1 remote monotonic timestamp: `148950979498 ns`.
- Formal restore program start/end UTC: `2026-08-21T11:24:38Z` / `2026-08-21T11:24:43Z`.
- Formal restore host disappearance/return UTC: `2026-08-21T11:25:15.9496173Z` / `2026-08-21T11:25:43.6829555Z`.

The elapsed stopwatch marker value cannot be related to later absolute `GetTimestamp()` values because the supervisor did not retain or record its stopwatch epoch. This is the controlling limitation for the primary classification.
