# G2B BT656 DIAG1-R1 simulation gate

- Result: PASS
- Existing DIAG1 passed: 10/10
- Total passed: 12/12
- Functional noninterference: PASS
- Source mutations during gate: 0

| Test | Result | Evidence |
|---|---|---|
| T1 | PASS | `BT656_DIAG1_T1_PASS clear_arm_status` |
| T2 | PASS | `BT656_DIAG1_T2_PASS marker_byte_alignment` |
| T3 | PASS | `BT656_DIAG1_T3_PASS pretrigger_chronological_order` |
| T4 | PASS | `BT656_DIAG1_T4_PASS line1079_eav_next_frame_line0_line1_stop malformed=0` |
| T5 | PASS | `BT656_DIAG1_T5_PASS malformed_reason_1_2_3_exact` |
| T6 | PASS | `BT656_DIAG1_T6_PASS ring_full_and_malformed_drop_independent` |
| T7 | PASS | `BT656_DIAG1_T7_PASS event_limit_clock_timeout_freeze` |
| T8 | PASS | `BT656_DIAG1_T8_PASS dual_clock_mmio_readback` |
| T9 | PASS | `BT656_DIAG1_T9_PASS side_by_side_product_equivalent_vs_trace_armed byte_identical` |
| T10 | PASS | `G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16` |
| T11 | PASS | `BT656_DIAG1_R1_T11_PASS source_registered_aligned_adjacent_events` |
| T12 | PASS | `BT656_DIAG1_R1_T12_PASS frozen_metadata_before_done_stable_new_generation` |
