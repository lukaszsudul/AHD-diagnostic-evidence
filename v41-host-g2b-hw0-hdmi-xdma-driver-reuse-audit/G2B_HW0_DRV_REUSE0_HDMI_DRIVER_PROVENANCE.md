# G2B-HW0-DRV-REUSE0 — HDMI XDMA driver provenance

## Provenance disposition

```text
HISTORICAL_BINARY_PROVENANCE=VERIFIED
CURRENT_DUT_BINARY_PROVENANCE=NOT_CURRENTLY_REVERIFIABLE_ARTIFACT_ABSENT
SOURCE_TO_BUILD_IDENTITY_AMBIGUOUS=NO
```

The exact HDMI binary had complete, hash-bound source and build provenance when
it was produced and used. The authoritative current DUT path no longer contains
the file, so this audit cannot independently rehash or statically inspect those
same bytes now. The two statements are intentionally separate.

## Upstream source identity

```text
UPSTREAM_REPOSITORY=Xilinx/dma_ip_drivers
UPSTREAM_SANITIZED_REMOTE=https://github.com/Xilinx/dma_ip_drivers.git
UPSTREAM_COMMIT=b8466090b4e812e191da9e9305ffb11cb7ace768
UPSTREAM_TREE=f9286c5d1bdae57285570ac5c23244d54076b99f
UPSTREAM_TREE_FILE_COUNT=417
UPSTREAM_STATUS_AT_PREPARATION=CLEAN_NO_UNTRACKED
```

GitHub commit/tree metadata was independently read for the exact upstream
identity. The upstream module identifies itself as `Xilinx XDMA Reference
Driver`, internal name `xdma`, source version `2025.2.0`, and license
`Dual BSD/GPL`.

## HDMI-controlled source identity

The exact driver-control surface was committed in the HDMI source repository:

```text
HDMI_DRIVER_CONTROL_REPOSITORY=lukaszsudul/FPGA_HDMI
HDMI_DRIVER_CONTROL_BRANCH=codex/demo-r0f-a8-c1-kbuild-compat-20260829
HDMI_DRIVER_CONTROL_COMMIT=b7ef83efcba95e74c25f67996e8c5686a6fa887c
HDMI_DRIVER_CONTROL_TREE=01d33fea7f9d36e6772342e536990151ffd1ecc3
```

The accepted C5 commit
`6fd13fe7994e454065448303850b8eb9fd140603`, tree
`cab9a2d15a81f7687cdbee1c8e700744f14e8b64`, is two commits ahead. The following
eight paths have identical Git blob IDs at the driver-control and C5 commits:

- `demo/r0f_a/driver/README.md`;
- `demo/r0f_a/driver/Test-R0FADriverContract.ps1`;
- `demo/r0f_a/driver/build_restricted_xdma_module.sh`;
- `demo/r0f_a/driver/prepare_restricted_xdma_source.sh`;
- `demo/r0f_a/driver/restricted_xdma_contract.json`;
- `demo/r0f_a/driver/verify_xdma_binding_gate.sh`;
- `demo/r0f_a/driver/xdma-kbuild-ccflags-y.patch`;
- `demo/r0f_a/driver/xdma-pci-id-10ee-7021-only.patch`.

## Prepared-source contract

The prepared source is the exact upstream tree plus exactly two authorized
deltas:

| Path | Upstream/preimage | Patch SHA-256 | Postimage SHA-256 | Classification |
|---|---|---|---|---|
| `XDMA/linux-kernel/xdma/xdma_mod.c` | LF `1AEE454168457659AEBFF0B1FCB5F9390C7033781D06A66953516C96307041A0`; CRLF `C9E759CF77AAE62B3DBBC6C14B9382CC8E49DD87BC58EEE936A073DEC6E608B8` | `5CA5B73463EDE2FF74BD1C4117891F622E80F5DDAE133236FB03426CD292C51B` | LF `3EFFCA6A4328AAE7A2597A35B147B396C1630313481510A893AB5980FC885EE3` | HDMI-specific PCI match restriction |
| `XDMA/linux-kernel/xdma/Makefile` | LF `AEC0196E6DFF7DC9D9A2F5733EF417914A9E8E5FA38B7EFCD05BE6B7BE7EB89F`; CRLF `B316AC164733183D6317C82BA015D9C2664E4360BF14D5963A5ED271486F1A01` | `AF405EAB420049CDB4E0AD356E9945A064AF082A1E4EC0D2DED901534572C736` | LF `E81FABE9B5C1FA0B3A03E1D7A3DE7AEA8CC90D03EF1FA7612A8B3AB92317F845` | Generic kernel/Kbuild compatibility |

The exact aggregate identities are:

```text
AUTHORIZED_DELTA_PATH_COUNT=2
SOURCE_FILES_MANIFEST_ENTRY_COUNT=417
SOURCE_FILES_MANIFEST_SHA256=144B73F8B30529E7A420A21E574BE6E9F3083C7FE4ACEE8E43661059349AC19A
PREPARED_MANIFEST_SHA256=67FF79F42BCD55E2647C0AFA9CAC1C5B47664D4AD8A9BA51C943C5761DA7C394
```

No prepared full driver tree was represented as a new Git commit. Instead, the
exact upstream commit/tree, two patches, postimages, and 417-entry manifest bind
the derivative source. This is deliberate manifest-bound provenance, not an
assertion that the modified upstream checkout itself was committed.

## Build provenance

The successful restricted build is recorded by:

