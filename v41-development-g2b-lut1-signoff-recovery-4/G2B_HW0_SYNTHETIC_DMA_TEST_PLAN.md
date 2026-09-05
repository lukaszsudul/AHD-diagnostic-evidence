# G2B-HW0 synthetic DMA test plan — preparation only

NOT EXECUTED. Hardware remains NOT_PROVEN. This document grants no hardware authorization. Begin only after separate META promotion of the exact sealed offline candidate and a separately authorized HW0 task.

Use the exact bitstream/DCP/source hashes in G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json. Recheck hashes before any future programming. The approved constraint source is recovery-4; the routed logic retains Gen12 runtime identity `224d194e5f82c85bcb29297561c5d5e76d28063b`, `BUILD_FLAGS=0x00000103`, and PRODUCT instrumentation. That original precommit identity is bound by the 35-entry sealed build manifest, not falsely represented as the complete historical parent-commit sources. Recovery-4 changes no runtime register values.

The future task must define host/device identity, access ownership, programming authority, driver policy, capture paths and stop/recovery procedure before execution. Do not proceed on an identity mismatch. Use no live video, HDMI change or R-track work. No V4L2 is required for v41.

| Gate | Action in the separately authorized HW0 task | Required evidence and pass boundary |
|---|---|---|
| T0 | Verify runtime identity and read-only MMIO baseline | Exact expected identity; ABI v1 and PRODUCT profile; governed MMIO `0x3800..0x3BFF`; actual PCIe Gen2 x1 and user clock; counters/reset state recorded. Stop on mismatch. |
| T1 | Transfer one deterministic 4096-byte C2H record | Exactly 512 64-bit beats, correct TKEEP/TLAST; 64-byte header, 3840-byte payload and 192 zero bytes; exact golden bytes; correct channel, sequence, flags and epoch; no unaccounted drop. |
| T2 | Transfer finite bursts with controlled backpressure | Four-slot ring ownership and release; no duplicated/missing sequence except explicitly accounted drops; stable record boundaries and coherent counters. Preserve source and host captures. |
| T3 | Run continuous synthetic stream and measure throughput | At least 288 MB/s application payload, reported separately from transport bytes; at least 75,000 records/s and 307.2 MB/s transport; documented measurement duration and warm-up; every gap/drop accounted. The theoretical 468.75 MB/s payload ceiling is not a measured result. |
| T4 | Reconstruct a synthetic 1080-line frame | Exact geometry, line ordering, frame identity and payload pattern; no stale epoch/slot data; save reconstructed artifact and comparison report. |
| T5 | Run continuous synthetic video | Sustained frame sequence and payload integrity, bounded buffering, recorded counters and throughput; preserve anomalies and stop on corruption, unexplained sequence gap or ownership/reset error. |

Stop at the first failed gate and preserve all logs. Do not silently reset or clear counters to hide a failure. Reboot, power-cycle, driver changes and PCIe recovery require the future task's explicit authorization. This recovery-4 task performs none of these actions.
