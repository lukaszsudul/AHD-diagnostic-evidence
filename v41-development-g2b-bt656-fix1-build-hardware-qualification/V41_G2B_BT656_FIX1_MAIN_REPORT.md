# AHD v41 G2B-BT656-FIX1 main report

## Governed result

- Engineering gate: **FAIL**
- Evidence publication: **PASS** (commit identified by repository history)
- Overall result: **FAIL**
- First blocker: `FIX1_FULL_PRODUCT_BUILD_BUS_SKEW_EXPORT_COUNT_FAILED:EXPECTED_17_FOUND_11`

The retained DIAG1-R1 state was safely cleared, the append-only erratum was
created, and the correction hardening gate passed 9/9. The hardened child
commit `30b14d13b0b789b62b05ab513eb9578c7c43b11a` was pushed without force.

The fresh nonincremental Vivado 2025.2 PRODUCT build synthesized, optimized,
placed, physically optimized, and physically routed the design. The raw routed
report showed WNS 0.148 ns, TNS 0.000 ns, WHS 0.044 ns, THS 0.000 ns, with zero
unrouted or partially routed nets. The governed flow then stopped in
`ROUTED_REPORTS`: the exact bus-skew exporter required 17 constraints but found
11. No waiver, suppression, constraint change, or second build was used.

Consequently the timing/CDC/DRC/methodology sign-off sequence was not completed,
no bitstream was generated, and the FIX1 FPGA programming, post-program reboot,
driver load, MMIO, DMA capture, record validation, and frame reconstruction were
not reached. The FPGA remains on the inherited DIAG1-R1 volatile profile.

The primary-only rolling host path was nevertheless built and verified before
the build blocker: its focused gate passed 16/16, using 2500 logical 4096-byte
requests, a maximum outstanding window of 1024, no guard IOCBs, pending AIO zero
at `PRIMARY_WINDOW_COMPLETE`, and persistence only after `DISABLE_ISSUED`.

All fresh FIX1 locks were released. Credential remnants are zero. No raw camera
record, frame, PNG, bitstream, DCP, driver binary, native executable, or secret
is included in this evidence directory.
