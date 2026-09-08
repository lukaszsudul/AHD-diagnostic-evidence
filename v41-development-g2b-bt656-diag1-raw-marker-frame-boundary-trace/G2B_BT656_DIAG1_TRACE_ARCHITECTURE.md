# Trace architecture

- Profile: diagnostic-only `G2B_BT656_DIAG1`
- Trace format: `G2B_BT656_TRACE_ENTRY_V1`
- Logical entry: 16 little-endian 32-bit words / 512 bits
- Physical storage: 512 entries
- Logical capture: 32 pretrigger events plus up to 256 posttrigger events
- Trigger: successful valid EAV associated with source line 1079 in WAIT_EAV
- Stop: next-frame line-1 commit, 256 posttrigger events, or 300000 source clocks
- Data class: marker/control metadata only; no active camera-pixel payload
- PRODUCT functional consumer of trace outputs: none
- Simulation noninterference: PASS
- Hardware usability: NOT REACHED because build timing failed
