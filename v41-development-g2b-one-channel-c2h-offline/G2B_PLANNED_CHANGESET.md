# AHD v41 G2B Planned Changeset

## Result

`STATUS: BLOCKED_AT_PREFLIGHT`

`FIRST_BLOCKER: BLOCKED — G2B_RECORD_ABI_NOT_FROZEN`

The G2B source branch and isolated worktree were created at the exact accepted
G2A identity, but the mandatory v41D transport ABI is still marked
`PROVISIONAL` by project-current-state revision 1 and `FINAL_C2H_ABI` remains
an open decision. The proposed G2 MMIO allocation is also provisional. The
gate therefore stopped before any RTL, XCI, build-harness, or test edit.

## Frozen starting identity

| Field | Value |
|---|---|
| Base branch | `integration/v41-r1i-gen2-g2a` |
| Base commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Base tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| G2B branch | `integration/v41-g2b-onech-c2h` |
| G2B worktree | `C:\FPGA\V41_G2B` |
| G2B branch HEAD at hard stop | exact base commit |
| Source worktree state at hard stop | clean |

## Exact authorized source allowlist

`NONE`

No source edit was authorized after the preflight blocker. Consequently, no
new C2H RTL module name or integration path is represented as implemented.
The G1 conceptual implementation areas remain future review inputs only:
one channel-0 four-slot ring, descriptor/release/reset-epoch CDC, a fixed
channel-0 path, v41D formatter, C2H AXI4-Stream adapter, counters, and a
transparent MMIO extension router. They are not changes made by this gate.

Existing files that would require review after an Owner/Architect ABI and
MMIO freeze include `rtl/top/ahd_capture_top_xdma.sv`, the existing
`rtl/record/` producer/mailbox boundary, `rtl/v41/` control/MMIO integration,
the G2 build harness, and focused tests. This is not an edit allowlist; exact
paths must be approved in a resumed G2B pre-edit plan against the frozen
contract.

## Explicit exclusions

The following paths and behaviors were never eligible for modification:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd`
- `rtl/nvp/nvp6134c_autoinit.vhd`
- the NVP initialization table and R1i I2C/telemetry semantics
- `ip/v41/xdma_v41_m1.xci`
- H2C application behavior
- host drivers or DUT tooling
- R-track source or diagnostic reduction
- logical channel 1, arbitration, round-robin scheduling, or any two-channel RTL

## Actual diff classification

| Classification | Files | Result |
|---|---:|---|
| `C2H_REQUIRED` | 0 | NOT STARTED |
| `MMIO_REQUIRED` | 0 | NOT STARTED |
| `TEST_ONLY` | 0 | NOT STARTED |
| `BUILD_ONLY` | 0 | NOT STARTED |
| `UNEXPECTED` | 0 | PASS for empty source delta |

Evidence documents describing the blocked disposition are outside the FPGA
source repository and are not a functional source delta.
