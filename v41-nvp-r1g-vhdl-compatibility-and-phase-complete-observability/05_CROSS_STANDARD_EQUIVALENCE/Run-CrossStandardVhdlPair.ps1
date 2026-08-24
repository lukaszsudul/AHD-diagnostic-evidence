param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('autoinit', 'd2b', 'power', 'serial', 'preinit')]
    [string]$TestKey,

    [switch]$CaptureVcd
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ReferenceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY'
$CandidateRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
$EvidenceRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\05_CROSS_STANDARD_EQUIVALENCE'
$ToolRoot = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$Xvhdl = Join-Path $ToolRoot 'xvhdl.bat'
$Xelab = Join-Path $ToolRoot 'xelab.bat'
$Xsim = Join-Path $ToolRoot 'xsim.bat'

$ExactR1fCommit = '225544084dbfcaadb8592fcecc947aa1cec4970e'
$ExactR1fTree = 'cfde8769af95cf20586391c411fab3ddfa2c87b6'

function Invoke-CapturedTool {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogStem
    )

    $commandRecord = @(
        "TOOL=$Tool"
        "WORKING_DIRECTORY=$WorkingDirectory"
        "ARGUMENT_COUNT=$($Arguments.Count)"
    )
    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        $commandRecord += "ARG_$index=$($Arguments[$index])"
    }
    [System.IO.File]::WriteAllLines(
        "$LogStem.command.txt",
        $commandRecord,
        [System.Text.UTF8Encoding]::new($false))

    Push-Location -LiteralPath $WorkingDirectory
    try {
        $output = @(& $Tool @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    $outputText = @($output | ForEach-Object { $_.ToString() })
    [System.IO.File]::WriteAllLines(
        "$LogStem.log",
        $outputText,
        [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText(
        "$LogStem.exit.txt",
        "PROCESS_EXIT_CODE=$exitCode`n",
        [System.Text.UTF8Encoding]::new($false))
    if ($exitCode -ne 0) {
        throw "tool failed with exit ${exitCode}: $Tool (see $LogStem.log)"
    }
}

function Get-NormalizedTranscript {
    param([Parameter(Mandatory = $true)][string]$LogPath)
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadLines($LogPath)) {
        if ($line -match '^(Note|Warning|Error|Fatal):') {
            $result.Add($line)
        }
        elseif ($line -match '^Time:\s+([^\s]+\s+[^\s]+).*Process:\s+([^\s]+)') {
            $result.Add("Time: $($Matches[1]) Process: $($Matches[2])")
        }
        elseif ($line -match '^\$stop called at time\s*:\s*([^\s]+\s+[^\s]+)') {
            $result.Add("STOP_TIME=$($Matches[1])")
        }
    }
    return $result
}

function Get-NormalizedVcdSha256 {
    param([Parameter(Mandatory = $true)][string]$VcdPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $reader = [System.IO.StreamReader]::new($VcdPath, [System.Text.Encoding]::ASCII)
    $skipDate = $false
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line.Trim() -eq '$date') {
                $skipDate = $true
                continue
            }
            if ($skipDate) {
                if ($line.Trim() -eq '$end') {
                    $skipDate = $false
                }
                continue
            }
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($line + "`n")
            [void]$sha.TransformBlock($bytes, 0, $bytes.Length, $null, 0)
        }
        [void]$sha.TransformFinalBlock([byte[]]::new(0), 0, 0)
        return [Convert]::ToHexString($sha.Hash)
    }
    finally {
        $reader.Dispose()
        $sha.Dispose()
    }
}

foreach ($required in @($ReferenceRoot, $CandidateRoot, $EvidenceRoot, $Xvhdl, $Xelab, $Xsim)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "required path missing: $required"
    }
}

