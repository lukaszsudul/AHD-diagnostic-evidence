# AHD v41 G2B MMIO Delta

## Delta result

`BLOCKED — MMIO_ALLOCATION_NOT_FROZEN`

Actual G2B MMIO delta: `NONE`.

No address was decoded, activated, repurposed, or marked `G2B_IMPLEMENTED`. No RTL or tests were created because the first blocker is `G2B_RECORD_ABI_NOT_FROZEN`; the MMIO freeze issue is an independent secondary blocker.

## Authorities reviewed

G1 evidence in this clean evidence clone:

- `v41-development-g1-integration-architecture/V41_G1_MMIO_MAP_PLAN.md`
- `v41-development-g1-integration-architecture/V41_G2_IMPLEMENTATION_CONTRACT.md`
- `v41-development-g1-integration-architecture/V41_G1_G2_ENTRY_CHECKLIST.md`

Read-only SSOT in this clean evidence clone:

- `project-current-state/PROJECT_STATE.json`
- `project-current-state/CURRENT_INTERFACES.md`

## Frozen legacy compatibility boundary

These ranges remain unchanged:

| Range | Frozen behavior |
|---|---|
| `0x0000..0x00FF` | XDMA-local identity/status/telemetry/scratch and tied-zero placeholders |
| `0x00C0..0x00E0` | currently tied-zero DMA-named offsets; must not be activated or repurposed |
| `0x0100..0x35FF` | forwarded legacy PIO/capture/MMIO behavior |
| `0x3600..0x367F` | exact R1i read-only telemetry page |
| `0x3680..0x37FF` | frozen reserved compatibility gap |

Non-extension traffic must preserve values, write behavior, byte enables, unaligned/reserved behavior, response timing, and the exact R1i service path without an added registered stage.

## G1 proposed extension

`V41_G1_MMIO_MAP_PLAN.md`, line 10, is explicit: “All addresses below are `PROPOSED_FOR_G2`. They become contractual only after G2 review confirms no decode collision.”

The proposal allocates:

| Range | Proposed use | Implementation status |
|---|---|---|
| `0x3800..0x387F` | global DMA control/status/counters/snapshot | `NOT IMPLEMENTED` |
| `0x3880..0x38FF` | scheduler/throughput status | `NOT IMPLEMENTED` |
| `0x3900..0x397F` | logical channel 0 | `NOT IMPLEMENTED` |
| `0x3980..0x39FF` | logical channel 1 | `NOT IMPLEMENTED`; two-channel excluded |
| `0x3A00..0x3A7F` | selection/apply/drain commands | `NOT IMPLEMENTED` |
| `0x3A80..0x3BFF` | reserved expansion | `NOT IMPLEMENTED` |
| `0x3C00..0x3FFF` | future product extensions | `NOT IMPLEMENTED` |

Although `V41_G2_IMPLEMENTATION_CONTRACT.md`, line 94, directs G2B to add a transparent `0x3800..0x3BFF` extension router, it does not convert the proposed register definitions into an exact final ABI. Important bit encodings remain unspecified, including capabilities, global control, global/channel state, desired enable/capture-mode bits, scheduler masks/state, command encodings, reject causes, and sticky error causes.

## SSOT disposition

`project-current-state/CURRENT_INTERFACES.md`, lines 101–117, labels the G2 MMIO ranges `PROVISIONAL` and “currently not authoritative implemented registers.” It requires decode-collision proof, exhaustive no-alias verification, protected-response equivalence, an accepted final register contract, and a future SSOT interface update.

`PROJECT_STATE.json` also leaves the transport ABI provisional and open. The explicit task authority accepts G2A despite a stale gate label, but it does not explicitly accept final MMIO addresses or encodings. G2A acceptance cannot silently promote a proposed G1 map.

## Required resolution

Before any G2B register implementation:

1. Owner/Architect must accept the exact extension range and every implemented register's bit-level/reset/write/clear/snapshot semantics.
2. The decision must state the G2B one-channel behavior for the channel-1 and scheduler fields without implementing two-channel logic.
3. A collision/no-alias review must confirm the 128 KiB BAR decode and frozen `0x0000..0x37FF` behavior.
4. The accepted final register contract must supersede the current provisional SSOT interface through the authorized process, or an explicit task-local authority must unambiguously do so.
5. Only then may implemented addresses be labeled `G2B_IMPLEMENTED`.

## Verification status

| Item | Status |
|---|---|
| Legacy map modified | `NO` |
| R1i telemetry modified | `NO` |
| Proposed extension implemented | `NO` |
| MMIO no-alias simulation | `NOT RUN` |
| Byte-enable/reset-value tests | `NOT RUN` |
| Snapshot-coherency tests | `NOT RUN` |
| Protected forwarding equivalence | `NOT RUN` |
