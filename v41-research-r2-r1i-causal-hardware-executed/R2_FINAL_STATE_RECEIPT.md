# R2 Final State Receipt

## Remote host checkpoint

- Completed UTC: `2026-08-28T09:30:47Z`
- hostname: `VCDE-DUT-1`
- user: `vcdeagent1`
- kernel: `7.0.0-29-generic`
- boot ID: unchanged from initial preflight
- Xilinx vendor `10ee` functions: `NONE`
- class `0580` functions: `NONE`
- XDMA module: `NOT_LOADED`
- XDMA device nodes: `NONE`
- exact `FPGA_AHD_HW_LOCK` path/lslocks holder: `NONE_VISIBLE`
- MMIO: `NOT_ATTEMPTED_ENDPOINT_ABSENT`
- mutations: `0`

## JTAG checkpoint

- Session start UTC: `2026-08-28T09:34:20Z`
- Session end UTC: `2026-08-28T09:37:42Z`
- qualified selected-target script: `r7_jtag_reconfirmation_session.tcl`
- FPGA programming invocations: `0`
- samples: `5/5 PASS`
- part: `xc7a35t` in `5/5`
- IDCODE: `0362D093` in `5/5`
- DONE: `0` in `5/5`

## Final classification

The exact terminal state is `UNPROGRAMMED_OR_FPGA_UNKNOWN`, resolved specifically as unprogrammed, with corresponding `PCIe_NOT_ENUMERATED`. R2 performed no programming, reset, power, driver, DMA, MMIO-write, flash, or firmware mutation. No lock was acquired, so safe-baseline programming and lock release remained prohibited.

Sanitized evidence: `raw/REMOTE_FINAL_CHECKPOINT_SANITIZED.txt` and `raw/JTAG_FINAL_DONE_SAMPLES_SANITIZED.csv`.
