# R4 post-reboot tooling

These task-local tools were prepared for the bounded R4 bootstrap, Arm A, and
Arm B transitions. They were **not executed**. R4 reached a terminal hardware
hard stop during the consumed formal-bootstrap programming invocation before
any reboot or driver-load phase, so these tools are retained as static evidence
only and must not be run as part of R4.

## Intended sequence (not executed)

For each role (`FormalBootstrap`, `ArmA`, or `ArmB`), the intended bounded
sequence was:

1. Submit exactly one warm reboot with `Invoke-R4WarmRebootOnce.ps1`.
2. After independently observing host disappearance and return, invoke
   `Invoke-R4RemoteValidator.ps1 -Validator PreLoader` with the boot ID captured
   before reboot.
3. Invoke `Invoke-R4ExactPinnedLoaderOnce.ps1` exactly once.
4. Invoke `Invoke-R4RemoteValidator.ps1 -Validator PostLoader` with the same
   pre-reboot boot ID.

Example parameter form (documentation only):

```powershell
& .\Invoke-R4WarmRebootOnce.ps1 `
  -Role FormalBootstrap `
  -EvidencePath '<phase-directory>\REBOOT_SUBMIT.log'

& .\Invoke-R4RemoteValidator.ps1 `
  -Validator PreLoader `
  -Role FormalBootstrap `
  -PreviousBootId '<pre-reboot-UUID>' `
  -EvidencePath '<phase-directory>\POST_REBOOT_PRELOADER.log'

& .\Invoke-R4ExactPinnedLoaderOnce.ps1 `
  -Role FormalBootstrap `
  -EvidencePath '<phase-directory>\EXACT_DRIVER_LOAD.log'

& .\Invoke-R4RemoteValidator.ps1 `
  -Validator PostLoader `
  -Role FormalBootstrap `
  -PreviousBootId '<pre-reboot-UUID>' `
  -EvidencePath '<phase-directory>\POST_LOADER_VALIDATION.log'
```

## Safety properties

- The pre-loader validator is read-only and requires a changed boot ID, kernel
  `7.0.0-29-generic`, the single exact `0000:01:00.0` endpoint, Gen1 x1,
  131072/65536-byte BARs, an unbound endpoint, no loaded XDMA module, no XDMA
  nodes/owners, a fresh phase-specific loader-evidence directory, and clean
  targeted kernel/AER health.
- The loader wrapper has one exact loader invocation, no loop, no retry, and
  verifies the immutable module/loader hashes and an absent evidence directory
  before invocation.
- The post-loader validator is read-only and requires the exact module
  version/srcversion, exact binding, exact 21-node set, zero owners, exact BARs,
  accepted-reader identity, and role-specific FPGA runtime provenance.
- Formal roles require exact common identity, a zero/reserved R1e page, and
  diagnostic magic zero through the accepted reader. Arm A requires the exact
  R1e Git SHA, build flags `0x00000002`, and frozen R1e constants.
- The reboot wrapper contains one exact `/usr/sbin/reboot` command and no retry
  or polling loop. Boot-ID change is proven only by the separate validator.
- All network transport would have used the existing credential-safe helper,
  PuTTY `-pwfile`, pinned host key, `-batch`, `-noagent`, and `-noshare`.

## R4 terminal status

```text
POST_REBOOT_TOOLING_EXECUTED=NO
REASON=FORMAL_BOOTSTRAP_PROGRAM_CONSUMED_AND_FAILED_VENDOR_STARTUP_HIGH_GATE
REBOOT_OR_LOADER_AFTER_FAILURE_AUTHORIZED=NO
```
