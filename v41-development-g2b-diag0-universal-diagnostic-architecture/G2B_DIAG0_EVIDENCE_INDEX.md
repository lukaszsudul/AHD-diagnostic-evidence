# Evidence index and authority provenance

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


Payload authority: lukaszsudul/AHD-diagnostic-evidence main at6843d582fd367fbc0edc0b1d55a9617162c489b0 before this task; recovery-4 candidate identity and actual local artifacts independently hashed. Source C:\FPGA\V41_G2B,branch integration/v41-g2b-onech-c2h,commit92e9b3d914134c044371779def1ee18eaaeda98a,treecf6bf82249c90782eab1978c68541ed9c0e6430b. See AUTHORITY_RECEIPT.json for per-file hashes.

Primary source references (paths relative to source commit above):

|Reference|Evidence used|
|---|---|
|rtl/g2b/v41_g2b_onech_c2h.sv:1–132|post-frontend tap,488 stored words,four512x64 dual-clock XPM RAM slots|
|same:803–1048|exact simplified marker detector,active-frame/line logic,payload packing,header and commit|
|same:1224–1254|RAM prefetch,common formatter padding,global word insertion,TLAST/TKEEP|
|rtl/top/ahd_capture_top_xdma.sv:39–42,66–67,100–105,1182–1240|AXI autonomous clock,I2C output composition,25kHz init,G2B-to-XDMA wiring|
|rtl/g2b/v41_g2b_mmio_router.sv:1–35|full-address3800..3BFF decode|
|rtl/v41/control_status_regs.sv:96–104|legacy overlays through367F|
|rtl/pio/pio_bar_target.sv:298–390|PIO slot decode,unused read0,control aliases,slot0 mirror|
|scripts/v41/g2b_build.tcl:1243–1255|profile flag bits8/9 and SLOT_COUNT=2|
|rtl/nvp/nvp6134c_autoinit.vhd:190–203|forced1080p25,input0,phaseA,AUTO off|
|rtl/nvp/nvp6134c_diagnostics_pkg.vhd:89–156,394–438|mode and output routing table|
|rtl/nvp/nvp6134c_i2c_bringup.vhd|qualified physical SCL/ACK,verified bank selection,restore/error behavior|
|xdc/boards/current/pins.xdc;rtl/video/physical_frontend.sv|E13 one-port physical wiring and logical bit4/5 correction|
|ip/v41/xdma_v41_m1.xci:47–48|128KiB user AXI-Lite aperture|
|host/tools/g2b/abi_v1.py|existing strict ABI parser;not modified or run on hardware|

NVP original manufacturer PDF at C:\FPGA\V40_1_0_AUDIT_VERIFY_20260816T082147Z\10_KEY_EVIDENCE\AUTHORITATIVE_REFERENCES\NVP6134C_Rev1_0.pdf; SHA301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46. It also exists in historical evidence path v41-nvp-r1f-phase-complete-observability/03_SAFE_PROBE_TARGET/AUTHORITATIVE_REFERENCES. Relevant pages20 (routing),51 (AUTO limits),62 (present),65 (locks),66 (FSC/NOVIDEO status),88 (conditional classifier). The PDF is not republished; audit notes quote/register-summarize only needed facts.

Secondary board evidence inspected: C:\FPGA\PCB_PIN0_EVIDENCE_REPO_20260831\v41-hardware-pcb-pin0-high-speed-input-feasibility\PCB_PIN0_CHANNEL1_ANALYSIS.md and PCB_PIN0_CHANNEL2_ANALYSIS.md. These are proposed NEW PCB E16/R16 assignments, not as-built current E13 board evidence. A filesystem search for available schematic/PDF and current source/evidence references did not locate the required matching as-built connector map. Missing historical C firmware path C:\FPGA\firmware\git-repo\capture-card-fw was not treated as evidence actually inspected; source Z0 report gives historical provenance only.

All G2B_DIAG0_*.md documents describe their named contract. MODE_COVERAGE_MATRIX.csv covers actual common-path limitations;RISK_REGISTER.csv tracks closure;MMIO_REGISTER_MAP.csv is generated from MMIO_CONTRACT.json register metadata. ABI_REFERENCE.json is a semantic copy of frozen ABI, not a revision. STATE.json contains gate status. MAIN_REPORT records all15 required decisions. SHA256_MANIFEST excludes itself to avoid a recursive hash and covers every other publication payload file. VALIDATION.json records structural/pattern/arithmetic/immutability checks performed on architecture artifacts only. No generated RTL,host tool,build,bitstream or hardware result is included.
