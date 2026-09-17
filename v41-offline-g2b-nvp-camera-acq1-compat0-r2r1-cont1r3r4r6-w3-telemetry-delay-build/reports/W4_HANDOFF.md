# W4 handoff — blocked at W3 post-opt resource gate

**W3 engineering: FAIL. W4: BLOCKED and NOT_AUTHORIZED.** Candidate 2's `opt_design` completed, then `POST_OPT_LUT_GATE_FAILED:23774` stopped the build: 23,774 Slice LUTs versus the governed 20,384 ceiling, an excess of **3,390**. Placement, routing, fresh sign-off, qualified DCP, bitstream generation and final release packaging were not reached. W3 has not contacted the DUT. No programming, reboot, driver action, MMIO, camera scan or capture is authorized by this document.

## Identity gate

| Item | Current exact identity / release condition |
|---|---|
| W3 candidate-2 source commit / tree | `98d4d214c1219b29a60dc1a33af13e91fe33d27c` / `1c43ee847bc468408f574125e3e37209cbb27d54` |
| Source branch | `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z` |
| Parent source commit / tree | `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db` |
| New W3 contract/schema | `contract/W3_CONTRACT.json`, 17,783 bytes, SHA-256 `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7` |
| Candidate-2 source/build-input manifest | `build/W3_CANDIDATE2_SOURCE_BUILD_MANIFEST.json`, SHA-256 `45C74B282C85D750ED828C53F12131E66F8CEE3CB98810E5C06F35FE42E49CF6` |
| Signed new routed DCP absolute path / size / SHA-256 | `NONE` |
| Final W3 `.bit` absolute path / size / SHA-256 | `NONE` |
| Closed final host bundle file set / manifest SHA-256 | `NONE`; provisional offline copies are not a release bundle |
| Private release package absolute path / size / SHA-256 | `NONE` |
| Private source remote commit-pinned byte readback | `PASS`: candidate-2 commit/tree, 342 paths; `reports/SOURCE_REMOTE_READBACK.json` |
| Public evidence remote commit-pinned byte readback | `PENDING`; no publication PASS claim |
| Hardware qualification | `NOT_RUN` |

The historical parent DCP (`C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`) and old bitstream (`CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`, 2,192,144 bytes) are comparison authorities only. They are **not** W3 release identities.

The raw first failed gate is `build/candidate2_vivado.log:2888`; `build/candidate2/POST_OPT_UTILIZATION.rpt` reports 22,450 logic LUTs and 1,324 memory LUTs within the 23,774 total. That total also exceeds the device's 20,800 physical LUT capacity by 2,974. Candidate 1 failed earlier at the top telemetry-bundle width gate; candidate 2 fixed that wiring and exposed the separate resource failure. The required roughly 3,390-LUT reduction would entail a substantial architecture redesign beyond this bounded W3 cone. **No candidate 3 was attempted.** The old signed DCP or bitstream cannot replace a missing W3 artifact.

## Archived W4 admission requirements — not executable from this handoff

The sole current endpoint authority is `10.132.1.111:22`. `192.168.1.57`, a historical `xdma0` name and a historical BDF are not live authority. W4 must first confirm current boot identity, FPGA/driver state, PCI IDs and function ownership read-only, then map the dynamic XDMA nodes back to the confirmed BDF and exact approved driver/module identity. Changed boot, driver or FPGA state requires a new classification before any control action. No generic `modprobe xdma`, manual PCI bind, alternate endpoint, surprise reset or recovery is implied.

Only after safe admission, confirm runtime identity using the already-required SCAN1 control scan. Its Bank0/`0xF4` and `0xF5` entries supply device and revision ID; do not add a generic I2C path. The verified historical control plus 25 completed scans each recorded raw `0x00F49005` and `0x00F50105` (ID `0x90`, revision `0x01`, valid, no retry), generations 1–26. The incomplete next scan is excluded. Pinned reference code conditionally classifies this as its `0x90` C-revision/two-port default branch; it does not prove current live identity, camera format or wiring. W4 must compare a fresh raw read with that historical observation and stop on a conflicting or invalid identity.

## Archived A/B proposal — pending a new design and separate W4 approval

