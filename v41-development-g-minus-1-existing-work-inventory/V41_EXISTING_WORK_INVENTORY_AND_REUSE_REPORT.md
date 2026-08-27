# AHD v41 Existing Work Inventory and Reuse Report

Gate: G-1 — existing-work inventory and evidence archaeology

Audit timestamp: 2026-08-27

Source workspace: `C:\FPGA\FPGA_AHD`

Method: source-workspace read-only inspection, isolated remote mirror, isolated evidence clone, immutable Git-object inspection, and sanitized report generation outside the source repository.

## 1. Executive conclusion

Substantial v41 work exists, but it stops at an important boundary. The project already contains an integrated XDMA PCIe endpoint, one exposed C2H interface, the mandatory H2C engine safely backpressured, an AXI-Lite bridge and register bank, a documented BAR map, a single-input video/record path, build and constraint infrastructure, Linux driver/MMIO procedures, and useful diagnostics. The best-correlated donor lineage has passed full implementation before R1i and has passed PCIe enumeration, driver loading, BAR discovery, identity reads, and scratch-register hardware checks. It has **not** moved application data by DMA.

The best-supported primary XDMA donor candidate for Owner/Architect review is `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`. Its functional Phase 1 tree is anchored at commit `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`, tree `c54368c7e830904505ca58da7bb57ef62c3635dc`; its Phase 2 hardware acceptance is `9306c25a48dedd2372bf5d06e37344ae2aa3e85a`; and its tip adds documentation only. This is a recommendation for G0 input, not a final donor selection.

The most valuable secondary donor is `dev/v41-xdma-offline-next` at `8464af66611f7c22b8a36a4aab915d598eedda3f`. Its RTL, XCI, XDC, MMIO and host assets are identical to the base. Its only added delta is provenance hardening in `scripts/v41/phase3_build.tcl` (31 insertions, 2 deletions), for which no separate hardware run exists. The old `v41/xdma` and `archive/v41-xdma-pre-v40.1.0-20260817` are exact duplicate refs at `f3cfa6bf...`; they preserve history but are not the best current implementation donors.

Qualified R1i must be preserved as the functional NVP/I2C baseline: R1h `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`, R1i `20c3323d79d3896edc586d6db1df7deee60f9e41`, R1i tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`, and bitstream SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`. The scientific result is `THESIS_CONFIRMED`, `STRONG_PASS`, `QUALIFIED_POC_BASELINE`; the exact low-level causal submechanism remains inconclusive. Current FPGA_AHD refs no longer advertise R1h or R1i and direct object fetch fails. However, the public ordered patch chain from reachable `diag/v41-nvp-i2c-25khz-r1` reconstructs every recorded intermediate and the exact final R1i tree, so source-tree recoverability is independently verified.

Do not reuse pre-R1i NVP/I2C FSMs as functional donors, the experimental D3/R1c/R1f/R1g/ODIV2 lines as production sources, the legacy `pcie_7x` PIO endpoint for v41 XDMA, or any document claim that the current design already has DMA. Stale statements that the application clock is 125 MHz are superseded by the XCI, top-level parameters, routed evidence, and approximately 62.383 MHz hardware measurement establishing a nominal 62.5 MHz application clock.

The real remaining gap is not “make PCIe enumerate.” It is the full data plane: define/implement the record-to-C2H adapter, backpressure/drop policy, packet correctness, application one-channel DMA, host transfer/correctness tooling, interrupts/telemetry as required, two physical/logical channel architecture, two-channel resource closure, and sustained-throughput qualification. There is also an architectural incompatibility to resolve: a PCIe Gen1 x1 link has a raw post-8b/10b ceiling of 250 MB/s before PCIe protocol overhead, so 288 MB/s of sustained application payload cannot be achieved by the committed link configuration. The target must change, or the requirement must be reinterpreted.

## 2. Local workspace state

The primary workspace was clean throughout the audit:

