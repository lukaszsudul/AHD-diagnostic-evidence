# AHD v41 CH3 R2R10R8 — one bounded C2H capture

## Result

- One fresh SCAN1 admission was clean: generation 4, `F0/F2/F3=34/C0/03`, `A8 PRE/POST=0B/0B`, `NOVID03=0/0`, `T/R=105/0`, bank restore PASS.
- One C2H session submitted and completed exactly 2,500 records (10,240,000 bytes), with zero pending, short, failed, or duplicate completions.
- The ABI validator accepted all 2,500 records. The stream contained two complete 1920x1080 frames; the first used lines 0..1079 of one epoch/frame key.
- The selected 4,147,200-byte UYVY raster was converted to a 1920x1080 PNG using the pinned BT.601 limited-range integer conversion.
- Cleanup PASS: stream OFF, final pending I/O 0, transport quiescent, exact driver unloaded normally, task locks released, profile A preserved.

## Content limit

The PNG shows a regular static multi-color block pattern, and the next complete frame is byte-identical. The pinned RTL source chain reaches the physical VDO1 frontend, but this capture alone cannot distinguish a live camera scene from a pattern produced upstream of the FPGA input. Therefore:

- `COMPLETE_FRAME_ACQUIRED=YES`
- `PNG_CREATED=YES`
- `REAL_CAMERA_SCENE_CONFIRMED=NO`
- `LIVE_SCENE_UNCONFIRMED`

No second capture, reconfiguration, PREPARE/APPLY, reset, reboot, programming, H2C, or FPGA build was performed.

Raw pixels, PNG, full system logs, profiles, microcode, and private reference material are intentionally withheld from this public package.
