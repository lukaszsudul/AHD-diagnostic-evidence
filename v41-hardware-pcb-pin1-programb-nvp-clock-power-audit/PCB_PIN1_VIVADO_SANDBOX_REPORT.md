# PCB-PIN-1 Vivado Sandbox Report

## Result

VIVADO_SANDBOX = PASS

Tool: Vivado v2025.2, build 6299465  
Exact target: `xc7a35tcsg325-2`  
Run type: isolated in-memory project, synthesis through route and DRC  
Product bitstream: not requested and not produced

## Sandbox boundary

The run used only `C:/FPGA/PCB_PIN1_VIVADO_SANDBOX_VIVADO_PINS_20260901_001`. It did not open or modify the active AHD Vivado project, source, XDC, PCB, or SSOT. The batch script contains no `write_bitstream` command.

Command recorded by the Vivado log:

```text
vivado.exe -mode batch -notrace -source query_device.tcl -log query_device_retry.log -journal query_device_retry.jou
```

The raw Tcl, Verilog, XDC, log, and generated text reports are published under `raw/vivado_sandbox/`.

## Tested resource path

The minimal design was:

```text
D13 IBUF
  -> BUFGCE, CE_TYPE=SYNC
  -> ODDR, D1=1, D2=0, CE=1, INIT=0
  -> OBUF
  -> A14
```

T12 supplied the enable only inside the disposable sandbox. It is not a product-pin proposal, not a replacement for the removed PROGRAM_B loop, and creates no active XDC assignment.

This topology validates a legal synchronized-BUFGCE/fixed-ODDR alternative resource path. It does not validate the exact preferred continuous-BUFG/dynamic-D1 control contract, whose enable synchronizer and timing still require later product RTL/timing verification.

## Exact part and I/O evidence

The batch log reports:

```text
PART_COUNT=1
PART_NAME=xc7a35tcsg325-2
PART_FAMILY=artix7
PART_DEVICE=xc7a35t
PART_PACKAGE=csg325
PART_SPEED=-2
```

Post-route `report_io` reports:

| Port | Package pin | Exact pin function | Direction | I/O standard | Bank |
|---|---|---|---|---|---:|
| `osc27_d13` | D13 | `IO_L11P_T1_SRCC_15` | input | LVCMOS33 | 15 |
| `nvp_clk_a14` | A14 | `IO_L8N_T1_AD10N_15` | output | LVCMOS33, DRIVE 8, SLEW SLOW | 15 |

The report also identifies VCCO_15 package rails as 3.30 V in the sandbox I/O plan. Drive and slew are sandbox choices only; their final values require product SI review.

Prior published PCB-PIN-0 Vivado device-database evidence independently identifies D13 as `IOB_X0Y78`, clock-capable SRCC in Bank 15, and A14 as `IOB_X0Y83` in Bank 15. This new run adds actual placed/routed ODDR evidence.

## Placed cells

| Cell | Implemented primitive | LOC | BEL | Result |
|---|---|---|---|---|
| `u_ibuf` | IBUF | `IOB_X0Y78` | `IOB33.INBUF_EN` | fixed at D13 input site |
| `u_bufgce` | BUFGCTRL | `BUFGCTRL_X0Y16` | `BUFGCTRL.BUFGCTRL` | placed global buffer |
| `u_oddr` | ODDR | `OLOGIC_X0Y83` | `OLOGICE2.OUTFF` | fixed in A14 output logic |
| `u_obuf` | OBUF | `IOB_X0Y83` | `IOB33.OUTBUF` | fixed at A14 output site |

Vivado transformed the 7-series BUFGCE abstraction to BUFGCTRL as expected. The generic sandbox instance left `SIM_DEVICE` at its library default, so Vivado warned and normalized it from ULTRASCALE to 7SERIES; any later explicit 7-series BUFGCE instantiation should set that simulation property correctly. Clock utilization reports D13/IBUF at `IOB_X0Y78` in clock region X0Y1 feeding `BUFGCTRL_X0Y16`, with a 37.037 ns nominal clock and the ODDR as the clock load.

## Route, DRC, and timing

- synthesis: completed successfully;
- optimization: completed successfully;
- placement: completed successfully;
- routing: completed successfully;
- routable nets: 6 of 6 fully routed;
- nets with routing errors: 0;
- DRC errors: 0;
- DRC critical warnings: 0;
- DRC warnings: 1; and
- timing report: all user-specified sandbox constraints met.

The only DRC warning is `CFGBVS-1`, because the intentionally minimal sandbox did not set configuration-bank `CFGBVS` and `CONFIG_VOLTAGE` properties. The active read-only product file `xdc/common/configuration_bank.xdc` already specifies `CFGBVS=VCCO` and `CONFIG_VOLTAGE=3.3`; the warning does not concern D13, A14, clock routing, ODDR placement, or LVCMOS33 legality.

The timing report has no ordinary setup/hold endpoint because the sandbox ODDR data is constant and the asynchronous external gate input is intentionally false-pathed. It also identifies the expected absence of an A14 output delay because no NVP/PCB interface timing specification was supplied. Its useful timing result is the successful 27.000 MHz clock/pulse-width check with 35.445 ns slack. This is a resource-legality run, not final product timing signoff.

## Query-flow disclosure

An early pre-synthesis `get_package_pins` loop returned `PIN_COUNT=0` because the in-memory design had not yet been linked/elaborated into a device context. Those zero counts are non-probative and are not used as pin-validity evidence. Pin identity is based on the prior PCB-PIN-0 device-database export plus this run's post-route `report_io`, port sites, and placed cell LOC/BEL properties.

## Conclusion

The isolated implementation proves that the exact device can legally route a 27 MHz LVCMOS33 signal from D13 through a global clock resource and place an ODDR in A14's dedicated OLOGIC before its LVCMOS33 OBUF. It supports:

- `D13_27MHZ_INPUT = VALID`;
- `A14_NVP_CLOCK_OUTPUT = VALID_WITH_CONSTRAINT`; and
- `VIVADO_SANDBOX = PASS`.

The A14 active-XDC ownership conflict, configuration-stage pull behavior, external pull-down, NVP power-domain constraints, and later product timing/SI work remain outside this minimal legality proof and are handled by the other PCB-PIN-1 artifacts.
