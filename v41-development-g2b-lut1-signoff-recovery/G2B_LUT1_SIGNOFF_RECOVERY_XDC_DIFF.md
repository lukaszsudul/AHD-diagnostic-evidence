# AHD v41 G2B-LUT1 Sign-Off Recovery XDC Diff

## Gate result

`XDC_SCOPE_AUDIT = PASS`

`UNRELATED_XDC_CHANGED = NO`

`GROUPS_10_TO_17_CHANGED = NO`

The governed change replaces only the retired Group-9
`OWNERSHIP_AXI_TO_SOURCE` global `set_bus_skew 3.000` requirement. The
replacement is the byte-exact BS3 candidate stanza, containing three
`set_max_delay -datapath_only 6.000` checks for slot, generation, and epoch.

## Authorities

| Item | Identity |
|---|---|
| Active G2B worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Parent HEAD | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Active XDC | `xdc/common/g2b_cdc.xdc` |
| Sealed old active-XDC SHA-256 | `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF` |
| BS3 candidate commit | `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` |
| BS3 candidate Git blob | `7c146a09feb4b37b55ba7398ff82c19b898b8c4c` |
| BS3 candidate SHA-256 | `AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087` |
| Proposed active new-XDC SHA-256 | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` |

The complete candidate file is an exact substring of the proposed active XDC.
Mechanically removing that candidate block and its promotion-only blank line,
then restoring the single old command, reconstructs SHA-256
`2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF`,
which is the independently sealed old active-XDC identity. This proves that no
other byte of the active XDC changed.

## Three-way semantic comparison

### Active old Group 9

```tcl
set_bus_skew 3.000 \
    -from $g2b_ownership_payload_src \
    -to $g2b_ownership_payload_dst
```

The resolved scope was 58 launch registers by 19 heterogeneous destination
registers. META-4R2 retires this global comparison from required sign-off.

### BS3 candidate and proposed active new Group 9

```tcl
set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_slot_src \
    -to $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_generation_src \
    -to $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_epoch_src \
    -to $g2b_bs3_ownership_payload_dst_d
```

The required executable object gate is 2 slot, 24 generation, and 32 epoch
sources to exactly 17 payload-dependent destination D pins. The retained
two-stage request/acknowledgement synchronizers, stable payload hold, and
reset/epoch coherency proof provide the structural part of the promoted method.

## Constraint census

The census below combines active `xdc/common/cdc.xdc` and
`xdc/common/g2b_cdc.xdc`.

| Executable command | Active old | Proposed active new | Delta |
|---|---:|---:|---:|
| `set_bus_skew` | 17 | 16 | -1 Group 9 only |
| `set_max_delay` | 9 | 12 | +3 Group-9 families only |
| `set_false_path` | 3 | 3 | 0 |
| Clock-creation/grouping commands in these two files | 0 | 0 | 0 |

The unchanged legacy `cdc.xdc` remains byte-identical at SHA-256
`E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62`.

## Preservation proof

| Required preservation | Result | Basis |
|---|---|---|
| Only Group-9 required sign-off changed | PASS | exact reverse reconstruction of the sealed old active-XDC hash |
| Other bus-skew groups unchanged | PASS | all other active-XDC bytes are identical; 16 executable skew commands remain |
| Groups 10-17 untouched | PASS | their selectors and eight 3.000 ns commands are outside the sole replaced line |
| Clocks unchanged | PASS | no clock XDC was edited; constraint-only diff is inside `g2b_cdc.xdc` |
| False paths unchanged | PASS | count remains 3 and all pre-existing bytes are identical |
| Max-delay constraints outside Group 9 unchanged | PASS | the only additions are the three candidate family commands |
| Broad AXI-to-source 6.000 ns cap unchanged | PASS | retained verbatim |
| Reverse source-to-AXI 6.000 ns cap unchanged | PASS | retained verbatim |
| R1i functional behavior unaffected | PASS | no RTL, NVP, R1i, reset, or initialization source changed by this task |
| ABI/MMIO unaffected | PASS | no RTL or host contract source changed by this task; ABI remains v1 and MMIO remains `0x3800..0x3BFF` |

## Scope conclusion

`ACTIVE_XDC_GROUP9_UPDATE = AUTHORIZED_SCOPE_ONLY`

The proposed active new XDC is suitable for the governed source commit and the
routed-DCP recovery. The retired global Group-9 `report_bus_skew` must not be
executed. Groups 10-17 remain subject to their existing bounded 3.000 ns
requirements.
