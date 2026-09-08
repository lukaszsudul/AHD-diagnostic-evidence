[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('CleanAcquire','Release')][string]$Action)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$task = 'G2B-HW0-PRODUCT-R3R4R6R2R2'
$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R2_20260908T081532Z'
$lock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$receipt = Join-Path $lock 'receipt.json'
$log = Join-Path $run ('logs\controller-lock-' + $Action.ToLowerInvariant() + '.json')
$acceptedStale = @{
  'G2B-HW0-PRODUCT-R3R4R6R1' = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R1_20260907T202452Z'
  'G2B-HW0-PRODUCT-R3R4R6R2' = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2_20260908T061945Z'
  'G2B-HW0-PRODUCT-R3R4R6R2R1' = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R1_20260908T073817Z'
}

if ($Action -eq 'CleanAcquire') {
  $removed = $null
  if (Test-Path -LiteralPath $lock) {
    if (-not (Test-Path -LiteralPath $receipt -PathType Leaf)) {
      throw 'R3R4R6R2R2_EXISTING_CONTROLLER_LOCK_RECEIPT_MISSING'
    }
    $held = Get-Content -Raw -LiteralPath $receipt | ConvertFrom-Json
    if (-not $acceptedStale.ContainsKey([string]$held.task) -or
        $acceptedStale[[string]$held.task] -cne [string]$held.run_root -or
        [string]$held.state -cne 'HELD') {
      throw 'R3R4R6R2R2_EXISTING_CONTROLLER_LOCK_NOT_EXACT_AUTHORIZED_STALE_LOCK'
    }
    if (@(Get-ChildItem -LiteralPath $lock -Force).Count -ne 1) {
      throw 'R3R4R6R2R2_STALE_CONTROLLER_LOCK_HAS_UNEXPECTED_CONTENT'
    }
    $removed = [ordered]@{ task=$held.task; run_root=$held.run_root; state=$held.state }
    Remove-Item -LiteralPath $receipt -Force
    Remove-Item -LiteralPath $lock
  }
  [void](New-Item -ItemType Directory -Path $lock)
  $value = [ordered]@{
    task=$task
    state='HELD'
    run_root=$run
    process_id=$PID
    acquired_utc=[DateTime]::UtcNow.ToString('o')
    exact_stale_lock_removed=$removed
    sram_programming_attempts=0
    warm_reboot_attempts=0
    terminal_cleanup_reboots=0
  }
  [IO.File]::WriteAllText($receipt,($value | ConvertTo-Json -Depth 6) + "`n",
    [Text.UTF8Encoding]::new($false))
} else {
  if (-not (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    throw 'R3R4R6R2R2_CONTROLLER_LOCK_RECEIPT_MISSING'
  }
  $held = Get-Content -Raw -LiteralPath $receipt | ConvertFrom-Json
  if ([string]$held.task -cne $task -or [string]$held.run_root -cne $run -or
      [string]$held.state -cne 'HELD') {
    throw 'R3R4R6R2R2_CONTROLLER_LOCK_OWNER_MISMATCH'
  }
  $value = [ordered]@{
    task=$task
    state='RELEASED'
    run_root=$run
    released_utc=[DateTime]::UtcNow.ToString('o')
    sram_programming_attempts=$held.sram_programming_attempts
    warm_reboot_attempts=$held.warm_reboot_attempts
    terminal_cleanup_reboots=$held.terminal_cleanup_reboots
  }
  Remove-Item -LiteralPath $receipt -Force
  Remove-Item -LiteralPath $lock
}
[IO.File]::WriteAllText($log,($value | ConvertTo-Json -Depth 6) + "`n",
  [Text.UTF8Encoding]::new($false))
$value | ConvertTo-Json -Depth 6
