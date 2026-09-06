# G2B-HW0-DRV1 expected node model

## Classification

```text
NODE_MODEL=OFFLINE_SOURCE_DERIVATION
EXPECTED_CLASS_NAME=xdma
EXPECTED_USER_NODE=/dev/xdmaN_user
EXPECTED_C2H_NODE=/dev/xdmaN_c2h_0
MULTI_DEVICE_INDEXING=SUPPORTED_DYNAMIC
LIVE_NODE_CREATION_CLAIM=NO
```

`N` is a runtime-selected nonnegative device index. It must not be assumed to
be zero when another XDMA PCIe device is or has been registered.

## Exact source-code evidence

Source authority is official `Xilinx/dma_ip_drivers` commit
`b8466090b4e812e191da9e9305ffb11cb7ace768`, tree
`f9286c5d1bdae57285570ac5c23244d54076b99f`. The AHD patch changes neither
`xdma_cdev.h`, `xdma_cdev.c`, nor `libxdma.c`.

| Source | Lines / symbol | Evidence |
|---|---|---|
| `XDMA/linux-kernel/xdma/xdma_cdev.h` | line 29, `XDMA_NODE_NAME` | `#define XDMA_NODE_NAME "xdma"` |
| `XDMA/linux-kernel/xdma/xdma_cdev.c` | lines 40-49, `devnode_names[]` | Declares templates `xdma%d_user`, `xdma%d_control`, `xdma%d_xvc`, `xdma%d_events_%d`, `xdma%d_h2c_%d`, `xdma%d_c2h_%d`, `xdma%d_bypass_h2c_%d`, `xdma%d_bypass_c2h_%d`, and `xdma%d_bypass`. |
| `XDMA/linux-kernel/xdma/xdma_cdev.c` | lines 109-121, character-device name setup | Formats user/control/XVC names with `xdev->idx`; engine names with `xdev->idx` and `engine->channel`; event names with `xdev->idx` and the event/BAR index. |
| `XDMA/linux-kernel/xdma/xdma_cdev.c` | lines 234-236 | Calls `device_create` with the character-device kobject name. |
| `XDMA/linux-kernel/xdma/xdma_cdev.c` | lines 468-588 | Creates the interfaces that are present for the discovered user BAR, control BAR, engines, events, XVC, and bypass capabilities. |
| `XDMA/linux-kernel/xdma/xdma_cdev.c` | lines 604-616, `xdma_cdev_init` | Calls `class_create` with `XDMA_NODE_NAME`, producing class `xdma`. |
| `XDMA/linux-kernel/xdma/libxdma.c` | lines 108-127, `xdev_list_add` | Assigns index 0 when the device list is empty; otherwise assigns the last device's index plus one. |

The AHD patch changes `TARGET_MODULE` and `DRV_MODULE_NAME` to
`xdma_ahd_pcie`, but deliberately does not change `XDMA_NODE_NAME`. Therefore
the unique kernel-module name does not change the standard XDMA class or
character-device prefix.

## Expected functional nodes

For the current one-channel AHD design, a successful future probe is expected
to expose at minimum:

| Function | Expected pattern | First-device example only |
|---|---|---|
| User BAR | `/dev/xdmaN_user` | `/dev/xdma0_user` |
| C2H channel 0 | `/dev/xdmaN_c2h_0` | `/dev/xdma0_c2h_0` |

The `xdma0` examples are naming illustrations, not a pinned device index.

Depending on the hardware capabilities discovered by the unmodified upstream
probe path, the standard driver may also create:

- `/dev/xdmaN_control`;
- `/dev/xdmaN_h2c_0` and additional H2C/C2H channel nodes;
- `/dev/xdmaN_events_M` event nodes;
- `/dev/xdmaN_xvc` when an XVC interface is present/configured;
- `/dev/xdmaN_bypass`, `/dev/xdmaN_bypass_h2c_M`, and
  `/dev/xdmaN_bypass_c2h_M` when bypass capabilities exist.

The source templates prove the naming possibilities; DRV1 does not assert
which optional hardware capabilities a future live probe will discover.

## Multi-device behavior

The upstream allocator makes the index dynamic. Historical HDMI evidence also
shows that an exact PCIe XDMA binary can create standard `xdma0_*` nodes and
that those nodes can be correlated to a BDF through sysfs, but that historical
result is not imported as an AHD runtime result.

A future R3 must:

1. discover the actual `N` after the exact candidate probes;
2. prove every selected node's sysfs ancestry maps to the exact AHD BDF;
3. stop if a node maps to an unexpected endpoint;
4. make that mapping proof before any separately authorized MMIO or DMA.

## DRV1 non-claims

Fresh pre-build inventory found zero `/dev/xdma*` nodes and neither relevant
module loaded. DRV1 did not load the candidate and therefore created no live
nodes. This document is an offline expected model derived from unchanged
upstream source; runtime node creation and node-to-BDF correlation remain R3
qualification items.
