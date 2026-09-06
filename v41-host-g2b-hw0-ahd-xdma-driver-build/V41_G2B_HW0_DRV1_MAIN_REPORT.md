# AHD v41 G2B-HW0-DRV1 AHD-Compatible PCIe XDMA Driver Build and Offline Qualification

## Result

| Gate | Result |
|---|---|
| Engineering gate | `PASS` |
| Evidence publication | `PASS` |
| Candidate classification | `OFFLINE_QUALIFIED_AHD_PCIE_XDMA_DRIVER_CANDIDATE` |
| First engineering blocker | `NONE` |
| Runtime qualification | `NOT_PERFORMED` |

Engineering `PASS` is limited to governed source authority, two clean builds,
byte reproducibility, exact module identity, exact PCI alias policy, static ELF
and module inspection, and offline kernel compatibility. The qualification
payload was committed and pushed without force at
`879d578d8759b6afca8961be4fe55344e02264ca`; a fresh commit-pinned clone
matched all 29 files byte-for-byte, and its 28-entry self-excluded manifest
verified `PASS`.

This result does not claim that the module loads, probes, binds, creates device
nodes, maps a BAR, completes MMIO, or transfers DMA. Those are separately
authorized G2B-HW0-PRODUCT-R3 claims.

## Governance and predecessor authority

