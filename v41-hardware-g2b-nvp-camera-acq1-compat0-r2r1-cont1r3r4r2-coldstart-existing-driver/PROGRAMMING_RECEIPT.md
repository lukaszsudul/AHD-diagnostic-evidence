# Sole exact SRAM programming receipt

Preconditions: Owner-attested cold start; changed stable DUT boot; namespace free in two postboot surveys and immediately before programming; exclusive task/controller locks; 34-file DUT bundle PASS; exact historical AHD JTAG target `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01` read-only identity PASS (`xc7a35t`, IDCODE `0362D093`, `DONE=0`). The protected `10ee:7021` function remained absent after the authorized whole-DUT cycle; it was not accessed or reconfigured by this task.

The sole bitstream was `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z\firmware\AHD_v41_CONT1R3R3_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`, checked immediately before delivery at `2026-09-17T07:53:40.5304601Z`.

The exact target and device were rechecked inside the delivery command. Pre-program `DONE=0`; exactly one `program_hw_devices` call was consumed; post-program part and IDCODE remained exact and `DONE=1`. Vivado returned 0 and emitted `PROGRAM_TCL_RESULT=PASS_DONE_1`. Storage was volatile SRAM only. Flash/cfgmem operations: 0. No alternate image or retry is allowed. The raw stdout log is retained at `logs/vivado-program-exact-once.stdout.log`, SHA-256 `C5D747E2954E6CE2E2F3B40ED4D19BE57A7595E684A41BB4C414469754ED5B6C`.

This receipt proves configuration/DONE, not yet PCIe enumeration, product-equivalent autoinit readiness, runtime identity, SCAN1 operation or camera acquisition. Those remain separately gated.
