# R3R4R6 Focused Host-Tool Gate

Result: `5/6 PASS — BLOCKED BEFORE DUT CONNECTION`

- `NATIVE_HELPER_COMPILES_PASS`: `FAIL` — `"AssertionError:offline Linux compilation failed: ssh: connect to host 10.132.1.227 port 22: Connection timed out"`
- `NO_ACTIVE_DMA_SIGNAL_INTERRUPTION_PASS`: `PASS` — `{"forbidden_hits": [], "controller_forced_termination": false}`
- `C2H_OPEN_FLAGS_PASS`: `PASS` — `{"read_only": true, "close_on_exec": true, "no_follow": true, "truncate": false, "eop_flush": false}`
- `TWO_AIO_REQUESTS_PREQUEUED_PASS`: `PASS` — `{"program_order": ["PRIMARY_SUBMIT", "GUARD_SUBMIT", "PREQUEUE_READY"], "both_submit_results_required": true}`
- `PREQUEUE_READY_ENABLE_DEPENDENCY_PASS`: `PASS` — `{"prequeue_ready_before_enable": true, "enable_precondition": "PREQUEUE_READY"}`
- `METRIC_SPLIT_FIXTURE_PASS`: `PASS` — `{"valid_discontinuity_record_integrity": "PASS", "valid_malformed_preceding_record_integrity": "PASS", "continuity_classification_separate": true, "bad_magic_integrity": "FAIL_EXPECTED", "nonzero_padding_integrity": "FAIL_EXPECTED", "partial_returned_bytes": 3584, "partial_counted_as_additional_malformed_record": false}`

The compile check attempted a compile-only connection to the non-DUT host
alias `ahd-ubuntu` (`10.132.1.227`). TCP port 22 timed out. The authoritative
DUT address `10.132.1.111` was never contacted. No installed local Linux C
compiler or compatible Linux syscall-header toolchain was available, and
package installation was prohibited.

First blocker: `R3R4R6_FOCUSED_HOST_TOOL_GATE_FAILED:NATIVE_HELPER_COMPILES_PASS:NON_DUT_OFFLINE_COMPILER_UNREACHABLE`
