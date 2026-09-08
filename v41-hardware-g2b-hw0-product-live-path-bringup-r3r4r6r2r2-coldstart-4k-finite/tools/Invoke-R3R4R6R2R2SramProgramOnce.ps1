[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R2_20260908T081532Z'
$lockPath = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$bit = 'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit'
$tcl = Join-Path $root 'scripts\program-product-once-r3r4r6r2r2.tcl'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$receiptPath = Join-Path $root 'logs\fpga-programming-receipt.json'
if (Test-Path -LiteralPath $receiptPath) { throw 'R3R4R6R2R2_PROGRAM_RECEIPT_EXISTS_NO_RETRY' }
if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) { throw 'R3R4R6R2R2_CONTROLLER_LOCK_NOT_HELD' }
$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
if ($lock.task -cne 'G2B-HW0-PRODUCT-R3R4R6R2R2' -or
    $lock.run_root -cne $root -or $lock.state -cne 'HELD') {
  throw 'R3R4R6R2R2_CONTROLLER_LOCK_OWNER_MISMATCH'
}
if ([int]$lock.sram_programming_attempts -ne 0) { throw 'R3R4R6R2R2_SRAM_PROGRAM_BUDGET_EXHAUSTED' }
if (-not (Test-Path -LiteralPath $bit -PathType Leaf)) { throw 'R3R4R6R2R2_TRUSTED_BITSTREAM_CANNOT_BE_OPENED' }
if (-not (Test-Path -LiteralPath $vivado -PathType Leaf)) { throw 'R3R4R6R2R2_VIVADO_UNAVAILABLE' }
$tclText = [IO.File]::ReadAllText($tcl)
$programCalls = ([regex]::Matches($tclText,'(?m)^\s*program_hw_devices\s+')).Count
$forbiddenCalls = ([regex]::Matches($tclText,'(?im)^\s*(create_hw_cfgmem|program_hw_cfgmem|write_cfgmem)\b')).Count
if ($programCalls -ne 1 -or $forbiddenCalls -ne 0) { throw 'R3R4R6R2R2_PROGRAM_STATIC_ALLOWLIST_FAILED' }
$receipt = [ordered]@{
  task='G2B-HW0-PRODUCT-R3R4R6R2R2'
  start_utc=[DateTime]::UtcNow.ToString('o')
  bitstream_path=$bit
  owner_trusted_bitstream_sha256='AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7'
  bitstream_rehash_performed=$false
  vivado=$vivado
  tcl=$tcl
  static_program_hw_devices_calls=$programCalls
  static_cfgmem_calls=$forbiddenCalls
  delivery_attempt=1
  automatic_retry='DENIED'
  result='DELIVERY_IN_PROGRESS_NO_RETRY'
}
[IO.File]::WriteAllText($receiptPath,($receipt | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$lock.sram_programming_attempts = 1
[IO.File]::WriteAllText($lockPath,($lock | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
$log = Join-Path $root 'logs\vivado-program.log'
$journal = Join-Path $root 'logs\vivado-program.jou'
& $vivado -mode batch -journal $journal -log $log -source $tcl 2>&1 |
  Tee-Object -FilePath (Join-Path $root 'logs\vivado-program-console.log')
$rc = $LASTEXITCODE
$logText = if (Test-Path -LiteralPath $log) { [IO.File]::ReadAllText($log) } else { '' }
$pass = ($rc -eq 0 -and
  $logText.Contains('PROGRAM_TCL_RESULT=PASS_DONE_1',[StringComparison]::Ordinal) -and
  $logText.Contains('POSTPROGRAM_FPGA_DONE=1',[StringComparison]::Ordinal))
$receipt.result = if ($pass) { 'PASS' } else { 'FAIL_NO_RETRY' }
$receipt.vivado_exit_code = $rc
$receipt.done_asserted = $pass
$receipt.end_utc = [DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText($receiptPath,($receipt | ConvertTo-Json -Depth 5) + "`n",
  [Text.UTF8Encoding]::new($false))
if (-not $pass) { throw 'R3R4R6R2R2_EXACT_PRODUCT_PROGRAMMING_FAILED' }
'R3R4R6R2R2_EXACT_PRODUCT_PROGRAMMING=PASS'
