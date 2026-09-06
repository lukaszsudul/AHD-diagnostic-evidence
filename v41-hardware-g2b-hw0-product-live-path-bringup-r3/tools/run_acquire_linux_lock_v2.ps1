[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$controllerReceipt = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$scriptPath = Join-Path $taskRoot 'tools\acquire_linux_lock_v2.sh'
$evidencePath = Join-Path $taskRoot 'raw\LINUX_LOCK_ACQUIRE_V2.log'

foreach ($required in @($controllerReceipt, $helper, $plink, $scriptPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "REQUIRED_FILE_MISSING=$required" }
}
if (Test-Path -LiteralPath $evidencePath) { throw 'LINUX_LOCK_V2_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $controllerReceipt -Raw | ConvertFrom-Json
if ($lock.state -cne 'HELD' -or $lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.linux_lock_state -cne 'NOT_YET_ACQUIRED') {
    throw 'CONTROLLER_LOCK_STATE_INVALID_FOR_LINUX_LOCK_V2'
}

$remoteCommand = Get-Content -LiteralPath $scriptPath -Raw
& $helper `
    -PlinkPath $plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $evidencePath `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R3_LINUX_LOCK_ACQUIRE_V2' `
    -TimeoutSeconds 45
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) { exit $exitCode }

$text = [IO.File]::ReadAllText($evidencePath)
foreach ($marker in @('RESULT=PASS','LINUX_LOCK=HELD','OTHER_TASK_LOCK_COUNT_BEFORE_LOCK=0','ENDPOINT_BDF=0000:01:00.0')) {
    if (-not $text.Contains($marker, [StringComparison]::Ordinal)) { throw "LINUX_LOCK_MARKER_MISSING=$marker" }
}
$receiptMatch = [regex]::Match($text, '(?s)LINUX_LOCK_RECEIPT_BEGIN\s*(\{.*?\})\s*LINUX_LOCK_RECEIPT_END')
if (-not $receiptMatch.Success) { throw 'LINUX_LOCK_RECEIPT_NOT_FOUND' }
$linuxReceipt = $receiptMatch.Groups[1].Value | ConvertFrom-Json
if ($linuxReceipt.task_id -cne 'G2B-HW0-PRODUCT-R3' -or $linuxReceipt.lock_release_state -cne 'HELD') { throw 'LINUX_LOCK_RECEIPT_SEMANTICS_FAILED' }
[IO.File]::WriteAllText((Join-Path $taskRoot 'locks\LINUX_LOCK_RECEIPT.json'), $receiptMatch.Groups[1].Value + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

$controller = Get-Content -LiteralPath $controllerReceipt -Raw | ConvertFrom-Json
$controller.linux_lock_state = 'HELD'
$controller | Add-Member -NotePropertyName linux_lock_path -NotePropertyValue '/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock' -Force
$controller | Add-Member -NotePropertyName dut_artifact_path -NotePropertyValue '/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3/20260906T140148Z' -Force
$controller | Add-Member -NotePropertyName boot_id -NotePropertyValue '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac' -Force
$controllerJson = $controller | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText($controllerReceipt, $controllerJson + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $taskRoot 'locks\CONTROLLER_LOCK_AFTER_LINUX_ACQUIRE.json'), $controllerJson + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Write-Output 'LINUX_LOCK=HELD'
Write-Output 'CONTROLLER_LOCK=HELD'
exit 0
