
# Primary preservation receipt

- path: `/home/<GOVERNED_USER>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r3/20260908T102555Z/private/primary.bin`
- expected and observed size before cleanup: `10240000` bytes
- ordinary-user open: permission denied because the retained file is root-owned
- governed read-only open under the connection helper: `PASS`
- observed size after cleanup: `10240000` bytes
- final governed read-only open: `PASS`
- accepted SHA-256 (not rehashed as a qualification prerequisite):
  `2AF54B0C894131BCAB0B9A09E5282AD1C7D776184AB193FB4B106D545B5C8EB7`
- rename, move, truncate, delete, or write operation: `NONE`
- `PRIMARY_CAPTURE_PRESERVED_BEFORE_CLEANUP=PASS`
- `PRIMARY_CAPTURE_MODIFIED=NO`

The offline forensic program opened the file read-only and parsed fixed 4096-byte
offsets. No full capture or raw camera payload was copied into public evidence.
