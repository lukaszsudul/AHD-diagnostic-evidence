# G2B-LUT0 Recommended G2B-LUT1 Plan

## Decision

Implement Plan B as a separately approved G2B-LUT1 `PRODUCT`/`RESEARCH_DIAGNOSTIC` profile change. Expected PRODUCT result is 17,512 LUT (84.192%), with a planning range of 17,112–17,912 LUT. Do not optimize or weaken the G2B transport first.

This plan is implementation-ready but not currently authorized: `project-current-state` says diagnostic reduction is not authorized while R-track is open. OWNER_ARCHITECT must approve the profile and research-page compatibility policy in a separate meta update before RTL work.

## Exact source/module actions

### Add the profile boundary

- `scripts/v41/g2b_build.tcl`: select and receipt `PRODUCT` or `RESEARCH_DIAGNOSTIC` through an explicit top parameter/generic.
- `rtl/top/ahd_capture_top_xdma.sv`: named generate regions and deterministic inactive tie-offs; no functional mux changes outside research islands.

### Move to RESEARCH_DIAGNOSTIC

- `rtl/v41/nvp_i2c_tri_phase_probe.sv` / `POST_INIT_TRI_PHASE_PROBE`.
- `rtl/v41/r1h_probe_index_bram_store.sv` / three 512×16 stores.
- `rtl/v41/r1f_failed_txn_logger.sv` / `R1F_FAILED_TXN_LOGGER`.
- `rtl/v41/axi_clock_lifecycle_monitor.sv` / deep timestamps and transitions.
- Deep-history portions of `rtl/v41/r1h_mmio_read_service.sv`.
- Research-only portions of `rtl/v41/r1f_measurement_regs.sv`, `rtl/v41/r1e_measurement_regs.sv`, `rtl/v41/control_status_regs.sv`, `rtl/v41/axi_lite_host_bridge.sv` and top read mux.
- In `rtl/nvp/nvp6134c_i2c_bringup.vhd`, only D1 history, failed-record construction and counters proven to have diagnostic-only fanout. The physical bank cache/check/invalidation and all error terminality stay.

When the post-init probe is absent, drive its two release contributions high before the existing open-drain AND. Do not change the initializer's `nvp_init_scl_release`/`nvp_init_sda_release` path.

### Keep in both profiles

- All functional logic in `rtl/nvp/nvp6134c_i2c_bringup.vhd`: synchronizers, filters, physical SCL qualification, ACK sample behavior, first-NACK abort, STOP/BUS_FREE, retry/backoff, timeout/readiness/recovery, and bank safety.
- `rtl/nvp/nvp6134c_autoinit.vhd` functional wrapper/table/power/reset sequencing.
- Full R1i 1,024-bit telemetry and `0x3600–0x367F` page in the first PRODUCT iteration, including the R1f opportunity/NACK counters and transaction serial it consumes.
- Firmware/build identity, capabilities, `INIT_DONE`, `INIT_ERROR`, basic qualified NACK/error, video presence and product status.
- `ip/v41/xdma_v41_m1.xci` exact Gen2 x1 configuration.
- `rtl/g2b/v41_g2b_onech_c2h.sv` unchanged in the first implementation.
- `rtl/g2b/v41_g2b_mmio_router.sv` and every `0x3800–0x3858` G2B semantic unchanged.
- Four 4 KiB slots and four XPM block memories unchanged.

### MMIO compatibility requirement

Keep legacy address ownership, deterministic response timing and the full R1i/G2B pages. For research-only deep-history addresses, implement only the OWNER_ARCHITECT-approved compatibility response and profile identification; do not silently alias or expose stale BRAM data. This does not require a G2B MMIO change.

## Verification required

1. Build both profiles from the same commit and receipt profile/generic/source/IP identities.
2. Prove named research instances absent in PRODUCT and present in RESEARCH_DIAGNOSTIC.
3. Produce paired post-synth, post-opt and routed hierarchy/flat/memory reports; accept only PRODUCT `<=18,720 LUT`, prefer `<=17,680`.
4. Run the complete protected R1i focused suite: all-ACK trace equivalence, physical-low qualification, first-NACK abort, legal STOP/BUS_FREE, retry tiers/backoff, timeout, readiness/recovery and bank-safety tests.
5. Run exhaustive legacy and R1i MMIO tests, including latency/backpressure and every address; verify approved PRODUCT compatibility responses.
6. Run complete G2B ABI golden vectors, four-slot/ring/formatter/scheduler, frozen MMIO snapshot/counter/reset/error tests and host parser fixtures.
7. Run CDC/reset analysis, timing, DRC, memory inference and high-fanout review on both profiles.
8. Demonstrate that PRODUCT probe releases are constant high and no research-only signal has functional fanout.
9. Do not proceed to hardware qualification until the full offline G2B-IMPL gate passes and separate authority is granted.

If the paired PRODUCT post-opt result exceeds 17,680 but is at or below 18,720, continue with evidence review; do not automatically apply Plan C. If it exceeds 18,720, review measured residuals and then approve selected category-B optimizations from Plan C. Category C remains prohibited.

