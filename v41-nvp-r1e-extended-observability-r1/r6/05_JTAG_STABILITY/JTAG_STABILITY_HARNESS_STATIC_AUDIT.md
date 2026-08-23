# R6 selected-JTAG stability-harness static audit

## Result

```text
READ_ONLY_JTAG_STABILITY_SESSIONS_CONFIGURED=2
JTAG_REFRESH_SAMPLES_PER_SESSION=5
TOTAL_JTAG_STABILITY_SAMPLES_CONFIGURED=10
INTER_SAMPLE_DELAY_MS=500
R6_SELECTED_JTAG_CANONICAL_ID=Xilinx/80802026a98b01
R6_FULL_JTAG_TARGET_PATH=localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
EXPECTED_PART=xc7a35t
EXPECTED_IDCODE=0362D093
STABLE_READABLE_DONE_REQUIRED=YES_0_OR_1
FULL_TARGET_AND_DEVICE_PROPERTIES_RECORDED=YES
FRESH_OUTPUT_GATES=YES
PROGRAM_COMMANDS=0
DESIGN_MUTATION_COMMANDS=0
JTAG_FREQUENCY_CHANGE_COMMANDS=0
STATIC_AUDIT=PASS
LIVE_JTAG_OR_VIVADO_EXECUTED=NO
```

The supervisor launches two sequential Vivado batch processes. Each session
uses fresh raw/log/journal/matrix/property paths and performs exactly five
`refresh_hw_device` samples with a 500 ms interval. Aggregate validation
requires 10 rows, exact and stable full target path/canonical ID/server
endpoint/transport/part/IDCODE, target count one, device count one, successful
refreshes, monotonically increasing sample timestamps within each session, and
one stable readable DONE value across both sessions.

The scripts were only parsed, fixture-tested, hashed, and statically scanned.
No Hardware Manager, Vivado, hw_server, JTAG, or FPGA programming operation was
started by this audit.

## Frozen hashes

```text
r6_jtag_stability_session.tcl_SHA256=7CDA6928B3480802E8C47C156641B4BA3C5488D32702ED95A2EDAF281383D62E
Invoke-R6SelectedJtagStability.ps1_SHA256=2C908B0152B2E58192C10F856ACB90446C2491152D65FE214C7E828134079AC0
select_r6_jtag_target.tcl_SHA256=3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE
```

