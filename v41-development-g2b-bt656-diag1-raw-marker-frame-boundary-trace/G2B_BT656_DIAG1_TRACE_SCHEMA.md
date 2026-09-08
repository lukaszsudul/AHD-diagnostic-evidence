# G2B_BT656_TRACE_ENTRY_V1

Each entry is 16 little-endian 32-bit words.

| Word | Meaning |
|---:|---|
| 0 | absolute event sequence |
| 1 | source-clock delta from prior event |
| 2 | chronological parser marker bytes, `0xXY0000FF` for `FF 00 00 XY` |
| 3 | marker/decode/event/control/state flags; bit 31 reserved zero |
| 4 | source frame sequence |
| 5 | source line sequence |
| 6 | next source line |
| 7 | source capture sequence |
| 8 | pending frame |
| 9 | pending line |
| 10 | pending capture |
| 11 | pending/channel-attempt sequence |
| 12 | source lifetime malformed count before event |
| 13 | source lifetime dropped count before event |
| 14 | composed flags on commit, otherwise pending flags |
| 15 | payload count, post-payload count, marker fill, slot, malformed reason and drop reason |

Word 3 bits 0..24 are MARKER_EVENT, MARKER_VALID, F, V, H, XY_VALID, MALFORMED_INCREMENT, SOURCE_DROP_INCREMENT, COMMIT_PULSE, TRIGGER_PULSE, SOURCE_READY, ENABLE_APPLIED, PREVIOUS_SAV_V, SOURCE_LOCKED_BEFORE, SOURCE_LOCKED_AFTER, MONITOR_HAS_ATTEMPT, ALLOCATION_VALID, MONITOR_WRITES_SLOT, RING_FULL, RING_EMPTY, FORMATTER_FATAL, OWNERSHIP_FATAL, and the three stop reasons. Bits 27:25 and 30:28 hold canonical source state before/after.
