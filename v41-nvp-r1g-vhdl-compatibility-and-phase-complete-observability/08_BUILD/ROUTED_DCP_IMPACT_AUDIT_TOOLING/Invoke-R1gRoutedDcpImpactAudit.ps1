[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$R1gDcpPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedR1gDcpSha256,

    [Parameter(Mandatory = $true)]
    [string]$R1gBuildPassReceiptPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$ExpectedR1gSourceCommit,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$ExpectedR1gSourceTree,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$R1eDcpPath =
        'C:\FPGA\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1\07_BUILD\reports\PHASE3_routed.dcp',

    [string]$VivadoBatchPath =
        'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedR1eDcpSha256 =
    '1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1'
$ExpectedR1eDcpSizeBytes = 48609481L
$ExpectedTask =
    'V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY'
$ExpectedBranch = 'diag/v41-nvp-r1g-vhdl-compatibility'
$ExpectedPart = 'xc7a35tcsg325-2'
$ExpectedTop = 'ahd_capture_top_xdma'
$AllowedOutputRoot =
    [System.IO.Path]::GetFullPath('C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\08_BUILD')
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Resolve-RequiredFile {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $fullPath = [System.IO.Path]::GetFullPath($LiteralPath)
    if (-not [System.IO.File]::Exists($fullPath)) {
        throw "Required file is absent: $fullPath"
    }
    return $fullPath
}

function Get-ExactSha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Read-StrictKeyValueReceipt {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $result = [ordered]@{}
    foreach ($line in [System.IO.File]::ReadAllLines($LiteralPath)) {
        $trimmed = $line.Trim()
        if (($trimmed.Length -eq 0) -or $trimmed.StartsWith('#')) {
            continue
        }
        $separator = $trimmed.IndexOf('=')
        if ($separator -le 0) {
            continue
        }
        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim()
        if ($result.Contains($key)) {
            throw "Duplicate receipt key is forbidden: $key"
        }
        $result[$key] = $value
    }
    return $result
}

function Require-ReceiptValue {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Receipt,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    if (-not $Receipt.Contains($Key)) {
        throw "Build-pass receipt is missing required key: $Key"
    }
    if ($Receipt[$Key] -cne $Expected) {
        throw "Build-pass receipt mismatch for $Key; expected '$Expected', got '$($Receipt[$Key])'"
    }
}

function Require-ReceiptNumber {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Receipt,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][ValidateSet('GeZero', 'GtZero')][string]$Rule
    )

    if (-not $Receipt.Contains($Key)) {
        throw "Build-pass receipt is missing required numeric key: $Key"
    }
    $number = 0.0
    if (-not [double]::TryParse(
            $Receipt[$Key],
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$number)) {
        throw "Build-pass receipt value for $Key is not an invariant numeric value"
    }
    if (($Rule -eq 'GeZero') -and ($number -lt 0.0)) {
        throw "Build-pass receipt requires $Key >= 0; got $number"
    }
    if (($Rule -eq 'GtZero') -and ($number -le 0.0)) {
        throw "Build-pass receipt requires $Key > 0; got $number"
    }
}

function Write-Utf8Lines {
    param(
        [Parameter(Mandatory = $true)][string]$LiteralPath,
        [Parameter(Mandatory = $true)][string[]]$Lines
    )

    [System.IO.File]::WriteAllLines($LiteralPath, $Lines, $Utf8NoBom)
}

$r1eDcp = Resolve-RequiredFile -LiteralPath $R1eDcpPath
$r1gDcp = Resolve-RequiredFile -LiteralPath $R1gDcpPath
$buildReceiptPath = Resolve-RequiredFile -LiteralPath $R1gBuildPassReceiptPath
$vivado = Resolve-RequiredFile -LiteralPath $VivadoBatchPath
$tcl = Resolve-RequiredFile -LiteralPath (
    Join-Path $PSScriptRoot 'r1g_routed_dcp_impact_audit.tcl')

