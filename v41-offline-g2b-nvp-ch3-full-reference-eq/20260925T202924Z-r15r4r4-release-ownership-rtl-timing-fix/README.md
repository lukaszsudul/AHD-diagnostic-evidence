# R15R4R4 — local release/ownership timing correction

Engineering result: **PASS_RELEASE_OWNERSHIP_RTL_REFACTOR_TIMING_CLOSED_BITSTREAM_READY_UNTESTED**. A single local RTL refactor was
built once. The protocol and cycle correspondence was reviewed in source,
without simulation or formal equivalence.

Slice LUTs: 23362 after synth,
21469 after ExploreArea, and
20753 after place/final, below the 20800 device
limit by 47. Routing:
41478/41478 nets, zero errors.
Final setup/hold: WNS +0.080 ns,
TNS 0.000 ns,
WHS +0.029 ns,
THS 0.000 ns; zero failing setup, hold and
pulse-width endpoints.

Both changed path families meet the unchanged 6.000 ns bound, with worst
slacks +0.080 and
+0.502 ns. All four
slots were checked. The historical 128 shadow functions were accounted for
against 127 current endpoints, all with
active 6 ns constraints; the minimum reported slack is
+0.604 ns. Ready synchronization and the
existing 3 ns snapshot bus-skew limits were retained. The stable-data
mailbox crossings still receive CDC-1 Critical tool classifications and
were resolved only under the retained local handshake/source/physical
contract, not by a global CDC sign-off.

Mandatory bitgen DRC: zero errors. The new private experimental bitstream
has SHA-256 `3962886A7813B16D4A3B5C0D21F81A5B930696FF8E6DCD319A3331FA7FD2D5E2`; the private final routed checkpoint has
SHA-256 `C754172FB4F8585F3D344C7B346857B7D47EA94CAB89A25B3FD9B14E06AF9FB4`. Neither binary is published here.

No Linux reader work, functional test, DUT contact or hardware activation
occurred. The ten-frame hardware package remains incomplete pending the
separately authorized reader/host step.
