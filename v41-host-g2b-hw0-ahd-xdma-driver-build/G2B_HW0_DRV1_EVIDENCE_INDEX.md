# G2B-HW0-DRV1 evidence index

## Package state

| Field | Value |
|---|---|
| Repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Branch | `main` |
| Directory | `v41-host-g2b-hw0-ahd-xdma-driver-build` |
| Engineering gate | `PASS` |
| Publication gate | `PENDING` |
| Evidence commit | `PENDING` |
| SHA-256 manifest | `PRESENT` |
| Commit-pinned remote read-back | `NOT_RUN` |

No file should be treated as published merely because it exists locally.
Publication becomes `PASS` only after the final package manifest is generated,
the package is committed and pushed without force, and every required file is
read back from the exact remote commit with matching size and SHA-256.

## Required public evidence files

| File | Role | Assembly state |
|---|---|---|
| `V41_G2B_HW0_DRV1_MAIN_REPORT.md` | Governed result, qualification scope, and nonclaims | `PRESENT` |
| `G2B_HW0_DRV1_AUTHORITY_RECEIPT.md` | Owner, project-state, predecessor, upstream, worktree, and boundary receipt | `PRESENT` |
| `G2B_HW0_DRV1_DUT_BUILD_ENVIRONMENT.md` | Authenticated DUT, toolchain, headers, config, Secure Boot, and coordination inventory | `PRESENT` |
| `G2B_HW0_DRV1_HDMI_PROCESS_REUSE_MATRIX.md` | Generic process reuse versus rejected HDMI-specific identity | `PRESENT` |
| `G2B_HW0_DRV1_SOURCE_DELTA_AUDIT.md` | Machine-readable source-delta classification and generic-transport proof | `PRESENT` |
| `G2B_HW0_DRV1_PCI_TABLE_PROOF.md` | Before/after PCI table and exact subsystem-policy proof | `PRESENT` |
| `G2B_HW0_DRV1_ALIAS_MATRIX.csv` | Positive and negative offline alias results | `PRESENT` |
| `G2B_HW0_DRV1_EXPECTED_NODE_MODEL.md` | Static class/node/index model with source evidence | `PRESENT` |
| `G2B_HW0_DRV1_EXPECTED_BIND_MODEL.md` | Offline exact-alias automatic-probe model | `PRESENT` |
| `G2B_HW0_DRV1_PLATFORM_MODULE_COLLISION_AUDIT.md` | Installed platform-module preservation and namespace risk | `PRESENT` |
| `G2B_HW0_DRV1_BUILD_A.log` | Full clean Build A transcript and warnings | `PRESENT` |
| `G2B_HW0_DRV1_BUILD_B.log` | Full clean Build B transcript and warnings | `PRESENT` |
| `G2B_HW0_DRV1_REPRODUCIBILITY_REPORT.md` | A/B hash, byte, diff, input, and path-leak comparison | `PRESENT` |
| `G2B_HW0_DRV1_MODINFO.txt` | Static module metadata | `PRESENT` |
| `G2B_HW0_DRV1_ELF_REPORT.md` | ELF header, sections, notes, symbols, and build ID | `PRESENT` |
| `G2B_HW0_DRV1_VERIFICATION_RECEIPT.md` | Consolidated offline verification and no-load receipt | `PRESENT` |
| `G2B_HW0_AHD_XDMA_DRIVER_CANDIDATE_IDENTITY.json` | Machine-readable qualified candidate identity | `PRESENT` |
| `G2B_HW0_DRV1_R3_LOAD_PLAN.md` | Documentation-only future load/probe/node/runtime plan | `PRESENT` |
| `G2B_HW0_DRV1_STATE.json` | Machine-readable DRV1 gate and no-touch state | `PRESENT` |
| `G2B_HW0_DRV1_EVIDENCE_INDEX.md` | This package index | `PRESENT` |
| `G2B_HW0_DRV1_SHA256_MANIFEST.txt` | Final public-file byte/size/hash manifest | `PRESENT` |
| `0001-ahd-exact-pci-match.patch` | Exact AHD PCI/module/Kbuild patch | `PRESENT` |
| `UPSTREAM.lock` | Exact upstream commit/tree and patch/policy lock | `PRESENT` |
| `build_ahd_xdma.sh` | Deterministic isolated build recipe | `PRESENT` |
| `verify_ahd_xdma.sh` | Static identity, ELF, symbol, and alias verifier | `PRESENT` |
| `G2B_HW0_DRV1_SEALING.log` | Authenticated remote sealing and manifest-verification receipt | `PRESENT` |
| `G2B_HW0_DRV1_FINAL_DUT_STATE.log` | Final authenticated read-only DUT-state receipt | `PRESENT` |
| `G2B_HW0_DRV1_SEALED_ARTIFACT_SHA256_MANIFEST.txt` | Hash manifest stored with both sealed artifact copies | `PRESENT` |

