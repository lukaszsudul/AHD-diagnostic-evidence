
# Channel index proof

- Private classifier mapping: zero-based 0/1/2/3 -> 5/6/7/8: PASS.
- Route translation: `current_channel - 1` -> 0/1/2/3: PASS.
- Public per-channel arrays/registers: four contiguous entries: PASS.
- Active parity-sensitive configuration paths: 0.
- Channel-index audit: PASS.
- Parity/index defect: NOT_PROVEN.

No source path was found that erroneously handles routes 0/2 differently from 1/3 and survives to effective state.
