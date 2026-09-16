# Loaded module versus disk identity

| Evidence type | Current observation | Meaning |
| --- | --- | --- |
| Live PCI binding | `0000:0b:00.0/driver -> /sys/bus/pci/drivers/xdma`; `driver/module -> /sys/module/xdma` | The protected function is bound to live module `xdma`. |
| Live `/sys/module/xdma` | `srcversion=0BD06700E95DB5A1067F2A2`, `version=2025.2.0`, taint `OE`, refcount reported `0`, parameters present | Live metadata; refcount is not unload permission. |
| Current-boot kernel log | `xdma_mod_init` Xilinx XDMA Reference Driver `v2025.2.0`; probe of `0000:0b:00.0` as `xdma0` | Corroborates live PCI driver and module, not its historical file path. |
| Installed disk lookup | `modinfo xdma` resolves `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst`, alias `platform:xdma`, `srcversion=8F61105E6B60B5A7A441D9A`, SHA-256 `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490` | Disk metadata differs from live `srcversion`; **not** proof that this file supplied the loaded module. |
| Sealed AHD candidate file | `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`, SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`, size 3,296,104, exact PCI alias for `10ee:7011`/`10ee:0007` | Byte-exact approved file exists; not loaded. |

Decision: `DISK_METADATA_VERSUS_LIVE_OWNER=DIFFERENT`. The live module's original load pathname and byte-identical file provenance remain unknown. This does not weaken the namespace blocker: the class is visibly populated by the protected function, and the sealed candidate's qualified source unconditionally creates the same class before probe. No module was inserted or removed to test this inference.
