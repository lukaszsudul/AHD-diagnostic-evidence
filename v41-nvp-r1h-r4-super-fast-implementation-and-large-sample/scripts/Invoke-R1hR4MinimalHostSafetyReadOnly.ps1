[CmdletBinding()]
param([ValidateRange(60,600)][int]$TimeoutSeconds = 180)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $gzip = [IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true)
        try { $gzip.Write($Bytes,0,$Bytes.Length) } finally { $gzip.Dispose() }
        return [Convert]::ToBase64String($output.ToArray())
    } finally { $output.Dispose() }
}

function Get-UniqueValue([string]$Text,[string]$Key) {
    $matches = [regex]::Matches($Text,'(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

Assert-R1hAcceptedToolSet
$safetyRoot = Join-Path $script:R1hPrecheckRoot '00_MINIMAL_SAFETY'
$payloadPath = Join-Path $PSScriptRoot 'r1h_r4_minimal_host_safety_readonly.sh'
$outputPath = Join-Path $safetyRoot 'R1H_R4_HOST_SAFETY_RAW.log'
$gatePath = Join-Path $safetyRoot 'R1H_R4_HOST_SAFETY_GATE.txt'
foreach ($path in @($outputPath,$gatePath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite host-safety evidence: $path" }
}
if (-not (Test-Path -LiteralPath $payloadPath -PathType Leaf)) { throw 'task-local host-safety payload is absent' }
$payloadSha = (Get-FileHash -LiteralPath $payloadPath -Algorithm SHA256).Hash
$payload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($payloadPath))
$remoteTemplate = 'sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s'' _ ''{0}'''
$remoteCommand = $remoteTemplate -f $payload
& $script:R1hAcceptedTools.ContextualPlink.Path `
    -PlinkPath $script:R1hAcceptedTools.Plink084.Path `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand -EvidencePath $outputPath `
    -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R1H_R4_MINIMAL_HOST_SAFETY_READ_ONLY' `
    -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds $TimeoutSeconds
$processExit = $LASTEXITCODE
$text = [IO.File]::ReadAllText($outputPath)
$failures = [Collections.Generic.List[string]]::new()
try {
    $contextResult = Get-UniqueValue $text RESULT
    $remoteExit = Get-UniqueValue $text EXIT_CODE
    $remoteGate = Get-UniqueValue $text R1H_R4_HOST_SAFETY_GATE
    $kernel = Get-UniqueValue $text CURRENT_KERNEL
    $nextKernel = Get-UniqueValue $text NEXT_REBOOT_KERNEL_PROVEN
    $owners = Get-UniqueValue $text XDMA_NODE_OWNERS
    $dma = Get-UniqueValue $text TASK_DMA_COMMANDS
    $health = Get-UniqueValue $text KERNEL_AER_XDMA_HEALTH
    $moduleSha = Get-UniqueValue $text PINNED_MODULE_SHA256
    $loaderSha = Get-UniqueValue $text ACCEPTED_LOADER_SHA256
    $readOnly = Get-UniqueValue $text HOST_SAFETY_DISCOVERY_READ_ONLY
} catch {
    $failures.Add($_.Exception.Message)
    $contextResult='UNKNOWN';$remoteExit='UNKNOWN';$remoteGate='UNKNOWN';$kernel='UNKNOWN'
    $nextKernel='UNKNOWN';$owners='UNKNOWN';$dma='UNKNOWN';$health='UNKNOWN'
    $moduleSha='UNKNOWN';$loaderSha='UNKNOWN';$readOnly='UNKNOWN'
}
if ($processExit -ne 0 -or $contextResult -cne 'PASS' -or $remoteExit -cne '0' -or
    $remoteGate -cne 'PASS' -or $kernel -cne '7.0.0-29-generic' -or
    $nextKernel -cne '7.0.0-29-generic' -or $owners -cne '0' -or $dma -cne '0' -or
    $health -cne 'PASS' -or $readOnly -cne 'YES' -or
    $moduleSha -cne '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A' -or
    $loaderSha -cne '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F') {
    $failures.Add('MINIMAL_HOST_SAFETY_CONTRACT')
}
$gate = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$lines = [Collections.Generic.List[string]]::new()
foreach ($line in @(
    "R1H_R4_HOST_SAFETY_GATE=$gate","CURRENT_KERNEL=$kernel","NEXT_REBOOT_KERNEL=$nextKernel",
    "XDMA_NODE_OWNERS=$owners","TASK_DMA_COMMANDS=$dma","KERNEL_AER_XDMA_HEALTH=$health",
    "PINNED_MODULE_SHA256=$moduleSha","ACCEPTED_LOADER_SHA256=$loaderSha",
    "PAYLOAD_SHA256=$payloadSha","RAW_EVIDENCE_SHA256=$((Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash)",
    'READ_ONLY_GATE=YES','MMIO_WRITES=0','DMA_TRANSFERS=0')) { $lines.Add($line) }
foreach ($failure in $failures) { $lines.Add("FAILURE=$failure") }
Write-R1hUtf8NoBom -Path $gatePath -Lines $lines.ToArray()
$lines
if ($gate -cne 'PASS') { exit 1 }
