# AHD v41 CH3 R2R10 — APPLY sync, no capture

Engineering result: **FAIL_APPLY_A_LOADER_TERMINAL**.

The preserved `CAMP_PREPARED` state and exact image/driver/BAR mapping passed admission. One `APPLY_A` write completed at the MMIO transport layer. The first response was busy after 6.799945 ms; the command ended after 101.159407 ms with raw status `0xC3C02542`, terminal code 18 and `CAMP_RECOVERED=5`. Route was off and the loader did not set its CH2 impact flag.

The first failed gate stopped the campaign. SCAN1, ACK, RECOVER, APPLY_B, C2H, DMA and capture were not run. Fresh CH3 synchronization and CH3→VDO1 route verification therefore remain unestablished.

Failure cleanup used six read-only MMIO checks, then one normal unload of the exact owned module. NVP was ready, scanner idle, stream off, transport quiescent and W3a off before unload. Endpoint binding, XDMA nodes, FD/maps and both task locks were cleared.

Source `b2f80cf4fda1775ab34804a246cb7be61e0ecd62` / tree `fd19d5e27923f69d16d2d8679db85d7813124c37`; bitstream SHA-256 `34DFC48E9CCEDD9E4F608624EE51D1D79767E8E74035393576B69C21C07E8CB8`. Full private logs, NVP reference and implementation details are withheld.
