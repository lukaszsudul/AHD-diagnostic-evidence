# Authority and scope — CONT1R3R4R5-W1W2-OFFLINE

## Mandate and boundary

The Owner authorized one combined offline W1/W2 execution: measure resolved-line gaps in the unchanged SCAN1/master path; compare the frozen FPGA initialization and detection path with pinned reference code; audit the latest existing events; and decide the minimum justified W3 scope. W1 flows directly into W2. W3 implementation, W4, hardware experiments and camera acquisition are outside this execution. Task-owned source copies, parsers, trace checkers and minimal simulation are permitted. Append-only evidence publication to `lukaszsudul/AHD-diagnostic-evidence` is permitted, with a separate commit-pinned read-back gate. No SSOT/META/PRODUCT promotion is authorized.

No DUT contact is required or authorized: no SSH, ping, discovery, JTAG, real MMIO/I2C, node access, driver load/bind, reboot, reset, programming, scan or capture. The sole future DUT endpoint recorded by META-9 is `10.132.1.111:22`; `192.168.1.57` is superseded, not a fallback. Live DUT state in this task is `NOT_SURVEYED_IN_THIS_TASK`. The historical cold-start cleanup remains historical evidence, not a new observation. No RTL, master, table, manifest, projection, driver, IP or XDC change; no synthesis, optimization, placement, routing, DCP reopening or bitstream generation is within scope.

## Governed entry and current state

The six entry documents were read in their prescribed order: `README.md` → `GOVERNANCE.md` → `UPDATE_POLICY.md` → `PROJECT_STATE.json` → `TRACK_STATUS.json` → `CURRENT_INTERFACES.md`, all under `project-current-state/` in `lukaszsudul/AHD-diagnostic-evidence`. At admission both JSON revision fields and the human-readable documents reported `PROJECT_STATE_REV=9`. The 18 entries in `project-current-state/SHA256_MANIFEST.txt` matched the present file bytes, with zero mismatches; the manifest excludes itself. The six entry-document byte SHA-256 values were:

| Entry document | SHA-256 |
|---|---|
| `README.md` | `179C6BD16B2A4143BD5A116F3C6A63D59C2B7C96E65771E62FBDF63EAC30EBB9` |
| `GOVERNANCE.md` | `70BE3FF2A5BB65C843BFAC719D740DF467F4E00E7B3F9A9CAC8D331F146B7D8B` |
| `UPDATE_POLICY.md` | `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497` |
| `PROJECT_STATE.json` | `B441296763785CB0FD8764DB78175F1F0D2A5DA891D174FEF364417901C6A6C2` |
| `TRACK_STATUS.json` | `11B99A80D76C81C514FB24131F847EECFB75B6AD7E7B08563A383A98A4CA4686` |
| `CURRENT_INTERFACES.md` | `00F55BF703AC0541045D319352B248DB4CA9702530E4CA378171CAAE9080FD90` |

The latest project-state update is META-9, committed in the evidence repository as `f8429a81e22a2f887afd06b334889c30aed7a293`. Its accepted decision provenance is `1c0bad816d98c4ce077e7237bd759c0c1bfbdb2e`, `v41-owner-decisions/2026-09-16-dut-endpoint-return-cont1r3r1/OWNER_DUT_ENDPOINT_DECISION.md`; the decision blob is present at that exact commit. The META-9 write receipt is `v41-meta-project-state-rev9-dut-endpoint-return/META9_WRITE_CONTRACT_RECEIPT.md`. Project truth and execution evidence remain separate. This task is an SSOT read-only Gate task. The governance stale-state rule requires one more revision/hash read before final publication; if the revision changes, inspect all intervening changes and record `NO_IMPACT`, `REVALIDATION_REQUIRED` or `TASK_INVALIDATED`, or stop an affected action on conflict. At this authority review, start/end revision was `9/9` and staleness `NONE`; the package-level end read remains the publishing agent's responsibility.

## Frozen implementation and reference authority

