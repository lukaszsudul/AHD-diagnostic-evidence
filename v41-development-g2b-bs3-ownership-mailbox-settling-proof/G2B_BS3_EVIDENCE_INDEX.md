# G2B-BS3 Evidence Index

## Gate identity

- Gate: `G2B-BS3 — Ownership Mailbox Settling Bounds and Structural CDC Proof`
- Authoritative project state at start/end: `PROJECT_STATE_REV = 3`
- Predecessor evidence commit: `4699632c591238fee46ada3b0de37532fddd0b6f`
- Sealed routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Validation run: successful bounded `run_validate_all_r3` only
- `report_bus_skew` attempt count: `0`

## Primary qualification artifacts

| Artifact | Purpose |
|---|---|
| `V41_G2B_BS3_MAIN_REPORT.md` | Engineering decision, evidence synthesis, methodology results, runtime, and final dispositions |
| `G2B_BS3_OWNERSHIP_PROTOCOL_MODEL.md` | Actual request/payload/ack protocol and control-versus-stable-data distinction |
| `G2B_BS3_CDC_INVARIANTS.md` | Functional safety invariants and proof classifications |
| `G2B_BS3_STRUCTURAL_CDC_PROOF.md` | RTL/netlist structural proof, reset/epoch analysis, and focused CDC disposition |
| `G2B_BS3_PAYLOAD_FAMILIES.csv` | Exact 58-source decomposition into slot, generation, and epoch families |
| `G2B_BS3_PROTOCOL_TIMING_MARGIN.md` | Clock/stage derivation, 13.468 ns theoretical window, 6.000 ns cap, and safety reserve |
| `G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc` | Isolated declarative three-family max-delay candidate; zero ownership bus-skew commands |
| `G2B_BS3_CONSTRAINT_DIFF.md` | Old global bus-skew versus new semantic settling strategy |
| `G2B_BS3_FAMILY_TIMING_RESULTS.csv` | Routed per-family requirement, worst-slack-path datapath delay, slack, and result |
| `G2B_BS3_REQUEST_ACK_SEQUENCE_PROOF.md` | Edge-by-edge normal, failure, and reset-overlap sequence proof |
| `G2B_BS3_RECOMMENDED_SIGNOFF_RECIPE.md` | Fail-closed future G2B sign-off procedure |
| `G2B_BS3_STATE.json` | Machine-readable gate state and decisions |
| `G2B_BS3_SHA256_MANIFEST.txt` | SHA-256 integrity inventory for every other published file |

## Supporting analysis

| Artifact | Purpose |
|---|---|
| `G2B_BS3_BASE_XDC_PRESERVATION.md` | Proof that the temporary base preserves unrelated constraints and omits only old Group 9 |
| `G2B_BS3_CANDIDATE_STRATEGY_EVALUATION.md` | Candidate A–F comparison, proven property, exclusions, runtime, and false-confidence risk |
| `G2B_BS3_EXCEPTION_EFFECTIVENESS.md` | Coverage and equal-value overlap disposition |
| `G2B_BS3_MUTATION_AUDIT.md` | Source/active-XDC/index/branch/SSOT/hardware protection audit |

## Raw routed-validation evidence

All files under `validation/` are copied from the successful supervised r3 run, plus the exact executed harness and temporary base XDC. No failed or exploratory run is published.

| Evidence group | Files |
|---|---|
| External supervision | `G2B_BS3_EXTERNAL_WATCHDOG.txt`, `G2B_BS3_LAUNCH_COMMAND.txt`, `QUERY_STARTED.marker`, `WORKER_STARTED.marker`, `WORKER_COMPLETED.marker` |
| Fail-closed receipts | `G2B_BS3_EXACT_IDENTITY_RECEIPT.txt`, `G2B_BS3_TIMING_RESULT_GATE_RECEIPT.txt` |
| Exact object inventories | `G2B_BS3_OBJECT_INVENTORY.txt`, `G2B_BS3_SYNCHRONIZER_INVENTORY.txt`, three source lists, and the 17-cell destination list |
| Per-family timing | Three `*_TIMING_RESULT.txt` summaries, three `*_WORST_PATH.rpt` reports, and their completion markers |
| Methodology | Full-context and candidate-isolated timing-methodology reports and completion markers |
| Exception validation | Candidate coverage/ignored reports and completion markers |
| Constraint provenance | `G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc`, `G2B_BS3_APPLIED_CONSTRAINTS.xdc`, and `G2B_BS3_EXECUTED_WORKER.tcl` |
| Reproducibility harness | `Invoke-G2BBs3Worker.ps1`, `Test-G2BBs3ExactIdentity.ps1`, `Test-G2BBs3TimingResults.ps1` |
| Tool transcript | `G2B_BS3_CONSOLE.log`, empty stderr log, `G2B_BS3_VIVADO.log`, and `G2B_BS3_VIVADO_VERSION.txt` |

The external receipt records a 300-second per-query watchdog, successful exit, no timeout, zero post-existing Vivado processes, exact DCP/base/candidate hashes, and zero `report_bus_skew` attempts. The exact-identity receipt proves the 2/24/32 source families, 17 destinations, two request plus two ack synchronizer stages, and 16.000/6.734 ns clock periods. The timing gate receipt proves all three 6.000 ns datapath-only checks and candidate methodology `Checks found: 0`.
