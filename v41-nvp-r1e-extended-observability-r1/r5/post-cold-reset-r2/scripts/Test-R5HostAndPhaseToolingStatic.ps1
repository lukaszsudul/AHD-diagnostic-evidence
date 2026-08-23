[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$scriptRoot = Join-Path $taskRoot 'scripts'
$r4ScriptRoot = 'C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4\scripts'
$resultPath = Join-Path $taskRoot '02_HOST_TOOL_PREFLIGHT\R5_HOST_AND_PHASE_TOOLING_STATIC_AUDIT.md'

function Add-Check {
    param([string]$Name, [bool]$Pass, [string]$Evidence)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Pass = $Pass; Evidence = $Evidence })
}

function Read-Exact([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing audit input: $Path" }
    return [IO.File]::ReadAllText($Path)
}

function Get-ParseErrors([string]$Path) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    return @($errors).Count
}

function Normalize-R4ToR5([string]$Text) {
    return $Text.Replace(
        'V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4',
        'V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
    ).Replace(
        'v41_nvp_r1e_r4', 'v41_nvp_r1e_r5'
    ).Replace('R4', 'R5').Replace('r4', 'r5')
}

$checks = [Collections.Generic.List[object]]::new()

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
    $path = Join-Path $scriptRoot $entry.Key
    $actual = if (Test-Path -LiteralPath $path -PathType Leaf) {
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    } else { 'MISSING' }
    Add-Check "FROZEN_$($entry.Key)" ($actual -ceq $entry.Value) "expected=$($entry.Value);actual=$actual"
}

$powerShellFiles = @(
    'Invoke-R5PostColdResetHostStability.ps1',
    'Invoke-R5PreBootstrapSafetyDiscovery.ps1',
    'Invoke-R5RemoteValidator.ps1',
    'Invoke-R5ExactPinnedLoaderOnce.ps1',
    'Invoke-R5WarmRebootOnce.ps1',
    'Invoke-R5IndependentDoneReadOnly.ps1',
    'Invoke-R5TelemetryReadOnly.ps1',
    'Wait-R5HostCycle.ps1'
)
foreach ($name in $powerShellFiles) {
    $path = Join-Path $scriptRoot $name
    $errorCount = if (Test-Path -LiteralPath $path -PathType Leaf) { Get-ParseErrors $path } else { 1 }
    Add-Check "AST_$name" ($errorCount -eq 0) "parse_errors=$errorCount"
}

$python = Get-Command python.exe -ErrorAction SilentlyContinue
$pythonUsable = $false
if ($null -ne $python) {
    & $python.Source --version *> $null
    $pythonUsable = ($LASTEXITCODE -eq 0)
}
if ($pythonUsable) {
    $pythonInputs = @('parse_pci_bars.py','read_nvp_r1e.py','verify_runtime_identity.py','analyze_r4_telemetry.py')
    $pythonFailures = [Collections.Generic.List[string]]::new()
    foreach ($name in $pythonInputs) {
        $path = Join-Path $scriptRoot $name
        $parse = & $python.Source -c "import ast,pathlib,sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8-sig'), filename=sys.argv[1])" $path 2>&1
        if ($LASTEXITCODE -ne 0) { $pythonFailures.Add("$name`: $parse") }
    }
    Add-Check 'PYTHON_AST_FROZEN_TOOLS' ($pythonFailures.Count -eq 0) "failures=$($pythonFailures.Count)"
} else {
    Add-Check 'PYTHON_AST_FROZEN_TOOLS' $true 'PASS_NOT_RERUN: local Python runtime unavailable; byte-exact frozen passed tools gated above'
}

$adaptedPairs = @(
    @('r4_post_reboot_preloader_readonly.sh','r5_post_reboot_preloader_readonly.sh'),
    @('r4_post_loader_readonly.sh','r5_post_loader_readonly.sh'),
    @('Invoke-R4RemoteValidator.ps1','Invoke-R5RemoteValidator.ps1'),
    @('Invoke-R4ExactPinnedLoaderOnce.ps1','Invoke-R5ExactPinnedLoaderOnce.ps1'),
    @('Invoke-R4WarmRebootOnce.ps1','Invoke-R5WarmRebootOnce.ps1')
)
foreach ($pair in $adaptedPairs) {
    $r4Text = Read-Exact (Join-Path $r4ScriptRoot $pair[0])
    $r5Text = Read-Exact (Join-Path $scriptRoot $pair[1])
    Add-Check "NORMALIZED_R4_EQUAL_$($pair[1])" ((Normalize-R4ToR5 $r4Text) -ceq $r5Text) 'only R4/R5 task-label/root substitutions permitted'
}

