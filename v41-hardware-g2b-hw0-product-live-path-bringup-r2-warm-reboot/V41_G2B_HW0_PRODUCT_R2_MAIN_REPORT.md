# AHD v41 G2B-HW0-PRODUCT-R2 Warm-Reboot PCIe Re-enumeration and Live-Path Bring-Up

## Result

| Field | Result |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `PASS` |
| Overall result | `BLOCKED` |
| T0 pre-reboot authority/exclusivity gate | `PASS` |
| T1 warm-reboot/endpoint gate | `BLOCKED` |
| T2 runtime/MMIO gate | `NOT_REACHED` |
| T3 one-record gate | `NOT_REACHED` |
| T4 finite-capture gate | `NOT_REACHED` |
| T5 continuous-capture gate | `NOT_REACHED` |
| Remote read-back | `PASS` |
| First blocker | `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE` |
| Final execution point | `HARD STOP AFTER G2B-HW0-PRODUCT-R2 WARM-REBOOT LIVE-PATH BRING-UP` |

The one authorized graceful warm reboot succeeded. The exact DUT disconnected,
reconnected at the same IP, and returned with one new authenticated boot ID.
The exact PRODUCT candidate remained configured in volatile SRAM with five
post-reboot and five final `DONE=1` samples. The exact AHD endpoint enumerated
at `0000:01:00.0` behind `0000:00:01.1`, correlation passed, and the live
link negotiated PCIe Gen2 x1.

Execution stopped at the XDMA portion of T1. The only installed module named
`xdma` is a platform-bus driver with only alias `platform:xdma`; zero matching
platform devices exist, and no installed module resolves the endpoint's exact
PCI modalias for `10ee:7011`. Loading that module could not bind the AHD
PCI function or create the required user/C2H nodes. The governed decision was
`DO_NOT_LOAD_OR_BIND`, producing `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE`. No module load, bind, MMIO access,
stream operation, or DMA capture followed.

## Authority and immutable inputs

- R1 evidence commit: `eb3a75c09925574c6947d67cdefb8e2a723add9e`; package and final state verified.
- `PROJECT_STATE_REV_AT_START = 8`.
- `PROJECT_STATE_REV_AT_END = 8`.
- META-8A: `VERIFIED / PROMOTED`.
- G2B-LUT1: `ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- G2B-HW0-PRODUCT readiness: `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- Source worktree: `C:\FPGA\V41_G2B`.
- Source branch: `integration/v41-g2b-onech-c2h`.
- Source commit/tree: `92e9b3d914134c044371779def1ee18eaaeda98a` / `cf6bf82249c90782eab1978c68541ed9c0e6430b`.
- PRODUCT bitstream: 2,192,144 bytes, SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
- Signed-off DCP: 15,726,324 bytes, SHA-256 `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`.
- Owner warm-reboot authorization: `GRANTED`; maximum warm reboots: `1`.
- Power cycle, R2 SRAM reprogramming, and Flash programming: `DENIED`.
- Legacy MMIO reads: `GRANTED`; legacy MMIO writes: `DENIED`.

## Pre-reboot authority and locks