- path: `C:\FPGA\FPGA_AHD`
- branch: `main`
- HEAD: `be94f88ee8d179f12928ab791bdae27c22cd1762`
- origin: `https://github.com/lukaszsudul/FPGA_AHD.git`
- tracked files: 68
- untracked files: 0
- present ignored files/directories: 0
- local branches: one (`main`)
- worktrees: one (the primary workspace)
- submodules: none
- tracked LFS paths/objects: none
- local-only reachable commits: none
- index/worktree differences: none

The local clone had only `origin/main` as a remote-tracking ref; all 11 live remote branches were inspected through read-only remote enumeration and an isolated bare mirror. `git fsck` reported no unreachable commits and three unreachable blobs. Their contents were deliberately not inspected or published.

A read-only `git lfs status` probe triggered Git LFS's automatic repository-format stanza in `.git/config`. The exact tool-created stanza was immediately removed. Final refs, index, tracked tree, worktree, and `lfs.*` configuration match the audited baseline. No source file or Git history was changed.

The detailed state is in `V41_LOCAL_WORKSPACE_MANIFEST.txt`.

## 3. Repository topology

The active `main` tree is a compact frozen-v40 baseline. The migrated v41 donor trees are substantially larger:

| Branch | Files | docs | ip | rtl | scripts | host | tests/tb | xdc |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `main` | 68 | 8 | 3 | 17 | 6 | 0 | 18 | 6 |
| `v41/xdma-v40.1.0-base` | 178 | 74 | 4 | 20 | 27 | 10 | 23 | 8 |
| `dev/v41-xdma-offline-next` | 178 | 74 | 4 | 20 | 27 | 10 | 23 | 8 |
| `v41/xdma` | 140 | 47 | 4 | 20 | 21 | 10 | 20 | 8 |

The expected top-level domains exist, but not all are present on `main`; many v41 assets live only in the remote branches. No submodule or Git LFS dependency carries hidden source. Generated Vivado products are ignored and were absent in the active workspace. The public evidence repository is a separate authority for campaign artifacts, reports, patches, raw captures, hashes, and selected LFS bitstreams; it is not a full proprietary source mirror.

The evidence repository's audit-start `origin/main` was verified at `955ba0cd2462f4dec9dcb086175ab6eca57365bb`. That commit corrects seven R1i XDC provenance path labels over initial publication `c1c552fa4fc693d6c375db9478abecd7960ec3ce`; source hashes, measurements, artifacts, and scientific conclusions are unchanged. A final pre-publication fetch found that `origin/main` had advanced to unrelated R0-design publication `aff7e32edc1cf71bde95b6c19e54e6f307764237`. The new package had no G-1 path overlap and was retained by rebasing the isolated G-1 publication onto it.

## 4. XDMA development history

The best-supported lineage is:

```text
main be94f88
├─ original XDMA line (15 commits)
│  └─ f3cfa6b = v41/xdma = archive/v41-xdma-pre-v40.1.0-20260817
└─ 67f6513
   ├─ experimental D3 line → 7707243 → 01acf49
   └─ K1/K2/K3 → release/v40.1.0-nvp 55ce0df
      └─ replay/migrate original XDMA assets 3a5e80a
         └─ Phase 1 accepted fd32fcb
            └─ Phase 2 hardware accepted 9306c25
               └─ documentation-only donor head c89e88b
                  ├─ provenance-only dev change 8464af6
                  │  ├─ address-probe line 1beb705
                  │  └─ 25-kHz line f007dc1
                  └─ AXI-clock diagnostic 0af44de
```

The qualified NVP lineage continues in public evidence from the reachable 25-kHz line through R1e, R1f, R1g, R1h and R1i. It is not currently advertised as source-repository branch refs.

`dev/v41-xdma-offline-next` contains one change not in the base: Phase 3 SHA round-trip/provenance preflight. It is a strict child of the base. Compared by path content, it also contains all old `v41/xdma` pathnames; there is no old-only missing XDMA pathname at the tip. The apparent 15 old-only/13 dev-only commit-set split is caused by replay/migration rather than a history merge. Conversely, no old-only pathname or donor-worthy XDMA XCI/AXI-Lite/XDC/host asset is absent from the dev tip; `v41/xdma` retains distinct pre-v40.1 versions of modified NVP/top/PIO/vendor/video/build/test files and old Phase 2 evidence content, whose value is historical provenance rather than preferred implementation.

