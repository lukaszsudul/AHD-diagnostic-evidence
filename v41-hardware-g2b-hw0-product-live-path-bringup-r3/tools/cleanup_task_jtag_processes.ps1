[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskStartUtc = [DateTimeOffset]::Parse('2026-09-06T14:02:30.4469117Z')
$allowedPathPrefix = 'C:\AMDDesignTools\2025.2\Vivado\bin\'
$evidence = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z\raw\JTAG_T0_TASK_PROCESS_CLEANUP.log'
if (Test-Path -LiteralPath $evidence) { throw 'JTAG_CLEANUP_EVIDENCE_EXISTS' }

$targets = @(Get-Process | Where-Object { $_.ProcessName -match '^(hw_server|cs_server)$' })
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("UTC_START=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add("TARGET_COUNT=$($targets.Count)")
foreach ($process in $targets) {
    $startUtc = [DateTimeOffset]$process.StartTime.ToUniversalTime()
    if ($startUtc -lt $taskStartUtc -or -not $process.Path.StartsWith($allowedPathPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "NON_TASK_JTAG_PROCESS_REFUSED=$($process.Id)"
    }
    $lines.Add("TASK_OWNED_PROCESS=PID:$($process.Id),NAME:$($process.ProcessName),START_UTC:$($startUtc.ToString('o')),PATH:$($process.Path)")
}
foreach ($process in $targets) {
    Stop-Process -Id $process.Id -ErrorAction Stop
    $lines.Add("STOP_REQUESTED_PID=$($process.Id)")
}
Start-Sleep -Milliseconds 500
$remaining = @(Get-Process | Where-Object { $_.ProcessName -match '^(vivado|vivado_lab|hw_server|xsdb|cs_server|xicom)$' })
$lines.Add("REMAINING_RELEVANT_PROCESS_COUNT=$($remaining.Count)")
$lines.Add("UTC_END=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add($(if ($remaining.Count -eq 0) { 'RESULT=PASS' } else { 'RESULT=FAIL' }))
[IO.File]::WriteAllLines($evidence, $lines, [Text.UTF8Encoding]::new($false))
if ($remaining.Count -ne 0) { throw 'TASK_JTAG_PROCESS_CLEANUP_INCOMPLETE' }
Write-Output 'TASK_JTAG_PROCESS_CLEANUP=PASS'
