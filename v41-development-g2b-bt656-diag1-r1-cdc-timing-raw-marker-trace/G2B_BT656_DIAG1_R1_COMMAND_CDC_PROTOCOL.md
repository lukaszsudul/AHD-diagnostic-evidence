# Command CDC protocol

CLEAR, ARM, and ABORT_AND_FREEZE are AXI-originated single-bit toggles. Each has an exact first-stage ASYNC_REG synchronizer and a second source-domain stage. Only the synchronized source-local pulse controls the trace FSM.

Status advisories return through independent single-bit synchronizers; wide immutable trace/metadata data crosses only through dual-clock RAM.
