[CmdletBinding()]
param([ValidateRange(3,60)][int]$MinimumSpanSeconds=3)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture=[Globalization.CultureInfo]::InvariantCulture
. 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\R1fCampaignCommon.ps1'

function ConvertTo-GzipBase64([byte[]]$Bytes){$m=[IO.MemoryStream]::new();try{$g=[IO.Compression.GzipStream]::new($m,[IO.Compression.CompressionLevel]::Optimal,$true);try{$g.Write($Bytes,0,$Bytes.Length)}finally{$g.Dispose()};return[Convert]::ToBase64String($m.ToArray())}finally{$m.Dispose()}}
function Get-Value([string]$Text,[string]$Key){$m=[regex]::Matches($Text,'(?m)^'+[regex]::Escape($Key)+'=([^\r\n]*)\r?$');if($m.Count-ne1){throw "$Key exact-line count is $($m.Count), expected 1"};return$m[0].Groups[1].Value}

Assert-R1fAcceptedToolSet
$helper=$script:R1fAcceptedTools.ContextualPlink.Path
$payloadPath=$script:R1fAcceptedTools.HostBaselinePayload.Path
$payload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($payloadPath))
$hostKey='SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$paths=@(
    (Join-Path $script:R1fPrecheckRoot 'HOST_BASELINE_SESSION_1.log'),
    (Join-Path $script:R1fPrecheckRoot 'HOST_BASELINE_SESSION_2.log')
)
$matrixPath=Join-Path $script:R1fPrecheckRoot 'R1F_HOST_BASELINE_MATRIX.csv'
$gatePath=Join-Path $script:R1fPrecheckRoot 'R1F_HOST_BASELINE_GATE.txt'
foreach($path in @($paths+$matrixPath+$gatePath)){if(Test-Path -LiteralPath $path){throw "refusing to overwrite host-baseline evidence: $path"}}
$records=[Collections.Generic.List[object]]::new();$failures=[Collections.Generic.List[string]]::new();$frequency=[Diagnostics.Stopwatch]::Frequency
for($session=1;$session-le2;$session++){
    if($session-eq2){Start-Sleep -Seconds $MinimumSpanSeconds}
    $localStart=[Diagnostics.Stopwatch]::GetTimestamp()
    $template='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2"'' _ ''{0}'' ''{1}'''
    $remoteCommand=$template-f$payload,$session
    &$helper -PlinkPath $script:R1fAcceptedTools.Plink084.Path -HostKey $hostKey -RemoteCommand $remoteCommand `
        -EvidencePath $paths[$session-1] -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' `
        -EvidenceKind("R1F_HOST_BASELINE_SESSION_{0}"-f$session) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 120
    $helperExit=$LASTEXITCODE;$localEnd=[Diagnostics.Stopwatch]::GetTimestamp();$text=[IO.File]::ReadAllText($paths[$session-1])
    try{
        $row=[pscustomobject]@{Session=$session;LocalStart=$localStart;LocalEnd=$localEnd;Result=(Get-Value $text RESULT);ExitCode=(Get-Value $text EXIT_CODE);Hostname=(Get-Value $text HOSTNAME);User=(Get-Value $text REMOTE_USER);EffectiveUser=(Get-Value $text REMOTE_EFFECTIVE_USER);Kernel=(Get-Value $text CURRENT_KERNEL);BootId=(Get-Value $text CURRENT_BOOT_ID);Uptime=[double]::Parse((Get-Value $text UPTIME_SECONDS),[Globalization.CultureInfo]::InvariantCulture);RemoteUtc=(Get-Value $text REMOTE_UTC);NextKernel=(Get-Value $text NEXT_REBOOT_KERNEL_PROVEN);ReadOnly=(Get-Value $text HOST_BASELINE_SAMPLE_READ_ONLY);SampleGate=(Get-Value $text HOST_BASELINE_SAMPLE_GATE);HelperExit=$helperExit}
    }catch{$failures.Add("SESSION_${session}_PARSE=$($_.Exception.Message)");throw}
    if($helperExit-ne0-or$row.Result-cne'PASS'-or$row.ExitCode-cne'0'-or$row.ReadOnly-cne'YES'-or$row.SampleGate-cne'PASS'){$failures.Add("SESSION_${session}_GATE")}
    $records.Add($row)
}
$a=$records[0];$b=$records[1]
if($a.Hostname-cne$b.Hostname-or$a.User-cne'vcdeagent1'-or$b.User-cne'vcdeagent1'){$failures.Add('HOSTNAME_OR_USER_STABILITY')}
if($a.EffectiveUser-cne'root'-or$b.EffectiveUser-cne'root'){$failures.Add('PRIVILEGED_READ_ONLY_CONTEXT')}
if($a.Kernel-cne'7.0.0-29-generic'-or$b.Kernel-cne'7.0.0-29-generic'-or$a.NextKernel-cne'7.0.0-29-generic'-or$b.NextKernel-cne'7.0.0-29-generic'){$failures.Add('KERNEL_OR_NEXT_KERNEL')}
if($a.BootId-cne$b.BootId-or$a.BootId-notmatch'^[0-9a-f-]{36}$'){$failures.Add('BOOT_ID_STABILITY')}
$remoteSpan=$b.Uptime-$a.Uptime;$localSpan=[double]($b.LocalEnd-$a.LocalStart)/$frequency
if($remoteSpan-lt$MinimumSpanSeconds-or$localSpan-lt$MinimumSpanSeconds){$failures.Add('BASELINE_SPAN')}
$csv=[Collections.Generic.List[string]]::new();$csv.Add('session,local_start_tick,local_end_tick,remote_utc,hostname,user,kernel,boot_id,uptime_seconds,next_kernel,result')
foreach($r in $records){$csv.Add(('{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}'-f$r.Session,$r.LocalStart,$r.LocalEnd,$r.RemoteUtc,$r.Hostname,$r.User,$r.Kernel,$r.BootId,$r.Uptime,$r.NextKernel,$r.Result))}
Write-R1fUtf8NoBom -Path $matrixPath -Lines $csv.ToArray()
$gate=if($failures.Count-eq0){'PASS_2_OF_2'}else{'FAIL'}
$lines=[Collections.Generic.List[string]]::new();foreach($line in @("R1F_HOST_BASELINE=$gate","R1F_BOOT_ID_BASELINE=$($a.BootId)",'READ_ONLY_SSH_SESSIONS=2',"NEXT_REBOOT_KERNEL_PROVEN=$($a.NextKernel)","REMOTE_UPTIME_SPAN_SECONDS=$remoteSpan","LOCAL_MONOTONIC_SPAN_SECONDS=$localSpan",'NO_OBSERVED_REBOOT_OR_SHUTDOWN='+$(if($gate-eq'PASS_2_OF_2'){'YES'}else{'NOT_PROVEN'}),"HOST_SAMPLE_PAYLOAD_SHA256=$($script:R1fAcceptedTools.HostBaselinePayload.Sha256)")){$lines.Add($line)};foreach($f in $failures){$lines.Add("FAILURE=$f")}
Write-R1fUtf8NoBom -Path $gatePath -Lines $lines.ToArray();$lines
if($gate-cne'PASS_2_OF_2'){exit 1}
