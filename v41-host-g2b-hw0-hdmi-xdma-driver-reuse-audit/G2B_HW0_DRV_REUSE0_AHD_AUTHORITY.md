# G2B-HW0-DRV-REUSE0 AHD Authority

## Record purpose

This record establishes only the AHD-side project authority and the accepted
R2 snapshot facts needed by `G2B-HW0-DRV-REUSE0`. It does not establish HDMI
repository or driver authority, does not determine driver reuse, and does not
replace the mandatory fresh read-only DUT inventory required by the audit.

`AHD_AUTHORITY_VERIFICATION = PASS`

`AHD_R2_EVIDENCE = VERIFIED`

`PROJECT_STATE_REV_AT_START = 8`

`PROJECT_STATE_REV_AT_END = 8`

## Evidence-repository anchor

| Field | Exact value |
|---|---|
| Repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Local worktree | `C:\FPGA\V41_G2B_EVIDENCE` |
| Branch | `main` |
| Required/current local HEAD | `9caa9c339966eda999219e4ed686c01654b9a87e` |
| Repository tree | `ca671bd27568d6ec97eb3de3025b3894fa3c0634` |
| HEAD parent / initial R2 evidence commit | `3ebab4c05e9c9c3271ed1c5f9d800aabd3020632` |
| HEAD subject | `Record G2B HW0 PRODUCT R2 evidence remote read-back` |
| Local `origin/main` at verification time | `9caa9c339966eda999219e4ed686c01654b9a87e` |

The tracked checkout was clean when authority was inspected. No remote fetch
was performed in this scoped authority audit; equality with `origin/main`
therefore refers to the locally held remote-tracking ref, not a new network
read-back.

## Revision-8 SSOT authority

Authoritative directory:

`C:\FPGA\V41_G2B_EVIDENCE\project-current-state`

The following literals are authoritative at revision 8:

| Authority field | Exact value |
|---|---|
| `PROJECT_STATE_REV` | `8` |
| State type | `CURRENT_ACCEPTED_STATE` |
| Accepted by role | `OWNER_ARCHITECT` |
| Acceptance authorization | `META-8A_TASK_DIRECTIVE` |
| SSOT write authorization recorded by META-8A | `SSOT WRITE AUTHORIZED` |
| Update type | `TRACK_GATE_ACCEPTANCE` |
| Expected previous revision | `7` |
| Source evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Source evidence commit | `6843d582fd367fbc0edc0b1d55a9617162c489b0` |
| Source evidence directory | `v41-development-g2b-lut1-signoff-recovery-4` |

Authority sources:

- `project-current-state/README.md`, especially lines 7-22 and 153-176;
- `project-current-state/PROJECT_STATE.json`, especially lines 1-14,
  89-114, and 2286-2329;
- `project-current-state/TRACK_STATUS.json`, especially lines 580-628;
- `project-current-state/CHANGELOG.md`, revision-8 entry at lines 563-604.

No revision 9 and no superseding accepted PRODUCT candidate are recorded in
the current SSOT. The bounded claim is therefore:

`AHD_PRODUCT_CANDIDATE_SUPERSESSION = NOT_RECORDED_IN_CURRENT_REV8_SSOT`

## Revision-8 SSOT integrity

| Field | Result |
|---|---|
| Manifest | `project-current-state/SHA256_MANIFEST.txt` |
| Manifest SHA-256 | `B935E05F75AC1357D29ACB91E08978BD9A6701CD06024F9E6E2C6EB071993EC6` |
| Declared entries | `18` |
| Independently recomputed matches | `18/18` |
| Result | `PASS` |

The manifest covers every other file in `project-current-state/`. The manifest
itself is not one of its 18 entries.

## Accepted exact AHD PRODUCT candidate

META-8A accepts the exact Recovery-4 PRODUCT candidate for controlled hardware
evaluation. This is offline candidate acceptance, not a released product or a
completed G2B hardware qualification.