$prebootstrapWrapper = Read-Exact (Join-Path $scriptRoot 'Invoke-R5PreBootstrapSafetyDiscovery.ps1')
$prebootstrapPayload = Read-Exact (Join-Path $scriptRoot 'r5_prebootstrap_safety_readonly.sh')
Add-Check 'PREBOOTSTRAP_EXACT_FROZEN_DEPENDENCIES' (
    $prebootstrapWrapper.Contains('5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9') -and
    $prebootstrapWrapper.Contains('5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922') -and
    $prebootstrapWrapper.Contains('E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915')
) 'Plink/helper/BAR-parser exact hashes embedded'
Add-Check 'PREBOOTSTRAP_ZERO_OR_ONE_ENDPOINT' (
    $prebootstrapPayload.Contains('[[ ${#expected_endpoints[@]} -le 1 ]]') -and
    $prebootstrapPayload.Contains('PRE_BOOTSTRAP_ENDPOINT_STATE=%s') -and
    $prebootstrapPayload.Contains('ABSENT_ACCEPTED')
) '0 or 1 expected endpoint; absence explicitly accepted'
Add-Check 'PREBOOTSTRAP_FOREIGN_ENDPOINT_REJECTED' (
    $prebootstrapPayload.Contains('[[ ${#xilinx_functions[@]} -eq ${#expected_endpoints[@]} ]]') -and
    $prebootstrapPayload.Contains('FOREIGN_XILINX_ENDPOINT')
) 'any non-10ee:7011 Xilinx function is rejected'
Add-Check 'PREBOOTSTRAP_DRIVER_AND_NODE_ABSENCE_ACCEPTED' (
    $prebootstrapPayload.Contains('PRE_BOOTSTRAP_DRIVER_STATE=%s') -and
    $prebootstrapPayload.Contains('XDMA_NODE_COUNT=%s') -and
    $prebootstrapPayload.Contains('ABSENT_ACCEPTED')
) 'exact pinned state or absence accepted; wrong same-name rejected'
Add-Check 'PREBOOTSTRAP_COLD_RESET_BASELINE_GATE' (
    $prebootstrapPayload.Contains('BOOT_ID_CHANGED_AFTER_STABILITY_GATE') -and
    $prebootstrapPayload.Contains('PASS_BASELINE_UNCHANGED')
) 'new R5 baseline must remain unchanged; no historical R4 continuity gate'
Add-Check 'PREBOOTSTRAP_IDENTITY_INFORMATIONAL_ONLY' (
    $prebootstrapPayload.Contains('UNPROVEN_INFORMATIONAL_READ_ONLY') -and
    $prebootstrapPayload.Contains('O_RDONLY | os.O_CLOEXEC') -and
    $prebootstrapPayload.Contains('os.pread')
) 'optional current-image identity uses O_RDONLY/pread and is not an entry gate'
$prebootstrapForbidden = [regex]::Matches(
    $prebootstrapPayload,
    '(?im)^\s*(?:sudo\s+)?(?:reboot|shutdown|poweroff|halt|modprobe|rmmod|insmod|setpci|mount|umount|dd)\b|/sys/bus/pci/(?:rescan|devices/[^\s]+/remove)|os\.pwrite|O_RDWR|>\s*/(?:sys|proc)/'
).Count
Add-Check 'PREBOOTSTRAP_NO_STATE_MUTATION' ($prebootstrapForbidden -eq 0) "forbidden_matches=$prebootstrapForbidden"

