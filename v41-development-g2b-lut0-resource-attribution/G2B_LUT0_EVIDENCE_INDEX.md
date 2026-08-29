# G2B-LUT0 Evidence Index

## Scope

Analysis-only/offline-only resource attribution and diagnostic de-instrumentation plan. No RTL, source branch, SSOT, DUT or hardware state was changed. No bitstream was produced.

## Package files

| File | Purpose |
|---|---|
| `V41_G2B_LUT0_ARCHITECTURE_REVIEW.md` | main findings, normalized attribution and engineering verdict |
| `G2B_LUT0_HIERARCHICAL_RESOURCE_MAP.csv` | comparable post-opt hierarchy map |
| `G2B_LUT0_FILE_RESOURCE_MAP.csv` | source/file mapping with exact versus estimated labels |
| `G2B_LUT0_RTRACK_INSTRUMENTATION_INVENTORY.md` | history, purpose, consumers, lifecycle and reversible restoration |
| `G2B_LUT0_G2B_COST_BREAKDOWN.md` | G2B core/XDMA/integration and counter/snapshot decomposition |
| `G2B_LUT0_BRAM_PACKING_REVIEW.md` | four-slot inference, efficiency, port and spill review |
| `G2B_LUT0_BUILD_PROFILE_PROPOSAL.md` | PRODUCT/RESEARCH_DIAGNOSTIC strategy and minimum observability |
| `G2B_LUT0_DEINSTRUMENTATION_PLANS.md` | ranked Plan A/B/C recovery and risk |
| `G2B_LUT0_RECOMMENDED_PLAN.md` | exact future G2B-LUT1 actions and verification |
| `G2B_LUT0_RESOURCE_TARGETS.md` | exact 100/95/90/85/80% arithmetic |
| `G2B_LUT0_VIVADO_ANALYSIS_RECEIPT.md` | read-only DCP query provenance |
| `G2B_LUT0_SSOT_IMPACT.md` | revision/state non-impact and governance blocker |
| `G2B_LUT0_STATE.json` | machine-readable gate state |
| `G2B_LUT0_SHA256_MANIFEST.txt` | package content integrity |

## Primary resource evidence

| Evidence | Use |
|---|---|
| `../v41-development-g2a-r1i-gen2-offline-build/build/reports/ROUTED_UTILIZATION_HIER.rpt` | accepted routed G2A 18,178-LUT hierarchy |
| `../v41-development-g2a-r1i-gen2-offline-build/build/reports/POST_OPT_UTILIZATION_HIER.rpt` | comparable G2A post-opt 18,569-LUT hierarchy |
| `../v41-development-g2a-r1i-gen2-offline-build/build/reports/POST_OPT_UTILIZATION_FLAT.rpt` | G2A primitive totals |
| `../v41-development-g2a-r1i-gen2-offline-build/build/reports/RAM_UTILIZATION.rpt` | memory primitive placement |
| `../v41-development-g2a-r1i-gen2-offline-build/build/reports/G2A_DEBUG_PROBES_RECEIPT.txt` | no active `.ltx`/debug probe payload |
| `../v41-development-g2b-one-channel-c2h-implementation-offline/POST_OPT_UTILIZATION_HIER.rpt` | blocked G2B 21,412-LUT hierarchy |
| `../v41-development-g2b-one-channel-c2h-implementation-offline/POST_OPT_UTILIZATION_FLAT.rpt` | G2B primitive totals |
| `../v41-development-g2b-one-channel-c2h-implementation-offline/G2B_IMPL_BUILD_RESOURCE_REPORT.md` | published blocker and provenance |
| `../v41-development-g1-integration-architecture/V41_G1_RESOURCE_DECOMPOSITION.md` | accepted diagnostic-island bounds and mixed-cost cautions |
| `../v41-development-g1-integration-architecture/V41_G1_DIAGNOSTIC_REDUCTION_PLAN.md` | protected behavior, minimum observability and reduction governance |

## Contract/state authority

| Evidence | Use |
|---|---|
| `../project-current-state/PROJECT_STATE.json` | revision 2, accepted base, NOT_IMPLEMENTED state and diagnostic-reduction condition |
| `../project-current-state/CURRENT_RESOURCE_STATE.md` | accepted resource interpretation |
| `../project-current-state/OPEN_DECISIONS.md` | diagnostic reduction remains open |
| `../v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_MMIO_CONTRACT.md` | frozen G2B counters/snapshot/capability semantics |
| `../v41-development-g2b-pre-c2h-abi-mmio-freeze/` | frozen AHD_C2H_TRANSPORT_ABI_V1 and four-slot architecture authority |

## Source/history authority

Read-only source analysis used the accepted G2A commit and the sealed G2B snapshot under `C:/FPGA/V41_G2B`. Principal files were:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd`
- `rtl/nvp/nvp6134c_autoinit.vhd`
- `rtl/nvp/r1f_transaction_serial_counter.vhd`
- `rtl/top/ahd_capture_top_xdma.sv`
- `rtl/v41/nvp_i2c_tri_phase_probe.sv`
- `rtl/v41/r1h_probe_index_bram_store.sv`
- `rtl/v41/r1f_failed_txn_logger.sv`
- `rtl/v41/r1h_mmio_read_service.sv`
- `rtl/v41/r1f_measurement_regs.sv`
- `rtl/v41/r1e_measurement_regs.sv`
- `rtl/v41/axi_clock_lifecycle_monitor.sv`
- `rtl/v41/axi_lite_host_bridge.sv`
- `rtl/v41/control_status_regs.sv`
- `rtl/g2b/v41_g2b_onech_c2h.sv`
- `rtl/g2b/v41_g2b_mmio_router.sv`
- `ip/v41/xdma_v41_m1.xci`

History was traced with exact commits recorded in the instrumentation inventory. R0/R1/R2 evidence was inspected to distinguish new RTL from plans, sibling functional variants and off-chip observers.

## Measurement labels

- `MEASURED`: directly reported at the named stage/scope.
- `DERIVED`: arithmetic from measured values.
- `ESTIMATED`: source/DCP name grouping normalized to a measured total or history-backed planning range.
- `UNKNOWN`: no compatible isolated measurement exists.

No estimate is represented as a qualification result. Future G2B-LUT1 must replace planning estimates with paired post-opt/routed A/B measurements.

