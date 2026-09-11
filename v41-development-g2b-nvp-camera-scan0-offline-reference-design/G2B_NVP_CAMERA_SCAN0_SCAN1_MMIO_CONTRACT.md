# SCAN1 MMIO contract

The frozen profile-only range is `0x12000..0x123FF`. Current full-map proof: the G2B router owns only `0x03800..0x03BFF`; DIAG1 conditionally intercepts `0x03C00..0x03FFF`; control/status owns low-address, measurement and R1h ranges; all remaining requests reach `pio_bar_target`; that target returns deterministic zero for reads at and above `0x12000` and rejects writes. SCAN1 therefore intercepts this currently unallocated 1-KiB range before the application target only when its compile-time profile is enabled. PRODUCT decoding remains unchanged.

MAGIC is `0x4E565343` (`NVSC`), VERSION `0x00010001`, and the 256-bit manifest digest is `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`. CONTROL accepts only START, ACK and ABORT with full-DWORD/aligned write-response semantics. START is legal only in IDLE; ACK only in DONE/ERROR; ABORT only while active. Unsupported bits, byte enables or addresses return an explicit protocol error without affecting I2C.

Host consistency sequence: read generation G0; read status, header, group directory and all 82 entries; read generation G1; require G0=G1, DONE=1, header generation=G0, entry count=82 and manifest SHA match; persist; then ACK. Missing entries are never synthesized.
