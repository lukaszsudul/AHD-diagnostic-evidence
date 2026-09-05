# Diagnostic resource budget

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.

Owner hard gate applies only to HW0_DIAGNOSTIC:20384/20800 LUT (98%). Current PRODUCT17366/20800=83.4903846%; nominal additional budget3018. PRODUCT stays<=90%,preferred80–85%. Current FF19314,BRAM26.5,DSP0,BUFGCTRL8,MMCM2 from recovery-4; estimates below are incremental net engineering ranges, NOT synthesis results.

|Bucket|LUT low..high|FF low..high|BRAM36 extra|
|---|---|---|---|
|source selector / common formatter extraction|100..180|120..220|0|
|synthetic video parser and three patterns|450..750|400..650|0|
|synthetic record generator / diagnostic ring controller|300..500|250..450|4|
|frame/record limits and frame-validity ledger|120..220|180..300|0|
|scan-and-lock / runtime I2C engine reuse|400..650|300..500|0|
|autonomous scheduler|100..180|180..280|0|
|MMIO shadow/active and decode|350..550|1250..1600|0|
|counters and coherent telemetry|400..650|5600..6500|0|
|source-mode boundary / quarantine / epoch|180..320|250..450|0|

Totals: LUT 2400..4000;FF 8530..10950;BRAM36 +4 (four512x64 diagnostic slots). Final estimated LUT 19766..21366. The estimate crosses20384: feasibility MARGINAL. The low end leaves618 LUT; high end exceeds by982. Four new BRAMs yield30.5/50 nominal; no full-frame memory. No new clock primitive or DSP is planned.

Counter/active/snapshot FF costs are included, not treated as free. Wide snapshot read muxes, two-byte parser timing and runtime I2C engine reuse dominate uncertainty. The resource gate requires a full implemented count, not this estimate. If synthesis exceeds budget, share decode/adders and RAM-based snapshot storage before reducing required counters/semantics. Do not re-enable research probes, bypass ownership safety or silently relax98%. Route congestion at near98% can fail timing even if LUT count passes. No lightweight Vivado query/build was necessary for this estimate.
