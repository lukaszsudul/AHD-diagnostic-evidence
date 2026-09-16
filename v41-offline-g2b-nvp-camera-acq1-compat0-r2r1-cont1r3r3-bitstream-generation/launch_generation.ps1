$ErrorActionPreference = 'Stop'

$taskRoot = 'C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z'
$originalDcp = 'C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R1_20260916T105442Z\signoff\CONT1R3R1_SIGNED_OFF_ROUTED.dcp'
$copiedDcp = Join-Path $taskRoot 'inputs\CONT1R3R1_SIGNED_OFF_ROUTED.dcp'
$outputBit = Join-Path $taskRoot 'firmware\AHD_v41_CONT1R3R3_DIAGNOSTIC.bit'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$tcl = Join-Path $taskRoot 'scripts\generate_exact_dcp_bitstream.tcl'
$log = Join-Path $taskRoot 'logs\vivado_generation.log'
$journal = Join-Path $taskRoot 'logs\vivado_generation.jou'
$expectedHash = 'C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2'
$expectedSize = 17469233

foreach ($item in @($originalDcp, $copiedDcp)) {
    $info = Get-Item -LiteralPath $item -ErrorAction Stop
    if ($info.Length -ne $expectedSize) { throw "DCP size mismatch: $item" }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item).Hash
    if ($hash -ne $expectedHash) { throw "DCP SHA-256 mismatch: $item" }
    Write-Output "VERIFIED_DCP=$item|$($info.Length)|$hash"
}
if (-not (Test-Path -LiteralPath $vivado -PathType Leaf)) { throw 'Exact Vivado launcher absent' }
if (-not (Test-Path -LiteralPath $tcl -PathType Leaf)) { throw 'Task Tcl absent' }
if (Test-Path -LiteralPath $outputBit) { throw 'Fresh bitstream output path occupied' }
if ((Test-Path -LiteralPath $log) -or (Test-Path -LiteralPath $journal)) { throw 'Fresh generation log/journal path occupied' }

$taskTemp = Join-Path $taskRoot 'logs\temp'
New-Item -ItemType Directory -Path $taskTemp -ErrorAction Stop | Out-Null
$env:TEMP = $taskTemp
$env:TMP = $taskTemp
Set-Location -LiteralPath (Join-Path $taskRoot 'logs')

Write-Output 'CONT1R3R3_VIVADO_LAUNCH_BEGIN'
& $vivado -mode batch -source $tcl -log $log -journal $journal
$code = $LASTEXITCODE
Write-Output "CONT1R3R3_VIVADO_EXIT_CODE=$code"
exit $code
