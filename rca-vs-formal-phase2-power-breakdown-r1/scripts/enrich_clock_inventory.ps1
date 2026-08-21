param(
    [Parameter(Mandatory=$true)][string]$TaskRoot
)

$ErrorActionPreference = 'Stop'
$comparison = Join-Path $TaskRoot '05_COMPARISON'
$formalRaw = Join-Path $TaskRoot '03_FORMAL_PHASE2\raw'
$rcaRaw = Join-Path $TaskRoot '04_RCA\raw'

function Resolve-ExactClockName {
    param([string]$Role, [string]$RawName)
    if ($RawName -match 'idelay_mmcm_feedback_unbuf$') { return 'idelay_mmcm_feedback_unbuf' }
    if ($RawName -match 'idelay_refclk_unbuf$') { return 'idelay_refclk_unbuf' }
    if ($RawName -eq 'vclk1') { return 'nvp_vclk1' }
    if ($RawName -eq 'sys_clk_p') {
        if ($Role -eq 'FORMAL_PHASE2_FAIL_CONTROL') { return 'pcie_refclk_100' }
        return 'sys_clk'
    }
    if ($RawName -match 'clk_125mhz$') { return 'clk_125mhz' }
    if ($RawName -match 'clk_250mhz$') { return 'clk_250mhz' }
    if ($RawName -match 'mmcm_fb$') { return 'mmcm_fb' }
    if ($RawName -match 'userclk1$') { return 'userclk1' }
    if ($RawName -match 'pipe_txoutclk_out$' -or $RawName -match 'gtpe2_channel_i_6$') { return 'txoutclk_x0y0' }
    throw "No exact clock-object mapping for role=$Role raw=$RawName"
}

function Get-NormalizedDomain {
    param([string]$ClockName)
    switch -Regex ($ClockName) {
        '^userclk1$' { return 'PCIE_USER_AXI_NVP_AUTOINIT_CAPTURE_CONTROL_COMBINED' }
        '^(nvp_vclk1|idelay_mmcm_feedback_unbuf|idelay_refclk_unbuf)$' { return 'NVP_VIDEO' }
        default { return 'PCIE_REFERENCE_OR_GT_CLOCKING' }
    }
}

$roleSpecs = @(
    [pscustomobject]@{ Role='FORMAL_PHASE2_FAIL_CONTROL'; Raw=$formalRaw },
    [pscustomobject]@{ Role='RCA_PASS_CONTROL'; Raw=$rcaRaw }
)

$summaryByRole = @{}
$membersByRole = @{}
foreach ($spec in $roleSpecs) {
    $summaryPath = Join-Path $spec.Raw 'CLOCK_REGISTER_INVENTORY_RAW.csv'
    $membersPath = Join-Path $spec.Raw 'CLOCK_REGISTER_MEMBERSHIP_RAW.csv'
    $statusPath = Join-Path $spec.Raw 'CLOCK_INVENTORY_STATUS.txt'
    if (-not (Test-Path -LiteralPath $summaryPath) -or -not (Test-Path -LiteralPath $membersPath)) {
        throw "Missing clock inventory for $($spec.Role)"
    }
    if (-not ((Get-Content -LiteralPath $statusPath -Raw) -match 'CLOCK_REGISTER_INVENTORY=PASS')) {
        throw "Clock inventory did not pass for $($spec.Role)"
    }
    $summaryByRole[$spec.Role] = @(Import-Csv -LiteralPath $summaryPath)
    $membersByRole[$spec.Role] = @(Import-Csv -LiteralPath $membersPath)
}

$oldMap = @(Import-Csv -LiteralPath (Join-Path $comparison 'CLOCK_DOMAIN_MAP.csv'))
$enriched = foreach ($row in $oldMap) {
    $exactClock = Resolve-ExactClockName -Role $row.IMAGE_ROLE -RawName $row.RAW_CLOCK_NAME
    $match = @($summaryByRole[$row.IMAGE_ROLE] | Where-Object { $_.CLOCK_NAME -eq $exactClock })
    if ($match.Count -ne 1) {
        throw "Expected one inventory row for $($row.IMAGE_ROLE)/$exactClock, got $($match.Count)"
    }
    $m = $match[0]
    [pscustomobject]@{
        IMAGE_ROLE = $row.IMAGE_ROLE
        RAW_CLOCK_NAME = $row.RAW_CLOCK_NAME
        EXACT_CLOCK_OBJECT = $exactClock
        NORMALIZED_DOMAIN = $row.NORMALIZED_DOMAIN
        SOURCE_PIN_OR_PORT = $m.SOURCE_PINS
        PERIOD_NS = $m.PERIOD_NS
        FREQUENCY_MHZ = $row.FREQUENCY_MHZ
        REGISTER_CELL_COUNT = $m.REGISTER_CELL_COUNT
        REPRESENTATIVE_SEQUENTIAL_SINKS = $m.REPRESENTATIVE_SINKS
        MAIN_HIERARCHY_COUNTS = $m.TOP_HIERARCHY_COUNTS
        REF_NAME_COUNTS = $m.REF_NAME_COUNTS
        RAW_POWER_TOKEN = $row.RAW_POWER_TOKEN
        TRACE_METHOD = 'REPORT_POWER_ROOT_MATCHED_TO_EXACT_GET_CLOCKS_SOURCE_AND_ALL_REGISTERS_CONNECTIVITY'
    }
}
$enriched | Export-Csv -LiteralPath (Join-Path $comparison 'CLOCK_DOMAIN_MAP.csv') -NoTypeInformation -Encoding UTF8

