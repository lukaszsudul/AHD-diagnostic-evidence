$ErrorActionPreference='Stop'
$run='C:\FPGA\G2B_HW0_PRODUCT_R3R3_20260906T200624Z'
$repo='C:\FPGA\V41_G2B_EVIDENCE'
$rel='v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record'
$out=Join-Path $repo $rel
$remote=Join-Path $run 'artifacts\remote-snapshot'
$remoteLogs=Join-Path $remote 'logs'
$utf=[Text.UTF8Encoding]::new($false)
$helper=Join-Path $run 'scripts\Invoke-R3R3DutConnection.ps1'
$helperSha='EA6DEBB816C029726D00D9227A2DE5FB352C1692849A7A4BB96583CC164804D1'
$manifestName='G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt'

function Write-Utf8([string]$Path,[string]$Text){
 $normalized=($Text -replace "`r`n","`n").TrimEnd("`r","`n")+"`n"
 [IO.File]::WriteAllText($Path,$normalized,$utf)
}
function Read-Json([string]$Path){Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json}
function Read-ConnectionPayload([string]$Name){
 $j=Read-Json (Join-Path $run "logs\connection-$Name.json")
 $match=[regex]::Match([string]$j.stdout,'(?s)^\s*(\{.*\})\s*(?:[A-Z][A-Z0-9_]+=.*)?\s*$')
 if(-not $match.Success){throw "CONNECTION_JSON_PAYLOAD_NOT_FOUND:$Name"}
 return ($match.Groups[1].Value | ConvertFrom-Json)
}

if(Test-Path -LiteralPath $out){throw 'R3R3_PUBLICATION_DIRECTORY_ALREADY_EXISTS'}
if(-not(Test-Path -LiteralPath $remoteLogs -PathType Container)){throw 'R3R3_REMOTE_SNAPSHOT_MISSING'}
New-Item -ItemType Directory -Path $out,(Join-Path $out 'raw'),(Join-Path $out 'tools') | Out-Null

$authority=Read-Json (Join-Path $run 'logs\authority.json')
$program=Read-Json (Join-Path $run 'receipts\sram-program-supervisor.json')
$reboot=Read-Json (Join-Path $run 'receipts\warm-reboot-supervisor.json')
$helperAudit=Read-Json (Join-Path $run 'receipts\credential-helper-audit.json')
$boundaryDisposition=Read-Json (Join-Path $run 'receipts\boundary-initial-disposition.json')
$prelock=Read-Json (Join-Path $run 'receipts\controller-prelock-exclusivity.json')
$controllerAcquired=Read-Json (Join-Path $run 'logs\controller-lock-acquired.json')
$controllerReleased=Read-Json (Join-Path $run 'logs\controller-lock-released.json')
$preInventory=Read-ConnectionPayload 'preprogram-fresh-inventory'
$postInventory=Read-ConnectionPayload 'postreboot-fresh-inventory'
$linuxRelease=Read-ConnectionPayload 'release-post-reboot-lock'
$t1=Read-Json (Join-Path $remoteLogs 't1-proof.json')
$t1Result=Read-Json (Join-Path $remoteLogs 't1-result.json')
$t2=Read-Json (Join-Path $remoteLogs 't2-result.json')
$t3=Read-Json (Join-Path $remoteLogs 'T3-result.json')
$reader=Read-Json (Join-Path $remoteLogs 'T3-reader-result.json')
$rollback=Read-Json (Join-Path $remoteLogs 'post-t3-rollback-assessment.json')
$cleanup=Read-Json (Join-Path $remoteLogs 'cleanup-result.json')
$driver=Read-Json (Join-Path $remoteLogs 'driver-verification.json')
$nodeMap=Read-Json (Join-Path $remoteLogs 'node-map.json')
$healthT2=Read-Json (Join-Path $remoteLogs 'health-after-t2.json')
$healthT3=Read-Json (Join-Path $remoteLogs 'health-after-t3.json')
$healthFinal=Read-Json (Join-Path $remoteLogs 'health-after-unload.json')
$ledger=@(Import-Csv -LiteralPath (Join-Path $remoteLogs 'mmio-write-ledger.csv'))
$completions=@(Get-Content -LiteralPath (Join-Path $remoteLogs 'write-completions.jsonl') | ForEach-Object {$_|ConvertFrom-Json})

if($program.result -cne 'PASS' -or $reboot.result -cne 'PASS' -or
   $t1.result -cne 'PASS' -or $t2.result -cne 'PASS' -or
   $t3.result -cne 'BLOCKED' -or $cleanup.result -cne 'PASS' -or
   $rollback.result -cne 'PASS'){throw 'R3R3_SOURCE_EVIDENCE_STATE_MISMATCH'}
if((Get-FileHash -LiteralPath $helper).Hash -cne $helperSha -or
   $helperAudit.result -cne 'PASS'){throw 'R3R3_HELPER_IDENTITY_OR_AUDIT_FAILED'}
if((Get-FileHash -LiteralPath (Join-Path $run 'logs\boundary-before.json')).Hash -cne
   (Get-FileHash -LiteralPath (Join-Path $run 'logs\boundary-after.json')).Hash){
 throw 'R3R3_IMMUTABLE_BOUNDARY_HASH_DRIFT'
}

$connectionRows=@(Get-ChildItem -LiteralPath (Join-Path $run 'logs') -Filter 'connection-*.json' | Sort-Object Name | ForEach-Object {
 $j=Read-Json $_.FullName
 if($j.helper -cne $helper -or $j.helper_sha256 -cne $helperSha -or
    $j.credential_in_process_arguments -ne $false -or
    $j.temporary_deleted -ne $true -or [int]$j.private_remaining -ne 0){
   throw ('R3R3_CONNECTION_HELPER_AUDIT_FAILED:'+$_.Name)
 }
 [pscustomobject]@{receipt=$_.Name;start_utc=$j.start_utc;end_utc=$j.end_utc;
   ip=$j.ip;host_key_pinned=$j.host_key_pinned;exit_code=$j.exit_code;
   problem=if($j.problem){$j.problem}else{''};credential_in_process_arguments=$j.credential_in_process_arguments;
   temporary_deleted=$j.temporary_deleted;private_remaining=$j.private_remaining}
})
$helperInvocations=$connectionRows.Count
$helperTransportFailures=@($connectionRows|Where-Object {[int]$_.exit_code -ne 0}).Count