$preloader = Read-Exact (Join-Path $scriptRoot 'r5_post_reboot_preloader_readonly.sh')
$postloader = Read-Exact (Join-Path $scriptRoot 'r5_post_loader_readonly.sh')
$validatorForbidden = [regex]::Matches(
    $preloader + "`n" + $postloader,
    '(?im)^\s*(?:sudo\s+)?(?:reboot|shutdown|poweroff|halt|modprobe|rmmod|insmod|setpci|mount|umount|dd)\b|/sys/bus/pci/(?:rescan|devices/[^\s]+/remove)|os\.pwrite|O_RDWR|>\s*/(?:sys|proc)/'
).Count
Add-Check 'POST_REBOOT_VALIDATORS_READ_ONLY' ($validatorForbidden -eq 0) "forbidden_matches=$validatorForbidden"
Add-Check 'PRELOADER_EXACT_STATE_GATES' (
    $preloader.Contains('BOOT_ID_CHANGED=YES') -and
    $preloader.Contains('BAR0_BYTES=%s') -and
    $preloader.Contains('ENDPOINT_BOUND_DRIVER=ABSENT') -and
    $preloader.Contains('PRELOADER_GATE=PASS')
) 'new boot, endpoint/BAR geometry, unbound/no-module/no-node gates'
Add-Check 'POSTLOADER_ROLE_SPECIFIC_IDENTITY' (
    $postloader.Contains('RUNTIME_IMAGE=FORMAL_PHASE2_EXACT_IDENTITY_PAGE_ZERO') -and
    $postloader.Contains('RUNTIME_IMAGE=R1E_EXACT_PROVENANCE') -and
    $postloader.Contains('expected_page = {') -and
    $postloader.Contains('RAW_READER_MODE=O_RDONLY_PREAD_ONLY') -and
    $postloader.Contains('POST_LOADER_GATE=PASS_')
) 'formal and R1e role-specific provenance plus accepted-reader checks'

$loader = Read-Exact (Join-Path $scriptRoot 'Invoke-R5ExactPinnedLoaderOnce.ps1')
$reboot = Read-Exact (Join-Path $scriptRoot 'Invoke-R5WarmRebootOnce.ps1')
$remoteValidator = Read-Exact (Join-Path $scriptRoot 'Invoke-R5RemoteValidator.ps1')
Add-Check 'EXACT_LOADER_SINGLE_INVOCATION_SITE' (
    [regex]::Matches($loader, '(?m)^\s*\& \$helperPath\s*`\s*$').Count -eq 1 -and
    [regex]::Matches($loader, '(?m)\bexec sudo -S -k -p').Count -eq 1 -and
    -not [regex]::IsMatch($loader, '(?im)^\s*(for|foreach|while|do)\b')
) 'one contextual helper site, one remote exec-loader site, no retry loop'
Add-Check 'WARM_REBOOT_SINGLE_INVOCATION_SITE' (
    [regex]::Matches($reboot, [regex]::Escape("sudo -S -k -p '' /usr/sbin/reboot")).Count -eq 1 -and
    [regex]::Matches($reboot, '(?m)^\s*\& \$helperPath\s*`\s*$').Count -eq 1 -and
    -not [regex]::IsMatch($reboot, '(?im)^\s*(for|foreach|while|do)\b')
) 'one reboot command, one helper site, no retry loop'
Add-Check 'REMOTE_VALIDATOR_SINGLE_HELPER_SITE' (
    [regex]::Matches($remoteValidator, '(?m)^\s*\& \$helperPath\s*`\s*$').Count -eq 1
) 'one selected read-only validator per call'

$doneWrapper = Read-Exact (Join-Path $scriptRoot 'Invoke-R5IndependentDoneReadOnly.ps1')
$doneTcl = Read-Exact (Join-Path $scriptRoot 'read_jtag_identity_done_strong.tcl')
$doneProgramCommands = [regex]::Matches($doneTcl, '(?m)^\s*(?:program_hw_devices\b|set_property\s+PROGRAM\.FILE\b)').Count
Add-Check 'INDEPENDENT_DONE_READ_ONLY' (
    $doneProgramCommands -eq 0 -and
    $doneWrapper.Contains('FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT=0') -and
    $doneWrapper.Contains("INDEPENDENT_DONE_GATE=`$gate")
) "program_commands=$doneProgramCommands; exact target/part/IDCODE/DONE checked by frozen Tcl"

$telemetry = Read-Exact (Join-Path $scriptRoot 'Invoke-R5TelemetryReadOnly.ps1')
Add-Check 'TELEMETRY_FROZEN_READER_HASH' (
    $telemetry.Contains('0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037')
) 'exact frozen R1e reader hash embedded'
Add-Check 'TELEMETRY_TWO_SNAPSHOTS_READ_ONLY' (
    $telemetry.Contains('--twice --delay 1.0') -and
    $telemetry.Contains("{'r1e'}else{'formal'}") -and
    -not [regex]::IsMatch($telemetry, 'os\.pwrite|O_RDWR|AXI_LITE_WRITE')
) 'ArmA expects r1e, ArmB expects formal, twice with 1-second delay'

