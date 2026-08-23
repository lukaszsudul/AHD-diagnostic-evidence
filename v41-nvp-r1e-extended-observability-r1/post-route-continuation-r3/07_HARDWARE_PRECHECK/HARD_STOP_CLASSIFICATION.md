# Hardware precheck hard stop

CLASSIFICATION=BLOCKED_REQUIRED_FORMAL_START_STATE
JTAG_PRECHECK=PASS
JTAG_TARGET_COUNT=1
JTAG_HS2_SERIAL=210241768436
JTAG_PART=xc7a35t
JTAG_IDCODE=0362D093
JTAG_DONE=1
CURRENT_KERNEL=7.0.0-29-generic
ENDPOINT_COUNT=1
ENDPOINT_ID=10ee:7011
ENDPOINT_SUBSYSTEM=10ee:0007
ENDPOINT_CLASS=058000
ENDPOINT_LINK=GEN1_X1
BAR0_BYTES=131072
BAR1_BYTES=65536
XDMA_OPEN_PROCESS_COUNT=0
TASK_DMA_TRANSFERS=0
CURRENT_BOOT_ID=a2b8dff1-e296-4b32-a230-fe6d8a2caa49
RETAINED_FORMAL_CLOSURE_BOOT_ID=7f8db2e5-12aa-4421-b44a-28e72fff483f
BOOT_CONTINUITY=FAIL
ACCEPTED_READER_OFFSET_0X00000000_OBSERVED=0xFFFFFFFF
ACCEPTED_READER_OFFSET_0X00000000_EXPECTED=0xA40A0C07
FORMAL_RUNTIME_IDENTITY_GATE=FAIL
FORMAL_DIAGNOSTIC_MAGIC_GATE=NOT_REACHED_AFTER_IDENTITY_FAILURE
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
POST_REBOOT_DRIVER_LOADS=0
PROGRAM_RETRIES=0

The fresh JTAG transport and FPGA identity were valid, but JTAG DONE does not establish the loaded application image. The live boot no longer matches the retained exact-formal closure boot, and the accepted AXI-Lite reader failed the first formal identity word. The prompt forbids a formal bootstrap program, PCIe reset/rescan, driver recovery loop, physical recovery, or any program before exact formal Phase-2 start state is proven. R3 therefore stopped before Arm A.

An initial credential-helper invocation and one accepted-reader invocation were rejected before the intended remote executable ran because task-local command paths used the wrong expansion context. Both raw records are preserved. They consumed no FPGA program, reboot, driver load, DMA, or state-changing MMIO operation. The later accepted-reader relaunch did execute and returned the authoritative 0xFFFFFFFF mismatch above.
