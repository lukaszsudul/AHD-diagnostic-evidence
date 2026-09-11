
# NVP6134C register authority

| PDF page | Bank/address | Field | Meaning | Mode dependency | Access |
|---:|---|---|---|---|---|
| 58 | B0 0x78[7:4]/[3:0] | BGDCOL CH2/CH1 | no-video background color; 1 white75, 3 cyan, 4 green, 6 red, 8 black | no-video output | R/W |
| 58 | B0 0x79[7:4]/[3:0] | BGDCOL CH4/CH3 | no-video background color | no-video output | R/W |
| 62-66 | B0 0xA8[3:0] | NOVID4..1 | per-channel video-loss status | live status | R |
| 65 | B0 0xE0/0xE1/0xE2 | AGC/comparator-clamp/H lock | per-channel status bits | live status | R |
| 20,78 | B1 0xC2[3:0] | VPORT_1_SEQ1 | 0/1/2/3 select CH1/CH2/CH3/CH4 in single-output mode | C8 port mode | R/W |
| 20,78 | B1 0xC8[7:4] | VPORT_1_CH_OUT_SEL | 0=1-port 1-channel; 2=1-port 2-channel; 8=1-port 4-channel | output topology | R/W |
| 78 | B1 0xCA[5] | VCLK1_EN | enables VCLK1; active source uses CA=0x22 | output port | R/W |
| 78 | B1 0xCA[1] | VDO1_EN | enables VDO1; active source uses CA=0x22 | output port | R/W |
| 79 | B1 0xCD | VCLK1 selector/delay | source/phase for VCLK1 | output clock | R/W |
| 45 | B1 0x97[3:0] | CH_RST4..1 | decoder channel reset controls | standard setup | R/W |
| 45 | B1 0x98[3:0] | PD_DEC4..1 | decoder power-down controls | standard setup | R/W |
| 87 | public per-channel clock/mode fields | CH1..CH4 | contiguous per-channel ADC/PRE/DEC and HD/SP mode registers | AHD1080p25 | R/W |
| 88 | B5..B8 0xF0 | format classifier | maps per-channel classifier banks 5/6/7/8 | auto-detection | R |
| 50,86 | Banks 5-10 | private | vendor manual states these are not for users and defers to guide note | unpublished | undocumented |

The PDF documents the route/mode registers but contains no VDO1 hot-switch re-arm procedure and does not document the private Bank5 table meanings.
