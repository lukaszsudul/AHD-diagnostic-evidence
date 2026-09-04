# Combined candidate XDC scope audit

## Inputs

- Active XDC: `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc`
- Active XDC SHA-256: `49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A`
- Accepted Group-14 candidate SHA-256: `094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A`
- Combined Groups 15-17 candidate SHA-256: `BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F`
- Sealed routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`

## Intended source-level replacement

The active Group-14 block at lines 118-179 is byte-sequence identical to the accepted G14-A candidate and is outside this candidate's scope. The only intended future active-XDC change is lines 180-191:

- remove Group 15's one global `set_bus_skew 3.000` relation;
- remove Group 16's one global `set_bus_skew 3.000` relation;
- remove Group 17's one global `set_bus_skew 3.000` relation;
- add three explicit 6.000 ns datapath-only max-delay families per slot.

The candidate contains exactly nine `set_max_delay -datapath_only 6.000` commands and no `set_bus_skew` command. It declares independent source/state collections per slot and exact shared fault/reset collections. It contains no clock, false-path, ABI/MMIO, unrelated max-delay, Group 9, Group 13, or Group 14 command.

## Isolated-DCP application

The sealed DCP carried historical release bus-skew constraints. The temporary analysis context removed those four release-slot relations only inside the open in-memory design, restored the accepted three Group-14 max-delay families, and applied the nine candidate families. The written analysis context then contained:

- 11 retained non-release bus-skew relations;
- zero release-slot bus-skew relations;
- the existing aggregate release-related max-delay relation;
- 3 preserved Group-14 release max-delay families;
- 9 candidate Groups 15-17 release max-delay families.

All 12 Group-14-to-17 semantic families were present in that context. The nine new families resolved exactly and passed. The aggregate mailbox relation remained active. No production file was read back from or written by the temporary `write_xdc` operation.

## Preservation proof

- Group 9 replacement: unchanged and preserved PASS.
- Groups 10-12: unchanged and preserved PASS.
- Group 13 replacement: unchanged and preserved PASS.
- Group 14 replacement: unchanged, active, and preserved PASS.
- Clocks and unrelated exceptions: unchanged.
- RTL, active XDC, Git index, and source commit: unchanged.

`CANDIDATE_SCOPE_AUDIT = PASS`

`CANDIDATE_SCOPE = COMBINED_ALL_THREE`
