# Exact pinned-driver loader command manifest

The same accepted loader command shape was used for the optional pre-Arm-A
load and for the single post-reboot load in each arm:

```text
LOADER_INVOKER=sudo /usr/bin/bash
EXPLICIT_LOADER_PATH=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
EXPLICIT_LOADER_SHA256=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
EXPLICIT_LOADER_MODE=0644
EXPLICIT_MODULE_PATH=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
EXPLICIT_MODULE_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
EXPLICIT_MODULE_VERSION=2025.2.0
EXPLICIT_MODULE_VERMAGIC=7.0.0-29-generic SMP preempt mod_unload modversions
PRE_ARM_A_REMOTE_EVIDENCE_DIR=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/pre_arm_a_driver
ARM_A_REMOTE_EVIDENCE_DIR=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/arm_a_driver
ARM_B_REMOTE_EVIDENCE_DIR=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/arm_b_driver
OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=1
POST_REBOOT_DRIVER_LOADER_INVOCATIONS=2
TOTAL_DRIVER_LOADER_INVOCATIONS=3
LOADER_RETRIES=0
```

Each role used a distinct, previously absent remote evidence directory and a
durable local one-shot receipt. Each retained live log proves the exact
explicit module and loader paths, hashes, kernel compatibility, consumed
marker, loader exit code 0, expected endpoint, 21-node set, unchanged BAR
geometry, zero node owners, and only the accepted module-signature taint.

No invocation used `modprobe xdma`, a same-name in-tree driver, module unload,
PCI remove/rescan, FLR, `setpci`, `driver_override`, MMIO writes, or DMA.
