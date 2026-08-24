[CmdletBinding()]
param(
    [string]$BindingPath = 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\R1F_HARDWARE_BINDINGS.json',
    [switch]$RequireFrozenHardwareBindings
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$toolRoot='C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS'
. (Join-Path $toolRoot 'R1fCampaignCommon.ps1')

$results=[Collections.Generic.List[object]]::new()
function Add-Result([string]$Gate,[bool]$Pass,[string]$Detail) {
    $results.Add([pscustomobject]@{Gate=$Gate;Result=$(if($Pass){'PASS'}else{'FAIL'});Detail=$Detail})
}

try { Assert-R1fAcceptedToolSet; Add-Result ACCEPTED_R7_TOOL_HASHES $true 'all exact path/byte/SHA-256 gates pass' }
catch { Add-Result ACCEPTED_R7_TOOL_HASHES $false $_.Exception.Message }

$programTcl=[IO.File]::ReadAllText($script:R1fAcceptedTools.ModeAwareObserverTcl.Path)
$observerParser=[IO.File]::ReadAllText($script:R1fAcceptedTools.ProgramObserverParser.Path)
Add-Result PROGRAM_HW_DEVICES_EXACT_COUNT ([regex]::Matches($programTcl,'(?m)^\s*program_hw_devices\b').Count-eq1) 'accepted observer contains exactly one anchored program_hw_devices command'
Add-Result VENDOR_STARTUP_HIGH_PARSER_FROZEN ($observerParser.Contains('Labtools 27-3164',[StringComparison]::Ordinal)-and$observerParser.Contains('End of startup status:\s*HIGH',[StringComparison]::Ordinal)) 'exact accepted parser SHA binds the vendor HIGH gate'
Add-Result SAME_SESSION_BIT5_DONE_GATE ([regex]::Matches($programTcl,'get_property\s+\$bit5_property').Count-ge1) 'accepted observer reads REGISTER.IR.BIT5_DONE after program'
Add-Result BIT4_EOS_QUERY_ABSENT ([regex]::Matches($programTcl,'get_property\s+\$bit4_property').Count-eq0) 'BIT4_EOS is never queried'
Add-Result JTAG_FREQUENCY_CHANGE_ABSENT ([regex]::Matches($programTcl,'(?im)^\s*set_property\s+[^\r\n]*(?:FREQUENCY|JTAG_FREQUENCY)').Count-eq0) 'accepted observer does not set JTAG frequency'
Add-Result SELECTED_TARGET_EXACT ($programTcl.Contains('Xilinx/80802026a98b01',[StringComparison]::Ordinal)) 'selected canonical target is exact'
$reconfirmTcl=[IO.File]::ReadAllText($script:R1fAcceptedTools.JtagReconfirmationTcl.Path)
Add-Result START_JTAG_RECONFIRMATION_READ_ONLY (-not[regex]::IsMatch($reconfirmTcl,'(?m)^\s*(?:program_hw_devices|set_property)\b')) 'exact inherited five-sample reconfirmation Tcl has zero programming/property writes'
Add-Result START_JTAG_RECONFIRMATION_SAMPLE_COUNT ($reconfirmTcl.Contains('set sample_count 5',[StringComparison]::Ordinal)) 'five fresh readable/stable DONE samples are required by the outer R1f gate'

$wrapperNames=@(
    'Initialize-R1fCampaignEvidenceDirectories.ps1','Invoke-R1fProgramOnce.ps1',
    'Invoke-R1fIndependentDoneReadOnly.ps1','Wait-R1fProgramMinimum.ps1',
    'Invoke-R1fHostStep.ps1','Invoke-R1fTelemetryReadOnly.ps1',
    'New-R1fConfiguredImageReceipt.ps1','R1fCampaignCommon.ps1'
)
foreach($name in $wrapperNames) {
    $path=Join-Path $toolRoot $name
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    Add-Result("POWERSHELL_PARSE_{0}"-f$name.ToUpperInvariant()) ($errors.Count-eq0) (($errors|ForEach-Object Message)-join ' | ')
}
$precheckNames=@(
    'Invoke-R1fHostBaselineReadOnly.ps1','Invoke-R1fPrecheckJtagDoneReadOnly.ps1',
    'Invoke-R1fStartSafetyReadOnly.ps1','Invoke-R1fExistingFormalTelemetryReadOnly.ps1',
    'Finalize-R1fFreshFormalStartGate.ps1','New-R1fExistingFormalStartReceipt.ps1'
)
foreach($name in $precheckNames) {
    $path=Join-Path $script:R1fPrecheckRoot $name
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    Add-Result("POWERSHELL_PARSE_{0}"-f$name.ToUpperInvariant()) ($errors.Count-eq0) (($errors|ForEach-Object Message)-join ' | ')
}
$programWrapper=[IO.File]::ReadAllText((Join-Path $toolRoot 'Invoke-R1fProgramOnce.ps1'))
Add-Result WRAPPER_HAS_NO_DIRECT_PROGRAM_COMMAND (-not$programWrapper.Contains('program_hw_devices',[StringComparison]::Ordinal)) 'only exact accepted Tcl can issue programming'
Add-Result IMMUTABLE_ATTEMPT_RESERVATION ($programWrapper.Contains('PROGRAM_ATTEMPT_RESERVATION.txt',[StringComparison]::Ordinal)-and$programWrapper.Contains('PROGRAM_RETRY_AUTHORIZED=NO',[StringComparison]::Ordinal)) 'reservation is written before the one process launch and never removed'
Add-Result ONE_PROGRAM_PROCESS_START ([regex]::Matches($programWrapper,'\$process\.Start\(\)').Count-eq1) 'one supervisor process start and no restart/retry call'
Add-Result CONDITIONAL_BOOTSTRAP_GATE ($programWrapper.Contains('FORMAL_START_GATE=BOOTSTRAP_REQUIRED_SAFE',[StringComparison]::Ordinal)-and$programWrapper.Contains('conditional bootstrap is forbidden after an exact formal-start receipt already exists',[StringComparison]::Ordinal)) 'bootstrap cannot run after existing formal proof and requires the fresh safe-bootstrap classification'
$allWrapperText=(($wrapperNames|ForEach-Object{[IO.File]::ReadAllText((Join-Path $toolRoot $_))})-join"`n")
Add-Result FORBIDDEN_PCIE_AND_MODULE_SHORTCUTS_ABSENT (-not[regex]::IsMatch($allWrapperText,'(?i)\b(?:modprobe\s+xdma|driver_override|remove/rescan|setpci)\b')) 'no alternate module selection, driver override, PCI remove/rescan, or setpci path'
Add-Result MAXIMA_FROZEN_IN_COMMON ($allWrapperText.Contains('R1fMaximumPrograms = 7',[StringComparison]::Ordinal)-and$allWrapperText.Contains('R1fMaximumWarmReboots = 7',[StringComparison]::Ordinal)-and$allWrapperText.Contains('R1fMaximumDriverLoads = 7',[StringComparison]::Ordinal)) 'program/reboot/load maxima are each seven with one optional bootstrap plus six arms'

$tokens=@('A1','B1','A2','B2','A3','B3')
$actual=@($tokens|ForEach-Object{(Get-R1fPhaseSpec $_).Token})
Add-Result FROZEN_PAIR_SEQUENCE (($actual-join',')-ceq'A1,B1,A2,B2,A3,B3') ($actual-join' -> ')
$directories=@('Bootstrap','A1','B1','A2','B2','A3','B3'|ForEach-Object{(Get-R1fPhaseSpec $_).Directory})
$remote=@('Bootstrap','A1','B1','A2','B2','A3','B3'|ForEach-Object{(Get-R1fPhaseSpec $_).RemoteDriverAbsolutePath})
Add-Result UNIQUE_LOCAL_EVIDENCE_DIRECTORIES ((@($directories|Select-Object -Unique).Count)-eq7) ($directories-join'; ')
Add-Result UNIQUE_REMOTE_DRIVER_DIRECTORIES ((@($remote|Select-Object -Unique).Count)-eq7) ($remote-join'; ')
$adapterAudit=Import-Csv -LiteralPath (Join-Path $script:R1fPrecheckRoot 'R1F_REMOTE_DIRECTORY_ADAPTER_AUDIT.csv')
Add-Result PRELOADER_DIRECTORY_ADAPTER_MATRIX ($adapterAudit.Count-eq8-and@($adapterAudit|Where-Object semantic_change -ne 'NONE_OUTSIDE_SELECTED_DIRECTORY_LITERAL'|Where-Object phase_token -ne 'START').Count-eq0) 'one start block plus seven phase-specific directory-only adaptations are frozen'
Add-Result PREBOOTSTRAP_ADAPTED_PAYLOAD_SHA (($adapterAudit|Where-Object phase_token -eq 'START').adapted_sha256-ceq'98B776EDF8FEDD8638F71FCAF908D797EF3218938CF79B83A1DFBD6BF0B3EE05') 'three stale R7 paths are replaced by the seven fresh R1f paths; all other payload bytes are retained'

$r7CollisionFiles=@(
    'Run-ProgramOnceModeAware.ps1','Invoke-R7WarmRebootOnce.ps1','Wait-R7HostCycle.ps1',
    'Invoke-R7RemoteValidator.ps1','Invoke-R7ExactPinnedLoaderOnce.ps1','Invoke-R7TelemetryReadOnly.ps1',
    'New-R7ConfiguredImageReceipt.ps1'
)
$directCalls=0
foreach($wrapper in $wrapperNames) {
    $text=[IO.File]::ReadAllText((Join-Path $toolRoot $wrapper))
    foreach($legacy in $r7CollisionFiles){$directCalls += [regex]::Matches($text,[regex]::Escape($legacy)).Count}
}
foreach($wrapper in $precheckNames) {
    $text=[IO.File]::ReadAllText((Join-Path $script:R1fPrecheckRoot $wrapper))
    foreach($legacy in $r7CollisionFiles){$directCalls += [regex]::Matches($text,[regex]::Escape($legacy)).Count}
}
Add-Result R7_HARDCODED_WRAPPER_COLLISION_AVOIDED ($directCalls-eq0) 'R7 orchestration wrappers are not invoked directly; only hash-bound leaf tools/payloads are reused'

$templatePath=Join-Path $toolRoot 'R1F_HARDWARE_BINDINGS.template.json'
$template=Get-Content -Raw -LiteralPath $templatePath|ConvertFrom-Json
Add-Result TEMPLATE_FAILS_CLOSED ($template.status-cne'FROZEN_FOR_HARDWARE'-and$template.r1fBit.bytes-eq0-and$template.r1fReader.bytes-gt0) 'reader is hash-bound, while unresolved R1f bit/build fields keep the template fail-closed'
Add-Result R1F_READER_HASH_BOUND ($template.r1fReader.bytes-eq46868-and$template.r1fReader.sha256-ceq'5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C') 'fixture-passed read_nvp_r1f.py is bound by exact size and SHA-256'

$bindingStatus='PENDING_R1F_BUILD'
if(Test-Path -LiteralPath $BindingPath -PathType Leaf) {
    try{[void](Get-R1fBindingDocument -BindingPath $BindingPath);$bindingStatus='PASS_FROZEN_FOR_HARDWARE';Add-Result FROZEN_HARDWARE_BINDINGS $true $BindingPath}
    catch{$bindingStatus='FAIL';Add-Result FROZEN_HARDWARE_BINDINGS $false $_.Exception.Message}
} else {
    Add-Result FROZEN_HARDWARE_BINDINGS (-not$RequireFrozenHardwareBindings) 'active binding file intentionally absent until the one clean build passes and its exact bit/wait fields are frozen'
}

$failed=@($results|Where-Object Result -ne 'PASS')
$gate=if($failed.Count-eq0){if($bindingStatus-eq'PASS_FROZEN_FOR_HARDWARE'){'PASS_READY_FOR_SEPARATE_LIVE_PRECHECK'}else{'PASS_OFFLINE_TOOLING_BINDING_PENDING'}}else{'FAIL'}
$results|ForEach-Object{"GATE=$($_.Gate) RESULT=$($_.Result) DETAIL=$($_.Detail)"}
"STATIC_AUDIT_GATE=$gate"
"HARDWARE_BINDING_STATUS=$bindingStatus"
'LIVE_SSH_JTAG_PROGRAM_REBOOT_MMIO_ACTIONS=0'
if($gate-eq'FAIL'){exit 1}
