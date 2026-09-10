# Current-session snapshot schema

Diagnostic version is `0x00010001`. Words 0..7 reside at 0x3D00..0x3D1C;
valid, session ID, and generation reside at 0x3D20, 0x3D24, and 0x3D28.
0x3D2C..0x3EFF read zero.

Exact word packing:

- Word 0: `[31:24]` classification, `[23:21]` channel, `[20:18]` one-based
  round, `[17:16]` zero, `[15:0]` session ID.
- Word 1: `[31:27]` zero, `[26:24]` requested zero-based route/channel,
  `[23:16]` route readback, `[15:12]` zero, `[11:8]` assigned BGDCOL,
  `[7:0]` stable sample count.
- Word 2: `[31:24]` raw NOVID, `[23:16]` raw AGC lock, `[15:8]` raw
  comparator/clamp lock, `[7:0]` raw H lock.
- Word 3: `[31:24]` raw channel status, `[23:16]` BGDCOL 0x78 readback,
  `[15:8]` BGDCOL 0x79 readback, `[7:0]` total status sample count.
- Word 4: `[31:24]` zero, `[23:16]` classification, `[15:9]` zero,
  `[8:6]` round position, `[5:3]` zero-based round, `[2:0]` channel.
- Word 5: `[31:0]` I2C transaction count at snapshot.
- Word 6: `[31:27]` zero; `[26]`, `[25]`, and `[24]` indicate nonzero
  high bits for bus-recovery, timeout, and NACK counters respectively;
  `[23:16]`, `[15:8]`, and `[7:0]` hold their low eight bits.
- Word 7: `[31:24]` last I2C error, `[23:16]` first I2C error,
  `[15:0]` current error code.

The words contain no pixel data. Simulation proved atomic latching,
valid-before-CAPTURE_READY ordering, immutability while waiting, one generation
increment per session, and invalidation only after a matching host response.
