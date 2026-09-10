# AHD v41 G2B NVP VIDEO DIAG1-R2R1 main report

Engineering gate: **BLOCKED**

Overall result: **BLOCKED**

Evidence publication: **PENDING — local package only; no commit, push or read-back performed by this assembler**

The exact PRODUCT and diagnostic routed DCP identities passed. The raw CDC authorities reproduced 427 Critical and 874 Warning rows. All 423 CDC-1 destination endpoints are preserved. The complete 522-row destination-cone comparison passed: 295/295 Critical and 217/217 Warning same-family representative changes, 7/7 cross-family destination support-set proofs, and 3/3 composite release-token warning proofs. The final 1,337-row profile-specific semantic CDC manifest contains 815 byte-identical rows plus the 522 proven changed rows, with zero unreconciled Critical/Warning rows and zero family, token, protocol, exception, barrier or replacement-group drift.

Offline routed sign-off status at package assembly: **PASS**.

Hardware status: **NOT_REACHED**. No DUT root, hardware lock, JTAG access, FPGA programming, reboot, driver load, NVP I2C transaction, MMIO, DMA/AIO, capture or camera-pixel processing was performed by the evidence-preparation work.

First blocker: `NVP_DIAG1_R2R1_FROZEN_BASELINE_DOUBLE_READ_AND_HOST_LEDGER_CAPABILITY_ABSENT`.

The Phase-N requirement demands two agreeing physical reads of the complete PRODUCT NVP restoration baseline before any diagnostic NVP write, with the values recorded in both firmware and host ledgers. Repeating PREPARE is only a partial workaround: each pass performs bank-select writes and overwrites the same firmware baseline copy, no in-firmware comparison or dual ledger exists, the saved original bank/page is not exposed through diagnostic MMIO, and the accepted host controller performs only one PREPARE/read set. A wrapper cannot recover the hidden bank value. Hardware therefore remains outside the authorized gate unless the Owner/Architect reconciles that literal contract or authorizes the bounded implementation change.
