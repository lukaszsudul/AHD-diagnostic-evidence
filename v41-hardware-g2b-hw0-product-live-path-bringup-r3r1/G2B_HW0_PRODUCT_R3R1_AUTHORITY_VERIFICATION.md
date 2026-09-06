# G2B-HW0-PRODUCT-R3R1 authority verification

## Repository and SSOT

- repository branch: `main`
- preflight local and live remote HEAD:
  `8c957106a82deeb9649211696177fa5f6529b051`
- tree: `879543ac1ba61b272d3c7298f2414dcf64c69ab1`
- tracked worktree/index: clean
- pre-existing untracked paths: `71`, confined to `.diag0-work` and
  `.meta8a-work`; preserved without modification
- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- no newer revision found

SSOT confirms META-8A, the exact offline PRODUCT candidate, separate
controlled HW0 authorization, fixed one-channel live scope, hardware
`NOT_PROVEN`, and persistent Flash programming not authorized.

## Exact evidence commits and committed-blob manifests

| Authority | Commit | Manifest result |
|---|---|---:|
| META-8A | `f92f4d8fcc0dc88d3dc5753c799e1d891846e392` | `32/32` |
| Recovery-4 | `6843d582fd367fbc0edc0b1d55a9617162c489b0` | `181/181` |
| R2 | `9caa9c339966eda999219e4ed686c01654b9a87e` | `128/128` |
| DRV1 | `9aacc157dab5fe604faf66501b0129613b98ae2d` | `29/29` public |
| failed R3 | `8c957106a82deeb9649211696177fa5f6529b051` | `66/66` |
| SSOT | current | `18/18` |

Failed R3 is verified as a procedural boundary failure before `insmod`:
load attempts `0`; no module, probe, bind, nodes, MMIO, DMA, C2H, programming,
reboot, or power-cycle; endpoint present/unbound at Gen2 x1; taint `0`; prior
credential temp files deleted and no credential leak.

## PRODUCT authority

- part/profile: `xc7a35tcsg325-2` / `PRODUCT`
- source commit/tree:
  `92e9b3d914134c044371779def1ee18eaaeda98a` /
  `cf6bf82249c90782eab1978c68541ed9c0e6430b`
- source worktree tracked/index/untracked clean
- bitstream: `2192144` bytes,
  `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`
- DCP: `15726324` bytes,
  `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`

## Driver evidence authority

- sealed path:
  `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`
- bytes: `3296104`
- SHA-256:
  `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
- expected module/architecture/vermagic/alias are consistent in DRV1 evidence

Fresh DUT-side revalidation: `NOT_REACHED`.

## Frozen contract hard blocker

Authoritative ABI SHA-256:
`AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6`.

Normative `parser_contract` lines 946–951 require session-start
`RESET_STREAM_STATE` and set mid-epoch attachment false. Lines 980–987 define
the first valid record after that mandatory reset. Revision-8
`CURRENT_INTERFACES.md` lines 453–461 repeats the rule.

Required write: `0x380C=0x00000004`.

R3R1 authorized writes exclude it and explicitly prohibit transport reset and
error clear. No exception exists.

`AUTHORITY_VERIFICATION = BLOCKED_FOR_LIVE_EXECUTION`
