# AHD v41 LEGACY1 R1 — capture-card-master-2 / local-only review

## Result

The Owner identifies the historical project as `capture-card-master-2`; the
available local package is named `capture-card-fw`. A reachable MicroBlaze
source path configures VIN1 / logical CH1 / Bank5 for CVBS SD PAL 720H and
routes channel 0 to VDO1 in 1MUX SD mode. This is not TVI1080p25, CH3, or
Bank7.

`PAL` is source-resolved as the PAL-B/D/G/H/I group, SD 576i50 / 720H
(interlaced, 50 fields/s, nominally 25 full frames/s). The code does not select
one individual regional member of that group. It is an input CVBS timing
choice; the output mode is configured separately.

## Local authority

- source archive: `capture-card-fw_ee06d86_source.zip`, size 3,883,475 B,
  SHA-256 `E89069C88BAF215D75EAC3A7653F587B23C34866541664AC123E62E03E0F0B61`;
- local Git bundle: SHA-256
  `2FEC4990DBFB5EC130F3CE8E7CDDFD5A3FF826237042E00850C16082FD338AE0`;
- local commit `ee06d86f2ad6c30a83dabebfbb9df36b87df1c36`, tree
  `a38ece651a2a1e27d9536308ca6bdf70fbab0109`;
- reviewed-files manifest SHA-256
  `836C1F9CB83B705E5778E02C4A076E865503CA3FD1D2D18B995C2EA20FE3D7F3`;
- principal application file `capture_supervisor/src/codec.c`, local CRLF
  SHA-256 `B71BE0834873AB869C0D19C6EE722857E4A53611CDF50E497C6472A90EA4C2EE`.

These identifiers define the locally reviewed material. They do not claim
verification against an unavailable remote source repository. No source
clone, fetch, submodule download, or LFS download was performed.

## What the historical material proves

| Level | Result |
|---|---|
| `CONFIGURATION_PATH_FOUND` | `PASS_SOURCE_PROVEN` |
| `RUNNING_APPLICATION_LINKED` | `NOT_ESTABLISHED` |
| `REAL_CAMERA_FORMAT_OBSERVED` | `NOT_FOUND_IN_REVIEWED_MATERIAL` |
| `SYNC_OBSERVED` | `NOT_FOUND_IN_REVIEWED_MATERIAL` |
| `REAL_CAMERA_FRAME_OBTAINED` | `NOT_FOUND_IN_REVIEWED_MATERIAL` |

The commit subject `Codec config for SD PAL on (VIN1 -> VDO1)` is an author
declaration, not a retained camera measurement. The local package contains
application sources and Vitis/BSP metadata, but no preserved application ELF,
execution receipt, detector readout, synchronization sample, or real-camera
frame with provenance. This does not prove that the project never worked.

The path does not read F0 or A8/NOVID, does not poll readiness, and has no
deadline or consecutive-sample rule. Low-level helpers detect short I2C
send/receive and bank-readback failures, but `Codec_SetupVideo()` ignores all
helper return values and returns success unconditionally.

## Relevance to current PC310

`TRANSFER_TO_CURRENT_TVI_CH3=PARTIAL`. The historical CVBS PAL CH1/Bank5
table, routing, pinout, delays, DMA, and error policy are not transferable to
TVI1080p25 CH3/Bank7. The old code also does not prove that the current PC310
sample was too early.

The useful comparison is limited to initialization structure and readiness
policy. Preserve the independent R2R10R4 recommendation for a finite detector
readiness window with exact F0=`0x34`, fresh NOVID samples, consecutive
agreement, an absolute deadline and bounded transaction count. Transport,
timeout, bank, static-configuration and CH2-protection failures remain hard
terminal errors. No implementation is authorized by this review.

The single next step is Owner review of R2R10R4 together with the LEGACY1
addendum before any separate implementation authorization.

## Boundaries

No DUT contact, SSH, JTAG, live MMIO/I2C, driver operation, hardware-lock
mutation, PREPARE/APPLY/RECOVER, programming, reset, reboot, DMA, capture,
simulation, build, synthesis, implementation, bit generation, production
source change, or legacy-original mutation was performed. Current camera
readiness is not established and capture admission is not granted.

Publication commit and commit-pinned readback are recorded in the private
publication receipt after this self-contained payload is sealed; they are not
embedded here to avoid a self-referential commit hash.
