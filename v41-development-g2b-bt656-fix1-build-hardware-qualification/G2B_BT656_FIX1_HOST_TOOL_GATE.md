# G2B BT656 FIX1 Host-Tool Gate

Result: **16/16 PASS**

| Case | Result | Basis |
|---|---|---|
| NATIVE_HELPER_COMPILES | PASS | DUT-local gcc receipt |
| NATIVE_HELPER_X86_64 | PASS | file/readelf receipt |
| NO_DEVICE_SMOKE_TEST | PASS | no-argument DUT-local smoke receipt |
| MAX_OUTSTANDING_1024 | PASS | native constants and deterministic fixture |
| TOTAL_LOGICAL_REQUESTS_2500 | PASS | primary-only constant and fixture |
| NO_GUARD_REQUESTS | PASS | controller/native constants and fixture |
| NO_REQUEST_AFTER_2499 | PASS | bounded next-submit loop and fixture |
| PRIMARY_WINDOW_AT_2500_EXACT | PASS | native event guard and fixture |
| PENDING_AIO_ZERO_AT_PRIMARY_WINDOW | PASS | native event and parent acceptance guard |
| IMMEDIATE_DISABLE_BEFORE_DURABLE_LOGGING | PASS | controller AST/source ordering |
| PRIMARY_PERSIST_AFTER_DISABLE_ISSUED | PASS | native handshake fixture and source |
| ACTIVE_EVENTS_BUFFERED_IN_RAM | PASS | record_event AST/source |
| VERTICAL_TAIL_CAPTURE_SEQUENCE_RULE | PASS | validator bounded frame-boundary rule |
| POST_TARGET_FLUSH_CANNOT_CHANGE_PRIMARY | PASS | tail flush is parent-side and strictly post-primary/post-disable |
| NORMAL_PATH_NO_IO_CANCEL | PASS | primary-only deterministic normal path |
| FORBIDDEN_ACTIVE_RECEIVE_FEATURES_ABSENT | PASS | static source audit |
