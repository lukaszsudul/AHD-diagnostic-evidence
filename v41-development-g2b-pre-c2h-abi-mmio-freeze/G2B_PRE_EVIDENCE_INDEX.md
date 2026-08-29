# AHD v41 G2B-PRE Evidence Index

## Result and scope

This directory freezes the implementation-facing C2H transport ABI and G2B
MMIO contract. It contains architecture and interface evidence only. It does
not contain RTL, an XCI, constraints, a Vivado project, a build, host-driver
code, hardware results, or an SSOT update.

`PROJECT_STATE_REV_AT_START = 1`

The contract result is:

- `CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`
- `G2B_MMIO_STATUS = FROZEN`

These are task-local implementation-freeze results. Project truth remains at
revision 1 until an explicitly authorized META transaction applies the
requirements in `G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md`.

## Authoritative source base

| Item | Identity |
|---|---|
| Repository | `lukaszsudul/FPGA_AHD` |
| Accepted branch | `integration/v41-r1i-gen2-g2a` |
| Accepted commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Accepted tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Previous G2B branch | `integration/v41-g2b-onech-c2h` |
| Previous G2B branch head | exact accepted G2A commit; no G2B implementation commit |

The source tree was inspected with read-only Git operations. It was not
checked out, edited, built, synthesized, programmed, or exercised against a
DUT.

## Required evidence inputs

| Evidence input | Immutable path commit | Principal files used | Purpose |
|---|---|---|---|
| `v41-development-g1-integration-architecture` | `f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd` | `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`, `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md`, `V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md`, `V41_G1_CLOCK_RESET_CDC_PLAN.md`, `V41_G1_MMIO_MAP_PLAN.md`, `V41_G2_IMPLEMENTATION_CONTRACT.md`, `V41_G1_HOST_DMA_TEST_ARCHITECTURE.md` | Accepted geometry, channel/ring/scheduler architecture, drop/backpressure/reset obligations, proposed MMIO, and host-facing direction |
| `v41-development-g2a-r1i-gen2-offline-build` | `8d502a3e0a404b73c73af82846d730355288c7b1` | `V41_G2A_IMPLEMENTATION_REPORT.md`, `V41_G2A_STATE.json`, `G2A_C2H_INACTIVE_BOUNDARY_RECEIPT.md`, `build/reports/G2A_BUILD_PROVENANCE.txt` | Accepted G2A identity, full MMIO build provenance, and proof that application C2H remains inactive |
| `v41-development-g2b-one-channel-c2h-offline` | `08a39a0229f27e068a58860c7acf10de9b80c756` | `G2B_BLOCKER_REPORT.md`, `G2B_RECORD_CONTRACT_RECEIPT.md`, `G2B_MMIO_DELTA.md`, `G2B_CDC_RESET_REVIEW.md`, `V41_G2B_IMPLEMENTATION_REPORT.md` | Direct list of unresolved ABI/MMIO decisions and previous hard-stop boundary |
| `project-current-state` | `1d61145ebd0b35e517329f1a1bbd608d0e4f4e71` | `README.md`, `GOVERNANCE.md`, `UPDATE_POLICY.md`, `PROJECT_STATE.json`, `TRACK_STATUS.json`, `CURRENT_INTERFACES.md`, `CURRENT_REQUIREMENTS.md`, `COMPATIBILITY_MATRIX.csv`, `OPEN_DECISIONS.md`, `CHANGELOG.md`, `EVIDENCE_MAP.md` | Revision 1, provisional-interface state, immutable compatibility boundary, and later META procedure |
| Accepted FPGA source | `224d194e5f82c85bcb29297561c5d5e76d28063b` | `docs/RECORD_PROTOCOL.md`, `docs/v41/phase3/AXI_LITE_REGISTER_MAP.md`, `rtl/record/bt656_record_producer.sv`, `rtl/v41/control_status_regs.sv`, `rtl/pio/pio_bar_target.sv`, `rtl/top/ahd_capture_top_xdma.sv` | Existing record flag/source semantics, authoritative legacy build identity, and static MMIO collision review |

Evidence gaps identified by those inputs are resolved by the decision log;
they are not represented as facts already frozen by G1.

## Output artifacts

| Artifact | Role |
|---|---|
| `V41_G2B_PRE_ARCHITECTURE_FREEZE_REPORT.md` | Main engineering-gate report and acceptance matrix |
| `V41_C2H_TRANSPORT_ABI_V1.md` | Normative human-readable record/stream ABI |
| `V41_C2H_TRANSPORT_ABI_V1.json` | Normative machine-readable ABI |
| `V41_G2B_MMIO_CONTRACT.md` | Normative MMIO behavior and register semantics |
| `V41_G2B_MMIO_MAP.csv` | Machine-readable register/bit map |
| `V41_C2H_LINUX_CONSUMER_CONTRACT.md` | Transport-facing Linux handoff; not a V4L2 driver design |
| `G2B_PRE_ABI_CONSISTENCY_REPORT.md` | Static geometry, field, alignment, and overlap validation result |
| `validate_g2b_pre_contract.py` | Repeatable static validator used to produce the consistency result |
| `G2B_PRE_DECISION_LOG.md` | Prior open question to final decision traceability |
| `G2B_PRE_STATE.json` | Machine-readable gate state and non-execution declarations |
| `G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md` | Exact later META transaction requirements; not an SSOT edit |
| `G2B_PRE_EVIDENCE_INDEX.md` | This provenance and artifact index |
| `G2B_PRE_SHA256_MANIFEST.txt` | SHA-256 binding for every other published file in this directory |

## Precedence and interpretation

The Markdown ABI and MMIO contracts are normative prose. The ABI JSON and
MMIO CSV are normative machine representations of the same contracts. A
difference between representations is a validation failure and must be fixed
before implementation; an implementation agent may not choose between them.

Legacy v40B PIO and all MMIO through `0x37FF` remain immutable. Freezing a
future v41D C2H contract does not advertise it in the current G2A build and
does not change the legacy `PROTOCOL=0x0000400B` identity.

## Publication binding

The first ordinary publication commit contains the sealed payload with the
required commit subject at
`9fdcca4e3a40b931f07db01ad404b4a3cfc24b10`. Remote `main` and its tree were
read back and matched that payload exactly. This evidence-only closure records
that **PASS** result without changing any contract value. The final closure
commit is the remote HEAD containing `G2B_PRE_STATE.json`; its exact SHA is
supplied by the final remote read-back and task response, avoiding impossible
Git self-reference.
