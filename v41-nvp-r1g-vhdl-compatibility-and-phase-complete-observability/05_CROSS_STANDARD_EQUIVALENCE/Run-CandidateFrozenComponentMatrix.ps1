param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ReferenceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY'
$CandidateRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
$EvidenceRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\05_CROSS_STANDARD_EQUIVALENCE'
$ToolRoot = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$Xvlog = Join-Path $ToolRoot 'xvlog.bat'
$Xelab = Join-Path $ToolRoot 'xelab.bat'
$Xsim = Join-Path $ToolRoot 'xsim.bat'
$Python = 'C:\AMDDesignTools\2025.2\tps\win64\python-3.13.0\python.exe'

$ExactR1fCommit = '225544084dbfcaadb8592fcecc947aa1cec4970e'
$ExactR1fTree = 'cfde8769af95cf20586391c411fab3ddfa2c87b6'
$ExactCandidateBringupSha256 = '66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024'

function Invoke-CapturedTool {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogStem
    )

    $record = [System.Collections.Generic.List[string]]::new()
    $record.Add("TOOL=$Tool")
    $record.Add("WORKING_DIRECTORY=$WorkingDirectory")
    $record.Add("ARGUMENT_COUNT=$($Arguments.Count)")
    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        $record.Add("ARG_$index=$($Arguments[$index])")
    }
    [System.IO.File]::WriteAllLines(
        "$LogStem.command.txt", $record, [System.Text.UTF8Encoding]::new($false))

    Push-Location -LiteralPath $WorkingDirectory
    try {
        $output = @(& $Tool @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    [System.IO.File]::WriteAllLines(
        "$LogStem.log",
        @($output | ForEach-Object { $_.ToString() }),
        [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText(
        "$LogStem.exit.txt", "PROCESS_EXIT_CODE=$exitCode`n", [System.Text.UTF8Encoding]::new($false))
    if ($exitCode -ne 0) {
        throw "tool failed with exit ${exitCode}: $Tool (see $LogStem.log)"
    }
}

function Invoke-SystemVerilogCase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$Sources,
        [Parameter(Mandatory = $true)][string]$Top,
        [Parameter(Mandatory = $true)][string[]]$RequiredMarkers,
        [Parameter(Mandatory = $true)][string]$AttemptRoot
    )

    $caseRoot = Join-Path $AttemptRoot $Name
    [void](New-Item -ItemType Directory -Path $caseRoot)
    $arguments = [System.Collections.Generic.List[string]]::new()
    $arguments.Add('--sv')
    $arguments.Add('--work')
    $arguments.Add('work')
    foreach ($source in $Sources) {
        $arguments.Add((Join-Path $CandidateRoot $source))
    }
    Invoke-CapturedTool -Tool $Xvlog -Arguments $arguments.ToArray() `
        -WorkingDirectory $caseRoot -LogStem (Join-Path $caseRoot 'xvlog')

    $snapshot = "candidate_${Name}_snapshot"
    Invoke-CapturedTool -Tool $Xelab -Arguments @($Top, '-debug', 'typical', '-s', $snapshot) `
        -WorkingDirectory $caseRoot -LogStem (Join-Path $caseRoot 'xelab')

    $runTcl = Join-Path $caseRoot 'run.tcl'
    [System.IO.File]::WriteAllLines(
        $runTcl, @('run all', 'quit'), [System.Text.UTF8Encoding]::new($false))
    Invoke-CapturedTool -Tool $Xsim `
        -Arguments @($snapshot, '-tclbatch', $runTcl.Replace('\', '/')) `
        -WorkingDirectory $caseRoot -LogStem (Join-Path $caseRoot 'xsim')

    $logText = [System.IO.File]::ReadAllText((Join-Path $caseRoot 'xsim.log'))
    foreach ($marker in $RequiredMarkers) {
        if (-not $logText.Contains($marker)) {
            throw "$Name missing required marker: $marker"
        }
    }
    if ($logText -match '(?im)^Error:|^Fatal:|Assertion violation|severity failure') {
        throw "$Name contains a failure diagnostic"
    }
    $logSha = (Get-FileHash -LiteralPath (Join-Path $caseRoot 'xsim.log') -Algorithm SHA256).Hash
    [System.IO.File]::WriteAllLines(
        (Join-Path $caseRoot 'RESULT.txt'),
        @(
            "CASE=$Name"
            'CANDIDATE_SIMULATION=PASS'
            "TOP=$Top"
            "XSIM_LOG_SHA256=$logSha"
            'PROCESS_EXIT_CODE=0'
        ),
        [System.Text.UTF8Encoding]::new($false))
}

foreach ($required in @($ReferenceRoot, $CandidateRoot, $EvidenceRoot, $Xvlog, $Xelab, $Xsim, $Python)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "required path missing: $required"
    }
}

