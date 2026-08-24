[CmdletBinding()]
param(
    [string]$BindingPath = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\09_HOST_TOOLS\R1G_HARDWARE_BINDINGS.json',
    [switch]$RequireFrozenHardwareBindings
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
$toolRoot = Join-Path $taskRoot '09_HOST_TOOLS'
$precheckRoot = Join-Path $taskRoot '10_HARDWARE_PRECHECK'
. (Join-Path $toolRoot 'R1gCampaignCommon.ps1')

$results = [Collections.Generic.List[object]]::new()
function Add-Result([string]$Gate,[bool]$Pass,[string]$Detail) {
    $results.Add([pscustomobject]@{
        Gate = $Gate
        Result = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
}

try {
    Assert-R1gAcceptedToolSet
    Add-Result INHERITED_R7_R6_TOOL_HASHES $true 'all exact accepted live/read-only leaf path, byte-count, and SHA-256 gates pass'
} catch {
    Add-Result INHERITED_R7_R6_TOOL_HASHES $false $_.Exception.Message
}

$frozenExpected = [ordered]@{
    'read_nvp_r1f.py' = @('5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C',46868)
    'r1f_statistics.py' = @('C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD',38404)
    'test_nvp_r1f_tools.py' = @('7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1',17276)
    'fixtures\r1f_valid_scenario.json' = @('8D6C63878488F79B1299F1AD2576EF830C52741F2938A9715EC597FBF4FAB1A8',899)
    'read_nvp_r1e.py' = @('0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037',8385)
}
foreach ($entry in $frozenExpected.GetEnumerator()) {
    $path = Join-Path $toolRoot ('frozen_r1f_host_tools\' + $entry.Key)
    try {
        [void](Assert-R1gExactFile -Path $path -Sha256 $entry.Value[0] -Bytes $entry.Value[1])
        Add-Result ('FROZEN_R1F_{0}' -f ($entry.Key.ToUpperInvariant().Replace('\','_').Replace('.','_'))) $true "$($entry.Value[0])"
    } catch {
        Add-Result ('FROZEN_R1F_{0}' -f ($entry.Key.ToUpperInvariant().Replace('\','_').Replace('.','_'))) $false $_.Exception.Message
    }
}

$r1gReader = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY\scripts\v41\read_nvp_r1f.py'
try {
    [void](Assert-R1gExactFile -Path $r1gReader -Bytes 46868 -Sha256 '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C')
    Add-Result R1G_WORKTREE_READER_UNCHANGED $true 'exact R1f reader remains byte-identical in R1g worktree'
} catch {
    Add-Result R1G_WORKTREE_READER_UNCHANGED $false $_.Exception.Message
}

$wrapperNames = @(
    'Initialize-R1gCampaignEvidenceDirectories.ps1',
    'Invoke-R1gHostStep.ps1',
    'Invoke-R1gIndependentDoneReadOnly.ps1',
    'Invoke-R1gProgramOnce.ps1',
    'Invoke-R1gTelemetryReadOnly.ps1',
    'New-R1gConfiguredImageReceipt.ps1',
    'R1gCampaignCommon.ps1',
    'Wait-R1gProgramMinimum.ps1'
)
$precheckNames = @(
    'Finalize-R1gFreshFormalStartGate.ps1',
    'Invoke-R1gExistingFormalTelemetryReadOnly.ps1',
    'Invoke-R1gHostBaselineReadOnly.ps1',
    'Invoke-R1gPrecheckJtagDoneReadOnly.ps1',
    'Invoke-R1gStartSafetyReadOnly.ps1',
    'New-R1gExistingFormalStartReceipt.ps1'
)
foreach ($name in $wrapperNames) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $toolRoot $name),[ref]$tokens,[ref]$errors)
    Add-Result ("POWERSHELL_PARSE_{0}" -f $name.ToUpperInvariant()) ($errors.Count -eq 0) (($errors | ForEach-Object Message) -join ' | ')
}
foreach ($name in $precheckNames) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $precheckRoot $name),[ref]$tokens,[ref]$errors)
    Add-Result ("POWERSHELL_PARSE_{0}" -f $name.ToUpperInvariant()) ($errors.Count -eq 0) (($errors | ForEach-Object Message) -join ' | ')
}
foreach ($path in @(
    (Join-Path $taskRoot 'scripts\New-R1gCampaignTooling.ps1'),
    (Join-Path $taskRoot 'fixtures\Test-R1gPostBuildHardwareBindings.ps1')
)) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    Add-Result ("POWERSHELL_PARSE_{0}" -f (Split-Path -Leaf $path).ToUpperInvariant()) ($errors.Count -eq 0) (($errors | ForEach-Object Message) -join ' | ')
}

$programTcl = [IO.File]::ReadAllText($script:R1gAcceptedTools.ModeAwareObserverTcl.Path)
$observerParser = [IO.File]::ReadAllText($script:R1gAcceptedTools.ProgramObserverParser.Path)
$reconfirmTcl = [IO.File]::ReadAllText($script:R1gAcceptedTools.JtagReconfirmationTcl.Path)
Add-Result PROGRAM_HW_DEVICES_EXACTLY_ONE ([regex]::Matches($programTcl,'(?m)^\s*program_hw_devices\b').Count -eq 1) 'accepted mode-aware Tcl contains one anchored program command'
Add-Result VENDOR_STARTUP_HIGH_GATE ($observerParser.Contains('Labtools 27-3164',[StringComparison]::Ordinal) -and $observerParser.Contains('End of startup status:\s*HIGH',[StringComparison]::Ordinal)) 'accepted parser hash-binds exact vendor startup HIGH'
Add-Result SAME_SESSION_DONE_BIT5_GATE ([regex]::Matches($programTcl,'get_property\s+\$bit5_property').Count -ge 1) 'same-session REGISTER.IR.BIT5_DONE is read after programming'
Add-Result BIT4_EOS_NOT_QUERIED ([regex]::Matches($programTcl,'get_property\s+\$bit4_property').Count -eq 0) 'REGISTER.IR.BIT4_EOS is never queried'
Add-Result JTAG_FREQUENCY_UNCHANGED ([regex]::Matches($programTcl,'(?im)^\s*set_property\s+[^\r\n]*(?:FREQUENCY|JTAG_FREQUENCY)').Count -eq 0) 'no frequency-changing set_property exists'
Add-Result START_JTAG_READ_ONLY (-not [regex]::IsMatch($reconfirmTcl,'(?m)^\s*(?:program_hw_devices|set_property)\b')) 'fresh start-state JTAG reconfirmation has no write/program path'
Add-Result START_JTAG_FIVE_SAMPLES $reconfirmTcl.Contains('set sample_count 5',[StringComparison]::Ordinal) 'exact five-sample stable-DONE gate retained'

$programWrapper = [IO.File]::ReadAllText((Join-Path $toolRoot 'Invoke-R1gProgramOnce.ps1'))
Add-Result WRAPPER_DIRECT_PROGRAM_ABSENT (-not $programWrapper.Contains('program_hw_devices',[StringComparison]::Ordinal)) 'only the exact accepted Tcl leaf may program'
Add-Result IMMUTABLE_PROGRAM_RESERVATION ($programWrapper.Contains('PROGRAM_ATTEMPT_RESERVATION.txt',[StringComparison]::Ordinal) -and $programWrapper.Contains('PROGRAM_RETRY_AUTHORIZED=NO',[StringComparison]::Ordinal)) 'reservation precedes process launch and is never removed'
Add-Result ONE_PROGRAM_PROCESS_START ([regex]::Matches($programWrapper,'\$process\.Start\(\)').Count -eq 1) 'one supervisor process start with no restart loop'
Add-Result CONDITIONAL_BOOTSTRAP_MAX_ONE ($programWrapper.Contains('FORMAL_START_GATE=BOOTSTRAP_REQUIRED_SAFE',[StringComparison]::Ordinal) -and $programWrapper.Contains('conditional bootstrap is forbidden after an exact formal-start receipt already exists',[StringComparison]::Ordinal)) 'bootstrap is mutually exclusive with fresh existing-formal receipt'

$tokens = @('A1','B1','A2','B2','A3','B3')
$specs = @($tokens | ForEach-Object { Get-R1gPhaseSpec $_ })
Add-Result FROZEN_SEQUENCE (($specs.Token -join ',') -ceq 'A1,B1,A2,B2,A3,B3') ($specs.Token -join ' -> ')
Add-Result ARM_A_WAIT_EXACT (@($specs | Where-Object Kind -eq ARM_A | Where-Object { [Math]::Abs($_.RequiredWaitFloorSeconds - 33.536673744) -gt 0.000000000001 }).Count -eq 0) 'A1/A2/A3 each freeze 33.536673744 seconds'
Add-Result FORMAL_WAIT_FLOOR (@($specs | Where-Object Kind -eq ARM_B | Where-Object RequiredWaitFloorSeconds -ne 5.0).Count -eq 0) 'B1/B2/B3 each freeze five seconds'
$allSpecs = @((Get-R1gPhaseSpec Bootstrap)) + $specs
Add-Result UNIQUE_LOCAL_EVIDENCE_DIRECTORIES (@($allSpecs.Directory | Select-Object -Unique).Count -eq 7) ($allSpecs.Directory -join '; ')
Add-Result UNIQUE_REMOTE_DRIVER_DIRECTORIES (@($allSpecs.RemoteDriverAbsolutePath | Select-Object -Unique).Count -eq 7) ($allSpecs.RemoteDriverAbsolutePath -join '; ')
Add-Result MAXIMA_SEVEN ($script:R1gMaximumPrograms -eq 7 -and $script:R1gMaximumWarmReboots -eq 7 -and $script:R1gMaximumDriverLoads -eq 7) 'one optional bootstrap plus six arms; each maximum is seven'

$commonText = [IO.File]::ReadAllText((Join-Path $toolRoot 'R1gCampaignCommon.ps1'))
Add-Result RECEIPT_CHAIN_FROZEN ($commonText.Contains("'A1' { return Join-Path `$script:R1gPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt' }",[StringComparison]::Ordinal) -and $commonText.Contains("'B3' { return Join-Path (Get-R1gPhaseSpec A3).Directory 'VALID_ARM_A_RECEIPT.txt' }",[StringComparison]::Ordinal)) 'A1 starts from formal receipt; B3 starts from A3 receipt'
Add-Result SOURCE_BIT_PROVENANCE_FAIL_CLOSED ($commonText.Contains('R1g bit/source provenance fields disagree',[StringComparison]::Ordinal) -and $commonText.Contains('R1g source commit/tree binding is unresolved',[StringComparison]::Ordinal)) 'active binding must bind identical source commit/tree at document and bit levels'
Add-Result EXACT_BIT_FILENAME_AND_SIZE ($commonText.Contains('ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit',[StringComparison]::Ordinal) -and $commonText.Contains('[long]$document.r1gBit.bytes -ne 2192144L',[StringComparison]::Ordinal)) 'exact R1g bit filename and byte count are gated'

$telemetry = [IO.File]::ReadAllText((Join-Path $toolRoot 'Invoke-R1gTelemetryReadOnly.ps1'))
Add-Result TWO_COHERENT_SNAPSHOTS ($telemetry.Contains('--twice --delay 1.0',[StringComparison]::Ordinal) -and $telemetry.Contains('STATIC_SNAPSHOTS_MATCH=YES',[StringComparison]::Ordinal)) 'full reader collects and compares T0/T1'
Add-Result INHERITED_R1F_READER_ABI ($telemetry.Contains("`$expect=if(`$phase.Image-ceq'R1G'){'r1f'}else{'formal'}",[StringComparison]::Ordinal)) 'R1g preserves exact R1f map/reader expectation literal'
Add-Result RUNTIME_SOURCE_COMMIT_GATE ($telemetry.Contains('$binding.r1gSourceCommit',[StringComparison]::Ordinal) -and $telemetry.Contains('RUNTIME_PROVENANCE_GATE=PASS',[StringComparison]::Ordinal)) 'each R1g Arm-A validates runtime Git words and BUILD_FLAGS before full telemetry'

$readerText = [IO.File]::ReadAllText($r1gReader)
Add-Result FORMAL_COMPLETE_RANGE_ZERO ($readerText.Contains('R1F_FIRST = 0x20A0',[StringComparison]::Ordinal) -and $readerText.Contains('R1F_END_EXCLUSIVE = 0x3600',[StringComparison]::Ordinal) -and $readerText.Contains('formal image did not return deterministic zero across 0x20A0..0x35FF',[StringComparison]::Ordinal)) 'exact formal reader covers every aligned word 0x20A0..0x35FC'
Add-Result READER_MMIO_READ_ONLY ($readerText.Contains('os.O_RDONLY | os.O_CLOEXEC',[StringComparison]::Ordinal) -and -not [regex]::IsMatch($readerText,'\bos\.(?:pwrite|write)\s*\(')) 'reader opens O_RDONLY and exposes no write primitive'

$runtimeLeafText = [IO.File]::ReadAllText($script:R1gAcceptedTools.RuntimeProvenancePayload.Path)
Add-Result RUNTIME_LEAF_READ_ONLY ($runtimeLeafText.Contains('os.O_RDONLY | os.O_CLOEXEC',[StringComparison]::Ordinal) -and $runtimeLeafText.Contains('os.pread',[StringComparison]::Ordinal) -and -not [regex]::IsMatch($runtimeLeafText,'\bos\.(?:pwrite|write)\s*\(')) 'supplementary provenance and formal-zero leaf is O_RDONLY/pread only'
Add-Result RUNTIME_LEAF_EXACT_PROVENANCE ($runtimeLeafText.Contains('R1g source-commit provenance mismatch',[StringComparison]::Ordinal) -and $runtimeLeafText.Contains('build_flags != 0x00000002',[StringComparison]::Ordinal)) 'R1g Git words and BUILD_FLAGS=2 are strict'
Add-Result RUNTIME_LEAF_FORMAL_ZERO ($runtimeLeafText.Contains('range(0x20A0, 0x3600, 4)',[StringComparison]::Ordinal)) 'supplementary formal gate independently reads the complete R1f/R1g range'

$adapterRows = Import-Csv -LiteralPath (Join-Path $precheckRoot 'R1G_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv')
Add-Result REMOTE_DIRECTORY_ADAPTER_MATRIX ($adapterRows.Count -eq 8 -and @($adapterRows | Where-Object { $_.semantic_change -notlike 'NONE_OUTSIDE_*' }).Count -eq 0) 'one start block and seven phase-specific directory-only adaptations'
$hostStep = [IO.File]::ReadAllText((Join-Path $toolRoot 'Invoke-R1gHostStep.ps1'))
$startSafety = [IO.File]::ReadAllText((Join-Path $precheckRoot 'Invoke-R1gStartSafetyReadOnly.ps1'))
$adapterHashesPresent = $true
foreach ($row in $adapterRows) {
    if ($row.phase_token -ceq 'START') { $adapterHashesPresent = $adapterHashesPresent -and $startSafety.Contains($row.adapted_sha256,[StringComparison]::Ordinal) }
    else { $adapterHashesPresent = $adapterHashesPresent -and $hostStep.Contains($row.adapted_sha256,[StringComparison]::Ordinal) }
}
Add-Result REMOTE_ADAPTER_HASHES_FROZEN $adapterHashesPresent 'each adapted payload hash is embedded in its fail-closed wrapper'

$templatePath = Join-Path $toolRoot 'R1G_HARDWARE_BINDINGS.template.json'
$template = Get-Content -Raw -LiteralPath $templatePath | ConvertFrom-Json -Depth 20
$templatePending = ($template.status -ceq 'PENDING_R1G_BUILD' -and $template.r1gBit.bytes -eq 0 -and $template.r1gBit.sha256 -ceq 'PENDING_ONE_CLEAN_BUILD' -and $template.r1gSourceCommit -ceq 'PENDING_ONE_R1G_SOURCE_COMMIT' -and [double]$template.r1gBit.requiredWaitSeconds -eq 33.536673744)
Add-Result TEMPLATE_FAILS_CLOSED $templatePending 'commit/tree/bit/selected-full-path remain unresolved; modeled wait is frozen'

$bindingStatus = 'PENDING_R1G_COMMIT_AND_BUILD'
if (Test-Path -LiteralPath $BindingPath -PathType Leaf) {
    try {
        [void](Get-R1gBindingDocument -BindingPath $BindingPath)
        $bindingStatus = 'PASS_FROZEN_FOR_HARDWARE'
        Add-Result FROZEN_HARDWARE_BINDINGS $true $BindingPath
    } catch {
        $bindingStatus = 'FAIL'
        Add-Result FROZEN_HARDWARE_BINDINGS $false $_.Exception.Message
    }
} else {
    Add-Result FROZEN_HARDWARE_BINDINGS (-not $RequireFrozenHardwareBindings) 'active binding intentionally absent until the one R1g source commit and one clean build pass'
}

$failed = @($results | Where-Object Result -ne PASS)
$gate = if ($failed.Count) { 'FAIL' } elseif ($bindingStatus -ceq 'PASS_FROZEN_FOR_HARDWARE') { 'PASS_READY_FOR_SEPARATE_LIVE_PRECHECK' } else { 'PASS_OFFLINE_BINDING_PENDING' }
$results | ForEach-Object { "GATE=$($_.Gate) RESULT=$($_.Result) DETAIL=$($_.Detail)" }
"STATIC_AUDIT_GATE=$gate"
"HARDWARE_BINDING_STATUS=$bindingStatus"
'LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0'
if ($gate -ceq 'FAIL') { exit 1 }
