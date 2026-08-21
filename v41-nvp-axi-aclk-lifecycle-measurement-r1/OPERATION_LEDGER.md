# Operation ledger

- Formal bootstrap FPGA program: 1 (vendor startup HIGH; fresh DONE=1).
- R1 FPGA program: 1 (vendor startup HIGH; DONE=1; no retry).
- Formal restore FPGA program: 1 (vendor startup HIGH; DONE=1; no retry).
- Warm reboots: 3 (bootstrap, R1, restore).
- Exact pinned-driver loader invocations: 3 (one after each reboot).
- Programming retries: 0.
- Cold starts during task: 0.
- Physical actions: 0.
- PCIe remove/rescan/reset actions: 0.
- AXI-Lite writes: 0.
- C2H/H2C transfers: 0/0.
- Phase 3/Phase 4 actions: 0/0.

Two launcher/parser failures occurred before their target operation began: the first bootstrap loader shell line never invoked the loader, and the first restore launcher rejected its Tcl argument count before opening Hardware Manager. Neither is counted as a loader/program invocation.