FPGA implementation authority is `lukaszsudul/FPGA_AHD` commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, Git tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`. Both values were resolved locally from the commit object. The primary checkout at review was `main` commit `be94f88ee8d179f12928ab791bdae27c22cd1762`, tree `e128ff47a5e21e8131971f5e5caa7657e2eccc7f`, with no tracked edits and pre-existing untracked directories; it is not the selected design authority. Frozen inputs must be copied from the pinned object without altering that checkout. Byte SHA-256 values calculated directly from pinned Git blobs are:

| Frozen source path | Git blob | SHA-256 |
|---|---|---|
| `rtl/v41/nvp_i2c_fixed_master.sv` | `738a81ec621a4ff85efda48d14b45ba2b9a4803e` | `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF` |
| `rtl/g2b/g2b_nvp_camera_scan1.sv` | `16182fd9e5362c36ec85b1de974b6c235ec7513a` | `D0F54EDA1542E1A7D57004A90DD9B910956000711F125EF7774484E04D78793A` |
| `rtl/g2b/g2b_nvp_camera_scan1_manifest_pkg.sv` | `318c3979ac5b573baaef3afe6b4d15724a2abdd9` | `F21EE3718F84304DD40D29B0A5FE95BBBA15336D9B7BD642177B950CF7598DD6` |
| `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` | `0a9ee1fe4421abc3cc5d7d0a977a1a9ed5b66894` | `4ADD841745733723B6F19AA445E14AAA117E7D291CEE057AA37C115D3ED287BB` |
| `rtl/g2b/g2b_nvp_acq1_compat0_r2.sv` | `e69e1661fa3898bc1d46d5a46b9e94434a202594` | `79792717C8AAB7659692DC8ACD04F2B9C74B1D3FD522179F71CEEA307177E70C` |
| `rtl/top/ahd_capture_top_xdma.sv` | `cbbefea1a75a72fd2ae465649de709d55f740963` | `2467EFBEF793706688AEA1CA33FF23AE1F244AB213EB154E6F83A9FFC41B66A0` |

The prior private frozen-cone archive is `C:\FPGA\CONT1R3R4R4_I2C_OFFLINE_20260917T122048Z\authority\frozen-cone.zip`, and its file sizes/hashes are indexed by the prior `PRIVATE_ARTIFACT_MANIFEST.json`. That archive is a locator, not a substitute for validating each new simulation input against pinned Git bytes. The selected autoinit table/sequencer/profile and any additional source dependencies must be resolved by the W2 active-path audit at the same commit, then recorded with blob and byte hashes; filename resemblance is insufficient.

Third-party reference authority is `4e4o/nvp6134_ex` commit `081ebbff9a2722d47acf16c680594be43cb179e2`, tree `f6926ef14a34365a0e47652253f5f4d63274cb1e`. A clean detached checkout at that exact commit is `C:\FPGA\G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z\reference-repo`. The source reports driver version `17.03.20.01`. It is hosted third-party code with Nextchip copyright headers, not a verified specification for this assembled board. Compile-time transport/mode branches and read-dependent calls must be retained as conditions; unknown camera/chip identity must stay unknown. The reviewed NVP6134C Rev1.0 local PDF SHA-256 is `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`; a differently suffixed PDF in the reference repository does not replace it.

The installed simulator identified itself as `Vivado Simulator v2025.2` when invoked from `C:\AMDDesignTools\2025.2\Vivado\bin`. The inherited R4 simulator logs identify SW build `6299465`; the new W1 run receipt must establish its own actual compiled-source list and build identity. Compile/elaboration and minimal simulation are authorized; implementation stages are not.

## Inherited evidence and interpretation limits

The evidence checkout is `lukaszsudul/AHD-diagnostic-evidence` `main` at `173f23a799f8879e0dab1c29edd6e5c8b0805071` at review. These pinned commits and directories are locally present, with the listed primary files resolved as Git blobs:

| Purpose | Commit and directory | Primary receipts |
|---|---|---|
| Accepted R4 offline review | `173f23a799f8879e0dab1c29edd6e5c8b0805071` / `v41-offline-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r4r4-i2c-stretch-canary-review` | `EVIDENCE_INDEX.md`, main report, `SOURCE_TIMING_AUDIT.md`, `NVP_REFERENCE_FINDINGS.md`, `RAW_CAUSE_LIFETIME.md`, `FUTURE_SINGLE_IMAGE_FIRST_FRAME_PLAN.md`, manifests and simulation receipts |
| Latest 25-scan hardware campaign | `b1b12524d41435aad49d7ce7662af26981682143` / `v41-hardware-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r4r2-coldstart-existing-driver` | `EVENTS_SUMMARY.csv`, `CAMPAIGN_ANALYSIS.md`, `HARD_STOP_RECEIPT.md`, manifest |
| Bank5 failure replay | `74dd150c3438bbea24641cdd8e3bb45e62a5bc65` / `v41-offline-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r4r3-bank5-failure-replay` | `EVIDENCE_INDEX.md`, `FAILURE_SIGNATURE_COMPARISON.csv`, `REGADDR_EXISTING_EVENTS_REVIEW.md`, simulation matrix |
| Older target set, if needed | `501a0dea7588679b0379b88cdc32c8fec2507c3f` / `v41-hardware-g2b-nvp-camera-acq1-compat0-r2r1-cont1r2-i2c-integrity-slice-format` | Keep separate from the latest 11-event denominator |

Their commit tree IDs are, respectively, `8ae9aef56a4931cab27fd62c709dfa956baf16a8`, `2bddc269928d7d5a690b2a768be847135f9d4a16`, `b44a28747de6d7e1c80ffd78fbae09e1b8e777b4`, and `0fb6575294d64644c2b044a83f2c75f953385738`. The META-9 accepted-decision evidence tree is `79f38cd2df239099e34820cf218575f6a7b01156`; its SSOT update commit tree is `28fc292ccbeb663f65aa205332c6b847e83fdf28`.

The latest hardware campaign comprises 25 complete scans, 2,050 entry exposures, 250 group records and 11 recovered first-attempt `REGADDR_NACK`s; a separate control scan passed. The failed next attempt is not a complete scan. The Bank5 selector failure is a separate `0x00000C18` / `0x0005FF0A` event, with published generation 26 unchanged. The 18-test replay establishes signature reachability from normal `DATA_NACK`, not physical cause. The prior 214-case digital timing grid found no false NACK of a valid ACK within that grid; 72 cases reached the configured SCL timeout, which is not a hardware error rate. Current raw cause is not sticky through restore/verify; no qualified fresh post-error reset-canary read exists. The reviewed NVP6134C document supplies no maximum stretch or bank-settle requirement in the reviewed material. These are inherited bounded findings, not new W1/W2 observations or proof of assembled-board behavior.

The historical firmware (`2192144` bytes, SHA-256 `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`), DCP (`C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`) and driver (`E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`) are linkage identities only. They are not reopened, requalified or deployed here. Missing assembled-board records do not block the authorized offline comparison.

## Package-end reread

Immediately before publication staging, `PROJECT_STATE.json` and `TRACK_STATUS.json` both still reported revision **9**, and all **18/18** current SSOT manifest entries matched their file bytes. The evidence checkout and remote `main` both resolved to the pinned R4 commit `173f23a799f8879e0dab1c29edd6e5c8b0805071`; no intervening project-state change was present. The task-local copies of ten frozen FPGA input files, including the autoinit table/sequencer and build-profile script, were independently byte-compared with `FPGA_AHD@09cd7cbb426027acaefd0cf3989579b80a451f3a` and all **10/10** matched at task end. The task-local reference checkout remained clean at `081ebbff9a2722d47acf16c680594be43cb179e2`, tree `f6926ef14a34365a0e47652253f5f4d63274cb1e`. SSOT staleness is `NONE` for W1/W2. The package source/method scope remains offline-only.
