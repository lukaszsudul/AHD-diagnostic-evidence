[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$r7Root = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$r6Root = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$observerDir = Join-Path $r7Root '02_MODE_AWARE_OBSERVER'
$programTcl = Join-Path $r7Root 'scripts\program_once_mode_aware.tcl'
$preconditionFixtureTcl = Join-Path $r7Root 'fixtures\test_mode_aware_preconditions.tcl'
$tclsh = 'C:\AMDDesignTools\2025.2\Vivado\tps\win64\git-2.50.0\mingw64\bin\tclsh86.exe'
$parser = Join-Path $r6Root 'scripts\ProgramObserverCommon.ps1'
$r6Observer = Join-Path $r6Root 'scripts\program_once_startup_high_done_r6_selected.tcl'
$r6Matrix = Join-Path $r6Root '05_JTAG_STABILITY\JTAG_STABILITY_MATRIX.csv'
$r6Gate = Join-Path $r6Root '05_JTAG_STABILITY\JTAG_STABILITY_GATE.md'
$r6Ledger = Join-Path $r6Root 'OPERATION_LEDGER.md'
$r6Report = Join-Path $r6Root '11_FINAL\V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md'

$preconditionCsv = Join-Path $observerDir 'MODE_AWARE_PRECONDITION_FIXTURE_RESULTS.csv'
$combinedCsv = Join-Path $observerDir 'MODE_AWARE_OBSERVER_FIXTURE_RESULTS.csv'
$fixtureSummary = Join-Path $observerDir 'MODE_AWARE_OBSERVER_FIXTURES.md'
$replayPath = Join-Path $observerDir 'R6_REPLAY.md'
$replayHashes = Join-Path $observerDir 'R6_REPLAY_INPUT_SHA256.txt'

$expectedHashes = [ordered]@{
    Tclsh = '684E62BAFD4E8185EE6D95938BFAC4195C884DC94656A77828521EBC7B3B3FBA'
    Parser = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
    R6Observer = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
    R6Matrix = '295298541FDD1FC49884BA3445BE0C6CEA496B4E54C7303774FB8BFD0F0602BE'
    R6Gate = '4D76490860C2B86BBAC7CFA218EB00E42C7C2F670F0F1E36E69B62A97B5A2EFE'
    R6Ledger = '30EC11C8777C80A6BF7F7FA45C59EAE7AA69822BBBEA5BF338816089E8692C5D'
    R6Report = '9978358768EC0A12CEEDC89CC1C22705A2C92B662C9A595966300B3D1020F15E'
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

function Get-TranscriptResult([ValidateSet('Pass','StartupLow','DuplicateConsumed')][string]$Kind) {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('PROGRAM_INVOCATION_CONSUMED=1')
    if ($Kind -eq 'DuplicateConsumed') { $lines.Add('PROGRAM_INVOCATION_CONSUMED=1') }
    if ($Kind -eq 'StartupLow') {
        $lines.Add('[Labtools 27-3165] End of startup status: LOW')
        $lines.Add('PROGRAM_INVOCATIONS=1')
        $lines.Add('PROGRAM_ERROR=vendor startup LOW')
        $lines.Add('PROGRAM_TCL_RESULT=FAIL_NO_RETRY')
        $lines.Add('TIMED_OUT=NO')
        $lines.Add('PROCESS_EXIT_CODE=1')
    } else {
        $lines.Add('[Labtools 27-3164] End of startup status: HIGH')
        $lines.Add('I25_PROGRAM_RETURN_MARKER=fixture')
        $lines.Add('PROGRAM_DONE=1')
        $lines.Add('I25_FRESH_DONE_MARKER=fixture')
        $lines.Add('PROGRAM_INVOCATIONS=1')
        $lines.Add('PROGRAM_TCL_RESULT=PASS_DONE_1')
        $lines.Add('TIMED_OUT=NO')
        $lines.Add('PROCESS_EXIT_CODE=0')
    }
    $records = ConvertTo-I25ObserverRecords -Lines $lines.ToArray()
    return Test-I25ProgramObserver -Records $records
}

function Test-Bit4Query([string]$Text) {
    return [regex]::IsMatch($Text, '(?im)get_property\s+(?:\$bit4_property|\{?REGISTER\.IR\.BIT4_EOS\}?)')
}

foreach ($freshPath in @($preconditionCsv, $combinedCsv, $fixtureSummary, $replayPath, $replayHashes)) {
    if (Test-Path -LiteralPath $freshPath) { throw "fixture/replay output must be fresh: $freshPath" }
}

$inputPaths = [ordered]@{
    Tclsh = $tclsh
    Parser = $parser
    R6Observer = $r6Observer
    R6Matrix = $r6Matrix
    R6Gate = $r6Gate
    R6Ledger = $r6Ledger
    R6Report = $r6Report
}
foreach ($entry in $inputPaths.GetEnumerator()) {
    Assert-True (Test-Path -LiteralPath $entry.Value -PathType Leaf) "missing input $($entry.Key): $($entry.Value)"
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Value).Hash
    Assert-True ($actualHash -ceq $expectedHashes[$entry.Key]) "$($entry.Key) hash mismatch: $actualHash"
}
Assert-True (Test-Path -LiteralPath $programTcl -PathType Leaf) 'R7 mode-aware Tcl is missing'
Assert-True (Test-Path -LiteralPath $preconditionFixtureTcl -PathType Leaf) 'R7 precondition fixture Tcl is missing'

. $parser

& $tclsh $preconditionFixtureTcl $preconditionCsv
if ($LASTEXITCODE -ne 0) { throw "precondition Tcl fixtures failed with exit $LASTEXITCODE" }
$preconditions = @(Import-Csv -LiteralPath $preconditionCsv)
Assert-True ($preconditions.Count -eq 10) "precondition fixture count is $($preconditions.Count), expected 10"
Assert-True ((@($preconditions | Where-Object result -cne 'PASS')).Count -eq 0) 'one or more precondition fixtures failed'

$passTranscript = Get-TranscriptResult -Kind Pass
$startupLowTranscript = Get-TranscriptResult -Kind StartupLow
$duplicateTranscript = Get-TranscriptResult -Kind DuplicateConsumed
$observerText = [IO.File]::ReadAllText($programTcl)
$mutantBit4Text = $observerText + "`nset eos [get_property REGISTER.IR.BIT4_EOS `$dev]`n"
Assert-True (-not (Test-Bit4Query $observerText)) 'actual R7 observer contains a BIT4_EOS get_property query'
Assert-True (Test-Bit4Query $mutantBit4Text) 'C1 mutant BIT4_EOS query was not detected'

$rows = [Collections.Generic.List[object]]::new()
foreach ($precondition in $preconditions) {
    $fixture = $precondition.fixture
    $expectedOutcome = switch ($fixture) {
        {$_ -in @('B0','B1','T0')} { 'PASS'; break }
        'B4' { 'CONSUMED_ONE_FAIL_NO_RETRY'; break }
        default { 'FAIL_BEFORE_PROGRAM' }
    }

    if ($precondition.actual_precondition -ne 'PASS') {
        $actualOutcome = 'FAIL_BEFORE_PROGRAM'
        $consumed = 0
        $postClassification = 'NOT_REACHED'
    } elseif ($fixture -eq 'B4') {
        $actualOutcome = $(if ($startupLowTranscript.PROGRAM_INVOCATION_CONSUMED_COUNT -eq 1 -and
                               $startupLowTranscript.CLASSIFICATION -ne 'PASS_STARTUP_HIGH_DONE_1') {
                                'CONSUMED_ONE_FAIL_NO_RETRY'
                            } else { 'UNEXPECTED' })
        $consumed = $startupLowTranscript.PROGRAM_INVOCATION_CONSUMED_COUNT
        $postClassification = $startupLowTranscript.CLASSIFICATION
    } else {
        $actualOutcome = $(if ($passTranscript.CLASSIFICATION -eq 'PASS_STARTUP_HIGH_DONE_1') {'PASS'} else {'UNEXPECTED'})
        $consumed = $passTranscript.PROGRAM_INVOCATION_CONSUMED_COUNT
        $postClassification = $passTranscript.CLASSIFICATION
    }
    $rows.Add([pscustomobject]@{
        fixture = $fixture
        expected_outcome = $expectedOutcome
        precondition = $precondition.actual_precondition
        postprogram_classification = $postClassification
        program_invocations_consumed = $consumed
        actual_outcome = $actualOutcome
        result = $(if ($actualOutcome -ceq $expectedOutcome) {'PASS'} else {'FAIL'})
    })
}

$c0Outcome = $(if ($duplicateTranscript.CLASSIFICATION -ne 'PASS_STARTUP_HIGH_DONE_1' -and
                    $duplicateTranscript.PROGRAM_INVOCATION_CONSUMED_COUNT -eq 2) {
                    'FAIL_DUPLICATE_PROGRAM_INVOCATION_MARKER'
                } else { 'UNEXPECTED' })
$rows.Add([pscustomobject]@{
    fixture='C0'; expected_outcome='FAIL_DUPLICATE_PROGRAM_INVOCATION_MARKER'; precondition='PASS'
    postprogram_classification=$duplicateTranscript.CLASSIFICATION
    program_invocations_consumed=$duplicateTranscript.PROGRAM_INVOCATION_CONSUMED_COUNT
    actual_outcome=$c0Outcome; result=$(if ($c0Outcome -ceq 'FAIL_DUPLICATE_PROGRAM_INVOCATION_MARKER') {'PASS'} else {'FAIL'})
})
$rows.Add([pscustomobject]@{
    fixture='C1'; expected_outcome='FAIL_STATIC_BIT4_EOS_QUERY'; precondition='NOT_APPLICABLE'
    postprogram_classification='STATIC_AUDIT'
    program_invocations_consumed=0
    actual_outcome='FAIL_STATIC_BIT4_EOS_QUERY'; result='PASS'
})

$orderedRows = @($rows | Sort-Object @{Expression={
    $order = @('B0','B1','B2','B3','B4','T0','T1','T2','T3','C0','C1','C2')
    [array]::IndexOf($order, $_.fixture)
}})
$orderedRows | Export-Csv -LiteralPath $combinedCsv -NoTypeInformation -Encoding utf8NoBOM
$fixtureFailures = @($orderedRows | Where-Object result -cne 'PASS')
Assert-True ($orderedRows.Count -eq 12) "combined fixture count is $($orderedRows.Count), expected 12"
Assert-True ($fixtureFailures.Count -eq 0) 'one or more combined fixtures failed'

$summaryLines = [string[]]@(
    '# R7 mode-aware programming-observer fixtures',
    '',
    '```text',
    'MODE_AWARE_OBSERVER_FIXTURE_COUNT=12',
    'MODE_AWARE_OBSERVER_FIXTURES=PASS_ALL',
    'BOOTSTRAP_STABLE_DONE0=PASS',
    'BOOTSTRAP_STABLE_DONE1=PASS',
    'UNREADABLE_OR_UNSTABLE_DONE=FAIL_BEFORE_PROGRAM_AS_REQUIRED',
    'TRANSITION_STABLE_DONE0=FAIL_BEFORE_PROGRAM_AS_REQUIRED',
    'TRANSITION_RECEIPT_GATES=PASS',
    'STARTUP_LOW=CONSUMED_ONE_FAIL_NO_RETRY_AS_REQUIRED',
    'DUPLICATE_PROGRAM_MARKER=FAIL_AS_REQUIRED',
    'BIT4_EOS_QUERY_STATIC_DETECTION=PASS',
    'SELECTED_TARGET_MISMATCH=FAIL_BEFORE_PROGRAM_AS_REQUIRED',
    '```'
)
Write-Utf8NoBom -Path $fixtureSummary -Lines $summaryLines

$r6Rows = @(Import-Csv -LiteralPath $r6Matrix)
$r6GateText = [IO.File]::ReadAllText($r6Gate)
$r6LedgerText = [IO.File]::ReadAllText($r6Ledger)
$r6ReportText = [IO.File]::ReadAllText($r6Report)
$r6ObserverText = [IO.File]::ReadAllText($r6Observer)
$expectedTarget = 'localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'
$selectedTargetPass = $r6Rows.Count -eq 10 -and (@($r6Rows | Where-Object {
    $_.target_count -ne '1' -or $_.device_count -ne '1' -or
    $_.target_path -cne $expectedTarget -or
    $_.canonical_id -cne 'Xilinx/80802026a98b01' -or
    $_.part -cne 'xc7a35t' -or $_.idcode -cne '0362D093' -or
    $_.refresh_result -cne 'PASS'
})).Count -eq 0
$doneValues = @($r6Rows.done | Sort-Object -Unique)
$stableDoneZero = $doneValues.Count -eq 1 -and $doneValues[0] -ceq '0'
$oldBlocked = $r6ObserverText.Contains('if {$preprogram_done ne "1"}')
$b0 = $preconditions | Where-Object fixture -ceq 'B0'
$r7ReplayPass = $b0.actual_precondition -ceq 'PASS'
$r6ProgramsRemainZero = $r6LedgerText.Contains('FPGA_PROGRAM_INVOCATIONS=0') -and
                        $r6LedgerText.Contains('FORMAL_BOOTSTRAP_PROGRAMS=0')
$historicalClassificationPresent = $r6ReportText.Contains('BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT')
$gatePass = $r6GateText.Contains('JTAG_TRANSPORT_STABILITY_GATE=PASS_10_OF_10') -and
            $r6GateText.Contains('JTAG_PRECHECK_DONE_VALUE=0') -and
            $r6GateText.Contains('FPGA_PROGRAM_OPERATIONS=0')

Assert-True $selectedTargetPass 'R6 replay selected-target matrix failed'
Assert-True $stableDoneZero 'R6 replay pre-program DONE was not stable zero'
Assert-True $oldBlocked 'R6 old observer DONE==1 gate is absent'
Assert-True $r7ReplayPass 'R7 bootstrap precondition did not accept stable zero'
Assert-True $r6ProgramsRemainZero 'R6 program accounting is not zero'
Assert-True $historicalClassificationPresent 'R6 report blocker classification is absent'
Assert-True $gatePass 'R6 aggregate stability gate receipts are incomplete'

$replayLines = [string[]]@(
    '# R6 historical-evidence replay under the R7 pre-program contract',
    '',
    '```text',
    'R6_REPLAY_SELECTED_TARGET=PASS',
    'R6_REPLAY_PREPROGRAM_DONE=STABLE_0',
    'R6_OLD_OBSERVER_CLASSIFICATION=BLOCKED_PREPROGRAM_DONE_NOT_1',
    'R7_BOOTSTRAP_PRECONDITION_REPLAY=PASS_STABLE_DONE_0_ACCEPTED',
    'R6_RETROACTIVE_PROGRAM_RESULT=NOT_CREATED',
    'R6_FPGA_PROGRAMS_REMAIN=0',
    'R6_REPLAY=PASS_EXPECTED_CONTRACT_DIFFERENCE',
    '```',
    '',
    'This is a contract replay only. It does not reclassify any R6 action as a',
    'program attempt and does not create an R6 scientific sample.'
)
Write-Utf8NoBom -Path $replayPath -Lines $replayLines

$hashLines = [Collections.Generic.List[string]]::new()
foreach ($entry in $inputPaths.GetEnumerator()) {
    $hashLines.Add(('{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Value).Hash, $entry.Value))
}
$hashLines.Add(('{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $programTcl).Hash, $programTcl))
$hashLines.Add(('{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $preconditionFixtureTcl).Hash, $preconditionFixtureTcl))
Write-Utf8NoBom -Path $replayHashes -Lines $hashLines.ToArray()

'MODE_AWARE_OBSERVER_FIXTURES=PASS_ALL'
'MODE_AWARE_OBSERVER_FIXTURE_COUNT=12'
'R6_REPLAY_SELECTED_TARGET=PASS'
'R6_REPLAY_PREPROGRAM_DONE=STABLE_0'
'R6_OLD_OBSERVER_CLASSIFICATION=BLOCKED_PREPROGRAM_DONE_NOT_1'
'R7_BOOTSTRAP_PRECONDITION_REPLAY=PASS_STABLE_DONE_0_ACCEPTED'
'R6_RETROACTIVE_PROGRAM_RESULT=NOT_CREATED'
'R6_FPGA_PROGRAMS_REMAIN=0'
'R6_REPLAY=PASS_EXPECTED_CONTRACT_DIFFERENCE'
