# META-8A exact PRODUCT candidate decision

Executing role META_UPDATE_AGENT. Owner/Architect decision META-8A_TASK_DIRECTIVE; SSOT WRITE AUTHORIZED; TRACK_GATE_ACCEPTANCE; expected revision 7, resulting revision 8.

## Accepted offline G2B PRODUCT test candidate — META-8A

G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.

| Candidate binding | Exact value |
|---|---|
| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Runtime BUILD_FLAGS | `0x00000103` |
| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |

The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.

R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.

G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).

Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.

The complete frozen decision is preserved verbatim in META8A_WRITE_CONTRACT_RECEIPT.md. This is gate acceptance and a product test-candidate inventory addition, not a release baseline replacement.
