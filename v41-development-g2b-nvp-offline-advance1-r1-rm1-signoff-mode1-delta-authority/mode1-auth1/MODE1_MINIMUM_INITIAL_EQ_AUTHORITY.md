# MODE1 minimum initial-EQ authority

- Reference EQ function: `eq_init_each_format`, CH1 / AHD 1080p25.
- Reference EQ writes: 5; already-satisfied baseline writes: 2; retained final deltas: 3.
- Retained operations: 0x05/0x59=0x11, 0x05/0xC0=0x17, 0x05/0xC1=0x13.
- Adaptive EQ, cable-length tracking and continuous EQ thread: excluded.
- NVP6134C applicability for retained reference-derived bytes: controlled compatibility test still required.
- Recovery: 2 retained EQ registers lack recovery authority.

Decision: `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.
The minimum semantic subset is isolated, but applicability plus recovery is not fully governed before first image.
