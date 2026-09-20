# AHD v41 CH3 R2R8-FINALIZE2 — same-DCP finalization

## Result

- Same routed DCP: `CONFIRMED`.
- Final timing: `PASS`.
- Final DRC: `PASS_WARNINGS_MATCH_ACCEPTED_BASELINE`.
- Local realized MMIO/AXI CDC: `PASS`.
- PREPARE-only bitstream: `READY_PRIVATE_NOT_PUBLISHED`.
- DUT: `UNTOUCHED`.
- Overall: `PASS_EXISTING_DCP_FINALIZED_PREPARE_ONLY_BITSTREAM_READY`.

The task used unchanged FPGA source commit `b2f80cf4fda1775ab34804a246cb7be61e0ecd62`, tree `fd19d5e27923f69d16d2d8679db85d7813124c37`. No source revision or implementation was run. The exact routed DCP remained 62555747 bytes with SHA-256 `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64` before and after.

## Final gates

The one final whole-design timing summary reported WNS `+0.230 ns`, TNS `0.000 ns`, WHS `+0.032 ns`, THS `0.000 ns`, WPWS `0.000 ns`, TPWS `0.000 ns`, and zero setup, hold, or pulse-width failing endpoints. It reported zero missing clocks and zero unconstrained internal endpoints. The three input-delay and three output-delay notices match the pinned FINALIZE1 baseline; two low pulse-width clock notices have zero pulse-width failures.

The one explicit final default DRC found 0 errors, 0 critical warnings, and 24 warnings. Its exact violation-name and severity set matches the accepted baseline: IOSR-1 x2, PDCN-1569 x1, REQP-1839 x12, REQP-1840 x8, and RTSTAT-10 x1. Mandatory DRC inside the single `write_bitstream` invocation completed with 0 errors; bitgen reported 0 warnings and 0 critical warnings.

The scoped local CDC proof used realized cells, pins, owning-cell relationships, clocks, resets, and fanin/fanout. The response valid and dynamic response data storage are in the same realized AXI clock domain as their bridge receivers, with the accepted synchronous reset semantics. It proved six valid-to-state relations, including the actual CE endpoints, and 27 response-data-to-rdata relations. It accounted for optimized zero bits and shared constant-one storage instead of expecting 32 independent registers. Full-project CDC was not rerun.

## Reused exact-DCP evidence

- Ordered active-XDC payload: `PASS_SEQUENCE_IDENTICAL`, 161 lines, SHA-256 `64EB95F3F938C4803A83B818291FB3CA42BF4974C50CC20FB3FD7A53AF15BF9D`; FINALIZE1 comparator `PASS 7/7`; zero new exports or comparator tests.
- Route: 38612/38612 routable nets, zero route errors.
- Resources: 19695 LUT of the 20384 limit, margin 689; 21559 FF; 28.5 BRAM tiles.
- Bus skew: `PASS_REUSED_EXACT_R2R8_DESIGN`, 11/11, minimum slack `+1.119 ns`; zero new bus-skew calls.
- Focused XSim/SCAN1 evidence: reused from the exact R2R8 binding; zero new XSim calls.

## Bitstream and scope

Exactly one `write_bitstream` call created the private PREPARE-only image. The file is 2192144 bytes with SHA-256 `34DFC48E9CCEDD9E4F608624EE51D1D79767E8E74035393576B69C21C07E8CB8`. Its header identifies top `ahd_capture_top_xdma`, device/package core `7a35tcsg325`, and Vivado 2025.2; the exact speed-grade target remains bound by the verified DCP target `xc7a35tcsg325-2`. The bitstream bytes are not published.

```text
QUALIFICATION_SCOPE=PREPARE_ONLY_SCOPED_ADMISSION
HARDWARE_QUALIFICATION=NOT_RUN
CAMERA_CONFIGURATION_ADMISSION=NOT_GRANTED_BY_THIS_TASK
CAPTURE_ADMISSION=NOT_GRANTED
PRODUCT_QUALIFICATION=NOT_CLAIMED
```

One DCP open was used. Vivado query errors were zero. One bounded CDC enumeration correction changed `nworst=2` to `nworst=1,max_paths=64` to remove duplicated timing corners and prove all local sources/targets. Two post-bitgen parser corrections were applied to the already generated file: a native PowerShell parser replaced an unavailable Python command, then the header check was corrected to compare the standard device/package field while retaining the exact speed grade as the independent DCP target gate. Neither correction reran bitgen.

New RTL, XSim, synth, opt, place, phys_opt, route, checkpoint writes, bus-skew reports, full CDC, and all DUT or hardware operations were zero. Private source material, NVP material, XDC content, DCP, and bitstream are not published.
