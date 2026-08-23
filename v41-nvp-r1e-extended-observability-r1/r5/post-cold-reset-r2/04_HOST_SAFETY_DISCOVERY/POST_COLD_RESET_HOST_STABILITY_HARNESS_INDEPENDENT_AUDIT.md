# Independent offline audit — post-cold-reset host-stability harness

Audit scope was limited to static inspection of:

- `scripts/Invoke-R5PostColdResetHostStability.ps1`
- `scripts/r5_post_cold_reset_host_sample_readonly.sh`
- the exact frozen `scripts/Invoke-ContextualPlink.ps1`
- the locally installed Plink executable

No SSH, network, JTAG, Vivado, DUT, or hardware action occurred.

```text
SUPERVISOR_SHA256=80C5CC71EB0692CCF96E07B51B23F6DAAB6529434B7D82CFE27131DDFA6BD5CE
REMOTE_SAMPLE_PAYLOAD_SHA256=54A3BA93BE696C7BEDD5B3621AA60B057359F528E45773EE383E18948550FEBE
CONTEXTUAL_PLINK_HELPER_SHA256=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9
CONTEXTUAL_PLINK_HELPER_HASH_GATE=PASS
PLINK_VERSION=0.84
PLINK_SIZE_BYTES=1043072
PLINK_SHA256=E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915
PLINK_HASH_GATE=PASS

POWERSHELL_PARSE_ERRORS=0
FIXED_INDEPENDENT_SSH_SESSION_COUNT=3
ONE_HELPER_CALL_SITE_INSIDE_FIXED_1_TO_3_LOOP=YES
PLINK_BATCH_MODE=YES
PLINK_PWFILE_MODE=YES
PLINK_HOSTKEY_PINNED=YES
PLINK_AGENT_DISABLED=YES
PLINK_CONNECTION_SHARING_DISABLED=YES
PLINK_LITERAL_PASSWORD_OPTION_USED=NO

SESSION_EVIDENCE_PATHS_DISTINCT=YES
ALL_SESSION_AND_AGGREGATE_OUTPUTS_MUST_BE_FRESH=YES
OVERWRITE_REFUSAL_BEFORE_FIRST_SESSION=YES
SESSION_2_SCHEDULED_FROM_SESSION_1_COMPLETION_SECONDS=2.625
SESSION_3_SCHEDULED_FROM_SESSION_1_COMPLETION_SECONDS=5.250
REMOTE_UPTIME_SPAN_MINIMUM_SECONDS=5.000
LOCAL_MONOTONIC_SPAN_MINIMUM_SECONDS=5.000

REMOTE_EXPECTED_USER=vcdeagent1
REMOTE_EXPECTED_KERNEL=7.0.0-29-generic
SAME_HOSTNAME_REQUIRED_ACROSS_ALL_SESSIONS=YES
SAME_BOOT_ID_REQUIRED_ACROSS_ALL_SESSIONS=YES
BOOT_ID_FORMAT_GATE=YES
STRICTLY_INCREASING_UPTIME_REQUIRED=YES
REMOTE_UPTIME_SPAN_GATE=YES
LOCAL_STOPWATCH_SPAN_GATE=YES

REMOTE_SUDO_COMMAND_COUNT=0
REMOTE_MUTATION_COMMAND_COUNT=0
REMOTE_WRITE_REDIRECTION_COUNT=0
REMOTE_PAYLOAD_PERSISTED_ON_DUT=NO_STREAMED_TO_BASH_STDIN
REMOTE_SAMPLE_READS=HOSTNAME_USER_KERNEL_BOOT_ID_UPTIME_UTC_ONLY

POST_COLD_RESET_HOST_STABILITY_HARNESS_INDEPENDENT_AUDIT=PASS
```

The supervisor makes three separate calls to the exact contextual Plink helper.
That helper starts one Plink process per call with `-batch`, `-pwfile`, pinned
`-hostkey`, `-noagent`, and `-noshare`. The three result logs use distinct
paths, and the supervisor refuses to start if any session, matrix, or gate
output already exists.

The remote sample is non-privileged and read-only. It runs only `hostname`,
`id -un`, `uname -r`, reads `/proc/sys/kernel/random/boot_id` and
`/proc/uptime`, and reads UTC. It contains no `sudo`, persistent file creation,
driver command, reboot, shutdown, PCIe action, MMIO, or other remote mutation.

Passing live evidence still requires all three independent calls to succeed,
the exact kernel in every sample, one identical valid boot ID, strictly
increasing uptime, and both remote-uptime and local-monotonic spans of at least
the configured five seconds.