If a separately governed future design ever becomes fully qualified, use one qualified binary for all arms. OFF is the reset default; ON is a guarded setting, not a second firmware. The archived bounded proposal is **OFF-1 → ON-1 → OFF-2 → ON-2**, with at most **25 scan admissions per arm** and no make-up admissions to chase a recovered-error count. The second pair would be a repeatability check only if each preceding arm completed safely and W4 explicitly authorized the full sequence. Persist each arm's block ID, effective mode, firmware/source/schema identity, start/end coherence status and raw opportunity ledger. These budgets and order are a planning proposal only, with no W3 authority or statistical power claim.

For each arm, at safe scanner/executor/I2C idle with no pending legacy response or snapshot ownership: stage a unique nonzero block ID, set OFF or ON, arm/lock the block, read back configured and active identity, then verify the effective mode latched at admission. Mid-block configuration, close, clear, unsupported or partial writes must be treated as rejected. An accepted clear is allowed only after the legacy snapshot and W3 record/payload data have been persisted and validated, and it does not release bank-context lockout. Stop on reject-count, status, epoch, revision, sequence, or block-ID incoherence.

Before any permitted ACK_CLEAR or W3 clear, extract and hash the legacy complete-scan snapshot and W3 first/terminal records, latest-scan companions, successful same-kind controls and counters. Use the W3 valid masks and scan-attempt ID for incomplete scans; do not treat an old legacy generation as new publication or a zero after reset as historical absence. Retain raw first-detected cause separately from raw completion/timeout and mapped legacy outcome. Verify the same firmware and unchanged autoinit/table/camera settings across arms.

The ON pause is exactly **18,750 cycles** at 62.5 MHz (300 µs) after a successful scanner-owned `0xFF` bank write and before its existing verification command. This includes all ten successful group selects, three same-bank reselections, and a successful terminal restore in the clean modeled scan. A failed bank write receives no new pause; a later successful cleanup restore does. No other command, retry, timeout, I2C clock or initialization write is changed. The delay cannot retroactively supply an ACK for a write that already failed.

For each arm, use **actual accepted/completed opportunities** as denominators, separated by operation kind and first/retry. Report entry first failures, entry retries and retry outcomes, group select-write failures, group verify transport failures and value mismatches, SCL versus bus-idle timeouts, and restore-write versus restore-verify failures separately. Reconcile complete-scan and incomplete-scan ledgers; do not reduce the comparison to total NACKs or recovered-event count. Compare failed operations with same-kind successful controls and relevant ACK phase, bank/register/group context, wait validity and wait duration. The historical 27/18/6 comparison is conditional reference occurrence alignment, not correct/wrong/missing product settings.

Predefine the W4 comparison before seeing outcomes. A repeatable directional improvement across both OFF/ON pairs is only a candidate for later qualification; adequate no-improvement weakens this tested pause hypothesis; incomplete, contradictory or identity-incoherent data are inconclusive. W3 makes no numerical significance claim. Any inherited hard stop, ownership loss, bank lockout, failed admission, reset, or unsafe state ends the arm safely. A hard failure forbids an automatic next arm without a separately defined safe re-admission decision. There is no automatic cold reset, reprogramming, retry workaround or 10,000-scan waiver.

Camera/MODE1/EQ, DMA and frame capture remain outside this W4 timing comparison as planned. Neither historical ID nor a timing improvement establishes a genuine frame.

## Missing release receipts and hard stop

- `reports/CHANGE_ALLOWLIST_AND_DIFF_REVIEW.md` and `reports/IMMUTABLE_SOURCE_SHA256.json`, plus candidate-2 source/identity report and source remote readback.
- Frozen `contract/W3_CONTRACT.json`, its explanation/hash, `TEST_MATRIX.csv`, selected assertion and waveform receipts, `DELAY_TIMING_PROOF.csv`, and OFF-versus-parent exact-equivalence receipt.
- `RESOURCE_DELTA.csv`, whole-design post-opt/routed/resource/timing/DRC/CDC/bus-skew sign-off receipts, qualified new DCP and independent same-view reopen receipt.
- New firmware public manifest and bitgen receipt **without firmware bytes**, closed-bundle manifest and self-test receipt, private artifact path/hash manifest, `GATE_MATRIX.csv`, `STATE.json`, and evidence index.
- One commit-pinned independent byte/hash readback of each published source and evidence set. Public evidence must exclude private source, DCP, bitstream, driver binary, raw camera data, vendor PDFs, credentials and proprietary archives.

**Current final execution point:** W3 candidate 2 stopped at the post-opt resource gate. The next prerequisite is a separately governed architectural resource redesign and a fresh full W3 build/sign-off. W4 has not begun. No DUT access occurred in this task.