$actualReferenceCommit = (git -C $ReferenceRoot rev-parse HEAD).Trim()
$actualReferenceTree = (git -C $ReferenceRoot rev-parse 'HEAD^{tree}').Trim()
$referenceStatus = (git -C $ReferenceRoot status --porcelain --untracked-files=all) -join "`n"
$actualCandidateParent = (git -C $CandidateRoot rev-parse HEAD).Trim()
$candidateDiffNames = @(git -C $CandidateRoot diff --name-only)
if ($actualReferenceCommit -ne $ExactR1fCommit -or $actualReferenceTree -ne $ExactR1fTree -or $referenceStatus -ne '') {
    throw 'exact clean R1f reference identity is not present'
}
if ($actualCandidateParent -ne $ExactR1fCommit -or $candidateDiffNames.Count -ne 1 -or
    $candidateDiffNames[0] -ne 'rtl/nvp/nvp6134c_i2c_bringup.vhd') {
    throw 'candidate is not the exact one-file R1g rewrite over R1f'
}

$testDefinitions = @{
    autoinit = @{
        Top = 'tb_g0p8c5d_autoinit'
        Tb = 'tests/nvp/tb_nvp_autoinit.vhd'
        Design = @(
            'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
            'rtl/nvp/r1f_transaction_serial_counter.vhd',
            'rtl/nvp/nvp6134c_i2c_bringup.vhd')
        Expected = @(
            'PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION',
            'PASS LEGACY_FIRST8_RECONCILIATION',
            'PASS exact 13-event historical pattern',
            'PASS exact 15-event historical pattern',
            'PASS exact 36-event historical pattern',
            'PASS one isolated WADDR NACK',
            'PASS one isolated REGADDR NACK',
            'PASS one isolated DATA NACK',
            'PASS one isolated RADDR NACK',
            'PASS operation-86-like transitional bank context')
    }
    d2b = @{
        Top = 'tb_nvp_d2b_sequence'
        Tb = 'tests/nvp/tb_nvp_d2b_sequence.vhd'
        Design = @(
            'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
            'rtl/nvp/r1f_transaction_serial_counter.vhd',
            'rtl/nvp/nvp6134c_i2c_bringup.vhd')
        Expected = @('PASS D2b full sequence is D1 + Z5-ALT with operations 1..148 disabled')
    }
    power = @{
        Top = 'tb_g0p8c5d_power_timing'
        Tb = 'tests/nvp/tb_power_timing.vhd'
        Design = @(
            'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
            'rtl/nvp/r1f_transaction_serial_counter.vhd',
            'rtl/nvp/nvp6134c_i2c_bringup.vhd',
            'rtl/nvp/nvp6134c_autoinit.vhd')
        Expected = @('PASS power enable, 500-ms reset hold, 1.5-s start scaling')
    }
    serial = @{
        Top = 'tb_r1f_transaction_serial_counter'
        Tb = 'tests/v41/tb_r1f_transaction_serial_counter.vhd'
        Design = @('rtl/nvp/r1f_transaction_serial_counter.vhd')
        Expected = @('PASS TRANSACTION_INDEX_16_UNIQUE_AT_300', 'PASS R1F_TRANSACTION_SERIAL_CLEAR')
    }
    preinit = @{
        Top = 'tb_r1f_preinit_equivalence'
        Tb = 'tests/v41/tb_r1f_preinit_equivalence.vhd'
        Design = @(
            'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
            'rtl/nvp/r1f_transaction_serial_counter.vhd',
            'rtl/nvp/nvp6134c_i2c_bringup.vhd',
            'rtl/nvp/nvp6134c_autoinit.vhd')
        Expected = @(
            'PASS PRE_INIT_DONE_CYCLE_EQUIVALENCE',
            'PASS AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL',
            'PASS AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL')
    }
}

$definition = $testDefinitions[$TestKey]
$attempt = 1
do {
    $pairRoot = Join-Path $EvidenceRoot ("vhdl_pair_{0}_attempt_{1:D2}" -f $TestKey, $attempt)
    $attempt++
} while (Test-Path -LiteralPath $pairRoot)
[void](New-Item -ItemType Directory -Path $pairRoot)

