# AHD v41 G2B-LUT1 Sign-Off Recovery 2 Evidence Index

## Package state

| Field | Value |
|---|---|
| Evidence directory | `v41-development-g2b-lut1-signoff-recovery-2` |
| Engineering gate | `BLOCKED` |
| First blocker | `REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE` |
| Pre-bitstream hard gate | `FAIL` |
| Bitstream / LTX | `NOT PRODUCED / NOT PRODUCED` |
| Hardware accessed | `NO` |
| Evidence commit | `CONTAINING_GIT_COMMIT` |
| Remote read-back | Required after push; recorded in the execution response |

This package closes recovery-2 at the governed Group-14 timeout. `PRESENT`
means the artifact belongs to this directory. `RAW` means direct tool or
supervisor output. `TOOL` means executable provenance and does not by itself
claim execution or a passing result. `NOT_REACHED` is a fail-closed release
state, not a historical substitution.

## Primary governed artifacts

| Artifact | Status | Purpose |
|---|---|---|
| `V41_G2B_LUT1_SIGNOFF_RECOVERY2_REPORT.md` | PRESENT | Main blocked engineering report |
| `G2B_LUT1_RECOVERY2_AUTHORITY_RECEIPT.md` | PRESENT | SSOT revision 5, META-5, META-4R2, and G13-A authority |
| `G2B_LUT1_RECOVERY2_XDC_DIFF.md` | PRESENT | Group-13-only XDC scope proof |
| `G2B_LUT1_RECOVERY2_SOURCE_CHANGE_RECEIPT.md` | PRESENT | Governed source parent, commit, tree, and exact active-XDC identity |
| `G2B_LUT1_RECOVERY2_MODE_DECISION.md` | PRESENT | Routed-DCP reuse decision and no-rebuild boundary |
| `G2B_LUT1_RECOVERY2_PRESERVED_RESULTS.txt` | PRESENT | Hash-bound Group-9 and Groups 10-12 preserved results |
| `G2B_LUT1_GROUP13_SIGNOFF_RESULTS.csv` | PRESENT | Fresh two-family Group-13 replacement results |
| `G2B_LUT1_GROUP13_GATE.txt` | PRESENT | Group-13 promoted-method gate receipt |
| `G2B_LUT1_GROUPS14_17_RESULTS.csv` | PRESENT | Group-14 timeout and Groups 15-17 stop ledger |
| `G2B_LUT1_GROUPS14_17_GATE.txt` | PRESENT | Aggregate Groups 14-17 fail and exact first blocker |
| `G2B_LUT1_GROUPS14_17_COLLECTION_COUNTS.txt` | PRESENT | Fresh Group-14 56/20 inventory and governed-but-not-run Group 15-17 cardinalities |
| `G2B_LUT1_RECOVERY2_POST_TIMEOUT_AUDIT.txt` | PRESENT | Source/DCP revalidation, zero residual Vivado processes, and no-output audit |
| `G2B_LUT1_OFFLINE_PROTECTION_GATE_RECOVERY2.txt` | PRESENT | ABI/MMIO/G2B/R1i/XDMA protection gate |
| `G2B_LUT1_RECOVERY2_THROUGHPUT_SUMMARY.md` | PRESENT | Governed 288 MB/s offline capacity gate |
| `G2B_PRE_BITSTREAM_HARD_GATE_RECOVERY2.txt` | PRESENT; FAIL | Machine-readable pre-bitstream eligibility decision |
| `G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json` | PRESENT; no candidate | Hash-bound no-product-candidate record |
| `G2B_LUT1_RECOVERY2_STATE.json` | PRESENT | Machine-readable terminal state and publication convention |
| `G2B_LUT1_RECOVERY2_PUBLICATION_SANITIZATION_RECEIPT.md` | PRESENT | Binary/secret/reparse publication boundary |
| `G2B_LUT1_RECOVERY2_EVIDENCE_INDEX.md` | PRESENT | This evidence map |
| `G2B_LUT1_RECOVERY2_SHA256_MANIFEST.txt` | PRESENT AT PUBLICATION | SHA-256 inventory of every other published package file |

