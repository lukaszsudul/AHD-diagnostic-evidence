# Exact formal Phase-2 restoration

The exact sealed Phase-2 image was programmed once, returned EOS high and
DONE=1, and was followed by exactly one controlled warm reboot. The boot ID
changed and password-authenticated Plink returned through the sealed host key.

The first runtime check correctly found the formal endpoint and both BARs but
ran before a driver was loaded. A same-named Ubuntu platform `xdma` module was
then selected by `modprobe`; it did not bind to the PCIe endpoint or create any
node. It was removed while unbound. The accepted Phase-2 loader was then used
only after proving all three controlling identities: driver repository commit
`8721136e74a66500b02d16cb41922d966139cd46`, pinned PCIe module SHA-256
`1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A`,
and loader SHA-256
`7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F`.
The pinned module bound once and created the expected nodes. No driver build,
install, source change, reboot, or FPGA retry resulted from the correction.

Four independent accepted read-only register invocations proved BLOCK_ID,
PROTOCOL, CAPABILITIES, and diagnostic magic. The final fresh JTAG session
proved the exact FPGA/IDCODE and DONE=1 without programming.

    FORMAL_RESTORE_PROGRAM_INVOCATIONS=1
    FORMAL_RESTORE_EOS=HIGH
    FORMAL_RESTORE_DONE=1
    FORMAL_RESTORE_WARM_REBOOT=1
    BOOT_ID_CHANGED=YES
    ENDPOINT_COUNT=1
    LINK=Gen1_x1
    BAR0_BYTES=131072
    BAR1_BYTES=65536
    PINNED_XDMA_DRIVER_NODES=PASS
    FORMAL_IDENTITY=PASS_A40A0C07_0000400B_00031002
    DIAGNOSTIC_MAGIC=0x00000000
    TARGETED_KERNEL_AER_XDMA_HEALTH=PASS
    FINAL_FPGA=xc7a35t
    FINAL_IDCODE=0362D093
    FINAL_DONE=1
    FORMAL_PHASE2_ACTIVE_AT_END=YES
    RCA_IMAGE_ACTIVE_AT_END=NO
