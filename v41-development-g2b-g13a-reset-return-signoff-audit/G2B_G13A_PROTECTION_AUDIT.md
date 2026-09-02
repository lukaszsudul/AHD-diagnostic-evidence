# AHD v41 G2B-G13-A — Source, State, and Hardware Protection Audit

## Governed source identity

| Check | Start value | End value | Result |
|---|---|---|---|
| Worktree | `C:/FPGA/V41_G2B` | `C:/FPGA/V41_G2B` | PASS |
| Branch | `integration/v41-g2b-onech-c2h` | `integration/v41-g2b-onech-c2h` | PASS |
| HEAD | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` | PASS |
| Tree | `1e67e3f1fe06669839fe9ff8573e4d1e0114a889` | `1e67e3f1fe06669839fe9ff8573e4d1e0114a889` | PASS |
| Tracked worktree diff | none | none | PASS |
| Index diff | none | none | PASS |
| Active XDC SHA-256 | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` | PASS |

All candidate and report files are confined to the diagnostic evidence
repository. The candidate was sourced only into an isolated in-memory Vivado
analysis context opened from the accepted routed DCP.

## Primary-workspace observation

The user-named primary workspace `C:/FPGA/FPGA_AHD` is a separate checkout.
It had no tracked or index delta created by this audit. Pre-existing untracked
`.codex_tmp/` and `reports/` entries were observed and left untouched.

| Check | Start value | End value | Result |
|---|---|---|---|
| Branch | `main` | `main` | PASS |
| HEAD | `be94f88ee8d179f12928ab791bdae27c22cd1762` | `be94f88ee8d179f12928ab791bdae27c22cd1762` | PASS |
| Tree | `e128ff47a5e21e8131971f5e5caa7657e2eccc7f` | `e128ff47a5e21e8131971f5e5caa7657e2eccc7f` | PASS |
| Tracked worktree diff | none | none | PASS |
| Index diff | none | none | PASS |
| Untracked observation | `.codex_tmp/`; `reports/` | `.codex_tmp/`; `reports/` | PASS — unchanged/pre-existing |

`FPGA_AHD_MODIFIED = NO`

## Routed-checkpoint protection

| Check | Value | Result |
|---|---|---|
| Path | `C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp` | exact authority |
| Size | `57,900,063` bytes | exact authority |
| SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` | VERIFIED |
| Use | `open_checkpoint` read/analysis only | PASS |
| Substitute DCP | none | PASS |
| Route/synthesis/implementation | not run | PASS |
| Bitstream | not generated | PASS |

## SSOT protection

`PROJECT_STATE_REV_AT_START = 4`

`PROJECT_STATE_REV_AT_END = 4`

The evidence repository's `project-current-state/` tracked content is not
staged or modified by this audit. G2B-LUT1 remains
`READY_FOR_SIGNOFF_RECOVERY / SIGNOFF_RECOVERY_PENDING`; G2B-HW remains
`BLOCKED / NOT_PROVEN`.

The SSOT integrity manifest
`project-current-state/SHA256_MANIFEST.txt` has 18 entries and verified
`18/18 PASS, 0 FAIL` at audit start. Its own SHA-256 is
`BDA7C92947F212BB18AF60738F7AA5974C097AAFD93E90D8E8FBA9BA6F5C39A3`.
Exact `PROJECT_STATE.json` fields used by the authority gate are:

- `project_state_revision = 4`;
- `tracks.product.g2b_lut1.readiness = READY_FOR_SIGNOFF_RECOVERY`;
- `ownership_cdc_signoff.new_required_signoff.method = PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`;
- `ownership_cdc_signoff.new_required_signoff.promotion_state = PROMOTED`;
- `g2b_hardware.status = BLOCKED`; and
- `g2b_hardware.qualification_state = NOT_PROVEN`.

End-of-audit SSOT manifest verification: `18/18 PASS, 0 FAIL`; tracked and
cached diffs under `project-current-state/` are empty.

## Hardware protection

| Action | Performed |
|---|---|
| JTAG access | NO |
| FPGA programming | NO |
| PCIe access | NO |
| DMA access | NO |
| Driver change | NO |
| Reboot | NO |
| Power-cycle | NO |
| DUT access of any kind | NO |

`HARDWARE_ACCESSED = NO`

## Final protection decision

`SOURCE_REPOSITORY_MODIFIED = NO`

`ACTIVE_XDC_MODIFIED = NO`

`INDEX_CHANGED = NO`

`BRANCH_MOVEMENT = NO`

`BITSTREAM_PRODUCED = NO`

`SSOT_MODIFIED = NO`
