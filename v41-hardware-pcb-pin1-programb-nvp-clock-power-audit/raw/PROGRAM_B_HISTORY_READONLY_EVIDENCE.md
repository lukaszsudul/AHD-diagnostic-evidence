# PROGRAM_B History Read-Only Evidence

Audit date: 2026-09-01

Primary repository HEAD: `be94f88ee8d179f12928ab791bdae27c22cd1762`

## Current source

- `C:/FPGA/FPGA_AHD/rtl/top/ahd_capture_top_pcie.v:77-96`: no top-level PROGRAM_B-driving output.
- `C:/FPGA/FPGA_AHD/xdc/boards/current/pins.xdc:1-20`: no T12 or PROGRAM_B assignment.
- All-reference Git search: no RTL/XDC implementation of the feedback loop.

## Pre-Git routed report

Source:

`C:/FPGA/AHD_Capture_Card/v39A_SC1/regression_iter7/postroute_20260729_223238/report_io_v39A.rpt`

Size: 100221 bytes  
SHA-256: `E4BE4DDBA4FB82FD63ED2E6D48723E69117E28D35214727AE950C0440D29FDAF`

Relevant rows:

```text
P10  [blank signal]  Dedicated   PROGRAM_B_0                  Config   Bank 0
T12  [blank signal]  High Range IO_L22P_T3_A05_D21_14       User IO  Bank 14
```

T12 has blank signal, direction, and I/O-standard fields in the report. P10 is the dedicated configuration pin and also has no user signal name.

## Historical constraints

`C:/FPGA/AHD_Capture_Card/AHD_Capture_Card.srcs/constrs_1/imports/Downloads/ahd_capture_card_pins_v05e_ready.xdc:82-111` enumerates control outputs without a self-reconfiguration net. A `sys_reset` token at line 197 denotes an ordinary capture-core reset and is not PROGRAM_B.

Size: 10573 bytes  
SHA-256: `9070E827F6659C9FFE8855EF51EE9106C9F9F391F0E9156D1B346C8B3B20CA5B`

## Classification rule

The task statement is accepted as schematic-level evidence that a prototype once had `FPGA user output -> T12 -> PROGRAM_B_0`. Because accessible implementation artifacts neither name nor instantiate that loop, the correct classification is `PARTIAL`, and the exact signal name is `NONE_IDENTIFIED`.
