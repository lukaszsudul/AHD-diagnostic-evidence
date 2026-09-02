# AHD v41 G2B-LUT1 Source Change Receipt

## Governed commit

| Field | Value |
|---|---|
| Repository worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Parent | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Commit | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Tree | `1e67e3f1fe06669839fe9ff8573e4d1e0114a889` |
| Subject | `Implement META-4 ownership CDC sign-off constraints for G2B-LUT1` |
| Index after commit | clean |
| Worktree after commit | clean |
| Upstream | none configured |

## Source-authority boundary

Before this task, Gen12 was built from a governed, manifest-sealed uncommitted
G2B worktree based at the parent above. The sealed build-input manifest has 35
entries and SHA-256
`0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD`.
Immediately before the META-4 edit, all 35 inputs matched that manifest.

The commit anchors the already-qualified G2B source, host tools, build harness,
and focused tests that were previously present in that sealed worktree. This
was required so that the new commit tree represents the logical design in the
sealed routed DCP. A commit containing only the formerly-untracked XDC file
would have omitted the G2B RTL and would not have been a valid source authority.

Relative to the sealed Gen12 input manifest, exactly 34 of 35 build inputs are
byte-identical. The sole post-seal mutation is:

| File | Sealed old SHA-256 | Governed new SHA-256 |
|---|---|---|
| `xdc/common/g2b_cdc.xdc` | `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF` | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` |

No RTL/netlist-bearing input changed after the sealed route. The XDC diff is
the exact BS3 Group-9 candidate insertion and retirement of the single old
ownership bus-skew command.

## Exclusion audit

- Unrelated primary-checkout `.codex_tmp/` and `reports/` files were not staged.
- No R-track branch or HDMI project file was modified.
- No XDMA XCI or PCIe configuration file changed.
- No ABI or MMIO contract source changed during this recovery task.
- No hardware was accessed.

`SOURCE_CHANGE_GATE = PASS`
