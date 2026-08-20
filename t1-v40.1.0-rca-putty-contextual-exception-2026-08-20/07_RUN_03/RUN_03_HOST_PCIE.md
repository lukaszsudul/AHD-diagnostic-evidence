# RC-A Run 03 host and PCIe gate

    ENDPOINT_COUNT=1
    ENDPOINT_BDF=0000:01:00.0
    VENDOR_DEVICE=10ee:7011
    SUBSYSTEM_DEVICE=0007
    CLASS=058000
    LINK=Gen1_x1_2.5GT/s
    BAR0_BYTES=131072
    BOUND_DRIVER=NONE_EXPECTED_RCA_B7
    CRITICAL_KERNEL_AER_XDMA_ERRORS=0
    HOST_PCIE_KERNEL_HEALTH=PASS

The required endpoint was present once, the link and BAR identity matched the
accepted RC-A/B7 contract, and no critical endpoint/AER/kernel condition was
observed. The accepted observe tool restored the PCI command register exactly
and left bus mastering disabled.
