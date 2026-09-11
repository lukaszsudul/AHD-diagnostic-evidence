# Reference slice context

- Reference repository and commit: `4e4o/nvp6134_ex` / `081ebbff9a2722d47acf16c680594be43cb179e2`
- Reference tree: `f6926ef14a34365a0e47652253f5f4d63274cb1e`
- Source identity used for semantic inspection: `video.c` SHA-256 `CBC10B8585CF9F300C47EBD40AACB08635EF62784CF94B691B722758BA49657A`
- Source function: `nvp6134_getvideoloss`; detector caller: `video_fmt_det`
- Entry condition: channel NOVID asserted; phase write further requires format-set state clear
- CH1 private-bank mapping: `Bank 5`
- Phase register and canonical modulo mapping: `0x08`, phases `0/1/2 = 0x50/0x40/0x60`
- Reset behavior: slice counter resets to zero; the counter is incremented before branch dispatch, so the first post-reset phase is `0x40`
- Caller cadence visible in the frozen context: detection path waits about `200 ms` after video-loss handling; a sample kernel loop is disabled and therefore is not runtime cadence authority
- Companion read: Bank 0 / `0xA8[3:0]` for NOVID
- Inseparable companion write: selected private bank / `0x05 = 0xA4` on every NOVID branch execution
- Conditional companion behavior: an SD-mode helper can overwrite `0x08` with `0x50`; campaign reset state suppresses that condition
- Exit/alternate branch: video-present handling writes a different `0x05` value and may enter mode-dependent recovery, all outside this task

Decision: the three isolated `0x08` values are not the complete reference NOVID slice action. The unconditional `0x05 = 0xA4` write is inseparable, so the exact §4 blocker applies.
