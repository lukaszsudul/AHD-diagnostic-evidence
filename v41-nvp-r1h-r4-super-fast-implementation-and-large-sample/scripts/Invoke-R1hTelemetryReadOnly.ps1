[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][string]$BindingPath,
    [switch]$RuntimeOnly
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output=[IO.MemoryStream]::new()
    try{$gzip=[IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true);try{$gzip.Write($Bytes,0,$Bytes.Length)}finally{$gzip.Dispose()};return [Convert]::ToBase64String($output.ToArray())}finally{$output.Dispose()}
}
function New-R1hCombinedReaderBytes([string]$R1ePath,[string]$R1fPath) {
    $r1e=[Convert]::ToBase64String([IO.File]::ReadAllBytes($R1ePath))
    $r1f=[Convert]::ToBase64String([IO.File]::ReadAllBytes($R1fPath))
    $lines=@(
        'import base64, sys, types',
        "r1e_source = base64.b64decode('$r1e')",
        "r1f_source = base64.b64decode('$r1f')",
        "r1e = types.ModuleType('read_nvp_r1e')",
        "r1e.__file__ = 'read_nvp_r1e.py'",
        "exec(compile(r1e_source, r1e.__file__, 'exec'), r1e.__dict__)",
        "sys.modules['read_nvp_r1e'] = r1e",
        "scope = {'__name__': '__main__', '__file__': 'read_nvp_r1f.py'}",
        "exec(compile(r1f_source, scope['__file__'], 'exec'), scope)"
    )
    return [Text.UTF8Encoding]::new($false).GetBytes(($lines-join"`n")+"`n")
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
$adapterReceipt=Join-Path $directory 'TELEMETRY_READER_PAYLOAD_RECEIPT.txt'
foreach($fresh in @($output,$runtimeOutput,$adapterReceipt)){if(Test-Path -LiteralPath $fresh){throw "refusing to overwrite telemetry/provenance evidence: $fresh"}}
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
if($RuntimeOnly) {
    if($PhaseToken-ne'Bootstrap'){throw 'RuntimeOnly is authorized only for mandatory formal bootstrap'}
    'RUNTIME_ONLY_GATE=PASS_FORMAL_IDENTITY_DIAGNOSTIC_MAGIC_READ_ONLY'
    "RUNTIME_PROVENANCE_EVIDENCE_SHA256=$((Get-FileHash -LiteralPath $runtimeOutput -Algorithm SHA256).Hash)"
    return
}
$readerPath=if($phase.Image-ceq'R1H'){[string]$binding.r1hReader.path}else{$script:R1hAcceptedTools.FormalTelemetryReader.Path}
$readerSha=if($phase.Image-ceq'R1H'){[string]$binding.r1hReader.sha256}else{$script:R1hAcceptedTools.FormalTelemetryReader.Sha256}
$readerBytes=if($phase.Image-ceq'R1H'){New-R1hCombinedReaderBytes $script:R1hAcceptedTools.FormalTelemetryReader.Path $readerPath}else{[IO.File]::ReadAllBytes($readerPath)}
$readerPayload=ConvertTo-GzipBase64($readerBytes)
$readerPayloadSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($readerBytes))
Write-R1hUtf8NoBom -Path $adapterReceipt -Lines @(
    "IMAGE_CLASS=$($phase.Image)","PRIMARY_READER_PATH=$readerPath","PRIMARY_READER_SHA256=$readerSha",
    "R1E_DEPENDENCY_SHA256=$($script:R1hAcceptedTools.FormalTelemetryReader.Sha256)",
    "PAYLOAD_CLASS=$(if($phase.Image-ceq'R1H'){'TASK_LOCAL_IN_MEMORY_EXACT_R1E_PLUS_R1F_MODULE_ADAPTER'}else{'EXACT_FORMAL_READER'})",
    "PAYLOAD_SHA256=$readerPayloadSha",'REMOTE_TEMP_FILES=0','MMIO_ACCESS=READ_ONLY')
$expect=if($phase.Image-ceq'R1H'){'r1f'}else{'formal'}
$remoteOutputToken=if($phase.Image-ceq'R1H'){"v41_nvp_r1h_r4_61ec5f55/$($PhaseToken.ToLowerInvariant())_telemetry"}else{'NOT_APPLICABLE_FORMAL_STDOUT_ONLY'}
$remoteOutput=if($phase.Image-ceq'R1H'){"/home/vcdeagent1/FPGA_AHD_HOST/$remoteOutputToken"}else{'NOT_APPLICABLE_FORMAL_STDOUT_ONLY'}
if($phase.Image-ceq'R1H'){
    $template='sudo -S -k -p '''' /usr/bin/bash -c ''set -eu; out="/home/${{SUDO_USER}}/FPGA_AHD_HOST/$1"; test ! -e "$out"; printf %s "$2" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/python3 - --node /dev/xdma0_user --expect "$3" --twice --delay 1.0 --output-dir "$out"'' _ ''{0}'' ''{1}'' ''{2}'''
    $remoteCommand=$template -f $remoteOutputToken,$readerPayload,$expect
}else{
    $template='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/python3 - --node /dev/xdma0_user --expect "$2" --twice --delay 1.0'' _ ''{0}'' ''{1}'''
    $remoteCommand=$template -f $readerPayload,$expect
}
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
"R1H_READER_PAYLOAD_SHA256=$readerPayloadSha"
"R1H_READER_PAYLOAD_RECEIPT_SHA256=$((Get-FileHash -LiteralPath $adapterReceipt -Algorithm SHA256).Hash)"
"REMOTE_OUTPUT_DIRECTORY=$remoteOutput"
'TELEMETRY_GATE=PASS_READ_ONLY_TWO_COHERENT_SNAPSHOTS'
