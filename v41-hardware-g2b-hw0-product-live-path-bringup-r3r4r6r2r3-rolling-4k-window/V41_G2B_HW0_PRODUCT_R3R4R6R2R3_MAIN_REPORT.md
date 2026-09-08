# AHD v41 G2B-HW0 PRODUCT R3R4R6R2R3 main report

## Result

- Engineering gate: **FAIL**
- Evidence package: **PASS** (commit identifier reported out of band)
- Overall result: **FAIL**
- First blocker: `R3R4R6R2R3_PHYSICAL_QUIESCENCE_NOT_PROVEN`
- Cleanup blocker: `R3R4R6R2R3_GUARD_AIO_CLEANUP_UNRESOLVED`

## Governed scope

Owner continuity was accepted. No boot, artifact-hash, JTAG, PCIe-topology,
node-to-BDF, SSOT, Git, or predecessor requalification was repeated. No FPGA
programming, reboot, power-cycle, Flash access, package installation, driver
change, ABI change, bitstream change, SSOT change, capture retry, forced process
termination, or forced unload occurred.

## Host receive result

The device-free rolling-host gate passed 14/14. The new x86-64 helper initially
submitted 1024 4096-byte IOCBs, never observed more than 1024 outstanding, safely
crossed cumulative submission 2048, and submitted all 2532 logical requests.
`PRIMARY_WINDOW_COMPLETE` reported 2500 exact primary completions, zero short,
zero failed, zero pending, and 10,240,000 bytes. Capture duration from helper
start was 100.402085 ms. The primary file was durably preserved
with SHA-256 `2AF54B0C894131BCAB0B9A09E5282AD1C7D776184AB193FB4B106D545B5C8EB7`.

## Independent record and stream results

All 2500 fixed-boundary records passed structural integrity. Global sequence was
exactly 0..2499 with zero gaps. Record 441 carried both DISCONTINUITY and
OVERFLOW_OCCURRED, so primary zero-overflow continuity failed. Records 575 and
1654 carried MALFORMED_PRECEDING; the source malformed snapshot increased by
42. No clean SOF/line-zero record
was present, so a complete clean 1920x1080 frame could not be reconstructed.

## Disable, tail, and retained safe state

The normal disable was issued 24028.186
microseconds after the primary event. At SP, CONTROL was zero but STATUS was
`0x000004FA`; counters were attempted 3136, committed
2536, streamed 2532, dropped 600, overflow
598, discontinuity 3, and beats
1296384. The four committed-but-not-streamed records explain the
nonempty ring state. Five-sample quiescence never began because every sample was
nonquiescent; the last status remained `0x000004FA`.

The helper PID 6055, exact module, XDMA nodes, and both fresh locks are retained.
No PARENT_QUIESCENT command, signal, forced unload, reset, or reboot was used.
Raw primary bytes, first-record bytes, frame bytes, and camera images are private
and are not in this package.
