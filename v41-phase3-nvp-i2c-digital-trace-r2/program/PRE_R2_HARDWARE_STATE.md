# Pre-R2 formal hardware state

Snapshot time: 2026-08-19T12:16:19+02:00. All host and MMIO operations were
read-only. The approved Windows host context was used for LAN/SSH/JTAG.

The target ED25519 fingerprint presented on the wire exactly matched the
qualified new-host evidence:
`SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`.

```text
SSH_AUTHENTICATED=YES
HOST=10.132.1.111
HOSTNAME=VCDE-DUT-1
USER=vcdeagent1
BOOT_ID=6ef0e577-8912-4bec-b3c4-ed9404446b59
NTP_SYNCHRONIZED=YES

PCIE_BDF=0000:01:00.0
PCIE_VID_DID=10ee:7011
PCIE_SUBSYSTEM=10ee:0007
PCIE_CLASS=058000
PCIE_LINK=Gen1_x1
BAR0=131072_BYTES
BAR1=65536_BYTES
XDMA_DRIVER_COMMIT=8721136e74a66500b02d16cb41922d966139cd46
XDMA_DRIVER=LOADED
EXPECTED_XDMA_NODES=PASS

FORMAL_RUNNING_IMAGE=ACCEPTED_PHASE2_REFERENCE
FORMAL_PHASE2_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002

NVP_STATUS=0x000000FB
INIT_DONE=1
INIT_ERROR=1
NVP_NACK_COUNT=15
NVP_TIMEOUT_COUNT=0
NVP_FIRST_ERROR=0x80020600
NVP_DETAIL_W3=0x003A0306
VCLK_EDGE_COUNT=0x5EFB20B8
ACTIVE_SAV_COUNT=0
RECORD_COMMIT_COUNT=0

JTAG_TARGET=localhost:3121/xilinx_tcf/Digilent/210241768436
FPGA_PART=xc7a35t
FPGA_IDCODE=0362D093
FPGA_DONE=1
READ_ONLY_JTAG_GATE=PASS

AXIL_READS=17
AXIL_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```

The kernel match filter produced only two known false positives: the word
`panic` in an AMDGPU plane-registration line and the expected unsigned XDMA
module verification/taint notice. No AER failure, completion timeout, XDMA
runtime failure, Oops, panic, hung task, or watchdog lockup was observed.

The formal repository remained at branch `v41/xdma-v40.1.0-base`, HEAD
`c89e88bcdf389614c884fb129e8b2d42a585bccb`, with a clean worktree and the
Phase-2-p2 tag unchanged.
