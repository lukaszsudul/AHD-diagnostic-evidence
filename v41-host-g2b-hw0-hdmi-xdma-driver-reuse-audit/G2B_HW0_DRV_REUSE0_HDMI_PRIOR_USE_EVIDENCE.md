# G2B-HW0-DRV-REUSE0 — prior use of the exact HDMI XDMA binary

## Overall historical classification

```text
PREVIOUS_EXACT_HDMI_MODULE_BUILD=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_MODULE_LOAD=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_PCI_PROBE=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_ENDPOINT_BIND=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_NODE_CREATION=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_NODE_TO_BDF_MAPPING=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_MMIO=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_DMA=PASS_EXACT_BINARY
PREVIOUS_EXACT_HDMI_UNLOAD_ROLLBACK=NOT_PROVEN
```

Every `PASS_EXACT_BINARY` above is tied to module SHA-256
`B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2`,
size `3295008`, kernel `7.0.0-29-generic`, and the sole HDMI alias. It is not
based merely on the name `xdma.ko` or on a same-source different binary.

## A8-C1 — exact build, stopped before load

Evidence commit `ecb760da97a597460c16959a564979f3836dfd24`, tree
`91e5840925b770d8ac0c305e76def6e1af0563e5`, preserves capture
`DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361`.

The one successful build produced and statically gated:

```text
MODULE_NAME=xdma
MODULE_SIZE=3295008
MODULE_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
MODULE_VERMAGIC=7.0.0-29-generic SMP preempt mod_unload modversions <TRAILING_SPACE>
MODULE_ALIAS=pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*
AHD_10EE_7011_ALIAS_PRESENT=NO
```

This stage explicitly stopped before `insmod`, binding, node access, BAR, or DMA.

## A9 — one exact load and HDMI-only binding

Evidence commit `4902c5d04253c76584196e97115e6b4186dc3e0b`, tree
`a17e2bf0a9d0bfa6406500addca01ccfdb4c9cc6`, records capture
`DEMO_R0F_A9_20260829T142455Z_BOARD0005_323A6669`.

Before load, the locally retained and remotely staged module were independently
measured:

```text
LOCAL_MODULE_BYTES=3295008
REMOTE_MODULE_BYTES=3295008
LOCAL_MODULE_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
REMOTE_MODULE_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
INSMOD_OPERATION_COUNT=1
SECOND_INSMOD_ATTEMPT=NO
INSMOD_RESULT=PASS
```

The pre/post PCI state was:

| Endpoint | PRE | POST |
|---|---|---|
| HDMI | `0000:0b:00.0`, `10ee:7021`, subsystem `10ee:f0a1`, unbound, 5.0 GT/s x1 | Bound to `xdma`, same BDF/identity/link |
| AHD | `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`, unbound, 2.5 GT/s x1 | Unchanged and unbound |

The complete `xdma` bound-BDF set was exactly `{0000:0b:00.0}`. The driver
created 21 names: `xdma0_c2h_0`, `xdma0_control`, event nodes 0 through 15,
`xdma0_h2c_0`, `xdma0_user`, and `xdma0_xvc`. No node was opened and no MMIO or
DMA occurred in A9.

## A10 — exact node attribution, BAR, and one DMA frame

The historical evidence branch head
`d27ab44e3a9dc6fb721e9a1aaa69133fcd35daa6`, tree
`775c2e7ecf46ba17282ea9955564c54271165780`, preserves capture
`DEMO_R0F_A10_20260829T144531Z_BOARD0005_4ACB1EBC`.

The already loaded A8-C1 binary retained the same size, SHA-256, vermagic, and
sole alias. `INSMOD_OPERATION_COUNT_THIS_CAPTURE=0`; there was no second load.

Before access, sysfs attribution, `/sys/dev/char`, and the PCI parent agreed:

