# Complete active BAR/MMIO collision audit

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


Result PASS for allocation0x3C00..0x3FFF inclusive (1024 bytes,1KiB aligned), offset relative to the XDMA user AXI-Lite aperture. This is not XDMA's separate DMA control-register space. ip/v41/xdma_v41_m1.xci lines47–48 configures128KiB; axi_lite_host_bridge lines74–75 preserves address bits16:0. Host must map the user aperture and reject offsets beyond0x1FFFF; higher addresses alias if truncated and are outside this contract.

| User offset interval | Active owner / disposition |
|---|---|
|00000..000FF|control_status_regs local identity/status/scratch; overlay has priority over PIO slot0|
|00100..00FFF|legacy PIO slot0|
|01000..01FFF|legacy PIO slot1|
|02000..0209F reads|AXI measurement overlay|
|020A0..0367F reads|R1h/R1i service address reservation; PRODUCT reduced implementation does not make it free|
|03680..037FF|unused PIO slots beyond SLOT_COUNT=2; remains reserved|
|03800..03BFF|v41_g2b_mmio_router exclusive G2B control, unchanged|
|03C00..03FFF|unused PIO slot3 reads return0; no allocated functional storage with SLOT_COUNT=2; allocate to DIAG|
|04000..0FFFF|unused slots2..15 after overlays, reserved for legacy expansion|
|10000..10FFF|legacy control register page with low-byte aliases, not free|
|11000..11FFF|legacy PIO slot0 mirror|
|12000..1FFFF|unallocated read-zero region; legacy writes error-accounted|

Evidence: top parameter SLOT_COUNT=2 and g2b_build.tcl line1251 explicitly seals SLOT_COUNT=2. pio_bar_target lines357–364 rejects slot number>=SLOT_COUNT with read0; writes below10000 are bad-address accounted, not latent control functions. control_status_regs lines96–104 claims only the listed overlays; G2B router lines33–34 claims only3800..3BFF. The original router explicitly forwards3C00 upward to legacy. Thus the candidate range is free of implemented registers/slot storage, not un-decoded electrically. Allocating it replaces unallocated read-zero/bad-address behavior only in the new profile, not an existing MMIO register's semantics. Never describe it as having no prior bus behavior.

Future DIAG router must compare FULL17-bit address before legacy routing, with exact inclusive bounds, reject accidental low14-bit decode alias at13C00, and preserve original routing/latency outside its range. PRODUCT router remains unchanged. Freeze SLOT_COUNT=2 as an HW0_DIAGNOSTIC build precondition. A different SLOT_COUNT>=4 invalidates this allocation and must fail elaboration rather than steal PIO slot3.

DIAG1 tests: enumerate all aligned offsets00000..1FFFF with READ/WRITE and byte enables against baseline routing; the only intentional owner delta is3C00..3FFF. Verify boundary3BFC/3C00/3FFC/4000 and aliases13C00. No live BAR probe was performed in DIAG0.
