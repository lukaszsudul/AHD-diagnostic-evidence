# G2B-LUT0 R-track Instrumentation Inventory

## Classification rule

Classification follows source purpose, consumers, functional fanout and research dependency—not names. `KEEP_PRODUCT`, `KEEP_UNTIL_RTRACK_COMPLETE`, `REMOVE_FROM_PRODUCT_BUILD`, `MOVE_TO_DIAGNOSTIC_PROFILE`, and `UNKNOWN` mean lifecycle disposition; they do not authorize source edits. Current SSOT does not authorize diagnostic reduction.

## Proven introduction history

| Wave | Commit | Evidence-backed role in current lineage |
|---|---|---|
| earlier D2/D2b | `67f6513bc11d65b3bdaa6d018df69537020ff5f7` | embedded legacy NACK/bank/transaction diagnostics and legacy host exposure |
| D3 | `82ff0a19907ea75ae5268ea928d150bee27b4d55`, `01acf496b2b920c40f8564b08b9cefd9c7186e5a` | bounded retry, early abort and registered NACK decision; functional behavior mixed with counters |
| K2/K3 | `6071e2a070198601f51bc8abecae38d52e2d34b4`, `55ce0df41552bb74e0923f89eff43977b040f2e5` | input synchronization/filtering and physical-SCL timing declaration; functional, not diagnostic removal candidates |
| R1e | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` | lifecycle, address/ACK campaign and R1e measurement-register observability in the accepted lineage |
| R1f | `225544084dbfcaadb8592fcecc947aa1cec4970e` | phase-complete probe, transaction serial, failed-transaction logger and R1f measurement registers |
| R1f compatibility | `e112a5addb7ac62700a9a71af81bf368fad0bada` | production-VHDL-compatible diagnostic tap changes; no separate product purpose |
| R1h | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` | BRAM-backed 512-index histories, six-bank failed history and synchronous MMIO service |
| R1i | `94fa9e77ae58b791ebd884f767a26063fcf38e0a` | combined functional physical-SCL/ACK/STOP/retry correction and 1,024-bit causal telemetry page |
| R1i portable-build follow-up | `20c3323d79d3896edc586d6db1df7deee60f9e41` | build-environment isolation only; no new RTL instrumentation |

Earlier prototype commits `0af44dee...` (AXI lifecycle) and `1beb7053...` (post-init address probe) are not ancestors of the accepted G2A lineage; their concepts were reintroduced by `f3d9e5cd...`. They are historical evidence, not additional synthesized instances.

## Current synthesized inventory

### 1. Post-init tri-phase campaign and large-sample index stores

- **Source:** `rtl/v41/nvp_i2c_tri_phase_probe.sv`, `rtl/v41/r1h_probe_index_bram_store.sv`, top wiring in `rtl/top/ahd_capture_top_xdma.sv`.
- **Introduced in:** R1f `22554408...`; BRAM form in R1h `c4f4bfcf...`.
- **Purpose:** autonomously collect 10,000 WADDR, REGADDR and DATA opportunities per phase, ACK/NACK/run/adjacency/block statistics, and up to 512 retained indices per phase.
- **Consumer:** R1e/R1f/R1h host research readers and causal evidence; no product-control consumer.
- **Functional fanout:** the probe drives NVP open-drain outputs after initialization. Its product-profile replacement must tie both probe releases high so the qualified R1i initializer remains the only driver; that is a deliberate removal of post-init research traffic, not a change to R1i initialization.
- **Product runtime required:** NO.
- **Required to resume R2/R3:** YES, in `RESEARCH_DIAGNOSTIC`; R2 autoinit snapshots must occur before this post-init traffic.
- **Cost:** measured 2,092 LUT, 2,934 FF, 3 RAMB18 for the parent hierarchy (2,067/2,931 direct plus 25/3 and 3 RAMB18 store child).
- **Disposition:** `MOVE_TO_DIAGNOSTIC_PROFILE`; category A only after owner/SSOT and legacy-page disposition approval.
- **Safe removal method:** generate out the entire probe and store, tie open-drain release outputs high, retain deterministic profile-aware MMIO responses, and prove no initialization/control fanout.
- **Recreation:** select `RESEARCH_DIAGNOSTIC`, which elaborates the same modules, depths, constants, address semantics and host decoder fixtures from one source tree.