| Node | Type/mode | Major:minor | Attributed BDF |
|---|---|---|---|
| `/dev/xdma0_user` | character, `0600 root:root` | `511:0` | `0000:0b:00.0` |
| `/dev/xdma0_c2h_0` | character, `0600 root:root` | `511:36` | `0000:0b:00.0` |

The capture then demonstrated one exact C2H transfer:

```text
WIRE_BYTES=4147280
HEADER_BYTES=64
PAYLOAD_BYTES=4147200
TRAILER_BYTES=16
PAYLOAD_FORMAT=1920x1080 UYVY
HEADER_CRC=PASS
PAYLOAD_CRC=PASS
PAYLOAD_CRC32=0xF808A7BE
EVERY_PIXEL_PATTERN_CHECK=PASS
```

The public PNG was generated only from the bytes returned by that DMA transfer.
HDMI remained bound to `xdma`; AHD remained unbound. No unload or unbind was
performed.

## Current-SSOT accepted board-0006 evidence

The current SSOT accepts E-0006 at evidence commit
`3143b8775be671381ca19f5feae042b4daa9152d`, tree
`411ad90f43a17ad25445439acf476124546bea95`, directory
`review/ssot_bootstrap_20260904`.

`BOARD0006_FLASH_B1_B2_RESULT.json` records:

```text
HDMI_BDF=0000:0a:00.0
HDMI_PARENT_ROOT_PORT=0000:00:02.2
HDMI_LINK=5.0 GT/s x1
XDMA_BOUND_TO_HDMI_ONLY=YES
INSMOD_OPERATION_COUNT=1
HDMI_XDMA_USER=/dev/xdma0_user
HDMI_XDMA_C2H_0=/dev/xdma0_c2h_0
XDMA_MODULE_SIZE=3295008
XDMA_MODULE_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
XDMA_EXACT_ALIAS=pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*
AHD_10EE_7011_ALIAS_PRESENT=NO
KERNEL_RELEASE=7.0.0-29-generic
B1_FRAMES_VALID=1
B2_FRAMES_VALID=100
```

`BOARD0006_EXTERNAL_LIVE100_RESULT.json` records the same HDMI binding and
sysfs-correlated user/C2H pair for another 100 valid frames with
`new_insmod_count=0`. BDF `0000:0a:00.0` differs from the earlier A9/A10
observation, which reinforces the SSOT rule that BDF and `xdmaN` are dynamic,
not product identities.

The SSOT summarizes 201 validated board-0006 frames across three finite
sessions. This is accepted finite HDMI evidence, not a continuous 1080p60
qualification.

## Exact-binary linkage assessment

The strongest chain is:

1. exact source/patch/manifests produced one B08C... binary on the exact kernel;
2. A9 independently matched local and remote bytes before its one load;
3. A9 recorded the resulting HDMI-only binding and node set;
4. A10 explicitly retained B08C... and used the sysfs-attributed user/C2H nodes
   for one exact DMA frame;
5. E-0006 later recorded B08C..., the sole alias, one load, HDMI-only binding,
   nodes, and 201 accepted finite frames on the same DUT kernel.

This is sufficient for `PASS_EXACT_BINARY`, not merely
`PASS_SAME_SOURCE_DIFFERENT_BINARY`.

## Rollback and current-state boundary

The reviewed records explicitly state `MODULE_UNLOAD=NO` and
`DRIVER_UNBIND=NO`. They do not demonstrate an exact controlled unload/rollback,
so rollback is `NOT_PROVEN`.

The governed current DUT path no longer contains the module. That current
absence is not evidence of a controlled historical unload, and it does not
erase the historical exact-binary proof.

## Explicit non-claims

- Historical load/bind/DMA proof is not a current module-presence claim.
- It is not authorization to repeat `insmod`, binding, MMIO, or DMA.
- The observed `xdma0` index is not guaranteed for a later endpoint.
- The A9/A10 `0b:00.0` and E-0006 `0a:00.0` BDFs are observations, not constants.
- Finite successful frames do not prove continuous 1080p60 operation.
- No exact unload/rollback qualification is claimed.