| Candidate field | Exact value |
|---|---|
| Candidate name | `G2B_PRODUCT_RECOVERY4` |
| Candidate status | `ACCEPTED` |
| Maturity | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` |
| Accepted gate | `G2B-LUT1-SIGNOFF-RECOVERY-4` |
| Source repository | `lukaszsudul/FPGA_AHD` |
| Source branch | `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| FPGA part | `xc7a35tcsg325-2` |
| Vivado version / software build | `2025.2` / `6299465` |
| Profile | `PRODUCT` |
| Active XDC SHA-256 | `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE` |
| Base routed DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| Signed-off DCP bytes | `15726324` |
| PRODUCT bitstream | `G2B_PRODUCT_RECOVERY4.bit` |
| PRODUCT bitstream bytes | `2192144` |
| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Recovery-4 evidence commit | `6843d582fd367fbc0edc0b1d55a9617162c489b0` |
| Recovery-4 evidence directory | `v41-development-g2b-lut1-signoff-recovery-4` |
| Embedded runtime `GIT_SHA` | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Runtime `BUILD_FLAGS` | `0x00000103` |
| Sealed-input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
| Debug probes | `NONE_EXPECTED_PRODUCT_PROFILE` |
| Synthetic generator | `NO` |
| Accepted for gate | `G2B-HW0-PRODUCT` |
| Hardware qualification | `NOT_PROVEN` |
| Hardware throughput | `NOT_PROVEN` |
| Release state | `NOT_RELEASED` |
| Replaces R1i hardware baseline | `NO` |

The embedded runtime `GIT_SHA` and governed source commit intentionally differ
under the frozen dual-identity contract. A later authorized runtime task must
verify both layers; the older embedded identity is not by itself a mismatch.

## Current AHD qualification boundary

