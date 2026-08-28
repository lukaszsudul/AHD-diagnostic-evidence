# AHD v41 G2B Record Contract Receipt

## Receipt result

`BLOCKED — G2B_RECORD_ABI_NOT_FROZEN`

No G2B RTL, golden vector, parser, simulation, synthesis, implementation, or bitstream was produced. This receipt records the pre-implementation contract review only.

The accepted G2A source base named by the task is commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`. No source worktree was modified during this review.

## Authorities reviewed

Read-only G1 evidence in this clean evidence clone:

`v41-development-g1-integration-architecture/`

- `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`
- `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md`
- `V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md`
- `V41_G1_CLOCK_RESET_CDC_PLAN.md`
- `V41_G2_IMPLEMENTATION_CONTRACT.md`

The G1 package identifies evidence payload commit `221f65aef9664a6d6ad35c3ec7644badd69ba381` in `V41_G1_STATE.json`.

Read-only SSOT in this clean evidence clone:

`project-current-state/`

- `PROJECT_STATE.json`, `project_state_revision = 1`
- `CURRENT_INTERFACES.md`

The task context explicitly supersedes the stale SSOT gate label that still shows G2A active. It does not contain an explicit Owner/Architect acceptance of a final v41D wire ABI. G2A acceptance therefore does not silently promote the provisional transport ABI.

## G1 proposed record geometry

The following values are concrete in `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`, lines 38–72, but remain provisional at the SSOT interface layer:

| Property | G1 value |
|---|---:|
| Record family | `v41D` |
| Total record size | 4096 bytes |
| Header size | 64 bytes |
| Useful payload | 3840 bytes |
| Payload byte range | `64..3903` |
| Tail/padding | bytes `3904..4095`, exactly 192 zero bytes |
| AXI data width | 64 bits |
| Beats per record | 512 accepted beats |
| Endianness | little-endian 32-bit header words |
| Byte mapping | record byte `8*n+k` maps to `TDATA[8*k +: 8]` on beat `n` |
| `TKEEP` | `8'hFF` on every beat |
| `TLAST` | low on beats 0–510; high only on beat 511 |

### Proposed header

| Offset | G1 meaning/value | G2B fixed value where defined |
|---:|---|---|
| `0x00` | Magic `0x4C444841` | `0x4C444841` |
| `0x04` | DMA record version `0x00004101` | `0x00004101` |
| `0x08` | Firmware/build ID | unresolved G2B-specific value |
| `0x0C` | Source frame sequence | inherited source value |
| `0x10` | Source line sequence | inherited source value |
| `0x14` | Source capture sequence | inherited source value |
| `0x18` | Useful payload length | `3840` |
| `0x1C` | Existing v40B flags | inherited meanings |
| `0x20` | Active logical-channel count at admission | `1` |
| `0x24` | Source slot generation and slot number | inherited provenance value |
| `0x28` | Source malformed-record count snapshot | inherited source snapshot |
| `0x2C` | Source dropped-record count snapshot | inherited source snapshot |
| `0x30` | Logical channel ID | `0` |
| `0x34` | Selected physical input ID | `0` |
| `0x38` | Per-channel attempt sequence | semantics incomplete |
| `0x3C` | Global streamed-record sequence | semantics incomplete |

The accepted donor v40B source defines the inherited flag values as SOF `0x00000001`, discontinuity `0x00000004`, overflow `0x00000008`, malformed-preceding `0x00000010`, valid `0x00000020`, and window-end `0x00000040`. Its generation/slot word uses generation bits `[31:8]`, zero bits `[7:4]`, and slot bits `[3:0]`. G1 says those donor meanings remain unchanged unless explicitly replaced.

## Mandatory unresolved semantics

1. `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`, lines 69–70, says the channel attempt sequence increments for every admitted or whole-record-dropped attempt and calls `0x3C` the scheduler-assigned global streamed sequence. It does not define either sequence's initial value, reset value, wrap assignment, or whether the stored field is the pre-increment or post-increment value.
2. `V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md`, line 34, says the scheduler increments the global sequence on completion. The sequence must already be present in the record header before that completion handshake, leaving the first emitted value and assignment point ambiguous.
3. `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md`, line 32, says the first record after enable/reset carries the current reset epoch in “MMIO/header context.” The complete header table at C2H architecture lines 53–70 assigns every word through `0x3C` and contains no reset-epoch field.
4. `V41_G1_CLOCK_RESET_CDC_PLAN.md`, lines 59–61, requires a reset-epoch increment, session flush, host re-enable, and restart at record beat 0, but does not define the attempt/global sequence values after that epoch transition.
5. Offset `0x08` is described only as “Firmware/build ID.” G1 does not freeze a G2B-specific value or explicitly say that the G2A `BLOCK_OR_FW_ID` value is retained in v41D.

These are externally observable record semantics. Selecting values locally would invent ABI behavior prohibited by the task.

## SSOT confirmation

`project-current-state/CURRENT_INTERFACES.md` states:

- line 5: `CURRENT_TRANSPORT_ABI_STATUS = PROVISIONAL`;
- lines 79–93: every listed v41D geometry, magic, version, and tag field is `PROVISIONAL`;
- lines 95–98: the Owner/Architect META-0 direction is newer and explicit, and no consumer may treat the table as final until explicit interface acceptance and a META revision.

`project-current-state/PROJECT_STATE.json` independently records `record_family_status = PROVISIONAL`, `transport_abi_status = PROVISIONAL`, `encoded_record_fields = PROVISIONAL`, and open decision `OD-06 / FINAL_C2H_ABI`.

## Required resolution

Before G2B RTL can begin, the Owner/Architect must freeze, at minimum:

- the complete v41D header contract and G2B build-ID rule;
- attempt/global sequence first value, assignment point, reset behavior, and modulo-wrap behavior;
- whether reset epoch is carried in every record, and its exact offset/encoding if so;
- an immutable golden-record vector reflecting those decisions; and
- the corresponding accepted SSOT interface update or an explicit task-local authority that unambiguously supersedes the provisional SSOT ABI.
