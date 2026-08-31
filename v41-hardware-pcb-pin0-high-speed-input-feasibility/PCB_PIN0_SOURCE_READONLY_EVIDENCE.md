# PCB-PIN-0 Source Read-Only Evidence

## Repository identity

- Workspace: `C:\FPGA\FPGA_AHD`
- Branch: `main`
- Commit: `be94f88ee8d179f12928ab791bdae27c22cd1762`
- Before status: `## main...origin/main`
- After status: `## main...origin/main`
- Worktree diff exit: 0
- Index diff exit: 0
- Source modified: NO
- XDC modified: NO

The canonical project declares `PART=xc7a35tcsg325-2` in `scripts/project_common.tcl:2`, and the accepted Vivado I/O report identifies device xc7a35t, speed file -2, package csg325.

## Current accepted pins

| Function | Current pin(s) | Read-only source |
|---|---|---|
| VCLK1 | E13 | `xdc/boards/current/pins.xdc:15-17` |
| VDO1[0:7] | A14, B14, A15, B15, B16, A17, B17, C18 | `xdc/boards/current/pins.xdc:6-14` |
| PCIe refclock | D6/D5 | `xdc/boards/current/pcie_pio.xdc:3-4` |
| PCIe PERST# | C8 | `xdc/boards/current/pcie_pio.xdc:5-7` |
| PCIe RX | G4/G3 | `xdc/boards/current/pcie_pio.xdc:8-9` |
| PCIe TX | B2/B1 | `xdc/boards/current/pcie_pio.xdc:10-11` |
| NVP reset | R17 | `xdc/boards/current/nvp_control.xdc:4` |
| NVP SCL/SDA | T17/T18 | `xdc/boards/current/nvp_control.xdc:5-6` |
| NVP power enables | A9/A10 | `xdc/boards/current/nvp_control.xdc:7-9` |
| MPP[0:3] | V16, V17, U16, U17 | `xdc/boards/current/nvp_control.xdc:16-20` |

The current VCLK1 clock is constrained to 6.734 ns. The current physical frontend already instantiates an IBUF, BUFIO, global fabric clock branch, eight IBUFs and eight IDDRs (`rtl/video/physical_frontend.sv:28-60`). Only rising samples are presently used.

## Before/proposed mapping

| Signal | Before | Proposed | Current owner of proposed pin |
|---|---|---|---|
| VCLK1 | E13 | E16 | unassigned |
| VDO1[0] | A14 | B16 | current VDO1[4] |
| VDO1[1] | B14 | C16 | unassigned |
| VDO1[2] | A15 | A17 | current VDO1[5] |
| VDO1[3] | B15 | B17 | current VDO1[6] |
| VDO1[4] | B16 | C17 | unassigned |
| VDO1[5] | A17 | C18 | current VDO1[7] |
| VDO1[6] | B17 | E17 | unassigned |
| VDO1[7] | C18 | D18 | unassigned |
| VCLK2 | no port/LOC | R16 | unassigned |
| VDO2[0] | no port/LOC | R18 | unassigned |
| VDO2[1] | no port/LOC | T15 | unassigned |
| VDO2[2] | no port/LOC | T18 | current `nvp_sda` |
| VDO2[3] | no port/LOC | T17 | current `nvp_scl` |
| VDO2[4] | no port/LOC | U17 | current `nvp_mpp[3]` |
| VDO2[5] | no port/LOC | V17 | current `nvp_mpp[1]` |
| VDO2[6] | no port/LOC | U16 | current `nvp_mpp[2]` |
| VDO2[7] | no port/LOC | V16 | current `nvp_mpp[0]` |
| IRQ | no active port; historical R17 | K17 | unassigned |
| RST | R17 | L18 | unassigned |
| SDA | T18 | M17 | unassigned |
| SCL | T17 | N17 | unassigned |
| 27 MHz | no port/LOC | C13 | unassigned |

The canonical top has no VCLK2, VDO2, 27 MHz or IRQ port. The proposed CH2/control changes therefore require a later coordinated source revision after Owner acceptance. No proposed pin conflicts with active PCIe or dedicated JTAG pins.

## MPP and J18

`nvp_mpp` appears only in the top-level input declaration (`rtl/top/ahd_capture_top_pcie.v:95`) and its XDC assignments. No synthesizable consumer exists: `MPP1-MPP4_CURRENT_USE=UNUSED`.

J18 does not appear as a signal mapping in current source or reachable Git history. The accepted I/O report lists it as unassigned Bank 14 `IO_L3P_T0_DQS_PUDC_B_14`; schematic/configuration context is required before approving a pull-down.

## Historical note

`A35T_R17_CANDIDATE_DIFF.md:17-23` records the target migration from xc7a15tcsg325-1 to xc7a35tcsg325-2, NVP reset R18 to R17, and removal of the former unused IRQ mapping at R17. The A15T/-1 text retained in the vendor PCIe XDC header is generator provenance, not the actual project target.

