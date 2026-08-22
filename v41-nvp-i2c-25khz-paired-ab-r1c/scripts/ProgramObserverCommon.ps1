Set-StrictMode -Version Latest

function ConvertTo-I25ObserverRecords {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Lines)

    $result = [Collections.Generic.List[object]]::new()
    [long]$ordinal = 0
    foreach ($raw in $Lines) {
        $ordinal++
        [long]$tick = $ordinal
        [long]$sequence = $ordinal
        $stream = 'RAW'
        $logical = $raw
        if ($raw -match '^SEQ=(\d+) TICK=(\d+) STREAM=([^ ]+) LINE=(.*)$') {
            $sequence = [long]$Matches[1]
            $tick = [long]$Matches[2]
            $stream = $Matches[3]
            $logical = $Matches[4]
        } elseif ($raw -match '^(STDOUT|STDERR) TICK=(\d+) LINE=(.*)$') {
            $stream = $Matches[1]
            $tick = [long]$Matches[2]
            $logical = $Matches[3]
        }
        $result.Add([pscustomobject]@{
            Sequence = $sequence
            Tick = $tick
            Stream = $stream
            Line = $logical
            Raw = $raw
        })
    }
    return ,$result.ToArray()
}

function Test-I25ProgramObserver {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Records)

    function Select-Exact([string]$Value) {
        return @($Records | Where-Object { $_.Line -ceq $Value })
    }
    function Select-Like([string]$Pattern) {
        return @($Records | Where-Object { $_.Line -like $Pattern })
    }

    $consumed = @(Select-Exact 'PROGRAM_INVOCATION_CONSUMED=1')
    $startupAll = @($Records | Where-Object { $_.Line -match 'End of startup status:' })
    $startupHigh = @($Records | Where-Object {
        $_.Line -match '\[Labtools 27-3164\]' -and
        $_.Line -match 'End of startup status:\s*HIGH(?:\s|$)'
    })
    $returnMarker = @(Select-Like 'I25_PROGRAM_RETURN_MARKER=*')
    $doneOne = @(Select-Exact 'PROGRAM_DONE=1')
    $freshDone = @(Select-Like 'I25_FRESH_DONE_MARKER=*')
    $invocations = @(Select-Exact 'PROGRAM_INVOCATIONS=1')
    $tclPass = @(Select-Exact 'PROGRAM_TCL_RESULT=PASS_DONE_1')
    $tclFail = @(Select-Exact 'PROGRAM_TCL_RESULT=FAIL_NO_RETRY')
    $programErrors = @(Select-Like 'PROGRAM_ERROR=*')
    $processExitZero = @(Select-Exact 'PROCESS_EXIT_CODE=0')
    $timedOutNo = @(Select-Exact 'TIMED_OUT=NO')
    $unsupportedBit4 = @($Records | Where-Object {
        $_.Line -match 'REGISTER\.IR\.BIT4_EOS' -and
        $_.Line -match '(does not exist|does not have|unavailable|No properties matched)'
    })

    $countGate =
        $consumed.Count -eq 1 -and
        $startupAll.Count -eq 1 -and
        $startupHigh.Count -eq 1 -and
        $returnMarker.Count -eq 1 -and
        $doneOne.Count -eq 1 -and
        $freshDone.Count -eq 1 -and
        $invocations.Count -eq 1 -and
        $tclPass.Count -eq 1 -and
        $processExitZero.Count -eq 1 -and
        $timedOutNo.Count -eq 1 -and
        $tclFail.Count -eq 0 -and
        $programErrors.Count -eq 0

    $orderGate = $false
    if ($countGate) {
        $orderGate =
            $consumed[0].Sequence -lt $startupHigh[0].Sequence -and
            $startupHigh[0].Sequence -lt $returnMarker[0].Sequence -and
            $returnMarker[0].Sequence -lt $doneOne[0].Sequence -and
            $doneOne[0].Sequence -lt $freshDone[0].Sequence -and
            $freshDone[0].Sequence -le $tclPass[0].Sequence -and
            $tclPass[0].Sequence -lt $processExitZero[0].Sequence
    }

    if ($countGate -and $orderGate) {
        $classification = 'PASS_STARTUP_HIGH_DONE_1'
    } elseif ($consumed.Count -eq 0) {
        $classification = 'FAIL_BEFORE_PROGRAM'
    } elseif ($unsupportedBit4.Count -gt 0) {
        $classification = 'FAIL_POST_PROGRAM_OBSERVER_BIT4'
    } else {
        $classification = 'FAIL_OBSERVER_GATE'
    }

    [pscustomobject]@{
        CLASSIFICATION = $classification
        PROGRAM_EOS = $(if ($classification -eq 'PASS_STARTUP_HIGH_DONE_1') {'HIGH_VENDOR_STARTUP_STATUS'} else {'NOT_PROVEN'})
        PROGRAM_DONE = $(if ($doneOne.Count -eq 1) {'1'} else {'NOT_PROVEN'})
        COUNT_GATE = $(if ($countGate) {'PASS'} else {'FAIL'})
        ORDER_GATE = $(if ($orderGate) {'PASS'} else {'FAIL'})
        PROGRAM_INVOCATION_CONSUMED_COUNT = $consumed.Count
        VENDOR_STARTUP_STATUS_COUNT = $startupAll.Count
        VENDOR_STARTUP_HIGH_COUNT = $startupHigh.Count
        PROGRAM_RETURN_MARKER_COUNT = $returnMarker.Count
        PROGRAM_DONE_1_COUNT = $doneOne.Count
        FRESH_DONE_MARKER_COUNT = $freshDone.Count
        PROGRAM_INVOCATIONS_1_COUNT = $invocations.Count
        TCL_PASS_COUNT = $tclPass.Count
        TCL_FAIL_COUNT = $tclFail.Count
        PROGRAM_ERROR_COUNT = $programErrors.Count
        PROCESS_EXIT_ZERO_COUNT = $processExitZero.Count
        TIMED_OUT_NO_COUNT = $timedOutNo.Count
        UNSUPPORTED_BIT4_ERROR_COUNT = $unsupportedBit4.Count
        PROGRAM_INVOCATION_CONSUMED_TICKS = $(if ($consumed.Count -eq 1) {$consumed[0].Tick} else {-1})
        PROGRAM_RETURN_MARKER_TICKS = $(if ($returnMarker.Count -eq 1) {$returnMarker[0].Tick} else {-1})
        FRESH_DONE_MARKER_TICKS = $(if ($freshDone.Count -eq 1) {$freshDone[0].Tick} else {-1})
    }
}
