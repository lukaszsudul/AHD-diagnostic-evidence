# Sticky errors and recovery

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.

|Bit|Error|Effect|
|---|---|---|
|0|INVALID_CONFIG|reject START; prior ACTIVE/counters unchanged|
|1|ILLEGAL_COMMAND|COMMAND_WARNING; reject offending access, running data continues|
|2|BUSY_CONFIG_CHANGE|COMMAND_WARNING; reject offending access, running data continues|
|3|NVP_INIT_NOT_COMPLETE|acquisition failure; auto may advance candidate; terminal if no eligible source|
|4|NO_INPUT_AVAILABLE|acquisition failure; auto may advance candidate; terminal if no eligible source|
|5|INPUT_LOCK_TIMEOUT|acquisition failure; auto may advance candidate; terminal if no eligible source|
|6|INPUT_FORMAT_UNSUPPORTED|acquisition failure; auto may advance candidate; terminal if no eligible source|
|7|SOURCE_LOST|STOP or RESCAN per ACTIVE policy; sticky warning on successful rescan|
|8|SCAN_EXHAUSTED|acquisition failure; auto may advance candidate; terminal if no eligible source|
|9|PATTERN_ERROR|end current cycle/session after protocol-clean containment|
|10|RING_OVERFLOW|end current cycle/session after protocol-clean containment|
|11|RECORD_DROP|end current cycle/session after protocol-clean containment|
|12|SEQUENCE_ERROR|FATAL; inhibit START until external reset/new session|
|13|ABORTED_RUN|explicit abort completion; not successful count-limited result|
|14|AXI_PROTOCOL_ERROR|FATAL; inhibit START until external reset/new session|
|15|INTERNAL_FATAL|FATAL; inhibit START until external reset/new session|
|16|I2C_ERROR|acquisition failure; auto may advance candidate; terminal if no eligible source|
|17|PACE_OVERRUN|end current cycle/session after protocol-clean containment|
|18|COUNTER_OVERFLOW|end current cycle/session after protocol-clean containment|
|19|LEGACY_CONTROL_CONFLICT|end current cycle/session after protocol-clean containment|

Sticky ERROR_FLAGS are a union of events, not the current state. A successfully skipped unsupported auto candidate may leave INPUT_FORMAT_UNSUPPORTED with a per-input failure code; successful RUNNING does not erase it. LAST_COMMAND_RESULT reports a specific command, COMPLETION_REASON reports the run. First-error context records code,input,frame,line,record,cycle,segment and I2C details. Capture first failure once per run; later failures accumulate flags/counters without overwriting it. A new validated START resets run error context and nonfatal flags, not lifetime counters. CLEAR_RUN_STATUS preserves forensic context and totals; it clears only nonfatal sticky flags in terminal state.

Only fatal latches block all future START. Unresolved capability rejects the requested source at validation (UNSUPPORTED_CAPABILITY and INVALID_CONFIG); synthetic START remains possible despite NVP init/acquisition errors. A malformed/drop/overflow event invalidates the affected frame and fails the cycle after drain. Do not silently continue to replace dropped frames for an apparently successful finite capture. SOURCE_LOST with RESCAN is the sole frozen source-recovery continuation; it retains completed count and reports affected incomplete frame.

BUSY_CONFIG_CHANGE is for attempted writes to ACTIVE while a run is busy; also ILLEGAL_COMMAND because ACTIVE is RO. Shadow writes are always permitted. Unaligned reads return0 with ILLEGAL_COMMAND; partial RW writes merge enabled bytes; zero strobe RW is no-op. COMMAND requires full strobeF. Read COMMAND returns0. Reserved reads0, reserved/RO writes ignored and set ILLEGAL_COMMAND. No hardware bus exception is promised: semantic failures are polled.

Fatal containment must preserve stalled AXI signals; if TDATA has already been corrupted, integrity cannot be claimed, but still finish packet boundaries when possible and preserve fault evidence. Never call a fatal run PASS merely because it drained. External PCIe reset or legacy reset conflict invalidates host session association and requires re-negotiation. LIFETIME counters are never cleared by status clear, START,STOP,ABORT or counter snapshot.
