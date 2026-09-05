# Future hardware test ladder

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


No hardware gate executed. Prerequisites: DIAG1 full offline sign-off, correct diagnostic bitstream/hash, B1/B2 resolution for live stage, authorized future hardware session, known BDF and stable host capture environment. Preserve PRODUCT bitstream as independent recovery/reference.

|Gate|Stimulus|Required evidence / stop rule|
|---|---|---|
|T0|one diagnostic programming;PCIe/XDMA/MMIO|identity tuples agree,MMIO1.0,no unsolicited C2H|
|T1|one deterministic record|exact4096 bytes,header/padding/pattern pass,counter1|
|T2|finite bursts plus deliberate backpressure|no unexplained loss/duplication,stall counter,TLAST/TKEEP proof from RTL plus available hardware telemetry|
|T3|continuous MAX_RATE record|>=288decimalMB/s payload and>=307.2MB/s transport measured over reported window;75000records/s;pattern and accounting pass|
|T4|one synthetic1080p frame|1080 lines,frame closure,U/Y/V expected bytes,viewable reconstruction|
|T5|continuous video and scheduler|25fps under adequate service;explicit paced overrun under starvation;finite/infinite60s/60s behavior|
|L0|manual0..3,masked/missing/unsupported input|route and stable lock correspond to requested physical connector|
|L1|first real complete line|4096-byte ABI validation,no initial partial frame counted|
|L2|finite1,2,1000 real frames|exact valid frames or explicit failure,no rounded success|
|L3|continuous AHD|loss/drop/stall counters plus duration and input identity|
|L4|frame reconstruction|1080x1920 UYVY and visual/scalar geometry proof|
|L5|auto mask/preference/order,unplug/replug STOP/RESCAN|bounded scan,no source mixture,preserved completed counts,segment/epoch evidence|
|L6|software recovery,clock loss,external reset,soak|safe quarantine/late-token tests,same-session repeated source switching except actual reset requires new session|

Each gate publishes configuration/identity,raw or hashed capture,counter snapshots,validator output,timestamps and first failure. Fail a gate on unknown pattern/sequence corruption or incomplete required evidence; stop that ladder and preserve artifacts. Do not promote offline architecture estimates to hardware-qualified throughput. Long infinite scheduler tests end with an explicit host command and clean terminal snapshot.
