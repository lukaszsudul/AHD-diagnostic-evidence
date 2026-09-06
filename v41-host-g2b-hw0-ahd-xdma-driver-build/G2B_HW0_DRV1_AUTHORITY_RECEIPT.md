# G2B-HW0-DRV1 authority receipt

## Disposition

```text
AUTHORITY_RECEIPT=PASS
PROJECT_STATE_REV_AT_START=8
PROJECT_STATE_REV_AT_END=8
OWNER_BUILD_AUTHORIZATION=GRANTED
AUTHORIZED_UPSTREAM_SOURCE=VERIFIED
PRODUCT_SOURCE_PROTECTION=PASS
DRIVER_WORKTREE_AUTHORITY=PASS
FIRST_BLOCKER=NONE
SSOT_UPDATE_REQUIRED=NO
```

This receipt binds the DRV1 source/build/offline-qualification work to the
governed AHD authorities below. It does not authorize or report a module load,
module installation, endpoint bind, MMIO access, DMA, reboot, power-cycle, or
FPGA programming.

## Project-state authority

| Field | Verified value |
|---|---|
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Required project-state revision | `8` |
| Verified project-state revision | `8` |
| Project-state subtree | `221992c137052935367dea4a7970d73b4f0b6838` |
| Last project-state change | `f92f4d8fcc0dc88d3dc5753c799e1d891846e392` |
| Revision-8 manifest | `18/18` entries matched |
| Revision-8 manifest SHA-256 | `B935E05F75AC1357D29ACB91E08978BD9A6701CD06024F9E6E2C6EB071993EC6` |
| META-8A | `PROMOTED` |
| Exact PRODUCT candidate | Authorized for separate controlled hardware testing |
| G2B-HW qualification | `NOT_PROVEN` |
| Newer project-state revision | None found through the verified evidence tip `b3920c7ce5ef3cb83800c85a29eb8febca357319` |

Revision 8 does not record a superseding driver-build plan. DRV1 therefore
uses revision 8 as its authority while leaving `project-current-state`
unchanged.

## R2 predecessor authority

| Field | Verified value |
|---|---|
| Directory | `v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot` |
| Evidence commit | `9caa9c339966eda999219e4ed686c01654b9a87e` |
| Evidence commit tree | `ca671bd27568d6ec97eb3de3025b3894fa3c0634` |
| Directory subtree | `7846824929a642d765f4f1be31cc4f87493a4758` |
| Manifest result | `128/128` self-excluded entries matched |
| Manifest SHA-256 | `3A75952782C85C4B67F8F742D1E8D278FC8838ABC514CB542F920686E7D7C717` |
| State-record SHA-256 | `DEC0C53D97A2765B8162CAEE99FBEFC7483D03F74B3BF260FB2FE6EC109E1554` |

The accepted R2 facts used by DRV1 are:

- authoritative DUT `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`;
- running kernel `7.0.0-29-generic`, architecture `x86_64`;
- AHD endpoint `10ee:7011`, subsystem `10ee:0007`, at R2 BDF
  `0000:01:00.0`;
- exact modalias
  `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`;
- endpoint unbound with a Gen2 x1 link;
- the platform `xdma` module unloaded and zero `/dev/xdma*` nodes;
- exact PRODUCT candidate retained in volatile SRAM with FPGA `DONE=1`;
- first R2 blocker `SAFE_AHD_XDMA_BIND_UNAVAILABLE`.

DRV1 did not repeat R2's hardware actions. The endpoint is not required to be
present for the offline build.

## HDMI reuse authority

| Field | Verified value |
|---|---|
| AHD reuse-audit directory | `v41-host-g2b-hw0-hdmi-xdma-driver-reuse-audit` |
| AHD reuse-audit commit | `b3920c7ce5ef3cb83800c85a29eb8febca357319` |
| AHD reuse-audit commit tree | `736b078c78685dfe349bbcf218057ff9ec941883` |
| AHD reuse-audit subtree | `aab22e44180fad73ba23ab7c1648d1f81047de10` |
| Reuse-audit manifest | `28/28` self-excluded entries matched |
| Reuse-audit manifest SHA-256 | `A24C1C379DB648CB4B375D659A890050A85631C4E9138C3BC37157FE9F8094D2` |
| Direct binary reuse decision | `NOT_REUSABLE_PCI_ALIAS_MISMATCH` |

The governed HDMI binary was absent at its current DUT path, and its historical
single PCI alias is specific to `10ee:7021 / 10ee:f0a1`. It is therefore not an
AHD binary candidate. Only generic, evidence-backed source/build practices were
reused, as classified in
`G2B_HW0_DRV1_HDMI_PROCESS_REUSE_MATRIX.md`.

The authoritative HDMI build-process evidence is:

- repository `lukaszsudul/HDMI-diagnostic-evidence`;
- evidence commit `ecb760da97a597460c16959a564979f3836dfd24`;
- evidence tree `91e5840925b770d8ac0c305e76def6e1af0563e5`;
- directory
  `demo/r0f_a8_c1/DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361`;
- HDMI driver-control repository `lukaszsudul/FPGA_HDMI`, commit
  `b7ef83efcba95e74c25f67996e8c5686a6fa887c`, tree
  `01d33fea7f9d36e6772342e536990151ffd1ecc3`.

## PRODUCT source protection

Read-only checks before and after driver-source preparation returned the same
protected PRODUCT identity:

| Field | Value |
|---|---|
| Worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| HEAD | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| Tracked state | Clean |
| Index | Clean |

No driver asset was committed to the PRODUCT branch. No RTL, XDC, IP, FPGA
build script, ABI, MMIO map, PRODUCT bitstream, R-track, or HDMI content was
changed.

## Dedicated driver authority

| Field | Value |
|---|---|
| Worktree | `C:\FPGA\V41_G2B_DRV` |
| Branch | `host/v41-g2b-hw0-ahd-xdma-driver` |
| Base | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Driver-source commit | `0a201aab7adb13be079e784c6ed97dfad2ed7764` |
| Driver-source tree | `6f079bf086878ddbce1f1ec82fece3039eae6573` |
| Commit subject | `Add reproducible AHD PCIe XDMA driver candidate build` |
| Remote branch read-back | Exact commit visible |
| Worktree state | Clean |

The base-to-driver commit adds only the seven governed files under
`host/xdma/ahd_pcie/`; the diff is 816 insertions and has no protected FPGA
source delta.

## Upstream source authority

| Field | Verified value |
|---|---|
| Repository | `https://github.com/Xilinx/dma_ip_drivers.git` |
| Commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` |
| Commit tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` |
| Verification | Exact official GitHub commit and tree matched |
| Patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` |

Both builds began from independent clean detached checkouts of this exact
upstream identity. Neither used repository HEAD, the installed platform-bus
driver, the missing HDMI binary, or an unverified local source copy.

## Authorization boundary observed

Owner authorization covered authenticated read-only DUT inventory, the
dedicated driver worktree, official-source retrieval, the minimal patch, two
isolated builds, static inspection, sealing, and evidence preparation.

The following remained prohibited and did not occur in DRV1: package
installation, module installation, `depmod`, module load/unload, PCI
bind/unbind, `new_id`, `driver_override`, MMIO, DMA, live node creation, reset,
rescan, JTAG, FPGA programming, reboot, power-cycle, PRODUCT modification, and
SSOT modification.
