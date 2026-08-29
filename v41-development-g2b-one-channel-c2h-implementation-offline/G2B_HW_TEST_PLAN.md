# AHD v41 G2B One-Channel C2H Hardware Test Plan

## Status

This is a prepare-only plan for the next separately authorized hardware gate.
It was not executed during G2B-IMPL. Nothing in this document authorizes DUT
access, FPGA programming, PCIe rescan, driver operations, or DMA.

`G2B_IMPL_HARDWARE_ACCESSED = NO`

`HARDWARE_TEST_READINESS = BLOCKED`

The plan itself is ready, but its entry criteria are not met: the clean build
stopped at `RESOURCE_HEADROOM_GATE_POST_OPT` because LUT use was 102.942% of
the device. There is no accepted integration commit or bitstream candidate.

## Entry criteria

An architect-reviewed implementation must pass the full clean synthesis,
placement, physical optimization, routing, timing, DRC, CDC, and resource
gates. The Owner must then accept the offline evidence package and identify the
exact candidate by integration commit, tree, bitstream path, bitstream
SHA-256, Vivado identity, XDMA XCI identity, and frozen ABI/MMIO contracts.
The DUT and test window must be explicitly authorized, the safe restore
baseline must be known, and no conflicting R-track activity may be active.

## Planned gate

1. Record pre-test DUT, PCIe, driver, card, source, and restore identities.
2. Program only the named candidate, without regenerating or substituting a
   bitstream.
3. Read back runtime build identity and confirm it matches the candidate.
4. Verify negotiated PCIe Gen2 x1 independently of build-time capability bits.
5. Read the frozen `0x3800..0x3BFF` identity, capability, status, control,
   epoch, error, and coherent-snapshot registers; verify legacy MMIO remains
   intact.
6. With C2H disabled, issue `RESET_STREAM_STATE`, wait for completion, record
   the new epoch, clear only legally recoverable sticky errors, then enable the
   one implemented channel.
7. Perform a bounded XDMA C2H capture with explicit size and timeout limits.
8. Parse every fixed 4,096-byte boundary with the offline reference parser.
   Stop rather than scan for magic on any corrupt record.
9. Verify real AHD UYVY payload: channel/input identity, active-line ordering,
   line and frame metadata, zero padding, epoch, attempt/global sequences, and
   absence of blanking or BT.656 SAV/EAV bytes.
10. Reconstruct at least one complete real 1,080-line frame and distinguish it
    from the simulated fixture.
11. Repeat bounded captures after a fresh session-start reset and compare
    identity, continuity, errors, counters, drops, overflows, and reset events.
12. Exercise only approved observations of natural/controlled backpressure;
    verify record integrity, final-beat release, and no partial overwrite.
13. Measure application payload and transport rate over an approved interval.
    Do not claim the 288 MB/s requirement from link width or theoretical math.
14. Disable C2H, stop DMA safely, collect final coherent snapshots and logs,
    restore the accepted baseline, and verify the restore identity.

## Required evidence

Retain program/read-back logs, runtime identity, PCIe negotiation evidence,
MMIO dumps, bounded DMA command parameters and hashes, parser output, real-line
and frame checks, repeatability results, error/drop/backpressure observations,
throughput calculations, and safe-restore proof. Clearly label simulated and
hardware-derived artifacts so they cannot be confused.

## Stop conditions

Stop on identity mismatch, unexpected PCIe generation/width, MMIO contract
drift, parser structural failure, unsafe error state, uncontrolled DMA, loss of
source provenance, interference with another track, or inability to guarantee
safe restore. Preserve evidence and do not broaden the test without new
authorization.
