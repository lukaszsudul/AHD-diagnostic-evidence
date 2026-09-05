# Normative synthetic record operation

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


RECORD_LIMIT=0 continuous;1..0xffffffff exactly that many complete4096-byte records per cycle, absent a prior time/stop/error event. T1 uses1. The limit counts TLAST handshakes. Reserve a finite record budget at admission so filling/committed/inflight records cannot exceed remaining demand. Counters are64-bit even when the configured limit is32-bit.

Synthetic records are virtual valid active lines in the unchanged video-shaped ABI, not opaque records with reinterpreted header fields. Virtual line increments0..1079, then next virtual frame; first frame1. This source frame/capture state persists across transport epoch resets/START. A finite record test may end within a virtual frame; host record mode does not claim that prefix is a complete video frame. Header VALID means the generated3840-byte virtual line was complete. Logical channel0, active count1, physical_input_id0 remains an ABI-compatible fixture mapping; source identity comes from ACTIVE and the manifest, never a new physical-input enum.

Let R=RUN_ID,C=CYCLE_ID,Q=zero-based synthetic record ordinal within the cycle,j=payload offset0..3839. No admitted record may vanish unnoticed: on successful MAX_RATE synthetic runs Q has no gaps. Q is recorded out of band as cycle-first global sequence plus ordinal, including modulo wrap tracking; transport resets do not occur within a healthy record cycle.

COUNTER_PATTERN (record pattern0): byte_j=(fold64(R)+3*fold64(C)+5*fold64(Q)+j) mod256. fold64 is defined in the video pattern specification. This defines every byte and has no dependency on host timing.

PRBS31_PATTERN (record pattern1): s=((0x7fffffff XOR fold64(R) XOR rotl32(fold64(C),7) XOR rotl32(fold64(Q),13)) &0x7fffffff); if zero use1. At every record reseed; byte_j=the jth next_byte() from the exact PRBS31 recurrence in PATTERN_SPECIFICATION. Do NOT apply safe8 in record mode. Eight byte steps generate each64-bit write word; state advances only on accepted ring write. Use a parallel64-bit LFSR transform and pipeline as needed, never serialize at1bit or1byte/AXI tick.

Normative host validator: negotiate unchanged ABI; for each fixed4096-byte record validate header/padding; derive Q from expected ordinal and run/cycle manifest, independently regenerate3840 bytes using the selected formula, compare every payload byte. Require global sequence contiguous, correct virtual frame/line and unchanged input mapping; increment Q only for a complete accepted record. A reported aborted/uncommitted attempt is an explicit failed-test event, not a silent Q repair. Bytes0..63 retain ABI header layout;3904..4095 are zero.
