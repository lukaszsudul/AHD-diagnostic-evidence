# AHD v41 CH3 R2R5 PCIe/BAR incident review

## Required answers

1. **Fresh AHD/PCIe/BAR access:** the AHD endpoint answered one bounded 40-byte config-space read as `10ee:7011`, subsystem `10ee:0007`. The current link metadata is 5.0 GT/s x1. BAR0 and BAR1 remain assigned, but BAR/MMIO content was **not retested** because the qualified driver and all XDMA nodes are absent; the driver was not reloaded.
2. **Old unload and owned resources:** the R2R4 unload completion result was never retained. The current kernel is a different boot, the old process is absent, and there is no `xdma_ahd_pcie` module, driver binding, XDMA node, descriptor holder or mapping. Current host resources are closed. No new unload was attempted.
3. **First identity mismatch read:** the first raw word after PREPARE and the later word that triggered the identity exception are both `NOT_RETAINED`. Control flow proves each host read returned four bytes without a delivered errno. The identity gate was correct: `(raw & 0xFFC00000) == 0xC3C00000`. The first retained `0xFFFFFFFF` values are eight later cleanup reads and cannot be assigned to the earlier mismatch.

## Outcome

| Field | Result |
|---|---|
| Engineering gate | **PASS — scoped incident review and current host closeout** |
| PCI config access | **AVAILABLE**, one read only |
| BAR access | **NOT_RETESTED_NO_DRIVER** |
| R2R4 unload receipt | **NOT_RETAINED** |
| Current host resources | **CLOSED** |
| DUT/controller locks | **PRESERVED** because their receipts are bound to the prior boot |
| Camera campaign | **HARD STOP**; no PREPARE, scanner or capture |
| Evidence publication | **PASS** in this append-only directory |

## First-read reconstruction

The executed adapter wrote PREPARE at `r2_fixed_loader_backend.py:223`. It read status at line 225, then replaced that local value with another read at line 227 before checking identity at line 228. No command receipt existed yet, so neither raw word nor UTC/monotonic time was persisted. `VerifiedMmioDevice.read32()` used `pread(fd, 4, 0x12400)` on `/dev/xdma0_user`, rejected short reads before decoding, and reached the loader identity exception rather than an OS or short-read exception.

The pinned RTL at commit `d8dc9592037ca73e2321b30fd1f65a2a3f8b92e7` fixes status bits `[31:24]` to `0xC3` and `[23:22]` to `3`. Lower status fields are dynamic. The host decoder implements the same rule; it does not require the complete virgin word after PREPARE. An offline check also confirmed that `0xFFFFFFFF` fails this identity gate.

Cleanup1 later performed eight direct four-byte reads with no fallback value and persisted `0xFFFFFFFF` for all eight. The exact earlier mismatch remains unknown, and no causal layer is proven.

## Boot transition and present PCIe state

R2R4 cleanup2 began at `2026-09-20T07:54:12.2624227Z`. The current kernel enumerated `0000:01:00.0` at `2026-09-20T07:54:40.738599Z`, inside the later 180-second connection-watchdog window. R2R5 observed boot `a7398b07-9452-4b60-ada1-46ca76ad3819`, replacing R2R4 boot `b1cc6fd6-2a07-48b7-8c5f-92c97b64248f`. This proves a boot transition in that interval; it does not prove that `rmmod`, PREPARE or any specific fault caused it.

The fresh config read returned command `0x0000`, status `0x0010`, BAR0 `0xF6E00000` and BAR1 `0xF6E20000`. Sysfs metadata assigned 128 KiB and 64 KiB apertures respectively. Memory-space and bus-master enables are currently clear. No protected `10ee:7021 / 10ee:f0a1` function was present in the current topology survey.

The bounded current-boot kernel log contained normal AHD enumeration and no matching AER, DPC, hung-task, fatal, timeout or XDMA-driver event. It cannot explain the prior-boot failure.

## Locks and containment

The remote lock receipt and local controller receipt both match the preserved R2R4 session, but both name the old boot. The remote acquisition PID is absent and no matching local controller process exists. The established release chain requires boot continuity, so neither lock was deleted. The handoff prohibits a new hardware campaign, PREPARE replay, scanner operation and capture.

No reset or restart is justified by the present evidence: PCI config access works and current host resources are already closed. The next action is an Owner-governed stale-lock handoff or release bound to the observed boot transition. A future BAR boundary test would additionally require separate authority for one exact qualified-driver load.

## Future single boundary-test plan

Before any future command, persist the raw global identity, loader status, byte count, errno, UTC, monotonic timestamp, boot, BDF, driver identity and stream/master state. Persist every post-command raw word before decoding it. Reject OS errors, short reads and all-ones before field interpretation; check loader identity with mask `0xFFC00000`; stop at the first transport error or identity failure. This is a plan only. R2R5 issued no PREPARE.

Private logs, process stacks, command source, session identity and raw profile material are excluded. Their hashes are included in the public JSON summaries.