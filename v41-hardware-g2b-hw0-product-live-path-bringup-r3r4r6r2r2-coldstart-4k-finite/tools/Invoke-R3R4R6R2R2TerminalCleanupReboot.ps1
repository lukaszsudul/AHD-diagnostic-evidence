[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R2_20260908T081532Z'
$lockPath = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$receiptPath = Join-Path $root 'logs\terminal-cleanup-reboot-receipt.json'
if (Test-Path -LiteralPath $receiptPath) { throw 'R3R4R6R2R2_TERMINAL_REBOOT_RECEIPT_EXISTS' }
$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
if ($lock.task -cne 'G2B-HW0-PRODUCT-R3R4R6R2R2' -or $lock.state -cne 'HELD' -or
    [int]$lock.sram_programming_attempts -ne 1 -or [int]$lock.warm_reboot_attempts -ne 1 -or
    [int]$lock.terminal_cleanup_reboots -ne 0) {
  throw 'R3R4R6R2R2_TERMINAL_REBOOT_PRECONDITION_FAILED'
}
$controller = Get-Content -Raw -LiteralPath (Join-Path $root 'logs\terminal-controller-summary.json') | ConvertFrom-Json
if ($controller.capture_result -cne 'FAIL' -or $controller.pending_aio -le 0 -or
    $controller.physical_quiescence -cne 'FAIL') {
  throw 'R3R4R6R2R2_TERMINAL_REBOOT_NOT_JUSTIFIED'
}
$lock.terminal_cleanup_reboots = 1
[IO.File]::WriteAllText($lockPath,($lock | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$value = [ordered]@{
  task='G2B-HW0-PRODUCT-R3R4R6R2R2'
  requested_utc=[DateTime]::UtcNow.ToString('o')
  reboot_attempt=1
  purpose='TERMINAL_CLEANUP_PENDING_AIO_PREVENTED_SAFE_MODULE_UNLOAD'
  pending_aio=$controller.pending_aio
  physical_quiescence=$controller.physical_quiescence
  capture_retry='DENIED'
  result='REQUEST_IN_PROGRESS'
}
[IO.File]::WriteAllText($receiptPath,($value | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$helper = Join-Path $root 'scripts\Invoke-R3R4R6R2R2DutConnection.ps1'
& $helper -ReceiptName 'terminal-cleanup-reboot' -TimeoutSeconds 30 -Sudo `
  -RemoteCommand "nohup sh -c 'sleep 1; /usr/sbin/reboot' >/dev/null 2>&1 &"
$value.result = 'REQUEST_ACCEPTED'
$value.accepted_utc = [DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText($receiptPath,($value | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
