# R7 host-baseline tooling static audit

```text
HOST_BASELINE_TOOLING_STATIC_AUDIT=PASS
HOST_BASELINE_TOOL=PREPARED_NOT_EXECUTED
LIVE_SSH_EXECUTED_BY_THIS_AUDIT=0
```

The bounded supervisor performs exactly two independent privileged-but-read-only
SSH sessions. It waits at least `MinimumSpanSeconds + 0.250` after completion
of session 1 before session 2, with `MinimumSpanSeconds` constrained to
3.0–30.0 seconds and defaulting to 3.0 seconds. Both remote uptime span and
local monotonic span must be at least the selected minimum.

The gate requires stable hostname/user, kernel `7.0.0-29-generic`, one boot ID,
strictly increasing uptime, and a read-only proof that the next boot selects
kernel 29. The payload contains no reboot, shutdown, GRUB write, module,
PCIe-reset/rescan, MMIO-write, or DMA command.

```text
Invoke-R7HostBaseline.ps1_SHA256=A125FD20FF632199167DA795940C08A79D25B6B2AFEB4F18D79238B203F46444
r7_host_baseline_sample_readonly.sh_SHA256=0C49C3FB9192E40F53285844343BAA7AC6EE1801798C62627A6C45EAC718D730
Invoke-ContextualPlink.ps1_SHA256=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9
POWERSHELL_PARSE=PASS
SESSION_COUNT=2
MINIMUM_SPAN_SECONDS=3.000000
EXPECTED_GATE=R7_HOST_BASELINE_PASS_2_OF_2
INLINE_PASSWORD_OPTION=ABSENT
PWFILE_HELPER=PINNED
```
