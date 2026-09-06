# T3 session-start receipt

- Sessions started: 1; retries: 0.
- Disabled baseline: CONTROL 0, STATUS 0x000000C4, no reader, reset not busy.
- RESET_STREAM_STATE: exactly once.
- Pre/post reset epochs: 1 / 2; modulo transition PASS.
- Post-reset ERROR_STATUS: 0x00000000.
- Fatal mask observed/written: 0x00000000 / NONE.
- Nonfatal W1C and statistics clear: 0 / 0.
- Coherent pre-capture snapshot: PASS; generation 1.
- Reader-ready receipt: PASS for /dev/xdma0_c2h_0.
- Enable: exactly once after reader ready.
- First complete 4096-byte record event: observed within budget.
- Normal disable: exactly once after the first complete-record event.

The capture-time worker then stopped before final quiescence proof, making T3 BLOCKED. No second reset, enable, or session was attempted.
