# AHD v41 R-track Autonomous Overnight Final Report

Status: `COMPLETE`

Deadline: `2026-08-28 08:00 Europe/Warsaw`

## SSOT

- `PROJECT_STATE_REV_AT_START`: `1`
- `PROJECT_STATE_REV_AT_END`: `1`
- SSOT staleness: `NONE`
- SSOT modification: `NONE` (read-only contract)

## R1 result

- Engineering result: `PASS`
- R1i-a: `PASS`
- R1i-b: `PASS`
- Corrective iterations: `0`
- Candidate A bitstream SHA-256: `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D`
- Candidate B bitstream SHA-256: `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D`
- R1 evidence commit: `d02a3dbc41075764ecf915e4e2d0a1da3c0ce07e`

## R2 causal result

- Executed: `NO`
- Result: `BLOCKED`
- C0: `NOT_RUN`
- C1: `NOT_RUN`
- C2: `NOT_RUN`
- C3: `NOT_RUN`

First blocker: `FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`

The secondary independent stop condition was that the exact 32-run frozen
campaign could not fit before the 07:45 no-new-work cutoff using the proven
hardware sequence. No partial campaign was started.

## Exact R1i 10-cold-start result

`NOT_RUN`

The exact shared lock could not be acquired from a provable canonical state.
In addition, no proven automation/receipt chain could enforce full DUT/NVP rail
removal, 30 seconds of power absence, and exact R1i as the first NVP-driving
image after every return. A warm reboot or reprogram was not substituted.

## INIT_DONE timing result

- Classification: `NOT_RUN`
- Measurement: `N/A`
- Clock interpretation: `N/A`

No timing read was attempted without exclusive hardware ownership. Historical
counter values were not relabeled as a new measurement.

## R3 result

`NOT_RUN`

R3 was not triggered because no valid R2 causal result exists.

## Evidence publication

- R1: `PASS`
- R2: `PASS`
- R2A: `PASS`
- R3: `NOT_RUN`
- Initial R2/R2A payload commit:
  `25b3e12117b2f1d2fd0287be0073c00b475c8b53`
- Initial payload tree: `eaac4944253135f073cc082196337bb7920a931f`
- Independent fresh-clone remote read-back: `PASS`
- Published files compared byte-for-byte: `16 / 16`
- Manifest payloads validated: `14 / 14`
- Final synchronization commit: recorded in the final handoff and remote HEAD

## Final hardware state

- Hardware lock: `NOT_ACQUIRED`
- Hardware accessed by this continuation: `NO`
- Final state: `NOT ACCESSED; LIVE STATE UNVERIFIED; NO STATE CHANGE BY THIS CONTINUATION`

## Baseline preservation

- Product baseline modified: `NO`
- Qualified R1i modified: `NO`
- G-track branches modified: `NO`
- Flash: `UNCHANGED`
- Drivers: `UNCHANGED`

## Remaining blocker

`FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`

## Deadline closure

- New hardware/build/implementation work after 07:45: `NONE`
- Hardware restoration required: `NO` (hardware was never accessed)
- Hardware lock release required: `NO` (lock was never acquired)
- Deadline stop: `PASS`
- Final marker: `OVERNIGHT_RTRACK_HARD_STOP_COMPLETE`
