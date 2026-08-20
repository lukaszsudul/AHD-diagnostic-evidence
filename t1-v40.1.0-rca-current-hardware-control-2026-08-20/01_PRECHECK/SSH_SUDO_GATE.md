# SSH and sudo automation gate

## Result

```text
SSH_OWNER_CONFIRMED_WORKING=YES
HOST_FINGERPRINT_GATE=PASS_EXACT_SEALED_ED25519_SHA256
SSH_AUTHENTICATED=NO
SSH_NONINTERACTIVE_AUTOMATION=FAIL
SSH_CONSECUTIVE_SUCCESSFUL_COMMANDS=0_OF_3
SUDO_WARM_REBOOT_PATH=NOT_TESTED_SSH_AUTHENTICATION_FAILED
SSH_AUTOMATION_GATE=FAIL
T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE_SSH
FPGA_PROGRAM_OPERATIONS=0
```

The ordinary approved Windows host context reached the correct server and the
presented ED25519 fingerprint exactly matched the sealed identity. Because
that Windows context did not already know the IP, the verified public host key
was recorded only in `known_hosts.task`; global SSH configuration was not
changed.

OpenSSH BatchMode authentication was rejected. The two existing approved AHD
keys were then selected explicitly, one at a time, with `IdentitiesOnly=yes`;
both were rejected with `Permission denied (publickey,password)`. No approved
non-interactive protected-password channel was available to the task, so the
required three successful commands and the non-mutating sudo reboot-path check
could not be completed.

Per the hard gate, the campaign stopped before JTAG discovery, FPGA
programming, host/BAR telemetry, RC-A hashing, or any reboot. No interactive
owner request or credential-recovery workaround was attempted.
