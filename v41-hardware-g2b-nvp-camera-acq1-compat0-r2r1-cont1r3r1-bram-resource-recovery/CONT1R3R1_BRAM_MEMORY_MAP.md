# Candidate 1 telemetry BRAM map

The logical CONT1R3 payload remains 10 groups × 5 words plus 82 entries × 10 words: 870 32-bit words / 27,840 bits. Candidate 1 backs it with a 1,024×32 synchronous dual-port array inferred as one `RAMB36E1` in both narrow and full-design synthesis. It uses the existing scanner clock and no whole-RAM reset.

| Logical area | Byte addresses | Linear word indices | Governed words |
|---|---|---:|---:|
| Header/status | `0x12800..0x1287F` | decoded registers, not RAM | 32 |
| Group payload | `0x12880..0x12947` | 32–81 | 50 |
| Entry payload | `0x12A00..0x136CF` | 128–947 | 820 |
| Implementation identity | `0x137F0`, `0x137F4` | decoded constants, not RAM | 2 |

The accepted address is range- and alignment-checked before `(address−0x12800)>>2` is reduced to the ten-bit RAM index. Header, reserved holes, unaligned addresses and out-of-range addresses retain zero/defined decoded behavior and do not alias stored payload. The writer computes entry bases as `128 + 10×entry_index`, group bases as `32 + 5×group_index`, and writes one word per clock from a ten-word capture buffer. Group records use five words. There is one synchronous read port and one synchronous write port. A complete frozen generation prohibits read-during-write acceptance as valid: the host waits for `telemetry_complete` after all commits and checks generation/counts before reading or ACK.

Actual post-opt hierarchy: one new telemetry RAMB36E1; SCAN1 leaf 995 LUT, including 96 LUTRAM. No change to the legacy scanner snapshot store or manifest ROM is claimed here.
