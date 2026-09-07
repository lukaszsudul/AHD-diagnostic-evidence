# G2B-HW0-PRODUCT-R3R4R3 Persisted-Bytes Proof and Capture-Contract Closure

## Result

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `R3R4R3_CAPTURE_TOOL_SELFTEST_FAILED:FIRST_RECORD_PERSISTENCE_PASS`

The fresh run passed predecessor authority, immutable-boundary, exact baseline, and authorized-delta gates. The single 16-case suite stopped in case 1 on a strict timestamp-separation assertion. The callbacks were program-ordered, but both received the same 15.625-ms GetTickCount64 tick. The suite was not patched or rerun.

No credential helper was executed. No DUT connection, JTAG, PCIe inventory, driver load, MMIO, DMA, FPGA programming, reboot, Flash programming, or power-cycle occurred. No camera bytes are present in this package.

Offline synthetic files remain private in the run root. Only hashes, structural metadata, source, and sanitized receipts are public.

## Nonclaims

R3R4R3 does not prove persistent first-record hardware capture, a finite 2500-record live capture, complete real-frame reconstruction, 60-second capture, or 288 MB/s throughput.

## Corrective action

Authorize a fresh governed run that proves the formal ordering with an event sequence/index or explicit dependency receipt, without requiring two ordered callbacks to occupy distinct monotonic clock ticks. Preserve the runtime implementation unchanged.
