# G2B-HW0-DRV1 source-delta audit

## Verdict

```text
SOURCE_DELTA_AUDIT=PASS
AUTHORIZED_DELTA_PATH_COUNT=2
GENERIC_TRANSPORT_BEHAVIOR_UNCHANGED=YES
DRIVER_PAYLOAD_BEHAVIOR=GENERIC_TRANSPORT_ONLY
FUNCTIONAL_DMA_ENGINE_DELTA=NO
```

The complete candidate source delta is the hash-pinned patch
`415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7`
applied to official upstream commit
`b8466090b4e812e191da9e9305ffb11cb7ace768`, tree
`f9286c5d1bdae57285570ac5c23244d54076b99f`. Only two upstream paths change.

## Machine-readable classification

| Path | Hunk | Classification | Allowed class | Behavior effect |
|---|---|---|---|---|
| `XDMA/linux-kernel/xdma/Makefile` | `TARGET_MODULE:=xdma` to `TARGET_MODULE:=xdma_ahd_pcie` | `UNIQUE_KERNEL_MODULE_IDENTITY` | 2 | Changes the Kbuild output/internal object identity; no transport logic change. |
| `XDMA/linux-kernel/xdma/Makefile` | active `EXTRA_CFLAGS` assignments to same-value `ccflags-y` assignments | `PROVEN_KERNEL_BUILD_COMPATIBILITY` | 4 | Preserves include path, debug conditional, config-BAR conditional, and values; build-system namespace only. |
| `XDMA/linux-kernel/xdma/xdma_mod.c` | `DRV_MODULE_NAME` from `xdma` to `xdma_ahd_pcie` | `UNIQUE_KERNEL_MODULE_IDENTITY` | 2 | Changes the PCI driver/module label only. |
| `XDMA/linux-kernel/xdma/xdma_mod.c` | description gains `(AHD exact PCI match)` | `DISTINGUISHING_METADATA` | 3 | Metadata only. |
| `XDMA/linux-kernel/xdma/xdma_mod.c` | upstream broad 57-entry table replaced with one exact `PCI_DEVICE_SUB` entry | `EXACT_AHD_PCI_SUBSYSTEM_MATCH` | 1 | Narrows device discovery to `10ee:7011 / 10ee:0007`; does not alter probe/transport implementation. |

Allowed-class mapping:

1. exact AHD PCI/subsystem match;
2. unique kernel-module/Kbuild identity;
3. minimal metadata needed to distinguish the AHD module;
4. strictly necessary, already evidenced Kbuild compatibility adjustment.

No other source path or generated input was allowed to differ. Build A and
Build B record the same prepared-source input-manifest SHA-256
`7D28F66A4253A213E75B73036ED38D8E2F8974DEDDA4378CB3D028B5C2956019`
and the same complete patch/source-diff SHA-256
`415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7`.

## Exact identity delta

The patched PCI table is exactly:

```c
static const struct pci_device_id pci_ids[] = {
	{ PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007), },
	{0,}
};
MODULE_DEVICE_TABLE(pci, pci_ids);
```

The module name/description definitions are exactly:

```c
#define DRV_MODULE_NAME        "xdma_ahd_pcie"
#define DRV_MODULE_DESC        "Xilinx XDMA Reference Driver (AHD exact PCI match)"
```

Kbuild produces `xdma_ahd_pcie.ko`, and static `modinfo` reports the internal
name `xdma_ahd_pcie`. The module-object rename is behavior-preserving: its
object list is unchanged.

## Separately justified non-ID source delta

The only non-ID/non-name delta is the Makefile migration of three active
assignments from deprecated `EXTRA_CFLAGS` to `ccflags-y`:

- base include/XVC flags;
- optional `-D__LIBXDMA_DEBUG__` under the unchanged `DEBUG=1` condition;
- optional `-DXDMA_CONFIG_BAR_NUM=...` under the unchanged `config_bar_num`
  condition.

This exact generic adjustment was governed in the prior HDMI process as patch
SHA-256
`AF405EAB420049CDB4E0AD356E9945A064AF082A1E4EC0D2DED901534572C736`
and classified `GENERIC_KERNEL_COMPATIBILITY`. DRV1 uses `DEBUG=0`, empty BAR
override, and empty XVC flags. The change does not add, remove, or alter a C
source operation.

## Transport invariants

The patch does not touch `libxdma.c`, `xdma_cdev.c`, `xdma_cdev.h`, engine,
interrupt, thread, transfer, character-device, ioctl, SGDMA, or performance
implementation files. Inspection of the complete two-path diff found no change
to:

- DMA descriptor construction, ownership, completion, or semantics;
- C2H/H2C engine logic or streaming behavior;
- interrupt registration, mode, acknowledgement, or policy;
- BAR discovery, mapping, offsets, or user-BAR behavior;
- read/write, ioctl, mmap, and character-device transfer semantics;
- channel enumeration, channel indexing, or multi-device indexing;
- alignment, timeout, polling, or credit policy;
- standard XDMA class or character-device node naming;
- payload bytes or interpretation.

The candidate does not parse or interpret AHD record headers, pixels, frames,
`AHD_C2H_TRANSPORT_ABI_V1`, or NVP telemetry. Those semantics remain a userspace
responsibility.

## Repository-scope audit

The dedicated driver commit is
`0a201aab7adb13be079e784c6ed97dfad2ed7764`, tree
`6f079bf086878ddbce1f1ec82fece3039eae6573`, based directly on PRODUCT commit
`92e9b3d914134c044371779def1ee18eaaeda98a`. It adds only seven files under
`host/xdma/ahd_pcie/` and makes no tracked delta to RTL, FPGA XDC, IP, FPGA
build scripts, ABI, MMIO, PRODUCT bitstream, R-track, or HDMI content.

## Offline qualification boundary

This audit proves the source restriction and static candidate identity. It does
not prove that probe, node creation, MMIO, or DMA will succeed at runtime. Those
are separately authorized R3 gates.
