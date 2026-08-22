[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('HOST_PRECHECK','BAR_GEOMETRY','ZERO_ACTIVITY','TELEMETRY')][string]$Role,
    [Parameter(Mandatory)][string]$HelperPath,
    [Parameter(Mandatory)][string]$PlinkPath,
    [Parameter(Mandatory)][string]$HostKey,
    [Parameter(Mandatory)][string]$ExpectedIp,
    [Parameter(Mandatory)][string]$ExpectedUser,
    [Parameter(Mandatory)][string]$EvidencePath,
    [ValidateRange(30,600)][int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$expectedHelperSha = '8DB31E3C7FFF642EC4B2643A9C44317B5BC711558F0692C97335248BF154378D'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$moduleSha = '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A'
$loaderSha = '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F'
$readerSha = '808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E'

$helper = (Resolve-Path -LiteralPath $HelperPath).Path
$plink = (Resolve-Path -LiteralPath $PlinkPath).Path
if ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -cne $expectedHelperSha) {
    throw 'contextual Plink helper identity mismatch'
}
if ((Get-FileHash -LiteralPath $plink -Algorithm SHA256).Hash -cne $expectedPlinkSha) {
    throw 'Plink identity mismatch'
}
if ($HostKey -cne $expectedHostKey) { throw 'host-key fingerprint mismatch' }
if (Test-Path -LiteralPath $EvidencePath) { throw 'evidence path must be fresh' }

if ($Role -eq 'HOST_PRECHECK') {
    $payloadPath = Join-Path $PSScriptRoot 'i25_host_precheck_readonly.sh'
    $expectedPayloadSha = 'A410FA38B21EE53240DB1C222E081371414D9F96AB6A75A0712FABF17EA077E2'
    $arguments = '"$U/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko" ' +
        $moduleSha + ' "$U/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh" ' + $loaderSha
} elseif ($Role -eq 'BAR_GEOMETRY') {
    $payloadPath = Join-Path $PSScriptRoot 'r1b_bar_geometry_readonly.sh'
    $expectedPayloadSha = '02D2E9AA256F80BA9335559EFAFF24B5E80D2F779D479428314BA4AE2FA07540'
    $arguments = ''
} elseif ($Role -eq 'ZERO_ACTIVITY') {
    $payloadPath = Join-Path $PSScriptRoot 'r1b_zero_activity_readonly.sh'
    $expectedPayloadSha = '58D50BA0A8A5D056F284B307C663E20F1C70EE34BD9407181ECAE23A8A44BD00'
    $arguments = ''
} else {
    $payloadPath = Join-Path $PSScriptRoot 'i25_collect_nvp_readonly.sh'
    $expectedPayloadSha = 'E84AAF79068C22F3FE54187E11C4AFE12AB4A5A0C35716A5284F30EA87FC4B63'
    $arguments = '"$U/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read" ' + $readerSha
}

$payload = (Resolve-Path -LiteralPath $payloadPath).Path
if ((Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash -cne $expectedPayloadSha) {
    throw 'read-only payload identity mismatch'
}
$encoded = [Convert]::ToBase64String([IO.File]::ReadAllBytes($payload))
$inner = 'printf %s ' + $encoded + ' | /usr/bin/base64 -d | /usr/bin/bash -s -- ' + $arguments
$remoteCommand = 'sudo -S -p ' + "''" + ' /usr/bin/env U="$HOME" /usr/bin/bash -c ' + "'" + $inner + "'"

& $helper -PlinkPath $plink -HostKey $HostKey -RemoteCommand $remoteCommand `
    -EvidencePath $EvidencePath -ExpectedIp $ExpectedIp -ExpectedUser $ExpectedUser `
    -EvidenceKind $Role -SendPasswordToStdin -SudoPasswordCopies 1 -TimeoutSeconds $TimeoutSeconds
exit $LASTEXITCODE
