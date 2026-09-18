# C3-PNR1 offline W4 handoff — no hardware authorization

Task `CONT1R3R4R6-W3A-C3-PNR1` produced one routed implementation and one diagnostic bitstream from unchanged C3 commit `70266f0b90c6fc6a853495eba1d526b285fd7286` (tree `5f2bd8377985406b45433418b20be8993399bcb6`). The one-shot post-opt admission was `OWNER_EXCEPTION_C3_POST_OPT` at 20,456 whole-design Slice LUT. Final routed use was 19,995 against the unrelaxed 20,384 limit. Routing, timing, DRC/methodology hard severities, current-route semantic CDC, 11 exact bus-skew groups, 17 promoted checks and independent signed-DCP as-stored reopen passed. Ordinary warnings remain in `signoff/WARNING_SCOPE_NOTES.md` and the raw reports.

Exact private release artifacts:

- Signed DCP: `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\signoff\C3_PNR1_SIGNED.dcp`, 63,219,896 bytes, SHA-256 `A99EDFE4DF21A3607EC1C31464AD4A03EC6717FCBABBC2979FDA4DFF48E188A5`.
- Bitstream: `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\firmware\AHD_v41_W3A_C3_PNR1_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B`.
- C3 host bundle: `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\host-bundle`, seven byte-identical C3 files; contract SHA-256 `7F2A9647EF60D360B9884E57F6FAE16BCAFC4DD8F60D592CE0A44D728FA67D39`. Offline self-test passed without opening a device.
- Firmware manifest and status erratum: `FIRMWARE_MANIFEST.json` and `C3_STATUS_BIT1_ERRATUM.md` in this task root. The private ZIP is `firmware\AHD_v41_W3A_C3_PNR1_PRIVATE.zip` in this task root. The DCP is recorded in the manifest and need not be inside the ZIP.

C3 status bit 1: interpret as `SCAN_IN_PROGRESS` (states 1..9). Bit = 0 is **not** proof of `SAFE_IDLE`. The hardware `safe_idle` predicate remains the complete C3 predicate. The C4 contract/host must not be substituted for the C3 contract/host. The issued C3 host does not use bit-1=0 alone as permission for an unsafe write; its write guard also checks status bit 7 and the rejected-write counter.

This is an offline implementation qualification, **not** behavioral or hardware qualification. `XSIM_NEW_RUNS=0`; `NEW_RTL_SIMULATION=NOT_RUN_OWNER_REQUESTED_SPEEDUP`; `BEHAVIORAL_ASSURANCE=LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY`; `HARDWARE_QUALIFICATION=NOT_RUN`. DUT contact, programming, new scans and camera frames were all zero. There is no claim of NACK repair, a captured frame, or passage of the 10,000-scan gate.

Next step is a separately governed W4 admission of these **exact** artifact hashes and the C3 host/erratum. It must independently authorize any DUT connection or programming and perform its own hardware safety and scan gates; this offline task grants none of those actions.
