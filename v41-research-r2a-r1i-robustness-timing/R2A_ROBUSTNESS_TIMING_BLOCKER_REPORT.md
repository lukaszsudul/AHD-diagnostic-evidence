# AHD v41 R2A Robustness and Timing Blocker Report

## Classifications

- Exact R1i 10-cold-start qualification: `NOT_RUN`
- INIT_DONE timing: `NOT_RUN`
- Measured INIT_DONE: `N/A`
- Clock interpretation: `N/A`
- Hardware lock: `NOT_ACQUIRED`
- Hardware accessed: `NO`

## Shared safety blocker

The exact shared `FPGA_AHD_HW_LOCK` state was not provable because no canonical
cross-track executable/state receipt exists. Historical task-local mutexes do
not establish exclusive ownership for this continuation. The subset therefore
stopped before connectivity, SSH, JTAG, programming, MMIO, power, reset, or
driver activity.

## Cold-start-specific feasibility

The frozen protocol requires 10 consecutive valid starts with complete DUT/NVP
rail removal, a fixed 30-second power absence, verified power-good deassertion,
host-function absence, and exact qualified R1i as the first NVP-driving image
after power return. No proven automation or receipt chain was found that can
enforce those conditions while the Owner is unavailable. Earlier local cold
state evidence explicitly recorded `POWER_CYCLE_COUNT=0`; a warm reboot or FPGA
reprogram cannot be substituted.

Consequently, no trial was attempted and the result is `NOT_RUN`, not a partial
or inferred qualification.

## Timing-specific feasibility

The frozen timing protocol requires raw atomic high-low-high counter reads,
last coherent `INIT_DONE=0` and first coherent `INIT_DONE=1` snapshots with
host monotonic brackets, at least 20 live-counter samples spanning at least 10
seconds, regression/uncertainty analysis, exact runtime identity, and safe
restoration. Because exclusive hardware ownership could not be proven, none of
these reads or events was initiated. Historical counter values were not
relabeled as a new measurement.

## Artifact identity

The exact qualified R1i bitstream was found and rehashed locally:

- bytes: `2,192,144`
- SHA-256:
  `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`

The exact Formal Phase-2 restore image was also rehashed:

- bytes: `2,192,144`
- SHA-256:
  `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`

Neither artifact was programmed.

## Preservation

- Qualified R1i modified: `NO`
- Product/G-track source modified: `NO`
- Flash: `UNCHANGED`
- Drivers: `UNCHANGED`
- Hardware state changed by continuation: `NO`
