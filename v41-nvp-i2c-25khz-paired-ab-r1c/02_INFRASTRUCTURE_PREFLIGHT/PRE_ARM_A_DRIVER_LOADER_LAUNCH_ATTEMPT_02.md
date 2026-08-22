# Pre-Arm-A loader launcher attempt 02

```text
ATTEMPT_CLASSIFICATION=LOCAL_WINDOWS_POWERSHELL_RUNTIME_COMPATIBILITY_FAILURE_BEFORE_RECEIPT
INVALID_WRAPPER_SHA256=3D532F32FE62144D86743CAB8B31A907614B41723D363F6057E825CCF254357C
FAILURE=WINDOWS_POWERSHELL_5_1_DOTNET_FRAMEWORK_HAS_NO_CONVERT_TOHEXSTRING
LOCAL_ONE_SHOT_RECEIPT_CREATED=NO
CONTEXTUAL_PLINK_HELPER_ENTERED=NO
SSH_SESSION_STARTED=NO
REMOTE_LOADER_PAYLOAD_ENTERED=NO
DRIVER_LOADER_INVOCATION_CONSUMED_MARKER=NOT_EMITTED
OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS_AFTER_ATTEMPT=0
PROGRAM_INVOCATIONS=0
REBOOTS=0
HARDWARE_STATE_CHANGE=NO
```

The failed wrapper was preserved byte-for-byte as
`PRE_ARM_A_DRIVER_LOADER_WRAPPER_ATTEMPT_02_INVALID.ps1`. The compatibility
correction replaces `Convert.ToHexString` with the Windows PowerShell 5.1
compatible `BitConverter` representation and adds an offline-only identity
gate before the one-shot receipt boundary.

The corrected wrapper has SHA-256
`2FD17176A4847A526C073037A00107ED4C2A8810AEC5483071A0AD7CD0F1FDE0`.
Its exact Windows PowerShell 5.1 offline identity run passed with exit code 0;
the retained output is `EXACT_LOADER_WINDOWS_PS_OFFLINE_IDENTITY_GATE.log`.

This attempt did not consume an authorized loader invocation because execution
stopped during in-memory hash verification before receipt creation, helper
entry, SSH transport, or remote payload execution.