The final assembler must update assembly states from the actual filesystem and
must not infer presence from this planned index.

## Candidate identity anchor

| Field | Value |
|---|---|
| Driver branch commit | `0a201aab7adb13be079e784c6ed97dfad2ed7764` |
| Driver branch tree | `6f079bf086878ddbce1f1ec82fece3039eae6573` |
| Upstream commit | `b8466090b4e812e191da9e9305ffb11cb7ace768` |
| Upstream tree | `f9286c5d1bdae57285570ac5c23244d54076b99f` |
| Patch SHA-256 | `415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7` |
| Module | `xdma_ahd_pcie.ko` |
| Internal name | `xdma_ahd_pcie` |
| Module SHA-256 | `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77` |
| Module size | `3296104` bytes |
| Vermagic | `7.0.0-29-generic SMP preempt mod_unload modversions ` |
| Exact AHD modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| Generated alias | `pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*` |

## Source and raw-evidence authorities

The public documents are derived from these governed local authorities:

- project-state revision 8 under `project-current-state/`;
- R2 directory
  `v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot` at evidence
  commit `9caa9c339966eda999219e4ed686c01654b9a87e`;
- HDMI reuse directory `v41-host-g2b-hw0-hdmi-xdma-driver-reuse-audit` at
  evidence commit `b3920c7ce5ef3cb83800c85a29eb8febca357319`;
- driver recipe at driver commit
  `0a201aab7adb13be079e784c6ed97dfad2ed7764`;
- fresh governed DUT inventory and authenticated wrapper logs under
  `C:\FPGA\G2B_HW0_DRV1_PREFLIGHT_20260906`;
- decoded Build A, Build B, reproducibility, module-inspection, and alias
  receipts under
  `C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\raw_export`.

Local controller/raw paths are provenance pointers, not public remote-read-back
claims. Credentials, password files, private keys, tokens, and secret
connection material are excluded.

## Sealed binary policy

Verified sealed module paths are:

- `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`;
- `C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko`.

The `.ko` is intentionally excluded from the public repository. The public
package records only its exact hash, size, identity, provenance, and sealed
paths. The final verification receipt establishes byte equality between sealed
copies, and the remote sealed directory is mode `0555` with no writable file.

## Publication closure checklist

- [x] Verify every required public file exists.
- [x] Verify no credential, password, token, private key, or secret connection
      material is present.
- [x] Resolve every package assembly state from actual files.
- [x] Generate `G2B_HW0_DRV1_SHA256_MANIFEST.txt` after content is final.
- [x] Cross-check module hash, size, names, vermagic, aliases, branch commit,
      and source tree in every document.
- [ ] Commit with message
      `Build and qualify AHD PCIe XDMA driver candidate`.
- [ ] Push `main` without force.
- [ ] Read back the exact remote commit, not the moving branch head.
- [ ] Verify every required file's size and SHA-256 against the local package.
- [ ] Verify driver branch
      `host/v41-g2b-hw0-ahd-xdma-driver` is remotely visible at exact commit
      `0a201aab7adb13be079e784c6ed97dfad2ed7764`.
- [ ] Record the evidence commit and change publication from `PENDING` to
      `PASS` only after all checks pass.

## Nonclaims

This index and its package do not claim module installation, load, PCI probe or
binding, live node creation, node-to-BDF mapping, MMIO, DMA, FPGA programming,
reboot, power-cycle, or runtime/hardware qualification. R3 remains separately
authorized work.
