# G2B NVP ACQ1-COMPAT0-R2 operation manifest

- Channel: `CH1` only.
- Private bank: `0x05` only.
- Functional registers: `0x08` and `0x05` only.
- Reference: `4e4o/nvp6134_ex`, commit `081ebbff9a2722d47acf16c680594be43cb179e2`, `video.c`, `nvp6134_getvideoloss`, pinned lines 1036-1069.
- License disposition: `SEMANTIC_USE_ONLY_NO_DIRECT_COPY`.

## Forward actions

| Command | First functional write | Second functional write | Readback order |
|---|---|---|---|
| `ACQ_APPLY_SLICE_50` | Bank5/0x08=`0x50` | Bank5/0x05=`0xA4` | 0x08, 0x05 |
| `ACQ_APPLY_SLICE_40` | Bank5/0x08=`0x40` | Bank5/0x05=`0xA4` | 0x08, 0x05 |
| `ACQ_APPLY_SLICE_60` | Bank5/0x08=`0x60` | Bank5/0x05=`0xA4` | 0x08, 0x05 |

No read is inserted between the two writes. The legacy reversed order is absent.

## Rollback

Select and verify Bank5; restore the exact captured full byte for 0x08 and verify it; restore the exact captured full byte for 0x05 and verify it; restore and verify the original baseline entry bank. Guessed, table-derived, reset-default, or PRODUCT-expected values are prohibited.

## Reference helper disposition

The pinned helper runs only when the channel mode is below `NVP6134_VI_720P_2530` (`0x10`). The governed v41 context is fixed to AHD 1080p25 (`NVP6134_VI_1080P_2530`, `0x20`) or its 1080p no-video state (`0x24`). Therefore `REFERENCE_HELPER_CONDITION=FALSE`, `REFERENCE_HELPER_DISPOSITION=PROVEN_NOT_EXECUTED`, and no post-companion 0x08 rewrite or SD-mode branch is implemented.

