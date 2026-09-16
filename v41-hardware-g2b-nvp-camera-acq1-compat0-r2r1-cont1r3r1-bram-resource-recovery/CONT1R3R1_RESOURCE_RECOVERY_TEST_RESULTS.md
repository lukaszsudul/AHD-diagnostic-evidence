# CONT1R3R1 resource-recovery gate — candidate 1, interim

Source commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`; source tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`. The frozen source is unchanged by the task-local supplemental test benches. This is **not** a 24/24 PASS receipt yet: R21 needs a signed-off image link and R23 needs the effective endpoint/SSH gate.

Evidence roots below are relative to the fresh CONT1R3R1 task root. A PASS means the stated source/report/test was actually inspected or run. Vivado simulation `Fatal:` lines are checked from logs because `xsim` may itself exit 0 after a fatal assertion.

| ID | Interim result | Executed evidence / precise scope |
|---|---|---|
| R01 | PASS | `resource-iterations/candidate1/NARROW_MEMORY_INFERENCE.txt`, `POST_OPT_CANDIDATE_RESULT.txt`: 1 new telemetry RAMB36E1; post-opt hierarchy shows SCAN1 96 LUTRAM, not the prior 1,008-LUTRAM payload fallback. |
| R02 | PASS | `simulation/candidate1_extended/c1r3r1_extended.log`: all 870 group/entry payload words compared byte-exactly with the frozen CONT1R3 RTL in clean, 3-event, 82-event and post-reset clean scans. |
| R03 | PASS | Same extended RTL test reads all valid words, first/last records, identity, group/entry gaps, unaligned and reserved extension addresses; no alias observed. |
| R04 | PASS | Extended RTL test asserts no response one edge after accepted RAM read and exactly one response two edges after acceptance. |
| R05 | PASS | Extended RTL test retains valid/data/ready behavior for eight held cycles and rejects duplicate response. |
| R06 | PASS | `simulation/candidate1_mmio/c1r3r1_mmio.log`: actual shared AXI-Lite bridge alternates SCAN1, ACQ and telemetry targets under receiver backpressure without reorder or duplicate. |
| R07 | PASS | Same bridge test offers a command write while a read response is held, requires AW/W not accepted, then issues a zero-valued inert ACQ control write after read completion and requires one response with no executor/bus action. |
| R08 | PASS | Extended test covers entry 0/81, group 0/9, max payload address and both implementation-ID words. |
| R09 | PASS | Injected writer fault followed by reset and complete clean scan rewrites and compares all 870 payload words; publication count is 82 entries/10 groups. |
| R10 | PASS | All 82 entries incur recovered first-attempt RADDR NACK in directed RTL test; all 82 events and final record survive, no false overflow. |
| R11 | PASS | `reports/CONT1R3R1_WRITER_SERVICE_ENVELOPE.md` plus `simulation/candidate1_extended/c1r3r1_real_master.log`: effective 62.5 MHz/25 kHz master waits 1,251 cycles from acceptance to START_A, actual read completes at cycle 102,791 versus 12-cycle conservative writer bound. |
| R12 | PASS | Extended directed run includes first-start/retry/group transitions, 3- and 82-event scans, and exact 870-word parent comparisons; service fault remains zero in accepted scans. |
| R13 | PASS | Extended test continuously asserts that `telemetry_complete` implies no writer/pulse/fault, exactly 82 committed entries, 10 groups and 82 exposures. |
| R14 | PASS | Extended test forces an impossible overlapping flush; overflow becomes explicit and complete/frozen remains false. |
| R15 | PASS | Extended reset test requires stale generation invalid, then a complete 870-word rewrite; RAM data is not reset as a block. |
| R16 | PASS | Directed hard-error scan verifies status not complete and exposure/committed-entry count below 82. |
| R17 | PASS | Success and retry-failure directed cases retain original WADDR/REGADDR/RADDR first cause separately from retry outcome. |
| R18 | PASS | Extended test seeds full 64-bit tick counter at `0x00000001FFFFFFF0`, crosses low-word wrap, confirms nonzero upper word and compares all words to frozen parent. Host observability T23 rejects ambiguous wrap. |
| R19 | PASS | Directed 3-event case asserts entry 5 position +1 in G0-LOCK; inherited T12/T13 cover position and same-bank/changed-bank context. |
| R20 | PASS | Scanner command/control equivalence over 30,700 cycles and 757 accepted commands in extended test; fixed master source SHA unchanged `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`; inherited master tests PASS. No physical-delay equivalence claim. |
| R21 | PENDING_SIGNOFF | `runtime-bundle/test_implementation_identity.py` accepts exact magic/version and rejects old/missing/wrong values. Link to exact signed-off DCP/bitstream receipt cannot be completed before final sign-off. |
| R22 | PASS | Extended test rereads all 870 frozen words in coprime shuffled address order before ACK and compares with the frozen CONT1R3 reference. |
| R23 | PENDING_ENDPOINT_GATE | Closed payload has exact `10.132.1.111:22`, no fallback; local manifest/import/projection gate PASS. Conflicting SSH key and effective DUT connection must be checked only after offline sign-off. No DUT contact has occurred. |
| R24 | PASS | Inherited observability T28 decodes 20 recovered events without cap; RTL directed run retains 82/82; T06–T08 and directed timeout/hard-error cases keep hard-stop behavior. |

Interim count: **22 PASS, 2 PENDING; resource-recovery gate NOT YET PASSED**. Full routed timing/resource gates, bitstream, DUT bundle, runtime and 1,000-scan campaign are independent and unreached at this point.

Final disposition: **22 PASS, R21 NOT_REACHED (no signed-off image), R23 NOT_REACHED (no SSH/DUT access)**. The 24/24 gate did not pass.
