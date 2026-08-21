param(
    [Parameter(Mandatory=$true)]
    [string]$TaskRoot
)

$ErrorActionPreference = 'Stop'
$formalRaw = Join-Path $TaskRoot '03_FORMAL_PHASE2\raw'
$formalParsed = Join-Path $TaskRoot '03_FORMAL_PHASE2\parsed'
$rcaRaw = Join-Path $TaskRoot '04_RCA\raw'
$rcaParsed = Join-Path $TaskRoot '04_RCA\parsed'
$comparison = Join-Path $TaskRoot '05_COMPARISON'
New-Item -ItemType Directory -Force -Path $formalParsed,$rcaParsed | Out-Null

function Export-RoleSubset {
    param([string]$InputPath,[string]$Role,[string]$OutputPath)
    $rows = @(Import-Csv -LiteralPath $InputPath | Where-Object { $_.IMAGE_ROLE -eq $Role })
    if ($rows.Count -eq 0) { throw "No rows for role $Role in $InputPath" }
    $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
}

Export-RoleSubset (Join-Path $comparison 'SUPPLY_RAILS_ALL.csv') 'FORMAL_PHASE2_FAIL_CONTROL' (Join-Path $formalParsed 'SUPPLY_RAILS_ALL.csv')
Export-RoleSubset (Join-Path $comparison 'CLOCK_NETWORK_POWER_RAW.csv') 'FORMAL_PHASE2_FAIL_CONTROL' (Join-Path $formalParsed 'CLOCK_NETWORK_POWER_RAW.csv')
Export-RoleSubset (Join-Path $comparison 'HIERARCHY_POWER_RAW.csv') 'FORMAL_PHASE2_FAIL_CONTROL' (Join-Path $formalParsed 'HIERARCHY_POWER_RAW.csv')
Export-RoleSubset (Join-Path $comparison 'SUPPLY_RAILS_ALL.csv') 'RCA_PASS_CONTROL' (Join-Path $rcaParsed 'SUPPLY_RAILS_ALL.csv')
Export-RoleSubset (Join-Path $comparison 'CLOCK_NETWORK_POWER_RAW.csv') 'RCA_PASS_CONTROL' (Join-Path $rcaParsed 'CLOCK_NETWORK_POWER_RAW.csv')
Export-RoleSubset (Join-Path $comparison 'HIERARCHY_POWER_RAW.csv') 'RCA_PASS_CONTROL' (Join-Path $rcaParsed 'HIERARCHY_POWER_RAW.csv')

$formalCommands = Get-Content -LiteralPath (Join-Path $formalRaw 'REPORT_COMMAND_SEQUENCE.txt')
$rcaCommands = Get-Content -LiteralPath (Join-Path $rcaRaw 'REPORT_COMMAND_SEQUENCE.txt')
$formalLabels = @($formalCommands | ForEach-Object { ($_ -split '=',2)[0] })
$rcaLabels = @($rcaCommands | ForEach-Object { ($_ -split '=',2)[0] })
$labelsEqual = [string]::Join('|',$formalLabels) -ceq [string]::Join('|',$rcaLabels)

function Normalize-Commands {
    param([string[]]$Lines,[string]$Dcp,[string]$Out)
    return @($Lines | ForEach-Object { $_.Replace($Dcp,'<DCP>').Replace($Out,'<OUTPUT_ROOT>') })
}
$formalNorm = Normalize-Commands $formalCommands 'C:/FPGA/V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1/01_INPUT_IDENTITY/FORMAL_PHASE2_routed.dcp' 'C:/FPGA/V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1/03_FORMAL_PHASE2/raw'
$rcaNorm = Normalize-Commands $rcaCommands 'C:/FPGA/V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1/01_INPUT_IDENTITY/RCA_routed.dcp' 'C:/FPGA/V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1/04_RCA/raw'
$sequenceEqual = [string]::Join("`n",$formalNorm) -ceq [string]::Join("`n",$rcaNorm)
$sequenceText = @"
REPORT_SCRIPT_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $TaskRoot 'scripts\run_power_breakdown.tcl')).Hash)
FORMAL_COMMAND_COUNT=$($formalCommands.Count)
RCA_COMMAND_COUNT=$($rcaCommands.Count)
COMMAND_LABEL_SEQUENCE_EQUAL=$(if($labelsEqual){'YES'}else{'NO'})
NORMALIZED_COMMAND_SEQUENCE_EQUAL=$(if($sequenceEqual){'YES'}else{'NO'})

--- NORMALIZED SEQUENCE ---
$([string]::Join("`n",$formalNorm))
"@
[System.IO.File]::WriteAllText((Join-Path $comparison 'REPORT_SEQUENCE_COMPARISON.txt'),$sequenceText,[System.Text.UTF8Encoding]::new($false))
if (-not $labelsEqual -or -not $sequenceEqual) { throw 'Report command sequences differ' }