## Exact identity anchors

| Anchor | Identity |
|---|---|
| SSOT revision | `5` at start and end |
| META-4R2 evidence commit | `27dcf152e862c6db88a365328b92c0fd250f04c2` |
| META-5 promotion/evidence commit | `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314` |
| G13-A evidence commit | `10c7c2898d162af8e2262b3f99861c7d560c4557` |
| Source parent | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Source commit | `64feb60de5d07f400e6b92527bfe54838b3372ee` |
| Source tree | `26399ed456941e26d5ee4b1b2ca50392338fa24a` |
| Active XDC SHA-256 | `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C` |
| G13-A candidate XDC SHA-256 | `E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312` |
| Routed DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Recovery mode | `ROUTED_DCP_REUSE` |
| Vivado / device | `2025.2`, SW build `6299465` / `xc7a35tcsg325-2` |

## Raw Group-13 provenance

Directory: `raw/group13_fresh/`

The raw directory contains checkpoint/version/route receipts, applied
constraint context, exact family and supplemental results, path properties,
focused methodology output, query markers, watchdog receipt, warnings, and
the Vivado transcript. The governing gate binds these results:

| Semantic family | Required | Worst actual | Slack | Result |
|---|---:|---:|---:|---|
| `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` | 6.000 ns | 2.634 ns | 3.467 ns | PASS |
| `RESET_COMMIT_PHASE_COMPLETION_BARRIER` | 6.000 ns | 3.756 ns | 1.723 ns | PASS |

Supplemental 79-cell aggregate coverage is PASS and is explicitly not a third
semantic family. `GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = NO`.

## Raw Groups 14-17 provenance

Directory: `raw/groups14_17/`

`PREFLIGHT.txt` binds the promoted constraint context, fresh Group-13 PASS,
clean source identity, exact DCP, single-attempt policy, and 300-second
per-query watchdog. Under
`group_14_RELEASE_SLOT_0_AXI_TO_SOURCE/`, the query-start marker, watchdog,
group disposition, object inventory, contexts, warnings, logs, and launch
command establish:

- one Group-14 attempt;
- `301.299 s` measured from the query-start marker;
- no validated query-completion marker;
- required result
  `REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE`;
- no retry; and
- Groups 15-17 not run after the blocker.

No Group-14 worst actual or slack is claimed because the required query did
not complete.

## Fail-closed downstream artifacts

| Artifact | Status |
|---|---|
| `G2B_LUT1_RECOVERY2_TIMING_SUMMARY.md` | PRESENT; `NOT_REACHED`; WNS/TNS/WHS/THS N/A |
| `G2B_LUT1_RECOVERY2_DRC_SUMMARY.md` | PRESENT; `NOT_REACHED` |
| `G2B_LUT1_RECOVERY2_CDC_DISPOSITION.md` | PRESENT; whole-design gate `NOT_REACHED`; ownership/reset-return targeted proofs PASS |
| `G2B_LUT1_RECOVERY2_CLOCK_SUMMARY.md` | PRESENT; `NOT_REACHED`; effective clocks N/A |
| `G2B_LUT1_RECOVERY2_RESOURCE_SUMMARY.md` | PRESENT; `NOT_REACHED`; PRODUCT LUT gate not established |

The finalizer was not launched, its output directory does not exist, and no
bitstream or LTX was produced. No historical result is substituted for a
required fresh downstream result.

## Tool provenance

Files under `tools/` preserve the Group-13 runner/worker, Groups 14-17
runner/worker, and prepared routed finalizer. The Group-13 tools executed once
and passed. The Groups 14-17 tools executed through the single Group-14
attempt and then stopped. The prepared finalizer did not execute.

## Integrity and publication convention

`G2B_LUT1_RECOVERY2_SHA256_MANIFEST.txt` intentionally excludes itself. The
state and candidate-identity files use `CONTAINING_GIT_COMMIT` because
embedding the containing commit's SHA into that same commit would be
self-referential. The exact commit and remote branch-head equality are
reported after the ordinary non-force push and independent remote read-back.