$hostCycle = Read-Exact (Join-Path $scriptRoot 'Wait-R5HostCycle.ps1')
Add-Check 'HOST_CYCLE_DOWN_THEN_UP' (
    $hostCycle.Contains('PASS_HOST_DISAPPEARED_AND_RETURNED') -and
    $hostCycle.Contains('$downSeen-and$upAfterDownSeen')
) 'TCP/22 observer requires DOWN followed by UP'

$runbookPath = Join-Path $scriptRoot 'R5_POST_COLD_RESET_HOST_AND_PHASE_RUNBOOK.md'
$runbook = Read-Exact $runbookPath
Add-Check 'RUNBOOK_FULL_PHASE_ORDER' (
    $runbook.Contains('Invoke-R5ProgramPhaseOnce.ps1') -and
    $runbook.Contains('Invoke-R5IndependentDoneReadOnly.ps1') -and
    $runbook.Contains('Invoke-R5WarmRebootOnce.ps1') -and
    $runbook.Contains('Wait-R5HostCycle.ps1') -and
    $runbook.Contains('Invoke-R5RemoteValidator.ps1') -and
    $runbook.Contains('Invoke-R5ExactPinnedLoaderOnce.ps1') -and
    $runbook.Contains('Invoke-R5TelemetryReadOnly.ps1')
) 'program, independent DONE, reboot/down-up, pre/post-loader validation, loader, telemetry'
Add-Check 'RUNBOOK_NO_INLINE_PASSWORD_OPTION' (
    -not [regex]::IsMatch($runbook, '(?i)(?:^|\s)-pw(?:\s|$)')
) 'no executable PuTTY -pw form; frozen helper uses -pwfile'

$selectedProgramPath = Join-Path $scriptRoot 'Invoke-R5ProgramPhaseOnce.ps1'
$selectedProgramSha = if (Test-Path -LiteralPath $selectedProgramPath -PathType Leaf) {
    (Get-FileHash -LiteralPath $selectedProgramPath -Algorithm SHA256).Hash
} else { 'MISSING' }
Add-Check 'SELECTED_PROGRAM_SUPERVISOR_PRESENT_INFORMATIONAL' (
    $selectedProgramSha -ceq 'F27D4FB38AB8E080D30F647BA87D8CFC87F2A35B14A4B125DB03F15DCD099A44'
) "selected/current SHA256=$selectedProgramSha; owned/audited separately by JTAG agent"

$failures = @($checks | Where-Object { -not $_.Pass })
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# R5 host/safety/post-program tooling static audit')
$lines.Add('')
$lines.Add('Scope: offline source/hash/AST checks only. No Plink, SSH, Vivado, JTAG, MMIO, reboot, loader, or hardware command was executed.')
$lines.Add('')
$lines.Add('| Check | Result | Evidence |')
$lines.Add('|---|---|---|')
foreach ($check in $checks) {
    $safe = $check.Evidence.Replace('|','\|').Replace("`r",' ').Replace("`n",' ')
    $lines.Add("| $($check.Name) | $(if($check.Pass){'PASS'}else{'FAIL'}) | $safe |")
}
$lines.Add('')
$lines.Add('BASH_DYNAMIC_SYNTAX_CHECK=NOT_AVAILABLE_NO_LOCAL_BASH_OR_WSL_DISTRIBUTION')
$lines.Add('BASH_REVIEW_METHOD=FROZEN_R4_NORMALIZED_EQUALITY_PLUS_FORBIDDEN_OPERATION_AND_REQUIRED_GATE_SCAN')
$lines.Add("STATIC_CHECK_COUNT=$($checks.Count)")
$lines.Add("STATIC_FAILURE_COUNT=$($failures.Count)")
$lines.Add('LIVE_SSH_JTAG_VIVADO_MMIO_REBOOT_LOADER_ACTIONS=0')
$lines.Add('POST_PROGRAM_TOOLS_EXECUTED=NO_STATIC_PREPARATION_ONLY')
$lines.Add('R5_HOST_AND_PHASE_TOOLING_STATIC_GATE=' + $(if($failures.Count -eq 0){'PASS'}else{'FAIL'}))
[IO.File]::WriteAllLines($resultPath,$lines,[Text.UTF8Encoding]::new($false))
$lines | Select-Object -Last 8
if($failures.Count -ne 0){exit 1}
exit 0
