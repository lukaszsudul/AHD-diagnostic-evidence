# Formal Phase-2 baseline restoration

The archived diagnostic measurement package passed its ZIP, internal manifest,
and secret-scan gates before restoration began.

Immediately before programming, the accepted formal image was reverified:

```text
BIT_FILENAME=ahd_capture_v41_phase2_p1.bit
BIT_SIZE=2192144
BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_RESTORE_PROGRAM_INVOCATIONS=1
PROGRAM_EOS=HIGH
PROGRAM_DONE=1
```

The required final Ubuntu warm reboot changed the boot ID from
`fbb23d86-fecd-40ed-8ac1-df3cbcf6185b` to
`6ef0e577-8912-4bec-b3c4-ed9404446b59`. The post-reboot gate found:

```text
SSH_AUTHENTICATED=YES
FPGA=xc7a35t
FPGA_IDCODE=0362D093
FPGA_DONE=1
PCIE_BDF=0000:01:00.0
PCIE_VID_DID=10ee:7011
PCIE_SUBSYSTEM=10ee:0007
PCIE_CLASS=058000
PCIE_LINK=Gen1_x1
BAR0=131072_BYTES
BAR1=65536_BYTES
XDMA_DRIVER_COMMIT=8721136e74a66500b02d16cb41922d966139cd46
XDMA_DRIVER_LOAD=PASS
EXPECTED_XDMA_NODES=PASS
BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002
FORMAL_OFFSET_0X2000=0x00000000
DIAGNOSTIC_MAGIC_PRESENT_AFTER_RESTORE=NO
```

The `0x2000` read was authorized by the prior decode audit: this address is a
deterministic-zero, no-read-side-effect location in the formal Phase-2 image.
The first `dd` seek attempt was rejected by the character device as an illegal
seek and returned no value. One subsequent `os.pread` opened the user device
read-only and returned `0x00000000`. No write was issued.

The contextual NVP snapshot after formal restoration remained a failure, which
was explicitly not a restoration acceptance requirement:

```text
INIT_DONE=1
INIT_ERROR=1
NACK_COUNT=15
TIMEOUT_COUNT=0
FIRST_ERROR_PHASE=REGISTER_BYTE_NACK
FIRST_ERROR_STEP=0x06
FIRST_ERROR_META_BANK=0x03
FIRST_ERROR_PHYSICAL_BANK=0x03
FIRST_ERROR_REGISTER=0x3A
FIRST_ERROR_VALUE=0x00
VCLK_DELTA=152694465
SAV_DELTA=0
FRAME_DELTA=0
```

The final kernel filter found only the expected unsigned out-of-tree XDMA
module verification/taint line. It found no AER error, completion timeout,
XDMA runtime failure, Oops, panic, hung task, or watchdog lockup attributable
to restoration.

```text
FORMAL_RUNTIME_IDENTITY=PASS
FORMAL_BASELINE_RESTORED=YES
DIAGNOSTIC_BIT_ACTIVE=NO
KERNEL_PCIE_XDMA_HEALTH=PASS
```