| Authority | Verified result |
|---|---|
| Project-state revision at start | `8` |
| Project-state revision at end | `8` |
| META-8A | `PROMOTED` |
| Exact PRODUCT candidate | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION` |
| G2B-HW qualification | `NOT_PROVEN` |
| Newer project-state revision | `NONE OBSERVED` |
| R2 evidence | `VERIFIED`, commit `9caa9c339966eda999219e4ed686c01654b9a87e` |
| HDMI reuse evidence | `VERIFIED`, commit `b3920c7ce5ef3cb83800c85a29eb8febca357319` |
| Owner build authorization | `GRANTED` |

R2 established the retained PRODUCT candidate, the exact AHD endpoint and
PCIe Gen2 x1 link, and the blocker `SAFE_AHD_XDMA_BIND_UNAVAILABLE`. The HDMI
reuse audit established `NOT_REUSABLE_PCI_ALIAS_MISMATCH`: its historical
binary is absent and its exact `10ee:7021 / 10ee:f0a1` policy cannot match AHD.
Only its generic upstream/process evidence was reused.

The SSOT was not modified. `SSOT_UPDATE_REQUIRED = NO`: R3 must cite the final
DRV1 evidence commit and exact module SHA-256 rather than promote a new FPGA or
transport fact.

## Protected PRODUCT source and driver worktree

The authoritative PRODUCT source remained tracked-clean and index-clean before
and after driver work:

| Field | Value |
|---|---|
| PRODUCT worktree | `C:\FPGA\V41_G2B` |
| PRODUCT branch | `integration/v41-g2b-onech-c2h` |
| PRODUCT commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| PRODUCT tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| PRODUCT modified | `NO` |
| Driver worktree | `C:\FPGA\V41_G2B_DRV` |
| Driver branch | `host/v41-g2b-hw0-ahd-xdma-driver` |
| Driver base | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Driver source commit | `0a201aab7adb13be079e784c6ed97dfad2ed7764` |
| Driver source tree | `6f079bf086878ddbce1f1ec82fece3039eae6573` |
| Remote driver branch | `VISIBLE AT EXACT COMMIT` |

Only `host/xdma/ahd_pcie` driver recipe and documentation assets were added.
No RTL, active XDC, IP, FPGA build scripts, ABI, MMIO, PRODUCT bitstream,
R-track, or HDMI content changed.

## Upstream and patch authority

| Field | Value |
|---|---|
| Repository | `https://github.com/Xilinx/dma_ip_drivers.git` |
| Upstream commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` |
| Upstream tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` |
| Patch | `0001-ahd-exact-pci-match.patch` |
| Patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` |
| Source-input manifest SHA-256 | `7D28F66A4253A213E75B73036ED38D8E2F8974DEDDA4378CB3D028B5C2956019` |

The patch has three bounded effects:

1. it replaces the broad 57-entry upstream PCI table with one
   `PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007)` entry;
2. it renames the Kbuild target and PCI-driver/module label to
   `xdma_ahd_pcie` and distinguishes the description;
3. it applies the previously evidenced kernel-7 Kbuild compatibility
   conversion from `EXTRA_CFLAGS` to behavior-equivalent `ccflags-y`.

No descriptor, interrupt, C2H/H2C engine, BAR, character-device transfer,
channel-indexing, alignment, timeout, or payload behavior changed. The module
does not interpret AHD record headers, pixels, frames, ABI contents, or NVP
telemetry. `GENERIC_TRANSPORT_BEHAVIOR_UNCHANGED = PASS` and
`DRIVER_PAYLOAD_BEHAVIOR = GENERIC_TRANSPORT_ONLY`.

## Fresh authoritative DUT inventory

The governed authenticated connection to
`VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` passed with the pinned host key.
The credential wrapper used an ACL-restricted temporary password file, did not
place the password in a process argument, deleted the temporary file, and left
zero remnants.

| Field | Fresh value |
|---|---|
| Hostname | `VCDE-DUT-1` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Running kernel | `7.0.0-29-generic` |
| Architecture | `x86_64` |
| OS | `Ubuntu 26.04 LTS` |
| GCC/CC | `gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0` |
| Make | `GNU Make 4.4.1` |
| Git | `2.53.0` |
| Binutils | `2.46` |
| kmod/modinfo | `34.2` |
| Kernel build link | `/lib/modules/7.0.0-29-generic/build -> /usr/src/linux-headers-7.0.0-29-generic` |
| Exact headers and modpost | `PASS` |
| Module.symvers SHA-256 | `88EC24BC876CCE4C2D7947424F964E5B2A76011801288209BD96539647BEE4BA` |
| Kernel config SHA-256 | `D81A84B5BF2B94D5F08A5A87B6D052CD25E96DF5324BAB246790A679349A987B` |
| Required config | `CONFIG_MODULES=y; CONFIG_PCI=y; CONFIG_MODVERSIONS=y` |
| Secure Boot | `disabled` |
| Packages installed | `NO` |

No competing AHD/HDMI hardware process, driver-build process, or governed task
lock was observed. Historical driver workspaces existed but were inactive and
were not used as unverified source authority.

The fresh informational PCI observation remained:

- BDF `0000:01:00.0`;
- vendor/device `10ee:7011`;
- subsystem `10ee:0007`;
- modalias `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`;
- current/max link `5.0 GT/s`, width `x1`;
- driver `NONE` and `driver_override = NONE`.

The endpoint was not required for compilation and was not touched.

## Reproducible builds

Two absent, independent build roots were populated from independent clean
clones and the exact detached upstream commit:

| Build | Root | Result | Module SHA-256 |
|---|---|---|---|
| A | `/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A` | `PASS` | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |
| B | `/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_B` | `PASS` | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |

Both builds used:

```text
SOURCE_DATE_EPOCH=1787236279
KBUILD_BUILD_TIMESTAMP=Thu Aug 20 14:31:19 UTC 2026
KBUILD_BUILD_USER=ahd-drv1
KBUILD_BUILD_HOST=vcde-dut-1
KBUILD_BUILD_VERSION=1
```

Both `modpost` runs passed. Module bytes, source diffs, and source-input
manifests compared identical; neither binary contained its unique build path.
`BYTE_IDENTICAL = YES`, two clean builds were sufficient, and no third build
was needed.

### Warning disposition

Both builds emitted the same nonblocking diagnostics:

- The upstream Makefile printed `XVC_FLAGS: .` three times per build; the
  governed XVC flags value was intentionally empty.
- Kbuild reported a compiler difference because the executable labels were
  `x86_64-linux-gnu-gcc` and `x86_64-linux-gnu-gcc-15`; both resolved to exact
  version `Ubuntu 15.2.0-16ubuntu1 15.2.0`.
- Kbuild reported pahole version `0` versus kernel build version `131`, then
  skipped BTF because `vmlinux` was unavailable in the headers package.

No package installation was authorized or attempted. These warnings did not
produce a compile or modpost error, did not alter A/B reproducibility, and did
not affect vermagic or modversion inspection. They are retained verbatim in
both build logs. `KERNEL_OFFLINE_COMPATIBILITY = PASS_WITH_NONBLOCKING_WARNING`.

## Static candidate identity

| Field | Qualified value |
|---|---|
| Filename | `xdma_ahd_pcie.ko` |
| Internal module name | `xdma_ahd_pcie` |
| SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |
| Size | `3296104` bytes |
| ELF | `ELF64`, little-endian, relocatable, x86-64, not stripped |
| Vermagic | `7.0.0-29-generic SMP preempt mod_unload modversions ` |
| srcversion | `EE8B149D1883AE8C6B1EE31` |
| GNU build ID | `1471c3a284ec1cb26115fe9e9bd59890a034f83e` |
| License | `Dual BSD/GPL` |
| Description | `Xilinx XDMA Reference Driver (AHD exact PCI match)` |
| Dependencies | none declared |
| Signature | unsigned |
| Signature disposition | `UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST` |
| Offline verification | `PASS` |

The exact generated alias set contains one entry:

`pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*`

| Offline alias test | Result |
|---|---|
| Exact AHD modalias | `MATCH / PASS` |
| Same vendor/device, alternate subsystem | `NO_MATCH / PASS` |
| Synthetic HDMI-ID class variant | `NO_MATCH / PASS` |
| Generic Xilinx PCI device | `NO_MATCH / PASS` |
| `platform:xdma` | `NO_MATCH / PASS` |
| Installed Xilinx endpoint `0000:0b:00.0` | `NO_MATCH / PASS` |
| Unintended broad PCI aliases | `0` |

The standard XDMA character-device prefix remains `xdma`. An authorized future
probe is expected, not proven, to allocate a dynamic `N` and expose at least
`/dev/xdmaN_user` and `/dev/xdmaN_c2h_0`, with optional control/event/H2C or
bypass nodes according to discovered engines. Module renaming does not rename
that userspace node ABI.

## Installed platform module collision audit

The installed in-tree platform module remained unchanged:

| Field | Value |
|---|---|
| Path | `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` |
| SHA-256 | `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490` |
| Internal name | `xdma` |
| Alias | `platform:xdma` |
| Loaded | `NO` |
| Candidate internal name | `xdma_ahd_pcie` |
| Module-name collision | `NO` |

Both transports may still use the standard XDMA class/node namespace.
Coexistence was not tested and is not claimed. R3 must keep the platform
`xdma` module unloaded unless coexistence is separately proven.

## Artifact sealing targets

The exact DRV1 timestamp and candidate are pinned to these sealing targets:

- remote: `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`;
- controller: `C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko`.

Both targets were created and verified. Each module is `3296104` bytes with
SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`.
The remote manifest verified all 21 payload files; the remote directory mode is
`0555`, its 22 files are non-writable, and the controller copy is marked
read-only. `SEALED_COPY_HASH_AGREEMENT = PASS`. The public evidence package
publishes module hash, size, identity, provenance, and sealed paths, but not the
`.ko` binary.

