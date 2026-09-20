# AHD v41 CH3 R2R8-FINALIZE1 — same-DCP finalization

## Result

- Same routed DCP: `CONFIRMED`.
- Comparator repair: `PASS 7/7`.
- Ordered active-XDC payload: `PASS_SEQUENCE_IDENTICAL`.
- Missing final controls: `BLOCKED`.
- PREPARE-only bitstream: `NONE`.
- DUT: `UNTOUCHED`.
- Overall: `BLOCKED_RESERVE_EXHAUSTED_BEFORE_TIMING_DRC_BITGEN`.

The task used the unchanged FPGA source commit `b2f80cf4fda1775ab34804a246cb7be61e0ecd62`, tree `fd19d5e27923f69d16d2d8679db85d7813124c37`. No source revision or implementation was run.

The exact routed DCP remained 62555747 bytes with SHA-256 `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64` before and after. It is retained privately.

## XDC comparison

Raw export hashes remain distinct and are reported as distinct:

- historical aggregate export: `C1CB634BE0E6DF3A4F76110E69DDF0733E5C624492B32DE35EE30FC0174FD39B`;
- historical R2R8 finalizer export: `1CF0A8E34AEBF0F11E1267CC77227E3E8B23FB9F4E8102B9189D85D806E4D348`;
- FINALIZE1 as-open export: `E26B7C9043623EE50E899EE31236B12F432E0B843A500199554F51DF1921095B`.

Each export has 162 lines. The only excluded field is the generated preamble comment on one-based line 4, `# Command Used: write_xdc -type timing -force <output-path>`. The command and options are identical; only the output path argument differs. The remaining 161 ordered lines have payload SHA-256 `64EB95F3F938C4803A83B818291FB3CA42BF4974C50CC20FB3FD7A53AF15BF9D`, with no sorting, trimming, deduplication, global comment removal, or XDC execution.

The comparator accepted the real pair and rejected six mutations: constraint value, selector, command order, command removal, command addition, and export option. Result: `PASS 7/7`.

## Same-DCP sessions

The primary session completed DCP identity, full-route validation, one as-open XDC export, and ordered comparison. Its local MMIO check stopped because the report query targeted only `D` pins of AXI bridge state registers. Timing, DRC, and bitgen calls remained zero.

The authorized reserve reopened the same byte-identical DCP and reused the completed route/XDC result. The corrected query found six realized response-valid timing paths into AXI bridge state inputs and five realized response-data paths into AXI read-data registers. A redundant startpoint-name intersection compared different object-name representations and stopped the finalizer before it persisted the complete local CDC receipt.

The reserve budget was exhausted, so the task did not reopen the DCP again. The local CDC gate is `UNRESOLVED_REPORT_QUERY_NAME_REPRESENTATION_AFTER_RESERVE`; final timing, pulse-width, constraint coverage, final DRC, mandatory bitgen DRC, and bitgen are `NOT_RUN`.

## Reused exact R2R8 evidence

- Route: 38612/38612 routable nets, zero route errors.
- Routed resources: 19695 LUT, 21559 FF, 28.5 BRAM tiles; LUT margin 689 to the 20384 limit.
- Bus skew: `PASS_REUSED_EXACT_R2R8_DESIGN`, 11/11 constraints, minimum slack `+1.119 ns`, zero new calls.
- Focused XSim and SCAN1 evidence: reused from the exact R2R8 design binding; zero new XSim calls.

## Scope

```text
QUALIFICATION_SCOPE=NOT_GRANTED_BLOCKED_BEFORE_PREPARE_ONLY_SCOPED_ADMISSION
HARDWARE_QUALIFICATION=NOT_RUN
CAMERA_CONFIGURATION_ADMISSION=NOT_GRANTED_BY_THIS_TASK
CAPTURE_ADMISSION=NOT_GRANTED
PRODUCT_QUALIFICATION=NOT_CLAIMED
```

DUT contact, hardware PREPARE, APPLY, ONESHOT, capture, DMA changes, programming, reset, and reboot were all zero. Private source, NVP material, XDC content, DCP, and bitstream are not published.

The next action needs a new Owner authorization for one additional offline opening of this exact DCP after removal of the redundant startpoint-name intersection gate. Hardware PREPARE remains blocked until final timing, DRC, and one conditional bitgen pass.
