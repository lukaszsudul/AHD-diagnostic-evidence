# AHD v41 CH3 R2R10R13R1 — telemetry LUT reduction build only

## Result

- Source correction: compact storage for the R13 four-slot retry telemetry, with the same external MMIO ABI reconstructed on read.
- Compatibility status: `SOURCE_REASONED_COMPATIBILITY_NOT_TESTED`.
- New source: `88ac649a8484ff359270ec19ab539478edf534c0`, tree `8120a9560d85c1a147b30941e47901e52af0b306`.
- Build: `synth_design=PASS`, `opt_design=PASS`, then `BLOCKED_POST_OPT_LUT_CAPACITY`.
- Post-synth: 22,442 Slice LUT, 23,101 registers, 29.5 BRAM tiles.
- Post-opt: 20,845 Slice LUT, 22,194 registers, 28.5 BRAM tiles.
- Comparable reduction versus R13 post-opt: 6 LUT. The requested minimum was 52; 46 more LUT would be required to reach the strict maximum of 20,799.
- Placement, routing, and bit generation: not run.
- Bitstream and routed DCP: none.

## Frozen contract identity

- Retry allowlist: 16 PREPARE read occurrences, unchanged.
- Retry budgets: one per instruction and four per PREPARE, unchanged.
- Timers: 18,750 idle cycles and 62,500-cycle accept deadline, unchanged.
- Telemetry: ABI v1, four slots, unchanged addresses and bitfields.
- MMIO ABI SHA-256: `DE03871441572744489B8BE82654A508BF518D4ADAA0ADE50762E5E9CE868CCA`.
- Host decoder SHA-256: `ED75BE202EBFB3E4E7E7F5C2A8591D96B466DBB8AA7387E572A4FACAEFDEBF35`.
- Microcode SHA-256: `6821A46132381F9E2B52D2BF023294073F36653A814C9FF7BA95E02180FF6054`.

## Scope boundary

No simulation, host test, regression, formal equivalence, lint, extra timing/DRC/CDC/bus-skew/methodology report, or hardware operation was performed. No retry effectiveness, EQ execution, camera scene, timing sign-off, or product qualification is claimed. Historical R13 remains blocked independently.