All branch identities, merge bases, unique-commit counts, roles and evidence are in `V41_BRANCH_INVENTORY.csv`.

## 5. R1i qualified baseline

The supplied R1i identity is verified:

- exact R1h base commit: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`
- exact R1h tree: `161e561f007912d73dba93c5ecd78e3cc3a6955b`
- exact R1i commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- exact R1i tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- exact R1i bitstream: 2,192,144 bytes, SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- corrected/resealed public evidence commit at audit start: `955ba0cd2462f4dec9dcb086175ab6eca57365bb`
- tool/build context recorded by evidence: Vivado 2025.2, clean 232-file source tree, routed design, WNS +0.617 ns, WHS +0.036 ns, no DRC error/critical finding

The same-session A1/B1 comparison is strong within its scope. R1i A1 reported zero autoinit NACKs, no initialization error, video at 24.803727 Hz, and 0/10,000 NACKs in each of three post-init observation classes. Exact R1h B1 reported four autoinit NACKs (two register-address and two data), initialization error, no video, and 0/10,000 post-init NACKs in each class. Across the qualified campaign, 60,000 post-init observations were captured.

The result proves the combined correction under the tested conditions; it does not isolate the exact causal submechanism because R1i causal counters were all zero. It is a qualified PoC, not production qualification: one frozen same-session A1/B1 comparison, no multi-board population, temperature/voltage sweep, long run, broad cold-start population, formal proof, DMA, or throughput qualification.

Direct fetch of R1h/R1i by SHA from the current primary remote fails (`not our ref`). This is a branch-retention/provenance risk, not a source-recovery failure. In an isolated scratch clone, the ordered public R1e → R1f → R1g → R1h → R1i patches applied from reachable `f007dc1...` and reproduced every recorded tree, ending at exact R1i tree `70d801fd...`. Applying only the last R1h-to-R1i patch to the formal/base donor would not reproduce the qualified state; the whole published lineage matters.

## 6. Existing XDMA implementation

The committed XDMA asset is `ip/v41/xdma_v41_m1.xci`, VLNV `xilinx.com:ip:xdma:4.2`, revision 2, SHA-256 `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`. The effective configuration is:

- PCIe Gen1, x1, PCIe block X0Y0
- 100 MHz differential reference clock
- 64-bit AXI4-Stream application interface at nominal 62.5 MHz
- one C2H channel
- one tool-mandated H2C channel
- AXI-Lite Master, 128 KiB aperture at address zero
- one user interrupt, MSI enabled with one vector, MSI-X disabled
- dedicated active-low PERST
- vendor/device `10ee:7011`, subsystem `10ee:0007`, class `058000`

The XCI, active XDC, AXI-Lite bridge, register bank, host Phase 2 tools, and common configuration helper are blob-identical across the migrated base and dev tips. The old line shares the core assets but predates the v40.1 NVP integration/top changes.

`scripts/v41/xdma_config_common.tcl` is useful but incomplete as a reconstruction authority: it does not explicitly pin/check every effective property, including all application-clock, dedicated-PERST and MSI details. The exact proven XCI is the stronger donor. Any regeneration or tool/IP upgrade must be separately revalidated.

## 7. Existing PCIe/MMIO implementation

PCIe and MMIO are the strongest non-R1i implementation area. The donor provides:

- XDMA endpoint integration in `rtl/top/ahd_capture_top_xdma.sv`
- `rtl/v41/axi_lite_host_bridge.sv`
- `rtl/v41/control_status_regs.sv`
- current Phase 3 register-map documentation
- host enumeration, driver-load, readiness, identity, scratch and control validation tools
- one user IRQ interface (currently not requested by application logic)

Hardware evidence establishes one 2.5 GT/s x1 endpoint, BAR0 128 KiB user aperture, BAR1 64 KiB configuration aperture, the pinned official XDMA driver and expected nodes, read-only identity/status reads, and the restored scratch register. Thousands of read-only AXI-Lite accesses, including the R1h/R1i diagnostic pages, further establish bridge stability.

The official XDMA driver source is not vendored. Evidence pins source commit `8721136e74a66500b02d16cb41922d966139cd46` and a historical module SHA-256 `1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A`. The host evidence also documents hazards: a same-name Ubuntu in-tree/platform `xdma`, module vermagic mismatch, non-autoloading pinned module, and shell-launch semantics. Driver procedures are therefore `REUSE_AFTER_REVALIDATION`, not turnkey current proof.

R1i changes the MMIO semantics at one deliberate boundary: it preserves the map through `0x35ff` and adds a read-only page at `0x3600..0x367f`. Any future register-map extension must preserve both.

## 8. Existing DMA implementation

No application DMA data path is implemented.

- C2H channel 0 exists at the XDMA IP/top boundary, but application `tdata`, `tkeep`, `tlast`, and `tvalid` are tied to zero.
- The mandatory H2C channel exists and the host driver exposes `h2c_0`, but application `tready` is tied low.
- User IRQ request and DMA telemetry inputs are tied to zero.
- No record-to-AXI-Stream adapter exists.
- No application C2H packet has been demonstrated.
- No H2C application consumption exists.
- No host DMA correctness or throughput tool is present in FPGA_AHD.
- Every relevant evidence campaign records C2H/H2C transfer counts as zero.

The documented C2H contract—one 4,096-byte record, 512 64-bit beats, `TKEEP=0xff` every beat, `TLAST` on beat 511, whole-record drop policy—is a planned architecture contract, not verified RTL.

Driver node/channel enumeration (`usr 16, ch 1,1`, `c2h_0`, `h2c_0`, event nodes) proves IP/driver exposure only. It does not prove data movement, interrupts, integrity, rate, or loss behavior.

## 9. Existing video-path implementation

The donor/R1i design contains one physical video input and a useful record-oriented capture path:

- `rtl/video/physical_frontend.sv`: VDO1 capture, BUFIO/BUFG, eight IDDRs, per-bit IDELAY, approximately 198 MHz MMCM/IDELAYCTRL support
- `rtl/video/video_capture.sv`: integration wrapper for the physical frontend, record producer, and command/status control path
- `rtl/record/bt656_record_producer.sv`: BT.656 SAV/EAV parsing, frame/line/channel-slot behavior, and fixed record production with 3,840-byte UYVY payload plus v40B metadata/padding to 4,096 bytes
- `rtl/record/capture_mailbox.sv`: command/status clock-domain crossing; it is not record storage or DMA ownership logic
- diagnostics for gray-coded VCLK/SAV/commit counters and R1i NVP state

This path is hardware-correlated through R1i for video presence and rate, but it is not connected to C2H. Existing two-slot storage (`SLOT_COUNT=2`) is buffering, not two-channel capture or G7 proof. There is one physical VDO data/clock group and one configured C2H channel.

The video/frontend/record assets should be preserved with R1i and revalidated after any DMA backpressure or clock/reset integration. R1i routed utilization was approximately 18,181/20,800 LUT (87.41%), leaving about 12.59% LUT headroom. That makes record streaming, larger buffering and especially two-channel expansion a material feasibility risk.

## 10. Existing scripts and tests

The repository already has useful build/check procedures for v40, XDMA Phase -1 through Phase 3, XCI validation, route/timing/DRC/CDC auditing, bitstream identity, programming, host readiness, driver loading, PCIe/MMIO and evidence hashing. The exact script-level classification is in `V41_SCRIPT_INVENTORY.csv`.

The strongest reusable tests are the AXI-Lite host-bridge unit test, exact R1i focused tests/tools, the record producer test, the tracked golden v40B line, and the v40B parser. Pre-R1i NVP tests need update or are obsolete; legacy PIO TLP tests are reference-only for the superseded endpoint. The Phase 2 host validation is a G4 hardware procedure, not a DMA test.

No unit/integration/host tests exist for C2H packet formation, C2H transfer correctness, application one-channel DMA, two-channel DMA, backpressure/drop semantics, DMA interrupts, sustained throughput, sequence loss or CPU/interrupt cost. G9 and G10 cannot be mapped reliably because their acceptance criteria are not defined in the inspected repository. The complete gate mapping is in `V41_TEST_INVENTORY.csv`.

## 11. XDC and timing-constraint inventory

The active XDMA/R1i set is seven files:

1. `xdc/boards/current/xdma_pcie.xdc`
2. `xdc/boards/current/pins.xdc`
3. `xdc/boards/current/vdo_input_timing.xdc`
4. `xdc/boards/current/pcie_pio.xdc`
5. `xdc/boards/current/nvp_control.xdc`
6. `xdc/common/cdc.xdc`
7. `xdc/common/configuration_bank.xdc`

The set is identical across the base, dev and reconstructed R1i states. Public commit `955ba0c...` corrects evidence path labels only. Important content includes the 100 MHz PCIe reference, 148.5 MHz VDO input clock (6.734 ns), VDO input min/max delays, PCIe GT/refclk/PERST pinning, NVP control/I2C/MPP pins, CDC max-delay/bus-skew/first-stage/gray/reset exceptions, and configuration-bank electrical settings.

No active multicycle path was found; no explicit generated-clock definition was found in these hand-written files; generated clocks are primarily IP/tool-derived. `xdc/vendor/pcie.xdc` is inactive/reference and should not be mixed into the active set without ownership review. VDO empirical constraints and CDC object queries are hierarchy-sensitive, so exact textual reuse still requires post-integration object-resolution and timing validation.

## 12. Evidence correlation

Evidence history supports the following bounded conclusions:

- Frozen/current-board RCA controls establish a historical known-good NVP control, but are not the qualified v41 baseline.
- Digital trace R1/R2 confirms the legacy ACK/NACK/control-flow problem and a real NACK at the correct phase; the R1 erratum supersedes the original interpretation.
- Z8 midpoint timing alone was insufficient.
- The application clock is nominal 62.5 MHz; measured about 62.383 MHz. Lifecycle inference remained ambiguous.
- 25 kHz alone reduced NACK count in one sample but did not recover video and was not a pass.
- Address-probe R1d implemented offline tooling but never ran on hardware.
- R1e added useful diagnostics but failed recovery; R1f was blocked by VHDL compatibility; R1g exceeded capacity; BRAM-backed R1h restored build feasibility and diagnostic sample depth.
- R1h R4 produced the exact qualified control and demonstrated later bus availability even when autoinit failed.
- R1i produced the qualified paired recovery while retaining the exact XDMA/XDC substrate.
- PCIe endpoint and read-only MMIO are repeatedly hardware proven; DMA is repeatedly zero/unexercised.

The campaign-by-campaign source, result, failure, completeness and reuse classification is in `V41_EVIDENCE_CAMPAIGN_MATRIX.csv`.

## 13. R1i vs XDMA conflict map

Against `v41/xdma-v40.1.0-base` and `dev/v41-xdma-offline-next`, the R1i lineage is a descendant in the functional NVP path. Four functional files are `R1I_ONLY_CHANGE` relative to those donors:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd`
- `rtl/nvp/nvp6134c_autoinit.vhd`
- `rtl/top/ahd_capture_top_xdma.sv`
- `rtl/v41/control_status_regs.sv`

