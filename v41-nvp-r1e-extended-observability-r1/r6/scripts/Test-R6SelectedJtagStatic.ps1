[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$acceptedObserver = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\program_once_startup_high_done.tcl'
$acceptedParser = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\ProgramObserverCommon.ps1'
$fixtureCsv = Join-Path $taskRoot '02_TARGET_SELECTOR\TARGET_SELECTOR_FIXTURE_RESULTS_FINAL.csv'

$paths = [ordered]@{
    Selector = Join-Path $taskRoot 'scripts\select_r6_jtag_target.tcl'
    Fixture = Join-Path $taskRoot 'scripts\test_select_r6_jtag_target.tcl'
    ProgramAdapter = Join-Path $taskRoot 'scripts\program_once_startup_high_done_r6_selected.tcl'
    IndependentDone = Join-Path $taskRoot 'scripts\read_jtag_identity_done_r6_selected.tcl'
    StabilityTcl = Join-Path $taskRoot 'scripts\r6_jtag_stability_session.tcl'
    StabilitySupervisor = Join-Path $taskRoot 'scripts\Invoke-R6SelectedJtagStability.ps1'
}

$expectedHashes = [ordered]@{
    Selector = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
    Fixture = '28F41BD71E51AF5ED537841B066413C483EA405C3588706EC7328B4547119DD8'
    ProgramAdapter = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
    IndependentDone = 'A1D967C7306F0C751DC5A41DE3A3D331A0CE92E36BB9430C7D99604FC8432D30'
    StabilityTcl = '7CDA6928B3480802E8C47C156641B4BA3C5488D32702ED95A2EDAF281383D62E'
    StabilitySupervisor = '2C908B0152B2E58192C10F856ACB90446C2491152D65FE214C7E828134079AC0'
}

$acceptedObserverSha = '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653'
$acceptedParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
$canonicalId = 'Xilinx/80802026a98b01'
$fullTargetPath = 'localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Read-Normalized([string]$Path) {
    return [IO.File]::ReadAllText($Path).Replace("`r`n", "`n").Replace("`r", "`n")
}

function Count-Lines([string]$Text, [string]$Pattern) {
    return [regex]::Matches($Text, $Pattern).Count
}

function Normalize-Observer([string]$Path, [bool]$Candidate) {
    $text = Read-Normalized $Path
    if ($Candidate) {
        $text = [regex]::Replace($text, '(?m)^source \[file join \[file dirname \[info script\]\] select_r6_jtag_target\.tcl\]\n\n', '')
        $text = [regex]::Replace($text, '(?m)^set expected_r6_full_target_path .*\n', '')
        $text = [regex]::Replace($text, '(?m)^  r6_target::record_object_properties R6_SELECTED_DEVICE \$dev\n', '')
    } else {
        $text = [regex]::Replace($text, '(?m)^set intended_target .*\n', '')
        $text = [regex]::Replace($text, '(?m)^set expected_hs2_serial .*\n', '')
    }
    $text = [regex]::Replace(
        $text,
        '(?s)(  connect_hw_server\n).*?(\n  set devices)',
        '$1  # TARGET_SELECTION_LAYER$2'
    )
    return $text.TrimEnd() + "`n"
}

Assert-True ((Resolve-Path -LiteralPath $taskRoot).Path -ceq $taskRoot) 'unexpected R6 task-root resolution'
foreach ($entry in $paths.GetEnumerator()) {
    Assert-True (Test-Path -LiteralPath $entry.Value -PathType Leaf) "missing $($entry.Key): $($entry.Value)"
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Value).Hash
    Assert-True ($actual -ceq $expectedHashes[$entry.Key]) "$($entry.Key) SHA-256 mismatch: $actual"
}
Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $acceptedObserver).Hash -ceq $acceptedObserverSha) 'accepted R5 observer SHA-256 mismatch'
Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $acceptedParser).Hash -ceq $acceptedParserSha) 'accepted observer parser SHA-256 mismatch'

$fixtureRows = @(Import-Csv -LiteralPath $fixtureCsv)
Assert-True ($fixtureRows.Count -eq 8) "fixture result count is $($fixtureRows.Count), expected 8"
Assert-True ((@($fixtureRows | Where-Object result -cne 'PASS')).Count -eq 0) 'one or more selector fixtures failed'
Assert-True (($fixtureRows.fixture -join ',') -ceq 'A,B,C,D,E,F,G,H') 'selector fixture identifiers are not exactly A..H'

$selector = Read-Normalized $paths.Selector
$program = Read-Normalized $paths.ProgramAdapter
$independentDone = Read-Normalized $paths.IndependentDone
$stability = Read-Normalized $paths.StabilityTcl
$supervisor = Read-Normalized $paths.StabilitySupervisor

Assert-True ($selector.Contains("variable canonical_id {$canonicalId}")) 'canonical target ID is absent from selector'
Assert-True ($selector.Contains('variable canonical_suffix {/Xilinx/80802026a98b01}')) 'exact canonical suffix is absent from selector'
Assert-True ($selector.Contains('if {$total_count != 1}')) 'selector total-target-count gate is absent'
Assert-True ($selector.Contains('R6_FALLBACK_TO_FIRST_TARGET NO')) 'selector no-fallback receipt is absent'
Assert-True (-not $selector.Contains('lindex $targets 0')) 'selector contains a first-target fallback expression'
Assert-True ($selector.Contains('record_object_properties R6_ENUMERATED_TARGET_')) 'selector does not record every enumerated target property set'

