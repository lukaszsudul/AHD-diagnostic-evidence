# R3R4R6R2R4 Host Disable-Path Gate

Result: **12/12 PASS**

| Case | Result | Basis |
|---|---|---|
| PRIMARY_EVENT_FAST_DISABLE_FIRST | PASS | simulated trace plus fast_normal_disable AST/source |
| PRE_DISABLE_DURABLE_LOG_REJECTED | PASS | negative fixture |
| PRE_DISABLE_ISSUED_PRIMARY_PERSIST_REJECTED | PASS | negative fixture |
| DISABLE_ISSUED_AFTER_MMIO | PASS | corrected controller source ordering |
| ACTIVE_PROGRESS_BUFFERED_IN_MEMORY | PASS | fixture and record_event source |
| BUFFERED_EVENTS_PERSIST_ONLY_AFTER_DISABLE | PASS | positive fixture |
| GUARD_IS_EXACTLY_128_RECORDS | PASS | controller and native constants |
| GUARD_CANCEL_AFTER_PARENT_QUIESCENT | PASS | native source ordering and deterministic native fixture |
| PRIMARY_PERSIST_INDEPENDENT_OF_GUARD_COMPLETION | PASS | deterministic native fixture |
| PRIMARY_SURVIVES_GUARD_CLEANUP_FAILURE | PASS | negative cleanup fixture and native fixture |
| NORMAL_SUCCESS_COUNTS | PASS | deterministic success fixture |
| FAILURE_CLEANUP_NO_FORCE | PASS | static source audit |

Durable logging before MMIO disable: **NO**

Primary persistence before `DISABLE_ISSUED`: **NO**

Required next-run measured latency: **<=500 microseconds**

Actual hardware latency in this task: **NOT_MEASURED_NO_CAPTURE**
