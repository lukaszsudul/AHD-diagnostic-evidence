# AHD v41 G2B-DIAG0 Universal Diagnostic Firmware Architecture and MMIO Freeze

Engineering gate: BLOCKED. This package completes the offline architecture/interface analysis and identifies exact missing authority; it does not claim a universal diagnostic image has been implemented or qualified. Evidence publication status is independently recorded in STATE.json and the final remote read-back receipt.

First blocker: B1 NVP_RUNTIME_FORMAT_VALIDITY_UNPROVEN. The Rev1.0 p88 AHD classifier table is conditional on autodetection, while qualified R1i fixes1080p25/AUTO off; p51 AUTO describes a limited SD detection control. No authoritative recipe establishes classifier freshness/validity with the exact protected initialization. B2 FOUR_INPUT_BOARD_MAPPING_UNVERIFIED: the available proposed new-PCB E16/R16 pin audit does not establish as-built connector-to-VIN1..4 mapping for current E13/VDO1 hardware or all four private initialization prerequisites. Obtain those specific references; do not invent NVP writes or assert hardware unsupported.

The Owner task requires BLOCKED when complete four-input selection cannot be established. The earlier allowance to report an evidence-backed blocker is satisfied by the audit, but is not used to override that final engineering gate rule. Partial silicon route support is real: Bank1 C2[3:0]=0..3 selects one of four decoders onto VDO1 in one-channel mode. Only full LIVE/four-input/auto/rescan capability advertisement is withheld; the algorithm and MMIO semantics are specified.

SSOT rev7 verified at start; revision and tree rechecked at end without mutation. Candidate source branch/commit/tree and actual DCP/bitstream SHA256 exactly match required authority6843d582...;PRODUCT source is clean and unchanged. PRODUCT remains OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE, not hardware-qualified. Authority receipt includes exact identities and per-input file hashes.

## Required architecture decisions

|Decision|Frozen result|
|---|---|
|1 synthetic-video injection|post-frontend equivalent G2B byte-parser instance,two ordered byte steps per AXI tick;diagnostic line producer|
|2 synthetic-record injection|diagnostic synchronous ring64-bit write/header/complete-commit interface before common formatter|
|3 shared PRODUCT ring|NOT_SHARED;live original4 slots;synthetic modes share separate4 slots|
|4 arbitration|one ACTIVE producer;record-locked normalized descriptor;drain/retire or quarantine before switch|
|5 synthetic clock|existing axi_aclk62500000Hz;no NVP clock dependency,no new clock mux|
|6 four-input mechanism|silicon Bank1 C2[3:0] routing to VDO1 proven;full current-board runtime support UNRESOLVED B1/B2|
|7 scan/lock|preferred then mask/order;NVP present/AGC/CLAMP/H status;stable format;full-frame boundary;classifier adapter blocked|
|8 MMIO range|user AXI-Lite offsets0x3C00..0x3FFF inclusive;requires accepted SLOT_COUNT=2;collision audit PASS|
|9 state machine|14 states RESET through ERROR;exact codes/commands/transitions in JSON/runtime table|
|10 limits|FRAME0 continuous/1..1000 complete frames;RECORD0 continuous/1..ffffffff complete records;per-cycle;64-bit totals|
|11 scheduler|run timer starts first unit;first count/time wins graceful stop;pause after drain;cycle0 infinite;host stop cancels repeat|
|12 patterns|explicit bars/frame tiles,safe XY ramp,safe PRBS31 video;counter/raw PRBS31 records;formulas in JSON and normative docs|
|13 identity|full committed derivative SHA mirrored consistently in legacy/DIAG;DIAG_ID,profile3,MMIO1.0,ABI1.0,flags402|
|14 profile separation|HW0_DIAGNOSTIC separate from PRODUCT and RESEARCH_DIAGNOSTIC;generator excluded release/v41.0.0|
|15 <=98% feasibility|MARGINAL;incremental2400..4000 LUT against3018;full rebuild required|

## Feasibility and boundaries

Synthetic record architecture has >=307.2MB/s transport capability by overlapped64-bit ring writer and common formatter service bounds (504/544 ticks per record at62.5MHz; capacity limited to>=470.59MB/s transport before backpressure). This is a capacity proof for the selected proposed microarchitecture, not measured hardware throughput or a verified RTL implementation. Synthetic video uses two byte steps/tick to satisfy paced1080p25; one byte/tick at62.5MHz would fail. Safe payload byte mapping prevents accidental markers under the accepted simplified G2B parser.

Frame limits count fully closed,fully emitted1080-line frames;line prefixes may exist after a failed live frame and the host discards them. ABORT never cuts a stalled AXI record;finish complete records and invalidate only incomplete frame/line state. Per-cycle limits reset at scheduler cycles;run totals andrescan counts remain. Snapshot coherence does not wait for a stopped NVP clock. The extra ring allows safe synthetic operation while live ownership is quarantined;returning to live requires acknowledged epoch retirement.

Resource gate:HW0_DIAGNOSTIC<=20384/20800 LUT (98%) only;PRODUCT gate unchanged<=90%,preferred80–85%. Estimate MARGINAL,not final utilization. No branch/worktree created;no RTL/XDC/SSOT/accepted candidate edit;no diagnostic source commit;no Vivado build or bitstream;no DUT/programming/PCIe/DMA hardware tests. Only architecture/evidence files in the separate evidence workspace were created.

## Next action and execution boundary

Close B1/B2 with authoritative NVP/current-board evidence,then review this freeze for META-8 PRODUCT Candidate Baseline and Universal Diagnostic Firmware Architecture Promotion. Do not promote blocked live support as qualified. Future DIAG1 uses separate branch diag/v41-g2b-hw0-universal-diagnostic at C:\FPGA\V41_G2B_DIAG from92e9b3d...,then full synthesis-to-bitstream sign-off. Generator never enters final release/v41.0.0. HARD STOP AFTER G2B-DIAG0 ARCHITECTURE FREEZE.
