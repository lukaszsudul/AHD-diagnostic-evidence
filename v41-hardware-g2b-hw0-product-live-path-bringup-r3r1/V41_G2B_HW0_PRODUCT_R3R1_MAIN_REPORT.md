# AHD v41 G2B-HW0-PRODUCT-R3R1 main report

## Outcome

| Gate | Result |
|---|---|
| Engineering | `BLOCKED` |
| Evidence publication | `PASS` |
| Overall | `BLOCKED` |

First blocker:

`BLOCKED — R3R1_AUTHORIZATION_CONFLICT_WITH_FROZEN_C2H_SESSION_START_CONTRACT`

The task stopped before the first authenticated DUT connection and before any
JTAG, PCIe, module, MMIO, DMA, stream-control, FPGA-programming, reboot, or
power-cycle operation.

## Authority verified

- SSOT revision at start and end: `8`.
- Live `origin/main` at preflight: `8c957106a82deeb9649211696177fa5f6529b051`.
- META-8A: `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`.
- Recovery-4: `6843d582fd367fbc0edc0b1d55a9617162c489b0`.
- R2: `9caa9c339966eda999219e4ed686c01654b9a87e`.
- DRV1: `9aacc157dab5fe604faf66501b0129613b98ae2d`.
- Failed R3: `8c957106a82deeb9649211696177fa5f6529b051`.
- Required manifests passed: SSOT `18/18`, META-8A `32/32`, Recovery-4
  `181/181`, R2 `128/128`, DRV1 public `29/29`, R3 `66/66`.
- PRODUCT source: branch `integration/v41-g2b-onech-c2h`, commit
  `92e9b3d914134c044371779def1ee18eaaeda98a`, tree
  `cf6bf82249c90782eab1978c68541ed9c0e6430b`, tracked/index/untracked clean.
- PRODUCT bitstream SHA-256:
  `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
- Signed-off DCP SHA-256:
  `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`.
- DRV1 evidence binds the sealed module to SHA-256
  `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`.

No fresh Linux read of the sealed module was performed in R3R1.

## Literal contract conflict

The authoritative ABI copy has SHA-256
`AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6`.
Its `parser_contract.session_start_requirement` mandates this order:

1. negotiate while disabled;
2. issue `RESET_STREAM_STATE`;
3. wait for reset-complete empty/inactive state;
4. record the resulting epoch;
5. perform legal post-reset fatal W1C if required;
6. explicitly enable.

It also sets `mid_epoch_attach_allowed` to `false`. Revision-8 SSOT repeats
that every Linux consumer must issue `RESET_STREAM_STATE` before enable and
states that mid-epoch attachment is not conforming.

The required reset is `CONTROL[2]`, an aligned write of
`0x380C = 0x00000004`. Conditional fatal clearing uses `0x383C`.

R3R1 authorizes only:

- `0x380C = 0x00000001`;
- `0x380C = 0x00000000`;
- `0x3844 = 0x00000001`.

It expressly forbids transport reset and error/statistics clearing. There is
no clean-boot, first-reader, fresh-driver, pristine-counter, or initial-epoch
exception. Starting C2H without the mandatory reset would violate the frozen
input contract; issuing the reset would violate the R3R1 write allowlist.

## Fresh R3R1 procedural boundary

Fresh controller root:

`C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z`

A new connection helper was authored from scratch at:

`C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z\scripts\Invoke-R3R1DutConnection.ps1`

Its SHA-256 is
`50C1736A178B8807C1AEC752041C266BF58CE7015765EDCCC0D7C4A688F2F42E`.
Static hard gate: `PASS`. It was never executed.

The private directory was initially empty, ACL-restricted to the current
controller user, remained empty, and was removed. Credential remnants: `0`.
Authenticated DUT connections: `0`.

The prior immutable R1 boundary remained exactly unchanged: `107` files,
`38` descendant directories, identical root and secret-subtree timestamps,
and four identical sentinel hashes. New writes: `0`.

## Non-claims and preservation

- T0 procedural/authority/exclusivity gate: `BLOCKED`.
- T1 through T5: `NOT_REACHED`.
- Driver load attempts: `0`.
- Module load/unload, automatic probe/bind, XDMA nodes: `NOT_RUN`.
- MMIO reads/writes: `0/0`.
- DMA/C2H reads: `0`.
- FPGA SRAM programming: `NO`.
- Flash programming: `NO`.
- Reboot/power-cycle: `NO/NO`.
- Hardware qualification: `NOT_PROVEN`.
- `>=288 MB/s`: `NOT_PROVEN`.
- four-input selection/two-channel/synthetic/V4L2: `NOT_QUALIFIED` or
  `NOT_TESTED`.
- `release/v41.0.0`: `NOT_CREATED`.
- SSOT update required: `NO`.

The exact corrective action is a new governed decision that authorizes
`0x380C = 0x00000004` once per actual capture-session start and exact legal
`0x383C` post-reset fatal-bit W1C masks if any fatal bits remain. No broader
write authority is requested.
