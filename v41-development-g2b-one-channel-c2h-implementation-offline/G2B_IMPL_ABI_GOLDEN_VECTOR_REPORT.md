# AHD v41 G2B-IMPL ABI Golden-Vector Report

## Result

**PASS — eight deterministic RTL records matched the frozen ABI byte-for-byte, and all sixteen captured RTL records passed structural parsing.**

This is offline simulation evidence only. No record in this report was captured from a DUT or hardware DMA engine.

## Normative input and checker identity

| Item | Value |
|---|---|
| Contract | `AHD_C2H_TRANSPORT_ABI_V1`, version 1 |
| Accepted PRE evidence commit | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Contract JSON | `V41_C2H_TRANSPORT_ABI_V1.json` |
| Contract JSON SHA-256 | `AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6` |
| Golden checker SHA-256 | `59679C398D71455DAC693D64D0B1EA701697629C523A6373AACC852CB3E0FDBA` |
| RTL stream | `C:\FPGA\G2B_XSIM_AUTHORITATIVE_20260829_02\g2b_records.bin` |
| RTL stream bytes | 65,536 |
| RTL stream records | 16 |
| RTL stream SHA-256 | `BF41EE32E9D1855C86DC2BCAEFD151AFCD83AEAC37900C4D5AD145B29EA2C948` |
| Machine-readable result | `C:\FPGA\G2B_XSIM_AUTHORITATIVE_20260829_02\G2B_ABI_GOLDEN_VECTOR.json` |
| Result JSON SHA-256 | `1F3EB6BCA73F458E959EF246ABF29C7075DEEA7CE757DAC5E5225B35CE19B7E8` |

The checker loaded geometry and header definitions from the frozen JSON, generated the expected header and deterministic UYVY payload for each known testbench fixture, left every reserved and padding byte at zero, and compared the expected record with the captured RTL output without masking any byte.

## Geometry checked

| Region | Byte range | Length | Result |
|---|---:|---:|---|
| Header | `0..63` | 64 bytes | PASS |
| UYVY payload | `64..3903` | 3,840 bytes | PASS |
| Zero padding | `3904..4095` | 192 bytes | PASS |
| Complete record | `0..4095` | 4,096 bytes | PASS |

All comparisons required an exact 4096/4096-byte match. A truncated record or a single changed byte would fail the comparator.

## Known-vector comparisons

| Record | Fixture | Epoch | Attempt | Global | Slot/gen | Exact bytes | Mismatches | Padding | SHA-256 |
|---:|---|---:|---:|---:|---|---:|---:|---|---|
| 0 | seed `0x20` | 0 | 0 | 0 | 0/1 | 4096/4096 | 0 | zero | `D60A957972778F54E4F82773ECFD823A9531112C3E5134100D799B65AA2A6650` |
| 1 | seed `0x21` | 0 | 1 | 1 | 1/1 | 4096/4096 | 0 | zero | `D84F4127899C8DECD54DF15B1D93C18C5ED959AB6B9FF4DD7C2DDF5E14C9C512` |
| 2 | seed `0x22` | 0 | 2 | 2 | 2/1 | 4096/4096 | 0 | zero | `CC8EA96CCB5475E867B1A99FC223FA9C8029AAA6BA36979BA417764EE42B1669` |
| 3 | seed `0x23` | 0 | 3 | 3 | 3/1 | 4096/4096 | 0 | zero | `DFB2112941A5BB74CAF8447D6E23404328DA47238516128065738DCEDC1059B7` |
| 4 | seed `0x24` | 0 | 4 | 4 | 0/2 | 4096/4096 | 0 | zero | `6BC14F97D9907BD3F085059318AB153AF3AB1EA47049277473074A3D21DD60DC` |
| 5 | seed `0x25` | 0 | 5 | 5 | 1/2 | 4096/4096 | 0 | zero | `03C3ADB29D27053788879F49209F1D5F6424ACF8763B2235BD418853F86AFAEA` |
| 6 | seed `0x26` | 0 | 6 | 6 | 2/2 | 4096/4096 | 0 | zero | `996988685A09FD659B62619CE40F0D14E2E3FCD31B0F27E65A1F1224A090F8EA` |
| 7 | seed `0x27` | 0 | 7 | 7 | 3/2 | 4096/4096 | 0 | zero | `C5F4DC256D1DA38C88D2EB37551C57340F7214368329EF7F3DEF8DA5A75C090E` |

The vectors exercise both generations of all four ring slots. Source-frame sequence was 2, source-line sequences were `0..7`, and source-capture sequences were `2..9`, all exactly as expected from the deterministic fixture.

## Complete-stream structural validation

After the exact known-vector comparisons, the checker parsed all sixteen records in the simulated stream against the frozen contract:

| Classification | Count |
|---|---:|
| `VALID_RECORD` | 16 |
| `NEW_EPOCH` | 4 |
| `DISCONTINUITY` | 5 |
| Structural failures | 0 |

The epoch and discontinuity classifications are intentional products of reset, drop, and malformed-attempt scenarios in the focused testbench. They do not indicate structural corruption. Magic/version, header fields, payload length, logical/physical mapping, flags, slot/generation encoding, reserved zeros, payload boundaries, and all 192 padding bytes were accepted for every record.

## Acceptance statement

The ABI golden-vector gate is **PASS**: eight independently generated expected records equal RTL output at every one of 4,096 byte positions, and the remaining captured records are structurally valid under the same frozen contract. This result is independent of the later post-opt LUT-headroom build blocker and does not constitute hardware proof.