```text
BUILD_CAPTURE_ID=DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361
BUILD_EVIDENCE_REPOSITORY=lukaszsudul/HDMI-diagnostic-evidence
BUILD_EVIDENCE_BRANCH=codex/demo-r0f-a8-c1-kbuild-compat-20260829
BUILD_EVIDENCE_COMMIT=ecb760da97a597460c16959a564979f3836dfd24
BUILD_EVIDENCE_TREE=91e5840925b770d8ac0c305e76def6e1af0563e5
BUILD_EVIDENCE_DIRECTORY=demo/r0f_a8_c1/DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361
BUILD_HOST=VCDE-DUT-1
BUILD_KERNEL=7.0.0-29-generic
BUILD_ARCH=x86_64
HEADERS_PACKAGE_VERSION=7.0.0-29.29
COMPILER=GCC 15.2.0-16ubuntu1
BUILD_ATTEMPT_COUNT=1
```

The committed evidence reports that the compiler executable name differed from
the kernel build record, while both resolved to GCC `15.2.0-16ubuntu1`. BTF
generation was skipped because `vmlinux` was unavailable. Both conditions were
disclosed; neither prevented module linking or the exact `modinfo` gates.

The build used target `all`, not `install`. Its frozen Make knobs were:

```text
DEBUG=0
config_bar_num=EMPTY
xvc_bar_num=EMPTY
xvc_bar_offset=EMPTY
XVC_FLAGS=EMPTY
BUILDSYSTEM_DIR=EXACT_VERIFIED_HEADERS_ROOT
```

No `make install`, package installation, DKMS, `depmod`, `modprobe`, persistent
autoload, module load, binding, MMIO, or DMA occurred in the build capture.

## Built artifact identity

```text
MODULE_BUILD_RELATIVE_PATH=XDMA/linux-kernel/xdma/xdma.ko
MODULE_NAME=xdma
MODULE_SOURCE_DEFINED_VERSION=2025.2.0
MODULE_BYTES=3295008
MODULE_SHA256=B08C6E5CD296DDBD68B50B718B1EFAA581C152EE07E6623E153E2CDDF00124D2
MODULE_VERMAGIC=7.0.0-29-generic SMP preempt mod_unload modversions <TRAILING_SPACE>
MODULE_ALIAS_COUNT=1
MODULE_ALIAS=pci:v000010EEd00007021sv000010EEsd0000F0A1bc*sc*i*
MODULE_AHD_7011_ALIAS_COUNT=0
BUILD_MANIFEST_SHA256=99FAE64B07D54D695361BFCF1034237B879399CD8E8FFF4E403C57BBE401F74A
LIBXDMA_COMMAND_FILE_SHA256=80FAD50B146921097337496D92CE5F22B7EB82CF22349A1964C491002DE1A6AB
BUILD_STDOUT_SHA256=1322AC5759505B7406883CDD448CEF451D0221D708D912B85AD8DBB10739F367
BUILD_STDERR_SHA256=BA71FA6B6F8E049A6D344F8A3B02F55DCCE5392AEC0CE7DB5E9196EF2E0A4C1B
```

The historical controller-side evidence copy was recorded relative to the HDMI
worktree as:

```text
out/demo_r0f_a/DEMO_R0F_A8_C1_20260829T133814Z_BOARD0005_35486361/local_evidence/artifacts/xdma.ko
```

That is a historical controller-relative path, not a current DUT path. The C5
deployment source later governed `/opt/fpga-hdmi-lab/driver/xdma.ko`. The current
audit found the deployed file absent.

## Source-to-use lineage

| Stage | Commit/tree | What it binds |
|---|---|---|
| Driver source | code `b7ef83efcba95e74c25f67996e8c5686a6fa887c`; tree `01d33fea7f9d36e6772342e536990151ffd1ecc3` | Exact seven-path committed correction surface and unchanged PCI patch |
| Successful build | evidence `ecb760da97a597460c16959a564979f3836dfd24`; tree `91e5840925b770d8ac0c305e76def6e1af0563e5` | Source manifests, one build, exact binary identity |
| First load/bind | evidence `4902c5d04253c76584196e97115e6b4186dc3e0b`; tree `a17e2bf0a9d0bfa6406500addca01ccfdb4c9cc6` | Exact local/remote rehash, one load, HDMI-only binding and nodes |
| First exact DMA frame | branch head `d27ab44e3a9dc6fb721e9a1aaa69133fcd35daa6`; tree `775c2e7ecf46ba17282ea9955564c54271165780` | Same module, node-to-BDF proof, exact frame DMA and validation |
| SSOT-accepted board-0006 use | evidence `3143b8775be671381ca19f5feae042b4daa9152d`; tree `411ad90f43a17ad25445439acf476124546bea95` | Same hash/alias/kernel, later finite HDMI hardware proof |
| Current SSOT | `2317361094d599717a9509bd9d508efd58f6d1a2`; tree `7bf324a9afb02d8da6947cc0748b16e07d1d0c55` | Owner-accepted project-state revision 1 |

The R0F-A8-C1/A9/A10 branch is detailed historical provenance. The current SSOT
authority is revision 1 and accepts the module identity through E-0006; the
historical branch is not a competing SSOT.

## Provenance limits and non-claims

- No current DUT SHA-256 or size was obtained because the exact file is absent.
- The published historical set does not preserve current `file`, `readelf`,
  SHA-512, `srcversion`, `retpoline`, dependency, signer, signature-key, or
  signature-algorithm output.
- Source-defined version `2025.2.0` is not represented here as a fresh current
  `modinfo -F version` result.
- Build architecture is bound by the x86_64 build contract and evidence; an ELF
  header cannot be re-read from an absent file.
- Historical provenance does not authorize reconstructing, copying, rebuilding,
  installing, loading, binding, or substituting the binary in this task.

