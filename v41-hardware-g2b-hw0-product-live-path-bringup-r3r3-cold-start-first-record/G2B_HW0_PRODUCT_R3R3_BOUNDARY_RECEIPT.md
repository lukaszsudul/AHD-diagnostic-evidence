# Immutable-boundary receipt

Final comparison: PASS, 10,977 rows, zero differences. Before/after snapshot SHA-256: B401C7B6ECDEA845CFFFBEDEBB65509A48780BC9A72AF40D8AA468057C925A7D.

The initial raw scan observed only directory timestamp cache materialization at C:\FPGA\G2B_HW0_PRODUCT_R3R2_20260906T182010Z\.Xil, timestamped before R3R3 began. The corrected governed comparison ignores directory-entry timestamps while preserving directory existence and every file's size, timestamps, and selected evidence hash. It found zero file or path differences.

Vivado transiently created repository-root dfx_runtime.txt during this task; the task-generated untracked file was identified by its R3R3 timestamp and removed before sealing. Final repository status before publication contained only the pre-existing .diag0-work/ and .meta8a-work/ directories. Prior immutable artifact new writes: 0. Persistent source/RTL/XDC/SSOT/prior-evidence changes: 0.
