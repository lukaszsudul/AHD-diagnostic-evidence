[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$r5 = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts'
$r4 = 'C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4\scripts'
$failures = [Collections.Generic.List[string]]::new()

function Record-Failure([string]$Message) {
    $script:failures.Add($Message)
}

function Require-Equal([string]$Name, $Actual, $Expected) {
    if ($Actual -cne $Expected) {
        Record-Failure "$Name expected [$Expected], observed [$Actual]"
    }
}

$frozen = [ordered]@{
    'Invoke-ContextualPlink.ps1' = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
    'parse_pci_bars.py' = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
    'read_nvp_r1e.py' = '0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037'
    'read_jtag_identity_done_strong.tcl' = 'CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD'
    'verify_runtime_identity.py' = '84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C'
    'analyze_r4_telemetry.py' = 'A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967'
    'program_once_startup_high_done.tcl' = '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653'
    'ProgramObserverCommon.ps1' = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
}
foreach ($entry in $frozen.GetEnumerator()) {
    $path = Join-Path $r5 $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Record-Failure "missing frozen file $($entry.Key)"
        continue
    }
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    Require-Equal "FROZEN_SHA_$($entry.Key)" $sha $entry.Value
    Write-Output "FROZEN_SHA256_$($entry.Key)=$sha"
}

$wrappers = @(
    'Invoke-R5WarmRebootOnce.ps1',
    'Invoke-R5ExactPinnedLoaderOnce.ps1',
    'Invoke-R5RemoteValidator.ps1',
    'Invoke-R5IndependentDoneReadOnly.ps1',
    'Invoke-R5TelemetryReadOnly.ps1',
    'Wait-R5HostCycle.ps1'
)
foreach ($name in $wrappers) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $r5 $name), [ref]$tokens, [ref]$errors
    )
    Write-Output "POWERSHELL_PARSE_ERRORS_$name=$($errors.Count)"
    if ($errors.Count -ne 0) { Record-Failure "$name PowerShell parse errors=$($errors.Count)" }
}

function Test-NormalizedEquality {
    param(
        [string]$R5Name,
        [string]$R4Name,
        [array]$Replacements
    )
    $candidate = [IO.File]::ReadAllText((Join-Path $r5 $R5Name))
    foreach ($replacement in $Replacements) {
        $candidate = $candidate.Replace($replacement[0], $replacement[1])
    }
    $reference = [IO.File]::ReadAllText((Join-Path $r4 $R4Name))
    $equal = $candidate -ceq $reference
    Write-Output "NORMALIZED_R4_EQUALITY_$R5Name=$(if ($equal) {'PASS'} else {'FAIL'})"
    if (-not $equal) { Record-Failure "$R5Name contains a non-R5-path semantic delta from R4" }
}

$wrapperReplacements = @(
    @('C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5', 'C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4'),
    @('R5 task root', 'R4 task root'),
    @('R5_', 'R4_'),
    @('v41_nvp_r1e_r5', 'v41_nvp_r1e_r4'),
    @('r5_post_', 'r4_post_')
)
Test-NormalizedEquality 'Invoke-R5WarmRebootOnce.ps1' 'Invoke-R4WarmRebootOnce.ps1' $wrapperReplacements
Test-NormalizedEquality 'Invoke-R5ExactPinnedLoaderOnce.ps1' 'Invoke-R4ExactPinnedLoaderOnce.ps1' $wrapperReplacements
Test-NormalizedEquality 'Invoke-R5RemoteValidator.ps1' 'Invoke-R4RemoteValidator.ps1' $wrapperReplacements
Test-NormalizedEquality 'r5_post_reboot_preloader_readonly.sh' 'r4_post_reboot_preloader_readonly.sh' @(
    @('# R5', '# R4'), @('v41_nvp_r1e_r5', 'v41_nvp_r1e_r4')
)
Test-NormalizedEquality 'r5_post_loader_readonly.sh' 'r4_post_loader_readonly.sh' @(
    @('# R5', '# R4'), @('v41_nvp_r1e_r5', 'v41_nvp_r1e_r4')
)

$preloader = [IO.File]::ReadAllText((Join-Path $r5 'r5_post_reboot_preloader_readonly.sh'))
$postloader = [IO.File]::ReadAllText((Join-Path $r5 'r5_post_loader_readonly.sh'))
$validatorPayload = $preloader + "`n" + $postloader
$forbiddenValidatorPatterns = @(
    '(?im)^\s*(modprobe|insmod|rmmod|reboot|shutdown|poweroff|setpci)\b',
    '\bos\.pwrite\b',
    '\bO_RDWR\b',
    '(?m)^\s*program_hw_devices\b',
    '(?m)^\s*write_bitstream\b'
)
$forbiddenMatches = 0
foreach ($pattern in $forbiddenValidatorPatterns) {
    $forbiddenMatches += [regex]::Matches($validatorPayload, $pattern).Count
}
Write-Output "READ_ONLY_VALIDATOR_FORBIDDEN_MUTATION_MATCHES=$forbiddenMatches"
if ($forbiddenMatches -ne 0) { Record-Failure "validator mutation patterns=$forbiddenMatches" }