### 2. Failed-transaction deep history

- **Source:** `rtl/v41/r1f_failed_txn_logger.sv`, record production in `rtl/nvp/nvp6134c_i2c_bringup.vhd`, top wiring.
- **Introduced in:** R1f `22554408...`; six-RAMB18 form in R1h `c4f4bfcf...`.
- **Purpose:** retain 64 failed transactions with six 32-bit words (192 bits) each.
- **Consumer:** R1f/R1h forensic host tools and MMIO history reads; no retry/ACK/bank control consumes stored records.
- **Product runtime required:** NO, provided compact aggregate terminal-error observability remains.
- **Required to resume R2/R3:** YES for exact historic forensic reconstruction; restore in diagnostic profile.
- **Cost:** measured 106 LUT, 81 FF, 6 RAMB18. BRAM primitives are flattened to the top.
- **Disposition:** `MOVE_TO_DIAGNOSTIC_PROFILE`.
- **Safe removal method:** profile out logger and diagnostic-only record assembly/valid pulses after fanout proof; preserve functional error, qualified NACK, retry-exhausted, timeout and bank-safety state.
- **Recreation:** same generate/profile switch restores exact 64×192 geometry and read ordering.

### 3. Deep-history/index MMIO read service

- **Source:** `rtl/v41/r1h_mmio_read_service.sv`, `rtl/v41/r1f_measurement_regs.sv`, `rtl/v41/r1e_measurement_regs.sv`, `rtl/v41/control_status_regs.sv`, AXI bridge/top mux.
- **Introduced in:** R1f register bank `22554408...`; synchronous service in R1h `c4f4bfcf...`.
- **Purpose:** convert host reads into synchronous BRAM index/history transactions and return the research pages.
- **Consumer:** research host tools only for deep histories; mixed register files also carry identity/status and must not be removed wholesale.
- **Product runtime required:** NO for the deep-history service; YES for product identity/minimum status and every frozen R1i/G2B register.
- **Required to resume R2/R3:** YES in the diagnostic profile.
- **Cost:** read-service hierarchy 103 LUT/71 FF; additional decode/mux cost is flattened into the bridge/control hierarchy and cannot be isolated exactly.
- **Disposition:** `MOVE_TO_DIAGNOSTIC_PROFILE` for deep-read logic; `KEEP_PRODUCT` for identity/status; compatibility behavior requires owner approval.
- **Safe removal method:** generate-select research responders while keeping legacy address ownership, deterministic latency and an approved absent-feature/compatibility response in PRODUCT.
- **Recreation:** diagnostic profile elaborates the original service and register banks at the same addresses.

### 4. AXI/link/reset lifecycle campaign observer

- **Source:** `rtl/v41/axi_clock_lifecycle_monitor.sv`, R1e register readout/top wiring.
- **Introduced in accepted lineage:** R1e `f3d9e5cd...`.
- **Purpose:** 48-bit free-run time, first-event timestamps, transition counts and ordering for initialization/link/reset research.
- **Consumer:** R1e/R-track clock/link causal analysis; G2B has independent mandatory reset epoch/status.
- **Product runtime required:** NO for the deep timestamps; minimal transport/link status remains mandatory elsewhere.
- **Required to resume R2/R3:** YES until R-track/Gen2 reset-link questions close.
- **Cost:** measured 89 LUT/311 FF.
- **Disposition:** `KEEP_UNTIL_RTRACK_COMPLETE` and `MOVE_TO_DIAGNOSTIC_PROFILE`, not deletion.
- **Safe removal method:** select observer and research readout together; retain reset epoch, transport state and basic link-ready status in PRODUCT.
- **Recreation:** diagnostic profile restores the exact counter width, event predicates and readout.