if ($r1eDcp -ceq $r1gDcp) {
    throw 'R1e and R1g checkpoint paths must be distinct'
}

$r1eInfo = Get-Item -LiteralPath $r1eDcp
if ($r1eInfo.Length -ne $ExpectedR1eDcpSizeBytes) {
    throw "Exact R1e checkpoint size mismatch: expected $ExpectedR1eDcpSizeBytes, got $($r1eInfo.Length)"
}
$r1eSha = Get-ExactSha256 -LiteralPath $r1eDcp
if ($r1eSha -cne $ExpectedR1eDcpSha256) {
    throw "Exact R1e checkpoint SHA-256 mismatch: expected $ExpectedR1eDcpSha256, got $r1eSha"
}

$r1gSha = Get-ExactSha256 -LiteralPath $r1gDcp
$ExpectedR1gDcpSha256 = $ExpectedR1gDcpSha256.ToUpperInvariant()
if ($r1gSha -cne $ExpectedR1gDcpSha256) {
    throw "R1g checkpoint SHA-256 mismatch: expected $ExpectedR1gDcpSha256, got $r1gSha"
}

$receipt = Read-StrictKeyValueReceipt -LiteralPath $buildReceiptPath
$ExpectedR1gSourceCommit = $ExpectedR1gSourceCommit.ToLowerInvariant()
$ExpectedR1gSourceTree = $ExpectedR1gSourceTree.ToLowerInvariant()

Require-ReceiptValue $receipt 'TASK' $ExpectedTask
Require-ReceiptValue $receipt 'FULL_BUILDS' '1'
Require-ReceiptValue $receipt 'SOURCE_GIT_COMMIT' $ExpectedR1gSourceCommit
Require-ReceiptValue $receipt 'SOURCE_GIT_TREE' $ExpectedR1gSourceTree
Require-ReceiptValue $receipt 'SOURCE_BRANCH' $ExpectedBranch
Require-ReceiptValue $receipt 'VIVADO_VERSION' '2025.2'
Require-ReceiptValue $receipt 'VIVADO_SW_BUILD' '6299465'
Require-ReceiptValue $receipt 'PART' $ExpectedPart
Require-ReceiptValue $receipt 'TOP' $ExpectedTop
Require-ReceiptValue $receipt 'PROJECT_CREATION' 'PASS'
Require-ReceiptValue $receipt 'SYNTHESIS' 'PASS'
Require-ReceiptValue $receipt 'PLACE' 'PASS'
Require-ReceiptValue $receipt 'ROUTE' 'PASS'
Require-ReceiptValue $receipt 'ROUTE_ERRORS' '0'
Require-ReceiptNumber $receipt 'WNS' 'GeZero'
Require-ReceiptNumber $receipt 'WHS' 'GtZero'
Require-ReceiptNumber $receipt 'VDO_WNS' 'GtZero'
Require-ReceiptNumber $receipt 'VDO_WHS' 'GtZero'
Require-ReceiptValue $receipt 'DRC_ERRORS' '0'
Require-ReceiptValue $receipt 'DRC_CRITICAL_WARNINGS' '0'
Require-ReceiptValue $receipt 'REQP_1839_SEMANTIC_COUNT' '4'
Require-ReceiptValue $receipt 'CDC_CRITICAL' '0'
Require-ReceiptValue $receipt 'CDC_UNKNOWN' '0'
Require-ReceiptValue $receipt 'PREBUILD_MANIFEST_BINDING' 'PASS'
Require-ReceiptValue $receipt 'SOURCE_COMMIT_TO_BIT_PROVENANCE' 'PASS'
Require-ReceiptValue $receipt 'BITSTREAM_GENERATED' 'YES'
Require-ReceiptValue $receipt 'R1G_IMPLEMENTATION_GATE' 'PASS'

