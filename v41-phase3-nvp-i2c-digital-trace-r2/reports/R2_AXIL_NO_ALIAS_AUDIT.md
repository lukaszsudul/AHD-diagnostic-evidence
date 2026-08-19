# R2 AXI-Lite no-alias audit

The host bridge preserves all 17 BAR0 address bits. The formal 53-entry map is
selected only when address bits `16:8` are zero and remains at
`0x0000..0x00E0`. The accepted build has `SLOT_COUNT=2`, so only slot windows
`0x0000..0x1FFF` are active. Formal reads of unavailable slots 2 through 15
(`0x2000..0xFFFF`) return deterministic zero. The next formal application
register region begins at `0x10000`.

R2 intercepts only these unavailable-slot ranges:

- identity/status: `0x2000..0x20FF`
- 4096 x 64 high-resolution trace: `0x3000..0xAFFF`
- 512 x 128 FSM-tick context ring: `0xB000..0xCFFF`
- 256 x 256 correct-phase ACK event ring: `0xD000..0xEFFF`

No address at or above `0x10000` is intercepted. Requests outside the four
exact ranges pass to the original formal path with all address, data, byte
enable, and response signals preserved. Diagnostic writes are consumed as
no-ops and never forwarded; this prevents the formal unavailable-slot write
error counter from changing. The R2 simulation proves formal offset `0x0000`
still reads `0xA40A0C07`, diagnostic writes cannot change identity, and PCIe
user reset cannot alter frozen memories.

SAFE_NONALIASED_DIAGNOSTIC_WINDOW=PASS
EXISTING_53_REGISTER_OFFSETS_CHANGED=0
EXISTING_53_REGISTER_SEMANTICS_CHANGED=0
DIAGNOSTIC_WRITES_FORWARDED=0

