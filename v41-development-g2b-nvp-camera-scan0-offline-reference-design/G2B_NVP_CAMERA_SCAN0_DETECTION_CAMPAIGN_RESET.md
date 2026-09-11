# Detection campaign reset

Commit `3613635dc7028a11e0108d16cc3326f37f783c8a` added `video_fmt_det_reset()`. A fresh campaign must reset the semantic equivalents of:

| State | Reset value |
|---|---:|
| `ch_mode_status[16]` | 0xFF |
| `ch_vfmt_status[16]` | 0xFF |
| `g_ch_video_fmt[16]` | 0xFF |
| `s_fmt_dbnc_cnt[16]` | 0x00 |
| `s_fmt_dbnc_buf0[16]` | 0x00 |
| `s_fmt_dbnc_buf1[16]` | 0x00 |
| `s_fmt_dbnc_buf2[16]` | 0x00 |
| `s_keep_fmt[16]` | 0xFF |
| `s_keep_sync_width[16]` | 0x00000000 |
| `s_fmt_set_done` | 0 |
| `g_eq_set_done` | 0 |
| `s_slice_cnt` | 0 |
| `g_vloss` | 0xFFFF |

The host also creates a new `campaign_id`, clears prior raw tuples, stable counts, blockers and transition history, and rejects snapshots from any previous campaign generation.
