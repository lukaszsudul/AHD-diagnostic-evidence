# G2B-HW0-DRV1 HDMI process reuse matrix

## Scope

This matrix reuses only generic, evidence-backed process elements from the
authoritative HDMI driver build. It does not reuse the HDMI binary, HDMI PCI
identity, HDMI PCI patch, HDMI userspace interpretation, or HDMI SSOT decision.

The authoritative HDMI process evidence is pinned to:

- `lukaszsudul/HDMI-diagnostic-evidence` commit
  `ecb760da97a597460c16959a564979f3836dfd24`, tree
  `91e5840925b770d8ac0c305e76def6e1af0563e5`;
- directory
  `demo/r0f_a8_c1/DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361`;
- `lukaszsudul/FPGA_HDMI` driver-control commit
  `b7ef83efcba95e74c25f67996e8c5686a6fa887c`, tree
  `01d33fea7f9d36e6772342e536990151ffd1ecc3`;
- AHD reuse decision at commit
  `b3920c7ce5ef3cb83800c85a29eb8febca357319`:
  `NOT_REUSABLE_PCI_ALIAS_MISMATCH`.

## Matrix

| Item | Reusable | Reason | AHD treatment | Evidence |
|---|---|---|---|---|
| Official upstream source identity | YES | The HDMI build is bound to the accepted official Xilinx repository, exact commit, and exact tree. | Use the same official repository and exact `b8466090b4e812e191da9e9305ffb11cb7ace768` / `f9286c5d1bdae57285570ac5c23244d54076b99f`; independently verify both before each clean build. | HDMI provenance and prepared-source contract at the pinned HDMI build evidence. |
| Detached, clean source preparation | YES | It prevents repository-tip drift and makes the pre-patch authority inspectable. | Create independent detached Build A and Build B checkouts; reject any upstream commit/tree mismatch. | HDMI preparation scripts and 417-file governed prepared-source inventory. |
| Ordinal path/size/SHA source manifest | YES | The HDMI process binds the complete prepared source, rather than only naming a repository. | Hash the clean/patched inputs for each independent build and require identical input-manifest SHA-256 `7D28F66A4253A213E75B73036ED38D8E2F8974DEDDA4378CB3D028B5C2956019`. | HDMI `SOURCE_FILES_MANIFEST_ENTRY_COUNT=417`, manifest SHA-256 `144B73F8B30529E7A420A21E574BE6E9F3083C7FE4ACEE8E43661059349AC19A`, and prepared-manifest SHA-256 `67FF79F42BCD55E2647C0AFA9CAC1C5B47664D4AD8A9BA51C943C5761DA7C394`. |
| `EXTRA_CFLAGS` to `ccflags-y` Kbuild adjustment | YES | The three substitutions are a generic Kbuild compatibility change; option values and conditional behavior are unchanged. | Apply the same three active assignment substitutions inside the single AHD patch and list them separately from identity changes. | HDMI generic patch SHA-256 `AF405EAB420049CDB4E0AD356E9945A064AF082A1E4EC0D2DED901534572C736`; reuse-audit classification `GENERIC_KERNEL_COMPATIBILITY`. |
| Upstream `all` build target | YES | It compiles the module without installation or host-module mutation. | Invoke only `all` against `/lib/modules/7.0.0-29-generic/build`; never invoke `install`. | HDMI build contract records target `all`, `DEBUG=0`, BAR/XVC overrides empty, and no install/depmod/load. |
| Exact running-kernel headers | YES | An out-of-tree module must be built against the governed running-kernel build interface. | Verify build symlink, config, `Module.symvers`, kernel release, and compiler before both builds. | HDMI build kernel `7.0.0-29-generic`, headers package `7.0.0-29.29`, x86_64, GCC `15.2.0-16ubuntu1`. |
| Static `modinfo`, vermagic, alias, and dependency gates | YES | These checks qualify identity and offline compatibility without loading the module. | Require exact internal name, full vermagic, only the exact AHD alias, empty out-of-tree dependencies, and offline ELF/modversion checks. | HDMI build provenance records exact historical modinfo/vermagic/alias; DRV1 verification extends the same method. |
| Warning disclosure | YES | The HDMI build disclosed compiler-name and missing-`vmlinux`/BTF limitations rather than converting them into runtime claims. | Inventory every Build A/B warning; accept only after exact-version, modpost, static, and reproducibility gates pass. | HDMI provenance warning section and DRV1 Build A/B logs. |
| Generic XDMA transport behavior | YES | The governed HDMI source delta did not alter descriptor, interrupt, BAR, engine, channel, character-device, timeout, alignment, or payload semantics. | Retain upstream transport files unchanged; restrict the AHD delta to exact PCI match, unique name/metadata, and the proven Kbuild compatibility adjustment. | HDMI patch/customization audit and AHD source-delta audit. |
| Character-device node-creation expectations | YES | The standard upstream class and node templates are transport behavior, not HDMI payload semantics. | Preserve `XDMA_NODE_NAME="xdma"`; document `/dev/xdmaN_user`, `/dev/xdmaN_c2h_0`, and optional standard interfaces as future expected nodes only. | Upstream `xdma_cdev.h`, `xdma_cdev.c`; HDMI prior-use evidence is historical context, not an AHD live-node claim. |
| Dynamic multi-device indexing | YES | Upstream assigns index 0 when the active-device list is empty; otherwise it assigns the last active list entry's index plus one, rather than promising `xdma0`. | Require future R3 to discover `N` dynamically and prove each node's sysfs ancestry maps to the exact AHD BDF. | Upstream `libxdma.c` index allocator and authoritative HDMI A9/A10 node-to-BDF evidence. |
| BDF-to-node proof method | YES | The sysfs ancestry check is bus/device correlation and is independent of video payload interpretation. | Put the method in the R3 plan only; do not execute a probe in DRV1. | HDMI A9/A10 exact-binary node and BDF evidence cited by the reuse audit. |
| HDMI PCI table patch | NO | It is exactly restricted to device `7021`, subsystem `f0a1`, and cannot match AHD `7011/0007`. | Replace the upstream broad table with a new AHD-only `PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007)` entry. | HDMI PCI patch SHA-256 `5CA5B73463EDE2FF74BD1C4117891F622E80F5DDAE133236FB03426CD292C51B`; alias `pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*`. |
| HDMI binary artifact | NO | The current governed file was not found, and its hash-linked alias is deterministically incompatible even historically. | Build a new AHD candidate; do not copy, reconstruct, or substitute the HDMI binary. | Historical SHA-256 `B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2`, size `3295008`; reuse decision `NOT_REUSABLE_PCI_ALIAS_MISMATCH`. |
| HDMI internal module name `xdma` | NO | It would collide by name with the installed platform-bus module. | Rename the candidate filename and internal name to `xdma_ahd_pcie`; preserve user-visible XDMA node prefix separately. | HDMI historical module name `xdma`; installed platform module name `xdma`; DRV1 unique-name policy. |
| HDMI subsystem/device identity | NO | It names a different endpoint policy. | Use only vendor/device `10ee:7011` and subsystem `10ee:0007`. | HDMI `10ee:7021 / 10ee:f0a1`; AHD R2 `10ee:7011 / 10ee:0007`. |
| HDMI userspace frame/payload interpretation | NO | Payload semantics are project-specific and outside the generic kernel transport. | Keep the kernel `GENERIC_PCIE_XDMA_TRANSPORT_ONLY`; leave AHD record parsing, frames, pixels, and NVP telemetry to AHD userspace. | HDMI reuse audit classifies the kernel `GENERIC_TRANSPORT_ONLY`; AHD DRV1 transport boundary. |
| HDMI SSOT decisions | NO | HDMI governance is not AHD project authority. | Read only for provenance; do not modify or import HDMI SSOT decisions. | HDMI SSOT revision 1 and AHD project-state revision 8 remain separate. |
| One-build qualification cardinality | PARTIAL | The HDMI process proves a successful exact build, but DRV1 requires stronger two-build byte reproducibility. | Reuse the build recipe independently twice and require identical module hashes; do not treat one successful build as sufficient. | HDMI `BUILD_ATTEMPT_COUNT=1`; DRV1 Build A and Build B both SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`. |
| HDMI live load/bind/DMA result | NO | It proves historical HDMI operation only and cannot establish AHD runtime behavior. | Use as process context for a separately authorized R3 plan; make no load, bind, MMIO, or DMA claim in DRV1. | HDMI A9/A10 evidence cited by the reuse audit; DRV1 is static/offline only. |

## Result

```text
HDMI_REUSE_EVIDENCE=VERIFIED
HDMI_BINARY_REUSED=NO
HDMI_PCI_IDENTITY_REUSED=NO
GENERIC_SOURCE_PROCESS_REUSED=YES
GENERIC_TRANSPORT_PROCESS_REUSED=YES
AHD_RUNTIME_RESULT_DERIVED_FROM_HDMI=NO
```