$resetWrites=@($ledger|Where-Object {$_.Offset -ceq '0x380C' -and $_.Value -ceq '0x00000004'}).Count
$enableWrites=@($ledger|Where-Object {$_.Offset -ceq '0x380C' -and $_.Value -ceq '0x00000001'}).Count
$normalDisableWrites=@($ledger|Where-Object {$_.Purpose -ceq 'NORMAL_DISABLE'}).Count
$safetyDisableWrites=@($ledger|Where-Object {$_.Purpose -ceq 'SAFETY_DISABLE'}).Count
$snapshotWrites=@($ledger|Where-Object {$_.Offset -ceq '0x3844' -and $_.Value -ceq '0x00000001'}).Count
$fatalW1cWrites=@($ledger|Where-Object {$_.Offset -ceq '0x383C'}).Count
$statsClearWrites=@($ledger|Where-Object {$_.Offset -ceq '0x380C' -and $_.Value -ceq '0x00000002'}).Count
$unauthorizedWrites=@($ledger|Where-Object {
 $valid=($_.Offset -ceq '0x380C' -and $_.Value -in @('0x00000000','0x00000001','0x00000004')) -or
        ($_.Offset -ceq '0x3844' -and $_.Value -ceq '0x00000001') -or
        ($_.Offset -ceq '0x383C' -and $_.Value -in @('0x00000008','0x00000010','0x00000018','0x00000020','0x00000028','0x00000030','0x00000038'))
 (-not $valid) -or $_.Authorized -cne 'YES'
}).Count
if($ledger.Count -ne 4 -or $completions.Count -ne 4 -or $resetWrites -ne 1 -or
   $enableWrites -ne 1 -or $normalDisableWrites -ne 1 -or
   $safetyDisableWrites -ne 0 -or $snapshotWrites -ne 1 -or
   $fatalW1cWrites -ne 0 -or $statsClearWrites -ne 0 -or $unauthorizedWrites -ne 0){
 throw 'R3R3_MMIO_WRITE_LEDGER_VALIDATION_FAILED'
}

$raw=Join-Path $out 'raw'
$tools=Join-Path $out 'tools'
$rawCopies=[ordered]@{
 (Join-Path $run 'logs\authority.json')='authority.json'
 (Join-Path $run 'receipts\sram-program-supervisor.json')='programming-receipt.json'
 (Join-Path $run 'receipts\warm-reboot-supervisor.json')='warm-reboot-receipt.json'
 (Join-Path $run 'receipts\credential-helper-audit.json')='credential-helper-audit.json'
 (Join-Path $run 'receipts\credential-helper-audit-initial-conservative.json')='credential-helper-audit-initial-conservative.json'
 (Join-Path $run 'receipts\boundary-initial-disposition.json')='boundary-initial-disposition.json'
 (Join-Path $run 'receipts\controller-prelock-exclusivity.json')='controller-prelock-exclusivity.json'
 (Join-Path $run 'logs\controller-lock-acquired.json')='controller-lock-acquired.json'
 (Join-Path $run 'logs\controller-lock-released.json')='controller-lock-released.json'
 (Join-Path $run 'logs\jtag-preprogram.csv')='jtag-preprogram.csv'
 (Join-Path $run 'logs\jtag-postprogram.csv')='jtag-postprogram.csv'
 (Join-Path $run 'logs\jtag-postreboot.csv')='jtag-postreboot.csv'
 (Join-Path $run 'logs\jtag-final.csv')='jtag-final.csv'
 (Join-Path $remoteLogs 'driver-verification.json')='driver-verification.json'
 (Join-Path $remoteLogs 't1-result.json')='t1-result.json'
 (Join-Path $remoteLogs 't1-proof.json')='t1-proof.json'
 (Join-Path $remoteLogs 'node-map.json')='node-map.json'
 (Join-Path $remoteLogs 't2-result.json')='t2-result.json'
 (Join-Path $remoteLogs 'mmio-raw.csv')='mmio-raw.csv'
 (Join-Path $remoteLogs 'mmio-write-ledger.csv')='mmio-write-ledger.csv'
 (Join-Path $remoteLogs 'write-completions.jsonl')='write-completions.jsonl'
 (Join-Path $remoteLogs 'T3-start-once.json')='T3-start-once.json'
 (Join-Path $remoteLogs 'T3-reader-ready.json')='T3-reader-ready.json'
 (Join-Path $remoteLogs 'T3-reader-result.json')='T3-reader-result.json'
 (Join-Path $remoteLogs 'T3-result.json')='T3-result.json'
 (Join-Path $remoteLogs 'post-t3-rollback-assessment.json')='post-t3-rollback-assessment.json'
 (Join-Path $remoteLogs 'cleanup-result.json')='cleanup-result.json'
 (Join-Path $remoteLogs 'health-after-t2.json')='health-after-t2.json'
 (Join-Path $remoteLogs 'health-after-t3.json')='health-after-t3.json'
 (Join-Path $remoteLogs 'health-after-unload.json')='health-after-unload.json'
 (Join-Path $remoteLogs 'offline-selftest.json')='offline-selftest.json'
 (Join-Path $remoteLogs 'pre-t2-postload-guard-final.json')='pre-t2-postload-guard.json'
 (Join-Path $remoteLogs 'pre-t3-postload-guard.json')='pre-t3-postload-guard.json'
}
foreach($entry in $rawCopies.GetEnumerator()){
 if(-not(Test-Path -LiteralPath $entry.Key -PathType Leaf)){throw ('R3R3_RAW_SOURCE_MISSING:'+ $entry.Key)}
 Copy-Item -LiteralPath $entry.Key -Destination (Join-Path $raw $entry.Value)
}
Write-Utf8 (Join-Path $raw 'preprogram-inventory.json') ($preInventory|ConvertTo-Json -Depth 12)
Write-Utf8 (Join-Path $raw 'postreboot-inventory.json') ($postInventory|ConvertTo-Json -Depth 12)
Write-Utf8 (Join-Path $raw 'post-reboot-linux-lock-release.json') ($linuxRelease|ConvertTo-Json -Depth 8)
Write-Utf8 (Join-Path $raw 'connection-summary.csv') (($connectionRows|ConvertTo-Csv -NoTypeInformation)-join "`n")

