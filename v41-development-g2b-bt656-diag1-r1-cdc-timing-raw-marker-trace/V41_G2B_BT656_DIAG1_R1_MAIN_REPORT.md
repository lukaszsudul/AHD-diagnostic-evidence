# AHD v41 G2B-BT656-DIAG1-R1 main report

## Outcome

- Engineering gate: **BLOCKED**
- Evidence publication: **PASS** (subject to the final commit-pinned read-back recorded by the governing response)
- Overall result: **BLOCKED**
- First blocker: `BT656_DIAG1_R1_DRAIN_AIO_CLEANUP_UNRESOLVED`

DIAG1-R1 repaired the diagnostic-only CDC/timing architecture, passed 12/12 simulation, passed synthesis CDC, routed with WNS +0.178 ns and zero setup/hold failures, generated the diagnostic bitstream, programmed it once to SRAM, rebooted once, and captured a coherent 147-entry event trace. The trace was read twice byte-identically with no overflow.

The physical trace proves that the source emits 21 complete, parity-valid V=0 line intervals numbered 1080 through 1100 after line 1079. The current parser rejects each at EAV solely because `pending_line <= 1079` is false. The first rejection drops source lock. The next frame's line-0 SAV is physically present and enters capture, but is not admitted while lock is low. A current-parser replay using captured marker bytes and intervals reproduced 21 reason-2 malformed events, one resulting source drop, omitted line 0, and line-1 commit with flags `0x34`.

A separate correction candidate on `fix/v41-g2b-bt656-line0-sof` treats complete out-of-range V-low lines as non-record vertical-boundary tail. Its captured-pattern regression commits line 0 with SOF (`0x21`) and line 1 (`0x20`) with zero boundary malformed/drop events. The full affected transport/ABI regression also passes. No correction bitstream was built or tested in hardware.

## Operational blocker

The requested hardware trace itself completed and physical quiescence passed. The task-owned drain helper nevertheless retained 1023 AIO requests after bounded cancellation/reap. The helper remains present, module reference count is 1, XDMA nodes remain present, and both fresh locks are intentionally retained. No signal, force unload, reboot, power-cycle, or unsafe lock release was attempted.

The diagnostic image remains in volatile SRAM. PRODUCT source, PRODUCT bitstream, transport ABI, driver binary, and SSOT were not changed.
