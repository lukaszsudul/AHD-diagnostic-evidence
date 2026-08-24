[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][string]$BindingPath
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output=[IO.MemoryStream]::new()
    try{$gzip=[IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true);try{$gzip.Write($Bytes,0,$Bytes.Length)}finally{$gzip.Dispose()};return[Convert]::ToBase64String($output.ToArray())}finally{$output.Dispose()}
}
function Require-ExactLine([string]$Path,[string]$Key,[string]$Expected) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "required predecessor evidence absent: $Path"}
    $text=[IO.File]::ReadAllText($Path);$count=[regex]::Matches($text,'(?m)^'+[regex]::Escape($Key)+'='+[regex]::Escape($Expected)+'\r?$').Count
    if($count-ne1){throw "$Key=$Expected exact-line count is $count, expected 1"}
}

$binding=Get-R1hBindingDocument -BindingPath $BindingPath
Assert-R1hAcceptedToolSet
$phase=Get-R1hPhaseSpec $PhaseToken
$directory=Assert-R1hPhaseDirectory $phase
Require-ExactLine (Join-Path $directory 'LOADER_EVIDENCE.log') RESULT PASS
$output=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
$runtimeOutput=Join-Path $directory 'RUNTIME_PROVENANCE_EVIDENCE.log'
foreach($fresh in @($output,$runtimeOutput)){if(Test-Path -LiteralPath $fresh){throw "refusing to overwrite telemetry/provenance evidence: $fresh"}}
$runtimePayload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($script:R1hAcceptedTools.RuntimeProvenancePayload.Path))
$runtimeRole=if($phase.Image-ceq'R1H'){'r1h'}else{'formal'}
$runtimeCommit=if($phase.Image-ceq'R1H'){[string]$binding.r1hSourceCommit}else{'NOT_APPLICABLE'}
$runtimeTemplate='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" /dev/xdma0_user'' _ ''{0}'' ''{1}'' ''{2}'''
$runtimeRemote=$runtimeTemplate -f $runtimePayload,$runtimeRole,$runtimeCommit
$helper=$script:R1hAcceptedTools.ContextualPlink.Path
&$helper -PlinkPath $script:R1hAcceptedTools.Plink084.Path -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $runtimeRemote -EvidencePath $runtimeOutput -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
    -EvidenceKind("R1H_RUNTIME_PROVENANCE_{0}_{1}"-f$PhaseToken,$runtimeRole.ToUpperInvariant()) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 180
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
$runtimeText=[IO.File]::ReadAllText($runtimeOutput)
foreach($required in @('RESULT=PASS','EXIT_CODE=0','RUNTIME_PROVENANCE_GATE=PASS','MMIO_ACCESS=READ_ONLY','AXI_LITE_WRITES=0','C2H_TRANSFERS=0','H2C_TRANSFERS=0')) {
    if(-not$runtimeText.Contains($required,[StringComparison]::Ordinal)){throw "runtime provenance contract missing $required"}
}
$readerPath=[string]$binding.r1hReader.path
$readerSha=[string]$binding.r1hReader.sha256
$readerPayload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($readerPath))
$expect=if($phase.Image-ceq'R1H'){'r1f'}else{'formal'}
$remoteOutput="/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/$($PhaseToken.ToLowerInvariant())_telemetry"
$template='sudo -S -k -p '''' /usr/bin/bash -c ''set -eu; out="$1"; test ! -e "$out"; printf %s "$2" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/python3 - --node /dev/xdma0_user --expect "$3" --twice --delay 1.0 --output-dir "$out"'' _ ''{0}'' ''{1}'' ''{2}'''
$remoteCommand=$template -f $remoteOutput,$readerPayload,$expect
$helper=$script:R1hAcceptedTools.ContextualPlink.Path
&$helper -PlinkPath $script:R1hAcceptedTools.Plink084.Path -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand -EvidencePath $output -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
    -EvidenceKind("R1H_FULL_TELEMETRY_{0}_{1}"-f$PhaseToken,$expect.ToUpperInvariant()) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 180
$rc=$LASTEXITCODE
if($rc-ne0){exit $rc}
$text=[IO.File]::ReadAllText($output)
foreach($required in @('RESULT=PASS','EXIT_CODE=0','READ_ONLY=YES','STATIC_SNAPSHOTS_MATCH=YES')) {
    if(-not$text.Contains($required,[StringComparison]::Ordinal)){throw "telemetry contract missing $required"}
}
"R1H_READER_PATH=$readerPath"
"R1H_READER_SHA256=$readerSha"
"REMOTE_OUTPUT_DIRECTORY=$remoteOutput"
'TELEMETRY_GATE=PASS_READ_ONLY_TWO_COHERENT_SNAPSHOTS'
