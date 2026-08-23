[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$wrapperPath = Join-Path $taskRoot 'scripts\Invoke-R5PostColdResetHostStability.ps1'
$payloadPath = Join-Path $taskRoot 'scripts\r5_post_cold_reset_host_sample_readonly.sh'
$helperPath = Join-Path $taskRoot 'scripts\Invoke-ContextualPlink.ps1'
$resultPath = Join-Path $taskRoot '02_HOST_TOOL_PREFLIGHT\POST_COLD_RESET_HOST_STABILITY_STATIC_AUDIT.md'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'

function Add-Check {
    param(
        [Collections.Generic.List[object]]$Checks,
        [string]$Name,
        [bool]$Pass,
        [string]$Evidence
    )
    $Checks.Add([pscustomobject]@{ Name = $Name; Pass = $Pass; Evidence = $Evidence })
}

function Get-PowerShellParseErrorCount([string]$Path) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    return @($errors).Count
}

foreach ($path in @($wrapperPath, $payloadPath, $helperPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "required static-audit input missing: $path"
    }
}

$wrapper = [IO.File]::ReadAllText($wrapperPath)
$payload = [IO.File]::ReadAllText($payloadPath)
$checks = [Collections.Generic.List[object]]::new()

$parseErrors = Get-PowerShellParseErrorCount $wrapperPath
Add-Check $checks 'POWERSHELL_AST' ($parseErrors -eq 0) "parse_errors=$parseErrors"
Add-Check $checks 'TASK_ROOT_EXACT' ($wrapper.Contains($taskRoot)) $taskRoot
Add-Check $checks 'FROZEN_HELPER_HASH_LITERAL' (
    $wrapper.Contains($expectedHelperSha) -and
    (Get-FileHash -LiteralPath $helperPath -Algorithm SHA256).Hash -ceq $expectedHelperSha
) $expectedHelperSha
Add-Check $checks 'FROZEN_PLINK_HASH_LITERAL' ($wrapper.Contains($expectedPlinkSha)) $expectedPlinkSha
Add-Check $checks 'THREE_SESSION_LOOP' (
    [regex]::Matches($wrapper, '(?m)^for \(\$session = 1; \$session -le 3; \$session\+\+\) \{$').Count -eq 1
) 'one loop, bounds 1..3'
Add-Check $checks 'ONE_HELPER_SITE_INSIDE_LOOP' (
    [regex]::Matches($wrapper, '(?m)^\s*& \$helperPath\s*`\s*$').Count -eq 1
) 'one helper invocation site executed by the 1..3 loop'
Add-Check $checks 'THREE_DISTINCT_EVIDENCE_PATHS' (
    $wrapper.Contains('HOST_STABILITY_SESSION_{0}.log') -and
    $wrapper.Contains('$sessionPaths[$session - 1]')
) 'session index is embedded in each evidence filename'
Add-Check $checks 'FIVE_SECOND_SCHEDULING' (
    $wrapper.Contains('2.625 * $frequency') -and
    $wrapper.Contains('5.250 * $frequency') -and
    $wrapper.Contains('$firstCompletionTick +')
) 'sessions 2/3 scheduled from session-1 completion at 2.625/5.250 seconds'
Add-Check $checks 'REMOTE_SPAN_GATE' (
    $wrapper.Contains('$remoteSpan -lt $MinimumSpanSeconds') -and
    $wrapper.Contains('$third.Uptime - $first.Uptime')
) 'third minus first remote uptime must be >=5 seconds'
Add-Check $checks 'LOCAL_SPAN_GATE' (
    $wrapper.Contains('$localSpan -lt $MinimumSpanSeconds') -and
    $wrapper.Contains('$third.LocalEndTick - $first.LocalStartTick')
) 'local monotonic span must be >=5 seconds'
Add-Check $checks 'BOOT_ID_STABILITY_GATE' (
    $wrapper.Contains('$first.BootId -cne $second.BootId') -and
    $wrapper.Contains('$first.BootId -cne $third.BootId')
) 'all three UUID boot IDs compared ordinally'
Add-Check $checks 'UPTIME_STRICTLY_MONOTONIC' (
    $wrapper.Contains('$second.Uptime -gt $first.Uptime') -and
    $wrapper.Contains('$third.Uptime -gt $second.Uptime')
) 'uptime2 > uptime1 and uptime3 > uptime2'
Add-Check $checks 'KERNEL_EXACT_29_ALL_SESSIONS' (
    $wrapper.Contains("`$expectedKernel = '7.0.0-29-generic'") -and
    $wrapper.Contains('$first.Kernel -cne $expectedKernel') -and
    $wrapper.Contains('$second.Kernel -cne $expectedKernel') -and
    $wrapper.Contains('$third.Kernel -cne $expectedKernel')
) 'kernel 7.0.0-29-generic checked in every record'
Add-Check $checks 'HOST_USER_STABILITY' (
    $wrapper.Contains("`$expectedUser = 'vcdeagent1'") -and
    $wrapper.Contains('$first.Hostname -cne $second.Hostname') -and
    $wrapper.Contains('$first.Hostname -cne $third.Hostname')
) 'hostname stable and exact remote user required'
Add-Check $checks 'PASS_CLASSIFICATION' (
    $wrapper.Contains("'PASS_3_OF_3'") -and
    $wrapper.Contains('POST_COLD_RESET_BOOT_ID_BASELINE=') -and
    $wrapper.Contains('POST_COLD_RESET_HOST_STABILITY_GATE=')
) 'required baseline and PASS_3_OF_3 output fields'
Add-Check $checks 'FRESH_EVIDENCE_ONLY' (
    $wrapper.Contains('refusing to overwrite host-stability evidence')
) 'wrapper refuses every pre-existing session/matrix/gate output'
Add-Check $checks 'NONPRIVILEGED_REMOTE_COMMAND' (
    -not [regex]::IsMatch($wrapper, '(?im)\bsudo\b|-SendPasswordToStdin')
) 'no sudo or sudo-password stdin in host-stability wrapper'
Add-Check $checks 'PAYLOAD_STRICT_READ_ONLY' (
    $payload.Contains('set -euo pipefail') -and
    $payload.Contains('HOST_STABILITY_SAMPLE_READ_ONLY=YES') -and
    -not [regex]::IsMatch(
        $payload,
        '(?im)\b(sudo|reboot|shutdown|poweroff|halt|modprobe|rmmod|insmod|setpci|dd|mount|umount)\b|/sys/bus/pci/.*/(remove|rescan)|os\.pwrite|O_RDWR|program_hw_devices|write_bitstream'
    )
) 'payload uses only read-only/nonprivileged host observations'
Add-Check $checks 'SAMPLE_INDEX_EXACT' (
    $payload.Contains('1|2|3) ;;') -and
    $payload.Contains('HOST_STABILITY_SAMPLE_INDEX=%s')
) 'payload accepts exactly sample indices 1,2,3'

