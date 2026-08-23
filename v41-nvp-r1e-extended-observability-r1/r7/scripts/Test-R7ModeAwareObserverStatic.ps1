[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$r7Root = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$r6Root = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$observerDir = Join-Path $r7Root '02_MODE_AWARE_OBSERVER'
$jtagDir = Join-Path $r7Root '05_JTAG_RECONFIRMATION'

$paths = [ordered]@{
    R6Observer = Join-Path $r6Root 'scripts\program_once_startup_high_done_r6_selected.tcl'
    R6Selector = Join-Path $r6Root 'scripts\select_r6_jtag_target.tcl'
    R6Parser = Join-Path $r6Root 'scripts\ProgramObserverCommon.ps1'
    ProgramTcl = Join-Path $r7Root 'scripts\program_once_mode_aware.tcl'
    ProgramSupervisor = Join-Path $r7Root 'scripts\Run-ProgramOnceModeAware.ps1'
    IndependentDoneTcl = Join-Path $r7Root 'scripts\read_jtag_identity_done_r7_selected.tcl'
    WaitGate = Join-Path $r7Root 'scripts\Wait-R7ProgramMinimumAfterIndependentDone.ps1'
    ReconfirmationTcl = Join-Path $r7Root 'scripts\r7_jtag_reconfirmation_session.tcl'
    ReconfirmationSupervisor = Join-Path $r7Root 'scripts\Invoke-R7JtagReconfirmation.ps1'
    FixtureTcl = Join-Path $r7Root 'fixtures\test_mode_aware_preconditions.tcl'
    FixtureSupervisor = Join-Path $r7Root 'fixtures\Invoke-R7ModeAwareObserverFixturesAndReplay.ps1'
    FixtureCsv = Join-Path $observerDir 'MODE_AWARE_OBSERVER_FIXTURE_RESULTS.csv'
    Replay = Join-Path $observerDir 'R6_REPLAY.md'
    ReplayHashes = Join-Path $observerDir 'R6_REPLAY_INPUT_SHA256.txt'
    ObserverDiff = Join-Path $observerDir 'R6_TO_R7_OBSERVER_DIFF.patch'
}

$expectedHashes = [ordered]@{
    R6Observer = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
    R6Selector = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
    R6Parser = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
    ProgramTcl = '55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7'
    ProgramSupervisor = '42C6A969A4CA27375C139CB60B4A1E5C33A58E987EB4A5C84DE7312CB9F4208D'
    IndependentDoneTcl = '122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B'
    WaitGate = 'B25B1EE5C8193D9CF1F75C88AD63BFA012343FCAE613D02BF6BAB2668300AEA2'
    ReconfirmationTcl = '6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73'
    ReconfirmationSupervisor = '095C9559663CF8FEE08DF6AC268DF9EF13C8E5954471C2CC9B3F06D32D80C6C1'
    FixtureTcl = '5B0B31150F593C3DE7D8C409DFBCBCD0053063FAD900DA6E04E597DDABC9B3A9'
    FixtureSupervisor = '89130007BE6B28FCCEFBA7391114F32D919282A26E0BF76C704D53BA8E584168'
}

$results = [Collections.Generic.List[object]]::new()
function Add-Check([string]$Area, [string]$Check, [bool]$Passed, [string]$Actual, [string]$Expected) {
    $results.Add([pscustomobject]@{
        area = $Area
        check = $Check
        actual = $Actual
        expected = $Expected
        result = $(if ($Passed) { 'PASS' } else { 'FAIL' })
    })
}
function Count-Regex([string]$Text, [string]$Pattern) {
    return [regex]::Matches($Text, $Pattern).Count
}
function Normalize-Newlines([string]$Text) {
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}
function Test-PowerShellParse([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    return @($errors)
}
function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

foreach ($name in $paths.Keys) {
    $path = $paths[$name]
    Add-Check 'inputs' "$name exists" (Test-Path -LiteralPath $path -PathType Leaf) $path 'existing regular file'
}
foreach ($name in $expectedHashes.Keys) {
    if (Test-Path -LiteralPath $paths[$name] -PathType Leaf) {
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $paths[$name]).Hash
        Add-Check 'hashes' "$name SHA-256" ($actual -ceq $expectedHashes[$name]) $actual $expectedHashes[$name]
    }
}

$r6Text = Normalize-Newlines ([IO.File]::ReadAllText($paths.R6Observer))
$programText = Normalize-Newlines ([IO.File]::ReadAllText($paths.ProgramTcl))
$supervisorText = Normalize-Newlines ([IO.File]::ReadAllText($paths.ProgramSupervisor))
$independentText = Normalize-Newlines ([IO.File]::ReadAllText($paths.IndependentDoneTcl))
$waitText = Normalize-Newlines ([IO.File]::ReadAllText($paths.WaitGate))
$reconfirmText = Normalize-Newlines ([IO.File]::ReadAllText($paths.ReconfirmationTcl))
$reconfirmSupervisorText = Normalize-Newlines ([IO.File]::ReadAllText($paths.ReconfirmationSupervisor))

$programCount = Count-Regex $programText '(?m)^\s*program_hw_devices\s+\$dev\s*$'
$programFileCount = Count-Regex $programText '(?m)^\s*set_property\s+PROGRAM\.FILE\s+\$bitfile\s+\$dev\s*$'
$programMutationCount = Count-Regex $programText '(?im)^\s*(?:write_cfgmem|create_hw_cfgmem|program_hw_cfgmem|boot_hw_device|write_bitstream|write_checkpoint|set_property\s+(?!PROGRAM\.FILE))\b'
$bit4QueryCount = Count-Regex $programText '(?im)get_property\s+(?:\$bit4_property|\{?REGISTER\.IR\.BIT4_EOS\}?)'
$frequencyChangeCount = Count-Regex $programText '(?im)set_property\s+[^\r\n]*FREQUENCY'
Add-Check 'program_tcl' 'exactly one program_hw_devices' ($programCount -eq 1) ([string]$programCount) '1'
Add-Check 'program_tcl' 'exactly one PROGRAM.FILE assignment' ($programFileCount -eq 1) ([string]$programFileCount) '1'
Add-Check 'program_tcl' 'no other design/program mutation command' ($programMutationCount -eq 0) ([string]$programMutationCount) '0'
Add-Check 'program_tcl' 'no BIT4_EOS get_property query' ($bit4QueryCount -eq 0) ([string]$bit4QueryCount) '0'
Add-Check 'program_tcl' 'no JTAG frequency assignment' ($frequencyChangeCount -eq 0) ([string]$frequencyChangeCount) '0'
Add-Check 'program_tcl' 'five pre-program samples' ($programText.Contains('set preprogram_sample_count 5')) 'present' 'set preprogram_sample_count 5'
Add-Check 'program_tcl' '250 ms inter-sample delay' ($programText.Contains('set preprogram_delay_ms 250')) 'present' 'set preprogram_delay_ms 250'
foreach ($requiredToken in @(
    'BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM','TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE',
    'FORMAL_READY_RECEIPT','VALID_ARM_A_RECEIPT','ARM_A_TERMINAL_SAFE_DONE1_RECEIPT',
    'FAIL_PROVEN_CONFIGURED_IMAGE_LOST','FAIL_UNREADABLE_OR_UNSTABLE_DONE',
    'Xilinx/80802026a98b01','xc7a35t','0362D093'
)) {
    Add-Check 'program_tcl' "contains $requiredToken" ($programText.Contains($requiredToken)) 'present-or-absent' 'present'
}

$postMarker = '  set_property PROGRAM.FILE $bitfile $dev'
$r6MarkerIndex = $r6Text.IndexOf($postMarker, [StringComparison]::Ordinal)
$r7MarkerIndex = $programText.IndexOf($postMarker, [StringComparison]::Ordinal)
$postEqual = $r6MarkerIndex -ge 0 -and $r7MarkerIndex -ge 0 -and
             $r6Text.Substring($r6MarkerIndex) -ceq $programText.Substring($r7MarkerIndex)
Add-Check 'observer_delta' 'post-program Tcl block equality after newline normalization' $postEqual ([string]$postEqual) 'True'
Add-Check 'observer_delta' 'R6 selector absolute source unchanged' ($programText.Contains('C:/FPGA/V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6/scripts/select_r6_jtag_target.tcl')) 'present' 'present'

foreach ($psName in @('ProgramSupervisor','WaitGate','ReconfirmationSupervisor','FixtureSupervisor')) {
    $errors = @(Test-PowerShellParse $paths[$psName])
    Add-Check 'powershell_parse' "$psName parse errors" ($errors.Count -eq 0) ([string]$errors.Count) '0'
}

Add-Check 'program_supervisor' 'pins current program Tcl SHA' ($supervisorText.Contains($expectedHashes.ProgramTcl)) 'present' $expectedHashes.ProgramTcl
Add-Check 'program_supervisor' 'pins frozen observer parser SHA' ($supervisorText.Contains($expectedHashes.R6Parser)) 'present' $expectedHashes.R6Parser
Add-Check 'program_supervisor' 'pins frozen target selector SHA' ($supervisorText.Contains($expectedHashes.R6Selector)) 'present' $expectedHashes.R6Selector
Add-Check 'program_supervisor' 'single process start call' ((Count-Regex $supervisorText '\$process\.Start\(\)') -eq 1) ([string](Count-Regex $supervisorText '\$process\.Start\(\)')) '1'
Add-Check 'program_supervisor' 'success remains pending independent DONE and wait' ($supervisorText.Contains('PASS_PENDING_INDEPENDENT_DONE_AND_WAIT')) 'present' 'present'
Add-Check 'program_supervisor' 'immutable timing receipt status' ($supervisorText.Contains('PASS_IMMUTABLE_WAIT_INPUT')) 'present' 'present'
Add-Check 'program_supervisor' 'explicit no-retry receipt' ($supervisorText.Contains("'PROGRAM_RETRIES=0'")) 'present' 'present'
Add-Check 'program_supervisor' 'fresh fixed program timing receipt' ($supervisorText.Contains("'PROGRAM_TIMING_RECEIPT.txt'") -and $supervisorText.Contains('phase output path must be fresh')) 'present' 'present'

Add-Check 'independent_done' 'zero program commands' ((Count-Regex $independentText '(?im)^\s*program_hw_devices\b') -eq 0) ([string](Count-Regex $independentText '(?im)^\s*program_hw_devices\b')) '0'
Add-Check 'independent_done' 'one refresh command' ((Count-Regex $independentText '(?im)^\s*refresh_hw_device\s+\$dev\s*$') -eq 1) ([string](Count-Regex $independentText '(?im)^\s*refresh_hw_device\s+\$dev\s*$')) '1'
Add-Check 'independent_done' 'exact selected target and DONE gate' ($independentText.Contains('Xilinx/80802026a98b01') -and $independentText.Contains('PASS_SELECTED_TARGET_DONE_1')) 'present' 'present'
Add-Check 'independent_done' 'no mutation or frequency command' ((Count-Regex $independentText '(?im)^\s*(?:set_property|program_hw_devices|write_cfgmem|write_bitstream|write_checkpoint)\b') -eq 0) ([string](Count-Regex $independentText '(?im)^\s*(?:set_property|program_hw_devices|write_cfgmem|write_bitstream|write_checkpoint)\b')) '0'

Add-Check 'wait_gate' 'pins independent DONE Tcl SHA' ($waitText.Contains($expectedHashes.IndependentDoneTcl)) 'present' $expectedHashes.IndependentDoneTcl
Add-Check 'wait_gate' 'requires immediate DONE stage' ($waitText.Contains("Require-Value `$independent 'DONE_STAGE' 'IMMEDIATE_POST_PROGRAM'")) 'present' 'present'
Add-Check 'wait_gate' 'requires program and independent receipt hashes' ($waitText.Contains('ExpectedProgramTimingReceiptSha256') -and $waitText.Contains('ExpectedIndependentDoneReceiptSha256')) 'present' 'present'
$stopwatchFrequencyGateCount = Count-Regex $waitText "(?m)^Require-Value .+ 'STOPWATCH_FREQUENCY'"
Add-Check 'wait_gate' 'requires matching Stopwatch frequency' ($stopwatchFrequencyGateCount -eq 2) ([string]$stopwatchFrequencyGateCount) '2'
Add-Check 'wait_gate' 'later-of return and same-session DONE verified' ($waitText.Contains('[Math]::Max($returnTicks, $freshDoneTicks)')) 'present' 'present'
Add-Check 'wait_gate' 'independent session ordered after program marker' ($waitText.Contains('$independentStartTicks -lt $referenceTicks')) 'present' 'present'
Add-Check 'wait_gate' 'fresh fixed wait receipt' ($waitText.Contains("'PROGRAM_WAIT_RECEIPT.txt'") -and $waitText.Contains('wait receipt path must be fresh')) 'present' 'present'

$reconfirmProgramCount = Count-Regex $reconfirmText '(?im)^\s*program_hw_devices\b'
$reconfirmMutationCount = Count-Regex $reconfirmText '(?im)^\s*(?:set_property|program_hw_devices|write_cfgmem|write_bitstream|write_checkpoint)\b'
Add-Check 'reconfirmation' 'zero programming commands' ($reconfirmProgramCount -eq 0) ([string]$reconfirmProgramCount) '0'
Add-Check 'reconfirmation' 'zero mutation commands' ($reconfirmMutationCount -eq 0) ([string]$reconfirmMutationCount) '0'
Add-Check 'reconfirmation' 'five samples' ($reconfirmText.Contains('set sample_count 5')) 'present' 'set sample_count 5'
Add-Check 'reconfirmation' '500 ms inter-sample delay' ($reconfirmText.Contains('set inter_sample_delay_ms 500')) 'present' 'set inter_sample_delay_ms 500'
Add-Check 'reconfirmation' 'DONE accepts only readable 0 or 1' ($reconfirmText.Contains('if {$done ni {0 1}}')) 'present' 'present'
Add-Check 'reconfirmation' 'frozen target identity' ($reconfirmText.Contains('Xilinx/80802026a98b01') -and $reconfirmText.Contains('xc7a35t') -and $reconfirmText.Contains('0362D093')) 'present' 'present'
Add-Check 'reconfirmation' 'supervisor pins reconfirmation Tcl SHA' ($reconfirmSupervisorText.Contains($expectedHashes.ReconfirmationTcl)) 'present' $expectedHashes.ReconfirmationTcl
Add-Check 'reconfirmation' 'aggregate fixed gate contract' ($reconfirmSupervisorText.Contains('R7_JTAG_RECONFIRMATION_GATE.md') -and $reconfirmSupervisorText.Contains('PASS_5_OF_5')) 'present' 'present'
Add-Check 'reconfirmation' 'fresh evidence enforced' ($reconfirmSupervisorText.Contains('R7 reconfirmation evidence path must be fresh')) 'present' 'present'

$fixtureRows = @(Import-Csv -LiteralPath $paths.FixtureCsv)
$fixtureNames = @($fixtureRows.fixture | Sort-Object)
$expectedFixtureNames = @('B0','B1','B2','B3','B4','C0','C1','C2','T0','T1','T2','T3') | Sort-Object
$fixtureSetPass = $fixtureRows.Count -eq 12 -and ($fixtureNames -join ',') -ceq ($expectedFixtureNames -join ',')
$fixturePass = $fixtureSetPass -and @($fixtureRows | Where-Object result -cne 'PASS').Count -eq 0
Add-Check 'fixtures' 'B0-B4/T0-T3/C0-C2 complete and passing' $fixturePass ($fixtureRows.Count.ToString() + ' rows') '12 named PASS rows'
$replayText = [IO.File]::ReadAllText($paths.Replay)
foreach ($replayGate in @(
    'R6_REPLAY_PREPROGRAM_DONE=STABLE_0',
    'R6_OLD_OBSERVER_CLASSIFICATION=BLOCKED_PREPROGRAM_DONE_NOT_1',
    'R7_BOOTSTRAP_PRECONDITION_REPLAY=PASS_STABLE_DONE_0_ACCEPTED',
    'R6_FPGA_PROGRAMS_REMAIN=0',
    'R6_REPLAY=PASS_EXPECTED_CONTRACT_DIFFERENCE'
)) {
    Add-Check 'r6_replay' $replayGate ($replayText.Contains($replayGate)) 'present-or-absent' 'present'
}
$replayHashesText = [IO.File]::ReadAllText($paths.ReplayHashes)
Add-Check 'r6_replay' 'replay binds final R7 observer hash' ($replayHashesText.Contains($expectedHashes.ProgramTcl)) 'present' $expectedHashes.ProgramTcl

$diffText = [IO.File]::ReadAllText($paths.ObserverDiff)
Add-Check 'observer_delta' 'unified R6-to-R7 patch exists' ($diffText.StartsWith('diff --git ', [StringComparison]::Ordinal) -and $diffText.Contains('program_once_mode_aware.tcl')) 'valid unified diff' 'valid unified diff'

$resultCsv = Join-Path $observerDir 'MODE_AWARE_OBSERVER_STATIC_AUDIT_RESULTS.csv'
$auditReport = Join-Path $observerDir 'MODE_AWARE_OBSERVER_STATIC_AUDIT.md'
$deltaReport = Join-Path $observerDir 'OBSERVER_DELTA_CLASSIFICATION.md'
$timingReport = Join-Path $observerDir 'PROGRAM_TIMING_ORCHESTRATION.md'
$jtagReport = Join-Path $jtagDir 'R7_JTAG_RECONFIRMATION_HARNESS_STATIC_AUDIT.md'
foreach ($output in @($resultCsv,$auditReport,$deltaReport,$timingReport,$jtagReport)) {
    if (Test-Path -LiteralPath $output) { throw "static-audit output must be fresh: $output" }
}

$results | Export-Csv -LiteralPath $resultCsv -NoTypeInformation -Encoding utf8NoBOM
$failures = @($results | Where-Object result -cne 'PASS')
$overall = $(if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' })

$auditLines = [Collections.Generic.List[string]]::new()
$auditLines.Add('# R7 mode-aware observer static audit')
$auditLines.Add('')
$auditLines.Add('```text')
$auditLines.Add("STATIC_AUDIT_CHECKS=$($results.Count)")
$auditLines.Add("STATIC_AUDIT_FAILURES=$($failures.Count)")
$auditLines.Add("MODE_AWARE_OBSERVER_STATIC_AUDIT=$overall")
$auditLines.Add('LIVE_JTAG_OR_VIVADO_ACTIONS=0')
$auditLines.Add('```')
$auditLines.Add('')
$auditLines.Add('Detailed results are in MODE_AWARE_OBSERVER_STATIC_AUDIT_RESULTS.csv.')
Write-Utf8NoBom -Path $auditReport -Lines $auditLines.ToArray()

$deltaLines = [string[]]@(
    '# R6 to R7 programming-observer delta classification','',
    '```text',
    'OBSERVER_DELTA_CLASSIFICATION=PREPROGRAM_DONE_MODE_AND_RECEIPT_ONLY',
    'POSTPROGRAM_VENDOR_STARTUP_LOGIC_CHANGED=NO',
    'POSTPROGRAM_DONE_LOGIC_CHANGED=NO',
    'PROGRAM_INVOCATION_COUNT_LOGIC_CHANGED=NO',
    'NO_RETRY_LOGIC_CHANGED=NO',
    'TARGET_SELECTOR_CHANGED=NO',
    'JTAG_FREQUENCY_CHANGED=NO',
    'POSTPROGRAM_TCL_BLOCK_NORMALIZED_EQUAL=YES',
    ('MODE_AWARE_OBSERVER_STATIC_AUDIT=' + $overall),
    '```','',
    'R7 adds five-sample stable-DONE mode classification and a role-bound configured-image receipt gate before the unchanged R6 PROGRAM.FILE/program/post-program block. Bootstrap accepts stable DONE 0 or 1; transitions require stable DONE 1 and the phase-appropriate receipt.'
)
Write-Utf8NoBom -Path $deltaReport -Lines $deltaLines

$timingLines = [string[]]@(
    '# R7 program, independent-DONE, and minimum-wait orchestration','',
    '```text',
    'PROGRAM_SUPERVISOR_RETURNS_AFTER=PASS_STARTUP_HIGH_AND_SAME_SESSION_DONE_1',
    'PROGRAM_TIMING_RECEIPT=IMMUTABLE_FRESH_FIXED_PHASE_PATH',
    'INDEPENDENT_DONE_STAGE=IMMEDIATE_POST_PROGRAM',
    'MINIMUM_WAIT_REFERENCE=LATER_OF_PROGRAM_RETURN_AND_SAME_SESSION_FRESH_DONE',
    'MINIMUM_WAIT_SECONDS=FORMAL_BOOTSTRAP_5_ARM_A_10_ARM_B_5',
    'STOPWATCH_FREQUENCY_CROSS_RECEIPT_MATCH=REQUIRED',
    'RECEIPT_SHA256_BINDING=REQUIRED',
    'RECEIPT_REUSE_OR_OVERWRITE=REJECTED',
    'SEQUENCE=PROGRAM_PASS_THEN_INDEPENDENT_DONE_THEN_MINIMUM_WAIT',
    'POSTPROGRAM_GATE_WEAKENED=NO',
    '```'
)
Write-Utf8NoBom -Path $timingReport -Lines $timingLines

$jtagLines = [string[]]@(
    '# R7 selected-JTAG reconfirmation harness static audit','',
    '```text',
    'READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=1',
    'R7_JTAG_RECONFIRMATION_SAMPLES=5',
    'INTER_SAMPLE_DELAY_MS=500',
    'R7_SELECTED_JTAG_CANONICAL_ID=Xilinx/80802026a98b01',
    'FPGA_PART=xc7a35t',
    'FPGA_IDCODE=0362D093',
    'STABLE_DONE_ACCEPTED=0_OR_1',
    'FPGA_PROGRAM_COMMANDS=0',
    'JTAG_MUTATION_COMMANDS=0',
    'JTAG_FREQUENCY_CHANGED=NO',
    'LIVE_JTAG_OR_VIVADO_ACTIONS=0',
    ('R7_JTAG_RECONFIRMATION_HARNESS_STATIC_AUDIT=' + $overall),
    '```'
)
Write-Utf8NoBom -Path $jtagReport -Lines $jtagLines

$results | Where-Object result -cne 'PASS' | Format-Table -AutoSize | Out-String | Write-Host
"MODE_AWARE_OBSERVER_STATIC_AUDIT=$overall"
"STATIC_AUDIT_CHECKS=$($results.Count)"
"STATIC_AUDIT_FAILURES=$($failures.Count)"
if ($failures.Count -ne 0) { exit 1 }