$boundarySummary=[ordered]@{
 task='G2B-HW0-PRODUCT-R3R3';rows=10977;difference_count=0;result='PASS';
 before_sha256=(Get-FileHash -LiteralPath (Join-Path $run 'logs\boundary-before.json')).Hash;
 after_sha256=(Get-FileHash -LiteralPath (Join-Path $run 'logs\boundary-after.json')).Hash;
 directory_timestamp_disposition=$boundaryDisposition.result;
 transient_vivado_dfx_runtime_file='REMOVED_BEFORE_PUBLICATION';
 final_unrelated_untracked=@('.diag0-work/','.meta8a-work/');
 prior_immutable_new_writes=0
}
Write-Utf8 (Join-Path $raw 'boundary-summary.json') ($boundarySummary|ConvertTo-Json -Depth 6)

$identity=[ordered]@{
 project_state_rev_at_start=8;project_state_rev_at_end=8;
 evidence_head_at_start='90e81ada86a925fe421d3523b14ef3079c26cef1';
 source_branch='integration/v41-g2b-onech-c2h';
 source_commit='92e9b3d914134c044371779def1ee18eaaeda98a';
 source_tree='cf6bf82249c90782eab1978c68541ed9c0e6430b';source_clean=$true;
 bitstream_path=$program.bitstream_path;bitstream_bytes=$program.bitstream_size;
 bitstream_sha256=$program.bitstream_sha256;
 dcp_sha256='95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175';
 driver_sha256=$driver.sha256;abi_sha256='AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
}
Write-Utf8 (Join-Path $raw 'source-and-artifact-identity.json') ($identity|ConvertTo-Json -Depth 5)

$hashRows=@()
foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $remoteLogs '') -File | Where-Object {$_.Name -like 'kernel-*.txt'}) +
                 @(Get-ChildItem -LiteralPath (Join-Path $run 'logs') -File | Where-Object {$_.Name -like 'vivado-*.log' -or $_.Name -like 'vivado-*.jou'})){
 $hashRows+=[pscustomobject]@{artifact_class=if($file.Name -like 'kernel-*'){'PRIVATE_KERNEL_LOG'}else{'LOCAL_VIVADO_LOG'};
   name=$file.Name;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash;public_bytes='NOT_PUBLISHED'}
}
Write-Utf8 (Join-Path $raw 'private-log-hashes.csv') (($hashRows|Sort-Object artifact_class,name|ConvertTo-Csv -NoTypeInformation)-join "`n")

foreach($file in Get-ChildItem -LiteralPath (Join-Path $run 'scripts') -File){
 Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $tools $file.Name)
}
$toolHashLines=Get-ChildItem -LiteralPath $tools -File | Sort-Object Name | ForEach-Object {
 (Get-FileHash -LiteralPath $_.FullName).Hash+'  '+$_.Name
}
Write-Utf8 (Join-Path $tools 'TOOLS_SHA256.txt') ($toolHashLines-join "`n")

