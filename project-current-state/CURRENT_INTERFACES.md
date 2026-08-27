# AHD Current Interfaces

`PROJECT_STATE_REV = 1`

> `CURRENT_TRANSPORT_ABI_STATUS = PROVISIONAL`

This document separates accepted/frozen compatibility surfaces from proposed
or incomplete interfaces. An accepted architecture choice does not make an
unfinished wire or host ABI implementation-frozen.

## Authoritative accepted/frozen interfaces

### XDMA user control identity

All values are little-endian 32-bit words in the current XDMA user AXI-Lite
aperture.

| Offset | Interface field | Accepted value | Status |
|---:|---|---:|---|
| `0x0000` | `BLOCK_ID` | `0xA40A0C07` | `FROZEN` |
| `0x0004` | `PROTOCOL` | `0x0000400B` (`v40B`) | `FROZEN` |
| `0x0008` | `CAPABILITIES` | `0x00031002` | `FROZEN` |
| `0x000C` | `BUILD_ID_SCHEMA` | `0x00010000` | `FROZEN` |
| `0x0010–0x0020` | `GIT_SHA_W0..W4` | exact 40-hex clean source commit | `FROZEN` |
| `0x002C` | `BUILD_FLAGS` | dirty and verified-clean provenance bits | `FROZEN` |
| `0x0030` | `TRANSPORT_SIGNATURE` | `0x58444D41` (`XDMA`) | `FROZEN` |
| `0x0034` | `SCRATCH_RW` | byte-enable-aware, no side effect | `FROZEN` |

The current `PROTOCOL` value describes the existing v40B/PIO record contract.
It must not be changed to advertise an unimplemented v41D transport.

### BAR structure

| Surface | Current donor mapping | Status | Compatibility rule |
|---|---|---|---|
| User AXI-Lite BAR | observed BAR0, 128 KiB aperture at local address 0 | `FROZEN` | Host tooling must discover BAR assignments; preserve the 128 KiB semantic aperture |
| XDMA configuration BAR | observed BAR1, 64 KiB aperture | `FROZEN` | Distinct from the user AXI-Lite aperture; use driver/device discovery |
| C2H device interface | one C2H channel, host node family `/dev/xdma*_c2h_0` | `FROZEN` | One engine per card; current application payload is inactive |
| H2C device interface | one mandatory donor H2C interface | `FROZEN` | Unsupported by application; application `TREADY=0` and host must not submit H2C |

BAR numbering is the verified donor observation, not permission for consumers
to hard-code enumeration order. The stable interface is the distinct
configuration/user-aperture structure discovered through the device/driver.

### Existing MMIO compatibility

| Address range | Current interface | Status | Rule |
|---|---|---|---|
| `0x0000–0x00FF` | XDMA-local identity, status, telemetry, scratch, and tied-zero placeholders | `FROZEN` | Preserve values, reset behavior, byte enables, unaligned/reserved behavior, and response timing |
| `0x00C0–0x00E0` | Named DMA/interrupt telemetry currently tied to zero | `FROZEN` | Do not activate, move, or repurpose silently; these addresses are inside protected legacy space |
| `0x0100–0x35FF` | Forwarded legacy PIO/capture/MMIO space | `FROZEN` | Preserve all existing semantics through inclusive `0x35FF` |
| `0x3600–0x367F` | R1i read-only 32-word causal telemetry page | `FROZEN` | Preserve addresses, meanings, read-only behavior, and read-service timing |
| `0x3680–0x37FF` | Reserved compatibility gap | `FROZEN` | Do not allocate without an accepted interface change |

Unlisted aligned local words read zero and ignore writes; unaligned local reads
return zero and writes are ignored. No new router may add a registered stage to
the protected R1i/legacy response path.

### C2H architecture and channel identity

| Interface decision | Current value | Status | Qualification boundary |
|---|---|---|---|
| XDMA C2H channel count | 1 per card | `ACCEPTED` | Donor interface exists; application data plane not accepted |
| Logical capture channels | IDs 0 and 1 | `ACCEPTED` | Two-channel hardware not qualified |
| Physical input IDs | 0 through 3 | `ACCEPTED` | Current evidence proves only the present VDO1 path |
| Mapping rule | two distinct physical IDs may map to logical 0/1 | `ACCEPTED` | Change only while affected channel disabled and drained |
| Scheduling | record-boundary work-conserving round-robin | `ACCEPTED` | No beat interleave; implementation not qualified |
| Buffer ownership | private four-record ring per logical channel | `ACCEPTED` | Exact implementation/resources remain future work |
| Host transport order | one global streamed order plus per-channel attempt order | `ACCEPTED` | Encoded v41D fields remain provisional |

Channel identity semantics are authoritative at the architecture level:
logical channel identifies the consumer stream, physical input identifies the
selected connector/source, per-channel attempt sequence represents source
admission/drop order, and global sequence represents successful shared-C2H
transport order.

## Provisional interfaces — not implementation-frozen

### v41D record plan

| Field | Current plan | Status |
|---|---|---|
| Record family | `v41D` | `PROVISIONAL` |
| Total bytes | `4096` | `PROVISIONAL` |
| Header bytes | `64` | `PROVISIONAL` |
| Useful payload bytes | `3840` | `PROVISIONAL` |
| Tail bytes | `192` zero | `PROVISIONAL` |
| AXI width / beats | 64 bits / 512 accepted beats | `PROVISIONAL` |
| `TKEEP` | `0xFF` on every beat | `PROVISIONAL` |
| `TLAST` | asserted only on beat 511 | `PROVISIONAL` |
| Magic | `0x4C444841` | `PROVISIONAL` |
| Version word | `0x00004101` | `PROVISIONAL` |
| Required tags | logical channel, physical input, per-channel attempt, global streamed sequence | `PROVISIONAL` |

The G1 plan provides a concrete starting contract and preserves byte-exact
legacy v40B mode. The Owner/Architect META-0 direction is newer and explicit:
the transport ABI is not yet fully implementation-frozen. No consumer may
treat this table as a final ABI until an explicit interface acceptance and META
revision.

### Proposed G2 MMIO extension

The following ranges are `PROVISIONAL` and currently not authoritative
implemented registers:

| Range | G1 proposal |
|---|---|
| `0x3800–0x387F` | global DMA control/status |
| `0x3880–0x38FF` | throughput/scheduler status |
| `0x3900–0x397F` | logical channel 0 |
| `0x3980–0x39FF` | logical channel 1 |
| `0x3A00–0x3A7F` | selection/command |
| `0x3A80–0x3FFF` | reserved diagnostic, error, throughput, and future expansion |

Any implementation requires decode-collision proof, exhaustive no-alias
testing across the 128 KiB aperture, protected-response equivalence, an
accepted final register contract, and a future SSOT interface update.

### Linux transport and V4L2 ABI

The V4L2 frontend, AHD common core, transport-backend interface, stable card
identity, pixel format, timestamps, buffer/DMABUF behavior, and LitePCIe
backend contract are `PROVISIONAL` or `OPEN` design topics. They are not
current implemented interfaces.

## Interface change control

A future interface change requires `INTERFACE_CHANGE` authorization, an exact
Owner/Architect decision, immutable accepted evidence, the expected prior
revision, updates to this document and `COMPATIBILITY_MATRIX.csv`, a one-step
revision increment, changelog/evidence-map updates, non-force publication, and
remote read-back.
