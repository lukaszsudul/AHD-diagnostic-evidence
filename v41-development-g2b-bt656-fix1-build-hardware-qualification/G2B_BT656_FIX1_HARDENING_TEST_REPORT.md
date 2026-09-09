# FIX1 hardening tests

Result: **9/9 PASS**

- H1 — exact captured 21-line tail: **PASS** — capture delta 22; line0=0x21; line1=0x20; malformed/drop/attempt/commit/overflow tail deltas 0
- H2 — short legal tails 0,1,20: **PASS** — frame restart and no false malformed
- H3 — overlong tail line 1101: **PASS** — exactly one malformed; no active record
- H4 — capture-sequence semantics: **PASS** — 21 tail increments; boundary delta 22; attempt/global delta 1
- H5 — active-line malformed regression: **PASS** — full affected regression deliberate malformed path
- H6 — overflow independence: **PASS** — full affected regression ring-full path
- H7 — canonical project VBI fixture: **PASS** — captured and short-tail fixtures
- H8 — record ABI byte identity: **PASS** — fixed 4096-byte record regression
- H9 — full affected parser/transport regression: **PASS** — G2B_ONECH_C2H_XSIM_PASS

The first H2/H3 testbench observation ended before the final AXI record had drained. Only the testbench wait was corrected to wait on observable record completion; RTL policy was unchanged. The complete suite then passed.
