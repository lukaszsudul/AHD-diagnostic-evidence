# Sole clean-build hard stop

BUILD_INVOCATIONS=1

BUILD_COMPLETED=NO

HARD_STOP_CLASSIFICATION=BLOCKED_SINGLE_BUILD_REPORT_SCRIPT_ERROR_BEFORE_WRITE_BITSTREAM

Vivado 2025.2 build 6299465 completed synthesis, `opt_design`, placement, `phys_opt_design`, routing, routed checkpoint generation, timing, DRC, CDC, methodology, power, I/O, clock, and SCL/SDA timing reports. The routed results were:

- synthesis: 0 errors, 0 critical warnings;
- place: PASS;
- route: PASS;
- routed nets: 26,488 / 26,488;
- routing errors: 0;
- WNS: +0.617 ns;
- WHS: +0.021 ns;
- DRC errors: 0;
- DRC critical warnings: 0;
- REQP-1839: 4, equal to the exact accepted 25-kHz R1 baseline;
- CDC critical: 0;
- CDC unknown: 0.

The script then evaluated two NVP IOBUF cells and passed the two-object collection to:

```tcl
report_property -file .../R1E_nvp_iobuf_properties.txt $nvp_iobuf_cells
```

Vivado stopped with:

```text
ERROR: [Common 17-56] 'report_property' expects exactly one object got '2'.
```

This occurred before `write_bitstream`. Therefore:

R1E_BIT_AVAILABLE=NO

R1E_BIT_SHA256=NOT_AVAILABLE

SOURCE_COMMIT_TO_BIT_PROVENANCE=NOT_APPLICABLE_NO_BIT

The mandated no-source-correction/no-second-build rule was applied. The script was not edited, no second build was started, and the hardware entry gate failed. The shared lock was released immediately after the process terminated.

Preserved hashes:

- synth DCP: `1B86629EF73506533022488C28F41B56027E9FA1D6CFCB855381B79D6F78C001`
- routed DCP: `1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1`
- build log: `CC5DD8948AC0FD4C8D10C41E938AAB082D46AEB7245D855163017E7CF1BF01D0`
