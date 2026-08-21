[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorktreeRoot,

    [Parameter(Mandatory = $true)]
    [string]$BuildRoot,

    [Parameter(Mandatory = $true)]
    [string]$EvidenceRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$ExpectedCommit,

    [Parameter(Mandatory = $true)]
    [string]$VivadoLogPath,

    [string]$BitFilename = 'ahd_capture_v41_i2c_25khz_r1.bit',

    [string]$OutputPath,

    [int]$AcceptedReqp1839Maximum = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BaseCommit = '8464af66611f7c22b8a36a4aab915d598eedda3f'
$ExpectedBranch = 'diag/v41-nvp-i2c-25khz-r1'
$ExpectedPart = 'xc7a35tcsg325-2'
$ExpectedTop = 'ahd_capture_top_xdma'
$ExpectedXciSha256 = 'EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C'
$ExpectedBuildScriptSha256 = 'D7531F2B12B5CCBF91484C8A28182B0C0FCF71C93277A697F2D6793338DA8440'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $EvidenceRoot 'I25_POST_BUILD_GATE_RESULT.txt'
}

$script:Rows = New-Object System.Collections.Generic.List[string]
$script:Failures = New-Object System.Collections.Generic.List[string]

function Add-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][bool]$Pass
    )

    $rendered = if ($null -eq $Value) { '<null>' } else { [string]$Value }
    $script:Rows.Add(('{0}={1}' -f $Name, $rendered))
    if (-not $Pass) {
        $script:Failures.Add(('{0}={1}' -f $Name, $rendered))
    }
}

function Require-File {
    param([Parameter(Mandatory = $true)][string]$Path)

    $exists = Test-Path -LiteralPath $Path -PathType Leaf
    $size = if ($exists) { (Get-Item -LiteralPath $Path).Length } else { 0 }
    Add-Result -Name ('FILE_' + ([IO.Path]::GetFileName($Path)) + '_SIZE') -Value $size -Pass ($exists -and $size -gt 0)
    return $exists -and $size -gt 0
}

function Invoke-GitText {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    # The verifier may run from the restricted automation account while the
    # worktree is owned by the interactive owner. This per-command trust is
    # read-only and avoids mutating global Git configuration.
    $output = & git -c "safe.directory=$WorktreeRoot" -C $WorktreeRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: git -C $WorktreeRoot $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    return ($output -join [Environment]::NewLine).Trim()
}

function Read-KeyValueFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^([^=]+)=(.*)$') {
            $map[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $map
}

function Require-KeyValue {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Map,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    $actual = if ($Map.ContainsKey($Key)) { [string]$Map[$Key] } else { '<missing>' }
    Add-Result -Name $Key -Value $actual -Pass ($actual -ceq $Expected)
}

function Require-NumericGate {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Map,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][ValidateSet('GE_ZERO', 'GT_ZERO')][string]$Rule
    )

    $actual = if ($Map.ContainsKey($Key)) { [string]$Map[$Key] } else { '<missing>' }
    $number = 0.0
    $parsed = [double]::TryParse(
        $actual,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$number)
    $pass = $false
    if ($parsed) {
        if ($Rule -eq 'GE_ZERO') { $pass = $number -ge 0.0 }
        if ($Rule -eq 'GT_ZERO') { $pass = $number -gt 0.0 }
    }
    Add-Result -Name $Key -Value $actual -Pass $pass
}

