# Pre-Arm-A loader launcher attempt 03

```text
ATTEMPT_CLASSIFICATION=LOCAL_ACCEPTED_HELPER_PARSE_FAILURE_AFTER_LOCAL_RECEIPT_BEFORE_HELPER_ENTRY
WRAPPER_SHA256=2FD17176A4847A526C073037A00107ED4C2A8810AEC5483071A0AD7CD0F1FDE0
ACCEPTED_HELPER_SHA256=8DB31E3C7FFF642EC4B2643A9C44317B5BC711558F0692C97335248BF154378D
FAILURE=WINDOWS_POWERSHELL_5_1_MISDECODED_NON_ASCII_LITERAL_INSIDE_ACCEPTED_HELPER
LOCAL_ONE_SHOT_RECEIPT_CREATED=YES
LOCAL_ONE_SHOT_RECEIPT_SHA256=EDA681B986183F8D7B761D489431541C2A19710FFFB419E63F696A9846F62D0F
CONTEXTUAL_PLINK_HELPER_ENTERED=NO
PLINK_PROCESS_STARTED=NO
SSH_SESSION_STARTED=NO
REMOTE_LOADER_PAYLOAD_ENTERED=NO
DRIVER_LOADER_INVOCATION_CONSUMED_MARKER=NOT_EMITTED
REMOTE_LOADER_INVOCATION_COUNT_AFTER_ATTEMPT=0
PROGRAM_INVOCATIONS=0
REBOOTS=0
HARDWARE_STATE_CHANGE=NO
CONSERVATIVE_LOCAL_RECEIPT_STATE=FROZEN_PENDING_INDEPENDENT_ACCOUNTING_REVIEW
```

The accepted credential helper parses with zero errors under the task's
PowerShell 7 execution environment but not under Windows PowerShell 5.1 because
its source contains a non-ASCII path literal without a Windows-PowerShell
encoding marker. The wrapper's own offline identity gate passed under Windows
PowerShell 5.1; failure occurred only when that process tried to parse the
accepted helper.

No evidence log was created because helper execution never began. The local
one-shot receipt is preserved and will not be deleted or overwritten. No
further loader action is permitted until an independent accounting decision
determines whether a separately sealed, non-destructive pre-transport recovery
is within the owner's loader-invocation definition.
