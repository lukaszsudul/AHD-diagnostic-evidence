[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$controllerReceipt = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$helper = Join-Path $taskRoot 'tools\Invoke-G2BR3Plink_proven.ps1'
$plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$scriptPath = Join-Path $taskRoot 'tools\exclusivity_deep_readonly.sh'
$evidencePath = Join-Path $taskRoot 'raw\EXCLUSIVITY_DEEP_READONLY_V2_POST_JTAG.log'
foreach ($required in @($controllerReceipt, $helper, $plink, $scriptPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "DEEP_EXCLUSIVITY_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $evidencePath) { throw 'DEEP_EXCLUSIVITY_V2_EVIDENCE_EXISTS' }
$lock = Get-Content -LiteralPath $controllerReceipt -Raw | ConvertFrom-Json
if ($lock.state -cne 'HELD' -or $lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.linux_lock_state -cne 'HELD') { throw 'LOCK_STATE_INVALID' }
$remoteCommand = Get-Content -LiteralPath $scriptPath -Raw
& $helper -PlinkPath $plink -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' -RemoteCommand $remoteCommand -EvidencePath $evidencePath -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind 'R3_EXCLUSIVITY_DEEP_READONLY_V2_POST_JTAG' -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 90
exit $LASTEXITCODE
