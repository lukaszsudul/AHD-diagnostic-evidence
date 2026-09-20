# AHD v41 CH3 R2R4 direct APPLY and first-frame attempt

## Outcome

| Gate | Result |
|---|---|
| Engineering | **BLOCKED** |
| User result | CH3 synchronization was not established; no frame or PNG was produced |
| Evidence publication | **PASS** in this append-only directory |
| Cleanup | **BLOCKED, locks preserved** |

The unchanged Candidate 2 runtime passed identity and safety admission on the R2R3 post-warm boot. The aggregate autoinit NACK counter was then read once as `0`. PREPARE was issued exactly once as the first functional operation. Its first completion-status validation failed with `R2_CH3L_V3_IDENTITY_MISMATCH`, so APPLY_A, SCAN1, PN B and C2H were not run.

## Admission

- Boot ID: `b1cc6fd6-2a07-48b7-8c5f-92c97b64248f`.
- AHD function: `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`.
- Candidate 2 bitstream SHA-256: `2FA12074A874E89EA758DC45BE836F099D192CD5A5FBA83C23FC2E79CE4C713A`.
- Entry scanner status: `0x00000011` (idle, autoinit done, no error or bank lockout).
- Entry loader status: `0xC3C00000` (v3 identity, virgin campaign, idle, clean terminal state).
- Stream was OFF, transport was quiescent, W3a was OFF, and no conflicting hardware lock or protected function was present.
- The qualified `xdma_ahd_pcie` module was loaded through the issued BDF-bound procedure. No driver source or configuration changed.
- Fresh `AUTOINIT_NACK_COUNT=0` came from one read of proven logical MMIO `0x00002114`; the counter was not cleared or reread.

## Campaign

| Item | Result |
|---|---|
| `PRE_FULL_SCANS` | `0` |
| PREPARE | `ISSUED_ONCE`; completion identity gate failed |
| APPLY_A | `NOT_RUN` |
| Fresh post-A scans | `0` |
| RECOVER / APPLY_B | `NOT_RUN` |
| Selected PN | `NONE` |
| Fresh F0/F2/F3/A8/NOVID | `NOT_MEASURED` |
| CH2 impact after PREPARE | `NOT_ESTABLISHED` |
| CH3 to VDO1 | `NOT_RUN` |
| C2H sessions / bytes / complete lines | `0 / 0 / 0` |
| Frame / PNG | `NOT_CREATED` |

## First actual blocker

`R2_CH3L_V3_IDENTITY_MISMATCH` occurred on the first loader-status validation after the single PREPARE write. The failure handler performed no APPLY_A, SCAN1 or capture. A later cleanup-only snapshot read eight relevant MMIO words once; all eight returned `0xFFFFFFFF`, so stream, scanner and loader quiescence could not be proven.

## Cleanup and containment

The first reserved cleanup connection found no XDMA descriptor holder and module refcount `0`, but retained both locks because every containment MMIO word was `0xFFFFFFFF`. The second and final reserved cleanup connection attempted one normal unload of the exact task-owned module. That connection reached its 180-second watchdog without a completion receipt, so the unload result and final module presence are unproven.

The remote DUT lock was present in the last completed cleanup receipt. The final containment script had no lock-release operation, and the local controller lock remains held. No reboot, programming, profile command, SCAN1, C2H, force-kill or power cycle was used for cleanup.

## Next executable action

Open a separate Owner-governed DUT recovery task that explicitly authorizes recovery of the inaccessible BAR and the possibly blocked module unload under the preserved locks, followed by a fresh baseline identity check. Do not resume R2R4 or repeat PREPARE from the current state.

Detailed NVP profile material, raw receipts, session identity, host extension source, firmware and pixel data are intentionally excluded.
