[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\FPGA\G2B_BT656_DIAG1_R1_20260908T175752Z'
$lockPath='C:\FPGA\.AHD_G2B_BT656_DIAG1_R1_20260908T175752Z.lock\receipt.json'
$bit=Join-Path $root 'artifacts\full_build_01\artifacts\G2B_BT656_DIAG1_R1_RAW_MARKER_TRACE.bit'
$tcl=Join-Path $root 'scripts\program-diag1-r1-once.tcl'
$vivado='C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$receiptPath=Join-Path $root 'artifacts\programming-receipt.json'
if(Test-Path -LiteralPath $receiptPath){throw 'BT656_DIAG1_R1_PROGRAM_RECEIPT_EXISTS_NO_RETRY'}
if(-not(Test-Path -LiteralPath $lockPath -PathType Leaf)){throw 'BT656_DIAG1_R1_CONTROLLER_LOCK_NOT_HELD'}
$lock=Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if($lock.task -cne 'G2B-BT656-DIAG1-R1' -or $lock.state -cne 'HELD'){throw 'BT656_DIAG1_R1_CONTROLLER_LOCK_OWNER_MISMATCH'}
if(-not(Test-Path -LiteralPath $vivado -PathType Leaf)){throw 'BT656_DIAG1_R1_VIVADO_UNAVAILABLE'}
$fi=Get-Item -LiteralPath $bit
$bitHash=(Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
if($fi.Length -ne 2192144 -or $bitHash -cne '02B590D4C6DC391A55C2EF237EA167A7352385C2BF0AD46C4DCCEA8D091684FB'){throw 'BT656_DIAG1_R1_EXACT_BITSTREAM_MISMATCH'}
$tclText=[IO.File]::ReadAllText($tcl)
$programCalls=([regex]::Matches($tclText,'(?m)^\s*program_hw_devices\s+')).Count
$forbiddenCalls=([regex]::Matches($tclText,'(?im)^\s*(create_hw_cfgmem|program_hw_cfgmem|write_cfgmem)\b')).Count
if($programCalls -ne 1 -or $forbiddenCalls -ne 0){throw 'BT656_DIAG1_R1_PROGRAM_STATIC_AUDIT_FAILED'}
$receipt=[ordered]@{task='G2B-BT656-DIAG1-R1';start_utc=[DateTime]::UtcNow.ToString('o');bitstream_path=$fi.FullName;bitstream_size=$fi.Length;bitstream_sha256=$bitHash;vivado=$vivado;tcl=$tcl;tcl_sha256=(Get-FileHash -LiteralPath $tcl).Hash;program_hw_devices_calls=$programCalls;cfgmem_calls=$forbiddenCalls;delivery_attempt=1;automatic_retry='DENIED';result='DELIVERY_IN_PROGRESS_NO_RETRY'}
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 5)+"`n",[Text.UTF8Encoding]::new($false))
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
if(-not $pass){throw 'BT656_DIAG1_R1_SRAM_PROGRAMMING_FAILED_NO_RETRY'}
'BT656_DIAG1_R1_SRAM_PROGRAMMING=PASS'
