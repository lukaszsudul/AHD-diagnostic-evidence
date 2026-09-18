# W4 authority and Owner scope

Task `CONT1R3R4R7-W4-C3-PNR1-AB` was authorized by the Owner for bounded DUT admission, exact C3-PNR1 SRAM activation, one control scan, 16 × 16 OFF/ON scans, cleanup, and publication. This did not authorize MODE1, functional NVP configuration, DMA, capture, Flash, a new FPGA build, XSim, driver modification, or camera configuration.

Project-current-state revision was 9 at start and end. Its pinned tree was `24e8b5e3f7b151bebe6b8da5dc102d734037ee48`; all 18 local SSOT manifest entries matched before publication. SSOT and prior evidence are unchanged by the W4 evidence commit.

Source candidate C3 commit `70266f0b90c6fc6a853495eba1d526b285fd7286`, tree `5f2bd8377985406b45433418b20be8993399bcb6`; source revision budget 4/4 used unchanged. Release evidence commit `c23143d37c6518e6f7859ecebf4a4eb0f339f55b`. Inherited final LUT 19995/20384 and WNS +0.102 ns belong to C3 release, not a new W4 implementation result. `BEHAVIORAL_ASSURANCE=LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY`.

Exact bitstream: `AHD_v41_W3A_C3_PNR1_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B`. Signed DCP provenance SHA-256 `A99EDFE4DF21A3607EC1C31464AD4A03EC6717FCBABBC2979FDA4DFF48E188A5`. Released C3 host manifest SHA-256 `E2F16444A1B6DA59603774A79AE24D60541151DF05D3CD976BE87915BAE79478` and seven released files retained exact bytes. C3 contract SHA-256 `7F2A9647EF60D360B9884E57F6FAE16BCAFC4DD8F60D592CE0A44D728FA67D39`; status-bit1 erratum SHA-256 `B3764AC42EE2A26DA0202FF50F906E087B96A7A6E017DBCA020DF52849990689` applied.
