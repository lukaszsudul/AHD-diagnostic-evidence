# G2B HW0 PRODUCT Authorization Blocker

Classification: `BLOCKED — ADDITIONAL_HARDWARE_AUTHORIZATION_REQUIRED`

## Conflict

The task grants targeted MMIO read/write access only to `0x3800..0x3BFF`, but
mandatory T2 acceptance requires values that the frozen implementation exposes
only in protected legacy MMIO:

| Required runtime fact | Authoritative location |
|---|---|
| Block/protocol/build schema identity | `0x0000`, `0x0004`, `0x000C` |
| Embedded `GIT_SHA_W0..W4` | `0x0010..0x0020` |
| Vivado version/build | `0x0024`, `0x0028` |
| `BUILD_FLAGS` and PRODUCT bit | `0x002C` |
| Transport signature | `0x0030` |
| NVP/video initialization and readiness telemetry | `0x0080..0x00B4` |

The authorized G2B page contains no aliases for these values. It exposes
transport registers from `0x3800` through `0x3858`; `0x385C..0x3BFF` is
reserved-zero.

## Stop decision

Programming first and discovering the authorization gap at T2 would leave the
FPGA programmed without a legal path to complete the mandatory identity gate.
The task expressly requires stopping when any non-authorized operation is
needed. The stop was therefore applied before JTAG access and before the one
authorized SRAM programming attempt.

## Narrow authorization needed

Authorize read-only accesses to `0x0000..0x0030` and `0x0080..0x00B4` on the
exact mapped AHD XDMA user device. Keep writes restricted to frozen, documented
G2B control operations within `0x3800..0x3BFF`.
