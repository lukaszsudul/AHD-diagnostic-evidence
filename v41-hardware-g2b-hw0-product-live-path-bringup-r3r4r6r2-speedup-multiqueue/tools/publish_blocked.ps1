$ErrorActionPreference='Stop'
$r=Split-Path $PSScriptRoot -Parent
$d=Join-Path $r 'evidence-staging'
$p='G2B_HW0_PRODUCT_R3R4R6R2_'
$utf=[Text.UTF8Encoding]::new($false)
function Put($name,$body){[IO.File]::WriteAllText((Join-Path $d $name),$body.Replace("`r`n","`n")+"`n",$utf)}
function Report($name,$body){Put ($p+$name+'.md') ("# G2B-HW0-PRODUCT-R3R4R6R2 — $name`n`n"+$body)}
$blocker='R3R4R6R2_RECOVERY_DUT_RECONNECT_TIMEOUT_AFTER_AUTHORIZED_WARM_REBOOT'
New-Item -ItemType Directory -Path "$d\tools","$d\raw" -Force|Out-Null
Put '.gitattributes' '* -text'
foreach($f in Get-ChildItem "$r\scripts" -File){Copy-Item -LiteralPath $f.FullName -Destination "$d\tools\$($f.Name)"}
$connections=@(Get-ChildItem "$r\logs\connection-*.json")
foreach($f in $connections){
 $v=Get-Content -Raw $f.FullName|ConvertFrom-Json
 if(-not $v.temporary_deleted -or $v.credential_temp_remaining -ne 0){throw 'CREDENTIAL_REMNANTS'}
 Copy-Item $f.FullName "$d\raw\$($f.Name)"
}
$sourceHash=(Get-FileHash "$r\scripts\xdma_st_c2h_multiqueue.c").Hash
$helperHash=(Get-FileHash "$r\scripts\Invoke-R3R4R6R2DutConnection.ps1").Hash
Report 'OWNER_CONTINUITY_ATTESTATION' @'
PROJECT_STATE_REV=8 — OWNER_ATTESTED_NOT_REVERIFIED. Owner-confirmed unchanged environment ACCEPTED.
VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111; boot614295f4-c62b-4430-ae67-06013bea7084; endpoint0000:01:00.0,10ee:7011 /10ee:0007,Gen2x1; PRODUCT SHA AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7 retained in SRAM.
Accepted original module xdma_ahd_pcie loaded,refcount1,/dev/xdma0_user and /dev/xdma0_c2h_0; PID25287 waiting in old AIO; stream disabled and physically quiescent; epoch4;ERROR_STATUS0x7;LAST_ERROR_CAUSE0x3; predecessor locks held.
Driver SHA E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77. Exact accepted path /home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko. Frozen ABI AHD_C2H_TRANSPORT_ABI_V1.
Predecessor16972c27a132ef1963d9f46b59e2feeaff349e82 in v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r6r1-prequeued-finite. No predecessor/repository/hash/boot/JTAG/PCIe qualification repeated.
Accepted historical PREQUEUE_CAPACITY_EFFECT=CONFIRMED_STRONG; approximately52.1x drop-rate reduction (31.76% to0.61%). HOST_FPGA_BYTE_ACCOUNTING=PASS_EXACT:643072+24576=667648. Partial-byte symptom ABSENT; partial bytes0. The unreaped24576 bytes are not classified as corrupt FPGA data. SINGLE_OVERSIZED_AIO_REQUEST_CONTRACT_FAILED remains the accepted predecessor blocker; internal mechanism unproven.
'@
Report 'SPEEDUP_AUTHORIZATION' @"
One combined run; no separate recovery/characterization/finite task. Fresh root $r.
Every DUT invocation uses new task-local credential helper, SHA256 $helperHash. Syntax/IP/no-secret-argument checks PASS. Credential remnants0 after all completed invocations. No historical hashes or broad inventories run.
One SIGTERM to exact PID25287 after cmdline safety identity; wait12s; conditional one graceful warm reboot. No SIGKILL, forced unload, manual unbind, second reboot, power-cycle or FPGA programming.
Planned writes only CONTROL0x380C={4,1,0}, combined immediately observed ERROR_STATUS&0x3F once/session, snapshot0x3844=1. No statistics clear. Actual MMIO writes0, new insmod0, probes0, finite sessions0.
PRIOR_RUN_DIRECTORIES_MODIFIED_BY_R3R4R6R2=NO. Only exact predecessor lock resolution was inspected for authorized cleanup; no historical directory scan or evidence verification.
"@
Report 'PENDING_AIO_RECOVERY' @"
Recovery BLOCKED. First operational blocker: $blocker.
PID25287 cmdline matched prequeued_c2h_capture and exact /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r6r1/20260907T202452Z path. Exactly one SIGTERM issued. Old pending state remained after12s; normal rmmod was not attempted with outstanding state.
Method selected ONE_GRACEFUL_WARM_REBOOT. Exactly one systemctl reboot command dispatched; connection closed at2026-09-08T06:21:50.9076393Z. This proves dispatch, not reboot completion. Subsequent task-helper reconnect attempts timed out; their exact times and results are in raw connection receipts.
No boot-ID read/comparison. No additional signal/reboot/power-cycle. Old helper exit, descriptor release, module removal and node disappearance could not be confirmed. Old Linux/controller locks were not removed because recovery completion was unproven. No R3R4R6R2 operational locks acquired.
No root cause is assigned to the lost connection; a stuck reboot versus unavailable host cannot be distinguished from these results. Further mutation requires Owner intervention.
"@
Report 'NATIVE_HELPER_BUILD' @"
NOT_REACHED: DUT-local GCC unavailable through the required connection. Source was prepared locally while waiting for reconnect; it was not uploaded, compiled, smoke-tested or executed.
Native helper source: tools/xdma_st_c2h_multiqueue.c. SHA256 $sourceHash.
Binary SHA256 NONE. Speed-up host-tool gate0/7 (not executed; no failed compile claim). No compile-portability correction used.
The source implements planned raw-AIO probe/finite modes, individual aligned buffers, prequeue acceptance, metadata-only events and private persistence. It is UNQUALIFIED source, not a demonstrated hardware tool.
Parent MMIO controller, integrity/continuity validator and frame reconstruction tool were NOT_CREATED because recovery blocked before Phase B could complete. No placeholder implementation is presented as a finished tool.
"@
Put ($p+'SINGLE_REQUEST_CHARACTERIZATION.csv') "RequestedBytes,RequestedRecords,ReturnedBytes,CompleteRecords,PartialBytes,AioResult,LatencyNs,StreamedDelta,BeatsDelta,DroppedDelta,OverflowDelta,Disable,Cleanup,Result`n4096,1,,,,,,,,,,,,NOT_RUN`n65536,16,,,,,,,,,,,,NOT_RUN`n262144,64,,,,,,,,,,,,NOT_RUN`n524288,128,,,,,,,,,,,,NOT_RUN`n1048576,256,,,,,,,,,,,,NOT_RUN`n2097152,512,,,,,,,,,,,,NOT_RUN`n4194304,1024,,,,,,,,,,,,NOT_RUN"
Report 'TRANSFER_SIZE_DECISION' 'NOT_REACHED. Seven probes requested,zero executed. No maximum working request,first larger short request,curve or operating size measured. Do not infer a driver/descriptor/TLAST limit from predecessor byte counts. Historical oversized-request failure does not negate confirmed prequeue capacity benefit.'
Report 'PREQUEUE_PLAN' 'NOT_EXECUTED. Target primary10240000 bytes/2500 records;guard4194304 bytes/1024 records;total14434304. Operating size remains N/A. Authorized selection priority524288,262144,65536,4096 based on exact full probe completion. Remainder must be4096-byte requests. No requests submitted.'
Report 'PREQUEUE_RECEIPT' 'NOT_REACHED. No native process,io_setup,io_submit,PREQUEUE_READY,enable or finite request. No latency measurement.'
Put ($p+'AIO_SUBMISSIONS.csv') 'Class,Index,TargetOffset,Requested,AioData,AcceptedNs'
Put ($p+'AIO_COMPLETIONS.csv') 'Class,Index,Offset,Requested,Result,Result2,CompletionOrder,MonotonicNs'
Report 'FLAG_PREDICTION' @'
RECORDED_BEFORE_RUN. No new capture has been executed.
First primary: VALID1,DISCONTINUITY0or1,OVERFLOW_OCCURRED0,MALFORMED_PRECEDING0.
Remaining primary: VALID1,DISCONTINUITY0 after allowed initial transition,OVERFLOW_OCCURRED0,MALFORMED_PRECEDING0.
Qualified frame start: integrityPASS,SOF1,line0,VALID1,DISCONTINUITY0,OVERFLOW_OCCURRED0,MALFORMED_PRECEDING0. Same epoch/frame,lines0..1079,3840-byte payload each,all clean.
Prediction has no post-data revision because no data exists.
'@
Report 'FLAG_PREDICTION_COMPARISON' 'First-record,post-first-record and clean-frame predictions NOT_REACHED. No observation versus prediction comparison possible.'
Put ($p+'COUNTER_CHECKPOINTS.csv') 'Checkpoint,Epoch,ErrorStatus,LastErrorCause,Attempted,Committed,Streamed,Dropped,Overflow,Discontinuity,Beats,Abandoned,LastGlobal,LastAttempt'
Put ($p+'MMIO_WRITE_LEDGER.csv') 'Timestamp,Session,Node,BDF,Offset,Value,Purpose,Authorized,Precondition,Result'
Report 'FIRST_RECORD_REPORT' 'NOT_REACHED. First-record integrity and continuity unmeasured. No first-record/payload hashes. Accepted predecessor transition metadata is not reclassified as an integrity failure.'
Put ($p+'FIRST_RECORD_HEADER.csv') 'Field,Value,Status'
$recordHeader='RecordIndex,RequestId,OffsetWithinRequest,Integrity,Flags,Epoch,Frame,Line,CaptureSequence,AttemptSequence,GlobalSequence,SourceMalformedSnapshot,SourceDroppedSnapshot'
Put ($p+'PRIMARY_RECORD_METRICS.csv') $recordHeader
Put ($p+'GUARD_RECORD_METRICS.csv') $recordHeader
Put ($p+'STREAM_CONTINUITY_METRICS.csv') 'Window,DiscontinuityRecords,OverflowRecords,MalformedPrecedingRecords,GlobalGaps,AttemptGaps,SourceProgressionBreaks,Status'
Put ($p+'MALFORMED_PRECEDING_TIMELINE.csv') 'RecordIndex,Window,RequestId,Epoch,Frame,Line,Flags,SourceMalformedSnapshot,SourceDroppedSnapshot,GlobalSequence,AttemptSequence,BeforeFirstCleanSOF,InsideQualifiedFrame'
Report 'WINDOW_CLASSIFICATION' 'PRIMARY,GUARD and POST_TARGET_SHUTDOWN_TAIL: NOT_REACHED. No new records or counters. Record integrity,stream continuity,BT656 source qualification and host AIO remain separate unmeasured categories; no generic malformed-count substitution.'
Report 'FRAME_RECONSTRUCTION_REPORT' 'NOT_REACHED. No primary video,guard video,UYVY frame or PNG exists. Target1920x1080 UYVY/4147200 bytes not achieved. All hashes NONE. No raw camera bytes published.'
Report 'PCIE_AER_KERNEL_REVIEW' 'NOT_REACHED. No broad or final environment/kernel requalification performed. Recovery connection timeout is an operational blocker,not proof of PCIe,AER,kernel or FPGA fault. No fresh hardware-health PASS claimed.'
Report 'CLEANUP_RECEIPT' 'Recovery completion unresolved. New native helper never executed; no new AIO or MMIO descriptor opened; no new module loaded. Old pending-AIO state after reboot remains UNRESOLVED because reconnect failed. Normal rmmod0; forced rmmod0; SIGKILL0; SIGTERM1; graceful reboot command1. Old locks retained,not declared released. All local temporary credential files removed. No new hardware action scheduled or running locally.'
Report 'FINAL_STATE' 'Engineering BLOCKED. PROJECT_STATE_REV8 Owner-attested,not reread. Candidate retention accepted from Owner plus no task reprogramming; not freshly verified. Stream-disabled/physical-quiescence starting state accepted; final physical quiescence NOT_REACHED. Old helper/module/nodes/locks removal not proven. Hardware accessed YES (targeted process recovery/reboot); FPGA programming/Flash/power-cycle NO. New driver load NOT_REACHED. Prior run directories modified by task NO. Stop without another reboot or capture.'
Put ($p+'GATE_MATRIX.csv') "Gate,Result,Reason`nOwnerContinuity,ACCEPTED,No requalification`nSignalSafety,PASS,Exact PID cmdline match`nRecovery,BLOCKED,$blocker`nNativeBuild,NOT_REACHED,Required DUT connection unavailable`nHostToolGate,0_OF_7,Not executed`nCharacterization,NOT_REACHED,Recovery incomplete`nMultiRequestPrequeue,NOT_REACHED,No submission`nPrimaryFiniteCapture,NOT_REACHED,No capture`nRecordIntegrity,NOT_REACHED,No records`nBT656Qualification,NOT_REACHED,No records`nCompleteFrame,NOT_REACHED,No frame`nNormalCleanup,NOT_REACHED,Recovery unresolved`nHistoricalPrequeueEffect,CONFIRMED_STRONG,Accepted Owner decision"
$state=[ordered]@{task='G2B-HW0-PRODUCT-R3R4R6R2';engineering='BLOCKED';overall='BLOCKED';first_blocker=$blocker;project_state_revision=8;state_authority='OWNER_ATTESTED_NOT_REVERIFIED';environment_prechecks='SKIPPED_BY_OWNER_DECISION';root=$r;recovery='BLOCKED';recovery_method_selected='ONE_GRACEFUL_WARM_REBOOT';recovery_pid_identity='VERIFIED_FOR_SIGNAL_SAFETY';sigterm_count=1;warm_reboot_commands=1;warm_reboot_completion='UNRESOLVED';rmmod_attempts=0;old_locks_released=$false;native_source_sha256=$sourceHash;native_binary_sha256=$null;host_tool_gate_passed=0;driver_load='NOT_REACHED';probes_requested=7;probes_completed=0;finite_capture='NOT_REACHED';mmio_writes=0;new_aio_submissions=0;pending_old_aio_final='UNRESOLVED';prequeue_capacity_effect='CONFIRMED_STRONG';historical_drop_rate_improvement='APPROXIMATELY_52_1X';historical_byte_accounting='PASS_EXACT';historical_partial_bytes=0;first_record_integrity='NOT_REACHED';bt656_qualification='NOT_REACHED';complete_frame='NOT_REACHED';hardware_subqualification='NOT_PROVEN';prior_run_directories_modified=$false;credential_remnants=0;evidence_publication='SEALED_PENDING_ONE_COMMIT_PINNED_READBACK';recommended_next_step='Owner to restore DUT SSH availability and explicitly authorize continuation from the unresolved graceful-reboot recovery state; do not repeat reboot or capture.'}
Put ($p+'STATE.json') ($state|ConvertTo-Json -Depth 5)
Put 'V41_G2B_HW0_PRODUCT_R3R4R6R2_MAIN_REPORT.md' @"
# AHD v41 G2B-HW0-PRODUCT-R3R4R6R2 Speed-Up Plus