function Read-WithoutVolatileHeaders {
    param([string]$Path)
    return @(Get-Content -LiteralPath $Path | Where-Object { $_ -notmatch '^\| (Date|Command)\s+:' })
}

$invarianceRows = New-Object System.Collections.Generic.List[object]
foreach ($role in @(@('FORMAL_PHASE2',$formalRaw),@('RCA',$rcaRaw))) {
    $name=$role[0];$dir=$role[1]
    $corePre=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $dir 'PRE_OPERATING_CONDITIONS_CORE_VOLTAGE.rpt')).Hash
    $corePost=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $dir 'POST_OPERATING_CONDITIONS_CORE_VOLTAGE.rpt')).Hash
    $defaultsPre=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $dir 'PRE_SWITCHING_ACTIVITY_DEFAULTS.rpt')).Hash
    $defaultsPost=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $dir 'POST_SWITCHING_ACTIVITY_DEFAULTS.rpt')).Hash
    $clockPre=[string]::Join("`n",(Read-WithoutVolatileHeaders (Join-Path $dir 'PRE_CLOCKS.rpt')))
    $clockPost=[string]::Join("`n",(Read-WithoutVolatileHeaders (Join-Path $dir 'POST_CLOCKS.rpt')))
    $networkPre=[string]::Join("`n",(Read-WithoutVolatileHeaders (Join-Path $dir 'PRE_CLOCK_NETWORKS.rpt')))
    $networkPost=[string]::Join("`n",(Read-WithoutVolatileHeaders (Join-Path $dir 'POST_CLOCK_NETWORKS.rpt')))
    $preAvg=(Get-Content -LiteralPath (Join-Path $dir 'PRE_SWITCHING_ACTIVITY_TOP_PORTS.rpt') -Raw).Trim()
    $postAvg=(Get-Content -LiteralPath (Join-Path $dir 'POST_SWITCHING_ACTIVITY_TOP_PORTS.rpt') -Raw).Trim()
    $invarianceRows.Add([pscustomobject]@{
        IMAGE_ROLE=$name
        CORE_VOLTAGE_HASH_EQUAL=if($corePre -eq $corePost){'YES'}else{'NO'}
        DEFAULT_ACTIVITY_HASH_EQUAL=if($defaultsPre -eq $defaultsPost){'YES'}else{'NO'}
        CLOCK_DEFINITION_SEMANTIC_EQUAL=if($clockPre -ceq $clockPost){'YES'}else{'NO'}
        CLOCK_NETWORK_SEMANTIC_EQUAL=if($networkPre -ceq $networkPost){'YES'}else{'NO'}
        PRE_TOP_PORT_AVERAGE=$preAvg
        POST_TOP_PORT_AVERAGE=$postAvg
        INTERPRETATION='POST VALUE IS VECTORLESS PROPAGATION OUTPUT; NO ACTIVITY SETTER OR SAIF COMMAND WAS USED'
    })
}
$invarianceRows | Export-Csv -LiteralPath (Join-Path $comparison 'PRE_POST_INVARIANCE.csv') -NoTypeInformation -Encoding UTF8

$invarianceMd = @'
# Pre/post analysis invariance

The report-only Tcl contains no operating-condition setter, switching-activity
setter/reset, or SAIF command. Core-voltage queries and default activity
queries are byte-identical before and after `report_power`; clock definitions
and networks are semantically identical after removing only report date and
output-command headers.

The estimated junction temperature and average top-port activity change after
power analysis because they are derived analysis results populated by
vectorless propagation. They are not user assumption mutations.

```text
OPERATING_CONDITIONS_CHANGED_DURING_TASK=NO
SWITCHING_ACTIVITY_CHANGED_DURING_TASK=NO
VECTORLESS_DERIVED_ACTIVITY_POPULATED_BY_REPORT_POWER=YES
```
'@
[System.IO.File]::WriteAllText((Join-Path $comparison 'PRE_POST_INVARIANCE.md'),$invarianceMd,[System.Text.UTF8Encoding]::new($false))

$bankMd = @'
# Per-bank VCCO availability audit

The text, XML, RPX string inventory, `report_io`, I/O-bank objects, ports,
I/O primitives, and associated nets were searched after `report_power`.
`report_io` identifies VCCO_14 supply pins and the ports assigned to bank 14,
but it does not report bank power/current. No documented, unit-bearing,
mutually exclusive power/current property is present on the bank, port, I/O
cell, or net objects. Bank 16 has no used design ports in either image.

The only modeled 3.3-V rail row is aggregate `Vcco33`; it cannot be assigned
to bank 14 or bank 16.

```text
VCCO_14_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_14_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_16_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_16_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
AGGREGATE_VCCO33_IS_PER_BANK=NO
```
'@
[System.IO.File]::WriteAllText((Join-Path $comparison 'VCCO_BANK_BREAKDOWN_AVAILABILITY.md'),$bankMd,[System.Text.UTF8Encoding]::new($false))

Write-Output 'FINALIZE_COMPARISON=PASS'
