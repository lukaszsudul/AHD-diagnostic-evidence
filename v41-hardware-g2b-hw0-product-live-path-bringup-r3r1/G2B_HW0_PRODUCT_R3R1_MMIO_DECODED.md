# R3R1 MMIO decoded result

Result: `NOT_REACHED`.

- MMIO reads performed: `0`
- MMIO writes performed: `0`
- legacy identity MMIO: `NOT_REACHED`
- NVP/video telemetry MMIO: `NOT_REACHED`
- G2B MMIO baseline: `NOT_REACHED`
- coherent snapshot: `NOT_REACHED`
- runtime embedded GIT_SHA: `N/A`
- runtime BUILD_FLAGS: `N/A`
- G2B C2H magic/capabilities: `N/A` / `N/A`

The frozen ABI mandates a session-start `RESET_STREAM_STATE` write at
`0x380C=0x00000004`. R3R1 excludes that value and explicitly prohibits
transport reset, so hardware execution stopped before connection. The empty
raw CSV is intentional and makes no hardware-state claim.