if (-not $receipt.Contains('R1G_ROUTED_DCP')) {
    throw 'Build-pass receipt is missing R1G_ROUTED_DCP'
}
$receiptDcp = [System.IO.Path]::GetFullPath($receipt['R1G_ROUTED_DCP'])
if ($receiptDcp -cne $r1gDcp) {
    throw "Build-pass receipt checkpoint path mismatch: '$receiptDcp' versus '$r1gDcp'"
}

if (-not $receipt.Contains('BITSTREAM')) {
    throw 'Build-pass receipt is missing BITSTREAM'
}
$bitstream = Resolve-RequiredFile -LiteralPath $receipt['BITSTREAM']
if (-not $receipt.Contains('BITSTREAM_SHA256')) {
    throw 'Build-pass receipt is missing BITSTREAM_SHA256'
}
$bitSha = Get-ExactSha256 -LiteralPath $bitstream
if ($bitSha -cne $receipt['BITSTREAM_SHA256'].ToUpperInvariant()) {
    throw 'Build-pass receipt bitstream SHA-256 does not match the exact bitstream'
}

$terminalFailure = Join-Path -Path (Split-Path -Parent $buildReceiptPath) -ChildPath 'R1G_BUILD_TERMINAL_FAILURE.txt'
if ([System.IO.File]::Exists($terminalFailure)) {
    throw "A terminal build-failure receipt exists beside the claimed PASS receipt: $terminalFailure"
}

$tclText = [System.IO.File]::ReadAllText($tcl)
$forbiddenPattern = '(?im)^\s*(create_project|read_vhdl|read_verilog|read_xdc|add_files|synth_design|opt_design|power_opt_design|place_design|phys_opt_design|route_design|write_checkpoint|write_bitstream|write_cfgmem|write_device_image|set_property|reset_run|launch_runs|program_hw_devices|open_hw|connect_hw_server|open_hw_target)\b'
$forbiddenMatches = [regex]::Matches($tclText, $forbiddenPattern)
if ($forbiddenMatches.Count -ne 0) {
    throw 'Static no-mutation audit failed for routed-impact Tcl'
}
if ([regex]::Matches($tclText, '(?im)^\s*open_checkpoint\b').Count -ne 1) {
    throw 'Static audit requires exactly one open_checkpoint command site in the reusable audit procedure'
}
if ([regex]::Matches($tclText, '(?im)^\s*close_design\b').Count -lt 1) {
    throw 'Static audit requires an explicit close_design command site'
}

