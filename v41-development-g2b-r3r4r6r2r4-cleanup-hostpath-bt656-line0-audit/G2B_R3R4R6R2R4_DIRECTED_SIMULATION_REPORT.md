
# Directed simulation report

Simulator: Vivado XSim 2025.2. The DUT was the unmodified PRODUCT source
`v41_g2b_onech_c2h.sv`, SHA-256
`8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`.
Task-local focused testbench SHA-256:
`608D2965BD7650B44F70063E1C4D941D707921B3A06B3DB3C15FBD6241A92AE0`.

| Test | Result | Evidence and limitation |
|---|---|---|
| 1 stable active-line capture | PASS | consecutive clean lines 2 and 3; no malformed, discontinuity, or overflow flags |
| 2 complete frame boundary | PASS | unmodified RTL driven through line 1079 and the existing project VBI fixture commits next-frame line 0 with SOF, then line 1; malformed delta 0 |
| 3 reproduce hardware failure | INSUFFICIENT_AUTHORITATIVE_STIMULUS | project VBI fixture does not reproduce 1079->1 or +21; repository lacks a cycle-accurate authoritative NVP boundary trace; no stimulus was tuned to force 21 |
| 4 deliberate malformed active line | PASS | existing full regression proves early EAV drops one bounded attempt and puts MALFORMED_PRECEDING on the next structurally integral record |
| 5 overflow independence | PASS | existing full regression proves ring-full overflow/drop context without incrementing source malformed solely from overflow |
| 6 first-active-line admission | PASS | with lock retained, line 0 is admitted; with lock cleared, line 0 is observed with monitor_has_attempt=0, valid EAV relocks, and line 1 is next committed |

Focused marker:
`R3R4R6R2R4_FOCUSED_LINE0_SOF_XSIM_PASS`.

Existing full parser/transport regression marker:
`G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16`.

The test proves the conditional lock/admission code path and disproves a simple
line-counter error. It does not provide the missing physical NVP boundary bytes,
so it cannot identify which exact 21 parser episodes occur in hardware.