## Final no-touch accounting and nonclaims

| Operation or state | DRV1 result |
|---|---|
| Module installed in `/lib/modules` | `NO` |
| `depmod` | `NOT_RUN` |
| Candidate module loaded | `NO` |
| Any module unloaded | `NO` |
| Endpoint bound/unbound | `NO` |
| `new_id` or `driver_override` write | `NO` |
| XDMA nodes created by live probe | `NO` |
| MMIO access | `NO` |
| DMA execution | `NO` |
| Reboot or power-cycle | `NO` |
| JTAG or FPGA programming | `NO` |
| PRODUCT candidate modified | `NO` |
| AHD SSOT modified | `NO` |
| HDMI SSOT modified | `NO` |
| OS/kernel/package change | `NO` |

The final authenticated read-only DUT audit at `2026-09-06T12:43:29Z` found
boot ID `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` unchanged, kernel
`7.0.0-29-generic`, zero loaded `xdma`/`xdma_ahd_pcie` modules, zero installed
candidate copies under the running kernel, zero `/dev/xdma*` character nodes,
and the AHD endpoint still unbound at `0000:01:00.0`, Gen2 x1. The preserved
platform module retained SHA-256
`523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490`.

DRV1 proves an offline-qualified candidate only. It does not prove runtime
module acceptance, automatic probe, node creation, node-to-BDF mapping, BAR
access, MMIO identity, record correctness, DMA correctness, throughput, or
hardware qualification.

## Publication closure and next step

| Field | Current report value |
|---|---|
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Evidence directory | `v41-host-g2b-hw0-ahd-xdma-driver-build` |
| Qualification payload commit | `879d578d8759b6afca8961be4fe55344e02264ca` |
| Remote read-back | `PASS` |
| Driver ready for R3 | `YES_WITH_OWNER_AUTHORIZATION` |

Recommended next step after evidence publication is
`G2B-HW0-PRODUCT-R3`: exact sealed driver load, automatic exact-alias PCI
probe, node-to-BDF proof, separately authorized runtime MMIO identity, and one
bounded AHD C2H record capture.

`FINAL_EXECUTION_POINT = HARD STOP AFTER G2B-HW0-DRV1 OFFLINE DRIVER QUALIFICATION`