Against the old pre-v40.1 `v41/xdma`, the first three are `BOTH_CHANGED_CONFLICT` because the old top/NVP line also changed independently. The register mux is still an R1i-only semantic hotspot. The XDMA XCI, common config Tcl and active XDC are `UNCHANGED`. R1i build/tests/readers are `R1I_ONLY_CHANGE`. Donor host/build assets are `XDMA_ONLY_CHANGE` or separate compatible assets.

Five integration decision areas remain: the four functional RTL hotspots and deliberate composition of the R1i harness with dev/base provenance/build behavior. These are not five known irreconcilable textual conflicts; they are five places where an unreviewed transplant could silently lose qualified behavior. `V41_R1I_XDMA_CONFLICT_MATRIX.csv` records each classification and treatment without resolving it.

## 14. Reuse matrix summary

`V41_ASSET_REUSE_MATRIX.csv` contains 34 assets:

- 11 `REUSE_AS_IS`
- 6 `REUSE_WITH_R1I_INTEGRATION`
- 8 `REUSE_AFTER_REVALIDATION`
- 2 `REFERENCE_ONLY`
- 1 `SUPERSEDED`
- 1 `REJECT`
- 5 `UNKNOWN`

`REUSE_AS_IS` primarily covers exact R1i source/test identities, stable register/record contracts and exact shared assets with strong identity. `REUSE_WITH_R1I_INTEGRATION` covers the XDMA/top/build/video substrate. Host/environment and hierarchy-sensitive assets are mostly `REUSE_AFTER_REVALIDATION`. Absent DMA/two-channel/throughput implementations are `UNKNOWN`, not “rejected,” because they do not yet exist.

