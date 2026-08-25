[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function Get-UniqueValue([string]$Text,[string]$Key) {
    $matches = [regex]::Matches($Text,'(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

function Require-Line([string]$Text,[string]$Key,[string]$Expected) {
    $value = Get-UniqueValue $Text $Key
    if ($value -cne $Expected) { throw "$Key=$value, expected $Expected" }
}

function Parse-Double([string]$Text,[string]$Key) {
    $value = Get-UniqueValue $Text $Key
    [double]$parsed = 0
    if (-not [double]::TryParse($value,[Globalization.NumberStyles]::Float,
            [Globalization.CultureInfo]::InvariantCulture,[ref]$parsed)) {
        throw "$Key is not a finite invariant-culture number: $value"
    }
    return $parsed
}

$implementationReceipt = Join-Path $script:R1hTaskRoot 'implementation\R1H_R4_IMPLEMENTATION_RESULT.txt'
$r1hBitPath = Join-Path $script:R1hTaskRoot 'implementation\ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit'
$formalBitPath = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit'
$jtagGatePath = Join-Path $script:R1hTaskRoot 'hardware\00_MINIMAL_SAFETY\R1H_R4_JTAG_SAFETY_GATE.txt'
$hostGatePath = Join-Path $script:R1hTaskRoot 'hardware\00_MINIMAL_SAFETY\R1H_R4_HOST_SAFETY_GATE.txt'
$combinedGatePath = Join-Path $script:R1hTaskRoot 'hardware\R1H_R4_MINIMAL_HARDWARE_SAFETY_GATE.txt'
$bindingPath = Join-Path $script:R1hTaskRoot 'hardware\R1H_R4_HARDWARE_BINDING.json'
foreach ($output in @($combinedGatePath,$bindingPath)) {
    if (Test-Path -LiteralPath $output) { throw "refusing to overwrite hardware binding output: $output" }
}
foreach ($required in @($implementationReceipt,$r1hBitPath,$formalBitPath,$jtagGatePath,$hostGatePath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "required hardware binding input absent: $required" }
}

$implementationText = [IO.File]::ReadAllText($implementationReceipt)
foreach ($pair in @(
    @('R1H_R4_IMPLEMENTATION_RESULT','PASS'),
    @('R1H_SYNTH_DCP_SHA256','807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E'),
    @('R1H_SOURCE_COMMIT','c4f4bfcf577c92c3021d1fe83c05878dd12e001c'),
    @('PLACE','PASS'),@('ROUTE','PASS'),@('ROUTE_ERRORS','0'),@('UNROUTED_NETS','0'),
    @('DRC_ERRORS','0'),@('DRC_CRITICAL_WARNINGS','0'),
    @('SOURCE_COMMIT_TO_BIT_PROVENANCE','PASS_BY_EXACT_SHA_BOUND_DCP'))) {
    Require-Line $implementationText $pair[0] $pair[1]
}
$postOptLut = Parse-Double $implementationText POST_OPT_SLICE_LUTS
$postOptReg = Parse-Double $implementationText POST_OPT_SLICE_REGISTERS
$finalLut = Parse-Double $implementationText FINAL_SLICE_LUTS
$finalReg = Parse-Double $implementationText FINAL_SLICE_REGISTERS
$wns = Parse-Double $implementationText WNS
$whs = Parse-Double $implementationText WHS
if ($postOptLut -gt 19760 -or $postOptReg -gt 37440 -or $finalLut -gt 19760 -or
    $finalReg -gt 37440 -or $wns -lt 0 -or $whs -le 0) {
    throw 'R1h-R4 implementation resource/timing hard gate failed'
}

$r1hBit = Get-Item -LiteralPath $r1hBitPath
$r1hBitSha = (Get-FileHash -LiteralPath $r1hBitPath -Algorithm SHA256).Hash
if ($r1hBit.Length -ne 2192144L -or $r1hBitSha -cne (Get-UniqueValue $implementationText R1H_BIT_SHA256)) {
    throw 'generated R1h bit file/receipt identity mismatch'
}
$formalBit = Get-Item -LiteralPath $formalBitPath
$formalSha = (Get-FileHash -LiteralPath $formalBitPath -Algorithm SHA256).Hash
if ($formalBit.Length -ne 2192144L -or $formalSha -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2') {
    throw 'formal Phase-2 bit identity mismatch'
}

$jtagText = [IO.File]::ReadAllText($jtagGatePath)
$hostText = [IO.File]::ReadAllText($hostGatePath)
Require-Line $jtagText R1H_R4_JTAG_SAFETY_GATE PASS
Require-Line $jtagText SELECTED_JTAG 'Xilinx/80802026a98b01'
Require-Line $jtagText FPGA_PART xc7a35t
Require-Line $jtagText FPGA_IDCODE 0362D093
Require-Line $jtagText JTAG_FREQUENCY_CHANGED NO
Require-Line $jtagText READ_ONLY_GATE YES
Require-Line $hostText R1H_R4_HOST_SAFETY_GATE PASS
Require-Line $hostText CURRENT_KERNEL '7.0.0-29-generic'
Require-Line $hostText NEXT_REBOOT_KERNEL '7.0.0-29-generic'
Require-Line $hostText XDMA_NODE_OWNERS 0
Require-Line $hostText TASK_DMA_COMMANDS 0
Require-Line $hostText KERNEL_AER_XDMA_HEALTH PASS
Require-Line $hostText READ_ONLY_GATE YES
$fullTargetPath = Get-UniqueValue $jtagText R1H_FULL_JTAG_TARGET_PATH
if (-not $fullTargetPath.EndsWith('/Xilinx/80802026a98b01',[StringComparison]::Ordinal) -and
    $fullTargetPath -cne 'Xilinx/80802026a98b01') {
    throw 'selected full JTAG target path is not exact canonical target/suffix'
}

$readerPath = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\scripts\v41\read_nvp_r1f.py'
$statisticsPath = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\scripts\v41\r1f_statistics.py'
[void](Assert-R1hExactFile $readerPath 46868L '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C')
[void](Assert-R1hExactFile $statisticsPath 38404L 'C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD')
Assert-R1hAcceptedToolSet

$releaseItem = Get-Item -LiteralPath $implementationReceipt
$binding = [ordered]@{
    schemaVersion = 1
    status = 'FROZEN_FOR_HARDWARE'
    continuationRevision = 'R4'
    selectedJtagCanonicalId = 'Xilinx/80802026a98b01'
    selectedFullJtagTargetPath = $fullTargetPath
    fpgaPart = 'xc7a35t'
    fpgaIdcode = '0362D093'
    host = [ordered]@{ ip='10.132.1.111'; user='vcdeagent1'; kernel='7.0.0-29-generic' }
    driver = [ordered]@{
        modulePath='/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko'
        moduleSha256='1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A'
        loaderPath='/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh'
        loaderSha256='7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F'
    }
    formalBit = [ordered]@{
        path=$formalBit.FullName;filename=$formalBit.Name;bytes=$formalBit.Length;sha256=$formalSha
        sourceCommit='c89e88bcdf389614c884fb129e8b2d42a585bccb'
        sourceTree='417820c69c134161fcafae0947dc5976919814d1';requiredWaitSeconds=5.0
    }
    r1hBit = [ordered]@{
        path=$r1hBit.FullName;filename=$r1hBit.Name;bytes=$r1hBit.Length;sha256=$r1hBitSha
        sourceCommit='c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
        sourceTree='161e561f007912d73dba93c5ecd78e3cc3a6955b'
        modeledProbeCompleteSeconds=31.536673744;requiredWaitSeconds=33.536673744
    }
    r1hReader = [ordered]@{
        path=$readerPath;bytes=46868;sha256='5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C'
        responseLatencyContract='BLOCKING_PREAD_VARIABLE_LATENCY'
    }
    r1hStatistics = [ordered]@{
        path=$statisticsPath;bytes=38404;sha256='C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD'
    }
    r1hBuildRelease = [ordered]@{
        path=$releaseItem.FullName;bytes=$releaseItem.Length
        sha256=(Get-FileHash -LiteralPath $releaseItem.FullName -Algorithm SHA256).Hash
    }
    r1hSourceCommit = 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
    r1hSourceTree = '161e561f007912d73dba93c5ecd78e3cc3a6955b'
    globalProgramRetryBudget = 1
}
[IO.File]::WriteAllText($bindingPath,($binding | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
$bindingSha = (Get-FileHash -LiteralPath $bindingPath -Algorithm SHA256).Hash
Write-R1hUtf8NoBom -Path $combinedGatePath -Lines @(
    'R1H_R4_MINIMAL_HARDWARE_SAFETY_GATE=PASS','READ_ONLY_GATE=YES',
    "R1H_FULL_JTAG_TARGET_PATH=$fullTargetPath","FPGA_PART=xc7a35t","FPGA_IDCODE=0362D093",
    'CURRENT_KERNEL=7.0.0-29-generic','NEXT_REBOOT_KERNEL=7.0.0-29-generic',
    'XDMA_NODE_OWNERS=0','TASK_DMA_COMMANDS=0','KERNEL_AER_XDMA_HEALTH=PASS',
    "FORMAL_BIT_SHA256=$formalSha","R1H_BIT_SHA256=$r1hBitSha",
    "IMPLEMENTATION_RECEIPT_SHA256=$((Get-FileHash -LiteralPath $implementationReceipt -Algorithm SHA256).Hash)",
    "JTAG_GATE_SHA256=$((Get-FileHash -LiteralPath $jtagGatePath -Algorithm SHA256).Hash)",
    "HOST_GATE_SHA256=$((Get-FileHash -LiteralPath $hostGatePath -Algorithm SHA256).Hash)",
    "HARDWARE_BINDING_SHA256=$bindingSha",'MMIO_WRITES=0','DMA_TRANSFERS=0')
"HARDWARE_BINDING_PATH=$bindingPath"
"HARDWARE_BINDING_SHA256=$bindingSha"
"MINIMAL_HARDWARE_SAFETY_GATE_PATH=$combinedGatePath"
"MINIMAL_HARDWARE_SAFETY_GATE_SHA256=$((Get-FileHash -LiteralPath $combinedGatePath -Algorithm SHA256).Hash)"
