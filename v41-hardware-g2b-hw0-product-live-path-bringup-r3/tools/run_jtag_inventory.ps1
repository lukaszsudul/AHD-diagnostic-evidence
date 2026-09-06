[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$controllerReceipt = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$linuxReceipt = Join-Path $taskRoot 'locks\LINUX_LOCK_RECEIPT.json'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$sourceTcl = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906\tools\r2_jtag_final_state_session.tcl'
$sessionCsv = Join-Path $taskRoot 'raw\JTAG_T0_SESSION.csv'
$targetProperties = Join-Path $taskRoot 'raw\JTAG_T0_TARGET_PROPERTIES.tsv'
$deviceProperties = Join-Path $taskRoot 'raw\JTAG_T0_DEVICE_PROPERTIES.tsv'
$vivadoLog = Join-Path $taskRoot 'raw\JTAG_T0_VIVADO.log'
$vivadoJournal = Join-Path $taskRoot 'raw\JTAG_T0_VIVADO.jou'
$controllerStdio = Join-Path $taskRoot 'raw\JTAG_T0_CONTROLLER_STDIO.log'

foreach ($required in @($controllerReceipt, $linuxReceipt, $vivado, $sourceTcl)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "JTAG_PRECONDITION_MISSING=$required" }
}
foreach ($output in @($sessionCsv, $targetProperties, $deviceProperties, $vivadoLog, $vivadoJournal, $controllerStdio)) {
    if (Test-Path -LiteralPath $output) { throw "JTAG_OUTPUT_ALREADY_EXISTS=$output" }
}
$controller = Get-Content -LiteralPath $controllerReceipt -Raw | ConvertFrom-Json
$linux = Get-Content -LiteralPath $linuxReceipt -Raw | ConvertFrom-Json
if ($controller.state -cne 'HELD' -or $controller.task -cne 'G2B-HW0-PRODUCT-R3' -or $controller.linux_lock_state -cne 'HELD') {
    throw 'CONTROLLER_LOCK_NOT_HELD_FOR_JTAG'
}
if ($linux.task_id -cne 'G2B-HW0-PRODUCT-R3' -or $linux.lock_release_state -cne 'HELD') {
    throw 'LINUX_LOCK_NOT_HELD_FOR_JTAG'
}
$conflicts = @(Get-Process | Where-Object { $_.ProcessName -match '^(vivado|vivado_lab|hw_server|xsdb|cs_server|xicom)$' })
if ($conflicts.Count -ne 0) { throw 'LOCAL_JTAG_PROCESS_CONFLICT' }

& $vivado `
    -mode batch `
    -log $vivadoLog `
    -journal $vivadoJournal `
    -source $sourceTcl `
    -tclargs 3 $sessionCsv $targetProperties $deviceProperties *>&1 |
    Tee-Object -FilePath $controllerStdio
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) { exit $exitCode }

$rows = @(Import-Csv -LiteralPath $sessionCsv)
if ($rows.Count -ne 5) { throw 'JTAG_SAMPLE_COUNT_MISMATCH' }
foreach ($row in $rows) {
    if ($row.target_count -cne '1' -or $row.device_count -cne '1' -or
        $row.part -cne 'xc7a35t' -or $row.idcode -cne '0362D093' -or
        $row.done -cne '1' -or $row.refresh_result -cne 'PASS') {
        throw 'JTAG_SAMPLE_IDENTITY_OR_DONE_MISMATCH'
    }
}
Write-Output 'JTAG_T0_GATE=PASS'
Write-Output 'FPGA_PART=xc7a35t'
Write-Output 'FPGA_IDCODE=0362D093'
Write-Output 'FPGA_DONE=1'
Write-Output 'JTAG_CHAIN_INDEX=0'
Write-Output 'FPGA_PROGRAM_OPERATIONS=0'
