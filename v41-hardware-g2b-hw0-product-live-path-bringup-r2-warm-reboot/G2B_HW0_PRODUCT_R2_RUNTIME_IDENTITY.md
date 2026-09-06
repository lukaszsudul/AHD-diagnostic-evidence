# G2B-HW0-PRODUCT-R2 Runtime Identity

T2 result: `NOT_REACHED`

| Layer | Expected | Observed | Result |
|---|---|---|---|
| Governed source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` | offline authority only | `VERIFIED` |
| Governed source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` | offline authority only | `VERIFIED` |
| Bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` | offline authority only | `VERIFIED` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` | offline authority only | `VERIFIED` |
| SSOT revision | `8` | `8` | `PASS` |
| Embedded runtime GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` | `N/A` | `NOT_REACHED` |
| Embedded BUILD_FLAGS | `0x00000103` | `N/A` | `NOT_REACHED` |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version `1` | `N/A` | `NOT_REACHED` |
| Record geometry | `4096/64/3840/192` bytes | `N/A` | `NOT_REACHED` |
| Dual-layer identity | both layers agree | `N/A` | `NOT_REACHED` |

The older embedded runtime SHA remains expected because Recovery-4 reused
sealed routed logic and added constraints-only sign-off changes. No exact XDMA
user node existed, so no runtime identity register was read. No claim is made
about runtime identity, PRODUCT profile, transport signature, or ABI.
