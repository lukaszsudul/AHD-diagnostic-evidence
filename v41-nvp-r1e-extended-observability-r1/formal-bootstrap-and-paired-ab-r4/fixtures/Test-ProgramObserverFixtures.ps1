[CmdletBinding()]
param(
    [string]$FixtureRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'fixtures'),
    [string]$OutputCsv = (Join-Path (Split-Path -Parent $PSScriptRoot) '02_PROGRAM_OBSERVER_FIX\PROGRAM_OBSERVER_FIXTURE_RESULTS.csv')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1')

$expected = [ordered]@{
    'PASS_STARTUP_HIGH_DONE_1.log' = 'PASS_STARTUP_HIGH_DONE_1'
    'FAIL_STARTUP_LOW.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_MISSING_STARTUP_STATUS.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_DONE_0.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_WRONG_ORDER.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_DUPLICATE_PROGRAM_INVOCATION.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_PROCESS_EXIT_NONZERO.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_DUPLICATE_PROGRAM_INVOCATIONS.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_DUPLICATE_DONE.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_TIMEOUT.log' = 'FAIL_OBSERVER_GATE'
    'FAIL_PROGRAM_ERROR.log' = 'FAIL_OBSERVER_GATE'
}

$rows = [Collections.Generic.List[object]]::new()
foreach ($name in $expected.Keys) {
    $path = Join-Path $FixtureRoot $name
    $records = ConvertTo-I25ObserverRecords -Lines ([IO.File]::ReadAllLines($path))
    $result = Test-I25ProgramObserver -Records $records
    $match = $result.CLASSIFICATION -ceq $expected[$name]
    $rows.Add([pscustomobject]@{
        FIXTURE = $name
        EXPECTED = $expected[$name]
        ACTUAL = $result.CLASSIFICATION
        MATCH = $(if ($match) {'PASS'} else {'FAIL'})
        COUNT_GATE = $result.COUNT_GATE
        ORDER_GATE = $result.ORDER_GATE
    })
}
$rows | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding utf8NoBOM
$rows | Format-Table -AutoSize
if (@($rows | Where-Object MATCH -ne 'PASS').Count -ne 0) {
    throw 'one or more programming-observer fixtures were misclassified'
}
'PROGRAM_OBSERVER_FIXTURE_GATE=PASS'
