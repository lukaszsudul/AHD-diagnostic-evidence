# PCB-PIN-0 IDELAY / ISERDES Architecture

## Resource conclusion

All proposed video data pins are bonded HR user I/O with local ILOGIC and input IODELAY resources. Consequently:

- IDDR is supported for CH1 and CH2.
- ISERDESE2 is supported for CH1 and CH2.
- IDELAYE2 is supported for CH1 and CH2.
- BUFIO/BUFR are reachable from E16 and R16 within their respective clock regions.

The package `T2` token is the 7-series pin-name grouping used for this local byte group. It is not a timing grade. Vivado 2025.2 returns no modern `PKGPIN_BYTEGROUP` object for these 7-series pins, so the report does not invent one: the objective locality keys are exact `PIN_FUNC` T2, bank, clock region, and `BUFIO_2_REGION`. Every CH1 pin is Bank 15/X0Y1/T2/LB; every CH2 pin is Bank 14/X0Y0/T2/LB. The informal request to keep data in “T0-T3” is therefore satisfied more tightly: each full interface occupies only the package-name T2 group.

## IDELAYCTRL

IDELAYE2 taps are calibrated by IDELAYCTRL. The exact device exposes the relevant left-side sites `IDELAYCTRL_X0Y1` for the CH1/Bank 15 region and `IDELAYCTRL_X0Y0` for the CH2/Bank 14 region. Plan one control instance/group per channel/region; the reference clock may be shared. Assign consistent `IODELAY_GROUP` properties to each controller and the IDELAYE2 instances it calibrates, or use a supported replicated-controller flow.

The locally installed 7-series IDELAYE2 model accepts `REFCLK_FREQUENCY` windows 190-210, 290-310, or 390-410 MHz; 200.0 MHz is the normal default. Direct 27 MHz is therefore not compliant. No direct compliant IDELAYCTRL reference is present in the current top-level architecture. A later design may create a stable 200 MHz clock from the corrected D13/27 MHz input or another reference with an MMCM/PLL, provided the generated frequency is legal and IDELAYCTRL remains reset until the source is stable/locked. Reassert reset after reference-clock disruption and use `RDY` in initialization policy.

## Direct hard-resource evidence

For each video IOB coordinate Vivado exposes the matching ILOGIC and IDELAY sites. For example, E16 at `IOB_X0Y72` has `ILOGIC_X0Y72` with alternate site types `ILOGICE2` and `ISERDESE2`, plus `IDELAY_X0Y72` with IDELAYE2. Direct isolated placement of IDDR, ISERDESE2 and IDELAYE2 at that coordinate succeeds; the same coordinate relationship was enumerated for all proposed video data sites in X0Y0/X0Y1.

## Receive choices

### SDR

Use an IOB input register or IDDR and consume the rising-edge output. BUFIO minimizes clock insertion and keeps capture local. Per-bit IDELAY is optional and should be justified by the actual timing window.

### Two-edge DDR

Use IDDR with `SAME_EDGE` or `SAME_EDGE_PIPELINED` semantics selected to match downstream logic. This produces two samples per 148.5 MHz clock. If ISERDESE2 is used instead, supply its high-speed BUFIO clock and a phase-related divided word clock via BUFR/clock management, then constrain both domains.

### Deskew

Insert IDELAYE2 before IDDR/ISERDESE2 when static board skew or sampling-margin tuning needs it. Do not treat the existence of IDELAY taps as a substitute for source timing or PCB length control. Establish a calibration/training procedure if variable delay is used.

## Recommended status

| Channel | BUFIO + IDDR | BUFR word/fabric clock | IDELAYE2 | ISERDESE2 |
|---|---|---|---|---|
| CH1 | RECOMMENDED | RECOMMENDED | OPTIONAL | OPTIONAL |
| CH2 | RECOMMENDED | RECOMMENDED | OPTIONAL | OPTIONAL |

For a future DDR multiplex mode, IDDR becomes recommended rather than optional. IDELAYE2 remains margin-dependent but its controller/reference infrastructure must be designed in advance if the PCB timing budget relies on it.
