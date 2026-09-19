# AHD v41 CH3 R2R3 recovery, apply and first-frame continuation

## Outcome

| Gate | Result |
|---|---|
| Engineering | **BLOCKED** |
| User result | CH3 synchronization was not established; no frame or PNG was produced |
| Evidence publication | Prepared after hardware cleanup |
| Cleanup | **PASS** |

The exact Candidate 2 image was restored once in volatile SRAM and the one authorized warm reboot completed. The post-warm campaign did not start because its arm marker could not be created in the expected task runtime directory. The installed one-shot service therefore had an unsatisfied condition after reboot. The working SSH budget was already 3/3, so the cleanup reserve was kept measurement-free.

## Entry containment and recovery

- Entry scanner status: `0x00000C58`, with bank-context lockout and no active scan or bus ownership.
- Entry loader status: `0xC3C00000` (`CAMP_VIRGIN`, no terminal code).
- Transport was quiescent, with zero pending I/O and no C2H session.
- Existing same-task controller and DUT locks were validated and handed off.
- Exact Candidate 2 was programmed once to SRAM. No flash or configuration-memory write occurred.
- One warm reboot changed boot ID from `4402007f-bbf9-438a-a357-e89c5ea6c8f4` to `b1cc6fd6-2a07-48b7-8c5f-92c97b64248f`.
- No firmware build, RTL/XDC/DMA/driver change, XSim run, or protected-function takeover occurred.

## Camera campaign

| Item | Result |
|---|---|
| `PRE_FULL_SCANS` | `0` |
| PREPARE | `NOT_RUN` |
| APPLY_A | `NOT_RUN` |
| RECOVER / APPLY_B | `NOT_RUN` |
| Fresh post-profile scans | `0` |
| Maximum clean streak | `0` |
| Selected PN | `NONE` |
| Fresh CH3 synchronization | `NOT_ESTABLISHED` |
| CH2 impact | `NOT_MEASURED` |
| CH3 to VDO1 route | `NOT_RUN` |
| C2H sessions / bytes / complete lines | `0 / 0 / 0` |
| Frame / PNG | `NOT_CREATED` |

Candidate 2 exposes the aggregate autoinit NACK counter at logical MMIO `0x00002114`, mask `0x0000FFFF`. No post-warm MMIO campaign ran, so `AUTOINIT_NACK_COUNT=NOT_PROVEN_FRESH`; no numeric value is claimed.

## First actual blocker

`POSTWARM_AUTORUN_ARM_MARKER_CREATION_FAILED`: the staging shell attempted to create `runtime/postwarm.armed` before that task-local directory existed. The shell continued, installed the service and scheduled the authorized reboot. After reboot, systemd reported the service inactive with `ConditionResult=no`, and none of the autorun start or completion markers existed.

## Cleanup

Cleanup used only its reserved access and started zero profile commands, scans, captures, MMIO reads, or MMIO writes. It verified the new boot, an unbound AHD BDF, no XDMA module or device nodes, no open holders, and no DUT lock. The inactive task-owned service and remote session token were removed. Controller locks were archived and released last.

Detailed NVP profiles, private reference material, raw sideband, host source, firmware, session tokens and pixel data are intentionally excluded.