| Field | Authoritative revision-8 state |
|---|---|
| Last accepted offline gate | `G2B-LUT1-SIGNOFF-RECOVERY-4` |
| Next allowed engineering step | `G2B-HW0-PRODUCT` |
| G2B-HW0-PRODUCT lifecycle | `PLANNED` |
| Readiness | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION` |
| Progress | `NOT_STARTED` |
| Qualification | `NOT_PROVEN` |
| Scope | `ONE_CHANNEL_FIXED_LIVE_AHD_PATH` |
| Exact offline candidate available | `YES` |
| Hardware evidence present in META-8A | `NO` |
| Fresh operational authorization required | `YES` |
| Persistent Flash programming | `NOT_AUTHORIZED` |

R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. The
Recovery-4 candidate does not replace it as a hardware baseline. Hardware
throughput at `>=288 MB/s/card`, two-channel capture, four-input selection,
V4L2, and release `v41.0.0` remain unqualified or not released as stated in the
revision-8 SSOT.

## Required R2 evidence authority

| Field | Exact value |
|---|---|
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Branch | `main` |
| Required completion commit | `9caa9c339966eda999219e4ed686c01654b9a87e` |
| Required directory | `v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot` |
| Initial R2 evidence commit | `3ebab4c05e9c9c3271ed1c5f9d800aabd3020632` |
| Package engineering gate | `BLOCKED` |
| Package evidence publication | `PASS` |
| Package overall result | `BLOCKED` |
| First blocker | `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE` |
| R2 manifest | `G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt` |
| R2 manifest SHA-256 | `3A75952782C85C4B67F8F742D1E8D278FC8838ABC514CB542F920686E7D7C717` |
| R2 manifest entries | `128`, self-excluded |

Core R2 authority-bearing files were hash-checked against the manifest:

| File | SHA-256 |
|---|---|
| `G2B_HW0_PRODUCT_R2_STATE.json` | `DEC0C53D97A2765B8162CAEE99FBEFC7483D03F74B3BF260FB2FE6EC109E1554` |
| `V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md` | `7B5C0F6097E1AA46A2FB446B5B9A0FDD36B1367FB3FCD7F6B11D21CE5F81C915` |
| `G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md` | `9C3E74CE92F8C8FC2E3F7D1A9F714BFADCD7D1502E7D7A53CAA45465D0AA4C0E` |
| `G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md` | `8F7E8393D49F5BD8CC98DC23ABC257C34AA99351CF0CB7F75DF89DBFABF0E8D5` |

The package records commit-pinned remote byte read-back `PASS` for initial
evidence commit `3ebab4c05e9c9c3271ed1c5f9d800aabd3020632`, covering 129 files
with zero missing paths, size mismatches, or SHA-256 mismatches. Completion
commit `9caa9c339966eda999219e4ed686c01654b9a87e` records that result. The
self-referential package does not claim an embedded read-back of its containing
completion commit; any separate final-commit read-back record remains external
to this file.

## Accepted R2 snapshot facts relevant to driver reuse

These values describe the governed R2 observation, not an unverified claim
about the DUT at the time of the present audit.

| R2 snapshot field | Accepted value |
|---|---|
| Authoritative DUT | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Authenticated user | `vcdeagent1` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Kernel | `7.0.0-29-generic` |
| Architecture evidence | `x86_64` in the pre-reboot uname record |
| Post-reboot boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Exact PRODUCT retained across reboot | `PASS` |
| Exact PRODUCT left in volatile SRAM | `YES` |
| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| AHD endpoint BDF | `0000:01:00.0` |
| Vendor/device | `10ee:7011` |
| Subsystem | `10ee:0007` |
| PCI class | `058000` |
| Root/upstream port | `0000:00:01.1` |
| Link capability/status | `Speed 5GT/s, Width x1` / `Speed 5GT/s, Width x1` |
| Negotiated link gate | `PCIe Gen2 x1 = PASS` |
| Exact recorded modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| Endpoint driver | `UNBOUND` |
| `driver_override` | `(null)` |
| XDMA module | `UNLOADED` |
| XDMA device nodes | `0` |

The installed Linux module observed by R2 was:

| Platform-module field | Exact value |
|---|---|
| Path | `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` |
| Internal name | `xdma` |
| SHA-256 | `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490` |
| Alias | `platform:xdma` only |
| Matching platform devices | `0` |
| Exact AHD PCI modalias match | `NO` |
| Classification for this audit | `INSTALLED_PLATFORM_MODULE_NOT_HDMI_REUSE_CANDIDATE` |

R2 deliberately chose `DO_NOT_LOAD_OR_BIND`. Loading the installed
platform-only module could not have bound the AHD PCI function or created the
required user/C2H nodes.

R2 operation counts were: one authorized warm reboot; zero power cycles, SRAM
programs, Flash programs, module loads, binds, unbinds, MMIO reads or writes,
DMA operations, PCI rescans, and PCI resets. The sole authorized R2 warm reboot
was consumed and must not be repeated by `G2B-HW0-DRV-REUSE0`.

## Snapshot-versus-fresh boundary

`R2_ACCEPTED_FACTS = HISTORICAL_GOVERNED_SNAPSHOT`

`CURRENT_LIVE_DUT_STATE = NOT_VERIFIED_BY_THIS_RECORD`

R2 establishes the accepted starting reference, but endpoint presence, BDF,
driver symlink, modalias, link state, loaded-module state, node count, kernel,
boot ID, uptime, user, hostname, machine ID, and concurrent activity can drift.
The reuse audit must obtain a fresh authenticated read-only DUT inventory under
its explicit authorization before using any of those fields as current state.

If a fresh read-only check finds an XDMA module loaded or the endpoint bound,
the audit must not unload or unbind it. It must apply its governed state-change
handling, including `BLOCKED — DRIVER_STATE_CHANGED_SINCE_R2` unless the state
is fully attributable to an already governed concurrent project operation.

## No-touch record

This authority step performed no:

- DUT, SSH, JTAG, PCIe, sysfs, MMIO, or DMA access;
- FPGA, SRAM, or Flash programming;
- warm reboot, power-cycle, PCI rescan, or reset;
- module load, unload, install, bind, unbind, or `driver_override` write;
- package install or driver build;
- AHD source, active-XDC, binary, or SSOT modification;
- HDMI source, binary, evidence, or SSOT modification;
- Git branch, remote, commit, or push operation.

Only this evidence-draft file is created by the scoped authoring step.

## Explicit non-claims

This record does not claim that:

- the R2 DUT state is still current;
- an authoritative HDMI SSOT or repository has been found;
- an exact HDMI driver binary has been located or hash-verified;
- the HDMI module is a PCIe driver rather than another platform driver;
- HDMI source provenance, patches, vermagic, signatures, dependencies, PCI
  aliases, subsystem policy, or AHD/HDMI XDMA configuration are compatible;
- the exact HDMI module has previously loaded, bound, created nodes, or
  executed DMA on this kernel and DUT;
- module-name collision handling is safe;
- any HDMI driver reuse decision has been reached;
- any later load/bind plan is authorized for execution.

`HDMI_DRIVER_REUSE_DECISION = NOT_MADE_IN_AHD_AUTHORITY_RECORD`

`FINAL_EXECUTION_POINT = HARD_STOP_AFTER_READ_ONLY_AHD_AUTHORITY_RECORD`