## 15. What is already done

- v41 branch and phase structure, including a v40.1 migration line
- exact XDMA 4.2 XCI for Gen1 x1 and one C2H interface
- integrated PCIe endpoint/top and 62.5 MHz application clock/reset framework
- AXI-Lite bridge, BAR map, identity/status and scratch register path
- Linux endpoint/driver/MMIO readiness and validation procedures
- one-input video physical frontend, BT.656 capture, 4,096-byte record producer, legacy slot-storage path, and command/status CDC
- build/project, XCI, timing/DRC/CDC, provenance and artifact-manifest procedures
- qualified R1i NVP/I2C behavior, telemetry page, tests, reader and build harness
- diagnostic campaigns covering ACK timing, clock measurement, 25 kHz, address probes, observability and control comparisons

## 16. What is proven

- exact R1i source tree and bitstream identity are recoverable/verifiable from public evidence
- qualified R1i paired recovery under the documented single-board/session conditions
- R1i full route, positive setup/hold margins, and no DRC error/critical issue
- migrated donor full route/timing/DRC/CDC before R1i
- PCIe Gen1 x1 enumeration, `10ee:7011`, BAR0/BAR1 sizes, pinned-driver load and device nodes
- AXI-Lite identity/status/scratch and extensive read-only MMIO
- nominal 62.5 MHz application clock (about 62.383 MHz measured)
- exact active XCI/XDC identity between donor and R1i lineage
- one-input video presence/rate and NVP diagnostic telemetry under R1i