### 5. R1f phase/transaction counters and correlation serial

- **Source:** `rtl/nvp/nvp6134c_i2c_bringup.vhd`, `rtl/nvp/r1f_transaction_serial_counter.vhd`, autoinit/top ports and R1f registers.
- **Introduced in:** R1f `22554408...`, with some legacy D2/D3 ancestors.
- **Purpose:** WADDR/REGADDR/DATA/RADDR phase opportunities/NACKs, transaction outcome accounting, correlation indices, failed-record triggers and bank invariant evidence.
- **Consumer:** deep logger/probe/MMIO and R1i telemetry correlations; some aggregate error/bank signals are production-safe observability.
- **Product runtime required:** PARTIAL. Retry, abort, bank safety and compact qualified-NACK/terminal status are product functional/diagnostic requirements. Deep phase correlation and record-building are not.
- **Required to resume R2/R3:** YES in full form.
- **Cost:** transaction serial child 55 LUT/33 FF measured; embedded counter/decode cost is not separable from the 3,135-LUT/2,247-FF NVP hierarchy without an A/B build.
- **Disposition:** `UNKNOWN` signal-by-signal until fanout audit, then deep correlation signals `MOVE_TO_DIAGNOSTIC_PROFILE`; product aggregates `KEEP_PRODUCT`.
- **Safe removal method:** never gate functional state predicates. Gate only counter updates/output packing whose fanout ends at research consumers, using a machine-checked cone/fanout report.
- **Recreation:** diagnostic profile re-enables exact counter widths, saturation and sample points.

### 6. R1i functional fix

- **Source:** `rtl/nvp/nvp6134c_i2c_bringup.vhd` and autoinit wrapper.
- **Introduced in:** `94fa9e77...`.
- **Purpose:** physical SCL synchronization/filtering and qualification, qualified ACK behavior, first-qualified-NACK abort, legal STOP/BUS_FREE, bounded retry/backoff, timeout, readiness/recovery and bank safety.
- **Consumer:** the NVP state machine and product initialization result.
- **Product runtime required:** YES.
- **Required to resume R2/R3:** YES as C3 baseline.
- **Cost:** exact isolated cost UNKNOWN; R1h→R1i routed global delta is +1,062 LUT/+702 FF and mixes this fix with telemetry.
- **Disposition:** `KEEP_PRODUCT` without exception.
- **Safe removal method:** none; it is protected behavior.
- **Recreation:** not applicable because it never leaves either profile.

### 7. R1i diagnostic observability

- **Source:** 1,024-bit `r1i_poc_telemetry` packing and counters in `rtl/nvp/nvp6134c_i2c_bringup.vhd`, R1i page readout in top/control path.
- **Introduced in:** `94fa9e77...`.
- **Purpose:** per-phase early/false-early comparisons; raw/recovered/unrecovered NACKs; retry success tiers/exhaustion; maximum SCL wait/timeouts; first-event correlation.
- **Consumer:** R0/R1/R2 causal analysis and frozen R1i host telemetry page.
- **Product runtime required:** not all detail is inherently needed, but the current frozen page and governance require it to remain.
- **Required to resume R2/R3:** YES.
- **Cost:** +702 FF is exactly observed in R1h→R1i; LUT split from functional correction is UNKNOWN. Declared stored telemetry fields account for approximately 704 state bits before optimization.
- **Disposition:** `KEEP_UNTIL_RTRACK_COMPLETE` and, for this recommended plan, `KEEP_PRODUCT` as well as diagnostic profile.
- **Safe removal method:** no removal in G2B-LUT1; later separate owner-approved ABI/productization gate only.
- **Recreation:** already common to both proposed profiles.

