# PCB-PWR-0 Read-Only Evidence Ledger

## Active source baseline

- Repository: `C:\FPGA\FPGA_AHD`
- Branch: `main`, tracking `origin/main`
- HEAD: `be94f88ee8d179f12928ab791bdae27c22cd1762`
- Tracked/staged changes at start: none
- Pre-existing untracked entries: `.codex_tmp/`, `reports/`; untouched
- Exact-part source: `scripts/project_common.tcl:12-13`
- SHA-256: `E6DE82EE080C25A349377E62CDD572A1ADFED136B66816B7DE2E426723337209`
- Configuration XDC: `xdc/common/configuration_bank.xdc:1-5`
- SHA-256: `3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68`
- Relevant facts: `CONFIG_VOLTAGE=3.3`, `CFGBVS=VCCO`; comment maps CFGBVS/VCCO_0/load-switch output/test point to board net Vcco.
- Repository-wide history/search result: no schematic/netlist/PCB file and no `SPI_BUSWIDTH`, `S25FL064L`, or `Master SPI` history in reachable active-source commits.
- Current configured-behavior caveat: `rtl/nvp/nvp6134c_autoinit.vhd:80-83` drives both NVP enable outputs high and releases reset according to internal sequencing. Passive defaults cover preconfiguration/handoff only; no RTL was modified or approved as a power sequencer.

## Required previous evidence

- PCB-PIN-0 remote readback/commit: `a7db236b56340095f3521ec195d2a3b49d10f956`
- PCB-PIN-1 remote readback/commit: `6b39355b5b20f14242158c1ecd7a1c0487f09b33`
- PCB-PIN-1 AMD transcription: `v41-hardware-pcb-pin1-programb-nvp-clock-power-audit/raw/OFFICIAL_AMD_REFERENCE_NOTES.md`
- SHA-256: `DEB292B20DC7FE408FC11F0FD810B489791DDB2DA37A0B6F2370A1D785F42896`
- PUDC/A14 analysis SHA-256: `445BF402B1E74CA95A6B107C0986DEB6E57D3F1539E77E256CFBE2F3A3AE51E8`
- I2C-domain analysis SHA-256: `5200AA2804948950257EC73E3872E5159BC50EB893A39475629AFFD158235787`
- Interpretation: prior evidence is authoritative for its recorded audit, but its PUDC LOW/1 kOhm design assumption is intentionally reopened by PCB-PWR-0.

## Exact A35T device database

- Vivado: 2025.2
- Part used by sandbox: `xc7a35tcsg325-2`
- Package database: `C:\AMDDesignTools\2025.2\Vivado\data\parts\xilinx\artix7\public\ibis\pkg\xc7a35t_csg325.pkg`
- SHA-256: `DFC857F68F489A2A941372AF6D81CD9466C26823742D48831B04CE7D3426BA59`
- BSDL: `C:\AMDDesignTools\2025.2\Vivado\data\parts\xilinx\artix7\public\bsdl\xc7a35t_csg325.bsd`
- SHA-256: `B05BFD4948A5CECED2ACA92631D28FA22E00BD0137F34BE852275740BD997DF0`
- BSDL evidence: lines 121-125 name XC7A35T/CSG325; lines 130-138/162 identify dedicated configuration ports; lines 170-177 and 396-404 identify VCCAUX/VCCINT and VCCO_0/14/15/34 supply balls.
- Relevant exact functions were also printed by the sandbox: Bank 0 E8/CCLK, F12/DONE, F13/M2, P10/PROGRAM_B, R11/M1, R12/M0, T10/INIT_B; Bank 14 J15/D02, J16/D03, J18/PUDC_B, K16/D00_MOSI, L15/FCS_B, L17/D01_DIN, T18/DOUT_CSO_B.
- Scope: package-function evidence only; IBIS/package data does not establish powered-off DC/Ioff safety.

## Historical archived board evidence

This source is not in the active Git repository and is not the released A35T/NVP schematic.

- Board title/revision/date: AHD PCIe x4 frame grabber, Rev 0.1, 2020-09-10
- FPGA in archive: XC7A15T-CSG325 (not substituted for current A35T)
- Netlist: `C:\Users\Łukasz Suduł\Documents\Private\FPGA\kicad-20260530T131751Z-3-001\kicad\ahd.net`
- SHA-256: `654CDF22FE883E534C726A3C4388894AAC645BABF10D16DAEDB74C93F9A7C056`
- Configuration sheet: same directory, `ahd_xilinx_config.sch`
- SHA-256: `FB7E7B9547A5EBC74C5996D15D100C8304223469FA03231A643B828478067B6E`
- Power sheet: same directory, `ahd_power.sch`
- SHA-256: `A2CB0E2D80C2FD8AB194EDF1D83AF628102E13C0DB597B751060E6EB2CCE90AD`

Relevant line evidence:

