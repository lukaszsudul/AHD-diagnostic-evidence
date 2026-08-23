[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('ArmA','ArmB')][string]$Role,
    [Parameter(Mandatory = $true)][string]$EvidencePath,
    [string]$PlinkPath='C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$taskRoot='C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6';$helperPath=Join-Path $taskRoot 'scripts\Invoke-ContextualPlink.ps1';$readerPath=Join-Path $taskRoot 'scripts\read_nvp_r1e.py'
$expectedPlinkSha='E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915';$expectedHelperSha='5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9';$expectedReaderSha='0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037';$hostKey='SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
function ConvertTo-GzipBase64{param([byte[]]$Bytes)$output=[IO.MemoryStream]::new();try{$gzip=[IO.Compression.GzipStream]::new($output,[IO.Compression.CompressionLevel]::Optimal,$true);try{$gzip.Write($Bytes,0,$Bytes.Length)}finally{$gzip.Dispose()};return [Convert]::ToBase64String($output.ToArray())}finally{$output.Dispose()}}
function Assert-ExactFileHash{param([string]$Path,[string]$Expected)if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "required file missing: $Path"};$actual=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash;if($actual-cne$Expected){throw "SHA-256 mismatch for $Path`: $actual"}}
Assert-ExactFileHash $PlinkPath $expectedPlinkSha;Assert-ExactFileHash $helperPath $expectedHelperSha;Assert-ExactFileHash $readerPath $expectedReaderSha
$roleDirectory=if($Role-eq'ArmA'){Join-Path $taskRoot '08_ARM_A_R1E'}else{Join-Path $taskRoot '09_ARM_B_FORMAL'};$fullEvidence=[IO.Path]::GetFullPath($EvidencePath);$roleFull=[IO.Path]::GetFullPath($roleDirectory)
if(-not$fullEvidence.StartsWith($roleFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'telemetry evidence must stay inside the selected R6 phase directory'};if(Test-Path -LiteralPath $fullEvidence){throw 'refusing to overwrite telemetry evidence'};if(-not(Test-Path -LiteralPath (Split-Path -Parent $fullEvidence)-PathType Container)){throw 'telemetry evidence parent directory does not exist'}
$expect=if($Role-eq'ArmA'){'r1e'}else{'formal'};$readerPayload=ConvertTo-GzipBase64([IO.File]::ReadAllBytes($readerPath));$remoteTemplate='sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/python3 - --node /dev/xdma0_user --expect "$2" --twice --delay 1.0'' _ ''{0}'' ''{1}''';$remoteCommand=$remoteTemplate-f$readerPayload,$expect
&$helperPath -PlinkPath $PlinkPath -HostKey $hostKey -RemoteCommand $remoteCommand -EvidencePath $fullEvidence -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind("R6_FULL_TELEMETRY_{0}"-f$Role.ToUpperInvariant()) -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds 120
exit $LASTEXITCODE
