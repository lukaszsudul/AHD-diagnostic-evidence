[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][string]$BindingPath
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1fCampaignCommon.ps1')

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output=[IO.MemoryStream]::new()
    try{$gzip=[IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true);try{$gzip.Write($Bytes,0,$Bytes.Length)}finally{$gzip.Dispose()};return[Convert]::ToBase64String($output.ToArray())}finally{$output.Dispose()}
}
function Require-ExactLine([string]$Path,[string]$Key,[string]$Expected) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "required predecessor evidence absent: $Path"}
    $text=[IO.File]::ReadAllText($Path);$count=[regex]::Matches($text,'(?m)^'+[regex]::Escape($Key)+'='+[regex]::Escape($Expected)+'\r?$').Count
    if($count-ne1){throw "$Key=$Expected exact-line count is $count, expected 1"}
}

$binding=Get-R1fBindingDocument -BindingPath $BindingPath
Assert-R1fAcceptedToolSet
$phase=Get-R1fPhaseSpec $PhaseToken
$directory=Assert-R1fPhaseDirectory $phase
Require-ExactLine (Join-Path $directory 'LOADER_EVIDENCE.log') RESULT PASS
$output=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
if(Test-Path -LiteralPath $output){throw 'refusing to overwrite telemetry evidence'}
$readerPath=[string]$binding.r1fReader.path
$readerSha=[string]$binding.r1fReader.sha256
$readerPayload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($readerPath))
$expect=if($phase.Image-ceq'R1F'){'r1f'}else{'formal'}
$remoteOutput="/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1f/$($PhaseToken.ToLowerInvariant())_telemetry"
$template='sudo -S -k -p '''' /usr/bin/bash -c ''set -eu; out="$1"; test ! -e "$out"; printf %s "$2" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/python3 - --node /dev/xdma0_user --expect "$3" --twice --delay 1.0 --output-dir "$out"'' _ ''{0}'' ''{1}'' ''{2}'''
$remoteCommand=$template -f $remoteOutput,$readerPayload,$expect
$helper=$script:R1fAcceptedTools.ContextualPlink.Path
&$helper -PlinkPath $script:R1fAcceptedTools.Plink084.Path -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand -EvidencePath $output -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
    -EvidenceKind("R1F_FULL_TELEMETRY_{0}_{1}"-f$PhaseToken,$expect.ToUpperInvariant()) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 180
$rc=$LASTEXITCODE
if($rc-ne0){exit $rc}
$text=[IO.File]::ReadAllText($output)
foreach($required in @('RESULT=PASS','EXIT_CODE=0','READ_ONLY=YES','STATIC_SNAPSHOTS_MATCH=YES')) {
    if(-not$text.Contains($required,[StringComparison]::Ordinal)){throw "telemetry contract missing $required"}
}
"R1F_READER_PATH=$readerPath"
"R1F_READER_SHA256=$readerSha"
"REMOTE_OUTPUT_DIRECTORY=$remoteOutput"
'TELEMETRY_GATE=PASS_READ_ONLY_TWO_COHERENT_SNAPSHOTS'
