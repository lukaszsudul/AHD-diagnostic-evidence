# Activation and runtime receipt

The exact known JTAG target `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`
reported `xc7a35t`, IDCODE `0362D093`, `DONE=0` before activation. One
predeclared SRAM programming invocation of the exact approved bitstream
returned `DONE=1`; attempts `1/1`, no Flash write or retry. A graceful warm
reboot was scheduled exactly once for the established PCIe re-enumeration
path. Final boot ID: `e9656f6c-dd41-4500-95cc-9dc90ef9b69d`.

Final-boot AHD PCI identity was `0000:01:00.0`, `10ee:7011`, subsystem
`10ee:0007`, parent `0000:00:01.1`, Gen2 x1. The `xdma` namespace was free
before the qualified driver was loaded. The existing `xdma_ahd_pcie.ko`
matched size, full SHA-256, srcversion, kernel vermagic and target-only PCI
alias. One normal `insmod` (no parameters, alternate module, bind override or
node permission change) succeeded. Discovered `N=0`; both required nodes
mapped through `/sys/dev/char` to the target BDF. Their stable per-session
`dev_t` values were `511:0` (user) and `511:36` (C2H-0).

The final-boot 34-file closed bundle passed exact file/hash, imports,
module-origin and projection checks, with zero missing resources. The runtime
read through an opened FD verified against the selected node returned:

| Identity | Measured value |
| --- | --- |
| SCAN1 magic/version/capabilities | `0x4E565343` / `0x00010001` / `0x0000000F` |
| SCAN1 entries/groups/I2C | 82 / 10 / 25,000 Hz |
| ACQ magic/version/capabilities | `0x4E564143` / `0x00010000` / `0x000000FF` |
| Telemetry magic/version/capabilities | `0x4E565433` / `0x00010000` / `0x0000007F` |
| Implementation magic/version | `0x52335231` / `0x00010000` |
| Telemetry schema digest | `438D630943B0D3A2BFCB2C23B9FB060FD0C347C16F331D008997DBB3B8B22F95` |
| SCAN1 manifest digest | `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B` |

SCAN1 inert MMIO sanity `16/16 PASS`; ACQ inert MMIO sanity `16/16 PASS`.
Runtime status showed autoinit done, not busy, no ACQ error, I2C ready,
scanner idle before scanning and functional-write count zero. A dedicated
autoinit NACK counter was not separately retained, so exact `NACK_COUNT=0`
for autoinit is not claimed. No camera DMA channel was opened or used.