### 8. Legacy address-probe and measurement sources

- **Source:** `rtl/v41/nvp_i2c_address_probe.sv`, legacy measurement-register helpers.
- **Purpose/consumer:** earlier post-init address ACK research and compatibility readout.
- **Current use:** the standalone address-probe module is not present in synthesized hierarchy; its legacy output names are driven by the active tri-phase implementation. Some measurement-register modules remain active/flattened.
- **Product runtime required:** NO for standalone source; PARTIAL for identity/compatibility responders.
- **R-track required:** only through diagnostic-profile compatibility.
- **Cost:** standalone active cost 0; flattened register cost UNKNOWN.
- **Disposition:** inactive source `REMOVE_FROM_PRODUCT_BUILD` source-set-wise if desired, but no LUT credit; active research registers `MOVE_TO_DIAGNOSTIC_PROFILE` after compatibility approval.
- **Recreation:** include the same helper sources/diagnostic responders in the diagnostic profile.

### 9. ILA, VIO, probe endpoints and debug buses

- **Source:** catalog XCI/helper files under `ip/ila` and `ip/vio`; XDMA supports optional mark-debug settings.
- **Purpose:** interactive debug capability.
- **Current downstream consumer/use:** none in the accepted G2A or blocked G2B netlist. No ILA/VIO hierarchy and no qualified `.ltx` were generated.
- **Product/R-track required:** NO active instance; optional only for a future diagnostic profile.
- **Cost:** measured active cost 0 LUT/0 FF/0 BRAM. No removal credit is claimed.
- **Disposition:** `REMOVE_FROM_PRODUCT_BUILD` source selection / `MOVE_TO_DIAGNOSTIC_PROFILE` if later instantiated.
- **Recreation:** profile-specific IP source selection and XDC presence receipts.

### 10. Magic, identity, capabilities and minimum status

- **Source:** common/control registers and G2B MMIO.
- **Purpose:** firmware identity, ABI discovery, initialization health, transport state and data-loss accounting.
- **Consumer:** production host/firmware and qualification tooling.
- **Product runtime required:** YES.
- **Required to resume R2/R3:** YES.
- **Cost:** mixed; G2B mandatory MMIO/statistics/snapshot/error/identity subset is approximately 600 ±100 LUT and about 1,350 FF.
- **Disposition:** `KEEP_PRODUCT`.

## R0/R1/R2 inventory result

- R0 (`aff7e32e...`) was an experiment-design/evidence gate and added no active RTL to G2B.
- R1 built two sibling causal candidates. C1 (`8b8ec0fa...`) and C2 (`e4d10bb8...`) add only 34/33 routed LUT and one FF relative to C3; neither candidate is the accepted G2A/G2B source, so they contribute zero current removable LUT.
- R2 added no product instrumentation. It consumed the inherited R1i/R1h MMIO telemetry and external host observers. The live observer snapshot is off-chip evidence and costs zero FPGA LUT.
- R2/R3 resumption therefore requires reproducibility of the current R-track instrumentation, not permanent inclusion of all of it in PRODUCT. The proposed diagnostic profile is the restoration mechanism.

## Historical resource bound

Same-tool routed evidence provides a useful, non-controlled bound:

- R1e routed: 12,994 LUT / 16,022 FF / 21.5 BRAM tiles.
- R1h routed: 17,119 LUT / 19,381 FF / 26 BRAM tiles.
- R1e→R1h diagnostic-wave delta: +4,125 LUT / +3,359 FF / +4.5 BRAM tiles.

Current named G2B diagnostic hierarchies are 2,301 LUT/3,086 FF/9 RAMB18 for probe + logger + read service, or 2,390 LUT/3,397 FF including lifecycle. Embedded counters, record construction and flattened decode/mux explain why named-module sums are not the full historical cost. The `3,900 LUT` product-profile recovery is an evidence-informed point estimate, not a measured removal result.

