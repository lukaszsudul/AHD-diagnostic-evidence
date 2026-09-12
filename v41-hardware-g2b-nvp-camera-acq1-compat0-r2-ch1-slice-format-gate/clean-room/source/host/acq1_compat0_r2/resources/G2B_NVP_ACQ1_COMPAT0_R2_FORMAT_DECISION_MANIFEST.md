# G2B NVP ACQ1-COMPAT0-R2 read-only format decision manifest

Only coherent SCAN1 snapshots are inputs. Three consecutive complete raw tuples must agree and CH1 NOVID must remain zero. The tuple includes A8, F0, F2-F5, E2/E3, E8-EB, AGC lock, clamp/comparator lock, H lock, and per-channel status.

The frozen reference treats raw codes `0x20`, `0x21`, `0x2B`, `0x2C`, `0x30`, `0x31`, `0x35`, and `0x36` as AHD/CVI-family ambiguities. Its AHD-versus-CVI decision depends on temporary preconditioning writes before reading slope and ACC metrics. Those writes are not authorized in R2. Consequently a stable raw `F0=0x31` remains `FORMAT_PRESENT_UNRESOLVED`; it is not sufficient to assert AHD 1080p25.

The exact outcomes are `AHD1080P25_CANDIDATE_CONFIRMED`, `FORMAT_PRESENT_UNSUPPORTED`, `FORMAT_PRESENT_UNRESOLVED`, `NO_FORMAT_CODE`, and `SIGNAL_UNSTABLE`. Under the currently frozen read-only authority, `AHD1080P25_CANDIDATE_CONFIRMED` is reachable only if a future observation satisfies a separately authoritative read-only discriminator already present in the frozen evidence; raw F0 alone never opens MODE1.

