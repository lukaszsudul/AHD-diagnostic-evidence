[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R2_20260908T081532Z'
$lockPath = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$receiptPath = Join-Path $root 'logs\warm-reboot-receipt.json'
if (Test-Path -LiteralPath $receiptPath) { throw 'R3R4R6R2R2_WARM_REBOOT_RECEIPT_EXISTS' }
$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
if ($lock.task -cne 'G2B-HW0-PRODUCT-R3R4R6R2R2' -or $lock.state -cne 'HELD' -or
    [int]$lock.sram_programming_attempts -ne 1 -or [int]$lock.warm_reboot_attempts -ne 0) {
  throw 'R3R4R6R2R2_WARM_REBOOT_PRECONDITION_FAILED'
}
$lock.warm_reboot_attempts = 1
[IO.File]::WriteAllText($lockPath,($lock | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$value = [ordered]@{
  task='G2B-HW0-PRODUCT-R3R4R6R2R2'
  requested_utc=[DateTime]::UtcNow.ToString('o')
  reboot_attempt=1
  purpose='REQUIRED_POST_SRAM_PROGRAM_PCIE_ENUMERATION'
  boot_id_comparison='SKIPPED_BY_OWNER_DECISION'
  result='REQUEST_IN_PROGRESS'
}
[IO.File]::WriteAllText($receiptPath,($value | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$helper = Join-Path $root 'scripts\Invoke-R3R4R6R2R2DutConnection.ps1'
& $helper -ReceiptName 'required-warm-reboot' -TimeoutSeconds 30 -Sudo `
  -RemoteCommand "nohup sh -c 'sleep 1; /usr/sbin/reboot' >/dev/null 2>&1 &"
$value.result = 'REQUEST_ACCEPTED'
$value.accepted_utc = [DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText($receiptPath,($value | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
