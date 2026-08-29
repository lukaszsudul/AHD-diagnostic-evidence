# AHD v41 META-2 SSOT Consistency Report

## Result

`LOCAL_SSOT_CONSISTENCY = PASS`

`SSOT_CONSISTENCY = PASS`

This report is finalized from the exact staged revision-2 tree before
publication and then checked again against remote `main`.

## Required invariant matrix

| Invariant | Expected | Result |
|---|---|---|
| Project-state revision | `2` everywhere required | `PASS` |
| JSON parsing | both SSOT JSON documents valid | `PASS` |
| Lifecycle `status` values | normative enum only | `PASS` |
| Transport semantic state | `FROZEN_FOR_G2B` | `PASS` |
| ABI identity/version | `AHD_C2H_TRANSPORT_ABI_V1` / `1` | `PASS` |
| Record geometry | `64 + 3840 + 192 = 4096` | `PASS` |
| AXI geometry | 64-bit / 512 beats / `0xFF` / final `TLAST` | `PASS` |
| Header map | 16 exact LE u32 words, `0x00..0x3C` | `PASS` |
| Payload | one complete validated 1920-pixel UYVY active line | `PASS` |
| Padding | bytes 3904..4095 all zero | `PASS` |
| MMIO | `FROZEN`, `0x3800..0x3BFF` | `PASS` |
| Legacy compatibility | protected through `0x37FF` | `PASS` |
| Linux consumer | frozen transport input/parser contract | `PASS` |
| Tracked decision closure | only `OD-06`; nine unrelated ODs remain open | `PASS` |
| G2B implementation | `NOT_IMPLEMENTED` | `PASS` |
| G2B hardware | `NOT_PROVEN` | `PASS` |
| V4L2 | `NOT_IMPLEMENTED` | `PASS` |
| Gen2 negotiation | `NOT_PROVEN` | `PASS` |
| 288 MB/s qualification | requirement retained, not achieved/proven | `PASS` |
| R-track | byte/semantic state preserved except global revision context | `PASS` |
| Evidence commit | exact `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` | `PASS` |
| SSOT manifest | 18/18 non-manifest files, sorted, uppercase SHA-256 | `PASS` |
| FPGA source repository | unchanged and clean at original HEAD | `PASS` |
| Remote read-back | remote HEAD and required hashes match | `PASS`, payload commit `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b`, 24/24 paths |

## Historical/provisional-string rule

Current transport ABI statements must contain no unresolved `PROVISIONAL`
claim. Historical revision-1 changelog text, the secondary donor, and R-track
research candidates retain their legitimate historical or unrelated
`PROVISIONAL` labels.

## Validation receipt

```text
META2_SSOT_CHECKS_PASSED: 75
META2_SSOT_CHECKS_FAILED: 0
G2B_PRE_CONTRACT_CHECKS_PASSED: 63
G2B_PRE_CONTRACT_CHECKS_FAILED: 0
SSOT_MANIFEST_ENTRIES_VERIFIED: 18
GIT_DIFF_CHECK: PASS
LOCAL_RESULT: PASS
PUBLICATION_PAYLOAD_COMMIT: 7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b
PUSH_WITHOUT_FORCE: PASS
REMOTE_FILES_CHECKED: 24
REMOTE_READBACK_FAILURES: 0
REMOTE_RESULT: PASS
```
