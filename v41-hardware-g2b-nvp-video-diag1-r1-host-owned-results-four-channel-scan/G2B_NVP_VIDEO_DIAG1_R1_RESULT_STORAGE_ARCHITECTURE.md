# Result storage architecture

The on-chip 16-session history is absent. No `result_words[0:127]`, bulk table
reset, asynchronous 128-word MMIO mux, replacement memory, or equivalent
retained history remains. FPGA storage is limited to eight explicit 32-bit
current-result words (256 payload bits) plus valid, 16-bit session ID, and
16-bit generation metadata. Complete history ownership moved to the host.
Post-synthesis and post-opt architecture receipts passed.
