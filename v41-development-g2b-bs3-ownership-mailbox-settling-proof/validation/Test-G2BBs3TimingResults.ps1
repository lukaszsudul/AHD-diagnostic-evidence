[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ValidationDirectory,

    [Parameter(Mandatory)]
    [string]$ReceiptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$invariant = [Globalization.CultureInfo]::InvariantCulture

function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing result file: $Path" }
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) { $map[$parts[0]] = $parts[1] }
    }
    return $map
}

function Require-Value {
    param([hashtable]$Map, [string]$Key, [string]$Expected, [string]$Context)
    if (-not $Map.ContainsKey($Key) -or $Map[$Key] -ne $Expected) {
        throw "$Context $Key mismatch: actual=$($Map[$Key]) expected=$Expected"
    }
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('CHECK=G2B_BS3_FAIL_CLOSED_TIMING_RESULT_GATE')
$lines.Add("VALIDATION_DIRECTORY=$ValidationDirectory")

$watchdog = Read-KeyValueFile -Path (Join-Path $ValidationDirectory 'G2B_BS3_EXTERNAL_WATCHDOG.txt')
foreach ($pair in @(
    @('TIMED_OUT','FALSE'),
    @('TIMEOUT_PHASE','NONE'),
    @('PROCESS_EXIT_CODE','0'),
    @('POSTEXISTING_VIVADO_COUNT','0'),
    @('EXTERNAL_QUERY_TIMEOUT_SECONDS','300'),
    @('REPORT_BUS_SKEW_ATTEMPT_COUNT','0'),
    @('DCP_SHA256','EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'),
    @('BASE_XDC_SHA256','3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507'),
    @('CANDIDATE_XDC_SHA256','AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087')
)) {
    Require-Value -Map $watchdog -Key $pair[0] -Expected $pair[1] -Context 'WATCHDOG'
    $lines.Add("WATCHDOG|$($pair[0])=$($pair[1])|RESULT=PASS")
}

$worker = Read-KeyValueFile -Path (Join-Path $ValidationDirectory 'WORKER_COMPLETED.marker')
Require-Value -Map $worker -Key 'MODE' -Expected 'validate_all' -Context 'WORKER'
Require-Value -Map $worker -Key 'STATUS' -Expected 'PASS' -Context 'WORKER'
$lines.Add("WORKER_RUNTIME_SECONDS=$($worker['WORKER_RUNTIME_SECONDS'])")

$families = @(
    [pscustomobject]@{ Label = 'SLOT'; Count = '2' },
    [pscustomobject]@{ Label = 'GENERATION'; Count = '24' },
    [pscustomobject]@{ Label = 'EPOCH'; Count = '32' }
)
foreach ($family in $families) {
    $resultPath = Join-Path $ValidationDirectory "G2B_BS3_$($family.Label)_TIMING_RESULT.txt"
    $result = Read-KeyValueFile -Path $resultPath
    foreach ($pair in @(
        @('STATUS','PASS'),
        @('SOURCE_COUNT',$family.Count),
        @('DESTINATION_COUNT','17'),
        @('PATH_COUNT','1'),
        @('REQUIRED_NS','6.000'),
        @('PATH_REQUIREMENT_NS','6.000'),
        @('STARTPOINT_CLOCK','userclk1'),
        @('ENDPOINT_CLOCK','nvp_vclk1'),
        @('EXCEPTION','MaxDelay Path 6.000ns -datapath_only')
    )) {
        Require-Value -Map $result -Key $pair[0] -Expected $pair[1] -Context $family.Label
    }
    $delay = [double]::Parse($result['DATAPATH_DELAY_NS'], $invariant)
    $slack = [double]::Parse($result['SLACK_NS'], $invariant)
    $runtime = [double]::Parse($result['QUERY_RUNTIME_SECONDS'], $invariant)
    if ($delay -gt 6.000) { throw "$($family.Label) datapath delay exceeds 6.000 ns: $delay" }
    if ($slack -lt 0.0) { throw "$($family.Label) slack is negative: $slack" }
    if ($runtime -gt 300.0) { throw "$($family.Label) query runtime exceeds 300 seconds: $runtime" }
    $lines.Add("FAMILY|$($family.Label)|DATAPATH_DELAY_NS=$($result['DATAPATH_DELAY_NS'])|SLACK_NS=$($result['SLACK_NS'])|QUERY_RUNTIME_SECONDS=$($result['QUERY_RUNTIME_SECONDS'])|RESULT=PASS")
}

$candidateMethodologyPath = Join-Path $ValidationDirectory 'G2B_BS3_CANDIDATE_TIMING_METHODOLOGY.rpt'
$candidateMethodology = Get-Content -LiteralPath $candidateMethodologyPath -Raw
if ($candidateMethodology -notmatch 'Checks found:\s+0') {
    throw 'Candidate focused methodology report does not contain Checks found: 0'
}
$lines.Add('CANDIDATE_FOCUSED_METHODOLOGY_CHECKS_FOUND=0')

foreach ($name in @(
    'G2B_BS3_CANDIDATE_EXCEPTION_COVERAGE.rpt',
    'G2B_BS3_CANDIDATE_IGNORED_EXCEPTIONS.rpt',
    'QUERY_COMPLETED_CANDIDATE_EXCEPTION_COVERAGE.marker',
    'QUERY_COMPLETED_CANDIDATE_IGNORED_EXCEPTIONS.marker'
)) {
    $path = Join-Path $ValidationDirectory $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing exception evidence: $path" }
    $lines.Add("EXCEPTION_EVIDENCE_PRESENT=$name")
}

$lines.Add('WORST_ACTUAL_INTERPRETATION=DATAPATH_DELAY_OF_WORST_SLACK_CONSTRAINED_PATH')
$lines.Add('RESULT=PASS')
[IO.File]::WriteAllText($ReceiptPath, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
