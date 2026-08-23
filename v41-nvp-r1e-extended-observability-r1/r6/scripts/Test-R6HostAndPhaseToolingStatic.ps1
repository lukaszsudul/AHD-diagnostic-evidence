[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$scriptRoot = Join-Path $taskRoot 'scripts'
$r5ScriptRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts'
$failures = [Collections.Generic.List[string]]::new()
$checks = [Collections.Generic.List[string]]::new()

function Add-Check([string]$Name, [bool]$Passed, [string]$Detail) {
    $checks.Add("$Name=$(if ($Passed) {'PASS'} else {'FAIL'}) DETAIL=$Detail")
    if (-not $Passed) { $failures.Add("$Name`: $Detail") }
}

function Read-Text([string]$Name) {
    return [IO.File]::ReadAllText((Join-Path $scriptRoot $Name))
}

function Count-Matches([string]$Text, [string]$Pattern) {
    return [regex]::Matches($Text, $Pattern).Count
}

$expectedHashes = [ordered]@{
    'Invoke-ContextualPlink.ps1' = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
    'parse_pci_bars.py' = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
    'read_nvp_r1e.py' = '0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037'
    'verify_runtime_identity.py' = '84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C'
    'analyze_r4_telemetry.py' = 'A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967'
    'ProgramObserverCommon.ps1' = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
    'r6_host_baseline_sample_readonly.sh' = '5FA47F2150BC816F9075C16C152423F85F0BFAB1466A2859591BB137C12D4AFC'
    'Invoke-R6HostBaseline.ps1' = '6E7DF2B1972D81A497E1B3B442D37F9FF82BD8C1E26B2AAC605DBE4AADDB188D'
    'r6_prebootstrap_safety_readonly.sh' = '89F9DE845E42766684A37C6518694CBD18953B8E30E1C95B82CA84A999E8EFBC'
    'Invoke-R6PreBootstrapSafetyDiscovery.ps1' = '3B44CB557DD67E6684199D88A91BBDE812DCBDA97E02ABD591AACA2938D5784C'
    'r6_post_reboot_preloader_readonly.sh' = '5AB73A9D90DF96A0A3809499B6381437C0FFBB85EB2A87B152F0812F1B4402B9'
    'r6_post_loader_readonly.sh' = '0695281F1D212C1F90A31A6359F0D606F48AF67528D0F1E379009E72C04EEBD4'
    'Invoke-R6RemoteValidator.ps1' = '65975474DCFD34129F16B90AFC81749BB405568BFBB4F28BB49EEBA5C6E6D7CC'
    'Invoke-R6ExactPinnedLoaderOnce.ps1' = 'DE175629A945D02A772638221AF81C9C2FDC364C5990BC4BE5E5883802A8AF8B'
    'Invoke-R6WarmRebootOnce.ps1' = '14E5B3DFF5BA0C73A0CCFC56052757EEEC69C1C726A9866C8C1ED8B15AF8A179'
    'Wait-R6HostCycle.ps1' = 'BB1A4E7B10D22949FAE14B509E7945436C95CC91DAAB61F4A8BE98AD3EA07576'
    'Invoke-R6TelemetryReadOnly.ps1' = 'D8732544D1437622CB0877C2F85898010324A67BB778CF2A8F9B2271361ED283'
    'program_once_startup_high_done_r6_selected.tcl' = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
    'Invoke-R6ProgramPhaseOnce.ps1' = 'DCFAF6C83CCB828E6CB8DB18584FCBBD8083C14E61332E430B2AC783353DEA53'
    'read_jtag_identity_done_r6_selected.tcl' = 'A1D967C7306F0C751DC5A41DE3A3D331A0CE92E36BB9430C7D99604FC8432D30'
    'Invoke-R6IndependentDoneReadOnly.ps1' = '35FCB94602EF6CA292412B3E2925C04783F53356936FCF6924260027F911CF3C'
}

$manifestRows = [Collections.Generic.List[string]]::new()
$manifestRows.Add('filename,size_bytes,sha256,expected_sha256,gate')
foreach ($entry in $expectedHashes.GetEnumerator()) {
    $path = Join-Path $scriptRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Check "HASH_$($entry.Key)" $false 'missing'
        continue
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $size = (Get-Item -LiteralPath $path).Length
    $pass = $actual -ceq $entry.Value
    Add-Check "HASH_$($entry.Key)" $pass $actual
    $manifestRows.Add("$($entry.Key),$size,$actual,$($entry.Value),$(if ($pass) {'PASS'} else {'FAIL'})")
}

$psFiles = @($expectedHashes.Keys | Where-Object { $_ -like '*.ps1' })
foreach ($name in $psFiles) {
    $tokens = $null; $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptRoot $name), [ref]$tokens, [ref]$parseErrors) | Out-Null
    $parseMessages = @($parseErrors | ForEach-Object { $_.Message }) -join ' | '
    Add-Check "POWERSHELL_PARSE_$name" (@($parseErrors).Count -eq 0) $parseMessages
}

