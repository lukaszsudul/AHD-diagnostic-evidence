# AHD v41 G2B-LUT1 Recovery Mode Decision

## Decision

`RECOVERY_MODE = ROUTED_DCP_REUSE`

`DCP_REUSE_VALID = YES`

`FULL_REBUILD_REQUIRED = NO`

`FULL_REBUILD_TRIGGER = NONE`

## Exact routed input

| Field | Value |
|---|---|
| DCP | `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp` |
| Size | `57,900,063` bytes |
| SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Device | `xc7a35tcsg325-2` |
| Original route | fully routed, 33,985/33,985 routable nets |
| Vivado | `2025.2`, SW build `6299465` |

## Validity checks

| Check | Result | Evidence |
|---|---|---|
| Netlist identity compatible with current source | PASS | 34/34 non-XDC Gen12 build inputs remain byte-identical |
| Current change is constraints-only | PASS | sole post-seal mutation is active `g2b_cdc.xdc` Group 9 |
| RTL/netlist difference | NONE | all RTL/XCI inputs retain sealed SHA-256 identities |
| Routed implementation is the same logical design | PASS | exact sealed DCP and exact non-XDC manifest identities |
| Candidate can be applied without synthesis | PASS | BS3 already opened this exact DCP and reloaded the replacement context |
| Timing database can update correctly | PASS | BS3 `reset_timing -invalid` plus base/candidate reload produced valid paths and no candidate TIMING-34/39 finding |

## Rebuild boundary

No condition authorizing a rebuild is present. The recovery therefore reuses
the routed checkpoint, reloads the complete preserved timing context with only
old Group 9 removed, applies the promoted BS3 candidate, and runs fresh bounded
sign-off. No synthesis, optimization, placement, physical optimization, or
routing command is authorized or executed in this mode.