try {
    foreach ($root in @($WorktreeRoot, $BuildRoot, $EvidenceRoot)) {
        Add-Result -Name ('DIRECTORY_' + ([IO.Path]::GetFileName($root)) + '_EXISTS') -Value (Test-Path -LiteralPath $root -PathType Container) -Pass (Test-Path -LiteralPath $root -PathType Container)
    }

    $head = Invoke-GitText -Arguments @('rev-parse', 'HEAD')
    $branch = Invoke-GitText -Arguments @('branch', '--show-current')
    $parents = Invoke-GitText -Arguments @('show', '-s', '--format=%P', 'HEAD')
    $status = Invoke-GitText -Arguments @('status', '--porcelain', '--untracked-files=all')
    Add-Result -Name 'SOURCE_HEAD' -Value $head -Pass ($head -ceq $ExpectedCommit)
    Add-Result -Name 'SOURCE_BRANCH' -Value $branch -Pass ($branch -ceq $ExpectedBranch)
    Add-Result -Name 'SOURCE_PARENT' -Value $parents -Pass ($parents -ceq $BaseCommit)
    Add-Result -Name 'SOURCE_TREE_CLEAN' -Value ([string]::IsNullOrWhiteSpace($status)) -Pass ([string]::IsNullOrWhiteSpace($status))

    $changedFilesText = Invoke-GitText -Arguments @('diff', '--name-only', "$BaseCommit..$ExpectedCommit", '--')
    $changedFiles = @($changedFilesText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $singleChangedFile = $changedFiles.Count -eq 1 -and $changedFiles[0] -ceq 'rtl/top/ahd_capture_top_xdma.sv'
    Add-Result -Name 'TRACKED_FUNCTIONAL_DIFF_COUNT' -Value $changedFiles.Count -Pass $singleChangedFile
    Add-Result -Name 'TRACKED_FUNCTIONAL_DIFF_PATHS' -Value ($changedFiles -join ',') -Pass $singleChangedFile

    $numstat = Invoke-GitText -Arguments @('diff', '--numstat', "$BaseCommit..$ExpectedCommit", '--', 'rtl/top/ahd_capture_top_xdma.sv')
    Add-Result -Name 'TRACKED_FUNCTIONAL_DIFF_NUMSTAT' -Value $numstat -Pass ($numstat -match '^1\s+1\s+rtl/top/ahd_capture_top_xdma\.sv$')

    $baseTop = Invoke-GitText -Arguments @('show', "$BaseCommit`:rtl/top/ahd_capture_top_xdma.sv")
    $candidateTop = Invoke-GitText -Arguments @('show', "$ExpectedCommit`:rtl/top/ahd_capture_top_xdma.sv")
    $base50Count = ([regex]::Matches($baseTop, '\.I2C_HZ\(50000\)')).Count
    $candidate25Count = ([regex]::Matches($candidateTop, '\.I2C_HZ\(25000\)')).Count
    $candidate50Count = ([regex]::Matches($candidateTop, '\.I2C_HZ\(50000\)')).Count
    Add-Result -Name 'BASE_I2C_HZ_50000_OCCURRENCES' -Value $base50Count -Pass ($base50Count -eq 1)
    Add-Result -Name 'CANDIDATE_I2C_HZ_25000_OCCURRENCES' -Value $candidate25Count -Pass ($candidate25Count -eq 1)
    Add-Result -Name 'CANDIDATE_I2C_HZ_50000_OCCURRENCES' -Value $candidate50Count -Pass ($candidate50Count -eq 0)

    $protectedSha256 = [ordered]@{
        'scripts/v41/phase3_build.tcl' = $ExpectedBuildScriptSha256
        'ip/v41/xdma_v41_m1.xci' = $ExpectedXciSha256
        'rtl/nvp/nvp6134c_autoinit.vhd' = '74EFDC0147ADEA9A13265C061ECD3BA0B8042A2357B0A0E10673112F9986C17F'
        'rtl/nvp/nvp6134c_i2c_bringup.vhd' = '027D0D2258E5FF80A2675198EA9CD7085E2FD360B0EBCE9C423D631656DF9080'
        'rtl/nvp/nvp6134c_diagnostics_pkg.vhd' = '36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156'
        'xdc/boards/current/nvp_control.xdc' = 'B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318'
        'rtl/v41/control_status_regs.sv' = '849DC315A243267941D196BC8039426F4C99893DDFBD9BD9F4E21EA5741C392F'
        'tb/v41/tb_control_status_regs.sv' = '8AA22C76A5761DAF792A464EEE1CFE9F78498AF37E9489A38D0890CD3C7F56B8'
        'docs/v41/phase3/AXI_LITE_REGISTER_MAP.md' = '984B3A89E182AFAD9513FD1F6269539C26150B8685E3295D28A12200CAB06047'
    }
    foreach ($entry in $protectedSha256.GetEnumerator()) {
        $path = Join-Path $WorktreeRoot $entry.Key
        $actual = if (Test-Path -LiteralPath $path -PathType Leaf) { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash } else { '<missing>' }
        Add-Result -Name ('SHA256_' + ($entry.Key -replace '[^A-Za-z0-9]', '_')) -Value $actual -Pass ($actual -ceq $entry.Value)
    }

    $buildInputXci = Join-Path $BuildRoot 'input_xci\xdma_v41_m1.xci'
    $buildInputXciSha = if (Test-Path -LiteralPath $buildInputXci -PathType Leaf) { (Get-FileHash -Algorithm SHA256 -LiteralPath $buildInputXci).Hash } else { '<missing>' }
    Add-Result -Name 'BUILD_INPUT_XCI_SHA256' -Value $buildInputXciSha -Pass ($buildInputXciSha -ceq $ExpectedXciSha256)

    $resultPath = Join-Path $EvidenceRoot 'PHASE3_BUILD_RESULT.txt'
    $provenancePath = Join-Path $EvidenceRoot 'PHASE3_BUILD_PROVENANCE.txt'
    $runtimeProvenancePath = Join-Path $EvidenceRoot 'EXPECTED_RUNTIME_PROVENANCE.txt'
    foreach ($path in @($resultPath, $provenancePath, $runtimeProvenancePath, $VivadoLogPath)) {
        [void](Require-File -Path $path)
    }

    $result = Read-KeyValueFile -Path $resultPath
    foreach ($pair in @(
        @('SOURCE_GIT_COMMIT', $ExpectedCommit),
        @('PROJECT_CREATION', 'PASS'),
        @('SYNTHESIS', 'PASS'),
        @('IMPLEMENTATION', 'PASS'),
        @('ROUTE', 'PASS'),
        @('ROUTE_ERRORS', '0'),
        @('DRC_ERRORS', '0'),
        @('DRC_CRITICAL_WARNINGS', '0'),
        @('BUS_SKEW_VIOLATIONS', '0'),
        @('CDC_CRITICAL_TYPES', '0'),
        @('BITSTREAM_GENERATED', 'YES'),
        @('PHASE3_IMPLEMENTATION_GATE', 'PASS')
    )) {
        Require-KeyValue -Map $result -Key $pair[0] -Expected $pair[1]
    }
    Require-NumericGate -Map $result -Key 'WNS' -Rule GE_ZERO
    Require-NumericGate -Map $result -Key 'WHS' -Rule GT_ZERO
    Require-NumericGate -Map $result -Key 'VDO_WNS' -Rule GT_ZERO
    Require-NumericGate -Map $result -Key 'VDO_WHS' -Rule GT_ZERO

    $provenance = Read-KeyValueFile -Path $provenancePath
    foreach ($pair in @(
        @('SOURCE_GIT_COMMIT', $ExpectedCommit),
        @('SOURCE_TREE_CLEAN', 'YES'),
        @('BUILD_FLAGS', '0x00000002'),
        @('VIVADO_VERSION', '2025.2'),
        @('VIVADO_SW_BUILD', '6299465'),
        @('PART', $ExpectedPart),
        @('TOP', $ExpectedTop)
    )) {
        Require-KeyValue -Map $provenance -Key $pair[0] -Expected $pair[1]
    }

    $runtimeProvenance = Read-KeyValueFile -Path $runtimeProvenancePath
    Require-KeyValue -Map $runtimeProvenance -Key 'BIT_SOURCE_COMMIT' -Expected $ExpectedCommit
    Require-KeyValue -Map $runtimeProvenance -Key 'EXPECTED_BUILD_FLAGS' -Expected '0x00000002'
    Require-KeyValue -Map $runtimeProvenance -Key 'RECONSTRUCTED_GIT_SHA' -Expected $ExpectedCommit
    Require-KeyValue -Map $runtimeProvenance -Key 'PROVENANCE_ROUND_TRIP' -Expected 'PASS'
    for ($wordIndex = 0; $wordIndex -lt 5; $wordIndex++) {
        $word = $ExpectedCommit.Substring($wordIndex * 8, 8)
        Require-KeyValue -Map $runtimeProvenance -Key ('EXPECTED_GIT_SHA_W{0}' -f $wordIndex) -Expected ('0x' + $word)
    }

    $requiredReports = @(
        'PHASE3_synth.dcp',
        'PHASE3_routed.dcp',
        'PHASE3_route_status.rpt',
        'PHASE3_timing_summary.rpt',
        'PHASE3_drc.rpt',
        'PHASE3_bus_skew.rpt',
        'PHASE3_cdc.rpt',
        'PHASE3_check_timing.rpt',
        'PHASE3_exception_coverage.rpt',
        'PHASE3_clock_interaction.rpt',
        'PHASE3_utilization.rpt',
        'PHASE3_utilization_hierarchical.rpt',
        'PHASE3_clock_utilization.rpt',
        'PHASE3_congestion.rpt',
        'PHASE3_methodology.rpt',
        'PHASE3_design_properties.txt',
        'PHASE3_vdo_setup_paths.rpt',
        'PHASE3_vdo_hold_paths.rpt'
    )
    foreach ($name in $requiredReports) {
        [void](Require-File -Path (Join-Path $EvidenceRoot $name))
    }

    $routeText = Get-Content -Raw -LiteralPath (Join-Path $EvidenceRoot 'PHASE3_route_status.rpt')
    $routeMatch = [regex]::Match($routeText, '# of nets with routing errors[^:]*:\s*([0-9]+)')
    $rawRouteErrors = if ($routeMatch.Success) { [int]$routeMatch.Groups[1].Value } else { -1 }
    Add-Result -Name 'RAW_ROUTE_ERRORS' -Value $rawRouteErrors -Pass ($rawRouteErrors -eq 0)

    $drcText = Get-Content -Raw -LiteralPath (Join-Path $EvidenceRoot 'PHASE3_drc.rpt')
    Add-Result -Name 'DRC_REPORT_COMPLETE' -Value ($drcText -match 'Report DRC' -and $drcText -match 'REPORT SUMMARY' -and $drcText -match 'REPORT DETAILS') -Pass ($drcText -match 'Report DRC' -and $drcText -match 'REPORT SUMMARY' -and $drcText -match 'REPORT DETAILS')
    $reqpSummary = [regex]::Matches($drcText, '(?m)^\|\s*REQP-1839\s*\|\s*Warning\s*\|[^|]*\|\s*([0-9]+)\s*\|\s*$')
    $reqpDetail = [regex]::Matches($drcText, '(?m)^REQP-1839#[0-9]+\s+Warning\s*$')
    $reqpCount = if ($reqpSummary.Count -eq 1) { [int]$reqpSummary[0].Groups[1].Value } elseif ($reqpSummary.Count -eq 0 -and $reqpDetail.Count -eq 0) { 0 } else { -1 }
    $reqpCrosscheck = $reqpCount -ge 0 -and $reqpCount -eq $reqpDetail.Count
    Add-Result -Name 'REQP_1839_COUNT' -Value $reqpCount -Pass ($reqpCrosscheck -and $reqpCount -le $AcceptedReqp1839Maximum)
    Add-Result -Name 'REQP_1839_NO_INCREASE' -Value ($reqpCount -ge 0 -and $reqpCount -le $AcceptedReqp1839Maximum) -Pass ($reqpCount -ge 0 -and $reqpCount -le $AcceptedReqp1839Maximum)

    $cdcText = Get-Content -Raw -LiteralPath (Join-Path $EvidenceRoot 'PHASE3_cdc.rpt')
    $cdcRows = [regex]::Matches($cdcText, '(?m)^CDC-[0-9]+\s+(Info|Warning|Critical(?: Warning)?|Unknown)\s+([0-9]+)\s+')
    Add-Result -Name 'CDC_SUMMARY_ROW_COUNT' -Value $cdcRows.Count -Pass ($cdcRows.Count -gt 0)
    $cdcCritical = 0
    $cdcUnknown = 0
    foreach ($row in $cdcRows) {
        $severity = $row.Groups[1].Value
        $count = [int]$row.Groups[2].Value
        if ($severity -match '^Critical') { $cdcCritical += $count }
        if ($severity -ceq 'Unknown') { $cdcUnknown += $count }
    }
    $unknownWordCount = ([regex]::Matches($cdcText, '(?i)\bUnknown\b')).Count
    Add-Result -Name 'CDC_CRITICAL' -Value $cdcCritical -Pass ($cdcCritical -eq 0)
    Add-Result -Name 'CDC_UNKNOWN' -Value $cdcUnknown -Pass ($cdcUnknown -eq 0 -and $unknownWordCount -eq 0)
    Add-Result -Name 'CDC_UNKNOWN_WORD_OCCURRENCES' -Value $unknownWordCount -Pass ($unknownWordCount -eq 0)

    $vivadoLog = Get-Content -Raw -LiteralPath $VivadoLogPath
    Add-Result -Name 'VIVADO_VERSION_ACTUAL' -Value '2025.2_BUILD_6299465' -Pass ($vivadoLog -match 'Vivado v2025\.2' -and $vivadoLog -match 'SW Build 6299465')
    $vivadoErrors = ([regex]::Matches($vivadoLog, '(?m)^ERROR:')).Count
    Add-Result -Name 'VIVADO_LOG_ERROR_LINES' -Value $vivadoErrors -Pass ($vivadoErrors -eq 0)

    $bitPath = Join-Path (Join-Path $EvidenceRoot 'artifacts') $BitFilename
    if (Require-File -Path $bitPath) {
        Add-Result -Name 'DIAGNOSTIC_BIT_SHA256' -Value (Get-FileHash -Algorithm SHA256 -LiteralPath $bitPath).Hash -Pass $true
    }
    foreach ($dcpName in @('PHASE3_synth.dcp', 'PHASE3_routed.dcp')) {
        $dcpPath = Join-Path $EvidenceRoot $dcpName
        if (Test-Path -LiteralPath $dcpPath -PathType Leaf) {
            Add-Result -Name (($dcpName -replace '[^A-Za-z0-9]', '_') + '_SHA256') -Value (Get-FileHash -Algorithm SHA256 -LiteralPath $dcpPath).Hash -Pass $true
        }
    }
}
catch {
    $script:Failures.Add(('PARSER_EXCEPTION=' + $_.Exception.Message))
}
finally {
    $overall = if ($script:Failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('TASK=V41_NVP_I2C_25KHZ_PAIRED_AB_R1')
    $lines.Add('POST_BUILD_GATE=' + $overall)
    foreach ($row in $script:Rows) { $lines.Add($row) }
    $lines.Add('FAILURE_COUNT=' + $script:Failures.Count)
    foreach ($failure in $script:Failures) { $lines.Add('FAILURE=' + $failure) }
    $lines.Add('FULL_BUILDS_EXPECTED=1')
    $lines.Add('HARDWARE_AUTHORIZED_BY_THIS_SCRIPT=NO')
    $lines | Set-Content -LiteralPath $OutputPath -Encoding ascii
}

if ($script:Failures.Count -ne 0) {
    Get-Content -LiteralPath $OutputPath
    exit 1
}

Get-Content -LiteralPath $OutputPath
exit 0
