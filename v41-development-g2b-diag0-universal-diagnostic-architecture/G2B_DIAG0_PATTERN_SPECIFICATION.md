# Normative deterministic video patterns

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


All integer shifts below are unsigned; u32(x)=x mod2^32; byte(x)=x mod256. F is source_frame_sequence in the header (first ever frame1; not reset at START), L is source_line_sequence0..1079, q is pair index0..959, k is lane0..3. Pattern selection and seed context are held per record.

safe8(x): b=byte(x); return1 if b==0 else254 if b==255 else b.
This avoids reserved00/FF video payload bytes and accidental FF0000 marker detection. It is normative, not an undocumented escape in the host. Record-mode payload uses raw bytes and bypasses the parser.

PATTERN_0 COLOR_BARS_WITH_FRAME_ID: select bar=floor((2*q)/240) (eight equal240-pixel bars). (Y,U,V) table, in order white,yellow,cyan,green,magenta,red,blue,black:
[(235,128,128),(210,16,146),(170,166,16),(145,54,34),(106,202,222),(81,90,240),(41,240,110),(16,128,128)]. Emit [U,Y,V,Y]. Override top32 lines and first512 pixels:32 binary tiles of16 pixels. For pair q<256 and L<32, bit=(F >> floor((2*q)/16)) &1; emit [128,235 if bit else16,128,235 if bit else16]. This shows low32 frame bits, little-bit-order left to right; no font.

PATTERN_1 XY_FRAME_RAMP: payload[4*q+k]=safe8(F + 3*L + 5*q + 67*k). Thus all U/Y/V lanes depend deterministically on frame,line,pair and lane; wrap before safe8. Simple constant adds/shifts, no multiplier required.

PRBS31 exact recurrence: polynomial x^31+x^28+1. State s is31 bits, never zero. next_bit(): b=(s>>30)&1; s=((s<<1)&0x7fffffff) | (((s>>30)^(s>>27))&1); return b. next_byte(): sum(next_bit()<<j for j=0..7). This recurrence and bit order are normative even if a library labels reciprocal-polynomial implementations differently.

fold64(x)=u32(x) XOR u32(x>>32).
seed(R,C,F,L)=((0x7fffffff XOR fold64(R) XOR rotl32(fold64(C),7) XOR rotl32(u32(F),13) XOR u32(L)) &0x7fffffff); replace zero with1.
rotl32(x,n)=u32((x<<n)|(x>>(32-n))).

PATTERN_2 PRBS31 in video: reseed at each line with seed(RUN_ID,CYCLE_ID,F,L); emit safe8(next_byte()) for offsets0..3839 in ascending order. SEGMENT_ID does not enter seed; resumed frame identity is reflected in F and the manifest. Never advance generator state during a stall or for bytes not accepted by the synthetic parser. Host can reproduce a line independently; no full frame BRAM needed. R/C are64-bit metadata from the host run manifest, not repurposed ABI fields.
