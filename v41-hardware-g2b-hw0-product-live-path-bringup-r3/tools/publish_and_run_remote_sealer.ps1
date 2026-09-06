[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$source = Join-Path $taskRoot 'tools\seal_remote_r3_artifacts.sh'
$helper = Join-Path $taskRoot 'tools\Invoke-G2BR3Plink_proven.ps1'
$plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$uploadEvidence = Join-Path $taskRoot 'raw\REMOTE_SEALER_TOOL_DUT_PUBLICATION.log'
$runEvidence = Join-Path $taskRoot 'raw\DUT_ARTIFACT_SEALING.log'
foreach ($path in @($uploadEvidence,$runEvidence)) { if (Test-Path -LiteralPath $path) { throw "OUTPUT_EXISTS=$path" } }
$bytes = [IO.File]::ReadAllBytes($source)
$base64 = [Convert]::ToBase64String($bytes)
$sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant()
$remotePath = '$HOME/vcde_artifacts/g2b_hw0_product_r3/20260906T140148Z/tools/seal_remote_r3_artifacts.sh'
$upload = 'set -e; umask 077; dst="' + $remotePath + '"; test ! -e "$dst"; printf ''%s'' ''' + $base64 + ''' | base64 -d > "$dst"; chmod 0444 "$dst"; test "$(sha256sum "$dst" | awk ''{print $1}'')" = ''' + $sha + '''; bash -n "$dst"; echo TOOL_UPLOAD=PASS; echo BASH_SYNTAX=PASS; echo TOOL_SHA256=' + $sha
& $helper -PlinkPath $plink -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' -RemoteCommand $upload -EvidencePath $uploadEvidence -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind 'R3_REMOTE_SEALER_TOOL_DUT_PUBLICATION' -TimeoutSeconds 60
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$run = 'bash "' + $remotePath + '"'
& $helper -PlinkPath $plink -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' -RemoteCommand $run -EvidencePath $runEvidence -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind 'R3_DUT_ARTIFACT_SEALING' -TimeoutSeconds 60
exit $LASTEXITCODE
