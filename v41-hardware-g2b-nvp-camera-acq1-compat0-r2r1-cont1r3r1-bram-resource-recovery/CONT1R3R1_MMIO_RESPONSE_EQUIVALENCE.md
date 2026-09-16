# Candidate 1 MMIO response equivalence

The new payload uses a synchronous RAM read. An accepted aligned payload read at edge N captures RAM data, and one response is asserted after edge N+1 (visible on the second sampled edge after request acceptance). The response valid/data remain stable until accepted, even under eight cycles of receiver backpressure. The read port never receives header, gap, unaligned or out-of-range addresses. Reserved/unknown words remain decoded zero.

The task-local extended RTL bench proved exact latency, no duplicate response, gap/unaligned rejection and all 870 payload words. The separate task-local AXI-Lite bridge/combined-wrapper bench alternated SCAN1, ACQ and telemetry reads under backpressure, offered a command write while a read response was held (not accepted), then accepted one inert ACQ zero control write only after read completion without executor or I²C activity. Its log is `simulation/candidate1_mmio/c1r3r1_mmio.log`.

For addresses below `0x12800`, the directed bench compared legacy ready/valid and response data against the original scanner on every active sampled cycle. The scanner command cone matched the frozen CONT1R3 parent for 30,700 cycles and 757 accepted I²C commands. This is logical simulation equivalence; routed timing is a separate sign-off gate.
