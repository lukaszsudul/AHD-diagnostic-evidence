# Timing methodology disposition — PASS

Fresh full report: 15 warnings. The required focused set has 11 TIMING-34 and 1 TIMING-39. No TIMING-32/37/38 finding. Every current skew warning is mapped below; none concerns a retired global relation. Constraint positions are taken from the current report, not copied from the audit.

| Warning | Position | Group | Source/destination count | Required sign-off | Classification | Endpoint |
|---|---:|---:|---|---|---|---|
| TIMING-34#1 | 31 | 1 | 74/74 | PASS; slack 1.854 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `CAPTURE_SUBSYSTEM/MAILBOX/nvp_cfg_abort_reg/D` |
| TIMING-34#2 | 33 | 2 | 291/291 | PASS; slack 1.596 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `CAPTURE_SUBSYSTEM/MAILBOX/status_bus_pcie_reg[0]/D` |
| TIMING-34#3 | 36 | 3 | 96/96 | PASS; slack 1.597 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `CAPTURE_SUBSYSTEM/active_sav_gray_sync1_pcie_reg[0]/D` |
| TIMING-34#4 | 48 | 4 | 128/128 | PASS; slack 1.927 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/snapshot_attempted_sync1_axi_reg[0]/D` |
| TIMING-34#5 | 50 | 5 | 32/32 | PASS; slack 1.942 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/snapshot_epoch_sync1_axi_reg[0]/D` |
| TIMING-34#6 | 52 | 7 | 32/32 | PASS; slack 1.922 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/snapshot_epoch_echo_source_reg[0]/D` |
| TIMING-34#7 | 54 | 8 | 38/217 | PASS; slack 0.961 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/hard_event_baseline_hold_source_reg[0]/D` |
| TIMING-34#8 | 62 | 10 | 44/32 | PASS; slack 1.801 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/axis_attempt_reg[0]/D` |
| TIMING-34#9 | 63 | 11 | 32/24 | PASS; slack 1.930 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/axis_generation_reg[0]/D` |
| TIMING-34#10 | 64 | 12 | 128/32 | PASS; slack 1.336 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/axis_epoch_reg[0]/D` |
| TIMING-34#11 | 68 | 6 | 4/4 | PASS; slack 2.247 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/hard_event_baseline_sync1_axi_reg[0]/D` |
| TIMING-39#1 | 54 | 8 | 38/217 | PASS; slack 0.961 ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `G2B_ONECH_C2H/overflow_count_source_reg[0]/R` |

TIMING-34 warns that the 3 ns bound is aggressive relative to clock periods and increases analysis runtime. Each actual required routed skew result passes on this exact implementation; its requirement remains enforced. Exact raw reports and object inventories are sealed under preserved_groups; Groups 10–12 refer to recovery-1 raw reports. No global waiver was applied.

TIMING-39 is current Group 8 transport payload, not a retired constraint. Its multi-level logic makes a relative skew relation expensive and unsuitable as the sole CDC safety argument. Group 8 remains governed and has actual skew 2.039 ns against 3 ns (+0.961 ns), while the retained 2.500 ns absolute transport settling bound and held request/ack reset barrier supply the functional CDC requirement. Fresh routed timing passes under that bound. This specific warning is accepted with those independent proofs; the constraint is not removed and the warning is not generalized to other groups.

Supplemental full-report findings: two LUTAR-1 warnings are inside unchanged generated XDMA reset/FIFO logic. They concern asynchronous reset assertions; current zero-error/zero-critical DRC, unchanged vendor IP and reset protocol evidence are retained. They do not establish hardware glitch immunity. TIMING-9 requests detailed CDC analysis; the complete 1,401-row CDC disposition supplies that analysis. No supplemental error or critical warning exists.

UNRESOLVED_METHODOLOGY_WARNINGS = 0
INVALID_CURRENT_CONSTRAINT = 0
RETIRED_GLOBAL_CONSTRAINT_ACTIVE = NO
