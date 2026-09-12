# Owner authorization

- Task: `G2B-NVP-CAMERA-ACQ1-R1`.
- Owner prompt SHA-256: `1C8FC6556291AA4824AD797A8ECE2F056EEDC3CCBD14DF7BA98BF1190C334F95`; byte size: `38603`.
- Authorized conditional scope: CH1 connected baseline, exact slice order `Bank5/0x08=level` then `Bank5/0x05=0xA4`, exact AHD/CVI gate, AHD 1080p25-only compiled mode/EQ, lock, BT.656, bounded capture, and exact rollback.
- Authorized slice levels: `0x50`, `0x40`, `0x60`.
- Other formats: `REPORT_ONLY_NO_MODE_WRITE`.
- Generic host NVP I2C: prohibited.
- Runtime adaptive EQ, CH2-CH4 writes, Flash, power-cycle, PRODUCT/SSOT/META changes: prohibited.
- Mandatory pre-implementation gate: every potentially touched functional register must have exact baseline/readback/rollback authority.
- Applied hard stop: `ACQ1_R1_COMPLETE_ROLLBACK_AUTHORITY_NOT_PROVEN`.
