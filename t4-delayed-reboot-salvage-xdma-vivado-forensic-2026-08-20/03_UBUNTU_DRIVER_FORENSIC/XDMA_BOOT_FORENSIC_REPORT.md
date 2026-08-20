# XDMA boot forensic

The endpoint enumerated normally, but no XDMA module was loaded, no driver was bound, and no `/dev/xdma*` nodes existed. Secure Boot is disabled. No relevant modules-load, modprobe, udev, or systemd boot mechanism was found, and the boot journal contains endpoint enumeration but no pinned-driver load/probe attempt.

`modinfo xdma` resolves Ubuntu's same-named in-tree **platform** driver, not the accepted Xilinx PCIe driver. This is a future collision hazard, but that wrong module was not loaded in this boot.

    CURRENT_XDMA_MODULE_LOADED=NO
    CURRENT_XDMA_MODULE_PATH=NONE_LOADED
    CURRENT_XDMA_MODULE_SHA256=NOT_APPLICABLE
    CURRENT_XDMA_MODULE_VERMAGIC=NOT_APPLICABLE
    CURRENT_XDMA_MODULE_SIGNER=NOT_APPLICABLE
    CURRENT_XDMA_MODULE_REFCNT=0
    CURRENT_XDMA_BOUND_DEVICES=0
    ENDPOINT_BOUND_DRIVER=NONE
    EXPECTED_NODES_PRESENT=NO
    BOOT_LOAD_MECHANISM_PRESENT=NO
    BOOT_LOAD_MECHANISM_RESULT=NOT_ATTEMPTED
    PRIMARY_BOOT_BINDING_FAILURE_CLASS=PINNED_MODULE_NOT_CONFIGURED_FOR_BOOT

