[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('Acquire','Release')][string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-HW0-PRODUCT-R3R4R6R1'
$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R1_20260907T202452Z'
$lock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$receipt = Join-Path $lock 'receipt.json'
$log = Join-Path $run ('logs\controller-lock-' + $Action.ToLowerInvariant() + '.json')

if ($Action -eq 'Acquire') {
  if (Test-Path -LiteralPath $lock) { throw 'R3R4R6R1_TASK_LOCK_UNAVAILABLE' }
  [void](New-Item -ItemType Directory -Path $lock)
  $value = [ordered]@{
    task=$task
    state='HELD'
    run_root=$run
    process_id=$PID
    acquired_utc=[DateTime]::UtcNow.ToString('o')
  }
  [IO.File]::WriteAllText($receipt,($value | ConvertTo-Json) + "`n",
    [Text.UTF8Encoding]::new($false))
} else {
  if (-not (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    throw 'R3R4R6R1_CONTROLLER_LOCK_RECEIPT_MISSING'
  }
  $held = Get-Content -Raw -LiteralPath $receipt | ConvertFrom-Json
  if ($held.task -cne $task -or $held.run_root -cne $run -or $held.state -cne 'HELD') {
    throw 'R3R4R6R1_CONTROLLER_LOCK_OWNER_MISMATCH'
  }
  $value = [ordered]@{
    task=$task
    state='RELEASED'
    run_root=$run
    released_utc=[DateTime]::UtcNow.ToString('o')
  }
  Remove-Item -LiteralPath $receipt -Force
  Remove-Item -LiteralPath $lock
}

[IO.File]::WriteAllText($log,($value | ConvertTo-Json) + "`n",
  [Text.UTF8Encoding]::new($false))
$value | ConvertTo-Json
