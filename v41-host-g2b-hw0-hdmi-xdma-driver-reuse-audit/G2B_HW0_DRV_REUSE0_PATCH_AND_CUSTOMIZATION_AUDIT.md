# G2B-HW0-DRV-REUSE0 — HDMI XDMA patch and customization audit

## Audited source identities

```text
UPSTREAM_REPOSITORY=Xilinx/dma_ip_drivers
UPSTREAM_COMMIT=b8466090b4e812e191da9e9305ffb11cb7ace768
UPSTREAM_TREE=f9286c5d1bdae57285570ac5c23244d54076b99f
HDMI_DRIVER_CONTROL_REPOSITORY=lukaszsudul/FPGA_HDMI
HDMI_DRIVER_CONTROL_COMMIT=b7ef83efcba95e74c25f67996e8c5686a6fa887c
HDMI_DRIVER_CONTROL_TREE=01d33fea7f9d36e6772342e536990151ffd1ecc3
PREPARED_TREE_FILE_COUNT=417
AUTHORIZED_DELTA_PATH_COUNT=2
```

The prepared-tree manifest and independent audit establish exactly two modified
upstream paths. There is no unresolved third driver-source delta.

## Patch 1 — HDMI-only PCI identity

```text
PATCH_PATH=demo/r0f_a/driver/xdma-pci-id-10ee-7021-only.patch
PATCH_SHA256=5CA5B73463EDE2FF74BD1C4117891F622E80F5DDAE133236FB03426CD292C51B
TARGET=XDMA/linux-kernel/xdma/xdma_mod.c
POSTIMAGE_LF_SHA256=3EFFCA6A4328AAE7A2597A35B147B396C1630313481510A893AB5980FC885EE3
CLASSIFICATION=HDMI_SPECIFIC_AND_AHD_INCOMPATIBLE
```

The patch replaces the upstream 57-entry `pci_ids[]` table with exactly:

```c
{ PCI_DEVICE_SUB(0x10ee, 0x7021, 0x10ee, 0xf0a1), },
{0,}
```

It deletes the upstream generic `PCI_DEVICE(0x10ee, 0x7011)` entry together
with every other upstream ID. The resulting built module exposes one PCI alias:

```text
pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*
```

Consequences:

- the match requires HDMI device `7021` and exact subsystem `10ee:f0a1`;
- AHD device `7011`, subsystem `10ee:0007`, cannot match;
- no BDF, slot, or root port is hard-coded;
- the restriction is a deliberate safety policy, not an accidental omission.

This single patch is independently sufficient to reject exact-binary reuse for
AHD.

## Patch 2 — kernel-7 Kbuild compatibility

```text
PATCH_PATH=demo/r0f_a/driver/xdma-kbuild-ccflags-y.patch
PATCH_SHA256=AF405EAB420049CDB4E0AD356E9945A064AF082A1E4EC0D2DED901534572C736
TARGET=XDMA/linux-kernel/xdma/Makefile
POSTIMAGE_LF_SHA256=E81FABE9B5C1FA0B3A03E1D7A3DE7AEA8CC90D03EF1FA7612A8B3AB92317F845
CLASSIFICATION=GENERIC_KERNEL_COMPATIBILITY
```

Exactly three assignments change identifier from `EXTRA_CFLAGS` to
`ccflags-y`. Operators and right-hand values remain unchanged:

- `-I$(topdir)/include $(XVC_FLAGS)`;
- optional `-D__LIBXDMA_DEBUG__`;
- optional `-DXDMA_CONFIG_BAR_NUM=$(config_bar_num)`.

The built configuration freezes `DEBUG=0`, `config_bar_num=EMPTY`,
`xvc_bar_num=EMPTY`, `xvc_bar_offset=EMPTY`, and `XVC_FLAGS=EMPTY`. The patch
does not select an HDMI BAR, change runtime behavior, or add payload logic.

## Required customization surface audit

| Area | Exact delta from upstream | Classification | AHD consequence |
|---|---|---|---|
| PCI ID table | Replaced by one exact `PCI_DEVICE_SUB(7021,f0a1)` entry | `HDMI_SPECIFIC_AND_AHD_INCOMPATIBLE` | Hard failure before probe for `7011/0007` |
| Probe/remove | None | `UPSTREAM_UNCHANGED` | Generic XDMA probe/remove remains, but AHD never reaches it |
| BAR discovery/selection | None; `config_bar_num` build knob empty | `UPSTREAM_UNCHANGED` | Runtime auto-discovery remains; no HDMI hard-coded BAR number in module |
| User BAR | None | `UPSTREAM_UNCHANGED` | Generic user-BAR character interface |
| Configuration BAR | None | `UPSTREAM_UNCHANGED` | Generic XDMA register discovery |
| Bypass BAR | None | `UPSTREAM_UNCHANGED` | No HDMI-specific bypass behavior |
| Channel enumeration | None | `UPSTREAM_UNCHANGED` | Driver probes engine IDs/channel counts dynamically |
| C2H/H2C handling | None | `UPSTREAM_UNCHANGED` | Generic scatter-gather byte transport |
| Streaming versus memory mapped | None | `UPSTREAM_UNCHANGED` | Driver retains upstream support; HDMI FPGA uses AXI Stream |
| MSI/MSI-X/legacy interrupts | None | `UPSTREAM_UNCHANGED` | Generic runtime interrupt selection |
| Interrupt vector count | None | `UPSTREAM_UNCHANGED` | No HDMI-specific vector constant introduced |
| Device-node naming | None | `UPSTREAM_UNCHANGED` | `xdma%d_*` dynamic naming retained |
| Maximum transfer size | None | `UPSTREAM_UNCHANGED` | No HDMI frame-sized kernel limit introduced |
| Descriptor handling | None | `UPSTREAM_UNCHANGED` | Generic upstream descriptors retained |
| Polling mode | None | `UPSTREAM_UNCHANGED` | No HDMI-specific poll setting introduced |
| Alignment | None | `UPSTREAM_UNCHANGED` | Generic engine alignment checks retained |
| Engine detection | None | `UPSTREAM_UNCHANGED` | Generic register-based engine discovery retained |
| BDF, slot, root port | None | `UPSTREAM_UNCHANGED` | No fixed topology dependency in module |
| Card/device index | None | `UPSTREAM_UNCHANGED` | Dynamic `xdev->idx` retained |
| ioctl ABI | None | `UPSTREAM_UNCHANGED` | Generic XDMA ioctl ABI retained |
| sysfs attributes | None | `UPSTREAM_UNCHANGED` | Generic PCI/character-device attribution remains |
| Module parameters | None | `UPSTREAM_UNCHANGED` | No HDMI-only parameter added |
| Kbuild flags | Three identifier-only substitutions | `GENERIC_KERNEL_COMPATIBILITY` | Necessary for the exact build; no runtime semantic divergence |

