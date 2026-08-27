# AHD v41 R1 Evidence Index

## Gate and narrative reports

| Artifact | Purpose |
|---|---|
| `README.md` | Entry point and terminal R1 result |
| `R1_IMPLEMENTATION_REPORT.md` | Overall contract, implementation and gate result |
| `R1_CANDIDATE_A_REPORT.md` | C1 source semantics, tests and build result |
| `R1_CANDIDATE_B_REPORT.md` | C2 source semantics, tests and build result |
| `R1_CANDIDATE_COMPARISON.md` | C3/C1/C2 timing, utilization, clock, I/O, DRC and provenance comparison |
| `R1_OFFLINE_TEST_REPORT.md` | Inherited, candidate-specific, MMIO and host-fixture evidence |
| `R1_BUILD_REPORT.md` | Clean-flow environment, hard gates, artifacts and process accounting |
| `R1_SOURCE_DIFF_AUDIT.md` | Ancestry, allowlist, frozen-file, state/fanout and cross-contamination audit |
| `R1_RUNTIME_IDENTITY_REPORT.md` | Frozen MMIO identity mechanism and build-time candidate binding |
| `R1_STATE.json` | Machine-readable terminal R1 state |
| `R1_SHA256_MANIFEST.txt` | SHA-256 for every published payload other than the manifest itself |

## Source evidence

- `R1I_A_SOURCE_DIFF.patch` and `R1I_B_SOURCE_DIFF.patch`: complete full-index unified diffs.
- `R1I_A_FROZEN_FILE_VERIFICATION.txt` and `R1I_B_FROZEN_FILE_VERIFICATION.txt`: 231/231 byte-identical frozen-file records, ancestry, name-only/stat/check results.
- `provenance/R1_SOURCE_SEMANTIC_AUDIT.txt`: state order/encoding, protected-body hashes, fanout, intentional-control hashes, cross-contamination and functional-hunk-to-clause map.
- `provenance/R0_CONTRACT_VERIFICATION.txt`: accepted R0 evidence and qualified-base receipt.
- `provenance/BUILD_FLOW_RECEIPT.txt`: canonical/adapted flow hashes and frozen commands.
- `provenance/PROTECTED_WORKTREE_FINAL_VERIFICATION.txt`: final primary/baseline/candidate Git identities and clean status.
- `provenance/HARDWARE_NONACCESS_DECLARATION.txt`: explicit offline-only boundary.

## Offline tests

`offline_tests/candidate_a` contains the final focused receipt, C1-aware inherited lifecycle, directed C1 simulation logs/traces, MMIO receipts/logs, 40-test host receipt, source tests, and a 14/14 payload manifest.

`offline_tests/candidate_b` contains static 10/10 contract evidence, endpoint-HIGH/LOW simulation logs, the environment-stamped inherited suite, three MMIO simulation groups, 40-test host evidence, and a detailed index.

Simulator work databases, WDB files, compiled work directories, backups and superseded development attempts are excluded.

## Candidate build evidence

`builds/candidate_a` and `builds/candidate_b` each contain:

- the Git-LFS-managed `.bit` payload;
- Vivado log, journal and direct process stdout/stderr where present;
- invocation, input hash, build provenance, operation counts and terminal result;
- post-synthesis/post-opt/final utilization and resource gates;
- timing summary, route status, DRC, CDC, hierarchy and compile-order reports;
- pre-bitstream hard-gate receipt;
- LTX/probe status receipt;
- per-build artifact SHA-256 manifest;
- independent post-build audit.

Candidate A manifest validation is 24/24 and Candidate B is 23/23. Routed/synthesis checkpoints remain preserved in the isolated local build roots but are omitted from this public evidence package.

The canonical MMIO/BRAM instrumentation flow has no debug-probe or LTX generation command. Accordingly no `.ltx` exists; each candidate's `LTX_PROBE_STATUS.txt` records `NOT_PRODUCED_NOT_REQUIRED_BY_CANONICAL_FLOW`.

`builds/PRE_PROJECT_LAUNCH_INCIDENT_RECEIPT.txt` records the contained, quarantined pre-project Candidate B wrapper race. It is not a valid design build.

## Publication

Repository: `lukaszsudul/AHD-diagnostic-evidence`  
Branch: `main`  
Directory: `v41-research-r1-r1i-causal-candidates`

The public package contains no proprietary full source tree, secret, token, private key, hardware capture or DUT access record.
