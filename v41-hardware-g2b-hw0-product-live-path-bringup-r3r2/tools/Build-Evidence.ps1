$ErrorActionPreference='Stop'
$r=Split-Path $PSScriptRoot -Parent
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$d=Join-Path $repo 'v41-hardware-g2b-hw0-product-live-path-bringup-r3r2'
if((Test-Path $d) -and @(Get-ChildItem $d -Recurse -File).Count){throw 'NEW_EVIDENCE_DIRECTORY_ALREADY_EXISTS'}
New-Item -ItemType Directory -Path $d,(Join-Path $d 'tools'),(Join-Path $d 'raw') -Force | Out-Null
$prefix='G2B_HW0_PRODUCT_R3R2_'
$utf=[Text.UTF8Encoding]::new($false)
function Put([string]$name,[string]$body){[IO.File]::WriteAllText((Join-Path $d $name),$body.Replace("`r`n","`n")+"`n",$utf)}
function Report([string]$name,[string]$body){Put ($prefix+$name+'.md') ("# G2B-HW0-PRODUCT-R3R2 — $name`n`n"+$body)}
$blocker='R3R2_DUT_BOOT_CHANGED_EXCLUSIVITY_LOST'
$stop='BLOCKED — '+$blocker
$conn=@(Get-ChildItem "$r\logs\connection-*.json" | ForEach-Object {Get-Content -Raw $_.FullName | ConvertFrom-Json})
if(@($conn | Where-Object { -not $_.temporary_deleted -or $_.private_remaining -ne 0 -or $_.helper_sha256 -cne '7E263395A3CB8523FAC2232B456885C171D7D231AE458DCDCC4C7A3505BBD46F'}).Count){throw 'CONNECTION_AUDIT_FAIL'}
if(@(Get-ChildItem "$r\private" -Force).Count){throw 'CREDENTIAL_REMNANTS'}
$state=Get-Content -Raw "$repo\project-current-state\PROJECT_STATE.json" | ConvertFrom-Json
if($state.project_state_revision -ne 8){throw 'SSOT_REV_DRIFT'}
Put '.gitattributes' '* -text'
foreach($f in Get-ChildItem $PSScriptRoot -File){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $d ('tools\'+$f.Name))}
foreach($name in @('authority.json','helper-audit.json','jtag-before.csv','jtag-after.csv','controller-lock-acquired.json','controller-lock-released.json')){Copy-Item "$r\logs\$name" "$d\raw\$name"}
foreach($name in @('driver-verification.json','driver-load.json','insmod-attempt.json','node-map.json','t1-proof.json','t2-result.json','offline-selftest.json','boot-list.txt','linux-lock.json')){Copy-Item "$r\artifacts\dut-text\$name" "$d\raw\$name"}
Copy-Item "$r\artifacts\MMIO_AUTHORIZATION_REVIEW.md" "$d\raw\MMIO_AUTHORIZATION_REVIEW.md"
$summary=@($conn | ForEach-Object { [ordered]@{start_utc=$_.start_utc;end_utc=$_.end_utc;helper=$_.helper;helper_sha256=$_.helper_sha256;ip=$_.ip;host_key_pinned=$_.host_key_pinned;temporary_created=$_.temporary_created;temporary_deleted=$_.temporary_deleted;private_remaining=$_.private_remaining;exit_code=$_.exit_code;problem=$_.problem;stdout_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($_.stdout)));stderr_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($_.stderr)))} })
Put 'raw/connection-summary.json' ($summary|ConvertTo-Json -Depth 6)
$hashes=Get-ChildItem "$r\artifacts\dut-text" -File | ForEach-Object {[pscustomobject]@{File=$_.Name;Bytes=$_.Length;SHA256=(Get-FileHash $_.FullName).Hash;Disposition='Private local textual diagnostic evidence; selected records published'}}
Put 'raw/private-text-hashes.csv' (($hashes|ConvertTo-Csv -NoTypeInformation)-join "`n")
$interruption=Get-Content -Raw "$r\artifacts\dut-text\interruption-state.json" | ConvertFrom-Json
$interruption.PSObject.Properties.Remove('modules')
Put 'raw/interruption-state.json' ($interruption|ConvertTo-Json -Depth 5)
$journal=Get-Content "$r\artifacts\dut-text\journal-original-tail.txt"
Put 'raw/original-boot-tail-excerpt.txt' (($journal | Select-Object -Last 3)-join "`n")
$kernel=Get-Content "$r\artifacts\dut-text\kernel-after-load.txt"
$base=Get-Content "$r\artifacts\dut-text\kernel-before.txt"
if(($kernel[0..($base.Count-1)] -join "`n") -cne ($base -join "`n")){throw 'KERNEL_BASELINE_PREFIX_CHANGED'}
$delta=$kernel | Select-Object -Skip $base.Count
Put 'raw/driver-kernel-delta.txt' (($delta | Where-Object {$_ -match 'xdma|module|taint|7011|01:00.0|AER|IOMMU|BUG:|Oops|Call Trace'})-join "`n")
Report 'AUTHORIZATION_RECEIPT' @'
Owner decision: G2B-HW0-PRODUCT-R3R2 supplied in this task. GRANTED.
Fresh root and helper only. Exactly three sessions maximum, no gate retries.
Reads: aligned 32-bit little-endian 0x0000..0x0030, 0x0080..0x00B4, 0x3800..0x3858.
Writes: CONTROL 0x380C exactly 0,1,4; SNAPSHOT 0x3844 exactly 1; post-reset conditional ERROR_STATUS W1C 0x383C exactly the immediately preceding active mask &0x38, once/session and at most three. Nonfatal W1C and statistics clear DENIED.
Mandatory disabled negotiation, reset, quiescent completion within five seconds, epoch +1, conditional exact fatal W1C, final baseline snapshot, reader ready, explicit enable, bounded capture, disable/drain. No mid-epoch or clean-boot exception.
One exact insmod, one normal unload if safe, read-only JTAG inventory and no FPGA programming were authorized. No persistent driver installation, modprobe, depmod, manual PCI binding, H2C, legacy writes, source/SSOT/prior-evidence changes, reboot or power cycle was authorized.
Actual capture sessions started: 0. Reset/enable/W1C/snapshot writes: 0/0/0/0. T3 launch timed out while DUT continuity was lost; no retry.
'@
Report 'BOUNDARY_RECEIPT' @"
PASS. Fresh controller root: $r
39 prior roots; 10814 inventory rows. Final comparison difference_count=0.
Prior immutable artifact new writes observed: 0. No task writes targeted prior roots.
Inventory combines all-file size/creation/last-write metadata with hashes of small manifest/index/receipt files; authority manifests separately verify exact content/blob identity. It is not a filesystem-wide write-event monitor.
PRODUCT worktree remained clean; SSOT revision 8 unchanged. Only the new R3R2 publication directory is staged.
Controller lock released after final read-only JTAG inventory. Linux lock disappeared across the unexpected boot transition; this is not a normal release PASS.
"@
Report 'CREDENTIAL_HELPER_AUDIT' @"
R3R2_CREDENTIAL_HELPER_HARD_GATE = PASS
Helper: $r\scripts\Invoke-R3R2DutConnection.ps1
SHA256: 7E263395A3CB8523FAC2232B456885C171D7D231AE458DCDCC4C7A3505BBD46F
Parse errors 0; prior-helper references 0; dot-source imports 0; hardcoded secret assignments 0.
Private ACL protected, one current-user rule. Temporary credential files created only in fresh private directory and deleted after each invocation. Pinned DUT host key; no credential-valued argument.
Invocations: $($conn.Count). Every invocation used this exact helper hash. First authenticated connection used this helper.
Credential remnants: 0. No credential content is published. Source reads the governed credential source in memory; it does not copy any predecessor secret file.
The T3 invocation timed out (124). Its credential file was nevertheless deleted. Receipt summaries retain timeout rather than claiming all calls succeeded.
"@
Report 'AUTHORITY_VERIFICATION' @'
PASS before hardware execution. PROJECT_STATE_REV=8 at start and end.
PRODUCT source: lukaszsudul/FPGA_AHD, integration/v41-g2b-onech-c2h, 92e9b3d914134c044371779def1ee18eaaeda98a; tree cf6bf82249c90782eab1978c68541ed9c0e6430b. RTL rtl/g2b/v41_g2b_onech_c2h.sv semantics agree with authorization (raw/MMIO_AUTHORIZATION_REVIEW.md).
ABI SHA256 AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6.
Bitstream AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7.
Signed-off DCP 95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175.
Exact manifest SHA and Git blob verified for SSOT18, META8A32, Recovery4 181, R2 128, DRV1 29, R3 66, R3R1 35 entries. Full commit identities and issue-free results in raw/authority.json. Prior R3R1 hardware accessed NO.
Artifact authority PASS does not prove continued SRAM identity after unexpected reboot. Final retained-candidate continuity UNRESOLVED.
'@
Report 'DUT_LOCK_RECEIPT' @'
T0 controller and Linux locks acquired with no competing hardware task/process/node holder. Original boot 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac.
The unexpected boot transitions invalidate ongoing exclusivity. Final Linux lock absent; do not describe it as successfully released or reacquire it for a retry. Controller lock released last at the timestamp in raw/controller-lock-released.json.
DUT exclusivity: PASS at T0; BLOCKED after boot change.
'@
Report 'PRELOAD_INVENTORY' @'
PASS at T0: VCDE-DUT-1 / 10.132.1.111, machine identity 0e90f50d9465492b80258da5658446f8, kernel 7.0.0-29-generic x86_64, boot 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac.
FPGA xc7a35t, IDCODE0362D093, DONE1 in five fresh samples. JTAG target 80802026a98b01 correlated with retained candidate and exact PCI endpoint.
Endpoint 0000:01:00.0, 10ee:7011 / 10ee:0007, upstream 0000:00:01.1, Gen2 5.0 GT/s x1, initially unbound. driver_override empty/(null), both xdma and xdma_ahd_pcie unloaded; no stale XDMA nodes or competing holders.
AER sysfs counter files unavailable, not asserted zero. PCI configuration and kernel baseline captured privately with published hashes.
'@
Report 'DRIVER_VERIFICATION' @'
PASS. Exact sealed module /home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko.
SHA256 E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77; size3296104.
Module name xdma_ahd_pcie; exact PCI vendor/device/subsystem alias; kernel vermagic 7.0.0-29-generic; ELF64 AMD64; no installation or module binary publication. Exact verification in raw/driver-verification.json.
'@
Report 'DRIVER_LOAD_PROBE' @'
PASS at T1. Exactly one sudo insmod of the sealed module, no parameters, return0. Automatic binding only to 0000:01:00.0; unintended bound endpoints0; platform xdma remained absent.
No manual new_id/bind/unbind/override, modprobe or depmod. Taint0 before,12288 after (out-of-tree and unsigned bits12/13).
After unexpected reboot the module was absent. Normal unload attempts0: no unload command was issued against an already absent module. This is not a successful normal cleanup cycle.
'@
Report 'NODE_TO_BDF_PROOF' @'
PASS at T1, before MMIO. Dynamic index0 was discovered, not assumed.
/dev/xdma0_user major511 minor0; /dev/xdma0_c2h_0 major511 minor36.
Both nodes independently resolved through /sys/dev/char and /sys/class/xdma to 0000:01:00.0. Full node map published. H2C node creation by the driver was observed but H2C was never opened or used.
'@
$nodes=Get-Content -Raw "$r\artifacts\dut-text\node-map.json"|ConvertFrom-Json
Put ($prefix+'NODE_MAP.csv') (($nodes|ConvertTo-Csv -NoTypeInformation)-join "`n")
Copy-Item "$r\artifacts\dut-text\mmio-raw.csv" ($d+'\'+$prefix+'MMIO_RAW.csv')
Report 'MMIO_DECODED' @'
T2 PASS. Legacy SHA224d194e5f82c85bcb29297561c5d5e76d28063b, BUILD_FLAGS0x00000103 PRODUCT. Full values in raw/t2-result.json and MMIO_RAW.csv.
G2B magic0x43324831, ABI0x00010000, capabilities0x000B001F. CONTROL0, STATUS0xC4 (disabled,inactive,empty,ready,locked), epoch0, ERROR_STATUS0, LAST_ERROR_CAUSE0. Historical LAST_ERROR_CAUSE was not treated as an active fatal bit.
All observed MMIO operations were aligned 32-bit reads in authorized ranges. No G2B write, snapshot request, stream reset or enable was reached. Final post-reboot MMIO was not attempted without a proven driver/node path.
'@
Put ($prefix+'MMIO_WRITE_LEDGER.csv') 'Timestamp,Session,Node,BDF,Offset,Value,Purpose,Authorized,Precondition,Result'
Report 'SESSION_START_RECEIPTS' @'
No actual START_C2H_CAPTURE_SESSION reached. T3 launch timed out; no T3-start-once, session-start, reader-ready, write ledger, completion journal or raw capture file exists on DUT. T4/T5 NOT_REACHED and not retried.
Reset writes0, enable writes0, fatal W1C0, nonfatal W1C0, statistics clear0, unauthorized writes0. No per-session epoch or fatal-mask observation is available; T2 epoch0 is NOT a T3 pre-reset epoch.
Complete auditable implementation in tools/capture.py (START_C2H_CAPTURE_SESSION). Exact frozen parser and ABI are included. Offline synthetic/mock tests PASS but are not DUT DMA or hardware-session evidence. Mock write tests never touched a device.
No continuation on the new boot was attempted. Absence of persistent start records plus boot interruption is reported honestly; no successful capture is inferred.
'@
Report 'NVP_VIDEO_READINESS' @'
PASS at T2 before interruption: initialization done, INIT_ERROR0, NACK_COUNT0, fixed physical input0, live1080p25 telemetry. In3.000557332s VCLK delta445570413, SAV delta84390, VCLK/SAV5279.895876, SAV/s28124.775054. G2B source-ready/locked bits set. No input switch/NVP write.
These are pre-interruption observations, not final post-reboot validation and not a captured-frame proof.
'@
Report 'FIRST_RECORD_REPORT' "$stop`nT3 launch timed out before any persistent session-start receipt. No first record; bytes N/A; SHA NONE; geometry/header/padding NOT_REACHED. No retry."
Put ($prefix+'FIRST_RECORD_HEADER.csv') 'Field,Value,Status'
Report 'FINITE_CAPTURE_REPORT' 'NOT_REACHED. T3 did not PASS. Primary records N/A; sequence, padding, malformed metrics unavailable. No T4 session or retry.'
Put ($prefix+'FINITE_CAPTURE_METRICS.csv') "Metric,Value,Status`nPrimaryRecords,,NOT_REACHED`nGaps,,NOT_REACHED`nDuplicates,,NOT_REACHED`nMalformed,,NOT_REACHED`nPaddingErrors,,NOT_REACHED"
Report 'FRAME_RECONSTRUCTION_REPORT' 'NOT_REACHED. No live raw records, UYVY frame or reconstructed camera image was created or published. Raw/viewable SHA NONE. Target geometry1920x1080 UYVY is unqualified, not an achieved result.'
Report 'CONTINUOUS_CAPTURE_REPORT' 'NOT_REACHED. No T5 start, warm-up or measured interval. No throughput measurement. Project-level >=288 MB/s remains NOT_PROVEN and was not an acceptance criterion.'
Put ($prefix+'CONTINUOUS_METRICS.csv') "Metric,Value,Status`nMeasuredSeconds,,NOT_REACHED`nRecords,,NOT_REACHED`nFrames,,NOT_REACHED`nApplicationMBps,,NOT_REACHED`nTransportMBps,,NOT_REACHED"
Report 'COUNTER_RECONCILIATION' 'NOT_REACHED. No capture-session host/MMIO reconciliation can be asserted. T2 disabled baseline recorded without coherent snapshot writes. No fabricated zero-error live-capture metrics.'
Report 'PCIE_AER_KERNEL_LOG_REVIEW' @'
Overall hardware-session health BLOCKED by unexpected DUT boot changes. Exact-alias driver-load kernel delta had expected unsigned/out-of-tree warnings and no observed driver Oops, Call Trace, BUG, IOMMU fault or AER fatal in that captured interval. AER sysfs counters were unavailable; no invented zero counts.
Original taint0 ->12288 after load. After normal unload N/A (unload not run). New boot taint0 must NOT be compared as an unload-cleared taint or unchanged original boot.
Original boot52b0bf13-e9d1-4558-ae13-d08f4ecc8dac journal ends20:40:00 CEST; intermediate3decbc63-3fc7-43fe-88b0-8901d225846b begins20:41:28; current9fec7547-fd31-4592-a9ce-89ea082d2484 begins20:42:00. T3 connection attempted18:41:02.988 UTC and timed out18:41:48.215 UTC.
Cause and initiator of reboot(s) unresolved. No task reboot/reset/power-cycle command exists. Do not attribute the boot change to driver, capture, operator or power supply without evidence. No capture START receipt was present after reconnection.
'@
Report 'CLEANUP_RECEIPT' @'
BLOCKED normal-cleanup qualification. Task-owned reader processes absent after boot change; no reader stop signal, MMIO safety disable, drain or rmmod was necessary/attempted on the new boot. Driver and XDMA nodes absent, endpoint unbound, platform xdma absent; endpoint still Gen2x1.
Original-session DMA quiescence and orderly unload could not be established across the reboot. No unsafe unload or additional reset was issued.
Linux lock absent across boot transition (not normal release). Controller lock released last after five final DONE1 samples. Credential remnants0; temporary credential files deleted after every helper invocation. No task-owned hardware work remains running.
'@
Report 'FINAL_HARDWARE_STATE' @'
Final read-only inventory: boot9fec7547-fd31-4592-a9ce-89ea082d2484; endpoint0000:01:00.0 unbound,5.0GT/s x1; xdma_ahd_pcie and xdma absent; /dev/xdma* absent. Final JTAG xc7a35t/0362D093/DONE1 five samples.
Final stream state/DMA quiescence NOT_REACHED; retained exact PRODUCT candidate UNRESOLVED because boot continuity was lost. DONE1 is not proof of exact bitstream identity after interruption.
Task-initiated reboot NO; actual reboot observed YES (two new boot IDs), cause unknown. Task power-cycle NO; whether an external power event occurred UNRESOLVED. Task FPGA SRAM/Flash programming NO. No persistent product/driver installation/SSOT/source changes. New task evidence files are the only intended persistent filesystem writes; do not interpret that scoped no-change claim as no filesystem writes at all.
'@
Put ($prefix+'GATE_MATRIX.csv') "Gate,Result,Reason`nT0,PASS,Fresh authority inventory and exclusivity before boot change`nT1,PASS,Exact module auto bind and node proof`nT2,PASS,Runtime and live readiness verified`nT3,BLOCKED,$blocker`nT4,NOT_REACHED,T3 not PASS`nT5,NOT_REACHED,T4 not reached`nCleanup,BLOCKED,Unexpected reboot prevented normal unload proof`nWriteAudit,PASS,No executed writes recorded or start reached`nImmutableBoundary,PASS,Zero differences`nEngineering,BLOCKED,$blocker"
$out=[ordered]@{task='G2B-HW0-PRODUCT-R3R2';engineering='BLOCKED';overall='BLOCKED';first_blocker=$blocker;evidence_publication='SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK';project_state_rev_at_start=8;project_state_rev_at_end=8;root=$r;credential_helper_sha256='7E263395A3CB8523FAC2232B456885C171D7D231AE458DCDCC4C7A3505BBD46F';credential_helper_hard_gate='PASS';helper_invocations=$conn.Count;all_connections_r3r2_helper=$true;credential_remnants=0;prior_immutable_new_writes=0;T0='PASS';T1='PASS';T2='PASS';T3='BLOCKED';T4='NOT_REACHED';T5='NOT_REACHED';driver_load_attempts=1;normal_unload_attempts=0;reset_writes=0;fatal_w1c_writes=0;enable_writes=0;unauthorized_writes=0;capture_sessions_started=0;hardware_accessed=$true;original_boot='52b0bf13-e9d1-4558-ae13-d08f4ecc8dac';final_boot=$interruption.boot;task_reboot_commands=0;actual_boot_changes_observed=2;task_power_cycle_commands=0;fpga_programming=$false;retained_exact_candidate='UNRESOLVED';final_done=1;normal_cleanup='BLOCKED';hardware_qualification='NOT_PROVEN';throughput_288_MBps='NOT_PROVEN';ssot_update_required=$false;recommended_next_step='Owner must resolve the unexpected DUT boot changes and re-establish exclusive stable-boot authority before authorizing a fresh run.'}
Put ($prefix+'STATE.json') ($out|ConvertTo-Json -Depth 5)
Put 'V41_G2B_HW0_PRODUCT_R3R2_MAIN_REPORT.md' @"
# AHD v41 G2B-HW0-PRODUCT-R3R2

Engineering gate: BLOCKED
Overall result: BLOCKED
First blocker: $blocker

T0 authority/exclusivity, T1 exact-driver auto-bind/node proof and T2 runtime/live-source readiness passed on boot52b0bf13-e9d1-4558-ae13-d08f4ecc8dac. One exact insmod succeeded. T3 launch timed out during loss of DUT continuity. Subsequent read-only inventory discovered two new boot IDs, no Linux lock, no driver or XDMA nodes, and no T3 start/write/capture artifacts. No retry, reset, reload, recovery or programming was performed.

No task reboot command was issued, but an actual reboot occurred: the requested literal 'Reboot: NO' cannot truthfully describe observed system state. 'NO' applies only to task-initiated reboot. Likewise absent driver/nodes is not a normal unload PASS, and final DONE1 does not establish exact candidate retention across changed boots.

T3 BLOCKED; T4/T5 NOT_REACHED. No first record, finite capture, frame or measured throughput. Reset/W1C/enable/MMIO writes0. Last verified MMIO was disabled T2 baseline; post-reboot stream/DMA state was not re-read without driver/node proof.

Fresh root: $r. Helper hard gate PASS; $($conn.Count) helper invocations, all exact fresh helper, credential remnants0. Prior immutable boundary PASS with10814 rows/zero differences. PROJECT_STATE_REV8 unchanged. Source/RTL/XDC/SSOT and prior evidence untouched. Only new task scripts/logs/artifacts and new publication directory created.

Final read-only JTAG xc7a35t/0362D093/DONE1 five samples. Endpoint Gen2x1/unbound; module/nodes absent after reboot. Linux lock lost, controller lock released last. Normal cleanup qualification BLOCKED; exact retained candidate UNRESOLVED.

Evidence is sealed independently of engineering. Commit and commit-pinned remote byte/blob/SHA readback are completed after sealing; the final transaction receipt is stored outside this immutable commit under the fresh controller artifacts directory. No publication PASS is inferred merely from push success.

Recommended next step: resolve unexpected DUT boot changes and obtain fresh Owner authorization with a stable exclusive boot. No SSOT promotion justified. >=288MB/s NOT_PROVEN; four-input/two-channel NOT_QUALIFIED; synthetic/V4L2 NOT_TESTED.
"@
$files=Get-ChildItem $d -Recurse -File | Sort-Object FullName
Report 'EVIDENCE_INDEX' ("All paths below are relative to this directory. Full task sources are in tools; no binaries or raw camera data included.`n`n"+(($files|ForEach-Object {'- '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/')})-join "`n"))
$manifest=Get-ChildItem $d -Recurse -File | Sort-Object FullName | ForEach-Object { (Get-FileHash $_.FullName).Hash+'  '+[IO.Path]::GetRelativePath($d,$_.FullName).Replace('\','/') }
Put ($prefix+'SHA256_MANIFEST.txt') ($manifest-join "`n")
"PACKAGE_FILES=$(@(Get-ChildItem $d -Recurse -File).Count)"
