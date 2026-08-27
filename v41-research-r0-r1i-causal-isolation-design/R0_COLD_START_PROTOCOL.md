# AHD v41 R0 — Exact R1i Ten-Cold-Start Protocol

## Purpose and separation

This protocol measures repeatability of the **exact qualified R1i** image. It is separate from the C0/C1/C2/C3 causal campaign. Its observations may be captured alongside INIT_DONE timing fields, but they are not pooled with factorial runs and cannot change the frozen functional verdict.

No part of this protocol is executed in R0.

## Frozen article

- Source commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- Runtime common identity: must equal the published qualified identity and decode cleanly
- Starts: exactly 10 consecutive valid cold starts
- DUT, cabling, pull-ups, power source, host, decoder, and environmental envelope: unchanged

## Definition of a valid cold start

A valid cold start requires complete DUT/NVP rail removal, not a warm FPGA reset or reprogramming event. Use the project-approved power procedure and hold power absent for a fixed 30 seconds, with power-good deasserted and the host function absent. If those conditions cannot be verified, label the trial invalid.

The exact R1i image must be the first FPGA image allowed to exercise the NVP after power returns. An automatic boot image that touches the NVP before R1i contaminates the trial. Use an approved boot-inhibit/first-configuration method; do not silently compensate in software. If first-image control is unavailable, the cold-start campaign is blocked pending a safe procedure.

The ten starts form one locked, consecutive research campaign. No other FPGA image, G-track work, probe traffic, warm-reset test, or unrelated hardware activity may be interleaved. Restore the approved safe baseline once, after trial 10 or after an abort, before releasing the lock.

## Preflight

1. Acquire `FPGA_AHD_HW_LOCK` exclusively and record owner, DUT, UTC/monotonic times, and intended image hash.
2. Verify there is no G-track hardware activity.
3. Verify the R1i file SHA-256 before the campaign and again before any re-load caused by a failed programming attempt.
4. Freeze the power-off/on/program/start recipe, host polling cadence, decoder revision/hash, video measurement window, and ambient-data source.
5. Verify that raw telemetry can be captured before any post-init diagnostic traffic.
6. Record the approved restoration image and expected identity. Preferred: Formal Phase-2 SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.

## Trial procedure, repeated exactly 10 times

1. Record trial number, UTC and host monotonic epoch, operator/task, DUT, power-controller state, ambient temperature if available, and predecessor (`NONE` for trial 1; exact R1i cold trial for later trials).
2. Remove DUT/NVP power using the frozen procedure. Confirm power-good deassertion and host-function absence. Hold for 30 seconds.
3. Start the host monotonic capture before power-on. Restore power and make exact R1i the first NVP-driving FPGA configuration.
4. Record programming/configuration receipt, bitstream SHA, independent DONE/configuration indication, runtime identity words, and source commit.
5. Poll raw init status without issuing post-init I²C probe traffic. Preserve last decoded `INIT_DONE=0` and first `INIT_DONE=1` (or timeout) snapshots with monotonic timestamps.
6. Immediately capture raw autoinit telemetry and decode it. Do not clear counters until both raw and decoded artifacts are sealed.
7. Record the required per-start evidence:
   - `INIT_DONE`;
   - `INIT_ERROR`;
   - WADDR autoinit NACK/opportunity count;
   - REGADDR autoinit NACK/opportunity count;
   - DATA autoinit NACK/opportunity count;
   - total retry count and success-on-retry lanes;
   - recovered transaction and recovered NACK counts;
   - retry-exhausted and unrecovered counts;
   - SCL timeout/unavailable count and wait maximum;
   - video present/absent;
   - frame rate using the qualified measurement method;
   - runtime/common/source/bitstream identity.
8. Also preserve RADDR counts, raw qualified NACK total, early/early-false counters, failed-attempt log, bank validity/invariant counters, counter start/done/delta, host event brackets, and environmental/order fields.
9. Do not use later probe traffic to reinterpret the autoinit snapshot. Optional post-init diagnostics begin only after the snapshot is sealed and are reported separately.
10. Mark the trial `VALID`, `INVALID`, `CLEAN_PASS`, `RECOVERED_PASS`, or `FAIL` under the rules below. Continue to the next trial without interleaving another image or task unless safety requires abort.

## Frozen acceptance and classification

The requested robustness target is met only if all 10 valid consecutive starts satisfy:

- `INIT_DONE=1`;
- `INIT_ERROR=0`;
- WADDR + REGADDR + DATA autoinit NACK total = 0;
- video present;
- runtime identity valid and exact;
- SCL timeout/unavailable count = 0;
- retry-exhausted count = 0 and unrecovered count = 0.

Because a qualified/raw NACK causes recovery, the expected clean result also has retry count = 0 and recovered count = 0. If terminal acceptance appears to pass but retry/recovered activity is nonzero, classify that trial `RECOVERED_PASS`, the 10/10 **clean** robustness claim is not supported, and trigger secondary/R3 review. Do not hide the recovery behind `INIT_ERROR=0`.

Frame-rate corroboration is valid at 24.803727 Hz ±0.10 Hz using the same method. A missing or out-of-range value makes the trial non-clean and requires review; it does not identify the ACK mechanism.

Invalid trials do not count toward 10 and are repeated only for a documented procedural cause. A functional failure is not invalidated or repeated away. Stop immediately on identity mismatch, unsafe power state, corrupted telemetry, or loss of hardware lock.

## Completion and restoration

After trial 10—or after any safety abort—program and verify the exact approved safe baseline while still holding `FPGA_AHD_HW_LOCK`. Record its bitstream/runtime identity and the restoration time. Release the lock only after restoration passes. If restoration fails, retain the lock and escalate.

Final cold-start classifications are `10/10 CLEAN_PASS`, `ROBUSTNESS_NOT_SUPPORTED`, or `INCONCLUSIVE` for procedural/measurement invalidity. They do not alter the historical `STRONG_PASS` qualification.
