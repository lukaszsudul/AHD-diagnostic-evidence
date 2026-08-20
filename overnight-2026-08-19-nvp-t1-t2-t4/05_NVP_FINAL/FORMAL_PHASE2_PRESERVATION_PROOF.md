# Formal Phase-2 preservation proof

```text
CURRENT_IMAGE_AT_AUTHORIZED_START=FORMAL_PHASE2_ACCEPTED_REFERENCE
RCA_PROGRAM_OPERATIONS=0
OTHER_FPGA_PROGRAM_OPERATIONS=0
COLD_STARTS=0
WARM_REBOOTS=0
PHYSICAL_ACTIONS=0
FRESH_JTAG_TARGET=localhost:3121/xilinx_tcf/Digilent/210241768436
FRESH_JTAG_FPGA=xc7a35t
FRESH_JTAG_IDCODE=0362D093
FRESH_JTAG_DONE=1
DIAGNOSTIC_IMAGE_ACTIVE=NO
FORMAL_PHASE2_ACTIVE_AT_END=YES_PRESERVED_BY_ZERO_MUTATION
```

The authoritative start state identified the configured SRAM image as the accepted formal Phase-2 reference. No command capable of changing FPGA configuration, host boot state, or physical state was executed. A fresh exact-target read-only JTAG session independently confirmed the expected FPGA, IDCODE, and DONE=1. Therefore the initial formal image remained active by state invariance; no restoration program was necessary.

Host-side BLOCK_ID/PROTOCOL/CAPABILITIES and diagnostic magic were not re-read because non-interactive SSH authentication could not complete. Their reported values remain the authoritative input values, not fresh overnight observations:

```text
BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002
DIAGNOSTIC_MAGIC=0x00000000
```
