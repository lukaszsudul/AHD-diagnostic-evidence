# G2B-HW0-PRODUCT-R3 final hardware state

- technical final state: `PASS_CLEAN_PRELOAD_STATE`
- engineering result: `FAIL`
- first blocker: `FAIL — PRIOR_IMMUTABLE_ARTIFACT_BOUNDARY_VIOLATION`

| Field | Value |
|---|---|
| boot/kernel/arch | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` / `7.0.0-29-generic` / `x86_64` |
| endpoint / driver / override | `0000:01:00.0` / none / `(null)` unset |
| endpoint link | `5.0 GT/s x1` |
| AHD/platform XDMA modules | `0 / 0` |
| XDMA nodes/class | `0 / absent` |
| taint before/final | `0 / 0` |
| module load/unload attempts | `0 / 0` |
| MMIO reads/writes; DMA/stream writes | `0 / 0; 0 / 0` |
| FPGA/Flash programming | `0 / 0` |
| reboot/power cycle | `0 / 0` |
| locks | Linux released; controller released last |

Last observed JTAG DONE was `1` at `2026-09-06T14:55:47Z`, approximately
22 minutes before the 15:18 final snapshot; it was not contemporaneously
re-read. Candidate retention is supported by unchanged boot/power/programming
history and stable endpoint/DONE evidence, while exact embedded runtime
identity remains NOT_REACHED.

`PERSISTENT_FILESYSTEM_STATE_MODIFIED = NO` refers to system/module
installation. Authorized evidence artifacts were created. The prior-R1
temporary-path crossing remains separately classified as the engineering fail.

`KERNEL_BOOT_SESSION_TAINT = UNCHANGED`

