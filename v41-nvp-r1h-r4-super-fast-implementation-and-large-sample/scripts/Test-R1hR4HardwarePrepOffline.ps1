[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskRoot='C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$toolCsv=Join-Path $taskRoot 'hardware\R1H_R4_EXACT_INHERITED_TOOL_IDENTITY.csv'
$output=Join-Path $taskRoot 'hardware\R1H_R4_HARDWARE_PREP_OFFLINE_GATE_FINAL3.txt'
$scriptCsv=Join-Path $taskRoot 'hardware\R1H_R4_TASK_LOCAL_SCRIPT_IDENTITY_FINAL3.csv'
foreach($path in @($output,$scriptCsv)){if(Test-Path -LiteralPath $path){throw "refusing to overwrite offline prep evidence: $path"}}

$failures=[Collections.Generic.List[string]]::new()
$rows=@(Import-Csv -LiteralPath $toolCsv)
foreach($row in $rows){
    try{
        $item=Get-Item -LiteralPath $row.path -ErrorAction Stop
        $sha=(Get-FileHash -LiteralPath $row.path -Algorithm SHA256).Hash
        if([long]$item.Length-ne[long]$row.bytes-or$sha-cne[string]$row.sha256){throw 'bytes/SHA mismatch'}
    }catch{$failures.Add("TOOL_IDENTITY=$($row.name):$($_.Exception.Message)")}
}

$credential='C:\FPGA\VCDE-DUT-1.txt'
try{
    $credentialItem=Get-Item -LiteralPath $credential -ErrorAction Stop
    if($credentialItem.PSIsContainer-or$credentialItem.Length-le0){throw 'credential metadata is not a nonempty file'}
    $credentialMetadata='PASS_EXISTENCE_AND_NONEMPTY_METADATA_ONLY'
}catch{$credentialMetadata='FAIL';$failures.Add("CREDENTIAL_METADATA=$($_.Exception.Message)")}

$hardwareScripts=@(
    'R1hCampaignCommon.ps1','Invoke-R1hProgramOnce.ps1','Invoke-R1hIndependentDoneReadOnly.ps1',
    'Wait-R1hProgramMinimum.ps1','Invoke-R1hHostStep.ps1','Invoke-R1hTelemetryReadOnly.ps1',
    'New-R1hConfiguredImageReceipt.ps1','Invoke-R1hR4JtagSafetyReadOnly.ps1',
    'Invoke-R1hR4MinimalHostSafetyReadOnly.ps1','New-R1hR4HardwareBinding.ps1',
    'Invoke-R1hR4EligibleProgramRetryOnce.ps1','Test-R1hR4HardwarePrepOffline.ps1')
$identity=[Collections.Generic.List[object]]::new()
foreach($name in $hardwareScripts){
    $path=Join-Path (Join-Path $taskRoot 'scripts') $name
    try{
        $tokens=$null;$errors=$null
        [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
        if($errors.Count-ne0){throw (($errors|ForEach-Object Message)-join'; ')}
        $item=Get-Item -LiteralPath $path
        $identity.Add([pscustomobject]@{name=$name;path=$path;bytes=$item.Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;parse='PASS'})
    }catch{$failures.Add("POWERSHELL_PARSE=$name`:$($_.Exception.Message)")}
}
$identity|Export-Csv -LiteralPath $scriptCsv -NoTypeInformation -Encoding utf8NoBOM

$programText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\Invoke-R1hProgramOnce.ps1'))
$retryText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\Invoke-R1hR4EligibleProgramRetryOnce.ps1'))
$telemetryText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\Invoke-R1hTelemetryReadOnly.ps1'))
$commonText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\R1hCampaignCommon.ps1'))
$hostStepText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\Invoke-R1hHostStep.ps1'))
$hostSafetyText=[IO.File]::ReadAllText((Join-Path $taskRoot 'scripts\r1h_r4_minimal_host_safety_readonly.sh'))
$remoteBase='v41_nvp_r1h_r4_61ec5f55'
$staticChecks=[ordered]@{
    PRIMARY_PROGRAM_WRAPPER_ONE_OBSERVER_LAUNCH=([regex]::Matches($programText,'(?m)^\s*\$command\s*=\s*@\(').Count-eq1)
    GLOBAL_RETRY_RESERVATION_UNIQUE=([regex]::Matches($retryText,'GLOBAL_PROGRAM_RETRY_RESERVATION\.txt').Count-ge1)
    GLOBAL_RETRY_REESTABLISHES_TARGET=($retryText.Contains('JtagReconfirmationTcl',[StringComparison]::Ordinal))
    TELEMETRY_R1H_READER_READ_ONLY=($telemetryText.Contains('R1H_FULL_TELEMETRY',[StringComparison]::Ordinal))
    TELEMETRY_IN_MEMORY_DEPENDENCY_ADAPTER=($telemetryText.Contains('TASK_LOCAL_IN_MEMORY_EXACT_R1E_PLUS_R1F_MODULE_ADAPTER',[StringComparison]::Ordinal))
    TELEMETRY_FORMAL_HAS_NO_OUTPUT_DIR=($telemetryText.Contains('NOT_APPLICABLE_FORMAL_STDOUT_ONLY',[StringComparison]::Ordinal))
    REMOTE_NAMESPACE_COMMON=($commonText.Contains($remoteBase,[StringComparison]::Ordinal))
    REMOTE_NAMESPACE_LOADER=($hostStepText.Contains($remoteBase,[StringComparison]::Ordinal))
    REMOTE_NAMESPACE_TELEMETRY=($telemetryText.Contains($remoteBase,[StringComparison]::Ordinal))
    HOST_SAFETY_READ_ONLY_DECLARED=($hostSafetyText.Contains('HOST_SAFETY_DISCOVERY_READ_ONLY=YES',[StringComparison]::Ordinal))
    HOST_SAFETY_NO_REBOOT=(-not[regex]::IsMatch($hostSafetyText,'(?m)^\s*(?:reboot|shutdown|poweroff)\b'))
    HOST_SAFETY_NO_MMIO=(-not$hostSafetyText.Contains('/dev/xdma0_user',[StringComparison]::Ordinal))
}
foreach($entry in $staticChecks.GetEnumerator()){if(-not$entry.Value){$failures.Add("STATIC_CHECK=$($entry.Key)")}}

$gate=if($failures.Count-eq0){'PASS'}else{'FAIL'}
$lines=[Collections.Generic.List[string]]::new()
foreach($line in @(
    "R1H_R4_HARDWARE_PREP_OFFLINE_GATE=$gate","INHERITED_TOOL_HASHES=$(if($failures|Where-Object{$_-like'TOOL_IDENTITY=*'}){'FAIL'}else{'PASS_ALL'})",
    "POWERSHELL_PARSE=$(if($failures|Where-Object{$_-like'POWERSHELL_PARSE=*'}){'FAIL'}else{'PASS_ALL'})",
    "CREDENTIAL_PROCEDURE=$credentialMetadata",'CREDENTIAL_CONTENT_READ=NO','SSH_SESSIONS=0','JTAG_SESSIONS=0',
    'FPGA_PROGRAMS=0','WARM_REBOOTS=0','DRIVER_LOADS=0','MMIO_READS=0','MMIO_WRITES=0',
    'DMA_TRANSFERS=0','PHYSICAL_ACTIONS=0','GLOBAL_PROGRAM_RETRY_BUDGET=1',
    "TOOL_IDENTITY_CSV_SHA256=$((Get-FileHash -LiteralPath $toolCsv -Algorithm SHA256).Hash)",
    "TASK_LOCAL_SCRIPT_IDENTITY_CSV_SHA256=$((Get-FileHash -LiteralPath $scriptCsv -Algorithm SHA256).Hash)")){$lines.Add($line)}
foreach($entry in $staticChecks.GetEnumerator()){$lines.Add("STATIC_$($entry.Key)=$(if($entry.Value){'PASS'}else{'FAIL'})")}
foreach($failure in $failures){$lines.Add("FAILURE=$failure")}
[IO.File]::WriteAllLines($output,$lines,[Text.UTF8Encoding]::new($false))
$lines
if($gate-cne'PASS'){exit 1}
