
# Channel parity audit

The public AHD1080p25 overlay configures CH1-CH4 contiguously: B0 0x00-0x03, 0x08-0x0B, 0x81-0x88; B1 0x84-0x87 and 0x8C-0x8F; B1 0x97/0x98; and four Bank9 FSC blocks. No active `channel & 1`, modulo-two, pair-index, step-two loop, 0x5/0xA channel mask, or truncated channel selector drives configuration.

The private stage-2 source is materially incomplete for a four-channel equivalence claim: 51 writes over 37 relative addresses target Bank5 only. Banks6-8 receive no equivalent private writes. This is not the exact observed CH1/CH3-versus-CH2/CH4 parity pattern because working CH3/Bank7 is also unwritten. Since the vendor withholds these fields, the omission is a strong configuration-completeness candidate, not a proven causal or parity defect.
