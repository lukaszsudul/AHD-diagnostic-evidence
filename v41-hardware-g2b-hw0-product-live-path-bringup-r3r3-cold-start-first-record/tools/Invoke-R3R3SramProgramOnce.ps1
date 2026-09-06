[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$lockPath='C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$bit='C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit'
$source='C:\FPGA\V41_G2B'
$tcl=Join-Path $PSScriptRoot 'program-product-once.tcl'
$vivado='C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$receiptPath=Join-Path $root 'receipts\sram-program-supervisor.json'
if(Test-Path -LiteralPath $receiptPath){throw 'R3R3_PROGRAM_RECEIPT_EXISTS_NO_RETRY'}
if(-not(Test-Path -LiteralPath $lockPath -PathType Leaf)){throw 'R3R3_CONTROLLER_LOCK_NOT_HELD'}
$lock=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if($lock.task -cne 'G2B-HW0-PRODUCT-R3R3' -or $lock.root -cne $root -or $lock.state -cne 'HELD'){throw 'R3R3_CONTROLLER_LOCK_OWNER_MISMATCH'}
if([int]$lock.sram_programming_attempts -ne 0){throw 'R3R3_SRAM_PROGRAM_BUDGET_EXHAUSTED'}
if(-not(Test-Path -LiteralPath $vivado -PathType Leaf)){throw 'R3R3_VIVADO_2025_2_UNAVAILABLE'}
$fi=Get-Item -LiteralPath $bit
$bitHash=(Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
$branch=(git -C $source branch --show-current).Trim()
$commit=(git -C $source rev-parse HEAD).Trim()
$tree=(git -C $source rev-parse 'HEAD^{tree}').Trim()
git -C $source diff --quiet
$trackedClean=($LASTEXITCODE -eq 0)
git -C $source diff --cached --quiet
$indexClean=($LASTEXITCODE -eq 0)
if($fi.Length -ne 2192144 -or $bitHash -cne 'AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7'){throw 'R3R3_EXACT_PRODUCT_BITSTREAM_MISMATCH'}
if($branch -cne 'integration/v41-g2b-onech-c2h' -or $commit -cne '92e9b3d914134c044371779def1ee18eaaeda98a' -or $tree -cne 'cf6bf82249c90782eab1978c68541ed9c0e6430b' -or -not $trackedClean -or -not $indexClean){throw 'R3R3_SOURCE_AUTHORITY_DRIFT'}
$tclText=[IO.File]::ReadAllText($tcl)
$programCalls=([regex]::Matches($tclText,'(?m)^\s*program_hw_devices\s+')).Count
$forbiddenCalls=([regex]::Matches($tclText,'(?im)^\s*(create_hw_cfgmem|program_hw_cfgmem|write_cfgmem)\b')).Count
if($programCalls -ne 1 -or $forbiddenCalls -ne 0){throw 'R3R3_PROGRAM_WRAPPER_STATIC_AUDIT_FAILED'}
$receipt=[ordered]@{task='G2B-HW0-PRODUCT-R3R3';utc=[DateTime]::UtcNow.ToString('o');bitstream_path=$fi.FullName;bitstream_size=$fi.Length;bitstream_sha256=$bitHash;source_branch=$branch;source_commit=$commit;source_tree=$tree;source_tracked_clean=$trackedClean;source_index_clean=$indexClean;vivado=$vivado;tcl=$tcl;tcl_sha256=(Get-FileHash -LiteralPath $tcl -Algorithm SHA256).Hash;static_program_hw_devices_calls=$programCalls;static_cfgmem_calls=$forbiddenCalls;delivery_attempt=1;automatic_retry='DENIED';result='DELIVERY_IN_PROGRESS_NO_RETRY'}
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
$lock.sram_programming_attempts=1
$lock | Add-Member -NotePropertyName sram_programming_budget_remaining -NotePropertyValue 0 -Force
$lock | Add-Member -NotePropertyName sram_programming_delivery_utc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
[IO.File]::WriteAllText($lockPath,($lock|ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
$log=Join-Path $root 'logs\vivado-program.log'
$journal=Join-Path $root 'logs\vivado-program.jou'
& $vivado -mode batch -journal $journal -log $log -source $tcl 2>&1 | Tee-Object -FilePath (Join-Path $root 'logs\vivado-program-console.log')
$rc=$LASTEXITCODE
$logText=if(Test-Path -LiteralPath $log){[IO.File]::ReadAllText($log)}else{''}
$pass=$rc -eq 0 -and $logText.Contains('PROGRAM_TCL_RESULT=PASS_DONE_1',[StringComparison]::Ordinal) -and $logText.Contains('POSTPROGRAM_FPGA_DONE=1',[StringComparison]::Ordinal)
$receipt.result=if($pass){'PASS'}else{'FAIL_NO_RETRY'}
$receipt.vivado_exit_code=$rc
$receipt.program_tcl_pass=$pass
$receipt.end_utc=[DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
if(-not $pass){throw 'R3R3_EXACT_PRODUCT_SRAM_PROGRAMMING_FAILED_NO_RETRY'}
'R3R3_EXACT_PRODUCT_SRAM_PROGRAMMING=PASS'
