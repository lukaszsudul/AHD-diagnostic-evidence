# AHD v41 R2 Hardware Causal Experiment Report

## Decision

- Engineering gate: `BLOCKED`
- Scientific causal result: `BLOCKED`
- First blocker: `FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`
- Primary campaign: `0/32` runs
- Exact-C3 formal cold starts: `0/10`
- INIT_DONE timing experiment: `NOT_RUN`
- Hardware mutations by R2: `0`
- R3 started: `NO`

The Owner-performed cold reset was recognized as the task precondition and was not counted as formal cold-start trial 1. The frozen R0 instrumentation was not active before that reset, exact first-image control was not established, and the formal start recipe was not observed.

## SSOT preflight

The six mandatory files under `project-current-state` were read from authoritative `origin/main` at `8d502a3e0a404b73c73af82846d730355288c7b1`.

- `PROJECT_STATE_REV_AT_START=1`
- `PROJECT_STATE_REV_AT_END=1`
- Revision staleness classification: `NONE`

The revision-1 semantic snapshot is stale relative to the Owner's current statement: it still records G2A active, R1 active, and no R2 entry. The snapshot was recorded but not modified. No META action was taken.

## Frozen authority

The R0 authority is commit `aff7e32edc1cf71bde95b6c19e54e6f307764237`, commit tree `2f54c91bd38f2c5d75f95e26610fca8acf27d495`, R0 subtree `5a9c08d9c48ac2e3ef7e0d79e189c8bdd2dbeaa9`.

The frozen primary denominator remains eight runs per cell, 32 total, in the exact rows:

1. C0, C1, C3, C2
2. C1, C2, C0, C3
3. C2, C3, C1, C0
4. C3, C0, C2, C1
5. C3, C0, C2, C1
6. C2, C3, C1, C0
7. C1, C2, C0, C3
8. C0, C1, C3, C2

No denominator, order, classification, interpretation, cold-start rule, timing method, or R3 trigger was changed after observing the live state.

## Cold-reset live baseline

Read-only transport and host identity passed:

- host reachable by ICMP and TCP/22;
- SSH helper result and argument-token audit: `PASS`;
- remote hostname: `VCDE-DUT-1`;
- remote user: `vcdeagent1`;
- kernel: `7.0.0-29-generic`;
- boot ID: `c53a4c28-4120-4527-89e2-1108cfaaa2f3`.

PCIe and driver evidence at `2026-08-28T08:28:09Z`:

- no Xilinx vendor `10ee` function anywhere in the topology;
- no class `0580` endpoint;
- `0000:01:00.0` is an AMD PCI bridge `1022:43f4`, not the DUT;
- XDMA module not loaded;
- no `/dev/xdma*` nodes;
- `/dev/xdma0_user` absent.

The MMIO read was correctly not attempted because the endpoint and character device were absent. Therefore live `BLOCK_ID`, `PROTOCOL`, `CAPABILITIES`, source words, build flags, and diagnostic magic were unreadable.

One qualified modern xc7a35t selected-target JTAG session performed zero programming invocations and captured five stable samples. Every sample reported part `xc7a35t`, IDCODE `0362D093`, and `DONE=0`.

Primary initial-state classification: `UNPROGRAMMED_OR_FPGA_UNKNOWN`, resolved specifically as unprogrammed. Corresponding host state: `PCIe_NOT_ENUMERATED`.

## Artifact and identity preflight

All five immutable bitstreams exist locally, are 2,192,144 bytes, and rehash exactly:

| Role | Commit/source | SHA-256 | Gate |
|---|---|---|---|
| C0 exact R1h | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | PASS |
| C1 R1i-a | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | PASS |
| C2 R1i-b | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | PASS |
| C3 exact R1i | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |
| Formal Phase-2 | frozen Formal baseline | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | PASS |

The inherited runtime scripts recognized only Formal, C0, and C3. R2 added `tools/r2_runtime_identity_readonly.py`, which recognizes C0/C1/C2/C3 by exact source commit and bitstream hash, records run and cold/warm epoch fields, and uses only `O_RDONLY` plus `pread`. Its offline uniqueness/access-mode self-test passed. No live candidate image was programmed, so no candidate runtime identity was claimed.

## Hardware lock gate

The exact names `FPGA_AHD_HW_LOCK`, `Local\FPGA_AHD_HW_LOCK`, and `Global\FPGA_AHD_HW_LOCK` were probed without acquisition and were not found. Repository and workspace inventories found no canonical executable or current state receipt. Remote read-only searches found no exact lock reference, lock file, related unit, relevant `lslocks` entry, or distinct owner process.

This evidence does not prove the DUT is free. It proves that the current holder, shared implementation, lease/expiry, acquisition, and ownership are not provable. Creating a new private mutex would not establish cross-track adoption and would contradict the previous frozen adjudication.

- `ACQUIRE=FAIL`
- `VERIFY_OWNERSHIP=FAIL`
- Hard stop: `BLOCKED — FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`

No programming was attempted.

## Consequences of the hard stop

Because lock ownership did not pass, Formal Phase-2 could not be programmed and verified, the first experimental arm could not start, and no run could be classified. The C0/C1/C2/C3 causal matrix therefore has no scientific outcome.

The ten formal C3 cold starts were not run. Independently, no documented mechanism currently proves repeatable full DUT/NVP rail removal, fixed 30-second absence, power-good deassertion, PCIe absence, and C3 as the first NVP-driving image. Warm reset and PCI runtime-power controls are not equivalent. If reached without new infrastructure, this would be `COLD_START_PROTOCOL_NOT_REPRODUCIBLE`.

The INIT_DONE timing protocol was not run. No elapsed-time hypothesis, counter delta, or clock-frequency conclusion is reported.

## Final live state and preservation

R2 left the DUT in the read-only-observed cold-reset state:

- xc7a35t IDCODE `0362D093`;
- `DONE=0` in 5/5 samples;
- Xilinx PCIe function absent;
- XDMA module not loaded;
- no XDMA device node;
- MMIO identity unreadable.

Terminal read-only verification independently reconfirmed this state. The host checkpoint completed at `2026-08-28T09:30:47Z` with the original boot ID unchanged, no Xilinx/class-0580 function, XDMA absent, and no provable exact lock holder. A second qualified selected-target JTAG session ran from `2026-08-28T09:34:20Z` through `2026-08-28T09:37:42Z`; all five samples again reported xc7a35t IDCODE `0362D093`, `DONE=0`, and `PASS`, with zero programming invocations. See `R2_FINAL_STATE_RECEIPT.md`.

Product R1i, R1h, R1i-a, R1i-b, G2A, XDC, XCI, drivers, kernel, MMIO ABI, NVP table, I2C frequency, and flash were not modified. G2A was not programmed. G2B was not resumed. R3 was not started.

No lock was acquired, so there was no held lock to leak or release. Under the required final response enum, hardware lock release is reported `FAIL`, with the precise meaning `NOT_ACQUIRED`.
