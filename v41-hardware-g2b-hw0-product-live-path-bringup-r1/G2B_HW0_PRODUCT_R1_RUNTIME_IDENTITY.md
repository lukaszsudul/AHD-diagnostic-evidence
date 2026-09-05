# G2B-HW0-PRODUCT-R1 Runtime Identity

Dual-layer identity result: `NOT_REACHED`

The governed candidate layer passed offline:

- source commit `92e9b3d914134c044371779def1ee18eaaeda98a`;
- source tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`;
- bitstream SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`;
- DCP SHA-256 `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`;
- SSOT revision `8` and META-8A `VERIFIED`.

Expected runtime layer:

- embedded `GIT_SHA=224d194e5f82c85bcb29297561c5d5e76d28063b`;
- `BUILD_FLAGS=0x00000103`;
- PRODUCT profile indication;
- transport `AHD_C2H_TRANSPORT_ABI_V1`, ABI version 1;
- legacy block/protocol/build schemas and Vivado build;
- NVP initialization, NACK, `INIT_ERROR`, live-video, VCLK, SAV, and frame
  telemetry.

T1 blocked before an exact XDMA user device existed. Therefore no legacy or
G2B MMIO was read, and none of the expected runtime values is reported as an
observed hardware value. PRODUCT profile, transport ABI, NVP readiness, and
fixed live source remain `NOT_REACHED`.
