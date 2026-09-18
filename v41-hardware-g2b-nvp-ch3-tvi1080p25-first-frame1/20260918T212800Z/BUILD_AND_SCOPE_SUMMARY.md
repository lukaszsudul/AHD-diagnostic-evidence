# Build and scope summary

| Gate | Result |
| --- | --- |
| Parent source | C3 commit `70266f0b90c6fc6a853495eba1d526b285fd7286` |
| SSOT revision | 9, 18/18 manifest entries verified at preflight |
| Private reference | Exact attached bytes verified by SHA-256; full text excluded here |
| FPGA candidate revisions | 0 of 2 |
| New NVP controller RTL | Not implemented; profile authority gate precedes build |
| Synthesis, opt, place, phys_opt, route | Not run |
| Post-opt/routed LUT, timing, DRC, CDC, bus skew, DCP reopen | Not measured for a new candidate |
| New bitstream and signed DCP | None |
| RTL simulation | `NOT_RUN_OWNER_REQUESTED_SPEEDUP` |
| DMA, IP, driver, record ABI, XDC, SSOT/META/PRODUCT | No changes |
| DUT contact, SRAM programming, warm reboot | 0, 0, 0 |

Offline work consists of a source-linked private register-order analysis, a replay of three prior scan records, and a private task-local host frame adapter checked on retained receiver data. The fixture does not qualify a new firmware image or prove a live frame.

The first failed gate is selection of the board-applicable PN branch. Shared register effects on CH2 and recovery of stateful steps must also be closed before a profile can be sealed. No one of these was replaced with an experimental hardware write.