$nodeRows=$nodeMap|ForEach-Object {[pscustomobject]@{node=$_.node;major=$_.major;minor=$_.minor;
 mode=$_.mode;bdf='0000:01:00.0';char_device=$_.char_device;class_device=$_.class_device;result='PASS'}}
Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_NODE_MAP.csv') (($nodeRows|ConvertTo-Csv -NoTypeInformation)-join "`n")
Copy-Item -LiteralPath (Join-Path $remoteLogs 'mmio-raw.csv') -Destination (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_MMIO_RAW.csv')
Copy-Item -LiteralPath (Join-Path $remoteLogs 'mmio-write-ledger.csv') -Destination (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_MMIO_WRITE_LEDGER.csv')

$abi=Read-Json (Join-Path $run 'scripts\V41_C2H_TRANSPORT_ABI_V1.json')
$headerRows=$abi.header.fields|ForEach-Object {[pscustomobject]@{word_index=$_.index;byte_offset=$_.offset_hex;
 field=$_.name;observed='N/A';status='NOT_REACHED_RECORD_BYTES_NOT_PRESERVED'}}
Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_FIRST_RECORD_HEADER.csv') (($headerRows|ConvertTo-Csv -NoTypeInformation)-join "`n")

Write-Utf8 (Join-Path $out 'V41_G2B_HW0_PRODUCT_R3R3_MAIN_REPORT.md') @"
# AHD v41 G2B-HW0-PRODUCT-R3R3

## Outcome

| Gate | Result |
|---|---|
| Engineering | BLOCKED |
| Evidence publication | SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK |
| Overall | BLOCKED |

First blocker: BLOCKED — R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA at the capture-time decision point.

T0, T1 and T2 passed. The exact PRODUCT image was programmed to SRAM once, survived exactly one controlled warm reboot, enumerated as the exact Gen2 x1 AHD endpoint, automatically bound to the sealed driver, exposed dynamically mapped XDMA nodes, and returned the expected runtime identity and live input-0 telemetry.

T3 consumed its one authorized session. The mandatory reset executed once, epoch advanced from 1 to 2, post-reset ERROR_STATUS was zero, no W1C was needed, one coherent pre-capture snapshot completed, one reader was ready before one enable, and a complete record arrived within the ten-second budget. The reader assembled 53 complete 4096-byte records (one primary plus 52 drain) and the parent issued the single normal disable. The reader then exited during bounded drain before proving quiescence. The exact records were not persisted, so ABI/header/payload/padding/epoch validation and coherent counter reconciliation were not reached. No retry was authorized or attempted.

A subsequent read-only rollback assessment found no XDMA descriptors open and independently proved CONTROL=0 with the quiescent status mask. It also preserved active nonfatal ERROR_STATUS=0x00000007 and LAST_ERROR_CAUSE=0x00000002; no nonfatal W1C was attempted. Safe cleanup then performed exactly one normal unload, automatically unbound the endpoint, removed all XDMA nodes, and left both endpoint and root-port links at Gen2 x1. Kernel/AER review remained clean. Final JTAG read-back returned the exact sole xc7a35t, IDCODE 0362D093, DONE=1 in five samples.

The engineering gate remains BLOCKED because the one permitted session cannot establish the record's SHA-256, frozen ABI fields, padding, epoch, or counter reconciliation. ONE_RECORD_FIXED_LIVE_AHD_C2H_HARDWARE_PASS is not claimed. The 2500-record capture, frame reconstruction, 60-second capture, throughput, multi-input, two-channel, synthetic, V4L2, soak, and release gates were not run.

PROJECT_STATE_REV remained 8. SSOT, RTL, XDC, PRODUCT candidate, driver binary, prior evidence, and unrelated records were not modified. Raw camera bytes are not present in this public package. Publication completion and commit-pinned remote byte/blob verification are recorded outside this immutable commit in the fresh run root.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_OWNER_RESTART_DISPOSITION.md') @"
# Owner restart disposition

- Owner prior restart attribution: PARALLEL_HDMI_WORK_CONFIRMED.
- Prior R3R2 boot-transition disposition: ACCEPTED_EXTERNAL_OWNER_OPERATION.
- Separate BOOT0 audit: NOT_REQUIRED.
- Continuity from R3R2: NOT_ASSUMED.
- R3R3 established current boot, FPGA, endpoint, module, node, lock, MMIO, and reset-epoch state afresh.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_AUTHORIZATION_RECEIPT.md') @"
# R3R3 authorization receipt

Owner authority in the R3R3 task granted one exact volatile SRAM programming attempt and one controlled graceful warm reboot; both budgets were consumed exactly once. Flash programming and power-cycle authority were denied. Exactly one driver load and one normal unload were used. PCI rescan, endpoint/root-port reset, new_id, driver_override, manual bind/unbind, persistent driver installation, H2C, and unrelated hardware recovery were not performed.

MMIO reads were restricted to aligned 32-bit words in 0x0000..0x0030, 0x0080..0x00B4, and 0x3800..0x3858. The completed write ledger contains exactly: one RESET_STREAM_STATE, one coherent snapshot request, one enable, and one normal disable. Fatal W1C, nonfatal W1C, statistics clear, safety disable, and unauthorized writes are all zero. One T3 session was started and no retry occurred.

The controller and DUT locks were held through cleanup and released Linux first, controller last.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_BOUNDARY_RECEIPT.md') @"
# Immutable-boundary receipt

Final comparison: PASS, 10,977 rows, zero differences. Before/after snapshot SHA-256: $($boundarySummary.before_sha256).

The initial raw scan observed only directory timestamp cache materialization at $($boundaryDisposition.path), timestamped before R3R3 began. The corrected governed comparison ignores directory-entry timestamps while preserving directory existence and every file's size, timestamps, and selected evidence hash. It found zero file or path differences.

Vivado transiently created repository-root dfx_runtime.txt during this task; the task-generated untracked file was identified by its R3R3 timestamp and removed before sealing. Final repository status before publication contained only the pre-existing .diag0-work/ and .meta8a-work/ directories. Prior immutable artifact new writes: 0. Persistent source/RTL/XDC/SSOT/prior-evidence changes: 0.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_CREDENTIAL_HELPER_AUDIT.md') @"
# Credential-helper audit

Result: PASS.

- Helper: $helper
- SHA-256: $helperSha
- Authenticated helper invocations: $helperInvocations
- Every DUT connection used this exact R3R3-local helper: YES
- Credential in process arguments: NO
- Pinned host key, -pwfile, agent disabled, sharing disabled: PASS
- Temporary credential deletion after every invocation: PASS
- Final protected-private remnants: 0
- Helper transport nonzero exits: $helperTransportFailures (one pre-create permission failure and the intentionally stopped T3 command; neither authorized a second hardware attempt)

The credential value equals the governed public login. The conservative literal scan was therefore non-discriminating; the final source audit proved occurrences were login/path identity only, not an embedded secret. No credential file or secret-bearing receipt is published.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_AUTHORITY_VERIFICATION.md') @"
# Authority verification

PROJECT_STATE_REV at start/end: 8/8. Evidence HEAD and origin/main at start: 90e81ada86a925fe421d3523b14ef3079c26cef1.

| Authority directory | Pinned commit | Manifest entries | Result |
|---|---|---:|---|
$((@($authority|ForEach-Object {"| $($_.directory) | $($_.commit) | $($_.passed) | PASS |"})) -join [Environment]::NewLine)

Exact PRODUCT source: branch integration/v41-g2b-onech-c2h, commit 92e9b3d914134c044371779def1ee18eaaeda98a, tree cf6bf82249c90782eab1978c68541ed9c0e6430b, tracked/index clean. Bitstream: 2,192,144 bytes, SHA-256 $($program.bitstream_sha256). Routed DCP SHA-256: 95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175. Driver SHA-256: $($driver.sha256). Frozen ABI SHA-256: AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_DUT_LOCK_RECEIPT.md') @"
# DUT lock receipt

- Controller prelock inventory: PASS; zero other active Codex hardware tasks and zero matching controller processes.
- Controller lock acquired for thread $($controllerAcquired.thread) and held across programming, reboot, load, MMIO, T3, cleanup, and final JTAG.
- Pre-reboot Linux lock: held on boot $($preInventory.boot_id); invalidated by the authorized reboot as required.
- Post-reboot Linux lock: held on boot $($postInventory.boot_id) through final DUT evidence collection.
- Post-reboot Linux lock release: PASS, exact lock removed, other matching locks 0.
- Controller lock release: $($controllerReleased.utc), after Linux release, state RELEASED.
- Final controller processes: 0.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_PREPROGRAM_INVENTORY.md') @"
# Pre-program inventory

Authenticated DUT identity PASS: hostname $($preInventory.hostname), machine ID $($preInventory.machine_id), boot $($preInventory.boot_id), kernel $($preInventory.kernel), architecture $($preInventory.architecture).

No task-conflicting processes, locks, modules, XDMA nodes, or open XDMA descriptors were present. Exact AHD endpoint 0000:01:00.0 was unbound with 10ee:7011, subsystem 10ee:0007, class 058000, IOMMU group 13, root port 0000:00:01.1, Gen2 x1. The distinct HDMI-like endpoint 0000:0b:00.0 (10ee:7021, subsystem 10ee:f0a1) was unbound and not selected.

Sole JTAG target localhost:3121/xilinx_tcf/Xilinx/80802026a98b01, sole chain device xc7a35t, IDCODE 0362D093, pre-program DONE 1 in five samples.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_PROGRAMMING_RECEIPT.md') @"
# SRAM programming receipt

Result: PASS. Exactly one guarded invocation of program_hw_devices was delivered using Vivado 2025.2. No automatic retry and no configuration-memory/Flash command occurred.

- Bitstream: $($program.bitstream_path)
- Bytes: $($program.bitstream_size)
- SHA-256: $($program.bitstream_sha256)
- Source commit/tree: $($program.source_commit) / $($program.source_tree)
- Programming-wrapper SHA-256: $($program.tcl_sha256)
- Attempts: $($program.delivery_attempt)
- Vivado exit: $($program.vivado_exit_code)
- Post-program DONE: 1 in five JTAG samples

Immediate pre-reboot guard confirmed the same boot, held lock, no module/node/descriptor, and no active MMIO/DMA.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_WARM_REBOOT_RECEIPT.md') @"
# Controlled warm-reboot receipt

Result: PASS. Exactly one delayed graceful systemctl reboot request was acknowledged. SSH disconnect and authenticated return at the exact pinned DUT were observed.

- Pre-reboot boot ID: $($reboot.pre_boot_id)
- Post-reboot boot ID: $($reboot.post_boot_id)
- Expected transitions: 1
- Observed transitions: $($reboot.observed_task_window_boot_transitions)
- Later unexpected transitions: $($reboot.unexpected_boot_transitions_after_post_baseline)
- Power cycles: $($reboot.power_cycles)
- Second reboot authorization: $($reboot.second_reboot_authorized)
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_POSTREBOOT_INVENTORY.md') @"
# Post-reboot inventory

Fresh authenticated inventory PASS on boot $($postInventory.boot_id). Hostname, machine ID, kernel, architecture, exact endpoints, root-port ancestry, IOMMU groups, and Gen2 x1 link matched the authorized DUT. The exact AHD endpoint was present and unbound before driver load. No competing process, lock, module, XDMA node, class node, or XDMA descriptor was present. Post-reboot JTAG returned the same target/device/IDCODE with DONE 1 in five samples.
"@
$postInventoryReport=Join-Path $out 'G2B_HW0_PRODUCT_R3R3_POSTREBOOT_INVENTORY.md'
if(-not(Test-Path -LiteralPath $postInventoryReport -PathType Leaf)){
 Write-Utf8 -Path $postInventoryReport -Text (("# Post-reboot inventory"+[Environment]::NewLine+[Environment]::NewLine+
  "Fresh authenticated inventory PASS on boot "+$postInventory.boot_id+". Hostname, machine ID, kernel, architecture, exact endpoints, root-port ancestry, IOMMU groups, and Gen2 x1 link matched the authorized DUT. The exact AHD endpoint was present and unbound before driver load. No competing process, lock, module, XDMA node, class node, or XDMA descriptor was present. Post-reboot JTAG returned the same target/device/IDCODE with DONE 1 in five samples."+[Environment]::NewLine))
}

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_JTAG_PCIE_CORRELATION.md') @"
# JTAG-to-PCIe correlation

Result: PASS. Every JTAG phase found exactly one pinned target and one xc7a35t chain device with IDCODE 0362D093. DONE samples were 1 before programming, after programming, after warm reboot, and at final state. The post-reboot runtime identity and exact 10ee:7011/10ee:0007 endpoint appeared under root port 0000:00:01.1; the distinct 10ee:7021/10ee:f0a1 endpoint was excluded. Endpoint and root port remained at 5.0 GT/s x1.

Candidate retention: CANDIDATE_LEFT_IN_VOLATILE_SRAM = YES based on one programming attempt, no Flash operation, no power cycle, no second programming, one expected reboot, runtime identity after reboot, final endpoint presence, and final DONE=1.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_DRIVER_VERIFICATION.md') @"
# Driver verification

Result: PASS.

- Path: /home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko
- Bytes: $($driver.bytes)
- SHA-256: $($driver.sha256)
- Name: $($driver.name)
- Vermagic: $($driver.vermagic)
- Alias: $($driver.alias)
- Source version: $($driver.srcversion)
- Build ID: 1471c3a284ec1cb26115fe9e9bd59890a034f83e
- Secure Boot: disabled; signer and signature ID empty as sealed.

The module and its directory were not writable. The binary is not included publicly.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_DRIVER_LOAD_PROBE.md') @"
# Driver load and automatic probe

T1 result: PASS. One insmod returned 0. Automatic exact-alias probing bound only 0000:01:00.0; unintended endpoints bound: 0. Platform xdma remained absent. Dynamic index 0 created /dev/xdma0_user and /dev/xdma0_c2h_0 plus the sealed driver's ancillary nodes. Two independent sysfs ancestry paths correlated required nodes to the exact BDF.

Kernel taint changed from 0 to 12288, exactly the expected out-of-tree and unsigned bits. No new AER count or kernel/driver fatal signature appeared. No manual bind, new_id, driver_override, modprobe, depmod, installation, or H2C transfer occurred.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_NODE_TO_BDF_PROOF.md') @"
# XDMA node-to-BDF proof

Result: PASS. Dynamic index: 0.

/dev/xdma0_user and /dev/xdma0_c2h_0 were the sole required user/C2H nodes. Both /sys/dev/char/<major>:<minor>/device and /sys/class/xdma/<node>/device resolved through 0000:01:00.0. The automatic driver binding contained exactly that BDF. Full node rows are in G2B_HW0_PRODUCT_R3R3_NODE_MAP.csv and raw/node-map.json.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_MMIO_DECODED.md') @"
# MMIO decode

T2 result: PASS.

- Legacy block/protocol/schema: 0xA40A0C07 / 0x0000400B / 0x00031002
- Runtime embedded GIT_SHA: $($t2.embedded_git_sha)
- Vivado word/build: 0x07E90002 / 6299465
- BUILD_FLAGS: 0x00000103 (PRODUCT)
- XDMA identity: 0x58444D41
- NVP: initialized/ready/locked, NACK 0, INIT_ERROR 0, input 0 live
- G2B magic/ABI/capabilities: 0x43324831 / 0x00010000 / 0x000B001F
- Pre-session CONTROL/STATUS/epoch/ERROR_STATUS: 0x00000000 / 0x000000C4 / 1 / 0x00000000

T3 pre-reset state matched T2. One reset advanced epoch 1 to 2. Post-reset ERROR_STATUS was 0. The only coherent capture snapshot was the authorized pre-capture baseline. After the bounded-drain failure, read-only rollback assessment found CONTROL 0, STATUS 0x000004F4 with quiescent mask 0x00000004, ERROR_STATUS 0x00000007, and LAST_ERROR_CAUSE 0x00000002. Bits 2:0 were preserved and never W1C-cleared. No final coherent snapshot was requested after the first blocker.

Write counts: reset 1, snapshot 1, enable 1, normal disable 1, safety disable 0, fatal W1C 0, nonfatal W1C 0, statistics clear 0, unauthorized 0.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_SESSION_START_RECEIPT.md') @"
# T3 session-start receipt

- Sessions started: 1; retries: 0.
- Disabled baseline: CONTROL 0, STATUS 0x000000C4, no reader, reset not busy.
- RESET_STREAM_STATE: exactly once.
- Pre/post reset epochs: 1 / 2; modulo transition PASS.
- Post-reset ERROR_STATUS: 0x00000000.
- Fatal mask observed/written: 0x00000000 / NONE.
- Nonfatal W1C and statistics clear: 0 / 0.
- Coherent pre-capture snapshot: PASS; generation 1.
- Reader-ready receipt: PASS for /dev/xdma0_c2h_0.
- Enable: exactly once after reader ready.
- First complete 4096-byte record event: observed within budget.
- Normal disable: exactly once after the first complete-record event.

The capture-time worker then stopped before final quiescence proof, making T3 BLOCKED. No second reset, enable, or session was attempted.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_NVP_VIDEO_READINESS.md') @"
# NVP and live-source readiness

Result: PASS. Fixed physical source: INPUT_0. NACK count: 0. INIT_ERROR: 0. Status 0x000000F9 satisfied initialization, live-video, ready, locked, and selected-source requirements. Across $([math]::Round($t2.telemetry.seconds,6)) seconds, SAV delta was $($t2.telemetry.delta.'0x0084'), SAV rate $([math]::Round($t2.telemetry.sav_per_second,3))/s, and VCLK/SAV ratio $([math]::Round($t2.telemetry.vclk_per_sav,3)), within the governed live-source window.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_FIRST_RECORD_REPORT.md') @"
# First-record report

T3 gate: BLOCKED.

The task-owned reader handled partial reads and assembled exact 4096-byte boundaries. A first complete record event was delivered within the 10-second limit; the parent then wrote the single normal disable. The reader reports 53 complete records total: 1 primary and 52 bounded-drain records, with 0 incomplete trailing bytes.

The worker exited during bounded drain before its in-process quiescence proof. The parent stopped at R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA before persisting the record buffer or invoking the frozen ABI validator. Consequently:

- first record bytes assembled: 4096
- first record SHA-256: NONE
- payload SHA-256: NONE
- raw first record/payload retained locally: NO — NOT_PERSISTED_AFTER_CAPTURE-TIME_BLOCKER
- little-endian header: NOT_REACHED
- payload geometry: NOT_REACHED
- zero padding: NOT_REACHED
- record epoch: N/A
- host-observed fixed 4096-byte boundary: PASS
- direct TKEEP/TLAST hardware observation: NOT_PERFORMED

No raw camera bytes exist in this public package. No deterministic pixel claim is made. A fresh read-only assessment later proved physical DMA quiescence, but it cannot reconstruct or validate the lost record bytes and does not authorize a retry.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_COUNTER_RECONCILIATION.md') @"
# Counter reconciliation

Result: NOT_REACHED.

The coherent pre-capture snapshot was valid and all attempted/committed/streamed/drop/overflow/discontinuity/beat counters were zero. The reader assembled 53 complete records, but the capture-time drain/quiescence blocker occurred before raw persistence and before the mandatory final coherent snapshot. Later ordinary reads showed the unchanged pre-snapshot shadow counters and therefore are not used as a post-capture counter claim.

Records-streamed delta, beats-streamed delta, expected beats from qualified host records, source attempted/committed/dropped reconciliation, last sequence reconciliation, padding, and epoch validation are N/A. Active post-failure nonfatal ERROR_STATUS 0x00000007 was preserved. FIRST_RECORD_COUNTER_RECONCILIATION_MISMATCH is not asserted because the required coherent comparison was never performed; PASS is also not claimed.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_PCIE_AER_KERNEL_REVIEW.md') @"
# PCIe, AER, and kernel review

Result: PASS for health monitoring; this does not override the T3 blocker.

Snapshots before load, after load, after T2, after T3, and after unload retained endpoint/root-port Gen2 x1. Sysfs AER sets were empty/unavailable in every phase and had no delta. Kernel continuity from the immediate pre-load baseline was preserved. No Oops, BUG, call trace, hung task, use-after-free, IOMMU fault, DMA-API violation, completion timeout, malformed TLP, unsupported request, surprise link-down, link downgrade, or XDMA fatal signature appeared.

Taint: 0 before load, 12288 after load, 12288 final; exactly the expected out-of-tree plus unsigned-module delta. Private full logs remain under the fresh local run root; this package publishes their sizes/SHA-256 only.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_CLEANUP_RECEIPT.md') @"
# Cleanup receipt

Result: PASS.

The R3R3 reader had already exited. Fresh read-only assessment showed no XDMA holder and independently proved CONTROL 0 with the quiescent status mask. No safety disable or cleanup reset was issued. Active nonfatal ERROR_STATUS 0x00000007 was preserved.

Exactly one normal rmmod xdma_ahd_pcie returned 0; no forced unload occurred. Udev settled. The task module and every R3R3-created XDMA node were absent, platform xdma remained absent, the exact endpoint was present and automatically unbound, driver_override remained empty, both links remained Gen2 x1, AER/kernel health remained clean, and the boot ID did not change. Linux lock was released, then controller lock last.
"@

Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_FINAL_HARDWARE_STATE.md') @"
# Final hardware state

- Boot ID: $($cleanup.boot_id); no unexpected later transition.
- FPGA: exact sole xc7a35t, IDCODE 0362D093, final DONE 1 in five samples.
- Candidate left in volatile SRAM: YES.
- FPGA SRAM programming: YES_ONCE; Flash: NO; power cycle: NO; warm reboot: YES_ONCE.
- AHD endpoint: 0000:01:00.0, present, unbound, Gen2 x1 through root 0000:00:01.1.
- xdma_ahd_pcie: unloaded normally; platform xdma: absent; XDMA nodes/holders: none.
- Last pre-unload transport state: CONTROL 0x00000000, STATUS 0x000004F4, quiescent; ERROR_STATUS 0x00000007 preserved.
- Kernel/AER fatal health: PASS; final taint 12288 expected.
- Linux and controller locks: released in required order.
- Persistent DUT filesystem modification: NO (driver was not installed).

The safe final state does not convert T3 to PASS. First-record ABI and counter qualification remain not proven.
"@

$gateRows=@(
 [pscustomobject]@{gate='Authority and immutable boundary';result='PASS';reason='Revision 8, all manifests pass, zero prior immutable differences'},
 [pscustomobject]@{gate='T0 cold-start program reboot';result='PASS';reason='One SRAM program, one warm reboot, retained exact candidate'},
 [pscustomobject]@{gate='T1 driver bind nodes';result='PASS';reason='Exact driver, automatic sole bind, node-to-BDF proof'},
 [pscustomobject]@{gate='T2 runtime MMIO live source';result='PASS';reason='Exact identity, input 0 ready, NACK/init errors zero'},
 [pscustomobject]@{gate='T3 first-record qualification';result='BLOCKED';reason='R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA at capture-time; no retry authorized'},
 [pscustomobject]@{gate='First record boundary event';result='PASS';reason='One exact 4096-byte record event before normal disable'},
 [pscustomobject]@{gate='Header payload padding epoch';result='NOT_REACHED';reason='Record bytes not persisted after capture-time blocker'},
 [pscustomobject]@{gate='Counter reconciliation';result='NOT_REACHED';reason='Final coherent snapshot not performed after first blocker'},
 [pscustomobject]@{gate='PCIe AER kernel health';result='PASS';reason='No delta or fatal signature; Gen2 x1 retained'},
 [pscustomobject]@{gate='Safe cleanup';result='PASS';reason='Fresh quiescence proof and one normal unload'},
 [pscustomobject]@{gate='Candidate retention';result='PASS';reason='DONE 1 final, no second program/power cycle'},
 [pscustomobject]@{gate='2500 records frame reconstruction 60 seconds';result='NOT_RUN';reason='Explicit R3R3 hard stop'},
 [pscustomobject]@{gate='Evidence publication';result='SEALED_PENDING_REMOTE_READBACK';reason='Independent of engineering'}
)
Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_GATE_MATRIX.csv') (($gateRows|ConvertTo-Csv -NoTypeInformation)-join "`n")

$state=[ordered]@{
 task='G2B-HW0-PRODUCT-R3R3';engineering='BLOCKED';overall='BLOCKED';
 first_blocker='R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA';
 blocker_disposition='CAPTURE_TIME_STOP; LATER_READ_ONLY_ROLLBACK_ASSESSMENT_PASS; NO_RETRY';
 evidence_publication='SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK';
 project_state_rev_at_start=8;project_state_rev_at_end=8;run_root=$run;
 owner_prior_restart_attribution='PARALLEL_HDMI_WORK_CONFIRMED';continuity_from_r3r2='NOT_ASSUMED';
 helper_sha256=$helperSha;helper_gate='PASS';helper_invocations=$helperInvocations;
 all_connections_local_helper=$true;credential_remnants=0;prior_immutable_new_writes=0;
 pre_boot_id=$reboot.pre_boot_id;post_boot_id=$reboot.post_boot_id;
 observed_boot_transitions=1;unexpected_later_boot_transitions=0;
 sram_programming_attempts=1;warm_reboots=1;power_cycles=0;flash_programming=0;
 final_done=1;candidate_left_in_volatile_sram=$true;
 T0='PASS';T1='PASS';T2='PASS';T3='BLOCKED';
 reset_writes=$resetWrites;snapshot_writes=$snapshotWrites;enable_writes=$enableWrites;
 normal_disable_writes=$normalDisableWrites;safety_disable_writes=$safetyDisableWrites;
 fatal_w1c_writes=$fatalW1cWrites;nonfatal_w1c_writes=0;statistics_clear_writes=$statsClearWrites;
 unauthorized_mmio_writes=$unauthorizedWrites;pre_reset_epoch=1;post_reset_epoch=2;
 post_reset_error_status='0x00000000';post_failure_error_status='0x00000007';
 reader_complete_records=53;reader_primary_records=1;reader_drain_records=52;
 reader_trailing_bytes=0;first_record_boundary_event='PASS';first_record_bytes=4096;
 record_bytes_persisted=$false;record_sha256=$null;payload_sha256=$null;
 header='NOT_REACHED';payload_geometry='NOT_REACHED';padding='NOT_REACHED';record_epoch='NOT_REACHED';
 counter_reconciliation='NOT_REACHED';rollback_assessment='PASS';final_dma_quiescent=$true;
 normal_unload_attempts=1;cleanup='PASS';endpoint_final='PRESENT_UNBOUND';nodes_final='REMOVED';
 pcie_aer_kernel_health='PASS';kernel_taint_before=0;kernel_taint_after_load=12288;kernel_taint_final=12288;
 finite_2500_record_capture='NOT_RUN';frame_reconstruction='NOT_RUN';continuous_60_second_capture='NOT_RUN';
 throughput_288_MBps='NOT_PROVEN';four_input='NOT_QUALIFIED';two_channel='NOT_QUALIFIED';
 synthetic='NOT_TESTED';v4l2='NOT_TESTED';release='NOT_CREATED';full_g2b_hw='NOT_YET_PROVEN';
 ssot_update_required=$false
}
Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_STATE.json') ($state|ConvertTo-Json -Depth 8)

$required=@(
 'V41_G2B_HW0_PRODUCT_R3R3_MAIN_REPORT.md','G2B_HW0_PRODUCT_R3R3_OWNER_RESTART_DISPOSITION.md',
 'G2B_HW0_PRODUCT_R3R3_AUTHORIZATION_RECEIPT.md','G2B_HW0_PRODUCT_R3R3_BOUNDARY_RECEIPT.md',
 'G2B_HW0_PRODUCT_R3R3_CREDENTIAL_HELPER_AUDIT.md','G2B_HW0_PRODUCT_R3R3_AUTHORITY_VERIFICATION.md',
 'G2B_HW0_PRODUCT_R3R3_DUT_LOCK_RECEIPT.md','G2B_HW0_PRODUCT_R3R3_PREPROGRAM_INVENTORY.md',
 'G2B_HW0_PRODUCT_R3R3_PROGRAMMING_RECEIPT.md','G2B_HW0_PRODUCT_R3R3_WARM_REBOOT_RECEIPT.md',
 'G2B_HW0_PRODUCT_R3R3_POSTREBOOT_INVENTORY.md','G2B_HW0_PRODUCT_R3R3_JTAG_PCIE_CORRELATION.md',
 'G2B_HW0_PRODUCT_R3R3_DRIVER_VERIFICATION.md','G2B_HW0_PRODUCT_R3R3_DRIVER_LOAD_PROBE.md',
 'G2B_HW0_PRODUCT_R3R3_NODE_MAP.csv','G2B_HW0_PRODUCT_R3R3_NODE_TO_BDF_PROOF.md',
 'G2B_HW0_PRODUCT_R3R3_MMIO_RAW.csv','G2B_HW0_PRODUCT_R3R3_MMIO_DECODED.md',
 'G2B_HW0_PRODUCT_R3R3_MMIO_WRITE_LEDGER.csv','G2B_HW0_PRODUCT_R3R3_SESSION_START_RECEIPT.md',
 'G2B_HW0_PRODUCT_R3R3_NVP_VIDEO_READINESS.md','G2B_HW0_PRODUCT_R3R3_FIRST_RECORD_REPORT.md',
 'G2B_HW0_PRODUCT_R3R3_FIRST_RECORD_HEADER.csv','G2B_HW0_PRODUCT_R3R3_COUNTER_RECONCILIATION.md',
 'G2B_HW0_PRODUCT_R3R3_PCIE_AER_KERNEL_REVIEW.md','G2B_HW0_PRODUCT_R3R3_CLEANUP_RECEIPT.md',
 'G2B_HW0_PRODUCT_R3R3_FINAL_HARDWARE_STATE.md','G2B_HW0_PRODUCT_R3R3_GATE_MATRIX.csv',
 'G2B_HW0_PRODUCT_R3R3_STATE.json','G2B_HW0_PRODUCT_R3R3_EVIDENCE_INDEX.md',$manifestName)

$prohibited=@('.bin','.bit','.ko','.dcp','.uyvy','.png','.jpg','.jpeg','.tmp','.tar','.gz','.zip')
$bad=@(Get-ChildItem -LiteralPath $out -Recurse -File | Where-Object {$_.Extension.ToLowerInvariant() -in $prohibited})
if($bad.Count){throw 'R3R3_PROHIBITED_PUBLIC_BINARY'}
if(Get-ChildItem -LiteralPath $out -Recurse -File | Where-Object {$_.Name -match '(?i)credential.*\.txt$|password|secret|private.*\.bin'}){
 throw 'R3R3_PROHIBITED_PUBLIC_SECRET_NAMING'
}
$audit=[ordered]@{
 task='G2B-HW0-PRODUCT-R3R3';result='PASS';prohibited_binary_count=0;
 raw_camera_payload_files=0;credential_files=0;ko_binaries=0;bit_binaries=0;
 helper_source_secret_embedding=$false;helper_login_literal_disposition='PUBLIC_LOGIN_NOT_SECRET_FIELD';
 connection_receipts_publication='SANITIZED_SUMMARY_ONLY_NO_STDOUT_STDERR';
 private_kernel_and_vivado_logs='HASH_ONLY';public_extensions=@('.md','.csv','.json','.jsonl','.txt','.ps1','.py','.sh','.tcl')
}
Write-Utf8 (Join-Path $raw 'publication-policy-audit.json') ($audit|ConvertTo-Json -Depth 6)

$indexFiles=Get-ChildItem -LiteralPath $out -Recurse -File | Sort-Object FullName
$index="# R3R3 evidence index`n`nEngineering gate: ``BLOCKED``. Evidence is sealed for independent commit-pinned publication verification. No raw live-video bytes, credentials, driver binary, bitstream binary, or DCP are published.`n`n"+
 (($indexFiles|ForEach-Object {'- '+[IO.Path]::GetRelativePath($out,$_.FullName).Replace('\','/')})-join "`n")+"`n"
Write-Utf8 (Join-Path $out 'G2B_HW0_PRODUCT_R3R3_EVIDENCE_INDEX.md') $index

$manifestFiles=Get-ChildItem -LiteralPath $out -Recurse -File | Where-Object {$_.Name -cne $manifestName} | Sort-Object FullName
$manifestLines=$manifestFiles|ForEach-Object {(Get-FileHash -LiteralPath $_.FullName).Hash+'  '+[IO.Path]::GetRelativePath($out,$_.FullName).Replace('\','/')}
Write-Utf8 (Join-Path $out $manifestName) ($manifestLines-join "`n")

foreach($name in $required){if(-not(Test-Path -LiteralPath (Join-Path $out $name) -PathType Leaf)){throw ('R3R3_REQUIRED_PUBLIC_ARTIFACT_MISSING:'+ $name)}}
foreach($line in Get-Content -LiteralPath (Join-Path $out $manifestName)){
 if($line -notmatch '^([A-F0-9]{64})  (.+)$'){throw 'R3R3_MANIFEST_FORMAT'}
 if((Get-FileHash -LiteralPath (Join-Path $out $Matches[2])).Hash -cne $Matches[1]){throw ('R3R3_MANIFEST_SHA:'+ $Matches[2])}
}

[pscustomobject]@{task='G2B-HW0-PRODUCT-R3R3';result='PASS';engineering='BLOCKED';
 public_directory=$out;files=@(Get-ChildItem -LiteralPath $out -Recurse -File).Count;
 required_files=$required.Count;helper_invocations=$helperInvocations;mmio_writes=$ledger.Count;
 raw_camera_payload_files=0;credential_files=0;prior_immutable_differences=0} | ConvertTo-Json
