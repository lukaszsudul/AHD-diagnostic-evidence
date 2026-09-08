# Minimal PCIe/AER/kernel review

The active-session kernel health sample contains the expected out-of-tree and
unsigned-module taint messages and normal XDMA probe messages. It contains no new
AHD-related Oops, BUG, call trace, DMA-API fault, IOMMU fault, AER fatal/nonfatal
event, malformed TLP, unsupported request, or engine fatal error.

Active-session health: PASS. Post-unload checkpoint: NOT_REACHED because unload
was prohibited while quiescence and guard cleanup were unresolved.

Sanitized captured output:

```text
R3R4R6R2R3_MINIMAL_KERNEL_HEALTH
[Tue Sep  8 11:01:22 2026] ata3: SATA link down (SStatus 0 SControl 300)
[Tue Sep  8 11:01:22 2026] ata4: SATA link down (SStatus 0 SControl 300)
[Tue Sep  8 11:01:23 2026] systemd[1]: Mounting sys-kernel-debug.mount - Kernel Debug File System...
[Tue Sep  8 11:01:23 2026] systemd[1]: Mounted sys-kernel-debug.mount - Kernel Debug File System.
[Tue Sep  8 11:01:25 2026] amdgpu 0000:0c:00.0: [drm] PCIE GART of 512M enabled (table at 0x000000801FD00000).
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie: loading out-of-tree module taints kernel.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie: module verification failed: signature and/or required key missing - tainting kernel
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:xdma_mod_init: Xilinx XDMA Reference Driver (AHD exact PCI match) xdma_ahd_pcie v2025.2.0
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:xdma_mod_init: desc_blen_max: 0xfffffff/268435455, timeout: h2c 10 c2h 10 sec.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:xdma_device_open: xdma_ahd_pcie device 0000:01:00.0, 0x0000000024b36582.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie 0000:01:00.0: enabling device (0000 -> 0002)
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:map_single_bar: BAR0 at 0xf6f00000 mapped at 0x000000003f9495cc, length=131072(/131072)
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:map_single_bar: BAR1 at 0xf6f20000 mapped at 0x00000000aa7b635f, length=65536(/65536)
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:map_bars: config bar 1, pos 1.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:identify_bars: 2 BARs: config 1, user 0, bypass -1.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:pci_keep_intx_enabled: 0000:01:00.0: clear INTX_DISABLE, 0x406 -> 0x6.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:probe_one: 0000:01:00.0 xdma0, pdev 0x0000000024b36582, xdev 0x000000008aff239f, 0x00000000a38644ef, usr 16, ch 1,1.
[Tue Sep  8 13:04:28 2026] xdma_ahd_pcie:cdev_xvc_init: xcdev 0x00000000240f5093, bar 0, offset 0x40000.
```