$referenceCommit = (git -C $ReferenceRoot rev-parse HEAD).Trim()
$referenceTree = (git -C $ReferenceRoot rev-parse 'HEAD^{tree}').Trim()
$referenceStatus = (git -C $ReferenceRoot status --porcelain --untracked-files=all) -join "`n"
$candidateParent = (git -C $CandidateRoot rev-parse HEAD).Trim()
$candidateDiffNames = @(git -C $CandidateRoot diff --name-only)
$candidateBringupHash = (Get-FileHash -LiteralPath `
    (Join-Path $CandidateRoot 'rtl\nvp\nvp6134c_i2c_bringup.vhd') -Algorithm SHA256).Hash
if ($referenceCommit -ne $ExactR1fCommit -or $referenceTree -ne $ExactR1fTree -or $referenceStatus -ne '') {
    throw 'exact clean R1f reference identity is not present'
}
if ($candidateParent -ne $ExactR1fCommit -or $candidateDiffNames.Count -ne 1 -or
    $candidateDiffNames[0] -ne 'rtl/nvp/nvp6134c_i2c_bringup.vhd' -or
    $candidateBringupHash -ne $ExactCandidateBringupSha256) {
    throw 'candidate is not the hash-bound one-file R1g rewrite over exact R1f'
}

$attemptNumber = 1
do {
    $attemptRoot = Join-Path $EvidenceRoot ("candidate_frozen_component_matrix_attempt_{0:D2}" -f $attemptNumber)
    $attemptNumber++
} while (Test-Path -LiteralPath $attemptRoot)
[void](New-Item -ItemType Directory -Path $attemptRoot)

[System.IO.File]::WriteAllLines(
    (Join-Path $attemptRoot 'MATRIX_IDENTITY.txt'),
    @(
        "REFERENCE_COMMIT=$referenceCommit"
        "REFERENCE_TREE=$referenceTree"
        "CANDIDATE_PARENT=$candidateParent"
        "CANDIDATE_DIFF_FILE=$($candidateDiffNames[0])"
        "CANDIDATE_BRINGUP_SHA256=$candidateBringupHash"
        'EXECUTION_CLASS=OFFLINE_ONLY'
        'SYNTH_DESIGN_INVOKED=NO'
        'SHARED_COMPONENT_SOURCES_EXPECTED_BYTE_IDENTICAL=YES'
    ),
    [System.Text.UTF8Encoding]::new($false))

$sharedSources = @(
    'rtl/v41/r1f_failed_txn_logger.sv',
    'rtl/v41/r1f_measurement_regs.sv',
    'rtl/v41/nvp_i2c_tri_phase_probe.sv',
    'tests/v41/tb_r1f_failed_txn_logger.sv',
    'tests/v41/tb_r1f_measurement_regs.sv',
    'tests/v41/tb_r1f_preinit_arbitration.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_idle_timeout.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_production_timing.sv',
    'scripts/v41/read_nvp_r1f.py',
    'scripts/v41/r1f_statistics.py',
    'tests/python/test_nvp_r1f_tools.py',
    'tests/python/test_nvp_r1f_tri_phase_probe_model.py'
)
$sourceIdentity = [System.Collections.Generic.List[string]]::new()
$sourceIdentity.Add('relative_path,reference_sha256,candidate_sha256,byte_identical')
foreach ($relativePath in $sharedSources) {
    $referencePath = Join-Path $ReferenceRoot $relativePath
    $candidatePath = Join-Path $CandidateRoot $relativePath
    if (-not (Test-Path -LiteralPath $referencePath) -or -not (Test-Path -LiteralPath $candidatePath)) {
        throw "shared source missing: $relativePath"
    }
    $referenceSha = (Get-FileHash -LiteralPath $referencePath -Algorithm SHA256).Hash
    $candidateSha = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash
    if ($referenceSha -ne $candidateSha) {
        throw "shared source differs between R1f and R1g: $relativePath"
    }
    $sourceIdentity.Add(('"{0}",{1},{2},YES' -f $relativePath, $referenceSha, $candidateSha))
}
[System.IO.File]::WriteAllLines(
    (Join-Path $attemptRoot 'SHARED_SOURCE_IDENTITY.csv'),
    $sourceIdentity,
    [System.Text.UTF8Encoding]::new($false))

Invoke-SystemVerilogCase -Name 'preinit_effective_arbitration' -AttemptRoot $attemptRoot `
    -Sources @('rtl/v41/nvp_i2c_tri_phase_probe.sv', 'tests/v41/tb_r1f_preinit_arbitration.sv') `
    -Top 'tb_r1f_preinit_arbitration' `
    -RequiredMarkers @('PASS R1F_PRE_INIT_EFFECTIVE_OPEN_DRAIN_ARBITRATION')

Invoke-SystemVerilogCase -Name 'failed_txn_logger_64_65' -AttemptRoot $attemptRoot `
    -Sources @('rtl/v41/r1f_failed_txn_logger.sv', 'tests/v41/tb_r1f_failed_txn_logger.sv') `
    -Top 'tb_r1f_failed_txn_logger' `
    -RequiredMarkers @(
        'R1F_FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS',
        'R1F_LOG_64_EXACT_OVERFLOW_65=PASS',
        'R1F_LOG_UNUSED_ZERO_IMMUTABLE=PASS')

Invoke-SystemVerilogCase -Name 'measurement_map_formal_zero' -AttemptRoot $attemptRoot `
    -Sources @('rtl/v41/r1f_measurement_regs.sv', 'tests/v41/tb_r1f_measurement_regs.sv') `
    -Top 'tb_r1f_measurement_regs' `
    -RequiredMarkers @(
        'R1F_REGISTER_MAP_DECODE=PASS',
        'R1F_RECORD_RANGE_LAST_WORD_0X29FC=PASS',
        'R1F_INDEX_LOG_512_PER_PHASE=PASS',
        'FORMAL_R1F_RANGE_ZERO_FIXTURE=PASS_ALL_1368_DWORDS')

$probeCases = @(
    @{ Name = 'tri_probe_main'; Tb = 'tb_nvp_i2c_tri_phase_probe.sv'; Top = 'tb_nvp_i2c_tri_phase_probe'; Marker = 'TRI_PHASE_PROBE_RTL_PASS' },
    @{ Name = 'tri_probe_abort_restore'; Tb = 'tb_nvp_i2c_tri_phase_probe_abort_restore.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_abort_restore'; Marker = 'TRI_PHASE_PROBE_ABORT_RESTORE_PASS' },
    @{ Name = 'tri_probe_timeout'; Tb = 'tb_nvp_i2c_tri_phase_probe_timeout.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_timeout'; Marker = 'TRI_PHASE_PROBE_TIMEOUT_PASS' },
    @{ Name = 'tri_probe_attempt_limit'; Tb = 'tb_nvp_i2c_tri_phase_probe_attempt_limit.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_attempt_limit'; Marker = 'TRI_PHASE_PROBE_ATTEMPT_LIMIT_PASS' },
    @{ Name = 'tri_probe_secondary_restore_failure'; Tb = 'tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_secondary_restore_failure'; Marker = 'TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE_PASS' },
    @{ Name = 'tri_probe_index_overflow'; Tb = 'tb_nvp_i2c_tri_phase_probe_index_overflow.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_index_overflow'; Marker = 'TRI_PHASE_PROBE_INDEX_OVERFLOW_PASS' },
    @{ Name = 'tri_probe_idle_timeout'; Tb = 'tb_nvp_i2c_tri_phase_probe_idle_timeout.sv'; Top = 'tb_nvp_i2c_tri_phase_probe_idle_timeout'; Marker = 'TRI_PHASE_PROBE_IDLE_TIMEOUT_COMPAT_PASS' }
)
foreach ($probeCase in $probeCases) {
    Invoke-SystemVerilogCase -Name $probeCase.Name -AttemptRoot $attemptRoot `
        -Sources @('rtl/v41/nvp_i2c_tri_phase_probe.sv', "tests/v41/$($probeCase.Tb)") `
        -Top $probeCase.Top -RequiredMarkers @($probeCase.Marker)
}

Invoke-SystemVerilogCase -Name 'tri_probe_production_timing' -AttemptRoot $attemptRoot `
    -Sources @(
        'rtl/v41/nvp_i2c_tri_phase_probe.sv',
        'tests/v41/tb_nvp_i2c_tri_phase_probe.sv',
        'tests/v41/tb_nvp_i2c_tri_phase_probe_production_timing.sv') `
    -Top 'tb_nvp_i2c_tri_phase_probe_production_timing' `
    -RequiredMarkers @(
        'PASS R1F_PRODUCTION_TIMING_MODEL',
        'R1F_PROBE_CYCLES_FROM_INIT_DONE=29415318',
        'R1F_PROBE_SECONDS_FROM_INIT_DONE=29.415318000',
        'MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION=31.536673744',
        'ARM_A_REQUIRED_WAIT_SECONDS=33.536673744')

$hostRoot = Join-Path $attemptRoot 'host_tool_fixtures'
[void](New-Item -ItemType Directory -Path $hostRoot)
Invoke-CapturedTool -Tool $Python `
    -Arguments @('-B', '-m', 'unittest', 'discover', '-s', 'tests/python', '-p', 'test_nvp_r1f*.py', '-v') `
    -WorkingDirectory $CandidateRoot -LogStem (Join-Path $hostRoot 'python_unittest')
$hostText = [System.IO.File]::ReadAllText((Join-Path $hostRoot 'python_unittest.log'))
if ($hostText -notmatch 'Ran 24 tests' -or $hostText -notmatch '(?m)^OK\s*$' -or
    $hostText -match '(?m)^FAILED \(') {
    throw 'host fixture suite did not pass exactly 24/24'
}
[System.IO.File]::WriteAllLines(
    (Join-Path $hostRoot 'RESULT.txt'),
    @(
        'TESTS_RUN=24'
        'TESTS_PASSED=24'
        'TESTS_FAILED=0'
        'TESTS_ERRORED=0'
        'HOST_TOOL_FIXTURES=PASS_ALL'
        "LOG_SHA256=$((Get-FileHash -LiteralPath (Join-Path $hostRoot 'python_unittest.log') -Algorithm SHA256).Hash)"
    ),
    [System.Text.UTF8Encoding]::new($false))

$results = @(Get-ChildItem -LiteralPath $attemptRoot -Recurse -Filter 'RESULT.txt' | Sort-Object FullName)
$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add('MATRIX_RESULT=PASS_ALL')
$summary.Add("SYSTEMVERILOG_CASES_PASS=$($results.Count - 1)")
$summary.Add('HOST_TOOL_FIXTURES=PASS_24_OF_24')
$summary.Add('REFERENCE_AND_CANDIDATE_SHARED_COMPONENT_FILES_BYTE_IDENTICAL=YES')
$summary.Add("CANDIDATE_BRINGUP_SHA256=$candidateBringupHash")
foreach ($result in $results) {
    $summary.Add("RESULT_FILE=$($result.FullName.Substring($attemptRoot.Length + 1).Replace('\', '/'))")
    $summary.Add("RESULT_SHA256=$((Get-FileHash -LiteralPath $result.FullName -Algorithm SHA256).Hash)")
}
[System.IO.File]::WriteAllLines(
    (Join-Path $attemptRoot 'MATRIX_RESULT.txt'),
    $summary,
    [System.Text.UTF8Encoding]::new($false))

Write-Output 'MATRIX_RESULT=PASS_ALL'
Write-Output "ATTEMPT_ROOT=$attemptRoot"
