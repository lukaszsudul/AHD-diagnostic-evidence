# CAM1 future hardware protocol

CAM1 is not authorized or executed by SCAN0. A later task may begin only after SCAN1 hardware qualification and after all dispatched ACQ1 actions are READY.

Pre-gates: selected channel is CH1 or CH3; physical mapping established; NOVID cleared; AGC/clamp/H/FSC locks stable over the governed interval; stable format is exactly AHD1080p25; APPLY_MODE and INIT_EQ passed with complete ledgers/readbacks; VDO1 route readback passed; qualified SAV/EAV and source rate are present.

Capture gate: exactly 2500/2500 records; record integrity PASS; one complete 1920x1080 UYVY frame; no missing/duplicated real line claim; frame is neither exact configured BGDCOL nor exact digital black; spatial variation passes. Raw capture, UYVY and rendered image stay private.

Then the Owner performs exactly one controlled scene change (cover/uncover lens, move a high-contrast target, or switch illumination) and a second independently valid frame is captured. Both frame hashes, private source hashes and sanitized metrics are recorded; only metrics/hashes may be published without a separate Owner decision.
