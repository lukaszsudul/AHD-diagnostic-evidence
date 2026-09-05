# Same-session configuration flow

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


Future execution only. Program HW0_DIAGNOSTIC once, then negotiate identity/capabilities/MMIO. Every transition below requires previous terminal clean drain, host buffer reconciliation, new shadow writes, accepted START snapshot and new epoch. There is no FPGA reprogramming between rows.

|Step|Run configuration|Acceptance|
|---|---|---|
|1|T0 identity, no START|no C2H data after reset|
|2|record counter,limit1,max|one4096-byte record|
|3|record PRBS,finite burst,max|exact records and reproducible bytes|
|4|record limit0,max then graceful stop|continuous accounting and clean stop|
|5|video bars,frame1,paced|one complete reconstructed1080p frame|
|6|video ramp,frames1/2/100/1000|exact complete frames,64-bit totals|
|7|video PRBS,frame0 then stop|continuous then complete-frame stop|
|8|manual live input0,1,2,3 separately|only requested enabled input; stable1080p25|
|9|live frame limits1..1000|exact complete-frame counts|
|10|auto scan preferred/order/mask|one stable eligible source only|
|11|record60s ON/60s OFF,infinite|autonomous clean drain/pause,host STOP cancels repeat|
|12|live loss STOP and RESCAN|no source mixing; error/segment/count policy|
|13|new synthetic config after live clock disappears|quarantined live backend cannot contaminate new epoch|

Repeat steps2–13 as desired. B1/B2 unresolved blocks live steps and overall universal-image engineering acceptance, even though synthetic steps have a fully specified architecture. Physical programming,driver loading and all tests above are prohibited in DIAG0 and were not performed.
