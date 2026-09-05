# AHD v41 G2B-HW0-PRODUCT Exact Candidate Live-Path Bring-Up

## Result

| Field | Result |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `PENDING` at package assembly |
| Overall result | `BLOCKED` |
| First blocker | `BLOCKED — ADDITIONAL_HARDWARE_AUTHORIZATION_REQUIRED` |
| Final execution point | Hard stop before JTAG access and SRAM programming |

The exact offline-qualified PRODUCT candidate and its governing evidence passed
all offline identity checks. Hardware execution stopped before programming
because mandatory T2 checks require read-only legacy MMIO addresses that are
outside the Owner-authorized MMIO range.

## Frozen state and authority

- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- `SSOT_STALENESS = NONE`
- META-8A evidence commit: `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`
- Recovery-4 evidence commit: `6843d582fd367fbc0edc0b1d55a9617162c489b0`
- G2B-LUT1: `ACCEPTED / OFFLINE_QUALIFIED`
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`
- G2B-HW0-PRODUCT readiness: `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`
- Initial source: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`
- Persistent Flash programming: `NOT_AUTHORIZED`

All 18 SSOT manifest entries, all 32 META-8A manifest entries, and all 181
Recovery-4 manifest entries verified. The Recovery-4 directory is unchanged
between its evidence commit and META-8A.

## Exact candidate

| Item | Result |
|---|---|
| PRODUCT bitstream | `VERIFIED`, 2,192,144 bytes |
| Bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Signed-off DCP | `VERIFIED`, 15,726,324 bytes |
| DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| Source branch | `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| FPGA part | `xc7a35tcsg325-2` |
| Profile | `PRODUCT` |

The source branch is published at the exact commit and both protected source
worktrees remained tracked-clean. Pre-existing untracked files were preserved.

## Dual-layer identity contract

The governed candidate layer verified offline: source commit/tree, signed-off
DCP, bitstream, and SSOT revision all match META-8A.

The required runtime layer would have to verify:

- embedded `GIT_SHA = 224d194e5f82c85bcb29297561c5d5e76d28063b`;
- `BUILD_FLAGS = 0x00000103`;
- PRODUCT profile indication; and
- NVP initialization, NACK, and live-video readiness.

Those runtime values were not read because their authoritative registers lie
outside the authorized MMIO range.

## Mandatory authorization conflict

The Owner authorized targeted MMIO access only to `0x3800..0x3BFF`.
The frozen G2B page provides transport magic, ABI, capabilities, control,
status, counters, errors, and snapshot state through `0x3858`; the remainder
of that page is reserved-zero. It does not expose firmware Git identity,
BUILD_FLAGS/PRODUCT profile, or NVP/video initialization telemetry.

The frozen implementation places the mandatory runtime identity at legacy
offsets `0x0000..0x0030`, including `GIT_SHA_W0..W4` at
`0x0010..0x0020` and `BUILD_FLAGS` at `0x002C`. Mandatory NVP/video readiness
telemetry is in the legacy `0x0080..0x00B4` area. Reading those locations was
not authorized by the task.

Per the explicit rule to stop if a non-authorized operation is required, no
JTAG connection, SRAM programming, MMIO access, XDMA node access, driver
operation, or PCIe recovery was attempted.

## Environment observations before stop

- The authoritative Linux DUT binding was recovered from accepted historical
  receipts, but no authenticated fresh Linux inventory was completed.
- A stale controller SSH alias referred to an archived host and timed out; this
  was not treated as evidence that the authoritative DUT was unavailable.
- No local Vivado, hardware-server, JTAG, or competing hardware-test process
  was observed.
- Only this HW0 task was active among observable Codex tasks.
- Fresh physical exclusivity, JTAG chain, endpoint mapping, and JTAG-to-PCIe
  correlation therefore remain unproven.

## Gate disposition

T0 is `BLOCKED`. T1 through T5, link qualification, runtime identity, first
record, finite capture, reconstruction, and continuous capture are
`NOT_REACHED_DUE_TO_EARLIER_GATE`.

`HARDWARE_THROUGHPUT_288_MB_S = NOT_PROVEN`. Four-input selection,
two-channel capture, V4L2, release creation, and persistent programming were
not performed.

## Required next action

Obtain explicit Owner authorization for read-only access to the exact legacy
identity range `0x0000..0x0030` and NVP/video telemetry range
`0x0080..0x00B4`, while retaining write access only to documented G2B control
registers in `0x3800..0x3BFF`. Then begin a fresh HW0 execution with an
explicitly pinned connection to the authoritative Linux DUT and repeat the
full pre-program exclusivity, JTAG, PCIe, and board-correlation inventory.
