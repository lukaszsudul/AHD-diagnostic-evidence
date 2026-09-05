# G2B-HW0-PRODUCT-R1 Programming Receipt

Result: `PASS`

| Field | Exact value |
|---|---|
| Candidate path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit` |
| Candidate bytes / SHA-256 | `2192144 / AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Target | `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01` |
| FPGA | `xc7a35t`, IDCODE `0362D093` |
| Pre-program DONE samples | `0,0,0,0,0` |
| Program start | `2026-09-05T22:03:58Z` |
| Program returned / end | `2026-09-05T22:04:05Z` |
| Vendor startup | `HIGH` |
| Immediate DONE | `1` |
| Final DONE samples | `1,1,1,1,1` |
| Final JTAG sample end | `2026-09-05T22:14:31Z` |
| Program invocations | `1` |
| Automatic retries | `0` |
| Flash / CFGMEM / PROGRAM_B | `0 / 0 / 0` |

The executing supervisor rehashed the exact candidate before launch. The Tcl
script independently checked the exact path argument, filename, and byte size;
recorded the expected SHA-256 and the requirement for a Windows-supervisor PASS;
selected the exact target/device; and contained one static `program_hw_devices`
invocation. The post-run authority
replay independently rehashed the candidate again. The Tcl final literal is
`PROGRAM_TCL_RESULT=PASS_DONE_1`. No second program or rollback operation
occurred.
