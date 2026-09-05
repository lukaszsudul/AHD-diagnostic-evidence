# Pacing and maximum rate

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


RATE_MODE=0 PACED_1080P25,1 MAX_RATE. Video supports both. Record requires MAX_RATE; LIVE uses observed real timing and accepts only rate0 (no synthesized live pacing). axi_aclk=62500000Hz yields exact40000us frame period and2500000 ticks/frame. Timers use clock enables, not divided fabric clocks. Millisecond tick divider is62500 cycles;64-bit tick count is available through snapshot.

Paced synthetic frame target starts are t0+k*2500000 ticks, with t0 the first actual admission after preparation. Admit only at target and when a whole-frame run budget remains. If downstream stalls prevent meeting the next target, set PACE_OVERRUN, record the missed deadline and terminate gracefully after the current frame. Never silently catch up, drop frames or claim25fps under unbounded backpressure. Achieving25fps is conditional on adequate downstream service; scheduling cannot force TREADY.

Two-byte parser provides125MB/s byte processing. (4+3840+4+32)*1080=4190400 byte steps/frame, at most2095200 base ticks, plus at most32 housekeeping ticks/line and128 frame ticks =2129888 ticks<2500000. Leaves370112 ticks (5.92ms) for bounded overhead. Implement this as a DIAG1 assertion against golden timestamps. Filler and header operations must not accidentally add a second full-line copy. A1byte/tick architecture would fail this test and is forbidden.

MAX_RATE omits real blanking; retain minimum synthetic parser housekeeping/filler and full logical frame/line semantics. Synthetic video need not reach the record-mode throughput target. Record producer runs one64-bit stored word each tick with bounded inter-record overhead and waits for available slot BEFORE assigning an eligible attempt. Stalls do not consume an attempt or fabricate drops. All input words/pattern state hold while not accepted.
