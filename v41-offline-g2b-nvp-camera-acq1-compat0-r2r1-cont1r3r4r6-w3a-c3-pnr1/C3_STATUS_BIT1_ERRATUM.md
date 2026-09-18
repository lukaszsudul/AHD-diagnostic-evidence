# C3 status bit 1 erratum (external, no C3 source or contract edit)

C3 status bit 1: interpret as `SCAN_IN_PROGRESS` (states 1..9). Bit = 0 is **NOT** proof of `SAFE_IDLE`. The hardware `safe_idle` predicate remains the complete C3 predicate. The C4 contract/host must not be substituted for the C3 contract/host.

The unchanged C3 JSON labels bit 1 `SCANNER_NOT_IDLE`; the RTL actually sets it when `scan_state_i` is 1 through 9. Hardware write acceptance additionally requires state `ST_IDLE`, no scan admission, executor/I2C/bus/transaction inactivity, and no pending snapshot/response. It rejects writes otherwise and increments the rejection counter. Bank-context lockout is separately represented and preserved.

The byte-identical C3 host `W3AController._safe_write` does **not** use bit 1 = 0 alone: it rejects bit 1 or bit 7 being set, and verifies the hardware rejected-write counter is unchanged after each write. This is a precheck plus hardware enforcement, **not** a software proof of `safe_idle`. A state outside active scan 1..9 can leave bit 1 clear while hardware still rejects the write; the host must treat `W3A_CONTROL_REJECTED` as failure. No host live operation was run in C3-PNR1.