## 17. What is implemented but unproven

- dev-only Phase 3 provenance hardening
- record-producer/legacy-slot assumptions and command/status mailbox CDC behavior under future DMA backpressure
- exact current host procedures on a new kernel/module/tool environment
- user interrupt plumbing beyond tied-off application request
- address-ACK probe hardware behavior (offline build only)
- any assumptions that the current 87.41%-LUT R1i implementation can absorb a stream adapter, deeper buffering or two channels and still close

The XDMA C2H/H2C interfaces are instantiated/exposed but their application data paths are tied off; they should be described as “interface present, data plane absent,” not “implemented but unproven DMA.”

## 18. What is obsolete

- old pre-v40.1 NVP/I2C and top behavior as a functional donor
- D3 R4/R5, R1c, R1f and R1g experimental implementations as production candidates
- 25 kHz alone as a recovery conclusion (retain only as an inherited R1i setting)
- the ODIV2 route-contention proposal as a donor
- legacy `pcie_7x` PIO endpoint for v41 XDMA
- Phase 0 AXI-Lite draft where the Phase 3 map and R1i page supersede it
- prose claiming 125 MHz application clock, 256 KiB configuration BAR, completed DMA, or two-channel capability
- legacy PIO TLP tests as validation of the XDMA-managed endpoint

## 19. What is still missing for v41

