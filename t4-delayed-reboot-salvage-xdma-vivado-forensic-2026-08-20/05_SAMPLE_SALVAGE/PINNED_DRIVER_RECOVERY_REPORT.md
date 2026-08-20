# Pinned-driver recovery report

All continuity, endpoint, module-hash, loader-hash, kernel/vermagic, Secure Boot, and no-preexisting-module gates passed. The single authorized recovery transaction then stopped before module insertion:

`sudo` could not execute the accepted loader because the preserved script is not executable (`0644`).

No retry is permitted. A read-only post-check proved the boot ID unchanged, no `xdma` module loaded, no driver bound, no XDMA nodes, and unchanged PCIe geometry.

    WRONG_XDMA_MODULE_UNLOADED=NO_NOT_LOADED
    PINNED_DRIVER_RECOVERY_TRANSACTIONS=1
    PINNED_DRIVER_INSMOD_INVOCATIONS=0
    PINNED_DRIVER_RECOVERY=BLOCKED_ACCEPTED_LOADER_NOT_EXECUTABLE_NO_RETRY
    PCI_RESET_OR_RESCAN_ACTIONS=0

