# AHD v41 G2B-HW0-PRODUCT-R1 Exact Candidate Live-Path Bring-Up

## Result

| Field | Result |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `PASS` |
| Overall result | `BLOCKED` |
| T0 candidate/environment gate | `PASS` |
| T1 SRAM/endpoint gate | `BLOCKED` |
| T2 runtime/MMIO gate | `NOT_REACHED` |
| T3 one-record gate | `NOT_REACHED` |
| T4 finite-capture gate | `NOT_REACHED` |
| T5 continuous-capture gate | `NOT_REACHED` |
| Remote read-back | `PASS` |
| First blocker | `BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE` |
| Final execution point | `HARD STOP AFTER G2B-HW0-PRODUCT-R1 LIVE-PATH BRING-UP` |

The exact offline-qualified PRODUCT candidate was programmed once into volatile
SRAM. The command returned successfully and `DONE=1` was confirmed immediately
and again in five independent final samples. The AHD PCIe endpoint did not
return during the bounded automatic-recovery interval. Read-only feasibility
checks then proved that no exact AHD-only root-port or endpoint subtree was
available for the one conditionally authorized recovery operation. Execution
therefore stopped before any PCIe write, driver bind, MMIO access, or DMA.

## Authority and immutable inputs

- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- META-8A: `VERIFIED`; evidence commit
  `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`.
- Previous blocked HW0 evidence: `VERIFIED`; final evidence commit
  `be8e5c6a875d5f4c21717d1fa8b5ae6419d3f8c2`.
- Recovery-4 evidence commit:
  `6843d582fd367fbc0edc0b1d55a9617162c489b0`.
- `G2B-LUT1 = ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- `G2B-HW0-PRODUCT = AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Initial source: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- META-8A state: `PROMOTED / VERIFIED`.
- SSOT, META-8A, Recovery-4, and previous-HW0 manifests verified respectively
  `18/18`, `32/32`, `181/181`, and `11/11`, with zero mismatches.
- Owner hardware authorization: `GRANTED`.
- Additional legacy-MMIO read authorization: `GRANTED` for aligned reads only
  in `0x0000..0x0030` and `0x0080..0x00B4` after T1.
- Legacy-MMIO write authorization: `DENIED`.
- Documented G2B control access was authorized only in `0x3800..0x3BFF`; T2
  was not reached, so no G2B access occurred.

The authoritative source worktree `C:\FPGA\V41_G2B` was tracked-clean at
branch `integration/v41-g2b-onech-c2h`, commit `92e9b3d914134c044371779def1ee18eaaeda98a`, tree
`cf6bf82249c90782eab1978c68541ed9c0e6430b`, with the remote branch at the same commit. The exact PRODUCT
bitstream is 2,192,144 bytes with SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`. The signed-off DCP is
15,726,324 bytes with SHA-256 `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`. Their local paths and rehashes are
recorded in `G2B_HW0_PRODUCT_R1_CANDIDATE_VERIFICATION.md`.

The pre-program authority checks were completed in the executing task before
T0. `raw/LOCAL_AUTHORITY_VERIFICATION.log` is a post-hardware read-only replay
at `2026-09-05T22:21:45Z`; it proves the protected static state was preserved
after execution and does not claim an earlier capture timestamp.

## T0 and board ownership

The authenticated DUT was `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`,
machine ID `0e90f50d9465492b80258da5658446f8`, user `vcdeagent1`, kernel
`7.0.0-29-generic`, and boot ID
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`. Host-key pinning and sanitized
credential handling passed. Fresh process checks found no competing JTAG,
Vivado, XDMA, or capture owner. Exact Windows and Linux task locks were held
before programming and released only after final-state capture.

Fresh JTAG selection found exactly one target,
`localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`, and one device at chain
index 0: `xc7a35t`, IDCODE `0362D093`, 6 MHz. Five pre-program samples all
reported `DONE=0`. Accepted historical binding evidence correlates this exact
cable/device/DUT to AHD endpoint `0000:01:00.0`, parent `0000:00:01.1`,
`10ee:7011`, subsystem `10ee:0007`, class `058000`. That binding was used only
for T0 physical-board correlation; it was not used to claim that a current
endpoint existed. T0 passed.

