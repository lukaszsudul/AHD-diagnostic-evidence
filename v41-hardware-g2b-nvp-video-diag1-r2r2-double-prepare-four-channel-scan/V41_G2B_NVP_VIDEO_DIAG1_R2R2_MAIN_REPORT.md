
# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R2 main report

Engineering gate: **BLOCKED**

Evidence publication gate: evaluated after the immutable commit and remote
read-back; no self-referential commit hash is embedded in this report.

Overall result: **BLOCKED**

## Outcome

R2R2 stopped before its first hardware contact. The prompt places the exact
SRAM programming, warm reboot, and driver load in Phase B, followed by runtime
identity in Phase C and double-PREPARE in Phase D. However, Owner authorization
section 1.3 conditions those same programming, reboot, and driver operations on
the double-PREPARE baseline gate already having passed. The introduction repeats
that programming follows the baseline gate.

The currently active, Owner-attested runtime is the PRODUCT profile. It does not
instantiate the diagnostic controller or its 0x3C00..0x3FFF diagnostic MMIO.
Therefore PREPARE_A and PREPARE_B cannot execute until the exact R2R1 diagnostic
candidate has first been programmed, enumerated, and opened through the driver.
That programming operation is itself withheld until PREPARE has passed. No
authorized first transition exists.

First blocker:

`BLOCKED — NVP_DIAG1_R2R2_OWNER_AUTHORIZATION_SEQUENCE_CONTRADICTION:SRAM_PROGRAMMING_IS_CONDITIONED_ON_DOUBLE_PREPARE_PASS_BUT_DIAGNOSTIC_PREPARE_REQUIRES_THE_NOT_YET_PROGRAMMED_IMAGE`

## Work completed without hardware

- Created fresh controller root `C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R2_20260910T174941Z`.
- Prepared an unexecuted task-local double-PREPARE and scan controller from the
  accepted R1 host implementation in the fresh root only.
- Added the authorized task-local double-PREPARE controller logic, including
  immutable A/B ledgers, MMIO double reads, positive equal transaction deltas,
  full visible-baseline comparison, PRODUCT cross-check, and PREPARE_B restore
  authority.
- Preserved the firmware-private original-bank disposition without inventing a
  host-visible value.
- Performed a local Python import/argument syntax check of the task-local
  controller.
- Did not change RTL, XDC, IP, DCP, bitstream, PRODUCT source, diagnostic source,
  SSOT, or prior evidence.

## Hardware non-execution receipt

No DUT connection, controller or Linux hardware lock, JTAG access, FPGA
programming, bitstream hash-at-programming check, reboot, PCIe access, driver
load, device-node access, MMIO, NVP I2C, DMA, AIO, capture, frame reconstruction,
or pixel analysis occurred. The Owner-attested PRODUCT image and NVP baseline
remain unchanged.

## Required reconciliation

The Owner/Architect must explicitly authorize exactly one programming of the
accepted diagnostic bitstream, the one required warm reboot, exact driver load,
and read-only runtime identity **before** the double-PREPARE gate. The existing
double-PREPARE gate can then remain the hard prerequisite for all functional NVP
writes, START_4X4_SCAN, route changes, BGDCOL changes, and captures.

No RTL, DCP, or bitstream change is needed.
