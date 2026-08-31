# PCB-PIN-0 Control I/O Analysis

## Decision

- `CONTROL_PINS = PASS_WITH_CONSTRAINTS`
- `MPP1-MPP4_CURRENT_USE = UNUSED`
- `MPP1-MPP4_REMOVAL = SAFE_WITH_CONSTRAINTS`
- `J18_PULLDOWN_REVIEW = NEEDS_SCHEMATIC_CONTEXT`

## Proposed pins

| Signal | Pin | Exact function | Bank/group | Intended direction | Assessment |
|---|---|---|---|---|---|
| IRQ | K17 | `IO_L4P_T0_D04_14` | 14/T0 | FPGA input | Legal user I/O |
| RST | L18 | `IO_L4N_T0_D05_14` | 14/T0 | FPGA output | Legal user I/O |
| SDA | M17 | `IO_L7N_T1_D10_14` | 14/T1 | Bidirectional open drain | Legal user I/O |
| SCL | N17 | `IO_L9N_T1_DQS_D13_14` | 14/T1 | Bidirectional open drain | Legal; consumes a DQS-capable pin |

All four are bonded HR Bank 14 user I/O in clock region X0Y0. `LVCMOS33` is legal only with `VCCO_14 = 3.3 V`. The proposed pins do not collide with the proposed video pins, PCIe, JTAG, `sys_clk`, or `sys_rst_n`.

K17 and L18 are the P/N halves of one differential-capable pair. Using both independently as single-ended IRQ/RST is legal. M17 is paired with M16; N17 is paired with N16. The unused companions remain usable as independent single-ended I/O but cannot form a differential pair with an occupied half.

Bank 14 pin names include configuration address/data alternate functions. They are user I/O after configuration; external pull-ups and device outputs must not interfere with configuration/startup or drive an unpowered bank.

## I2C behavior

M17 and N17 support the required IOBUF implementation:

- drive value fixed at 0;
- output enable asserted only to pull low; and
- otherwise high-Z with external pull-ups.

The current top already implements that electrical behavior for its present T18/T17 pins with `.I(1'b0)` and tri-state control. Pull-ups must connect to a voltage compatible with NVP and `VCCO_14` and be sized for bus capacitance/speed. Never actively drive a logic 1.

N17 is a DQS-capable T1 pin. It is not needed by either proposed T2 video byte group, so its use does not harm the two capture interfaces. If preserving every high-speed strobe resource is a PCB priority, N18 (`IO_L10P_T1_D14_14`) is a ranked ordinary-I/O alternative for SCL.

## Before/proposed control mapping

| Function | Current accepted mapping | Proposed mapping | Required later action |
|---|---|---|---|
| IRQ | no active port/LOC; historical R17 was removed | K17 | add port/consumer and XDC only after Owner acceptance |
| RST | R17 | L18 | migrate XDC/PCB together |
| SDA | T18 | M17 | migrate XDC/PCB together |
| SCL | T17 | N17 | migrate XDC/PCB together |

No current source is changed by this audit.

## MPP1-MPP4

The exact symbol `nvp_mpp` occurs only as the unused top-level input declaration and its four LOC/IOSTANDARD constraints. Repository-wide read-only search found no synthesizable consumer. Removing the physical MPP connections therefore breaks no current product behavior. The constraint is procedural: the four stale top ports/LOCs must be removed or reassigned in the later accepted source revision before CH2 takes V16, V17, U16 and U17.

## J18 pull-down

J18 is not assigned in current RTL/XDC or reachable Git history. Vivado identifies it as Bank 14 `IO_L3P_T0_DQS_PUDC_B_14`, currently unassigned user I/O. `PUDC_B` is a configuration-stage special function; a 1 kOhm pull-down could change configuration pull behavior and heavily load any future driver. The repository contains no schematic net or configuration intent for J18, so the resistor is not approved by this audit. Resolve the exact schematic net, configuration mode, desired PUDC_B state, and DC contention current first.

