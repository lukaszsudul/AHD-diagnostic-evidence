# AHD v41 G1 Evidence Index

## Gate identity

- Task: `AHD_V41_G1_INTEGRATION_ARCHITECTURE`
- Date: 2026-08-27
- Engineering gate: `PASS`
- Gen2 repository-only feasibility: `G2_IMPLEMENTATION_ALLOWED`
- Recommended next gate structure: `G2A+G2B`
- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence directory: `v41-development-g1-integration-architecture`
- Origin main before G1 publication: `b5efb25082d7d18c8e022142e2303fd8a7bc3c6d`
- G1 architecture payload commit: `221f65aef9664a6d6ad35c3ec7644badd69ba381`

The payload commit is recorded in `V41_G1_STATE.json`. The following receipt commit adds this index, state, and manifest; the verified remote `main` head is the publication commit reported at handoff. A manifest cannot include its own digest and therefore explicitly excludes itself.

## Frozen source identities

| Role | Identity |
|---|---|
| Qualified R1i | `baseline/v41-r1i-qualified-poc`; commit `20c3323d79d3896edc586d6db1df7deee60f9e41`; tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`; tag `v41-r1i-qualified-poc-20260827` |
| Qualified bitstream | SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| Primary XDMA donor | `v41/xdma-v40.1.0-base`; `c89e88bcdf389614c884fb129e8b2d42a585bccb`; tag `v41-xdma-primary-donor-g0-20260827` |
| Secondary donor | `dev/v41-xdma-offline-next`; `8464af66611f7c22b8a36a4aab915d598eedda3f`; provenance hardening only |

Read-only ancestry and blob inspection established primary donor → secondary donor → qualified R1i ancestry. The qualified R1i tree is therefore the exact future base; no synthetic donor/R1i merge was performed in G1.

## Authoritative input evidence

| Evidence | Use in G1 |
|---|---|
| [`v41-development-g-minus-1-existing-work-inventory`](../v41-development-g-minus-1-existing-work-inventory/) | Existing-work inventory, branch graph, IP/script/XDC/test inventories, conflict matrix, data-plane and reuse evidence |
| [`V41_G0_BASELINE_FREEZE_REPORT.md`](../v41-development-g0-baseline-freeze/V41_G0_BASELINE_FREEZE_REPORT.md) | Accepted baseline, product requirements, donor selection, G1 entry contract |
| [`V41_G0_INTEGRATION_CONFLICT_REGISTER.csv`](../v41-development-g0-baseline-freeze/V41_G0_INTEGRATION_CONFLICT_REGISTER.csv) | Five integration hotspots |
| [`V41_R1I_PROTECTED_BEHAVIOR_CONTRACT.md`](../v41-development-g0-baseline-freeze/V41_R1I_PROTECTED_BEHAVIOR_CONTRACT.md) | R1i behavioral and MMIO preservation boundary |
| [`V41_XDMA_DONOR_RECEIPT.md`](../v41-development-g0-baseline-freeze/V41_XDMA_DONOR_RECEIPT.md) | Primary/secondary donor identities and roles |
| [`V41_PCIE_GEN2_FEASIBILITY_AUDIT.md`](../v41-development-g0-baseline-freeze/V41_PCIE_GEN2_FEASIBILITY_AUDIT.md) | Starting Gen2 board/repository evidence |
| [`V41_288MBPS_ACCEPTANCE_CONTRACT.md`](../v41-development-g0-baseline-freeze/V41_288MBPS_ACCEPTANCE_CONTRACT.md) | Frozen 288 MB/s payload semantics |
| [`v41-nvp-r1i-r2-qualified-poc-hardware-evidence`](../v41-nvp-r1i-r2-qualified-poc-hardware-evidence/) | Qualified R1i source/bitstream/provenance/hardware/build evidence |
| [`v41-research-r0-r1i-causal-isolation-design`](../v41-research-r0-r1i-causal-isolation-design/) | Diagnostic-retention and experiment-semantics context only; G1 does not depend on an R1 outcome |

Resource decomposition also used the public R1h/R1g evidence named in `V41_G1_RESOURCE_DECOMPOSITION.md`. The absence of a qualified-R1i hierarchical report is itself recorded evidence and is why exact removable LUT cost remains `UNKNOWN`.

## Required artifact catalogue

| Artifact | Purpose |
|---|---|
| `V41_G1_ARCHITECTURE_REPORT.md` | Main 21-section architecture decision and G1 disposition |
| `V41_G1_CONFLICT_RESOLUTION_PLAN.csv` | Exact five-hotspot authority/merge/verification rules |
| `V41_G1_GEN2_XDMA_CHANGE_PLAN.md` | Exact XCI/Tcl delta, invariant properties, clocks, resets, host impact |
| `V41_G1_GEN2_HARDWARE_FEASIBILITY.md` | Repository-only lane/refclock/PERST/board feasibility decision |
| `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md` | Record/ring/AXIS/backpressure/error/reset architecture |
| `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md` | G6 one-channel FPGA/host record contract |
| `V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md` | Alternatives and frozen one-C2H/private-ring/scheduler model |
| `V41_G1_THROUGHPUT_BUDGET.md` | Quantitative 288 MB/s efficiency and sensitivity budget |
| `V41_G1_RESOURCE_DECOMPOSITION.md` | Product/diagnostic decomposition with evidence classifications |
| `V41_G1_DIAGNOSTIC_REDUCTION_PLAN.md` | Keep/remove lifecycle after R-track closure |
| `V41_G1_RESOURCE_HEADROOM_POLICY.md` | Development/release utilization, timing, and congestion limits |
| `V41_G1_CLOCK_RESET_CDC_PLAN.md` | Domain, CDC, reset, epoch, and NVP-independence plan |
| `V41_G1_MMIO_MAP_PLAN.md` | Protected ranges and proposed disjoint DMA pages |
| `V41_G1_HOST_DMA_TEST_ARCHITECTURE.md` | Correctness, sequence, capture, throughput, and soak tooling design |
| `V41_G2_IMPLEMENTATION_CONTRACT.md` | Atomic G2A/G2B work packages P1–P12 and hard stops |
| `V41_G1_G2_ENTRY_CHECKLIST.md` | Mandatory entry conditions and blockers |
| `V41_G1_STATE.json` | Machine-readable gate/publication state |
| `V41_G1_EVIDENCE_INDEX.md` | Evidence and artifact provenance index |
| `V41_G1_SHA256_MANIFEST.txt` | SHA-256 integrity list for every other G1 artifact |

## Read-only inspection scope

The audit read frozen Git commits/trees/blobs and existing documentation, reports, XCI, Tcl, top-level RTL, XDC, host procedures, register logic, record format, and tests. It used Git, text search, CSV/JSON parsing, and SHA-256 calculation. It did not run Vivado, compile, elaborate, synthesize, implement, generate a bitstream, install/modify drivers, or access hardware.

No RTL, XCI, XDC, build script, source branch, or source worktree was modified. All G1 output was created in an isolated evidence-repository clone and contains architecture/evidence only; no proprietary source tree or secret is published.

## Publication and read-back contract

1. Fetch and record `origin/main`.
2. Confirm no unrelated evidence-repository modification.
3. Commit the 16 architecture artifacts as `Publish AHD v41 G1 integration architecture`.
4. Add the machine state, evidence index, and self-excluding SHA-256 manifest in a receipt commit.
5. Fetch again, require a fast-forward push to `origin/main`, and never force.
6. Clone/read the remote head independently with LF-normalized repository content, verify all 19 required names, validate JSON/CSV, and recompute every manifest entry.
7. Recheck that the FPGA source repository is clean.

The handoff reports the final remote head and remote read-back result. G1 ends with a hard stop; no G2 action is authorized by publication alone.
