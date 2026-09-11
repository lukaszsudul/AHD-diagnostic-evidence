
# Physical connector-to-logical-channel mapping candidate

`PHYSICAL_CONNECTOR_TO_LOGICAL_CHANNEL_MAPPING_CANDIDATE`

- Owner connector label: `UNKNOWN`
- Candidate: `UNKNOWN→CH1`
- Confidence: `HIGH` for this bounded OFF/ON/OFF observation; not final as-built schematic authority
- Baseline detector tuple, 5/5: `F0=0xFF F2=0x00 F3=0x00 F4=0x00 F5=0x00`
- Connected detector tuple, 10/10: `F0=0xFF F2=0xC0 F3=0x03 F4=0x00 F5=0x00`
- Return-control tuple, 5/5: `F0=0xFF F2=0x00 F3=0x00 F4=0x00 F5=0x00`
- Disconnected → connected response: `PASS`
- Connected → disconnected return: `PASS`
- Control arms CH2/CH3/CH4: no phase-correlated change

The reversible response is confined to CH1 private detector fields F2/F3. NOVID stayed asserted and F0 stayed `0xFF`, so this evidence does not identify AHD, CVI, or another specific camera format.
