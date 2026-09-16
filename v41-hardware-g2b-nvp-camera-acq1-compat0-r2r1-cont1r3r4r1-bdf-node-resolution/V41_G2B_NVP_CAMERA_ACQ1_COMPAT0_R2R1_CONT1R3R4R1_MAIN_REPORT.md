# AHD v41 CONT1R3R4R1 — BDF-bound XDMA access decision

Engineering gate: **BLOCKED**. The current AHD function `0000:01:00.0` is unbound and has no AHD XDMA nodes. The only `xdma0` user/C2H-0 nodes map through `/sys/dev/char` to protected `0000:0b:00.0`, not to AHD. More importantly, `/sys/class/xdma` is already occupied by devices bound to live module `xdma`, while the exact qualified AHD module creates a second class with the same name before PCI driver registration. This is a driver-class namespace admission blocker, not merely a dynamic-node-index problem. No speculative insertion, protected-device intervention, programming, reboot, MMIO, or scan was performed.

## Exact authority and inherited status

- Current governed project revision: `9` at start and end; the six governed entry-document hashes were unchanged. No SSOT, META, PRODUCT, FPGA source, DCP, firmware, driver binary or global configuration change.
- Frozen firmware: SHA-256 `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`, 2,192,144 bytes. Frozen routed DCP: SHA-256 `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`. Neither was opened on DUT or regenerated.
- Frozen source commit/tree: `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`.
- Qualified sealed AHD driver: `xdma_ahd_pcie.ko`, SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`, 3,296,104 bytes; local and remote sealed copies agree. The candidate's exact PCI alias matches the AHD function only in the current inventory.
- Historical CONT1R3R4 blocker evidence: commit `e7af1de0a57fe8044e8c2f80800b212e645bf66a`. This run corrects its conflation of `modinfo xdma` disk lookup with the loaded module.
- Preregistered hypotheses remain byte-identical at SHA-256 `18CDD7FBC67ABDB799475CE509BC686C3A2CD0E7153BC4E44910ABC809B5DF8C`; no characterization data were generated.

## Live read-only survey

Three bounded pinned-host-key SSH calls reached `VCDE-DUT-1`, machine-id `0e90f50d9465492b80258da5658446f8`, boot ID `32d7b853-06fe-4004-9c4b-9b4abafbe896`, kernel `7.0.0-29-generic`. This equals the last measured R4 boot; no boot cause or timestamp is inferred. The initial batch and two targeted follow-ups read only Linux metadata and exact module files. Private connection receipts are retained locally, with SHA-256 in `LIVE_PCI_DRIVER_NODE_MAP.json`; credential temporary files were removed after each call.

| Function | Current ID / topology | Driver and module | Relevant nodes | Decision |
| --- | --- | --- | --- | --- |
| `0000:01:00.0` AHD | `10ee:7011`, subsystem `10ee:0007`, Gen2 x1, parent `0000:00:01.1` | unbound; no target module | none | exact qualified match, but inaccessible under current class namespace |
| `0000:0b:00.0` protected | `10ee:7021`, subsystem `10ee:f0a1`, class `0x070001`, parent `0000:00:02.2` | `xdma` → live `/sys/module/xdma` | `xdma0_user` `511:0`, `xdma0_c2h_0` `511:36`; both resolve to this function | no-touch |

The visible `/sys/class/xdma` contains 21 entries. The protected function's physical product purpose is **not** established by this survey; its no-touch status comes from the Owner's contract. No current AHD node exists, so no dynamic index `N` can be selected. No `/dev/xdma*` node was opened.

## First failed admission gate

The qualified source patch changes the module name and narrows the PCI match but retains `XDMA_NODE_NAME="xdma"`. In the pinned source, `xdma_cdev_init()` calls `class_create(XDMA_NODE_NAME)`; `xdma_mod_init()` calls `xdma_cdev_init()` before `pci_register_driver()`. The current kernel already has `/sys/class/xdma` populated by the protected function. Linux registers classes as named objects under `/sys/class`, and duplicate kobject names in the same directory fail with `-EEXIST`. Therefore normal insertion of this exact candidate cannot satisfy the class namespace prerequisite without a separate qualified sharing/namespace change; choosing `xdma1` cannot fix a failure that occurs before PCI probe. This is a source-and-live-state inference, not an observed module-load error; insertion was deliberately not attempted. [Linux sysfs layout](https://docs.kernel.org/filesystems/sysfs.html), [Linux class registration source](https://github.com/torvalds/linux/blob/master/drivers/base/class.c), [Linux duplicate-name error path](https://github.com/torvalds/linux/blob/master/lib/kobject.c).

The module currently loaded for `0000:0b:00.0` reports `srcversion=0BD06700E95DB5A1067F2A2`, version `2025.2.0` and taint `OE` through `/sys/module/xdma`; current-boot kernel messages show its probe of `0000:0b:00.0`. By contrast, `modinfo` resolves installed `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` to `platform:xdma`, `srcversion=8F61105E6B60B5A7A441D9A`. These are **different metadata identities**; the loaded binary's historical pathname is unknown. `modinfo` is a disk-file query, not proof of the loaded code's file path. [kmod modinfo source](https://github.com/kmod-project/kmod/blob/master/man/modinfo.8.scd).

## Stop and non-interference

Admission path **C — actual namespace conflict**. The task stopped before controller/DUT locks, driver load, target MMIO, JTAG, bitstream activation, product autoinit, warm reboot and 1+1,000 scans. The final read-only check found the same boot, protected binding/module, protected node major:minor and sysfs ancestry, populated class, unbound AHD function and absent `xdma_ahd_pcie` module. Visible node holders were zero, but that observation was not treated as permission to unload. No protected reset, unbind, driver unload, node open or cleanup was attempted.

One next practical action: open a **separate Owner-authorized offline driver-namespace isolation and qualification** for the AHD candidate, affecting its class/device naming and host node-resolution contract while leaving `0000:0b:00.0` untouched. Do not treat that as a path-only correction; it would create a new binary requiring its own qualification before any new hardware campaign. A genuine camera frame remains downstream of safe Linux access, read-only characterization, and separately governed camera/mode/capture work.

Evidence publication is a separate gate. This report was prepared for append-only publication; the commit and independent commit-pinned read-back are recorded outside the immutable payload after completion.
