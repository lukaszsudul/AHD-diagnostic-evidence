# Time Ledger — V41_NVP_I2C_25KHZ_PAIRED_AB_R1

| Event | UTC timestamp | Monotonic reference | Notes |
|---|---|---|---|
| Task execution began | 2026-08-21 | Not applicable | Offline identity/source phase |
| Diagnostic full build invocation consumed | 2026-08-21T20:47:52.2936222Z | Not applicable | Exact source commit f007dc172d43d30b02729755e60382f8ce3dbff4; no retry authorized |
| Diagnostic full build completed | 2026-08-21T21:26:32Z | Not applicable | Exit 0; strict post-build gate PASS; bit SHA-256 B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191 |
| Routed-DCP report-only attempt 1 | 2026-08-21T21:28:11Z | Not applicable | Failed closed before reports: checkpoint session label is not HDL top; preserved, no design change |
| Routed-DCP report-only attempt 2 | 2026-08-21T21:32:06Z | Not applicable | Failed closed before reports: non-project `IS_ROUTED` property empty; preserved, no design change |
| Routed-DCP report-only attempt 3 | 2026-08-21T21:36:14Z to 2026-08-21T21:41:18Z | Not applicable | PASS using report-route-status zero-error proof; report-only, no save/build/hardware |
| Exact formal start-state context telemetry | 2026-08-21T22:30:21.4203266Z to 2026-08-21T22:30:23.9949389Z | Remote nanosecond read brackets retained | 40 read-only MMIO reads; exact formal identity; functional context FAIL; not Arm B |
| Arm-A supervisor launch attempt 1 | 2026-08-21 before 22:42Z | Local process ticks retained | Local command-line quoting failure before Vivado/Tcl; zero programming invocations |
| Arm-A programming invocation consumed | 2026-08-21T22:44:26Z | Supervisor tick 945692353 | First and only diagnostic programming invocation |
| Arm-A program command returned | 2026-08-21T22:44:31Z | Supervisor tick 964574233 | Vendor startup status HIGH; subsequent required BIT4 EOS observer property unavailable |
| Arm-A supervisor fail-closed | 2026-08-21T22:44:31Z | Supervisor tick 967582112 | `FAIL_NO_RETRY`; no Arm-A reboot, driver load, or telemetry authorized |
| Arm-A separate read-only DONE session | 2026-08-21T22:46:41Z to 2026-08-21T22:47:45Z | Separate process reference | Exact target/IDCODE; DONE=1; zero programming calls; restoration-safety evidence only |
| Arm-A conservative post-DONE wait | after 2026-08-21T22:47:45Z | 50,121,767 ticks at 10 MHz | 5.012176700 seconds; does not cure infrastructure-invalid Arm A |
| Exact formal restoration program | 2026-08-21T22:54:53Z to 2026-08-21T22:55:00Z | Program-process completion | Second and final permitted FPGA program; startup HIGH; DONE=1 |
| Exact formal restoration wait | after 2026-08-21T22:55:00Z | 50,167,976 ticks at 10 MHz | 5.016797600 seconds from a reference later than program DONE/process exit |
| Formal-restoration warm reboot submitted | 2026-08-21T22:57:45.6467012Z | Not applicable | One and only task warm reboot; command exit 0 |
| Reboot reachability monitor | after 2026-08-21T22:57:47Z | Bounded monitor | Monitor output was not retained by the tool channel; new boot ID and low uptime independently prove reboot |
| Host return proven | 2026-08-21T22:59:38.7477433Z to 2026-08-21T22:59:39.9638001Z | Not applicable | New boot ID b9d58c87-6574-4596-8ff9-b61052ba26dc; uptime 84.53 seconds |
| Exact pinned XDMA loader | 2026-08-21T23:01:44.5448749Z to 2026-08-21T23:01:46.3445238Z | Not applicable | One accepted-loader invocation; exact pinned module; 21 expected nodes |
| Formal-restoration contextual T0/T1 | 2026-08-21T23:04:16.220380818Z to 2026-08-21T23:04:17.501092535Z | Remote nanosecond read brackets retained | 40 read-only MMIO reads; exact formal identity; contextual NVP FAIL |
| Final read-only DONE session | 2026-08-21T23:06:25Z to 2026-08-21T23:07:37Z | Not applicable | One exact target/device; DONE=1; zero programming calls; terminal hardware state |

No further hardware transition is authorized. The terminal state is exact
formal Phase 2 with the exact pinned driver loaded and DONE=1.
