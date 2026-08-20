# Fresh formal Phase-2 before-state

## Host and endpoint

    UTC=2026-08-20T12:36:15Z
    HOSTNAME=VCDE-DUT-1
    BOOT_ID=b636cf27-8373-4ca0-8819-ef2b8a722822
    ENDPOINT_COUNT=1
    ENDPOINT_BDF=0000:01:00.0
    ENDPOINT_ID=10ee:7011
    SUBSYSTEM=10ee:0007
    CLASS=058000
    LINK=PASS_GEN1_X1_2.5GT_S
    BAR0=PASS_128_KIB
    BAR1=PASS_64_KIB
    DRIVER_LINK=xdma
    XDMA_DRIVER_SOURCE_COMMIT=8721136e74a66500b02d16cb41922d966139cd46
    XDMA_DRIVER_VERSION=2025.2.0
    XDMA_MODULE_SHA256=523ed1f77a4700773ef1df846a54592d7396774826acabbcb222e104cc5a9490
    XDMA_DEVICE_NODES=PASS

The source-commit provenance is the accepted pinned new-host deployment
identity. The currently loaded kernel-matched module, modinfo identity, module
SHA-256, driver binding, and complete node inventory were collected fresh.

## Formal runtime identity

Four independent sudo-authenticated processes used the accepted read-only
AXI-Lite reader. No AXI-Lite write was issued.

    BLOCK_ID=0xA40A0C07
    PROTOCOL=0x0000400B
    CAPABILITIES=0x00031002
    DIAGNOSTIC_MAGIC=0x00000000
    FORMAL_IDENTITY=PASS_A40A0C07_0000400B_00031002
    PCIE_XDMA_HEALTH=PASS

The targeted kernel log contains normal enumeration and XDMA load messages and
no AER error, completion timeout, Oops, panic, hang, or fatal event.

## Fresh read-only JTAG

    JTAG_TARGET=localhost:3121/xilinx_tcf/Digilent/210241768436
    DEVICE_COUNT=1
    FPGA=xc7a35t
    IDCODE=0362D093
    DONE=1
    READ_ONLY_JTAG_GATE=PASS
    FPGA_PROGRAM_OPERATIONS=0

The task-local Vivado, hw_server, and cs_server processes were closed after the
read-only session.

    FORMAL_BEFORE_STATE=PASS
