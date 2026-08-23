# R5 host/safety/post-program tooling static audit

Scope: offline source/hash/AST checks only. No Plink, SSH, Vivado, JTAG, MMIO, reboot, loader, or hardware command was executed.

| Check | Result | Evidence |
|---|---|---|
| FROZEN_Invoke-ContextualPlink.ps1 | PASS | expected=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9;actual=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9 |
| FROZEN_parse_pci_bars.py | PASS | expected=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922;actual=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922 |
| FROZEN_read_nvp_r1e.py | PASS | expected=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037;actual=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037 |
| FROZEN_read_jtag_identity_done_strong.tcl | PASS | expected=CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD;actual=CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD |
| FROZEN_verify_runtime_identity.py | PASS | expected=84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C;actual=84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C |
| FROZEN_analyze_r4_telemetry.py | PASS | expected=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967;actual=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967 |
| FROZEN_program_once_startup_high_done.tcl | PASS | expected=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653;actual=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653 |
| FROZEN_ProgramObserverCommon.ps1 | PASS | expected=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66;actual=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66 |
| AST_Invoke-R5PostColdResetHostStability.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5PreBootstrapSafetyDiscovery.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5RemoteValidator.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5ExactPinnedLoaderOnce.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5WarmRebootOnce.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5IndependentDoneReadOnly.ps1 | PASS | parse_errors=0 |
| AST_Invoke-R5TelemetryReadOnly.ps1 | PASS | parse_errors=0 |
| AST_Wait-R5HostCycle.ps1 | PASS | parse_errors=0 |
| PYTHON_AST_FROZEN_TOOLS | PASS | PASS_NOT_RERUN: local Python runtime unavailable; byte-exact frozen passed tools gated above |
| NORMALIZED_R4_EQUAL_r5_post_reboot_preloader_readonly.sh | PASS | only R4/R5 task-label/root substitutions permitted |
| NORMALIZED_R4_EQUAL_r5_post_loader_readonly.sh | PASS | only R4/R5 task-label/root substitutions permitted |
| NORMALIZED_R4_EQUAL_Invoke-R5RemoteValidator.ps1 | PASS | only R4/R5 task-label/root substitutions permitted |
| NORMALIZED_R4_EQUAL_Invoke-R5ExactPinnedLoaderOnce.ps1 | PASS | only R4/R5 task-label/root substitutions permitted |
| NORMALIZED_R4_EQUAL_Invoke-R5WarmRebootOnce.ps1 | PASS | only R4/R5 task-label/root substitutions permitted |
| PREBOOTSTRAP_EXACT_FROZEN_DEPENDENCIES | PASS | Plink/helper/BAR-parser exact hashes embedded |
| PREBOOTSTRAP_ZERO_OR_ONE_ENDPOINT | PASS | 0 or 1 expected endpoint; absence explicitly accepted |
| PREBOOTSTRAP_FOREIGN_ENDPOINT_REJECTED | PASS | any non-10ee:7011 Xilinx function is rejected |
| PREBOOTSTRAP_DRIVER_AND_NODE_ABSENCE_ACCEPTED | PASS | exact pinned state or absence accepted; wrong same-name rejected |
| PREBOOTSTRAP_COLD_RESET_BASELINE_GATE | PASS | new R5 baseline must remain unchanged; no historical R4 continuity gate |
| PREBOOTSTRAP_IDENTITY_INFORMATIONAL_ONLY | PASS | optional current-image identity uses O_RDONLY/pread and is not an entry gate |
| PREBOOTSTRAP_NO_STATE_MUTATION | PASS | forbidden_matches=0 |
| POST_REBOOT_VALIDATORS_READ_ONLY | PASS | forbidden_matches=0 |
| PRELOADER_EXACT_STATE_GATES | PASS | new boot, endpoint/BAR geometry, unbound/no-module/no-node gates |
| POSTLOADER_ROLE_SPECIFIC_IDENTITY | PASS | formal and R1e role-specific provenance plus accepted-reader checks |
| EXACT_LOADER_SINGLE_INVOCATION_SITE | PASS | one contextual helper site, one remote exec-loader site, no retry loop |
| WARM_REBOOT_SINGLE_INVOCATION_SITE | PASS | one reboot command, one helper site, no retry loop |
| REMOTE_VALIDATOR_SINGLE_HELPER_SITE | PASS | one selected read-only validator per call |
| INDEPENDENT_DONE_READ_ONLY | PASS | program_commands=0; exact target/part/IDCODE/DONE checked by frozen Tcl |
| TELEMETRY_FROZEN_READER_HASH | PASS | exact frozen R1e reader hash embedded |
| TELEMETRY_TWO_SNAPSHOTS_READ_ONLY | PASS | ArmA expects r1e, ArmB expects formal, twice with 1-second delay |
| HOST_CYCLE_DOWN_THEN_UP | PASS | TCP/22 observer requires DOWN followed by UP |
| RUNBOOK_FULL_PHASE_ORDER | PASS | program, independent DONE, reboot/down-up, pre/post-loader validation, loader, telemetry |
| RUNBOOK_NO_INLINE_PASSWORD_OPTION | PASS | no executable PuTTY -pw form; frozen helper uses -pwfile |
| SELECTED_PROGRAM_SUPERVISOR_PRESENT_INFORMATIONAL | PASS | selected/current SHA256=F27D4FB38AB8E080D30F647BA87D8CFC87F2A35B14A4B125DB03F15DCD099A44; owned/audited separately by JTAG agent |

BASH_DYNAMIC_SYNTAX_CHECK=NOT_AVAILABLE_NO_LOCAL_BASH_OR_WSL_DISTRIBUTION
BASH_REVIEW_METHOD=FROZEN_R4_NORMALIZED_EQUALITY_PLUS_FORBIDDEN_OPERATION_AND_REQUIRED_GATE_SCAN
STATIC_CHECK_COUNT=42
STATIC_FAILURE_COUNT=0
LIVE_SSH_JTAG_VIVADO_MMIO_REBOOT_LOADER_ACTIONS=0
POST_PROGRAM_TOOLS_EXECUTED=NO_STATIC_PREPARATION_ONLY
R5_HOST_AND_PHASE_TOOLING_STATIC_GATE=PASS
