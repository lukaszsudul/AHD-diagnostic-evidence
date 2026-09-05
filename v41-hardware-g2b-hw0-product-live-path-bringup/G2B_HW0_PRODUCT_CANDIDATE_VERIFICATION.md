# G2B HW0 PRODUCT Candidate Verification

Result: `PASS`

Verification time: `2026-09-05T22:24:21+02:00` through
`2026-09-05T22:36:14+02:00`.

## Candidate artifacts

| Artifact | Expected bytes | Actual bytes | Expected SHA-256 | Actual SHA-256 | Result |
|---|---:|---:|---|---|---|
| `G2B_PRODUCT_RECOVERY4.bit` | 2192144 | 2192144 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` | `VERIFIED` |
| `G2B_PRODUCT_SIGNED_OFF.dcp` | 15726324 | 15726324 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` | `VERIFIED` |

No artifact was copied over another candidate, regenerated, or modified.

## Source publication and worktree protection

- Repository: `lukaszsudul/FPGA_AHD`
- Branch: `integration/v41-g2b-onech-c2h`
- Local and remote commit: `92e9b3d914134c044371779def1ee18eaaeda98a`
- Tree: `cf6bf82249c90782eab1978c68541ed9c0e6430b`
- Authoritative worktree: `C:\FPGA\V41_G2B`
- Tracked/index state: clean; untracked count: zero.
- Protected primary worktree remained on `main` at
  `be94f88ee8d179f12928ab791bdae27c22cd1762`, tracked/index clean.
- All pre-existing untracked files in the protected primary worktree were
  preserved.

## Evidence authority

- SSOT revision: `8`; SSOT manifest `18/18 PASS`.
- META-8A commit `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`;
  manifest `32/32 PASS`; remote `main` matched.
- Recovery-4 commit `6843d582fd367fbc0edc0b1d55a9617162c489b0`;
  manifest `181/181 PASS`; all mandatory files present.
- Candidate status: `ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate classification: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- Hardware qualification: `NOT_PROVEN`.

## Promoted identity tuple

- Runtime embedded GIT SHA expected:
  `224d194e5f82c85bcb29297561c5d5e76d28063b`.
- Runtime BUILD_FLAGS expected: `0x00000103`.
- Sealed input manifest SHA-256:
  `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD`.

The older embedded SHA is intentional under the constraints-only routed-DCP
recovery. Runtime verification was not reached because the required legacy
MMIO read was outside this task's authorization.
