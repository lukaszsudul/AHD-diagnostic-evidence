# CONT1R3R4R4 preregistered offline I2C experiment

Frozen before the 214-case primary sweep on 2026-09-17. No DUT or physical bus access. No RTL, parameter, manifest, driver, retry, timeout, filter, XDC, firmware or SSOT change.

## Authority and profile

- `lukaszsudul/FPGA_AHD` commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`.
- Exact compiled design: frozen `rtl/v41/nvp_i2c_fixed_master.sv` SHA-256 `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`.
- Actual instance profile: 62,500,000 Hz FPGA clock; 25,000 Hz nominal I2C; SCL_TIMEOUT_CYCLES=1250; BUS_IDLE_TIMEOUT_CYCLES=62500; 16 ns FPGA period; DIVIDER=1250 and `TICK_CYCLES=1251`.
- XSim 2025.2 SW build 6299465; simulation timeprecision 1 ps, stimulus edge offsets in 1 ns units. No implementation tools run.
- Prior frozen offline evidence commit `74dd150c3438bbea24641cdd8e3bb45e62a5bc65`; inherited raw4 DATA_NACK/scanner0xA mapping is not retested as the principal hypothesis.

## Hypothesis, grid and declarations

Question: can an ACK that is independently valid at the resolved bus and under the cited Standard-mode rules be misread as NACK by the unchanged receiver, at or below its actual timeout budget? The matrix contains 214 distinct primary cases and no random cases. All eight Bank5 write-data bits, data ACK, selected-read register ACK, preceding register bits, write/read address ACKs, no/mid/near/over-limit stretch durations, 1/4/8/12/15 ns edge offsets, SCL/SDA recognition delays, late-ACK setup, and premature-release controls are enumerated in `CASE_MATRIX.csv`. Full Cartesian combinations are not claimed.

The bench slave drives low or releases only, reacts to resolved bus START/STOP and byte/bit edges, and never reads DUT filtered inputs or result to select stimulus. The separate Python checker consumes pin-edge records and result logs; the simulator model's own `phase` label is not trusted as compliance evidence. The emitted master bytes and START/STOP counts are checked. A per-case simulated-time watchdog is 30 ms; a per-process wall-clock watchdog is 45 s. The launcher stops at a missing completion marker, fatal/error log, missing pin trace or checker corruption. Design defects are recorded as design outcomes; a correctly detected design defect does not make the verification check itself FAIL.

Digital release-to-input-high delays of 0,32,128,500,1000,2000 ns are sensitivity variables, **not** measured analog 30–70% rise time or PCB delay. An input rise is cancelled if the resolved wired-AND bus returns low before the delay expires. A late ACK asserted only near the master's SCL release can exceed Standard-mode `tVD;ACK` from the preceding SCL falling edge; such cases are predeclared `TIMING_STRESS_TVD_ACK_UNVERIFIED`, not a compliant counterexample. Deliberately absent ACK and premature ACK release are invalid controls. `GENERIC_VALID_DIGITAL` is conditional on independently checked setup, hold, high/low intervals and acknowledged source limits; NVP-specific compliance remains unverified where its Rev1.0 document has no maximum stretch time.

`RTL_FALSE_NACK_REPRODUCED` requires all of: complete waveform and correct master bytes, resolved ACK low before and throughout clock high for the target byte, cited timing-valid classification, no legitimate timeout, actual completion with raw NACK cause, clean independent replay and unchanged design hash. Timeout raw5 is not scanner0xA. Invalid-timing failures characterize tolerance only. A clean finite grid does not prove all RTL behavior or physical causation. A separate valid-path defect is recorded separately, not recoded as a NACK.

The frozen matrix is not modified in response to outcomes. At most 128 separately declared refinements near a boundary may be added, with a separately hashed amendment before execution. At most three task-owned harness corrections are permitted and each affected case must be rerun; no compiled design file may change. Hardware source of the historical event remains unproven by this experiment.

## Expected checks independent of a predicted threshold

- Clean write and read: emitted `0x60,0xFF,0x05` or `0x60,0xF4,Sr,0x61`; ACKs and terminal master NACK appropriate; raw0/success1.
- Missing write-data ACK: raw4/timeout0; missing register ACK: raw2/timeout0; other missing address ACKs: raw1/raw3.
- Long SCL low hold: measured wait counter and raw5/timeout1 whenever the master reaches its exact local budget. No rule guesses that nominal extra cycle 1250 is the physical-pin threshold.
- Stable valid ACK below budget: raw0/success1; any deviation is retained and investigated, not silently filtered.
- Late assertion and early release controls: timing classification precedes any claim about receiver correctness.

The current task ends in source/canary/PCB documentary conclusions and one future-image design note only. No diagnostic image is created.