- `ahd_xilinx_config.sch:161`: `M[2:0]=001`, Master SPI;
- `ahd.net:955-960,2966-2982`: U5 S25FL064L and pin roles;
- `ahd.net:3346-3371`: PCIe-derived permanent `V_3.3V`, Flash VCC and R26/R27/R28 pull ends;
- `ahd.net:3409-3476`: load-switched `Vcco`, CFGBVS, and Bank 0/14/15/34 VCCO;
- `ahd.net:961-981`: R26/R27/R28 = 4.7 kOhm;
- `ahd.net:729-735,989-995,1160-1166`: 22 ohm CS/CCLK/data series elements;
- `ahd.net:4036-4042,4083-4101,4290-4343`: Flash-to-FPGA configuration signal nets;
- `ahd.net:3479-3483`: Vcco load-switch enable relationship with regulator `~POR`;
- `ahd.net:4287-4289`: legacy J18 used as VDO2_0, not a PUDC strap;
- `ahd.net:892-905,3471-3472,3958-3965`: legacy I2C pulls to Vcco, not proposed NVP switched VDD3D;
- `ahd.net:1432-1449,3762-3778`: legacy reset RC/pull arrangement.
- `ahd_power.sch:409-426,846-860,1204-1217`: TP2/VCCINT=1.0 V, TP3/VCCAUX=1.8 V, TP1/VCCO=3.3 V.

## Historical A15T x4 build/programming evidence

- XDC: `C:\Users\Łukasz Suduł\Documents\Private\FPGA\firmware (Marek Królikowski)\capture-card-master\capture.srcs\constrs_1\capture_card.xdc`
- SHA-256: `39D61ECEEB88FCC726AB1BF5AE79AF794FD947C290364B787ED33471C20CCEF4`
- `capture_card.xdc:58`: `BITSTREAM.CONFIG.SPI_BUSWIDTH 4`
- Log: sibling project `vivado.log`
- SHA-256: `058DB44000EFF6157A70E4D83F7DAA9C17038333F9A91F0549EE52FB3F235286`
- `vivado.log:303,372-385,422`: x1/x2/x4 cfgmem part selected; bitfile SPI_buswidth=4; SPIx4 cfgmem command; Program/Verify operation successful.
- Scope: proves a historical A15T x4 build/programming event, not current A35T width and not a retained autonomous cold-boot test.

## NVP semiconductor evidence

- PDF: `C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\03_SAFE_PROBE_TARGET\AUTHORITATIVE_REFERENCES\NVP6134C_Rev1_0.pdf`
- Revision/date/pages: Rev 1.0, 2016-10-12, 93 pages
- SHA-256: `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`
- Pages 9-10: RSTB active-low input; SYS_CLK 27 MHz input; IRQ/VCLK/VDO/MPP outputs; SCL input; SDA bidirectional; VDD1D/VDD3D identification.
- Page 89: digital-input absolute maximum is relative to VDD3D; normal powered input/output leakage values do not constitute Ioff.
- Page 90: reset and 27 MHz clock timing entries.
- Full-document search: no powered-off Ioff/fail-safe statement and no IRQ push-pull/open-drain definition.
- Render verification: pages 9-10 and 89-90 were rendered to PNG and visually inspected; temporary renders are not publication artifacts.

## AMD documentation availability

- DocNav catalog: `C:\AMDDesignTools\DocNav\resources\xdocs.xml`
- SHA-256: `0005E4C270000036CAA4C5177CC9729F4CECFC2A9A557FD6C91EA77F31A9677C`
- DocNav TOC-only HTML: `C:\AMDDesignTools\DocNav\resources\hubs\sw_manuals\2023_1\dh0011-vivado-programming-and-debug-hub.html`
- SHA-256: `7523444C6815175B255C94EF30F06BDCDD7CE105E9BEC12E57A2B6EE1C37D992`
- HTML line 185 exposes only Master-SPI/dual-x2/quad-x4 section headings, not Figure 2-14 body or electrical requirements.
- Catalog identifies UG470 at `xdocs.xml:17514-17518,17560-17566` and DS181 at `xdocs.xml:17278-17284`, but no local UG470/DS181 PDF/body was found.
- PUDC semantics and current range are retained from the prior evidence's named-version transcription.
- A non-durable session extraction suggested Figure 2-14 is a Master SPI x4 example; the designer reports PUDC_B is low in the drawing. Because no stable source artifact exists, the figure topology is `SECONDARY_TRANSCRIPT / REQUIRES_UG470_PDF_CONFIRMATION`. Table 2-4's citable prior transcription separately permits HIGH or LOW.
- Exact DS181 page-8 `TVCCO2VCCAUX` wording and authoritative Artix-7 powered-off Ioff limits were not available and are not invented.

## User-provided observation

- Classification: `EXPERIMENTAL_EVIDENCE_FROM_RELATED_BOARD`
- Reported condition: related HDMI prototype, PUDC LOW -> nominally off ADV 3.3 V domain about 1.2 V; PUDC HIGH -> about 0 V.
- Scope: supports mechanism credibility only; not an AHD measurement.