## HDMI FPGA/XDMA configuration consumed by the generic driver

The accepted C5 Tcl source and frozen configuration evidence define:

| Property | HDMI value | Driver dependency |
|---|---|---|
| XDMA IP | `xilinx.com:ip:xdma:4.2` | Generic XDMA register/engine ABI |
| PCIe | Gen2 x1, 5.0 GT/s x1 | Generic PCIe enumeration |
| PCI identity | `10ee:7021`, subsystem `10ee:f0a1` | Exact custom alias; mandatory |
| XDMA interface | `AXI_Stream` | Engine discovered at runtime |
| C2H channels | 1 | Creates C2H channel 0 |
| H2C channels | 1 instantiated; intentionally unused/tied not ready | Node may exist, but HDMI host must not rely on H2C payload use |
| AXI data width | 64 bits | Hardware datapath property, not payload parsing in kernel |
| AXI/user clock | 62.5 MHz | Hardware property |
| Reference clock | 100 MHz | PCIe hardware property |
| BAR0 | 64 KiB external user AXI-Lite | Produces the user BAR interface |
| BAR1 | 64 KiB internal XDMA configuration | Driver engine/config discovery |
| BAR2..BAR5 | Disabled | No additional physical BAR dependency |
| Bypass BAR | Not evidenced/present in frozen BAR contract | No custom bypass requirement |

The published set-property list does not explicitly freeze PCI class,
MSI/MSI-X selection/count, descriptor mode, or user-interrupt count. The
historical module created event nodes 0 through 15, but that observation is not
promoted into an explicit IP-configuration claim.

## Generic transport versus payload awareness

```text
DRIVER_PAYLOAD_BEHAVIOR=GENERIC_TRANSPORT_ONLY
```

The kernel module maps PCI resources, discovers XDMA engines, exposes character
devices, and transfers caller-supplied byte counts. The only HDMI-specific
kernel behavior is whether the PCI function is eligible to probe.

HDMI protocol-v2 framing, UYVY geometry, sequence, header/payload CRC, control
register sequencing, and PNG conversion are implemented by HDMI userspace such
as `demo/r0f_a/host/frame.py`, `xdma_capture.py`, and the C5 finite-session
backend. They are not interpreted by the kernel module.

Accordingly, an AHD userspace parser remains AHD-specific. HDMI userspace is not
a replacement for `AHD_C2H_TRANSPORT_ABI_V1` parsing.

## Multi-device and dynamic-index behavior

```text
MULTI_DEVICE_AND_DYNAMIC_INDEX_SUPPORT=PASS
```

The unchanged upstream driver allocates an `xdev->idx` and names nodes
`xdma%d_user`, `xdma%d_c2h_%d`, `xdma%d_h2c_%d`, and related forms. The accepted
C5 host service discovers BDF and the matching `xdmaN` pair through sysfs; it
does not assume `xdma0`. Historical evidence demonstrates that observed BDFs
changed from `0b:00.0` to `0a:00.0` across captures while attribution remained
correct.

The HDMI-only alias limits eligible PCI identities; it does not hard-code one
BDF or index. This generic indexing capability cannot make an ineligible AHD
PCI ID probe.

## Final customization disposition

```text
HDMI_SPECIFIC_DRIVER_CUSTOMIZATION=INCOMPATIBLE
PCI_ALIAS_10EE_7011=FAIL
CURRENT_AHD_MODALIAS_MATCH=FAIL
AHD_PCI_ID_COMPATIBILITY=FAIL_HDMI_SPECIFIC_MATCH
UNRESOLVED_SEMANTIC_DRIVER_PATCHES=NO
HDMI_DRIVER_REUSE_DECISION=NOT_REUSABLE_PCI_ALIAS_MISMATCH
```

The exact binary is generic at the transport layer but intentionally
HDMI-specific at the PCI admission layer. These facts are not contradictory.
No compatible BAR/channel similarity can override the built module's sole
`7021/f0a1` alias.

## Explicit non-claims

- This source audit is not a fresh `modinfo` or ELF inspection of the absent DUT
  binary.
- It does not establish current signature, dependency, Secure Boot, or lockdown
  readiness.
- It does not establish every unspecified XDMA GUI default as an accepted
  project-state property.
- It does not authorize modifying the PCI table, rebuilding, installing,
  loading, binding, MMIO, or DMA.
- It does not recommend using generic `modprobe xdma` or the installed
  platform-bus module.

