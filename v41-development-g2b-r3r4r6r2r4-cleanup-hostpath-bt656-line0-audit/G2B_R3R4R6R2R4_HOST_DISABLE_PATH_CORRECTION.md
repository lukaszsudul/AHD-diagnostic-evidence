
# Host disable critical-path correction

Result: `PASS — OFFLINE READY FOR A LATER GOVERNED RERUN`

The R3R4R6R2R3 tools were copied into the fresh root and left intact as the
baseline. Task-local corrected sources are:

- `tools/controller_r3r4r6r2r4.py` — SHA-256 `83A0C75C6790F5B6E3F8AAE81FE96B5193EAE572F02382DA0EABA096445DB183`
- `tools/xdma_c2h_rolling_4k_r4.c` — SHA-256 `03F977285D755418024130D969AFD8E06154F2E980F40F64FDF993C03F24A849`

The controller recognizes the already decoded `PRIMARY_WINDOW_COMPLETE` event,
calls `fast_normal_disable()`, performs one direct four-byte `pwrite` of zero to
the already-open CONTROL fd, records only a monotonic completion timestamp in
memory, and then sends `DISABLE_ISSUED`. Only after that does it buffer the
primary event and create the in-memory ledger rows. Active-capture event logging
is memory-only; durable JSON/CSV/log operations are deferred.

The native helper retains the completed 10,240,000-byte primary buffer in
memory after emitting `PRIMARY_WINDOW_COMPLETE`. It does not begin persistence,
fsync, or SHA-256 until it receives `DISABLE_ISSUED`. Guard cancellation remains
gated by `PARENT_QUIESCENT`. The task-local guard is exactly 128 records / 524288
bytes.

DUT-local compilation used GCC 15.2.0, produced an x86-64 ELF, and emitted no
warnings. Binary SHA-256 (identity evidence only; binary not published):
`064E0490AE1806AC1F2D28629DC02893F139BAD24387CCD9EA80AEE5D45688E2`.

The deterministic host path gate passed `12/12`. Real hardware latency was not
measured because a new capture was forbidden. The next-run acceptance target is
`PRIMARY_COMPLETE_TO_DISABLE_US <= 500`.