Engineering BLOCKED. Overall BLOCKED. First blocker: $blocker.

The Owner-confirmed environment and historical prequeue conclusions were accepted without requalification. Exact PID25287 signal-safety identity passed. One SIGTERM did not release the pending old AIO in12 seconds. The authorized single graceful warm-reboot command was issued,then the connection closed. Bounded reconnect attempts through the fresh helper timed out. Reboot completion and old-state cleanup could not be established. No second reboot,power-cycle,FPGA operation or capture retry was attempted.

Old locks remain unreleased because recovery is unproven. The combined native C source was prepared locally but not compiled or run. Host-tool gate0/7 NOT_EXECUTED. Driver load,all seven probes,multi-request prequeue,2500-record validation and frame reconstruction NOT_REACHED. No MMIO writes or new AIO requests. No measured size curve or new causal mechanism is asserted.

Historical PREQUEUE_CAPACITY_EFFECT=CONFIRMED_STRONG;drop-rate improvement approximately52.1x. Accepted byte accounting643072+24576=667648 remains PASS_EXACT;partial bytes0. The old unreaped bytes are not classified as corrupt video. The unresolved old oversized-request contract must not be confused with failure of prequeue as a concept.

Fresh root: $r. Every DUT connection used the new helper. Credentials removed;no raw camera data exists or is published. Prior run directories modified by task NO. Environment prechecks SKIPPED_BY_OWNER_DECISION.

Evidence publication is independent of engineering. This package records only reached operations and explicit NOT_REACHED outcomes. Commit-pinned readback is performed once after push,with the transaction receipt outside the immutable commit in the fresh root.

Required next action: Owner restore DUT SSH availability and authorize continuation from the unresolved graceful-reboot recovery state. No additional reboot is assumed authorized.
"@
$files=Get-ChildItem $d -Recurse -File|Sort-Object FullName
Report 'EVIDENCE_INDEX' (("Relative paths. Native C source is uncompiled/unqualified; parent/validator/frame tools were not created. No binaries or camera bytes.`n`n")+(($files|ForEach-Object {'- '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/')})-join "`n"))
$manifest=Get-ChildItem $d -Recurse -File|Where-Object Name -ne ($p+'SHA256_MANIFEST.txt')|Sort-Object FullName|ForEach-Object {(Get-FileHash $_.FullName).Hash+'  '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/')}
Put ($p+'SHA256_MANIFEST.txt') ($manifest-join "`n")
"STAGING_FILES=$(@(Get-ChildItem $d -File -Recurse).Count)"
