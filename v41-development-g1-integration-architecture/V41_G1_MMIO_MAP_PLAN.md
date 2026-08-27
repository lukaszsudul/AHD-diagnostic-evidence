# AHD v41 G1 MMIO Map Plan

## Frozen compatibility regions

- Every existing address and behavior through `0x35FF` remains unchanged.
- The exact R1i read-only telemetry page `0x3600..0x367F` remains unchanged.
- Existing local offsets `0x00C0..0x00E0`, although named for future DMA in source, currently read tied-zero values and are inside the protected legacy range. They shall not be activated or repurposed.
- Existing PIO slot/MMIO behavior and response latency is preserved. New DMA registers are reached through a transparent extension router; non-extension requests pass directly to the exact R1i register block without an added registered stage.

All addresses below are `PROPOSED_FOR_G2`. They become contractual only after G2 review confirms no decode collision. Reads are aligned 32-bit little-endian; unaligned/reserved reads return zero and writes have no effect unless specified.

## Global DMA page — `0x3800..0x387F`

| Address | Access | Proposed meaning |
|---:|---|---|
| `0x3800` | RO | Magic `0x43324831` (`C2H1`) |
| `0x3804` | RO | ABI version `0x00010000` |
| `0x3808` | RO | Capabilities: C2H count, logical/physical channel counts, record-size code, IRQ support |
| `0x380C` | RW | Global control: stream enable, disable/flush request; unsupported bits read zero |
| `0x3810` | RO | Global state: reset epoch valid, formatter state, queue nonempty, sticky fault |
| `0x3814` | RO | Total records committed |
| `0x3818` | RO | Total records streamed |
| `0x381C` | RO | Total whole records dropped |
| `0x3820` | RO | Total FIFO overflow events |
| `0x3824` | RO | Stream protocol errors |
| `0x3828` | RO | DMA/link reset or aborted-session events |
| `0x382C` | RO | Last global streamed-record sequence |
| `0x3830/34` | RO | Transported record bytes, coherent 64-bit snapshot |
| `0x3838/3C` | RO | Useful payload bytes, coherent 64-bit snapshot |
| `0x3840/44` | RO | C2H stall cycles, coherent 64-bit snapshot |
| `0x3848/4C` | RO | C2H active/accepted cycles, coherent 64-bit snapshot |
| `0x3850` | RO | Current stream reset epoch |
| `0x3854` | RO | H2C attempt/valid observation count |
| `0x3858` | RO | User IRQ request count |
| `0x385C` | RO | User IRQ acknowledgement count |
| `0x3860` | RW1C | New-page sticky error clear; never clears R1i telemetry |
| `0x3864` | WO | Snapshot request; increments snapshot generation |
| `0x3868` | RO | Snapshot generation/complete status |
| `0x386C..0x387F` | RO zero | Reserved |

## Throughput/scheduler page — `0x3880..0x38FF`

| Address | Access | Proposed meaning |
|---:|---|---|
| `0x3880` | RO | Scheduler state/current channel |
| `0x3884` | RO | Eligible/nonempty/full channel masks |
| `0x3888` | RO | Completed channel-0 service count |
| `0x388C` | RO | Completed channel-1 service count |
| `0x3890` | RO | Scheduler idle cycles low |
| `0x3894` | RO | Scheduler idle cycles high |
| `0x3898` | RO | Descriptor/slot mismatch count |
| `0x389C` | RO | Last sticky error cause |
| `0x38A0..0x38FF` | RO zero | Reserved |

## Per-channel pages

Channel 0 is `0x3900..0x397F`; channel 1 is `0x3980..0x39FF`. Add the listed offset to the base.

| Offset | Access | Proposed meaning |
|---:|---|---|
| `+0x00` | RW | Desired physical input ID `0..3` |
| `+0x04` | RW | Desired enable and capture-mode bits |
| `+0x08` | RO | Applied physical input, enabled/drained/faulted state |
| `+0x0C` | RO | Selection/config generation |
| `+0x10` | RO | Attempt records |
| `+0x14` | RO | Committed records |
| `+0x18` | RO | Streamed records |
| `+0x1C` | RO | Whole records dropped |
| `+0x20` | RO | FIFO overflow events |
| `+0x24` | RO | FIFO occupancy and high-water mark |
| `+0x28` | RO | Last source frame sequence |
| `+0x2C` | RO | Last source line sequence |
| `+0x30` | RO | Last source capture sequence |
| `+0x34` | RO | Last streamed channel-attempt sequence |
| `+0x38` | RO | Malformed/source error count |
| `+0x3C` | RO | Sticky channel error cause |
| `+0x40/44` | RO | Channel useful bytes, coherent 64-bit snapshot |
| `+0x48/4C` | RO | Channel record bytes, coherent 64-bit snapshot |
| `+0x50..0x7F` | RO zero | Reserved |

## Selection/command page — `0x3A00..0x3A7F`

| Address | Access | Proposed meaning |
|---:|---|---|
| `0x3A00` | WO | Atomic apply-selection command |
| `0x3A04` | RO | Apply busy/accepted/rejected and cause |
| `0x3A08` | RO | Applied active-channel mask |
| `0x3A0C` | RO | Selection reject count |
| `0x3A10` | WO | Disable/drain request mask |
| `0x3A14` | RO | Drain-complete mask |
| `0x3A18..0x3A7F` | RO zero | Reserved |

## Error/expansion reservation

- `0x3A80..0x3AFF`: future scheduler diagnostics, reserved.
- `0x3B00..0x3B7F`: future detailed DMA/drop/error snapshots, reserved.
- `0x3B80..0x3BFF`: future throughput qualification snapshots, reserved.
- `0x3C00..0x3FFF`: reserved for versioned product extensions.

No new page may extend below `0x3680`, alias a legacy address, or modify the R1i read-service timing. The active top currently has only two legacy PIO slots, so the proposed region returns zeros today; G2 must still run an exhaustive no-alias test across the full 128 KiB BAR aperture.

## CDC and atomicity

Control writes are held in the AXI domain and transferred to video domains through acknowledged mailboxes. Applied state is read back separately from desired state. 64-bit and multi-domain counters are exposed only from an explicit coherent snapshot. Counter-clear commands apply only to new product DMA counters and are rejected while a snapshot is pending.

## Required G2 verification

G2 must compare every read/write/latency result through `0x35FF`, every R1i word at `0x3600..0x367F`, reserved/unaligned behavior, and application forwarding before and after the new router. It must then test each proposed page, invalid/duplicate channel selection, snapshot coherency, byte enables, backpressure, and reset values. Any legacy difference blocks the gate.
