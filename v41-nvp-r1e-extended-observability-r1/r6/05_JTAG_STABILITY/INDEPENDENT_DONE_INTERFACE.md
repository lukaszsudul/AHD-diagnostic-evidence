# R6 independent selected-target DONE interface

```text
SCRIPT=C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\scripts\read_jtag_identity_done_r6_selected.tcl
SHA256=A1D967C7306F0C751DC5A41DE3A3D331A0CE92E36BB9430C7D99604FC8432D30
TCLARGS=NONE
TARGET=localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
CANONICAL_ID=Xilinx/80802026a98b01
PART=xc7a35t
IDCODE=0362D093
REFRESH_HW_DEVICE_COUNT=1
REQUIRED_DONE=1
PROGRAM_COMMANDS=0
JTAG_FREQUENCY_CHANGE_COMMANDS=0
STATIC_AUDIT=PASS
LIVE_JTAG_OR_VIVADO_EXECUTED=NO
```

The script opens a new read-only Hardware Manager session, reuses the frozen
R6 selector, requires one exact target and one exact device, records the
selected device properties, performs one refresh, requires readable
`REGISTER.IR.BIT5_DONE=1`, emits a zero-program receipt, and closes without any
programming or mutation command.