This was a fresh T0 correlation decision: the current JTAG and PCIe inventories
were combined with the accepted physical binding because an unprogrammed
`DONE=0` FPGA exposes no live endpoint. The accepted binding sources were
reviewed in the executing task before T0. The later
`raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log` is a post-run hash replay
of those same sources, not a claim that a live endpoint existed before program.

## One authorized SRAM program

- Program start: `2026-09-05T22:03:58Z`.
- Command returned/end: `2026-09-05T22:04:05Z`.
- Program invocations: `1`; retry count: `0`.
- Target/device: exact selector above, `xc7a35t`, IDCODE `0362D093`.
- Vendor startup result: `HIGH`.
- Immediate result: `PROGRAM_TCL_RESULT=PASS_DONE_1` and `DONE=1`.
- Final independent JTAG session: five of five samples `DONE=1`, ending
  `2026-09-05T22:14:31Z`.
- Flash, CFGMEM, and PROGRAM_B operations: `0`.

## Endpoint recovery and first blocker

The bounded automatic wait ran from `2026-09-05T22:05:55Z` through
`2026-09-05T22:06:26Z`; `AUTO_RECOVERY_FOUND=0`. No Xilinx/AHD endpoint and no
XDMA node appeared.

Fresh read-only recovery feasibility then established:

- accepted AHD root function `0000:00:01.1` was absent from PCI config and
  sysfs;
- `0000:00:01.0` was an AMD Phoenix Dummy Host Bridge, so its rescan was not
  proven AHD-only;
- the current external tree was `0000:00:02.1` to AMD switch upstream
  `0000:01:00.0`, then seven downstream ports serving buses 03 through 09;
- several downstream branches were empty and several contained unrelated
  Ethernet, USB, or SATA devices, with no slot map and no evidence selecting
  one branch as AHD;
- endpoint-specific reset/remove was impossible because the endpoint was
  absent.

Rescanning the root/current switch would have covered an unrelated-device
subtree, while choosing an empty downstream port would have been guesswork.
No recovery write was issued. The required first blocker is therefore
`BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`. T1 is `BLOCKED`; the actual AHD endpoint check is `FAIL` because
the post-program endpoint was sought and remained absent. PCIe Gen2 x1, exact
XDMA mapping, and T2 through T5 are `NOT_REACHED`.

## Runtime and capture disposition

The governed offline runtime expectations remain embedded Git SHA
`224d194e5f82c85bcb29297561c5d5e76d28063b` and `BUILD_FLAGS=0x00000103`. They were not read from
hardware. Dual-layer identity, transport ABI, PRODUCT profile, legacy identity
MMIO, NVP/video telemetry, MMIO baseline, NVP initialization, fixed live
source, first record, finite capture, frame reconstruction, and continuous
capture are all `NOT_REACHED`.

No first-record or frame payload was created. Their hashes are `NONE`, and
their local paths are `N/A`. There is no claim about a 4096-byte record,
header, payload, padding, sequence, epoch, frame, live-video validity, internal
AXI `TKEEP`/`TLAST`, or throughput.

## Final state and protection

The exact programmed candidate remains in volatile SRAM by the unbroken
programming chain, and final JTAG reads show `DONE=1`. The AHD endpoint is
absent; its BDF, vendor/device, LnkCap, and LnkSta are `N/A`. The `xdma` module
is not loaded, the xdma driver sysfs directory is absent, and the XDMA node
count is zero. Last MMIO state is `NOT_REACHED_NO_MMIO_ACCESS`; the G2B stream
was never enabled. Both task locks were released after this state was captured.

`C:\FPGA\FPGA_AHD`, tracked source in `C:\FPGA\V41_G2B`, active XDC, SSOT,
Flash, driver files, package state, reboot state, and power state were not
modified. The task performed zero PCI config writes, rescans, resets, MMIO
reads, MMIO writes, and DMA captures. `HARDWARE_THROUGHPUT_288_MB_S` remains
`NOT_PROVEN`; four-input selection and two-channel capture are `NOT_QUALIFIED`;
the PRODUCT synthetic generator remains `NO`; V4L2 was not tested; and
`release/v41.0.0` was not created. `G2B-HW qualification = NOT_PROVEN` and
`SSOT_UPDATE_REQUIRED = NO`.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `v41-hardware-g2b-hw0-product-live-path-bringup-r1`.
- Required initial commit message: `Run authorized AHD v41 G2B-HW0 PRODUCT live-path bring-up R1`.
- Initial evidence commit: `77d3d30f5ebd4df3fa7be69e18b671a1ef8bcc0d`.
- Push mode: ordinary non-force.

