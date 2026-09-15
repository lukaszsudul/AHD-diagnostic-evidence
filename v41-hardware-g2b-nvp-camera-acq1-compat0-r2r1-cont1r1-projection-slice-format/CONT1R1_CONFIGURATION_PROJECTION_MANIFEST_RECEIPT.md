# CONT1R1 projection-to-manifest receipt

- Result: `PASS`
- Key type: `BANK_AND_REGISTER_PAIR`
- Exact manifest entries: `82/82`
- Exact bank groups: `10/10`
- Required projection keys: `13`
- Missing projection keys: `0`
- Duplicate projection keys: `0`
- Unexpected duplicate scan keys: `0`
- Governed repeated sampling key: `(0x00,0xA8)` at entries `0,4,81`
- Old wrong family: `(0x01,0x88)..(0x01,0x8B)` — absent and not required
- ADC-delay family: `(0x01,0x84)..(0x01,0x87)` — present
- Pre-clock family: `(0x01,0x8C)..(0x01,0x8F)` — present

The three A8 operations are the frozen PRE/live/POST sampling sequence and are outside the configuration-projection key set. No ungoverned duplicate projection key exists.
