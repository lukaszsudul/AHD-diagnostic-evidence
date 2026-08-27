# AHD v41 288 MB/s Acceptance Contract

## Purpose

This contract defines the throughput evidence that a later G8 test must produce. No throughput test is performed at G0.

## Measurement boundary and units

Throughput shall be measured at the **application/host boundary** using host-received, valid application payload bytes. PCIe framing, DMA descriptors, driver metadata, padding, and other transport overhead shall not be counted as application payload.

- Decimal throughput: `host-received application payload bytes / elapsed seconds / 1,000,000`
- Binary throughput: `host-received application payload bytes / elapsed seconds / 1,048,576`
- Required sustained result: **at least 288 MB/s decimal** over the declared measurement interval

The test report shall state the exact byte-count definitions, measurement start and stop conditions, elapsed duration, and any warm-up interval or excluded interval. No unreported interval may be removed from the result.

## Required operating condition

- Exactly two video channels shall be concurrently active for the acceptance run.
- The selected physical input identities, source formats, and observed run duration shall be explicit.
- The negotiated PCIe speed and negotiated lane width shall be captured for the same run.

Link training at Gen2, PCIe enumeration, driver loading, or BAR access alone does not constitute throughput acceptance.

## Mandatory reported values

The G8 evidence shall report at minimum:

- Measurement duration in seconds
- Application payload byte count used in the throughput calculation
- Throughput in decimal MB/s
- Throughput in binary MiB/s
- PCIe negotiated speed
- PCIe negotiated width
- XDMA C2H bytes
- Host-received bytes
- Dropped bytes and dropped records, each explicitly counted
- Frame counts per active channel sufficient to establish whether any frame was lost
- DMA error count
- FIFO overflow count
- PCIe recovery/reset event count

## Acceptance conditions

The run passes only when all of the following are true for the declared measurement interval:

1. Sustained application payload throughput is at least 288 MB/s decimal.
2. Two video channels are concurrently active.
3. No DMA error occurs.
4. No frame is lost.
5. No FIFO overflow occurs.
6. No PCIe recovery or reset event occurs.
7. Dropped bytes and dropped records are both zero.

Any unmet condition is a throughput-acceptance failure, regardless of negotiated link speed or raw link-rate calculation.