$readOnlyText = $selector + "`n" + $independentDone + "`n" + $stability
$forbiddenReadOnly = @(
    '(?im)^\s*program_hw_devices\b',
    '(?im)^\s*set_property\b',
    '(?im)^\s*write_(?:bitstream|cfgmem|checkpoint)\b',
    '(?im)^\s*create_hw_(?:bitstream|cfgmem)\b',
    '(?im)^\s*commit_hw_\w+\b',
    '(?im)^\s*(?:synth_design|opt_design|place_design|phys_opt_design|route_design)\b'
)
foreach ($pattern in $forbiddenReadOnly) {
    Assert-True (-not [regex]::IsMatch($readOnlyText, $pattern)) "read-only mutation pattern present: $pattern"
}
Assert-True (-not [regex]::IsMatch($readOnlyText, '(?im)^\s*set_property\s+.*FREQ')) 'read-only scripts can change JTAG frequency'

Assert-True ($stability.Contains("set expected_full_target_path {$fullTargetPath}")) 'stability Tcl full-path gate is absent'
Assert-True ($stability.Contains('set sample_count 5')) 'stability sample count is not fixed at five'
Assert-True ($stability.Contains('set inter_sample_delay_ms 500')) 'stability interval is not fixed at 500 ms'
Assert-True ($stability.Contains('if {$done ni {0 1}}')) 'stability DONE-readable 0/1 gate is absent'
Assert-True ($supervisor.Contains("`$expectedFullTargetPath = '$fullTargetPath'")) 'stability supervisor full-path gate is absent'
Assert-True ($supervisor.Contains('for ($sessionIndex = 1; $sessionIndex -le 2; $sessionIndex++)')) 'supervisor does not run exactly sessions 1 and 2'
Assert-True ($supervisor.Contains("`$doneValues.Count -ne 1")) 'cross-session stable-DONE gate is absent'
Assert-True ($supervisor.Contains('aggregate evidence path must be fresh')) 'aggregate freshness gate is absent'
Assert-True ($supervisor.Contains('session evidence path must be fresh')) 'per-session freshness gate is absent'

Assert-True ($independentDone.Contains("set expected_full_target_path {$fullTargetPath}")) 'independent-DONE full-path gate is absent'
Assert-True ((Count-Lines $independentDone '(?m)^\s*refresh_hw_device\s+\$dev\s*$') -eq 1) 'independent-DONE script does not contain exactly one refresh'
Assert-True ($independentDone.Contains('if {$done ne {1}}')) 'independent-DONE value==1 gate is absent'
Assert-True ($independentDone.Contains('FPGA_PROGRAM_OPERATIONS_THIS_SCRIPT 0')) 'independent-DONE zero-program receipt is absent'

Assert-True ((Count-Lines $program '(?m)^\s*program_hw_devices\s+\$dev\s*$') -eq 1) 'program adapter must contain exactly one program_hw_devices command'
Assert-True ((Count-Lines $program '(?m)^\s*set_property\s+PROGRAM\.FILE\s+\$bitfile\s+\$dev\s*$') -eq 1) 'program adapter must contain exactly one PROGRAM.FILE assignment'
Assert-True ($program.Contains("set expected_r6_full_target_path {$fullTargetPath}")) 'program adapter full-path gate is absent'
Assert-True ($program.Contains('if {$preprogram_done ne "1"}')) 'accepted pre-program DONE==1 gate was not preserved'
Assert-True ($program.Contains('PROGRAM_TCL_RESULT FAIL_NO_RETRY')) 'program adapter no-retry failure receipt is absent'
Assert-True (-not [regex]::IsMatch($program, '(?im)^\s*set_property\s+.*FREQ')) 'program adapter changes JTAG frequency'
Assert-True ((Normalize-Observer $acceptedObserver $false) -ceq (Normalize-Observer $paths.ProgramAdapter $true)) 'program observer changed outside selected-target adaptation/evidence layer'

$parseTokens = $null
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($paths.StabilitySupervisor, [ref]$parseTokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count -ne 0) {
    throw ('stability supervisor PowerShell parse errors: ' + ($parseErrors.Message -join '; '))
}

'R6_SELECTED_JTAG_STATIC_AUDIT=PASS'
'TARGET_SELECTOR_FIXTURES=PASS_8_OF_8'
'R6_SELECTED_JTAG_CANONICAL_ID=' + $canonicalId
'R6_FULL_JTAG_TARGET_PATH=' + $fullTargetPath
'FALLBACK_TO_FIRST_TARGET=NO'
'LEGACY_HS2_REQUIRED=NO'
'READ_ONLY_STABILITY_SESSIONS_CONFIGURED=2'
'READ_ONLY_REFRESH_SAMPLES_PER_SESSION=5'
'READ_ONLY_JTAG_PROGRAM_COMMANDS=0'
'READ_ONLY_JTAG_FREQUENCY_CHANGE_COMMANDS=0'
'PROGRAM_ADAPTER_PROGRAM_HW_DEVICES_COUNT=1'
'PROGRAM_ADAPTER_PROGRAM_FILE_ASSIGNMENT_COUNT=1'
'PROGRAM_ADAPTER_NORMALIZED_DIFF=TARGET_SELECTION_AND_PROPERTY_EVIDENCE_ONLY'
'PREPROGRAM_DONE_GATE_PRESERVED=YES'
'INDEPENDENT_DONE_REFRESH_COUNT=1'
'INDEPENDENT_DONE_PROGRAM_COMMANDS=0'
'LIVE_JTAG_OR_VIVADO_EXECUTED_BY_STATIC_AUDIT=NO'