$failures = @($checks | Where-Object { -not $_.Pass })
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# R5 post-cold-reset host-stability tooling static audit')
$lines.Add('')
$lines.Add('This audit is static only. It did not start Plink, SSH, Vivado, JTAG, MMIO, a reboot, or a driver operation.')
$lines.Add('')
$lines.Add("WRAPPER_SHA256=$((Get-FileHash -LiteralPath $wrapperPath -Algorithm SHA256).Hash)")
$lines.Add("PAYLOAD_SHA256=$((Get-FileHash -LiteralPath $payloadPath -Algorithm SHA256).Hash)")
$lines.Add("FROZEN_HELPER_SHA256=$((Get-FileHash -LiteralPath $helperPath -Algorithm SHA256).Hash)")
$lines.Add('')
$lines.Add('| Check | Result | Evidence |')
$lines.Add('|---|---|---|')
foreach ($check in $checks) {
    $safeEvidence = $check.Evidence.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
    $lines.Add("| $($check.Name) | $(if ($check.Pass) {'PASS'} else {'FAIL'}) | $safeEvidence |")
}
$lines.Add('')
$lines.Add("STATIC_CHECK_COUNT=$($checks.Count)")
$lines.Add("STATIC_FAILURE_COUNT=$($failures.Count)")
$lines.Add('LIVE_SSH_SESSIONS_EXECUTED_BY_AUDIT=0')
$lines.Add('HARDWARE_OR_NETWORK_ACTIONS_EXECUTED_BY_AUDIT=0')
$lines.Add('POST_COLD_RESET_HOST_STABILITY_TOOLING_STATIC_GATE=' + $(if ($failures.Count -eq 0) {'PASS'} else {'FAIL'}))

[IO.File]::WriteAllLines($resultPath, $lines, [Text.UTF8Encoding]::new($false))
$lines | Select-Object -Last 6
if ($failures.Count -ne 0) { exit 1 }
exit 0
