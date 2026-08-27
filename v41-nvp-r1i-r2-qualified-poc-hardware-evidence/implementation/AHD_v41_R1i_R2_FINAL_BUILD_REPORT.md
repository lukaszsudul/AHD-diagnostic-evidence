# AHD v41 R1i–R2 Final Build Report

## Result

```text
BUILD=PASS
SYNTHESIS=PASS
IMPLEMENTATION=PASS
BITSTREAM=PRODUCED
SOURCE_TO_BIT_PROVENANCE=PASS
```

## Frozen inputs

- Candidate branch: `diag/v41-nvp-r1i-r2-qualified-ack-readiness-poc`
- Commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Part: `xc7a35tcsg325-2`
- Top: `ahd_capture_top_xdma`
- Build Tcl SHA-256: `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F`
- Vivado: 2025.2 build 6299465
- Build flags: `0x00000002`

The canonical Git worktree was clean before and after the build. No source, XDC, IP, or build-script edit occurred.

## Launch

- Authorized Vivado role: process 2 of maximum 10
- Start: `2026-08-26T21:23:05.7921844Z`
- Completion: `2026-08-26T22:06:36.8336773Z`
- Exit code: 0
- Repository: `V:\R1I_R2\FPGA_AHD`
- Output: `V:\R1I_R2\build\launch_02`
- TEMP/TMP: `V:\TMP\build_02`
- `XILINX_LOCAL_USER_DATA=NO`
- `XILINX_TCLAPP_REPO=C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore`

## Operation accounting

| Operation | Invocations |
| --- | ---: |
| `synth_design` | 1 |
| `opt_design` | 1 |
| `place_design` | 1 |
| `phys_opt_design` | 1 |
| `route_design` | 1 |
| `write_bitstream` | 1 |

Unresolved black boxes: 0. Route errors: 0. Unrouted nets: 0.

## Timing and routing

| Metric | Result |
| --- | ---: |
| WNS | +0.617 ns |
| TNS | 0.000 ns |
| WHS | +0.036 ns |
| THS | 0.000 ns |
| Setup-failing endpoints | 0 |
| Hold-failing endpoints | 0 |
| Fully routed nets | 35,810 |
| Nets with routing errors | 0 |

Vivado reports: `All user specified timing constraints are met.`

## DRC

| Severity | Count |
| --- | ---: |
| Error | 0 |
| Critical warning | 0 |

The report records four historical `REQP-1839` warnings. They are neither errors nor critical warnings and did not violate the frozen build gate.

## Utilization

| Stage | Slice LUTs | Slice Registers | RAMB18E1 | RAMB36E1 | Class |
| --- | ---: | ---: | ---: | ---: | --- |
| Post-synthesis | 20,319 | 21,097 | 12 | 21 | recorded |
| Post-opt | 18,577 | 20,083 | 10 | 21 | PASS_STANDARD_MARGIN |
| Final routed | 18,181 | 20,083 | 10 | 21 | PASS_STANDARD_MARGIN |

Final Slice LUT utilization is 87.41%; final Slice Register utilization is 48.28%.

## Frozen outputs

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `ahd_capture_v41_i2c_25khz_r1i_qualified_ack_readiness_poc.bit` | 2,192,144 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| `R1I_routed.dcp` | 57,978,524 | `8E1AD0F2F15D43BDC1CBF9FA5FD22E1D5ABBF2E7CC6EDBED5A8DFF628107A81D` |
| `R1I_post_opt.dcp` | 48,250,846 | `AD4870BFB916CA56EF2ADDC7468799540FD3DEDAB352029F0CE7CA36396BB74B` |
| `R1I_synth.dcp` | 48,906,973 | `D04D58835443FD1FD5CAA64FD9BF92024A719ACCD16D03B73F6688604EFD25C7` |

No LTX was produced or required by the frozen MMIO/BRAM instrumentation flow.

## Hardware-use disposition

The build itself passed every mandatory gate. Hardware use did not begin because the subsequent read-only Formal-baseline transport was denied by the execution environment. The bitstream was never programmed.
