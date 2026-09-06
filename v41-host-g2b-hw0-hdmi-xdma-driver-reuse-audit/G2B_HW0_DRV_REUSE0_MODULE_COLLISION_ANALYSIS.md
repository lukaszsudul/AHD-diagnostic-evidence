# G2B-HW0-DRV-REUSE0 Module-Name Collision Analysis

## Collision

Two governed identities use the internal module name `xdma`:

1. The installed Ubuntu platform-bus module at `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst`, SHA-256 `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490`, alias `platform:xdma`.
2. The HDMI PCIe XDMA module governed at `/opt/fpga-hdmi-lab/driver/xdma.ko`, expected SHA-256 `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2`, sole PCI alias for `10ee:7021/10ee:f0a1`. The current file is absent.

Fresh start and final checks show no module named `xdma` loaded. The platform file remains installed and unchanged.

## Classification

`MODULE_NAME_COLLISION_MANAGEMENT = SAFE_WITH_EXACT_PATH_LOAD`, represented in the final response as `YES_MANAGED`, only as a conditional future mechanism:

- first prove that no `xdma` module is loaded;
- verify the exact authorized PCIe module path and SHA-256;
- never use generic `modprobe xdma`;
- do not remove, replace, rewrite, or unload the installed platform module merely because it shares the name;
- correlate any dynamic `xdmaN` nodes to the intended BDF through sysfs.

This classification does not approve the HDMI module for AHD. Its exact PCI alias is incompatible, the governed file is currently absent, and module load/bind authorization is denied in this task. No load command was executed or staged.

`MODULE_DEPENDENCY_READINESS = UNRESOLVED` because the absent exact module cannot receive a fresh `modinfo` dependency inspection. The separate platform module's empty dependency field is not transferable evidence.
