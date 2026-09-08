# Focused 4-KiB host-tool gate

Final result: **9/9 PASS**

- NATIVE_SOURCE_COMPILES_ON_DUT: PASS — /usr/bin/gcc gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0
- BINARY_IS_X86_64_LINUX: PASS — ELF 64-bit LSB pie executable, x86-64, dynamically linked
- NO_DEVICE_USAGE_SMOKE_TEST: PASS — exit=64
- NO_ACTIVE_DMA_SIGNAL_INTERRUPTION: PASS — No signal-driven DMA interruption tokens
- NO_O_TRUNC_OR_EOP_FLUSH: PASS — Forbidden tokens absent
- EXACT_2500_IOCBS_OF_4096_BYTES: PASS — Distinct indexed 4096-byte IOCBs 0..2499
- PREQUEUE_READY_AFTER_ALL_SUBMISSIONS: PASS — PREQUEUE_READY follows the all-submitted hard guard
- ASSEMBLY_USES_REQUEST_INDEX: PASS — Shuffled completion fixture reconstructs A,B,C by request index
- COMPLETED_BUFFERS_PRESERVED_AFTER_LATER_FAILURE: PASS — Positive completed buffers are persisted by fixed request index before free

The initial 8/9 auxiliary-inspector receipt is retained. Its only failed item was caused by selecting the first `free(primary)` source occurrence. The corrected inspector selects the final persistence-path occurrence; no native-helper source byte changed. Initial and final native source SHA-256 are both `7C13B835DCC037EF529BC915EF045B661BA4166AF6F5B002ED63E7787890A0FB`.
