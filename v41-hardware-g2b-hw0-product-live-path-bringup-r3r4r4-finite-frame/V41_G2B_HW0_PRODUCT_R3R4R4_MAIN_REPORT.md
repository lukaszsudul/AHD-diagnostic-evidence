# G2B-HW0-PRODUCT-R3R4R4 Event-Sequence Ordering Proof and Finite-Frame Gate

## Result

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `R3R4R4_CAPTURE_TOOL_SELFTEST_FAILED:PARENT_MULTI_SAMPLE_QUIESCENCE_PASS`

The fresh run passed predecessor authority, immutable-boundary, exact baseline, and authorized-delta gates. The event-sequence and explicit durability dependency proof passed with equal timestamps. Existing cases passed 11/11 and the first three contract cases passed. The single 16-case suite then stopped in case 15 because the nominal 1.4 - 1.0 second test span evaluated as 0.3999999999999999, below the exact 0.4 comparison. The capture runtime and self-test were not patched and the suite was not rerun.

No credential helper was executed. No DUT connection, JTAG, PCIe inventory, driver load, MMIO, DMA, FPGA programming, reboot, Flash programming, or power-cycle occurred. No camera bytes are present in this package.

Offline synthetic files remain private in the run root. Only hashes, structural metadata, source, and sanitized receipts are public.

## Nonclaims

R3R4R4 does not prove persistent first-record hardware capture, a finite 2500-record live capture, complete real-frame reconstruction, 60-second capture, or 288 MB/s throughput.

## Corrective action

Authorize a fresh governed run changing only the synthetic quiescence test's final observation from 1.4 seconds to 1.401 seconds, making the five-sample span unambiguously greater than 400 ms while preserving the runtime implementation unchanged.
