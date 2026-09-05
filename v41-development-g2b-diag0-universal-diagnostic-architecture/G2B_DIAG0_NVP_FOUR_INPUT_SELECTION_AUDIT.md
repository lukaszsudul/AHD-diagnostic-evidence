# NVP four-input selection audit

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


FOUR_INPUT_RUNTIME_SELECTION = UNRESOLVED at the complete board/runtime gate. Silicon routing is SUPPORTED_BY_NVP_OUTPUT_ROUTING, not FPGA port selection. Current top/XDC exposes only VCLK1/VDO1; no evidence supports selection of four FPGA input buses. Do not equate a silicon routing capability with proof that all current board connectors and initialization paths work.

Authoritative PDF: NVP6134C_Rev1_0.pdf, 93 pages, SHA256 301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46. Pages 20 and 88 were visually checked against extracted text. Source path and hashes are in the authority receipt/evidence index.

| Function | Exact evidence | Frozen register operation / limitation |
|---|---|---|
| Route decoder n to VDO1 | p20 Table2.4 Bank1 C2 bits3:0; values0,1,2,3 mean channels1–4 normal display | verified bank1; RMW C2=(old & F0) OR n; verify C2 low nibble |
| One channel per VDO1 | p20 Bank1 C8 bits7:4=0 | verify C8 high nibble zero; no time multiplexing |
| Output enable | existing table out_ca returns22; out_c8 returns00; out_c3 returns00 | preserve qualified CA=22, C8=00, C3=00, CD=4A; do not retune clock at runtime |
| Present | p62 Bank0 A8 bits0–3 NOVID | present=(~A8)&F; bit1 means no video |
| Lock | p65 Bank0 E0/E1/E2 bits0–3 | require AGC AND CLAMP AND H lock for candidate; not sufficient to prove format |
| Format | p88 Bank(5+n) F0:31=AHD1080p25;30=1080p30;20/21/22/23=720p30/25/60/50;00/10=SD480i60/576i50 | valid only under documented auto-detection prerequisite; not certified for forced-mode R1i |
| AUTO | p51 Bank0 (08+n) bit7 | text limits this AUTO control to NTSC/PAL detection; do not assume setting it enables the p88 AHD classifier |

Current autoinit lines190–199 fixes range_sel=10 (1080p25), output_sel=A, channel_sel=00, auto_enable=0. diagnostics_pkg out_c2 already encodes all four decoder choices but is called only at startup. The table applies 81..84=03; those are configured modes, not detected-format status. The wrapper has no runtime request port. The existing private/Marek initialization writes are not a proven per-input runtime reinitialization recipe.

Current pins.xdc maps VCLK1=E13; VDO1[0..7]=A14,B14,A15,B15,B16,A17,B17,C18. physical_frontend corrects VDO bits4/5 and samples this one port. The PCB-PIN-0 package inspected concerns a NEW PCB (VCLK1=E16, VCLK2=R16) and explicitly proposed assignments; it cannot establish as-built wiring for this E13 board. No matching as-built connector-to-VIN1..4 schematic/netlist was found in the inspected source/evidence workspaces. SSOT proves the requirement of four physical inputs, not complete multi-input qualification.

Blocker B1 NVP_RUNTIME_FORMAT_VALIDITY_UNPROVEN: obtain an authoritative AHD classifier enable/read-validity/settling recipe compatible with forced 1080p25, or vendor evidence that Bank5..8 F0 remains a live classifier in the exact qualified configuration. Also define stale/no-video status behavior and per-channel initialization prerequisites. Page51 AUTO cannot be invented as the answer to page88.

Blocker B2 FOUR_INPUT_BOARD_MAPPING_UNVERIFIED: obtain the as-built schematic/netlist or accepted board mapping for the current E13/VDO1 board showing connector/input0–3 to VIN1–4, and confirmation that the accepted initialization enables each required analog decoder channel. No additional physical FPGA video port is needed if that evidence is supplied. These are information gaps, not proof that the hardware is incapable.

NVP_INPUT_STATUS_REGISTER_PLAN = UNRESOLVED for complete present/lock/standard/fps plan. Present and basic lock registers are established. Capability bits LIVE_VIDEO, FOUR_INPUT_SELECTION, AUTO_SCAN and LOSS_RESCAN are withheld until B1/B2 closure. Route read-modify-write above is a concrete future plan, not a command executed on hardware.
