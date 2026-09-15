
# CONT1R1 live projection receipt

- Live single-scan physical receipt: `PASS`
- Live single-scan generation: `2`
- Physical counts: `82/82`, `10/10`, `105/105`
- Retry count: `0`
- Entry-bank restore: `PASS`
- Projection key type: `BANK_AND_REGISTER_PAIR`
- Projection required keys: `13`
- Missing projection keys: `0`
- Bank1/0x84..0x87: `PRESENT`
- Bank1/0x8C..0x8F: `PRESENT`
- Bank1/0x88..0x8B: `NOT_REQUIRED`
- Configuration projection: `PASS`
- Raw snapshot SHA-256: `172A535BB17166B6B2D014E464044BA0B23BE5804CC0DB2D56D8CEBC5B8968C6`

The same corrected projection was replayed locally against the exact returned live bytes
and produced the deterministic projection in `CONT1R1_LIVE_SINGLE_PROJECTION.csv`.
