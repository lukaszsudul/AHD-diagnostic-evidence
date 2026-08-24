# R1f tri-phase probe final-current RTL gate

This gate supersedes earlier focused-probe hash summaries.  It binds the
current RTL after the final evidence-fidelity and R1e-page compatibility
outputs were added.  All seven focused RTL simulations were freshly compiled,
elaborated, and executed with Vivado Simulator 2025.2 build 6299465.

```text
TRI_PHASE_PROBE_FINAL_CURRENT_GATE=PASS_7_OF_7
NORMAL_SETUP_PROBE_RESTORE=PASS
PRIMARY_ABORT_AND_BEST_EFFORT_RESTORE=PASS
SCL_TIMEOUT_AND_LEGACY_STICKY_STATUS=PASS
ATTEMPT_LIMIT_NO_FABRICATED_TARGET_OPPORTUNITY=PASS
SECONDARY_RESTORE_FAILURE_PRESERVES_PRIMARY_ABORT=PASS
INDEX_LOG_OVERFLOW_PRESERVES_AGGREGATES=PASS
INITIAL_BUS_IDLE_TIMEOUT_AND_LEGACY_STICKY_STATUS=PASS
```

The current module retains the frozen 00/85/00 safe target, exact round-robin
WADDR/REGADDR/DATA scheduler, zero-based target-opportunity indices, 512-entry
per-phase index logs, 10 blocks, bounded 12,000 attempts per phase, immutable
primary abort code, separate secondary restoration code, actual safe/restored
bank readbacks with validity, scheduler status, and diagnostic-only legacy
status outputs.  No output added for compatibility feeds probe control.

Exact source identities:

```text
4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552  rtl/v41/nvp_i2c_tri_phase_probe.sv
71523794924E8AB03F2A6F02C2C7998791E14A474088F44850AC0286BD40A38D  tests/v41/tb_nvp_i2c_tri_phase_probe.sv
BA56452CFB9298015E0C073E0196B9BAFB4F148E6A15444551ACF386C2E27F1D  tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv
F92FAFF99A2D8F1ADFA751792800D11882C25C7395C64AEBD3D7C96BF5E4BAF0  tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv
9DC27EB9E94E06F97D46B11E35BC8669B94A29BEC9BA4FCA02588CCED5A1016B  tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv
17F99B976EBC25C90C23F09E6FB4777252FFB263D15FE35AB356121765DCA8F1  tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv
2B62A9E6FAD827DAC5B13AE2CA3B850C9F7AC30D98FB6C906A87711B59261065  tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv
3E944F867F098AC2026925F804ED3FEAB4B2FE513836518F9C6D0B794F7F867E  tests/v41/tb_nvp_i2c_tri_phase_probe_idle_timeout.sv
```

Exact XSim log identities:

```text
81954E546FABE40C9529E5101CCE5BA662CE131CF936F2F956CB6B1902849B9E  normal
DB32D8A9A9AC3B1D5A15A1E8926B61C9C5DE107B4F9AC7D4FAD56A84A9FA5397  abort_restore
D0992BD4B7916B3E97A6B84EE504F332D0CC40BDF6F2425C6155B76A56D39DF1  scl_timeout
AD28A94D1BE47863FD2F46DA92282734260C95480EA5B654C3D934E5A30C27D9  attempt_limit
6507E1CA7709811D27E45A4AC8825727FA930325A8EB9936307FA6AB4E894416  secondary_restore_failure
100E13E720E931EE3B3850CB10EA87A67CB44A3EE52DC9F08664E34703161BD6  index_overflow
21208704912844DC510BA56E00FDD3F932F8ED4C0C38387354E6A13E0092B0CC  initial_bus_idle_timeout
```

The common `xvlog.log` SHA-256 is
`6A26DE0E79038E3903EB9EE9033E0BACF7B48E6D7198C4B2EEAAD1CF523E0963`.
All raw logs are under `06_SIMULATION/tri_phase_probe_final_current/`.
The separate production-count timing gate is recorded in
`R1F_PRODUCTION_TIMING_AND_ARM_A_WAIT.md`.