$baselinePs = Read-Text 'Invoke-R6HostBaseline.ps1'
$baselineSh = Read-Text 'r6_host_baseline_sample_readonly.sh'
Add-Check 'BASELINE_EXACT_THREE_SESSION_LOOP' ((Count-Matches $baselinePs 'for \(\$session = 1; \$session -le 3; \$session\+\+\)') -eq 1) 'one bounded 1..3 loop'
Add-Check 'BASELINE_MINIMUM_FIVE_SECOND_SPAN' ($baselinePs.Contains('5.250 * $frequency') -and $baselinePs.Contains('$MinimumSpanSeconds = 5.0')) 'local and remote span gated'
Add-Check 'BASELINE_SUDO_READ_ONLY_CONTEXT' ($baselinePs.Contains('-SendPasswordToStdin') -and $baselinePs.Contains('-SudoPasswordCopies 1')) 'privileged reads use frozen pwfile helper'
Add-Check 'BASELINE_NEXT_BOOT_PROOF' ($baselineSh.Contains('NEXT_REBOOT_KERNEL_PROVEN=%s') -and $baselineSh.Contains('grub-editenv /boot/grub/grubenv list')) 'kernel29 selected entry is read and checked'
Add-Check 'BASELINE_NO_GRUB_WRITE' (-not [regex]::IsMatch($baselineSh, '(?im)^\s*(?:grub-set-default|grub-reboot|update-grub)\b|\bgrub-editenv\b[^\r\n]*\b(?:set|unset|create)\b')) 'no GRUB mutation command'
Add-Check 'BASELINE_NO_HOST_STATE_CHANGE' (-not [regex]::IsMatch($baselineSh, '(?im)^\s*(?:reboot|shutdown|poweroff|halt|systemctl|modprobe|insmod|rmmod|setpci|mount|umount|rm|mv|cp|chmod|chown|mkdir|touch)\b')) 'read-only payload command inventory'

$safetyPs = Read-Text 'Invoke-R6PreBootstrapSafetyDiscovery.ps1'
$safetySh = Read-Text 'r6_prebootstrap_safety_readonly.sh'
Add-Check 'PREBOOTSTRAP_BASELINE_BINDING' ($safetyPs.Contains("'R6_HOST_BASELINE') -cne 'PASS_3_OF_3'") -and $safetyPs.Contains("'R6_BOOT_ID_BASELINE') -cne `$R6BootIdBaseline")) 'host baseline and boot ID required'
Add-Check 'PREBOOTSTRAP_JTAG_BINDING' ($safetyPs.Contains("'JTAG_TRANSPORT_STABILITY_GATE') -cne 'PASS_10_OF_10'")) 'selected-JTAG stability required'
Add-Check 'PREBOOTSTRAP_FORMAL_BIT_BINDING' ($safetyPs.Contains('7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2') -and $safetyPs.Contains('2192144L')) 'exact formal bit hash and size required'
Add-Check 'PREBOOTSTRAP_ZERO_OR_ONE_ENDPOINT' ($safetySh.Contains('[[ ${#expected_endpoints[@]} -le 1 ]]') -and $safetySh.Contains('ABSENT_ACCEPTED')) 'endpoint absence accepted; multiple rejected'
Add-Check 'PREBOOTSTRAP_DRIVER_ABSENCE_ACCEPTED' ($safetySh.Contains('XDMA_LOADED_VERSION=ABSENT_ACCEPTED') -and $safetySh.Contains('PRE_BOOTSTRAP_DRIVER_STATE=%s')) 'absent driver/node state accepted'
Add-Check 'PREBOOTSTRAP_R6_REMOTE_DIRS' ((Count-Matches $safetySh 'v41_nvp_r1e_r6/(?:bootstrap_driver|arm_a_driver|arm_b_driver)') -eq 3) 'all three fresh R6 loader directories'
Add-Check 'PREBOOTSTRAP_READ_ONLY' (-not [regex]::IsMatch($safetySh, '(?im)^\s*(?:reboot|shutdown|poweroff|systemctl|modprobe|insmod|rmmod|setpci|rm|mv|cp|chmod|chown|mkdir|touch)\b|/remove\b|/rescan\b')) 'no host/PCIe mutation command'

