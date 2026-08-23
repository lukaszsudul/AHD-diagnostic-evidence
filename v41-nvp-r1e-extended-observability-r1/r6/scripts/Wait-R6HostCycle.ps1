[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('FormalBootstrap','ArmA','ArmB')][string]$Role,
    [Parameter(Mandatory=$true)][string]$EvidencePath,
    [ValidateRange(30,600)][int]$TimeoutSeconds=300,
    [ValidateRange(100,5000)][int]$ConnectTimeoutMilliseconds=1000,
    [ValidateRange(100,5000)][int]$PollMilliseconds=1000
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$taskRoot='C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6';$expectedIp='10.132.1.111'
$roleDirectory=switch($Role){'FormalBootstrap'{Join-Path $taskRoot '07_FORMAL_BOOTSTRAP'}'ArmA'{Join-Path $taskRoot '08_ARM_A_R1E'}'ArmB'{Join-Path $taskRoot '09_ARM_B_FORMAL'}}
$fullEvidence=[IO.Path]::GetFullPath($EvidencePath);$roleFull=[IO.Path]::GetFullPath($roleDirectory)
if(-not$fullEvidence.StartsWith($roleFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'host-cycle evidence must stay inside the selected R6 phase directory'};if(Test-Path -LiteralPath $fullEvidence){throw 'refusing to overwrite host-cycle evidence'};if(-not(Test-Path -LiteralPath(Split-Path -Parent $fullEvidence)-PathType Container)){throw 'host-cycle evidence parent directory does not exist'}
function Test-Tcp22{$client=[Net.Sockets.TcpClient]::new();try{$task=$client.ConnectAsync($expectedIp,22);if(-not$task.Wait($ConnectTimeoutMilliseconds)){return$false};if($task.IsFaulted){return$false};return$client.Connected}catch{return$false}finally{$client.Dispose()}}
$startUtc=[DateTime]::UtcNow.ToString('o');$frequency=[Diagnostics.Stopwatch]::Frequency;$startTicks=[Diagnostics.Stopwatch]::GetTimestamp();$deadlineTicks=$startTicks+[long]($TimeoutSeconds*$frequency);$records=[Collections.Generic.List[string]]::new();$downSeen=$false;$upAfterDownSeen=$false;$sample=0
while([Diagnostics.Stopwatch]::GetTimestamp()-lt$deadlineTicks){$sample++;$tick=[Diagnostics.Stopwatch]::GetTimestamp();$up=Test-Tcp22;$records.Add(('SAMPLE={0} TICK={1} TCP22={2}'-f$sample,$tick,$(if($up){'UP'}else{'DOWN'})));if(-not$downSeen-and-not$up){$downSeen=$true}elseif($downSeen-and$up){$upAfterDownSeen=$true;break};Start-Sleep -Milliseconds $PollMilliseconds}
$endTicks=[Diagnostics.Stopwatch]::GetTimestamp();$gate=if($downSeen-and$upAfterDownSeen){'PASS_HOST_DISAPPEARED_AND_RETURNED'}else{'FAIL'};$lines=[Collections.Generic.List[string]]::new();$lines.Add("ROLE=$Role");$lines.Add("UTC_START=$startUtc");$lines.Add("UTC_END=$([DateTime]::UtcNow.ToString('o'))");$lines.Add("STOPWATCH_FREQUENCY=$frequency");$lines.Add("START_TICKS=$startTicks");$lines.Add("END_TICKS=$endTicks");$lines.Add("HOST_DOWN_OBSERVED=$(if($downSeen){'YES'}else{'NO'})");$lines.Add("HOST_UP_AFTER_DOWN_OBSERVED=$(if($upAfterDownSeen){'YES'}else{'NO'})");$lines.Add("HOST_CYCLE_GATE=$gate");foreach($record in $records){$lines.Add($record)}
[IO.File]::WriteAllLines($fullEvidence,$lines,[Text.UTF8Encoding]::new($false));$lines|Select-Object -First 8;if($gate-cne'PASS_HOST_DISAPPEARED_AND_RETURNED'){exit 1};exit 0