For G2/G3, an Owner-approved donor composition must reproduce exact R1i behavior while retaining the proven XDMA substrate, then repeat source identity, focused simulation, complete build/timing/DRC/CDC and selected hardware regression. No such integrated branch is created by G-1.

For G4, the implementation exists, but it needs regression on the selected integrated/R1i state and refreshed host/kernel/driver controls.

For G5/G6, the project needs a record-to-C2H adapter, clock/reset/backpressure/drop contract, packet unit tests, C2H transfer tooling, record integrity/sequence checks, hardware evidence, and one-channel sustained-operation qualification.

For G7, it needs a defined second physical input and/or channel-selection architecture, IP channel configuration decision, independent buffering/stream identity, host topology, resource/timing feasibility and two-channel tests. The existing two record slots are not a second channel.

For G8, it needs a feasible link architecture and a precise throughput definition before implementation. Gen1 x1 delivers at most 2.0 Gbit/s = 250 MB/s after 8b/10b and before TLP/DLLP/flow-control overhead. Sustained 288 MB/s application payload is therefore impossible with the committed link. A higher generation/width, reduced payload requirement, compression, or a different interpretation of 288 MB/s is required.

Production qualification remains beyond R1i: multiple boards, cold boots, temperature/voltage, long duration, error/loss counters, recovery behavior, and any G9/G10 criteria once defined.

## 20. Recommended inputs for G0

G0 should review, without treating this report as the final architectural decision:

1. Primary candidate: `v41/xdma-v40.1.0-base` at `c89e88b...`, anchored to functional `fd32fcb...` and hardware acceptance `9306c25...`.
2. Secondary candidate: dev-only `phase3_build.tcl` provenance hardening at `8464af6...`.
3. Mandatory functional baseline: exact reconstructed R1i tree `70d801fd...`, commit identity `20c3323d...`, full ordered public patch chain, exact file hashes, tests and reader.
4. Exact shared XDMA XCI and active seven-file XDC set; avoid property-helper-only regeneration.
5. Phase 2 PCIe/MMIO evidence and host procedures, with explicit driver/kernel revalidation.
6. Phase 3 register map plus R1i `0x3600..0x367f` overlay.
7. Record protocol/AXI-Stream contract as an unimplemented design input, not proof.
8. A formal G8 feasibility decision before a DMA architecture is frozen.
9. A resource-feasibility decision using R1i's approximately 87.41% LUT utilization.
10. A preservation action for the exact reconstructed R1i source/tree because current primary refs no longer advertise its commits.

## 21. Risks and uncertainties

1. **Throughput incompatibility:** 288 MB/s sustained payload exceeds Gen1 x1's theoretical 250 MB/s post-encoding ceiling.
2. **Capacity:** R1i uses about 87.41% of LUTs; DMA buffering and two-channel expansion may not fit/close.
3. **Ref retention:** R1h/R1i commits are not directly reachable from advertised FPGA_AHD refs. Exact public reconstruction is verified but should be preserved as an immutable source artifact/ref.
4. **PoC scope:** R1i is strongly qualified for the observed single-board/session PoC, not production/population operation.
5. **Causality:** the combined R1i correction is proven; the exact low-level causal mechanism is not isolated.
6. **Driver reproducibility:** driver source is external; historical kernel/module compatibility and same-name-driver hazards are real.
7. **XCI regeneration:** configuration Tcl checks only a subset of effective properties; tool/IP upgrades can silently change behavior.
8. **Constraint fragility:** VDO and CDC constraints contain empirical/hierarchy-sensitive assumptions.
9. **Documentation drift:** 125 MHz, BAR-size and Phase 3 prose contain superseded claims; source/XCI/routed/hardware evidence takes precedence.
10. **No DMA evidence:** IP/channel/node presence can be misreported as application DMA; all measured transfer counters are zero.
11. **Undefined later gates:** G9/G10 acceptance criteria are not recoverable from the inspected repository.
12. **G-1 boundary:** no integration, build, simulation, Vivado execution or hardware validation was performed; all recommendations remain inventory inputs for Owner/Architect review.