$loader = [IO.File]::ReadAllText((Join-Path $r5 'Invoke-R5ExactPinnedLoaderOnce.ps1'))
$reboot = [IO.File]::ReadAllText((Join-Path $r5 'Invoke-R5WarmRebootOnce.ps1'))
$telemetry = [IO.File]::ReadAllText((Join-Path $r5 'Invoke-R5TelemetryReadOnly.ps1'))
$doneTcl = [IO.File]::ReadAllText((Join-Path $r5 'read_jtag_identity_done_strong.tcl'))
$reader = [IO.File]::ReadAllText((Join-Path $r5 'read_nvp_r1e.py'))

$loaderExecCount = [regex]::Matches($loader, "exec sudo -S -k -p '' /usr/bin/bash").Count
$rebootCommandCount = [regex]::Matches($reboot, '\$remoteCommand\s*=\s*"sudo -S -k -p '''' /usr/sbin/reboot"').Count
$telemetryHelperCount = [regex]::Matches($telemetry, '(?m)^& \$helperPath\s*`').Count
$doneProgramCount = [regex]::Matches($doneTcl, '(?m)^\s*program_hw_devices\b').Count
$doneProgramFileCount = [regex]::Matches($doneTcl, '(?m)^\s*set_property\s+PROGRAM\.FILE\b').Count
Write-Output "EXACT_LOADER_REMOTE_EXEC_COUNT=$loaderExecCount"
Write-Output "WARM_REBOOT_REMOTE_COMMAND_COUNT=$rebootCommandCount"
Write-Output "TELEMETRY_CONTEXTUAL_HELPER_COUNT=$telemetryHelperCount"
Write-Output "INDEPENDENT_DONE_PROGRAM_COMMAND_COUNT=$doneProgramCount"
Write-Output "INDEPENDENT_DONE_PROGRAM_FILE_ASSIGNMENT_COUNT=$doneProgramFileCount"
Require-Equal 'EXACT_LOADER_REMOTE_EXEC_COUNT' $loaderExecCount 1
Require-Equal 'WARM_REBOOT_REMOTE_COMMAND_COUNT' $rebootCommandCount 1
Require-Equal 'TELEMETRY_CONTEXTUAL_HELPER_COUNT' $telemetryHelperCount 1
Require-Equal 'INDEPENDENT_DONE_PROGRAM_COMMAND_COUNT' $doneProgramCount 0
Require-Equal 'INDEPENDENT_DONE_PROGRAM_FILE_ASSIGNMENT_COUNT' $doneProgramFileCount 0

Require-Equal 'TELEMETRY_TWICE_COUNT' ([regex]::Matches($telemetry, '--twice').Count) 1
Require-Equal 'TELEMETRY_DELAY_COUNT' ([regex]::Matches($telemetry, '--delay 1\.0').Count) 1
Require-Equal 'READER_PWRITE_COUNT' ([regex]::Matches($reader, '\bpwrite\b').Count) 0
Require-Equal 'READER_O_RDWR_COUNT' ([regex]::Matches($reader, '\bO_RDWR\b').Count) 0
if (-not $reader.Contains('os.O_RDONLY')) { Record-Failure 'frozen R1e reader lacks O_RDONLY' }

$r4Residual = 0
foreach ($name in @(
    'Invoke-R5WarmRebootOnce.ps1',
    'Invoke-R5ExactPinnedLoaderOnce.ps1',
    'Invoke-R5RemoteValidator.ps1',
    'r5_post_reboot_preloader_readonly.sh',
    'r5_post_loader_readonly.sh'
)) {
    $text = [IO.File]::ReadAllText((Join-Path $r5 $name))
    $r4Residual += [regex]::Matches($text, 'r1e_r4|R4_|Invoke-R4|r4_post').Count
}
Write-Output "R4_PATH_OR_ROLE_RESIDUAL_COUNT=$r4Residual"
if ($r4Residual -ne 0) { Record-Failure "R4 residual count=$r4Residual" }

Write-Output 'NETWORK_OR_HARDWARE_EXECUTION_DURING_STATIC_TEST=0'
if ($failures.Count -ne 0) {
    foreach ($failure in $failures) { Write-Output "FAILURE=$failure" }
    Write-Output 'R5_POST_PROGRAM_TOOLING_STATIC_GATE=FAIL'
    exit 1
}
Write-Output 'R5_POST_PROGRAM_TOOLING_STATIC_GATE=PASS'
exit 0
