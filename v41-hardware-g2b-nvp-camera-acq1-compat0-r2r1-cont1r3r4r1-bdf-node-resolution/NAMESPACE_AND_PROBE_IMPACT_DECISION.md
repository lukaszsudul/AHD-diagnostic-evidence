# Namespace and probe-impact admission decision

Result: **Path C — BLOCKED_EXISTING_GLOBAL_XDMA_CLASS_COLLIDES_WITH_QUALIFIED_AHD_DRIVER**.

1. Current AHD `0000:01:00.0` is the sole current function matching the exact candidate PCI alias (`10ee:7011`, subsystem `10ee:0007`). Protected `0000:0b:00.0` is `10ee:7021`, subsystem `10ee:f0a1`; it is not in that exact match set. Thus the candidate's narrow probe table is not the blocker.
2. Current `/sys/class/xdma` exists and contains `xdma0_user`, `xdma0_c2h_0` and other entries. Their `/sys/dev/char` ancestry resolves to protected `0000:0b:00.0` and live module `xdma`. AHD has no corresponding node.
3. The pinned upstream `xdma_cdev.h` defines `XDMA_NODE_NAME` as `"xdma"`; the qualified AHD patch only changes module name/Kbuild/PCI table and does not alter this define. `xdma_cdev_init()` calls `class_create(XDMA_NODE_NAME)` unconditionally on kernel 7.0 and returns on error. `xdma_mod_init()` invokes that initialization **before** `pci_register_driver()`.
4. Linux class registration places the class under `/sys/class` by name; the Linux kobject layer returns `-EEXIST` for a duplicate name at the same parent. The exact AHD candidate lacks an approved shared-class mechanism. Consequently a guessed `/dev/xdma1_*` path cannot solve the pre-probe class conflict. No candidate module insertion was performed; the consequence is inferred from qualified source and current namespace, not asserted as an observed failure log.

Pinned candidate source provenance: upstream `Xilinx/dma_ip_drivers` commit `b8466090b4e812e191da9e9305ffb11cb7ace768` plus AHD patch SHA-256 `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7`, source commit `0a201aab7adb13be079e784c6ed97dfad2ed7764`. Local exact source constructs: `XDMA/linux-kernel/xdma/xdma_cdev.h:29`, `xdma_cdev.c:604-620`, `xdma_mod.c:301-305`. No vendor source bytes are republished.

Primary behavior references: [Linux sysfs](https://docs.kernel.org/filesystems/sysfs.html), [Linux class registration](https://github.com/torvalds/linux/blob/master/drivers/base/class.c), [Linux duplicate kobject name](https://github.com/torvalds/linux/blob/master/lib/kobject.c). These support the stated inference; they do not authorize intervention.

Only recommended resolution: a **separate Owner-authorized, offline AHD driver-namespace isolation and full qualification**, including the candidate class/device namespace and explicit host node resolver, while preserving the protected function and its existing driver. This is a new driver artifact and not a task-local path fix. No rebuild, rename, unload, reboot, rebind, MMIO or firmware operation is authorized in CONT1R3R4R1 after this gate.
