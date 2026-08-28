# R2 Runtime Identity Receipt

## Artifact identity

All five artifacts were verified as exact 2,192,144-byte files before use. No rebuild occurred.

| Role | Bitstream SHA-256 | Result |
|---|---|---|
| Formal Phase-2 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | PASS |
| C0 exact R1h | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | PASS |
| C1 R1i-a | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | PASS |
| C2 R1i-b | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | PASS |
| C3 exact R1i | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |

Source artifact-identity receipt SHA-256: `2833701B89BE55CE96B953705395CDB0429B022701493811A1E6426EC0C3C35D`.

## Common runtime identity

Every executed candidate capture reported:

- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- `DIAGNOSTIC_MAGIC=0x314B4C43`
- runtime build flags `0x00000002`

Formal Phase-2 used the same `BLOCK_ID`, `PROTOCOL`, and `CAPABILITIES`, with diagnostic magic and secondary diagnostic magic both `0x00000000`.

## Candidate-specific runtime source words

| Cell | Observed runs | Runtime source commit | W0 | W1 | W2 | W3 | W4 | Result |
|---|---:|---|---|---|---|---|---|---|
| C0 | 2 | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` | `0xC4F4BFCF` | `0x577C92C3` | `0x021D1FE8` | `0x3C05878D` | `0xD12E001C` | PASS |
| C1 | 2 | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `0x8B8EC0FA` | `0x9C22965E` | `0x46D0421C` | `0x25E63D83` | `0xE7971597` | PASS |
| C2 | 3 | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `0xE4D10BB8` | `0xE85E3797` | `0xD078144F` | `0xD0965E96` | `0x25EE727C` | PASS |
| C3 | 3 | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `0x20C3323D` | `0x79D3896E` | `0xDC586D6D` | `0xB1DF7DEE` | `0xE60F9E41` | PASS |

All four candidate identities were distinguished by the host-side read-only harness. Identity proof does not imply cell completion: only 10 of 32 primary runs executed.

## Final live identity

- role: exact Formal Phase-2 safe baseline
- bitstream SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- DONE: `1`
- endpoint: `10ee:7011`, Gen1 ×1
- bound driver: `xdma`
- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- diagnostic magic: `0x00000000`
- secondary diagnostic magic: `0x00000000`
- boot ID: `d12b3a07-ea25-4769-8293-88ee8fc92ef2`
- final safe-baseline receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`

The final pre-publication live read-only continuity capture reconfirmed this identity at `2026-08-28T18:34:18.741078119Z`. It recorded zero MMIO writes and zero DMA transfers. Receipt SHA-256: `57D0BA961EE73C2B89574B04FF5ED19782F4EE0FA909A47C7DA005F181EAD49A` (`audit/FINAL_LIVE_FORMAL_READBACK_RECEIPT.txt`).