The initial evidence commit and commit-pinned byte read-back are recorded in `G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md`.

## Final-response field ledger

| Field | Exact value |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `PASS` |
| Overall result | `BLOCKED` |
| PROJECT_STATE_REV_AT_START / END | `8 / 8` |
| META-8A / previous blocked HW0 evidence | `VERIFIED / VERIFIED` |
| Owner hardware authorization | `GRANTED` |
| Additional legacy MMIO read / legacy MMIO write | `GRANTED / DENIED` |
| Authoritative Linux DUT | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Authenticated connection / exclusivity | `PASS / PASS` |
| Source worktree / commit | `C:\FPGA\V41_G2B / 92e9b3d914134c044371779def1ee18eaaeda98a` |
| PRODUCT bitstream / SHA-256 | `VERIFIED / AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Signed-off DCP / SHA-256 | `VERIFIED / 95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| JTAG-to-PCIe board correlation | `PASS` at T0 from accepted physical binding |
| FPGA device | `xc7a35t / 0362D093 / chain index 0` |
| SRAM / Flash programming | `PASS / NO` |
| DONE | `1` |
| AHD endpoint / BDF | `FAIL / N/A` |
| PCIe vendor-device / LnkCap / LnkSta | `N/A / N/A / N/A` |
| PCIe Gen2 x1 / XDMA driver | `NOT_REACHED / NOT_REACHED` |
| XDMA version-hash / user / C2H | `N/A / N/A / N/A` |
| Runtime embedded GIT_SHA / BUILD_FLAGS | `N/A / N/A` |
| Expected runtime GIT_SHA / BUILD_FLAGS | `224d194e5f82c85bcb29297561c5d5e76d28063b / 0x00000103` |
| Dual-layer identity / transport ABI / ABI version | `NOT_REACHED / NOT_REACHED / N/A` |
| PRODUCT / legacy / NVP / baseline MMIO | `NOT_REACHED / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| NVP initialization / NACK count / INIT_ERROR | `NOT_REACHED / N/A / N/A` |
| Fixed live source | `NOT_REACHED` |
| T0 / T1 / T2 / T3 / T4 / T5 | `PASS / BLOCKED / NOT_REACHED / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| First record bytes / SHA / header / payload / padding | `N/A / NONE / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| Finite requested / received | `2500 / N/A` |
| Finite gaps / duplicates / padding errors / epoch changes | `N/A / N/A / N/A / N/A` |
| Frame reconstruction / SHA | `NOT_REACHED / NONE` |
| Continuous duration / records / records per second | `N/A / N/A / N/A` |
| Estimated frame rate / application payload / transport throughput | `N/A / N/A / N/A` |
| Malformed / unexplained gaps / formatter fatal / ownership fatal | `N/A / N/A / N/A / N/A` |
| One-channel live AHD path | `NOT_REACHED` |
| Hardware throughput >=288 MB/s | `NOT_PROVEN` |
| Four-input / two-channel | `NOT_QUALIFIED / NOT_QUALIFIED` |
| Synthetic generator / V4L2 / release | `NO / NOT_TESTED / NOT_CREATED` |
| Final FPGA state | Exact candidate last programmed to volatile SRAM; `DONE=1` |
| Final PCIe/driver state | AHD absent; xdma unloaded; zero nodes; no binding |
| Persistent state / reboot / power-cycle | `NO / NO / NO` |
| Hardware accessed | `YES` |
| G2B-HW0-PRODUCT / G2B-HW qualification | `BLOCKED / NOT_PROVEN` |
| SSOT update required | `NO` |
| Evidence repository / directory | `lukaszsudul/AHD-diagnostic-evidence / v41-hardware-g2b-hw0-product-live-path-bringup-r1` |
| Evidence commit | `77d3d30f5ebd4df3fa7be69e18b671a1ef8bcc0d` |
| Remote read-back | `PASS` |
| Main report | `C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-hw0-product-live-path-bringup-r1\V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md` |
| First blocker | `BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE` |

## Recommended next action

Owner-authorize one controlled warm reboot of `VCDE-DUT-1` in a new governed
hardware run so the accepted `0000:00:01.1 -> 0000:01:00.0` AHD path can be
re-enumerated and freshly verified before any MMIO or DMA action.