The authoritative DUT was `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`,
authenticated as `vcdeagent1`, machine ID
`0e90f50d9465492b80258da5658446f8`. Its pre-reboot boot ID was
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`. The inherited R1 state was confirmed: exact candidate retained
by operation continuity, `DONE=1`, AHD endpoint absent, XDMA unloaded, zero
XDMA nodes, Flash unchanged, and no R1 reboot.

Fresh controller and Linux exclusivity checks passed. The controller lock was
acquired at `2026-09-06T06:44:21.3498081Z`, remained held across the reboot and
all post-reboot work, and was released last after final-state capture. The
pre-reboot Linux lock was held before delivery. After reconnect and fresh
exclusivity, the post-reboot Linux lock was acquired and later released before
the controller lock.

## One controlled warm reboot

The first local wrapper invocation was rejected during controller-local
argument validation before a password file, child process, Plink, SSH session,
remote command, acknowledgement, or reboot existed. Its evidence was preserved,
and bookkeeping was corrected from one local wrapper rejection to zero remote
deliveries and zero warm reboots. This was not a reboot attempt.

The guarded delivery then consumed the only remote-delivery budget before
launch. Exactly one remote `systemd-run` timer scheduled unforced
`systemctl reboot`; the schedule acknowledgement passed. SSH disconnect was
observed at `2026-09-06T07:07:54.9070207Z`, and TCP reconnect on only
`10.132.1.111:22` was observed at `2026-09-06T07:08:25.1682075Z`, within
30.280 seconds of the bounded 895-second monitor. Authenticated post-reboot
identity returned boot ID `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac`, proving exactly one boot transition.
No second reboot and no power cycle occurred.

## T1 passed subgates and blocker

- Candidate retained across warm reboot: `PASS`.
- FPGA: `xc7a35t`, IDCODE `0362D093`, chain index 0, `DONE=1`.
- AHD endpoint after reboot: `PASS`, BDF `0000:01:00.0`.
- Identity: `10ee:7011`, subsystem `10ee:0007`, class `058000`.
- Upstream/root port: `0000:00:01.1`.
- Post-reboot JTAG-to-PCIe correlation: `PASS`.
- Endpoint `LnkCap`: `Speed 5GT/s, Width x1`.
- Endpoint `LnkSta`: `Speed 5GT/s, Width x1`.
- PCIe Gen2 x1 hardware gate: `PASS`.
- Endpoint driver: none; XDMA module unloaded; XDMA nodes: zero.
- Installed module: `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst`.
- Installed module SHA-256: `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490`.
- Installed module aliases: only `platform:xdma`; matching platform devices: 0.
- Exact AHD PCI modalias resolution: no installed module.
- Safe AHD XDMA bind: `BLOCKED`.
- XDMA node-to-BDF mapping: `NOT_REACHED`.

T1 therefore remains `BLOCKED` at `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE` even though the warm reboot,
retention, endpoint, correlation, and link-negotiation subgates passed.

## Downstream disposition

T2 through T5 are `NOT_REACHED`. Expected runtime identity remains embedded
Git SHA `224d194e5f82c85bcb29297561c5d5e76d28063b` and `BUILD_FLAGS=0x00000103`, but neither value was
read. Legacy identity MMIO, NVP/video telemetry MMIO, G2B MMIO, ABI/profile,
first record, 2500-record capture, frame reconstruction, and 60-second capture
were not attempted. First-record and frame hashes are `NONE`.

The offline expected transport contract remains
`AHD_C2H_TRANSPORT_ABI_V1`, version `1`, with record/header/payload/padding
geometry `4096/64/3840/192` bytes. It was not observed in R2 because T2 was
not reached.

## Final state and protected boundaries

Final JTAG evidence shows the candidate retained in volatile SRAM and five of
five `DONE=1` samples. Endpoint `0000:01:00.0` remains present, Gen2 x1,
unbound, with XDMA unloaded and zero nodes. The stream was never enabled.

R2 operation counts were exactly: one warm reboot; zero power cycles; zero
SRAM or Flash programs; zero module loads; zero binds or unbinds; zero PCIe
rescans or resets; zero MMIO reads or writes; zero stream-control writes; and
zero DMA operations. `C:\FPGA\FPGA_AHD`, tracked source in
`C:\FPGA\V41_G2B`, active XDC, SSOT, Flash, driver files, and package state
were not modified. `HARDWARE_THROUGHPUT_288_MB_S = NOT_PROVEN`.
Four-input and two-channel operation are `NOT_QUALIFIED`; synthetic and V4L2
tests were not run; `release/v41.0.0` was not created. G2B-HW qualification is
`NOT_PROVEN`, and `SSOT_UPDATE_REQUIRED = NO`.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot`.
- Required initial commit message: `Run AHD v41 G2B-HW0 PRODUCT warm-reboot live-path bring-up R2`.
- Push mode: ordinary non-force.
- Evidence publication: `PASS`.
- Remote read-back: `PASS`.

Commit-pinned remote byte read-back is PASS for initial evidence commit `3ebab4c05e9c9c3271ed1c5f9d800aabd3020632`, covering `129` files at `2026-09-06T08:24:17.478544Z` with zero missing paths, size mismatches, or SHA-256 mismatches.