$preLoaderSh = Read-Text 'r6_post_reboot_preloader_readonly.sh'
$postLoaderSh = Read-Text 'r6_post_loader_readonly.sh'
Add-Check 'PRELOADER_READ_ONLY' (-not [regex]::IsMatch($preLoaderSh, '(?im)^\s*(?:reboot|shutdown|poweroff|systemctl|modprobe|insmod|rmmod|setpci|rm|mv|cp|chmod|chown|mkdir|touch)\b|/remove\b|/rescan\b')) 'read-only post-reboot gate'
Add-Check 'POSTLOADER_READ_ONLY_MMIO' ($postLoaderSh.Contains('os.O_RDONLY | os.O_CLOEXEC') -and $postLoaderSh.Contains('POST_LOADER_MMIO=READ_ONLY') -and -not $postLoaderSh.Contains('os.pwrite')) 'pread-only runtime validation'
Add-Check 'POSTLOADER_R6_REMOTE_DIRS' ((Count-Matches $postLoaderSh 'v41_nvp_r1e_r6/(?:bootstrap_driver|arm_a_driver|arm_b_driver)') -eq 3) 'phase-specific loader evidence paths'

$loaderPs = Read-Text 'Invoke-R6ExactPinnedLoaderOnce.ps1'
$rebootPs = Read-Text 'Invoke-R6WarmRebootOnce.ps1'
$waitPs = Read-Text 'Wait-R6HostCycle.ps1'
$telemetryPs = Read-Text 'Invoke-R6TelemetryReadOnly.ps1'
$loaderInvocationLiteral = 'exec sudo -S -k -p '''' /usr/bin/bash "$loader"'
Add-Check 'LOADER_ONE_INVOCATION' ((Count-Matches $loaderPs ([regex]::Escape($loaderInvocationLiteral))) -eq 1) 'one exec of exact accepted loader'
Add-Check 'LOADER_EXACT_IDENTITIES' ($loaderPs.Contains('1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A') -and $loaderPs.Contains('7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F')) 'module and loader hashes pinned'
Add-Check 'LOADER_R6_REMOTE_ROOT' ($loaderPs.Contains('v41_nvp_r1e_r6/__DRIVER_DIRECTORY__')) 'R6 phase directory only'
Add-Check 'REBOOT_ONE_INVOCATION' ((Count-Matches $rebootPs '/usr/sbin/reboot') -eq 1) 'one exact warm reboot command'
Add-Check 'HOST_CYCLE_READ_ONLY_POLL' ($waitPs.Contains('TcpClient') -and -not $waitPs.Contains('/usr/sbin/reboot') -and -not $waitPs.Contains('plink')) 'local TCP disappearance/return observer only'
Add-Check 'TELEMETRY_FROZEN_READER' ($telemetryPs.Contains('0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037') -and $telemetryPs.Contains('--twice --delay 1.0')) 'exact reader, two snapshots, one-second delay'

$r5ProgramPath = Join-Path $r5ScriptRoot 'Invoke-R5ProgramPhaseOnce.ps1'
$r5ProgramExpectedSha = 'F27D4FB38AB8E080D30F647BA87D8CFC87F2A35B14A4B125DB03F15DCD099A44'
$r5ProgramHash = if (Test-Path -LiteralPath $r5ProgramPath -PathType Leaf) { (Get-FileHash -LiteralPath $r5ProgramPath -Algorithm SHA256).Hash } else { 'MISSING' }
Add-Check 'R5_PROGRAM_SUPERVISOR_INPUT_HASH' ($r5ProgramHash -ceq $r5ProgramExpectedSha) $r5ProgramHash
$r5Program = if ($r5ProgramHash -ceq $r5ProgramExpectedSha) { [IO.File]::ReadAllText($r5ProgramPath) } else { '' }
$r6Program = Read-Text 'Invoke-R6ProgramPhaseOnce.ps1'
$normalized = $r6Program.Replace('C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6','C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5')
$normalized = $normalized.Replace('program_once_startup_high_done_r6_selected.tcl','program_once_startup_high_done.tcl')
$normalized = $normalized.Replace('00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC','7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653')
$normalized = $normalized.Replace('C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit','C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\02_FRESH_BUILD\SEALED\artifacts\ahd_capture_v41_phase2_p1.bit')
$normalized = $normalized.Replace('C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_i2c_25khz_r1e_observability.bit','C:\FPGA\V41_NVP_R1E_SEMANTIC_DRC_CONTINUATION_R3\05_BITSTREAM\ahd_capture_v41_i2c_25khz_r1e_observability.bit')
$normalized = $normalized.Replace("'07_FORMAL_BOOTSTRAP'","'05_FORMAL_BOOTSTRAP'").Replace("'08_ARM_A_R1E'","'06_ARM_A_R1E'").Replace("'09_ARM_B_FORMAL'","'07_ARM_B_FORMAL'")
$normalized = ($normalized -replace "`r`n", "`n").TrimEnd()
$r5Normalized = ($r5Program -replace "`r`n", "`n").TrimEnd()
Add-Check 'PROGRAM_SUPERVISOR_ONLY_AUTHORIZED_ADAPTATIONS' ($normalized -ceq $r5Normalized) 'R5 observer/process/QPC/no-retry logic text-identical after path/selector normalization'

$programTcl = Read-Text 'program_once_startup_high_done_r6_selected.tcl'
$doneTcl = Read-Text 'read_jtag_identity_done_r6_selected.tcl'
Add-Check 'PROGRAM_TCL_ONE_PROGRAM_COMMAND' ((Count-Matches $programTcl '(?m)^\s*program_hw_devices\s+\$dev\s*$') -eq 1) 'sole program command'
Add-Check 'PROGRAM_TCL_PREPROGRAM_DONE_PRESERVED' ($programTcl.Contains('if {$preprogram_done ne "1"}')) 'accepted pre-program DONE==1 gate retained'
Add-Check 'PROGRAM_TCL_SELECTED_TARGET' ($programTcl.Contains('localhost:3121/xilinx_tcf/Xilinx/80802026a98b01') -and $programTcl.Contains('source [file join [file dirname [info script]] select_r6_jtag_target.tcl]')) 'exact R6 selected-target layer'
Add-Check 'PROGRAM_TCL_NO_FREQUENCY_CHANGE' (-not [regex]::IsMatch($programTcl, '(?im)^\s*set_property\s+(?:FREQUENCY|JTAG_FREQUENCY)\b')) 'adapter default retained'
Add-Check 'INDEPENDENT_DONE_READ_ONLY' ((Count-Matches $doneTcl '(?m)^\s*program_hw_devices\b') -eq 0 -and (Count-Matches $doneTcl '(?m)^\s*set_property\b') -eq 0) 'zero program/property writes'
Add-Check 'INDEPENDENT_DONE_SELECTED_TARGET' ($doneTcl.Contains('localhost:3121/xilinx_tcf/Xilinx/80802026a98b01') -and $doneTcl.Contains('PASS_SELECTED_TARGET_DONE_1')) 'exact target and DONE=1 gate'

$legacyMatches = [Collections.Generic.List[string]]::new()
foreach ($name in @($expectedHashes.Keys | Where-Object { $_ -like 'Invoke-R6*' -or $_ -like 'r6_*' -or $_ -like 'Wait-R6*' })) {
    $text = Read-Text $name
    if ([regex]::IsMatch($text, 'V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5|v41_nvp_r1e_r5|04_HOST_SAFETY_DISCOVERY|05_FORMAL_BOOTSTRAP|06_ARM_A_R1E|07_ARM_B_FORMAL')) {
        $legacyMatches.Add($name)
    }
}
Add-Check 'NO_LEGACY_R5_PATHS_IN_R6_WRAPPERS' ($legacyMatches.Count -eq 0) (($legacyMatches -join ','))

$manifestPath = Join-Path $taskRoot '04_HOST_BASELINE\R6_HOST_TOOL_SHA256.csv'
$mainAuditPath = Join-Path $taskRoot '04_HOST_BASELINE\R6_HOST_AND_PHASE_TOOLING_STATIC_AUDIT.md'
$preAuditPath = Join-Path $taskRoot '06_PRE_BOOTSTRAP_SAFETY\R6_PRE_BOOTSTRAP_TOOLING_STATIC_AUDIT.md'
$phasePaths = [ordered]@{
    '07_FORMAL_BOOTSTRAP\R6_FORMAL_BOOTSTRAP_TOOLING_STATIC_AUDIT.md' = 'FORMAL_BOOTSTRAP'
    '08_ARM_A_R1E\R6_ARM_A_TOOLING_STATIC_AUDIT.md' = 'ARM_A_R1E'
    '09_ARM_B_FORMAL\R6_ARM_B_TOOLING_STATIC_AUDIT.md' = 'ARM_B_FORMAL'
}
foreach ($path in @($manifestPath,$mainAuditPath,$preAuditPath) + @($phasePaths.Keys | ForEach-Object { Join-Path $taskRoot $_ })) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite static-audit evidence: $path" }
}

[IO.File]::WriteAllLines($manifestPath, $manifestRows, [Text.UTF8Encoding]::new($false))
$gate = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$mainLines = [Collections.Generic.List[string]]::new()
$mainLines.Add('# R6 host and post-program tooling static audit')
$mainLines.Add('')
$mainLines.Add("STATIC_AUDIT_UTC=$([DateTime]::UtcNow.ToString('o'))")
$mainLines.Add("HOST_AND_PHASE_TOOLING_STATIC_AUDIT=$gate")
$mainLines.Add('LIVE_SSH_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('LIVE_JTAG_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('PROGRAMS_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('REBOOTS_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('LOADERS_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('MMIO_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('DMA_EXECUTED_BY_THIS_AUDIT=0')
$mainLines.Add('BASH_RUNTIME_SYNTAX_CHECK=NOT_AVAILABLE_LOCAL_WSL_DISTRIBUTION_ABSENT')
$mainLines.Add('BASH_VALIDATION=STATIC_COMMAND_INVENTORY_PLUS_R5_PROVEN_PAYLOAD_DERIVATION')
$mainLines.Add('POST_PROGRAM_TOOLS=PREPARED_NOT_EXECUTED')
$mainLines.Add('')
$mainLines.Add('## Checks')
$mainLines.Add('')
foreach ($check in $checks) { $mainLines.Add("- $check") }
foreach ($failure in $failures) { $mainLines.Add("- FAILURE=$failure") }
[IO.File]::WriteAllLines($mainAuditPath, $mainLines, [Text.UTF8Encoding]::new($false))

$preLines = [string[]]@(
    '# R6 pre-bootstrap safety tooling static audit','',
    "PRE_BOOTSTRAP_TOOLING_STATIC_AUDIT=$gate",
    'ENDPOINT_POLICY=ZERO_OR_ONE_EXACT_ENDPOINT_ENDPOINT_ABSENCE_ACCEPTED',
    'DRIVER_NODE_POLICY=ABSENCE_ACCEPTED_WRONG_OR_MULTIPLE_REJECTED',
    'CURRENT_RUNTIME_IDENTITY=CONTEXTUAL_READ_ONLY',
    'BASELINE_BINDING=R6_HOST_BASELINE_PASS_3_OF_3_PLUS_EXACT_BOOT_ID',
    'JTAG_BINDING=PASS_10_OF_10_REQUIRED',
    'FORMAL_BIT_GATE=EXACT_SIZE_AND_SHA256',
    'PRE_BOOTSTRAP_TOOL=PREPARED_NOT_EXECUTED',
    'LIVE_ACTIONS_THIS_AUDIT=0'
)
[IO.File]::WriteAllLines($preAuditPath, $preLines, [Text.UTF8Encoding]::new($false))

foreach ($entry in $phasePaths.GetEnumerator()) {
    $phasePath = Join-Path $taskRoot $entry.Key
    $phaseLines = [string[]]@(
        "# R6 $($entry.Value) host/post-program tooling static audit",'',
        "PHASE=$($entry.Value)",
        "PHASE_TOOLING_STATIC_AUDIT=$gate",
        'PROGRAM_SUPERVISOR=PREPARED_NOT_EXECUTED',
        'INDEPENDENT_DONE=PREPARED_NOT_EXECUTED',
        'WARM_REBOOT=PREPARED_NOT_EXECUTED',
        'HOST_CYCLE_OBSERVER=PREPARED_NOT_EXECUTED',
        'PRELOADER_VALIDATOR=PREPARED_NOT_EXECUTED',
        'EXACT_PINNED_LOADER=PREPARED_NOT_EXECUTED',
        'POSTLOADER_VALIDATOR=PREPARED_NOT_EXECUTED',
        "TELEMETRY=$(if ($entry.Value -eq 'FORMAL_BOOTSTRAP') {'NOT_SCIENTIFIC_ARM_B_BOOTSTRAP_IDENTITY_ONLY'} else {'PREPARED_NOT_EXECUTED'})",
        'LIVE_ACTIONS_THIS_AUDIT=0'
    )
    [IO.File]::WriteAllLines($phasePath, $phaseLines, [Text.UTF8Encoding]::new($false))
}

$mainLines | Select-Object -First 14
if ($gate -cne 'PASS') { exit 1 }
exit 0