$sequentialRows = New-Object System.Collections.Generic.List[object]
$utilRows = New-Object System.Collections.Generic.List[object]
foreach ($spec in $roleSpecs) {
    $role = $spec.Role
    $members = @($membersByRole[$role])
    $clockDomain = @{}
    foreach ($clock in $summaryByRole[$role]) {
        $clockDomain[$clock.CLOCK_NAME] = Get-NormalizedDomain -ClockName $clock.CLOCK_NAME
    }
    $domains = @($clockDomain.Values | Sort-Object -Unique)
    $cellDomains = @{}
    foreach ($member in $members) {
        $domain = $clockDomain[$member.CLOCK_NAME]
        if (-not $cellDomains.ContainsKey($member.REGISTER_CELL)) {
            $cellDomains[$member.REGISTER_CELL] = New-Object System.Collections.Generic.HashSet[string]
        }
        [void]$cellDomains[$member.REGISTER_CELL].Add($domain)
    }
    foreach ($domain in $domains) {
        $domainClocks = @($clockDomain.Keys | Where-Object { $clockDomain[$_] -eq $domain } | Sort-Object)
        $domainMembers = @($members | Where-Object { $clockDomain[$_.CLOCK_NAME] -eq $domain })
        $uniqueMembers = @($domainMembers | Sort-Object REGISTER_CELL -Unique)
        $sharedCount = @($uniqueMembers | Where-Object { $cellDomains[$_.REGISTER_CELL].Count -gt 1 }).Count
        $sequentialRows.Add([pscustomobject]@{
            IMAGE_ROLE = $role
            NORMALIZED_DOMAIN = $domain
            EXACT_CLOCK_OBJECTS = ($domainClocks -join ';')
            CLOCK_MEMBERSHIP_COUNT = $domainMembers.Count
            UNIQUE_REGISTER_CELL_COUNT = $uniqueMembers.Count
            CROSS_DOMAIN_SHARED_CELL_COUNT = $sharedCount
            COUNT_METHOD = 'ALL_REGISTERS_CLOCK_CELL_MEMBERSHIP_DEDUPLICATED_WITHIN_DOMAIN'
            POWER_INTERPRETATION = 'NOT_POWER'
            SOURCE_FILES = 'CLOCK_REGISTER_INVENTORY_RAW.csv;CLOCK_REGISTER_MEMBERSHIP_RAW.csv'
        })
        $byRef = @($uniqueMembers | Group-Object REF_NAME | Sort-Object Name)
        foreach ($group in $byRef) {
            $utilRows.Add([pscustomobject]@{
                IMAGE_ROLE = $role
                NORMALIZED_DOMAIN = $domain
                REF_NAME = $group.Name
                UNIQUE_REGISTER_CELL_COUNT = $group.Count
                UTILIZATION_MEANING = 'SEQUENTIAL_PRIMITIVE_CELL_COUNT_ONLY_NOT_LOGIC_POWER'
                SOURCE = 'all_registers_-clock_-cells_REF_NAME'
            })
        }
    }
}
$sequentialRows | Export-Csv -LiteralPath (Join-Path $comparison 'SEQUENTIAL_CELL_COUNT_BY_CLOCK_DOMAIN.csv') -NoTypeInformation -Encoding UTF8
$utilRows | Export-Csv -LiteralPath (Join-Path $comparison 'UTILIZATION_BY_CLOCK_DOMAIN.csv') -NoTypeInformation -Encoding UTF8

$bankPath = Join-Path $comparison 'IO_BANK_14_INVENTORY.csv'
$bankRows = @(Import-Csv -LiteralPath $bankPath)
foreach ($row in $bankRows) {
    if ($row.PORT -in @('nvp_rst','nvp_scl','nvp_sda')) {
        $row.CLOCK_ASSOCIATION = 'SOURCE_SEMANTIC_USERCLK1_62.5_MHZ_NVP_AUTOINIT_OR_SYNCHRONIZED_OBSERVER'
    } elseif ($row.PORT -like 'nvp_mpp*') {
        $row.CLOCK_ASSOCIATION = 'NO_CLOCKED_CONSUMER_PROVEN_SOURCE_SEMANTIC_CONTEXT'
    }
}
$bankRows | Export-Csv -LiteralPath $bankPath -NoTypeInformation -Encoding UTF8

$status = @"
CLOCK_CONNECTIVITY_ENRICHMENT=PASS
FORMAL_CLOCK_OBJECTS=$($summaryByRole['FORMAL_PHASE2_FAIL_CONTROL'].Count)
RCA_CLOCK_OBJECTS=$($summaryByRole['RCA_PASS_CONTROL'].Count)
CLOCK_DOMAIN_MAP_ROWS=$($enriched.Count)
SEQUENTIAL_DOMAIN_ROWS=$($sequentialRows.Count)
UTILIZATION_DOMAIN_PRIMITIVE_ROWS=$($utilRows.Count)
LOGIC_POWER_BY_CLOCK_DOMAIN=NOT_DIRECTLY_AVAILABLE_FROM_UNMODIFIED_DCP
SEQUENTIAL_AND_UTILIZATION_OUTPUTS_ARE_COUNTS_NOT_POWER=YES
"@
[System.IO.File]::WriteAllText((Join-Path $comparison 'CLOCK_CONNECTIVITY_ENRICHMENT_STATUS.txt'), $status, [System.Text.UTF8Encoding]::new($false))

Write-Output 'CLOCK_CONNECTIVITY_ENRICHMENT=PASS'
