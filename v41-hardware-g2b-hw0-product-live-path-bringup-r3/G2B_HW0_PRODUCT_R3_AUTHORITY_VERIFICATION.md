# G2B-HW0-PRODUCT-R3 authority verification

Result: **VERIFIED**

## Authority-at-start chronology

| UTC | Verified item |
|---|---|
| 2026-09-06T13:58:03.300Z | evidence `origin/main` = `9aacc157dab5fe604faf66501b0129613b98ae2d` |
| 2026-09-06T14:00:39.875Z | `PROJECT_STATE_REV = 8` |
| 2026-09-06T14:01:54.724Z | SSOT manifest 18/18 |
| 2026-09-06T14:01:55.159Z | META-8A manifest 32/32 |
| 2026-09-06T14:01:55.631Z | Recovery-4 manifest 181/181 |
| 2026-09-06T14:01:57.793Z | R2 manifest 128/128 |
| 2026-09-06T14:05:52.8563276Z | first authenticated DUT inventory began |
| 2026-09-06T14:09:25.819Z | META-8A/PRODUCT candidate fields decoded |
| 2026-09-06T14:10:16.3587414Z | command-produced remote-ref check time |
| 2026-09-06T14:12:47Z | first read-only JTAG session began |

Chronology source event-log SHA-256:
`52C836EC4C32037714F048DB2569F4BCF828F0E7AC5BB2FBDA44A2818065F6EB`.
The 14:10:16 value is the verifier's embedded `checked_utc`; its orchestration
event completed later at 14:10:24.771Z.

## Packages and candidate

| Package | Commit | Result |
|---|---|---|
| SSOT revision 8 | `9aacc157dab5fe604faf66501b0129613b98ae2d` | 18/18 PASS |
| META-8A | `f92f4d8fcc0dc88d3dc5753c799e1d891846e392` | 32/32 PASS |
| Recovery-4 | `6843d582fd367fbc0edc0b1d55a9617162c489b0` | 181/181 PASS |
| R2 | `9caa9c339966eda999219e4ed686c01654b9a87e` | 128/128 PASS |
| DRV1 | `9aacc157dab5fe604faf66501b0129613b98ae2d` | 30 blobs, 29/29 manifest PASS |

- FPGA part/profile: `xc7a35tcsg325-2` / `PRODUCT`
- source: `integration/v41-g2b-onech-c2h`,
  `92e9b3d914134c044371779def1ee18eaaeda98a`,
  tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`
- bitstream:
  `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`
- DCP:
  `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`
- authorized source: fixed physical input 0, one live AHD channel
- persistent Flash programming: not authorized
- G2B-HW: not proven

`PROJECT_STATE_REV_AT_START = 8`

`PROJECT_STATE_REV_AT_END = 8`

No authority mismatch occurred and SSOT was not modified.

## Commit-pinned R3 driver-load plan

After the governance hard stop, a supplemental read-only verification
materialized the exact plan that the already-verified DRV1 manifest covered:

- source commit: `0a201aab7adb13be079e784c6ed97dfad2ed7764`
- path: `host/xdma/ahd_pcie/G2B_HW0_R3_DRIVER_LOAD_PLAN.md`
- Git blob: `f6d2e493d32207ba891e6494710867bc9921cb9f`
- byte count: `2450`
- SHA-256: `FEF50B4C57570233B92A300C28C5E939BA0B4D6FCB1F48393B1484A66A6715C0`

The plan requires the exact module only, platform `xdma` unloaded, no `new_id`
or `driver_override`, automatic exact-alias probing, dynamic `xdmaN` discovery,
node-to-BDF proof before MMIO, bounded capture, and controlled rollback. R3 did
not weaken the plan: the hard stop occurred before any T1 action. This content
read is post-stop supplemental evidence and is not represented as part of the
earlier authority-at-start chronology.
