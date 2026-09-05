# G2B-HW0-PRODUCT-R1 Candidate Verification

Result: `PASS`

## Governance

- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- SSOT manifest: `18/18 PASS`.
- META-8A manifest: `32/32 PASS`; commit
  `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`.
- Recovery-4 manifest: `181/181 PASS`; evidence commit
  `6843d582fd367fbc0edc0b1d55a9617162c489b0`.
- Previous blocked HW0 manifest: `11/11 PASS`; final evidence commit
  `be8e5c6a875d5f4c21717d1fa8b5ae6419d3f8c2`.
- `G2B-LUT1 = ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- `G2B-HW0-PRODUCT = AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Initial source: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- META-8A: `PROMOTED / VERIFIED`.

## Exact source and artifacts

| Item | Exact value |
|---|---|
| Source worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| Remote branch | Exact commit match |
| Bitstream path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit` |
| Bitstream bytes | `2192144` |
| Bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Signed-off DCP path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp` |
| Signed-off DCP bytes | `15726324` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| FPGA part | `xc7a35tcsg325-2` |
| Offline profile | `PRODUCT` |

The pre-program task checks found both protected worktrees tracked-clean. The
post-hardware replay in `raw/LOCAL_AUTHORITY_VERIFICATION.log` re-established
that state and rehashed the bitstream and DCP with the same exact results.
No source, active XDC, SSOT, or binary artifact was modified. Offline PRODUCT
authority does not constitute runtime identity or hardware qualification.
