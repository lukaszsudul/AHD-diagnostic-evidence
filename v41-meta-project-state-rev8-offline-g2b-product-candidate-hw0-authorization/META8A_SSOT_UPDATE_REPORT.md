# AHD v41 META-8A Offline-Qualified PRODUCT Candidate Promotion and Hardware-Test Authorization

Executing role: META_UPDATE_AGENT. Authorization: SSOT WRITE AUTHORIZED.
Update type: TRACK_GATE_ACCEPTANCE. Authorized revision transition: 7 → 8.

## Decision and exact candidate

## Accepted offline G2B PRODUCT test candidate — META-8A

G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.

| Candidate binding | Exact value |
|---|---|
| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Runtime BUILD_FLAGS | `0x00000103` |
| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |

The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.

R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.

G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).

Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.


## Accepted offline evidence

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.


## Verification and exact scope

Recovery-4 `6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4` verified at the immutable commit, reachable from evidence main `c231e1e575295638e3bd20ef8c942fcb7fd90408`. All 181 manifest entries match exact Git bytes. Both local artifacts have exact requested sizes/hashes. Source branch publication resolves exactly to `92e9b3d914134c044371779def1ee18eaaeda98a`; the source commit's tree is `cf6bf82249c90782eab1978c68541ed9c0e6430b`. FPGA xc7a35tcsg325-2; Vivado 2025.2 software build 6299465; PRODUCT debug probes NONE_EXPECTED_PRODUCT_PROFILE. No Vivado command was executed by META-8A.

Mandatory SSOT files were read in the frozen order. TRACK_GATE_ACCEPTANCE is supported by UPDATE_POLICY.md and appropriate for accepting an offline engineering gate and authorizing its next gate without replacing R1i. The exact supplied write contract is retained in META8A_WRITE_CONTRACT_RECEIPT.md. The expected-file contract, with all prior SHA-256 values and field/section reasons, was created before SSOT mutation.

Local engineering/consistency validation: PASS, 358 assertions. Exactly 16 authorized SSOT files change. The complete 19-file SSOT snapshot is included under project-current-state/. Governance changes only its governed-revision metadata; version/policy/schema/template remain unchanged. Changelog old bytes remain exact, with one revision-8 entry. All 18 SSOT manifest entries verify. Exact file ledger and textual diff accompany this report.

R1i identity, qualified PoC evidence, protected behavior, donor identities, G2A gate, R-track HOLD and Linux-track planned states remain preserved. All promoted Group-9 and Groups 13–17 normative methods and family bounds remain exact. Historical pending claims are explicitly historical; current candidate absence/final-sign-off blockers are removed. Registered OD entries stay open: new PRODUCT evidence updates OD-05/11/12/13 descriptions without inventing paired-profile, runtime, or hardware resolution. The offline candidate acceptance is an unnumbered governed decision.

DIAG0 commit c231e1e575295638e3bd20ef8c942fcb7fd90408 was read for context only. Its blocked universal diagnostic architecture and 0x3C00..0x3FFF MMIO are not promoted. The old synthetic HW0 plan is inspected as evidence history, not adopted; META8A_HW0_PRODUCT_GATE_CONTRACT.md defines the authorized fixed live-path scope.

## Execution protection and publication transaction

Source worktrees, source branch and active XDC are read-only throughout META-8A; exact bitstream/DCP are unchanged. No source commit, release branch/tag/release, JTAG, FPGA programming, PCIe access, DMA, driver operation, reboot or power-cycle. Primary worktree pre-existing untracked .codex_tmp/ and reports/ and evidence .diag0-work/ are preserved and excluded from publication.

One ordinary evidence commit to lukaszsudul/AHD-diagnostic-evidence main, without force, contains this package and the 16-file SSOT transaction. Before mutation and publication, recheck revision/base/remote identity; stop on concurrency or non-fast-forward. Publication commit and read-back are necessarily post-commit executor completion data. This immutable payload records local validation and does not claim a future remote PASS or predict its own SHA. Final task response and local .meta8a-work/META8A_REMOTE_READBACK.json record the resulting commit, remote HEAD, byte/SHA-256 comparisons of every SSOT and package file and final result after read-back. No overall PASS is declared before that check.

SSOT staleness classification: NO_IMPACT / AUTHORIZED_SELF_UPDATE for the authorized 7 → 8 transition only. No other transition or merge is permitted.

Recommended next step after confirmed publication: G2B-HW0-PRODUCT — Exact Candidate Live-Path Bring-Up, in a separate governed task with exact operational authorization.

Final execution point: HARD STOP AFTER META-8A SSOT PROMOTION.
