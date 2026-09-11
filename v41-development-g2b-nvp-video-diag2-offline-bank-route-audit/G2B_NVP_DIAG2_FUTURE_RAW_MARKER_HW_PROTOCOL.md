
# Future bounded no-DMA raw-marker protocol

This is a design specification only; it was not executed.

## Preconditions

Use a separately governed diagnostic extension exposing coherent source-domain counters for raw byte changes, nonconstant samples, FF, FF00, FF0000, FF0000XY candidates, legal SAV, legal EAV, illegal XY/parity, and parser state/lock. Keep stream disabled; submit no DMA/AIO. Save exact PRODUCT baseline and require zero I2C errors.

## Route order

1. CH1 control -> CH2 failing route -> CH1 control
2. CH3 control -> CH4 failing route -> CH3 control

For every leg: require prior route baseline and quiescence; apply one documented BGDCOL assignment; perform the current C2 hot-switch; verify full C2 readback; wait 250 ms settle; atomically baseline counters; measure 500 ms; read counters coherently; restore the control route; verify readback. Use only Arm A (current hot-switch). Arm B is excluded because no authoritative re-arm sequence exists.

## Discrimination

- VCLK active + near-zero raw toggles: NVP output/data path inactive or held constant.
- Raw toggles + no FF0000XY candidates: emitted data lacks BT.656 marker prefixes.
- Candidates + illegal XY/parity: mode/marker coding mismatch.
- Legal raw SAV/EAV + existing SAV zero: FPGA admission/phase defect.
- Legal markers absent only on routes 1/3: NVP private configuration/route/formatter issue.

Stop on any MMIO/I2C/route/restore error. Restore CH1 route and exact PRODUCT baseline. No full capture matrix is part of this gate.
