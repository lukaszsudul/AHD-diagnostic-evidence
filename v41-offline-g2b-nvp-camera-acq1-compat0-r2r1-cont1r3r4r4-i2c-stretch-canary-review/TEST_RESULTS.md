# Offline test results and bounded interpretation

All 214 preregistered primary cases executed and passed the **checker of their expected experiment outcome**, not a claim that all stimuli were valid or all master commands completed. No refinement case was declared or executed. The unmodified 62.5 MHz/25 kHz master returned raw0/success on 134 cases, raw5/timeout on 72, the four deliberately absent ACK controls returned raw1/raw2/raw3/raw4, and the four deliberately early-release controls returned raw2/raw4. No valid-path false NACK was found. The 42 late-assertion cases completed but exceeded the independently applied `tVD;ACK` criterion and are tolerance stress, not compliant-path proof.

At phase8 ns, zero modeled input delay and stable ACK, the DATA-ACK stretch anchors 1240 extra FPGA cycles (case16) and 1248 (case17) respectively completed with max wait1245/raw0 and timed out with max wait1250/raw5. This is the sampled transition interval, not a universal raw-pin or analog threshold. Case12 (256 extra cycles) had resolved SCL high at 1,127,360 ns; stage-2 sync at +24 ns, filtered high at +72 ns, and ACK sample at 1,147,448 ns. Across recorded nonzero events the SCL raw→stage-2 delay was 16–32 ns and raw→filtered 64–80 ns; SDA low raw→stage-2 was 24–32 ns and raw→filtered 72–80 ns. The 1,4,8,12,15 ns edge phases remained distinct at 1 ps simulation resolution. The nominal 1250-cycle counter conversion is 20 µs; it starts while released SCL is *not yet filtered high*, so it includes modeled recognition delay, and it does not act as a universal bus-idle wall timer.

The matrix covers all eight bits of transmitted `0x05` at 0,64,1248,1260 extra cycles (32 cases), full-duration DATA and REGADDR ACK ladders (36 cases), phase/skew combinations (76), rise-recognition sensitivity (20), late ACK timing (32), address-ACK controls (6), clean transactions (2), absent-ACK controls (4), preceding register-bit stretch (2), and early-release controls (4). The duration ladder includes 0,1,4,16,64,256,625,1000,1200,1240,1248,1249,1250,1251,1252,1260,1300,2500 cycles. No full Cartesian coverage is claimed. Input-high delay anchors 0,32,128,500,1000,2000 ns are digital sensitivity parameters, not measured rise times. Standard-mode generic timing, not NVP-specific stretching compliance, is the cited rule set.

| Check | Outcome | Auditable evidence |
|---|---|---|
| T01 exact source/profile/tool | PASS | `AUTHORITY_AND_SCOPE.md`, `SOURCE_TIMING_AUDIT.md`, private SHA manifest; three frozen compiled design files, XSim 2025.2 SW6299465. |
| T02 filter symmetry/edge latency | PASS | `SOURCE_TIMING_AUDIT.md`, `CASE_RESULTS.csv`; same SCL/SDA two-flop/candidate/count structure, measured ranges above. |
| T03 SCL and bus-idle counters | PASS | `SOURCE_TIMING_AUDIT.md`, cases16–17; threshold is old-count compare at1250, `LL_WAIT_IDLE` and incomplete `LL_STOP_C` only for idle counter. |
| T04 independent open-drain clean read/write | PASS | `MODEL_VALIDATION.md`, cases1–2, pin timelines and emitted bytes/START/STOP. |
| T05 absent ACK/normal read terminal NACK | PASS | cases3–6 yield raw1/2/4/3 by phase; case2 read terminal master NACK is normal. |
| T06 eight data bits + DATA ACK | PASS | cases43–74 all eight bit indices; DATA-ACK full ladder cases7–24. |
| T07 REGADDR ACK and preceding bit | PASS | REGADDR full ladder cases25–42 and two earlier-bit cases75–76. |
| T08 timeout/ACK/NACK boundary | PASS | cases12,16,17 and absent-ACK cases; 72 local raw5 timeouts, zero compliant-path raw NACK. |
| T09 edge phase and recognition | PASS | 1/4/8/12/15 ns cases; distinct timing and measured raw/sync/filter timestamps in `CASE_RESULTS.csv`. |
| T10 ACK setup/illegal late assertion | PASS | `TIMING_RULES.json`, independent classification; 42 `INVALID_TVD_ACK` cases, none treated as a valid defect. |
| T11 ACK hold/premature release | PASS | cases211–214: resolved SDA high during ACK high, raw2/raw4; invalid controls. |
| T12 rise/skew and cancel | PASS | rise anchors 0–2000 ns, asymmetric SDA/SCL cases; separate `MODEL_DELAY_CANCELLATION_PASS` receipt. |
| T13 counterexample or scoped absence | PASS | none in executed valid-path grid; `INDEPENDENT_AUDIT.json` reports zero valid-path false NACK, no broader proof. |
| T14 unchanged scanner integration | PASS | 256-cycle clean and 2500-cycle timeout simulation receipts; gen1/82/105 versus gen0/37, restored bank. Historical absolute generation not claimed. |
| T15 negative checker tests | PASS | `INDEPENDENT_AUDIT.json`: false compliance, phase, byte, pin count, stale completion, result ID, 6/6 rejected. |
| T16 raw-cause lifetime | PASS | `RAW_CAUSE_LIFETIME.md`: new command clears cause; restore/verify obscures raw origin; active MMIO lacks failed-command sticky cause. |
| T17 canary feasibility | PASS as review | `RESET_CANARY_FEASIBILITY.csv`, `RESET_CANARY_DECISION.md`; current path cannot deliver a fresh reset-discriminating post-error canary. |
| T18 NVP/reference review | PASS as review | `NVP_REFERENCE_FINDINGS.md`; absent max stretch/bank settle, SCL input designation, available helper delays/ignored returns, external implementation missing. |
| T19 exact-board documentary review | PASS as review | `PCB_RESET_I2C_FINDINGS.md`; Rev0.1 netlist topology, no serial-linked as-built or qualified probe access. |
| T20 authority/privacy/future-only | PASS | `AUTHORITY_AND_SCOPE.md`, `FUTURE_SINGLE_IMAGE_FIRST_FRAME_PLAN.md`, `NEXT_ONE_ACTION.md`; no hardware contact or new image. |

Required coverage: **20/20 executed checks PASS, 0 blocked/not-run**. Review PASS in T17–T19 confirms an honest disposition, not that the missing vendor limits, reset canary or as-built electrical facts are established. Independent slave/checker gate: 214/214 case checks, 6/6 checker negatives, 214/214 output row/log/pin hash identities. The three checker amendments and CSV-only export repair are disclosed; no silent post-result timing reclassification occurred.

Receiver conclusion: `PASS_NO_FALSE_NACK_IN_EXECUTED_GRID`, subject to finite grid, digital-model and vendor-specific limits. A local SCL timeout on an otherwise generically legal extended LOW is a configured completion limit, not raw DATA_NACK. The physical cause of the historical Bank5 event remains unproven. No NVP hardware or camera claim follows from this simulation.
