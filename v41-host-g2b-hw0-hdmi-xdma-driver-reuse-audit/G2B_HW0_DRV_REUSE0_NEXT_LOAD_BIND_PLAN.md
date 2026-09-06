# G2B-HW0-DRV-REUSE0 Next Load/Bind Plan

## Status

`NOT_APPLICABLE — HARD STOP`

The conditional task `G2B-HW0-DRV1-HDMI-REUSE — Exact HDMI PCIe XDMA Module Load, AHD BDF Bind and Device-Node Qualification` is not authorized and must not be opened from this audit because exact reuse was rejected as `NOT_REUSABLE_PCI_ALIAS_MISMATCH`.

No executable load/bind sequence is issued. In particular, do not:

- reconstruct or obtain an ungoverned copy of `/opt/fpga-hdmi-lab/driver/xdma.ko`;
- use generic `modprobe xdma`;
- load the historical HDMI binary by exact path;
- write `driver_override` or a PCI `bind`/`unbind` file;
- assume `xdma0` or any card index;
- access MMIO or execute DMA;
- treat the installed `platform:xdma` module as a PCIe fallback.

The only recommended successor is a separately authorized AHD-compatible driver build/qualification task. That future authority must freshly fix the source, build receipt, exact kernel headers/compiler, expected module hash, AHD PCI ID policy, signature/dependency requirements, exact-path load controls, BDF-to-node proof, and rollback. It must stop before MMIO or DMA unless those operations are independently authorized.

Nothing in this record authorizes that future task or its mutations.