$identityLines = @(
    "TEST_KEY=$TestKey",
    "REFERENCE_COMMIT=$actualReferenceCommit",
    "REFERENCE_TREE=$actualReferenceTree",
    "CANDIDATE_PARENT=$actualCandidateParent",
    "CANDIDATE_DIFF_FILE=$($candidateDiffNames[0])",
    "REFERENCE_LANGUAGE_MODE=XVHDL_EXPLICIT_2008_ACCEPTED_R1F_MODE",
    "CANDIDATE_DESIGN_LANGUAGE_MODE=XVHDL_DEFAULT_NON_2008",
    "TESTBENCH_LANGUAGE_MODE=XVHDL_EXPLICIT_2008",
    "TOP=$($definition.Top)",
    "VCD_CAPTURE=$($CaptureVcd.IsPresent)"
)
[System.IO.File]::WriteAllLines(
    (Join-Path $pairRoot 'PAIR_IDENTITY.txt'),
    $identityLines,
    [System.Text.UTF8Encoding]::new($false))

foreach ($variant in @('reference', 'candidate')) {
    $sourceRoot = if ($variant -eq 'reference') { $ReferenceRoot } else { $CandidateRoot }
    $variantRoot = Join-Path $pairRoot $variant
    [void](New-Item -ItemType Directory -Path $variantRoot)

    $designIndex = 0
    foreach ($relativeDesign in $definition.Design) {
        $designPath = Join-Path $sourceRoot $relativeDesign
        $arguments = [System.Collections.Generic.List[string]]::new()
        if ($variant -eq 'reference') {
            $arguments.Add('--2008')
        }
        $arguments.Add('--work')
        $arguments.Add('work')
        $arguments.Add($designPath)
        Invoke-CapturedTool -Tool $Xvhdl -Arguments $arguments.ToArray() `
            -WorkingDirectory $variantRoot `
            -LogStem (Join-Path $variantRoot ("{0:D2}_xvhdl_design" -f $designIndex))
        $designIndex++
    }

    if ($TestKey -eq 'preinit') {
        $r1eRaw = 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\02_CURRENT_SEMANTICS_AUDIT\raw_r1e_source'
        foreach ($r1eFile in @('nvp6134c_diagnostics_pkg.vhd', 'nvp6134c_i2c_bringup.vhd', 'nvp6134c_autoinit.vhd')) {
            Invoke-CapturedTool -Tool $Xvhdl `
                -Arguments @('--work', 'r1e_ref', (Join-Path $r1eRaw $r1eFile)) `
                -WorkingDirectory $variantRoot `
                -LogStem (Join-Path $variantRoot ("r1e_ref_{0}" -f [System.IO.Path]::GetFileNameWithoutExtension($r1eFile)))
        }
    }

    Invoke-CapturedTool -Tool $Xvhdl `
        -Arguments @('--2008', '--work', 'work', (Join-Path $sourceRoot $definition.Tb)) `
        -WorkingDirectory $variantRoot `
        -LogStem (Join-Path $variantRoot 'xvhdl_tb')

    $snapshot = "${variant}_${TestKey}_snapshot"
    Invoke-CapturedTool -Tool $Xelab `
        -Arguments @($definition.Top, '-debug', 'typical', '-s', $snapshot) `
        -WorkingDirectory $variantRoot `
        -LogStem (Join-Path $variantRoot 'xelab')

    $tclLines = [System.Collections.Generic.List[string]]::new()
    if ($CaptureVcd) {
        $vcdPath = (Join-Path $variantRoot 'top_observables.vcd').Replace('\', '/')
        $tclLines.Add("open_vcd {$vcdPath}")
        $tclLines.Add("log_vcd [get_objects /$($definition.Top)/*]")
    }
    $tclLines.Add('run all')
    if ($CaptureVcd) {
        $tclLines.Add('close_vcd')
    }
    $tclLines.Add('quit')
    $tclPath = Join-Path $variantRoot 'run.tcl'
    [System.IO.File]::WriteAllLines($tclPath, $tclLines, [System.Text.UTF8Encoding]::new($false))

    Invoke-CapturedTool -Tool $Xsim `
        -Arguments @($snapshot, '-tclbatch', $tclPath.Replace('\', '/')) `
        -WorkingDirectory $variantRoot `
        -LogStem (Join-Path $variantRoot 'xsim')

    $xsimLog = Join-Path $variantRoot 'xsim.log'
    $xsimText = [System.IO.File]::ReadAllText($xsimLog)
    foreach ($marker in $definition.Expected) {
        if (-not $xsimText.Contains($marker)) {
            throw "$variant $TestKey missing required marker: $marker"
        }
    }
    if ($xsimText -match '(?im)^Error:|^Fatal:|Assertion violation|severity failure') {
        throw "$variant $TestKey contains a failure diagnostic"
    }
    $normalized = @(Get-NormalizedTranscript -LogPath $xsimLog)
    [System.IO.File]::WriteAllLines(
        (Join-Path $variantRoot 'xsim.normalized.txt'),
        $normalized,
        [System.Text.UTF8Encoding]::new($false))
}

$referenceTranscript = Join-Path $pairRoot 'reference\xsim.normalized.txt'
$candidateTranscript = Join-Path $pairRoot 'candidate\xsim.normalized.txt'
$transcriptDifference = @(Compare-Object `
    ([System.IO.File]::ReadAllLines($referenceTranscript)) `
    ([System.IO.File]::ReadAllLines($candidateTranscript)) -SyncWindow 0)
if ($transcriptDifference.Count -ne 0) {
    $transcriptDifference | Out-String | Set-Content -LiteralPath (Join-Path $pairRoot 'TRANSCRIPT_DIFFERENCE.txt')
    throw "$TestKey normalized reference/candidate transcripts differ"
}

$resultLines = [System.Collections.Generic.List[string]]::new()
$resultLines.Add("TEST_KEY=$TestKey")
$resultLines.Add('REFERENCE_SIMULATION=PASS')
$resultLines.Add('CANDIDATE_SIMULATION=PASS')
$resultLines.Add('NORMALIZED_TRANSCRIPT_EQUAL=YES')
$resultLines.Add("NORMALIZED_TRANSCRIPT_SHA256=$((Get-FileHash -LiteralPath $referenceTranscript -Algorithm SHA256).Hash)")
if ($CaptureVcd) {
    $referenceVcd = Join-Path $pairRoot 'reference\top_observables.vcd'
    $candidateVcd = Join-Path $pairRoot 'candidate\top_observables.vcd'
    $referenceVcdHash = Get-NormalizedVcdSha256 -VcdPath $referenceVcd
    $candidateVcdHash = Get-NormalizedVcdSha256 -VcdPath $candidateVcd
    $resultLines.Add("REFERENCE_VCD_BYTES=$((Get-Item -LiteralPath $referenceVcd).Length)")
    $resultLines.Add("CANDIDATE_VCD_BYTES=$((Get-Item -LiteralPath $candidateVcd).Length)")
    $resultLines.Add("REFERENCE_NORMALIZED_VCD_SHA256=$referenceVcdHash")
    $resultLines.Add("CANDIDATE_NORMALIZED_VCD_SHA256=$candidateVcdHash")
    $resultLines.Add("CYCLE_BY_CYCLE_TOP_OBSERVABLE_VCD_EQUAL=$(if ($referenceVcdHash -eq $candidateVcdHash) { 'YES' } else { 'NO' })")
    if ($referenceVcdHash -ne $candidateVcdHash) {
        throw "$TestKey normalized observable VCD differs"
    }
}
$resultLines.Add('PAIR_RESULT=PASS_EXACT_CROSS_STANDARD_EQUIVALENCE')
[System.IO.File]::WriteAllLines(
    (Join-Path $pairRoot 'PAIR_RESULT.txt'),
    $resultLines,
    [System.Text.UTF8Encoding]::new($false))

Write-Output "PAIR_RESULT=PASS_EXACT_CROSS_STANDARD_EQUIVALENCE"
Write-Output "TEST_KEY=$TestKey"
