# AHD v41 CH3 TVI1080p25 first-frame attempt

Engineering: **BLOCKED before FPGA build and DUT access**. Publication verification is recorded separately after commit-pinned read-back.

The Owner selected physical input 3 (NVP CH3, zero-based index 2) and left a second camera connected on input 2. The requested CH3 profile could not be sealed from the available authorities. The board as-built identifies a driven 27 MHz oscillator feeding NVP SYS_CLK, while the pinned register procedure offers distinct PN branches and labels the compiled branch for a crystal. No supplied source establishes which branch applies to this board. The procedure also contains shared detection writes that could affect CH2 and stateful initialization pulses without an established reversal. These are profile gates before a new FPGA build or codec write.

No new FPGA source revision, synthesis, bitstream, programming, DUT connection, scan, codec write, C2H session, or camera capture was performed. CH2 was neither configured nor captured. The strict 20,384 LUT gates and all sign-off gates remain unevaluated for a new candidate.

Three **historical** blind-scan records (generations 292–294) were replayed offline. They each show CH3 raw format code `0x34`, classified by the supplied reference as TVI 1080p25, with NOVID PRE=POST=1. They establish prior format detection and lack of lock, not current synchronization.

A private, task-local offline frame adapter was checked against retained AHD receiver data. Its fixture output is not camera evidence. The first blocker is the missing authoritative clock-to-PN-branch mapping; the shared-field and pulse recovery decisions also need a board-specific approved profile before configuration.

No pixel data, raw C2H data, detailed register profile, proprietary reference text, firmware, driver, or private readback is included in this publication.
