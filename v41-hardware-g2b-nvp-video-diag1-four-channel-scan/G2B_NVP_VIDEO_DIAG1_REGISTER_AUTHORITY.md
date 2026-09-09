# NVP6134C register authority

Primary authority: local `NVP6134C_Rev1_0.pdf`, recorded owner-provided SHA-256 `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46` (not rehashed).

| Bank | Address/field | Scope and semantics | Diagnostic use | Restore | PDF page | Source reference |
|---|---:|---|---|---|---:|---|
| 0 | 0x78[3:0] | BGDCOL CH1 | round color | saved value | 58 | `g2b_nvp_video_diag.sv:64,233-237` |
| 0 | 0x78[7:4] | BGDCOL CH2 | round color | saved value | 58 | `g2b_nvp_video_diag.sv:64,233-237` |
| 0 | 0x79[3:0] | BGDCOL CH3 | round color | saved value | 58 | `g2b_nvp_video_diag.sv:65,240-244` |
| 0 | 0x79[7:4] | BGDCOL CH4 | round color | saved value | 58 | `g2b_nvp_video_diag.sv:65,240-244` |
| 1 | 0xC2[3:0] | VDO1 source: 0/1/2/3 = CH1/2/3/4 | read-modify-write route | saved byte | 20 | `g2b_nvp_video_diag.sv:66` |
| 0 | 0xA8[3:0] | NOVID CH1..CH4, 0=video, 1=no video | sampled status | read-only | 42,62 | `g2b_nvp_video_diag.sv:67` |
| 0 | 0xE0[3:0] | AGC lock CH1..CH4, 1=lock | sampled status | read-only | 65 | `g2b_nvp_video_diag.sv:68` |
| 0 | 0xE1[3:0] | comparator lock CH1..CH4, 1=lock | sampled status | read-only | 65 | `g2b_nvp_video_diag.sv:69` |
| 0 | 0xE2[3:0] | horizontal lock CH1..CH4, 1=lock | sampled status | read-only | 65 | `g2b_nvp_video_diag.sv:70` |
| 0 | 0xE8..0xEB | per-channel FSC-change/CKILL/FSC-lock/NOVIDEO | sampled corroboration | read-only | 66 | `g2b_nvp_video_diag.sv:247-254` |

Verified BGDCOL codes (PDF page 58): RED=0x6, GREEN=0x4, CYAN=0x3, WHITE_75_PERCENT=0x1, BLACK=0x8.

Authority gate: PASS. No undocumented register was admitted.