$output = [System.IO.Path]::GetFullPath($OutputDirectory)
$allowedPrefix = $AllowedOutputRoot.TrimEnd('\') + '\'
if (-not $output.StartsWith(
        $allowedPrefix,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Output directory must be a new child of $AllowedOutputRoot"
}
if ([System.IO.Directory]::Exists($output) -or [System.IO.File]::Exists($output)) {
    throw "Output target already exists; a fresh evidence directory is required: $output"
}
[System.IO.Directory]::CreateDirectory($output) | Out-Null

$buildReceiptSha = Get-ExactSha256 -LiteralPath $buildReceiptPath
$tclSha = Get-ExactSha256 -LiteralPath $tcl
$wrapperSha = Get-ExactSha256 -LiteralPath $PSCommandPath
Write-Utf8Lines -LiteralPath (Join-Path $output 'DCP_IDENTITY_AND_BUILD_PASS_GATE.txt') -Lines @(
    "TASK=$ExpectedTask",
    'GATE=PASS_BEFORE_READ_ONLY_VIVADO_QUERY',
    "R1E_DCP=$r1eDcp",
    "R1E_DCP_SIZE_BYTES=$($r1eInfo.Length)",
    "R1E_DCP_SHA256=$r1eSha",
    "R1E_DCP_IDENTITY=PASS_EXACT",
    "R1G_DCP=$r1gDcp",
    "R1G_DCP_SIZE_BYTES=$((Get-Item -LiteralPath $r1gDcp).Length)",
    "R1G_DCP_SHA256=$r1gSha",
    'R1G_DCP_IDENTITY=PASS_EXPECTED_POST_BUILD_SHA256',
    "R1G_BUILD_PASS_RECEIPT=$buildReceiptPath",
    "R1G_BUILD_PASS_RECEIPT_SHA256=$buildReceiptSha",
    'R1G_BUILD_PASS_RECEIPT_GATE=PASS_ALL_REQUIRED_FIELDS',
    "R1G_SOURCE_COMMIT=$ExpectedR1gSourceCommit",
    "R1G_SOURCE_TREE=$ExpectedR1gSourceTree",
    "R1G_BITSTREAM=$bitstream",
    "R1G_BITSTREAM_SHA256=$bitSha",
    "AUDIT_TCL_SHA256=$tclSha",
    "AUDIT_WRAPPER_SHA256=$wrapperSha",
    'STATIC_NO_MUTATION_AUDIT=PASS',
    'HARDWARE_ACTIONS=0',
    'NETWORK_ACTIONS=0'
)
[System.IO.File]::Copy(
    $buildReceiptPath,
    (Join-Path $output 'R1G_BUILD_PASS_RECEIPT_INPUT.txt'),
    $false)

$vivadoLog = Join-Path $output 'vivado_routed_dcp_impact_audit.log'
$vivadoJournal = Join-Path $output 'vivado_routed_dcp_impact_audit.jou'
$vivadoArguments = @(
    '-mode', 'batch',
    '-notrace',
    '-log', $vivadoLog,
    '-journal', $vivadoJournal,
    '-source', $tcl,
    '-tclargs', $r1eDcp, $r1gDcp, $output, $ExpectedPart
)

& $vivado @vivadoArguments
$vivadoExitCode = $LASTEXITCODE
if ($vivadoExitCode -ne 0) {
    Write-Utf8Lines -LiteralPath (
        Join-Path $output 'WRAPPER_TERMINAL_FAILURE.txt') -Lines @(
        'AUDIT_RESULT=FAIL_VIVADO_PROCESS',
        "PROCESS_EXIT_CODE=$vivadoExitCode",
        'RETRY_AUTHORIZED=NO',
        'PARTIAL_EVIDENCE_PRESERVED=YES'
    )
    throw "Read-only routed-checkpoint audit failed with exit code $vivadoExitCode"
}

$statusPath = Resolve-RequiredFile -LiteralPath (
    Join-Path $output 'R1G_ROUTED_DCP_IMPACT_AUDIT_STATUS.txt')
$status = Read-StrictKeyValueReceipt -LiteralPath $statusPath
Require-ReceiptValue $status 'AUDIT_RESULT' 'PASS_READ_ONLY_DCP_COMPARISON'
Require-ReceiptValue $status 'R1G_IMPLEMENTATION_DELTA' 'QUANTIFIED'
Require-ReceiptValue $status 'R1G_PLACEMENT_NEUTRAL' 'NOT_CLAIMED'
Require-ReceiptValue $status 'DESIGN_MUTATIONS' '0'
Require-ReceiptValue $status 'CHECKPOINT_WRITES' '0'

$r1eMetrics = Read-StrictKeyValueReceipt -LiteralPath (
    Resolve-RequiredFile -LiteralPath (Join-Path $output 'R1E_metrics.txt'))
$r1gMetrics = Read-StrictKeyValueReceipt -LiteralPath (
    Resolve-RequiredFile -LiteralPath (Join-Path $output 'R1G_metrics.txt'))
$metricKeys = @(
    (@($r1eMetrics.Keys) + @($r1gMetrics.Keys)) | Sort-Object -Unique
)
$metricComparison = [System.Collections.Generic.List[string]]::new()
$metricComparison.Add('METRIC,R1E,R1G,R1G_MINUS_R1E')
foreach ($key in $metricKeys) {
    if ($key -in @('LABEL', 'DCP')) {
        continue
    }
    $r1eValue = if ($r1eMetrics.Contains($key)) { $r1eMetrics[$key] } else { '' }
    $r1gValue = if ($r1gMetrics.Contains($key)) { $r1gMetrics[$key] } else { '' }
    $delta = ''
    $r1eNumber = 0.0
    $r1gNumber = 0.0
    $r1eNumeric = [double]::TryParse(
        $r1eValue,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$r1eNumber)
    $r1gNumeric = [double]::TryParse(
        $r1gValue,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$r1gNumber)
    if ($r1eNumeric -and $r1gNumeric) {
        $delta = ($r1gNumber - $r1eNumber).ToString(
            'R', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $metricComparison.Add("$key,$r1eValue,$r1gValue,$delta")
}
Write-Utf8Lines -LiteralPath (
    Join-Path $output 'R1E_VS_R1G_METRIC_COMPARISON.csv') -Lines $metricComparison

$hashComparison = [System.Collections.Generic.List[string]]::new()
$hashComparison.Add('ARTIFACT_SUFFIX,R1E_SHA256,R1G_SHA256,BYTE_IDENTICAL')
$r1eOutputs = Get-ChildItem -LiteralPath $output -File -Filter 'R1E_*'
foreach ($r1eOutput in $r1eOutputs) {
    $suffix = $r1eOutput.Name.Substring(4)
    $r1gOutputPath = Join-Path $output ('R1G_' + $suffix)
    if (-not [System.IO.File]::Exists($r1gOutputPath)) {
        continue
    }
    $leftHash = Get-ExactSha256 -LiteralPath $r1eOutput.FullName
    $rightHash = Get-ExactSha256 -LiteralPath $r1gOutputPath
    $identical = if ($leftHash -ceq $rightHash) { 'YES' } else { 'NO' }
    $hashComparison.Add("$suffix,$leftHash,$rightHash,$identical")
}
Write-Utf8Lines -LiteralPath (
    Join-Path $output 'R1E_VS_R1G_ARTIFACT_HASH_COMPARISON.csv') -Lines $hashComparison

Write-Utf8Lines -LiteralPath (
    Join-Path $output 'R1G_ROUTED_DCP_IMPACT_AUDIT_WRAPPER_STATUS.txt') -Lines @(
    'WRAPPER_RESULT=PASS',
    'PROCESS_EXIT_CODE=0',
    'R1G_IMPLEMENTATION_DELTA=QUANTIFIED',
    'R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED',
    'LANGUAGE_REWRITE_FUNCTIONAL_NETLIST_CONCLUSION=REQUIRES_SEPARATE_CROSS_STANDARD_EQUIVALENCE_RECEIPT',
    'READ_ONLY_POST_BUILD_DCP_QUERIES_RUN=2',
    'ADDITIONAL_BUILDS_RUN=0',
    'DESIGN_MUTATIONS=0',
    'CHECKPOINT_WRITES=0',
    'HARDWARE_ACTIONS=0',
    'NETWORK_ACTIONS=0'
)

$manifestLines = [System.Collections.Generic.List[string]]::new()
$manifestLines.Add('SHA256  SIZE_BYTES  RELATIVE_PATH')
foreach ($file in Get-ChildItem -LiteralPath $output -Recurse -File |
        Sort-Object FullName) {
    if ($file.Name -eq 'SHA256_MANIFEST.txt') {
        continue
    }
    $relative = [System.IO.Path]::GetRelativePath($output, $file.FullName).Replace('\', '/')
    $sha = Get-ExactSha256 -LiteralPath $file.FullName
    $manifestLines.Add("$sha  $($file.Length)  $relative")
}
Write-Utf8Lines -LiteralPath (Join-Path $output 'SHA256_MANIFEST.txt') -Lines $manifestLines

Write-Output 'AUDIT_RESULT=PASS_READ_ONLY_DCP_COMPARISON'
Write-Output 'R1G_IMPLEMENTATION_DELTA=QUANTIFIED'
Write-Output 'R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED'
