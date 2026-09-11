# `getvideoloss()` and no-video slice semantics

`nvp6134_getvideoloss()` selects Bank0 per chip, reads `0xA8[3:0]`, and assembles per-channel loss bits. It then updates one global `s_slice_cnt`: values greater than 100 wrap to 0, otherwise the counter increments before the per-channel branch.

For a no-video channel it selects Bank `0x05+CH`. If `s_fmt_set_done[CH]` is clear, register `0x08` receives `0x50` at phase 0, `0x40` at phase 1, or `0x60` at phase 2. Because the counter increments first, the first call after `video_fmt_det_reset()` writes phase 1 (`0x40`), then `0x60`, then `0x50`; the canonical modulo mapping/cycle remains `0x50 -> 0x40 -> 0x60`.

The same branch always writes private register `0x05=0xA4` and calls `nvp6134_cvbs_slicelevel_con(CH,0)`. If the stored mode is below 720p, that helper writes `0x08=0x50`, potentially overriding the phase write. Immediately after campaign reset, `ch_mode_status=0xFF`, so that SD-only override is suppressed. The video-present branch writes `0x05=0x24`, may write `0x08=0x70` for SD, and can invoke bounded FSC recovery for selected EXT modes.

Therefore `STEP_NOVIDEO_SLICE` may never copy only three isolated values. It must reproduce the entry condition, neighbor write, stored-mode condition, counter timing, and recovery exclusions. All such functional writes remain blocked for NVP6134C compatibility testing; SCAN1 performs none of them.
