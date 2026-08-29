# AHD v41 G2B-IMPL Host Reference Parser Report

## Result

**PASS — reference parser, stream validator, golden comparator, and frame assembler qualified offline.**

The reference parser is an offline diagnostic and fixture tool. It is not a V4L2 implementation and none of its inputs are hardware DMA evidence.

## Implementation scope

The host reference implementation is under `host/tools/g2b` and provides:

- strict loading of `V41_C2H_TRANSPORT_ABI_V1.json`, including identity, version, geometry, field layout, flags, and payload-model checks;
- generation and parsing of fixed 4,096-byte records;
- validation of magic/version, header length, payload length, flags, reserved zeros, logical channel, physical input, active-channel count, slot/generation encoding, source line range, and zero padding;
- extraction of the exact 3,840-byte UYVY active-line payload;
- tracking of `reset_epoch`, per-channel `channel_attempt_sequence`, shared `global_stream_sequence`, source frame/line/capture sequences, and discontinuity/overflow context;
- classification of valid records, new epochs, discontinuities, corrupt records, and session-fatal mapping/epoch errors;
- reconstruction of complete 1,080-line raw UYVY frames while rejecting duplicates, gaps, partial frames, epoch changes, and invalid input;
- command-line contract inspection, record generation/comparison, stream validation, fixture generation, and frame reconstruction.

## Unit-test result

Command:

```text
python -m unittest -v tests.python.test_g2b_host_tools
```

Result: **11/11 tests PASS**, elapsed 9.636 seconds.

| Test area | Behavior proved | Result |
|---|---|---|
| Authoritative contract identity/geometry/layout | Frozen identity, version, 64/3840/192/4096 geometry, and required field map | PASS |
| Contract drift rejection | Modified or incompatible contract input is rejected before parsing/generation | PASS |
| Exact golden record | Deterministic complete-record layout and expected SHA-256 | PASS |
| Fail-stop structural validation | Corrupt magic, reserved flag, nonzero padding, and invalid logical-channel upper field become fatal corrupt records | PASS |
| Exact comparator | 4096/4096 exact match passes; one changed payload byte and one-byte truncation fail at the correct offset | PASS |
| Flag/window/slot constraints | Invalid SOF, VALID, WINDOW_END, slot, and reserved encodings are rejected | PASS |
| Sequence/epoch classification | Attempt gaps, global gaps, overflow/discontinuity flags, source progression, and new epochs are classified | PASS |
| Armed epoch and mapping | Armed-epoch mismatch and G2B logical/physical mapping mismatch stop the session | PASS |
| Partial-frame handling | A discontinuity discards the partial frame and ignores the discontinuous record | PASS |
| Complete frame | A deterministic 1,080-line raw UYVY frame is reconstructed with exact line/sequence/payload checks | PASS |
| CLI flow | Explicit contract path, generation, comparison, validation, and output handling | PASS |

## Simulated RTL stream validation

Input:

`C:\FPGA\G2B_XSIM_AUTHORITATIVE_20260829_02\g2b_records.bin`

| Property | Observed |
|---|---:|
| Stream bytes | 65,536 |
| Complete records | 16 |
| Record-stream SHA-256 | `BF41EE32E9D1855C86DC2BCAEFD151AFCD83AEAC37900C4D5AD145B29EA2C948` |
| `VALID_RECORD` | 16 |
| `NEW_EPOCH` | 4 |
| `DISCONTINUITY` | 5 |
| Structural parse failures | 0 |
| Session-fatal result | No |
| Final observed epoch | 17 |

The discontinuities and epoch changes were deliberately created by reset/drop/malformed-attempt tests. The parser accepted their frozen-ABI signaling and sequence context while rejecting no structurally valid record.

## Negative controls

The parser was required to fail or classify errors rather than silently accept them:

- a magic-bit mutation, reserved-flag mutation, nonzero byte 4095, or invalid logical-channel upper field produced `CORRUPT_RECORD` and a session-fatal result;
- invalid SOF/VALID/WINDOW_END combinations and invalid slot/reserved encoding raised validation errors;
- changing payload byte 64 produced one mismatch at offset 64; truncating by one byte produced a mismatch at offset 4095;
- an armed-epoch mismatch and an incompatible G2B logical/physical mapping produced fatal discontinuity classification;
- an attempt/global sequence gap was reported, and overflow/discontinuity context was retained;
- a partial frame was discarded when discontinuity was observed;
- a deliberately invalid frame fixture whose first `global_stream_sequence` was nonzero was rejected. It is retained only as a negative parser check and is not the qualification fixture.

## Complete 1080-line frame fixture

Artifact root:

`C:\FPGA\G2B_HOST_FIXTURE_20260829_01`

The valid qualification fixture used `reset_epoch = 7` and source-frame sequence 42. It contains 1,080 complete 4,096-byte records and reconstructs exactly one raw 1920x1080 UYVY frame.

| Check | Result |
|---|---|
| Record stream size | 4,423,680 bytes |
| Record count | 1,080 |
| Active line sequences | exactly `0..1079` |
| Unique active lines | 1,080 |
| Payload per line | 3,840 bytes |
| Missing lines | 0 |
| Duplicate lines | 0 |
| Epochs | one: 7 |
| Source frame | one: 42 |
| Attempt/global/source sequence consistency | PASS |
| Ignored records | 0 |
| Discarded frames | 0 |
| Complete reconstructed frames | 1 |
| Raw frame size | 4,147,200 bytes |

Artifact identities:

| Artifact | SHA-256 |
|---|---|
| `frame_records.bin` | `78D76E1BBBAF02896611309B5AFEB29339B18DDBC526A1A23E1206BA8BF3B8C2` |
| `frame_expected.uyvy` | `759FFE7AC7A8B8F435FFF6B9ED76FA11A498165C3FCC026E24DBE9C3BCB2603E` |
| `frame_reconstructed.uyvy` | `759FFE7AC7A8B8F435FFF6B9ED76FA11A498165C3FCC026E24DBE9C3BCB2603E` |

The expected and reconstructed raw UYVY files are byte-identical, as proven by their identical size and SHA-256.

## Qualification boundary

The host parser and frame-reconstruction gates are **PASS** for simulation and generated fixtures. This result neither proves hardware transport nor remedies the separate post-opt resource blocker (`21412/20800` LUTs, `102.942%`). V4L2, hardware capture, repeatability, and measured throughput remain outside this offline report.
