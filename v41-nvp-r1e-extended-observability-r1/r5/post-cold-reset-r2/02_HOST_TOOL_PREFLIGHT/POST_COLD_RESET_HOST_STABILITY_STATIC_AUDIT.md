# R5 post-cold-reset host-stability tooling static audit

This audit is static only. It did not start Plink, SSH, Vivado, JTAG, MMIO, a reboot, or a driver operation.

WRAPPER_SHA256=80C5CC71EB0692CCF96E07B51B23F6DAAB6529434B7D82CFE27131DDFA6BD5CE
PAYLOAD_SHA256=54A3BA93BE696C7BEDD5B3621AA60B057359F528E45773EE383E18948550FEBE
FROZEN_HELPER_SHA256=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9

| Check | Result | Evidence |
|---|---|---|
| POWERSHELL_AST | PASS | parse_errors=0 |
| TASK_ROOT_EXACT | PASS | C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5 |
| FROZEN_HELPER_HASH_LITERAL | PASS | 5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9 |
| FROZEN_PLINK_HASH_LITERAL | PASS | E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915 |
| THREE_SESSION_LOOP | PASS | one loop, bounds 1..3 |
| ONE_HELPER_SITE_INSIDE_LOOP | PASS | one helper invocation site executed by the 1..3 loop |
| THREE_DISTINCT_EVIDENCE_PATHS | PASS | session index is embedded in each evidence filename |
| FIVE_SECOND_SCHEDULING | PASS | sessions 2/3 scheduled from session-1 completion at 2.625/5.250 seconds |
| REMOTE_SPAN_GATE | PASS | third minus first remote uptime must be >=5 seconds |
| LOCAL_SPAN_GATE | PASS | local monotonic span must be >=5 seconds |
| BOOT_ID_STABILITY_GATE | PASS | all three UUID boot IDs compared ordinally |
| UPTIME_STRICTLY_MONOTONIC | PASS | uptime2 > uptime1 and uptime3 > uptime2 |
| KERNEL_EXACT_29_ALL_SESSIONS | PASS | kernel 7.0.0-29-generic checked in every record |
| HOST_USER_STABILITY | PASS | hostname stable and exact remote user required |
| PASS_CLASSIFICATION | PASS | required baseline and PASS_3_OF_3 output fields |
| FRESH_EVIDENCE_ONLY | PASS | wrapper refuses every pre-existing session/matrix/gate output |
| NONPRIVILEGED_REMOTE_COMMAND | PASS | no sudo or sudo-password stdin in host-stability wrapper |
| PAYLOAD_STRICT_READ_ONLY | PASS | payload uses only read-only/nonprivileged host observations |
| SAMPLE_INDEX_EXACT | PASS | payload accepts exactly sample indices 1,2,3 |

STATIC_CHECK_COUNT=19
STATIC_FAILURE_COUNT=0
LIVE_SSH_SESSIONS_EXECUTED_BY_AUDIT=0
HARDWARE_OR_NETWORK_ACTIONS_EXECUTED_BY_AUDIT=0
POST_COLD_RESET_HOST_STABILITY_TOOLING_STATIC_GATE=PASS
