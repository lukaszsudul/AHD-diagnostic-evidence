# Read-only diagnostic MMIO delta

Legacy SCAN1 `0x12000..0x123FF` and ACQ `0x12400..0x127FF` remain unchanged. The diagnostic-only SCAN1 sideband decodes `0x12800..0x137FF`; implemented telemetry words occupy the header `0x12800..0x1287F`, ten five-word group records `0x12880..0x12947`, and 82 ten-word entry records `0x12A00..0x136CF`. Undeclared sideband locations read zero. No write command is decoded in the sideband.

The wrapper/top only extend read request selection for this new non-overlapping region and pass through the existing master's transaction-sequence observation. The host characterizer has only the legacy SCAN1 ONESHOT and ACK MMIO writes. The image is version-gated by magic `0x4E565433`, version `0x00010000`, capabilities `0x0000007F`, and embedded telemetry-schema SHA-256 `438D630943B0D3A2BFCB2C23B9FB060FD0C347C16F331D008997DBB3B8B22F95`; it rejects the prior image as a CONT1R3 measurement target.
