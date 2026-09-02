# G2B-LUT1 Recovery 2 Mode Decision

## Decision

- `RECOVERY_MODE = ROUTED_DCP_REUSE`
- `DCP_REUSE_VALID = YES`
- `FULL_REBUILD_EXECUTED = NO`
- `FULL_REBUILD_TRIGGER = NONE`

## Routed authority

| Field | Value |
|---|---|
| Routed DCP | `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp` |
| Size | `57,900,063 bytes` |
| SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Device | `xc7a35tcsg325-2` |
| Prior route signature | `33,985 / 33,985` routable nets fully routed, zero route errors |
| Vivado | `2025.2`, SW build `6299465` |

The predecessor recovery already established that this checkpoint represents
the exact logical G2B PRODUCT design and that the META-4 Group-9 delta was
constraints-only. The new source delta from `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49`
to `64feb60de5d07f400e6b92527bfe54838b3372ee` changes only
`xdc/common/g2b_cdc.xdc`. RTL, netlist-bearing sources, IP configuration, ABI,
and MMIO are unchanged.

G13-A already demonstrated on this exact DCP that the promoted Group-13
constraints can be loaded after `reset_timing -invalid`, that the routed
netlist and clock identity remain unchanged, and that the database can be
updated without synthesis, optimization, placement, physical optimization,
or routing. Recovery 2 therefore has no authorized rebuild trigger.

