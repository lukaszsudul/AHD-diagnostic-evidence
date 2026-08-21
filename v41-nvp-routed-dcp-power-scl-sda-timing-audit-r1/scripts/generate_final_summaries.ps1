$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1'
$Invariant = [System.Globalization.CultureInfo]::InvariantCulture

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function F3([double]$Value) { return $Value.ToString('0.000', $Invariant) }
function F6([double]$Value) { return $Value.ToString('0.000000', $Invariant) }
function P2([double]$Value) { return $Value.ToString('0.00', $Invariant) }

function Parse-DirectProbe {
    param([string]$Path)
    $result = @{}
    $context = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^ROLE=(\S+) LINE=(SCL|SDA) SEMANTIC=(\S+) MODE=(\S+) ') {
            $context = [pscustomobject]@{ Role=$Matches[1]; Line=$Matches[2]; Semantic=$Matches[3]; Mode=$Matches[4] }
            continue
        }
        if ($null -ne $context -and $context.Mode -eq 'FULL' -and $line -match '^TARGET_DELAY=.*FAST_MAX_PS=(\d+) FAST_MIN_PS=(\d+) SLOW_MAX_PS=(\d+) SLOW_MIN_PS=(\d+)') {
            $key = "$($context.Line)|$($context.Semantic)"
            if (-not $result.ContainsKey($key)) {
                $result[$key] = [pscustomobject]@{
                    FastMaxNs = [double]$Matches[1] / 1000.0
                    FastMinNs = [double]$Matches[2] / 1000.0
                    SlowMaxNs = [double]$Matches[3] / 1000.0
                    SlowMinNs = [double]$Matches[4] / 1000.0
                }
            }
        }
    }
    return $result
}

function Parse-DirectProbeInterconnect {
    param([string]$Path)
    $result = @{}
    $context = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^ROLE=(\S+) LINE=(SCL|SDA) SEMANTIC=(\S+) MODE=(\S+) ') {
            $context = [pscustomobject]@{ Role=$Matches[1]; Line=$Matches[2]; Semantic=$Matches[3]; Mode=$Matches[4] }
            continue
        }
        if ($null -ne $context -and $context.Mode -eq 'INTERCONNECT_ONLY' -and $line -match '^TARGET_DELAY=.*FAST_MAX_PS=(\d+) FAST_MIN_PS=(\d+) SLOW_MAX_PS=(\d+) SLOW_MIN_PS=(\d+)') {
            $key = "$($context.Line)|$($context.Semantic)"
            if (-not $result.ContainsKey($key)) {
                $result[$key] = [pscustomobject]@{
                    FastMaxNs = [double]$Matches[1] / 1000.0
                    FastMinNs = [double]$Matches[2] / 1000.0
                    SlowMaxNs = [double]$Matches[3] / 1000.0
                    SlowMinNs = [double]$Matches[4] / 1000.0
                }
            }
        }
    }
    return $result
}

function Parse-RouteCounts {
    param([string]$Path)
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^ROLE=\S+ LINE=(SCL|SDA) SEMANTIC=(\S+) NET=.* NODE_COUNT=(\d+) WIRE_COUNT=(\d+)$') {
            $key = "$($Matches[1])|$($Matches[2])"
            if (-not $result.ContainsKey($key)) {
                $result[$key] = [pscustomobject]@{ NodeCount=[int]$Matches[3]; WireCount=[int]$Matches[4] }
            }
        }
    }
    return $result
}

function Get-TimingBreakdown {
    param([string]$Path)
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match 'Data Path Delay:\s+([0-9.]+)ns\s+\(logic\s+([0-9.]+)ns\s+\(([0-9.]+)%\)\s+route\s+([0-9.]+)ns\s+\(([0-9.]+)%\)\)') {
            return [pscustomobject]@{
                Data=[double]::Parse($Matches[1],$Invariant)
                Logic=[double]::Parse($Matches[2],$Invariant)
                LogicPct=[double]::Parse($Matches[3],$Invariant)
                Route=[double]::Parse($Matches[4],$Invariant)
                RoutePct=[double]::Parse($Matches[5],$Invariant)
            }
        }
    }
    return $null
}

function Get-TimingPath0 {
    param([string]$CsvPath, [string]$Class, [string]$DelayType)
    $row = Import-Csv -LiteralPath $CsvPath |
        Where-Object { $_.path_class -eq $Class -and $_.delay_type -eq $DelayType -and $_.status -eq 'TIMING_PATH_REPORTED' } |
        Sort-Object { [int]$_.path_index } |
        Select-Object -First 1
    if ($null -eq $row) { return $null }
    return [double]::Parse($row.datapath_delay_ns, $Invariant)
}

function Get-PowerData {
    param([string]$XmlPath)
    [xml]$xml = Get-Content -LiteralPath $XmlPath -Raw
    $rows = @{}
    foreach ($row in $xml.SelectNodes('//tablerow')) {
        $cells = @($row.tablecell)
        if ($cells.Count -lt 2) { continue }
        $key = ([string]$cells[0].contents).Trim()
        if ($key -and -not $rows.ContainsKey($key)) {
            $rows[$key] = @($cells | ForEach-Object { ([string]$_.contents).Trim() })
        }
    }
    function Number([string]$label, [int]$index = 1) {
        if (-not $rows.ContainsKey($label)) { return 0.0 }
        $raw = $rows[$label][$index]
        if ($raw -eq '<0.001') { return 0.0005 }
        return [double]::Parse($raw, $Invariant)
    }
    # Supply rows are: rail, voltage, total current, dynamic current, static current, ...
    $vccint = Number 'Vccint' 2
    $vccaux = Number 'Vccaux' 2
    $vcco33 = Number 'Vcco33' 2
    $vccbram = Number 'Vccbram' 2
    return [pscustomobject]@{
        Total = Number 'Total On-Chip Power (W)'
        Dynamic = Number 'Dynamic (W)'
        Static = Number 'Device Static (W)'
        Clock = Number 'Clocks'
        Signal = Number 'Signals'
        Logic = Number 'Slice Logic'
        Bram = Number 'Block RAM'
        Dsp = Number 'DSPs'
        Io = Number 'I/O'
        Gt = Number 'GTP'
        Mmcm = Number 'MMCM'
        HardIp = Number 'Hard IPs'
        VccintCurrent = $vccint
        VccintPower = $vccint * 1.0
        VccauxCurrent = $vccaux
        VccauxPower = $vccaux * 1.8
        Vcco33Current = $vcco33
        Vcco33AggregatePower = $vcco33 * 3.3
        VccbramCurrent = $vccbram
        VccbramPower = $vccbram * 1.0
        Junction = Number 'Junction Temperature (C)'
        MaxAmbient = Number 'Max Ambient (C)'
        Tja = Number 'Effective TJA (C/W)'
        Confidence = $rows['Confidence Level'][1]
    }
}

$images = [ordered]@{
    R1 = [pscustomobject]@{
        Label='R1 measurement image'; Source='0af44dee3bc091eaff805704dd5c687eeaa01bbd'; Tree='69154c1257c226c8cddacf4d8e1e9badbbd91c46';
        Bit='4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB'; Dcp='182BC87220251ADFD849CB13B582CCD626E00A893F596D7F2D4EF9150108D08A';
        Top='ahd_capture_top_xdma'; DcpPath=(Join-Path $TaskRoot '01_INPUT_IDENTITY\R1_PACKAGE_EXTRACTED\PHASE3_routed.dcp');
        TimingCsv=(Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\R1_SCL_SDA_TIMING_PATHS.csv');
        Direct=(Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\R1_DIRECT_NET_DELAY_PROBE.txt');
        RouteNodes=(Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\R1_SCL_SDA_ROUTE_NODES.txt'); TimingDir=(Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING'); Prefix='R1';
        Placement=(Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\R1_SCL_SDA_PLACEMENT.csv');
        PowerXml=(Join-Path $TaskRoot '04_R1_POWER\R1_REPORT_POWER.xml')
    }
    FORMAL_PHASE2 = [pscustomobject]@{
        Label='Exact formal Phase-2 control'; Source='fd32fcb65be3f1a59c569874195d1faeaf7d27e9'; Tree='417820c69c134161fcafae0947dc5976919814d1';
        Bit='7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'; Dcp='788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460';
        Top='ahd_capture_top_xdma'; DcpPath='C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\02_FRESH_BUILD\R1\PHASE1B_routed.dcp';
        TimingCsv=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2\FORMAL_PHASE2_SCL_SDA_TIMING_PATHS.csv');
        Direct=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2\FORMAL_PHASE2_DIRECT_NET_DELAY_PROBE.txt');
        RouteNodes=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2\FORMAL_PHASE2_SCL_SDA_ROUTE_NODES.txt'); TimingDir=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2'); Prefix='FORMAL_PHASE2';
        Placement=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2\FORMAL_PHASE2_SCL_SDA_PLACEMENT.csv');
        PowerXml=(Join-Path $TaskRoot '06_COMPARATOR_FORMAL_PHASE2\FORMAL_PHASE2_REPORT_POWER.xml')
    }
    RCA = [pscustomobject]@{
        Label='Exact passing v40.1.0 RC-A control'; Source='55ce0df41552bb74e0923f89eff43977b040f2e5'; Tree='11be6461417607667aebf572adeee574c36d71a3';
        Bit='A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6'; Dcp='584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3';
        Top='ahd_capture_top_pcie'; DcpPath='C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\V40_1_0_NVP_PATCH\V40_1_0_FINAL_ACCEPTANCE_R2\BUILD\REPORTS\ahd_capture_v40_release_routed.dcp';
        TimingCsv=(Join-Path $TaskRoot '07_COMPARATOR_RCA\RCA_SCL_SDA_TIMING_PATHS.csv');
        Direct=(Join-Path $TaskRoot '07_COMPARATOR_RCA\RCA_DIRECT_NET_DELAY_PROBE.txt');
        RouteNodes=(Join-Path $TaskRoot '07_COMPARATOR_RCA\RCA_SCL_SDA_ROUTE_NODES.txt'); TimingDir=(Join-Path $TaskRoot '07_COMPARATOR_RCA'); Prefix='RCA';
        Placement=(Join-Path $TaskRoot '07_COMPARATOR_RCA\RCA_SCL_SDA_PLACEMENT.csv');
        PowerXml=(Join-Path $TaskRoot '07_COMPARATOR_RCA\RCA_REPORT_POWER.xml')
    }
}

$metrics = @{}
foreach ($key in $images.Keys) {
    $image = $images[$key]
    $direct = Parse-DirectProbe $image.Direct
    $metrics[$key] = [pscustomobject]@{
        Direct = $direct
        DirectInterconnect = Parse-DirectProbeInterconnect $image.Direct
        RouteCounts = Parse-RouteCounts $image.RouteNodes
        Power = Get-PowerData $image.PowerXml
        SclSyncMax = Get-TimingPath0 $image.TimingCsv 'SCL_SYNC0_Q_TO_SYNC1_D' 'max'
        SclSyncMin = Get-TimingPath0 $image.TimingCsv 'SCL_SYNC0_Q_TO_SYNC1_D' 'min'
        SdaSyncMax = Get-TimingPath0 $image.TimingCsv 'SDA_SYNC0_Q_TO_SYNC1_D' 'max'
        SdaSyncMin = Get-TimingPath0 $image.TimingCsv 'SDA_SYNC0_Q_TO_SYNC1_D' 'min'
        SclDecisionMax = Get-TimingPath0 $image.TimingCsv 'SCL_FILTERED_TO_TIMEOUT_OR_STATE_DECISION' 'max'
        SclDecisionMin = Get-TimingPath0 $image.TimingCsv 'SCL_FILTERED_TO_TIMEOUT_OR_STATE_DECISION' 'min'
        SdaDecisionMax = Get-TimingPath0 $image.TimingCsv 'SDA_FILTERED_TO_ACK_DECISION' 'max'
        SdaDecisionMin = Get-TimingPath0 $image.TimingCsv 'SDA_FILTERED_TO_ACK_DECISION' 'min'
        SclControlMax = Get-TimingPath0 $image.TimingCsv 'SCL_CONTROL_TO_OEN_REGISTER_D' 'max'
        SclControlMin = Get-TimingPath0 $image.TimingCsv 'SCL_CONTROL_TO_OEN_REGISTER_D' 'min'
        SdaControlMax = Get-TimingPath0 $image.TimingCsv 'SDA_CONTROL_TO_OEN_REGISTER_D' 'max'
        SdaControlMin = Get-TimingPath0 $image.TimingCsv 'SDA_CONTROL_TO_OEN_REGISTER_D' 'min'
    }
}

# Power summaries.
$r1p = $metrics.R1.Power
$powerSummary = @(
    'metric,value,unit,availability,note'
    "TOTAL_ON_CHIP_POWER,$(F3 $r1p.Total),W,REPORTED,Vivado report_power"
    "DYNAMIC_POWER,$(F3 $r1p.Dynamic),W,REPORTED,Vivado report_power"
    "DEVICE_STATIC_POWER,$(F3 $r1p.Static),W,REPORTED,Vivado report_power"
    "CLOCK_POWER,$(F3 $r1p.Clock),W,REPORTED,On-chip resource category"
    "SIGNAL_POWER,$(F3 $r1p.Signal),W,REPORTED,On-chip resource category"
    "LOGIC_POWER,$(F3 $r1p.Logic),W,REPORTED,Slice Logic"
    "BRAM_POWER,$(F3 $r1p.Bram),W,REPORTED,Block RAM"
    "DSP_POWER,$(F3 $r1p.Dsp),W,REPORTED,No DSP category usage"
    "IO_POWER,$(F3 $r1p.Io),W,REPORTED,Whole-design I/O estimate"
    "GT_POWER,$(F3 $r1p.Gt),W,REPORTED,GTP"
    "MMCM_POWER,$(F3 $r1p.Mmcm),W,REPORTED,MMCM"
    "HARD_IP_POWER,$(F3 $r1p.HardIp),W,REPORTED,PCIe hard IP"
    "RELEVANT_VCCO_BANK_POWER,NOT_AVAILABLE_FROM_UNMODIFIED_DCP,W,NOT_AVAILABLE,Only aggregate Vcco33 rail-class current is reported"
    "JUNCTION_TEMPERATURE,$(F3 $r1p.Junction),C,REPORTED,Vectorless estimate"
    "MAX_AMBIENT,$(F3 $r1p.MaxAmbient),C,REPORTED,Vectorless estimate"
    "POWER_CONFIDENCE,$($r1p.Confidence),text,REPORTED,Overall confidence"
) -join "`r`n"
Write-Utf8NoBom (Join-Path $TaskRoot '04_R1_POWER\R1_POWER_SUMMARY.csv') ($powerSummary + "`r`n")

$hierarchy = @'
hierarchy,power_w,availability,note
ahd_capture_top_xdma,0.557,REPORTED,Dynamic hierarchy total
AXI_CLOCK_LIFECYCLE_MONITOR,0.001,REPORTED,R1 observer hierarchy
AXI_LITE_HOST_BRIDGE,0.003,REPORTED,
CAPTURE_SUBSYSTEM,0.021,REPORTED,
NVP_AUTOINIT,0.002,REPORTED,
NVP_PHYSICAL_FRONTEND,0.149,REPORTED,
XDMA,0.379,REPORTED,
TOP_LEVEL_IO,NOT_AVAILABLE_FROM_UNMODIFIED_DCP,NOT_AVAILABLE,Resource-level whole-design I/O is available but hierarchy-specific top I/O is not
'@
Write-Utf8NoBom (Join-Path $TaskRoot '04_R1_POWER\R1_POWER_HIERARCHY.csv') $hierarchy

$supply = @(
    'supply,voltage_v,total_current_a,dynamic_current_a,static_current_a,derived_total_power_w,note'
    "VCCINT,1.000000,0.176911,0.165831,0.011080,$(F6 $r1p.VccintPower),Voltage times reported current"
    "VCCAUX,1.800000,0.152758,0.140067,0.012691,$(F6 $r1p.VccauxPower),Voltage times reported current"
    "VCCO33,3.300000,0.001092,0.000092,0.001000,$(F6 $r1p.Vcco33AggregatePower),Aggregate Vcco33 class; not bank 14 alone"
    "VCCBRAM,1.000000,0.002177,0.001463,0.000714,$(F6 $r1p.VccbramPower),Voltage times reported current"
) -join "`r`n"
Write-Utf8NoBom (Join-Path $TaskRoot '04_R1_POWER\R1_POWER_SUPPLY_SUMMARY.csv') ($supply + "`r`n")

$ioBank = @'
image,ports,bank,package_pins,iostandard,drive,slew,pulltype,report_io_offchip_term,bank_specific_power_w,aggregate_vcco33_current_a,aggregate_vcco33_power_w,interpretation
R1,nvp_scl+nvp_sda,14,T17+T18,LVCMOS33,12,SLOW,UNSET,FP_VTT_50,NOT_AVAILABLE_FROM_UNMODIFIED_DCP,0.001092,0.003604,The report's Vcco33 class is not a bank-14 decomposition and does not model the known board 4.7-kohm pull-ups completely
'@
Write-Utf8NoBom (Join-Path $TaskRoot '04_R1_POWER\R1_POWER_IO_BANK_SUMMARY.csv') $ioBank

$powerAssumptions = @'
# R1 Power Assumptions

Vivado 2025.2 `report_power` was run on the exact routed R1 checkpoint without `set_switching_activity`, SAIF generation, or any change to the checkpoint or power assumptions.

- Overall confidence: **Low**.
- Design implementation: High confidence; the design is routed.
- Clock activity: High; the report says more than 95% of clocks are user specified.
- Internal-node activity: Medium; fewer than 25% of internal nodes are user specified.
- I/O activity: Low; more than 75% of inputs lack user activity specification.
- Device models: High; production models.
- Activity basis: mixed propagated/user clock activity plus vectorless/default static probabilities and toggle rates. No setting file or simulation activity file was supplied.
- The SCL/SDA `report_io` rows show Vivado off-chip termination model `FP_VTT_50`. The physical board context supplied by the owner is instead a 4.7-kΩ pull-up on each line to 3.3 V. The routed DCP therefore does not contain a complete external analog bus model.

Consequently, the report can compare estimated on-chip power under identical assumptions, but cannot prove board Vcco droop, ground bounce, I²C rise time, or VIH margin. The aggregate `Vcco33` supply-class value is not a bank-14-only breakdown.
'@
Write-Utf8NoBom (Join-Path $TaskRoot '04_R1_POWER\R1_POWER_ASSUMPTIONS.md') $powerAssumptions

# R1 object and physical summaries.
$objectMap = @'
# SCL/SDA Object Map

Connectivity-first discovery proved exactly one decomposed input buffer (`IBUF`) and one decomposed open-drain output buffer (`OBUFT`) at each top-level port. The logical IOBUF's data input is constant zero and the output-enable path terminates at `OBUFT/T`.

| Line | Port | IBUF leaf | OBUFT leaf | OEN register | Sync0 | Sync1 | Filtered register |
|---|---|---|---|---|---|---|---|
| SCL | `nvp_scl` | `NVP_SCL_IOBUF/IBUF` | `NVP_SCL_IOBUF/OBUFT` | `NVP_AUTOINIT/u_sequence/scl_oen_r_reg` | `scl_sync_r_reg[0]` | `scl_sync_r_reg[1]` | `scl_filtered_r_reg` |
| SDA | `nvp_sda` | `NVP_SDA_IOBUF/IBUF` | `NVP_SDA_IOBUF/OBUFT` | `NVP_AUTOINIT/u_sequence/sda_oen_r_reg` | `sda_sync_r_reg[0]` | `sda_sync_r_reg[1]` | `sda_filtered_r_reg` |

The raw IBUF output feeds the intended first synchronizer stage. In R1 it also reaches observer/read-only diagnostic plumbing outside `NVP_AUTOINIT/u_sequence`; these endpoints are explicitly accounted and are not protocol-decision fanout. Protocol decisions consume synchronized/filtered signals. Both synchronizer stages retain `ASYNC_REG=TRUE` and `SHREG_EXTRACT=NO`.
'@
Write-Utf8NoBom (Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\SCL_SDA_OBJECT_MAP.md') $objectMap

$r1d = $metrics.R1.Direct
$outDeltaMax = [math]::Abs($r1d['SCL|OEN_Q_TO_IOBUF_T'].SlowMaxNs - $r1d['SDA|OEN_Q_TO_IOBUF_T'].SlowMaxNs)
$outDeltaMin = [math]::Abs($r1d['SCL|OEN_Q_TO_IOBUF_T'].FastMinNs - $r1d['SDA|OEN_Q_TO_IOBUF_T'].FastMinNs)
$inDeltaMax = [math]::Abs($r1d['SCL|IBUF_O_TO_SYNC0'].SlowMaxNs - $r1d['SDA|IBUF_O_TO_SYNC0'].SlowMaxNs)
$inDeltaMin = [math]::Abs($r1d['SCL|IBUF_O_TO_SYNC0'].FastMinNs - $r1d['SDA|IBUF_O_TO_SYNC0'].FastMinNs)
$syncDeltaMax = [math]::Abs($metrics.R1.SclSyncMax - $metrics.R1.SdaSyncMax)
$syncDeltaMin = [math]::Abs($metrics.R1.SclSyncMin - $metrics.R1.SdaSyncMin)

$physicalSummary = @"
# R1 SCL/SDA Physical Summary

Both ports use the same electrical standard and open-drain structure: T17/T18, bank 14, LVCMOS33, DRIVE 12, SLOW, blank/unset PULLTYPE, and constant zero on the OBUFT data input. `DIFF_TERM=0` and `IN_TERM=NONE` are reported. No OEN or synchronizer register is reported as IOB-packed.

| Path | SCL max/min (ns) | SDA max/min (ns) | absolute max/min delta (ns) | Status |
|---|---:|---:|---:|---|
| OEN register Q → OBUFT T | $(F3 $r1d['SCL|OEN_Q_TO_IOBUF_T'].SlowMaxNs) / $(F3 $r1d['SCL|OEN_Q_TO_IOBUF_T'].FastMinNs) | $(F3 $r1d['SDA|OEN_Q_TO_IOBUF_T'].SlowMaxNs) / $(F3 $r1d['SDA|OEN_Q_TO_IOBUF_T'].FastMinNs) | $(F3 $outDeltaMax) / $(F3 $outDeltaMin) | Physical direct delay from `get_net_delays` |
| IBUF O → sync0 D | $(F3 $r1d['SCL|IBUF_O_TO_SYNC0'].SlowMaxNs) / $(F3 $r1d['SCL|IBUF_O_TO_SYNC0'].FastMinNs) | $(F3 $r1d['SDA|IBUF_O_TO_SYNC0'].SlowMaxNs) / $(F3 $r1d['SDA|IBUF_O_TO_SYNC0'].FastMinNs) | $(F3 $inDeltaMax) / $(F3 $inDeltaMin) | Unconstrained asynchronous path; physical delay only |
| sync0 Q → sync1 D | $(F3 $metrics.R1.SclSyncMax) / $(F3 $metrics.R1.SclSyncMin) | $(F3 $metrics.R1.SdaSyncMax) / $(F3 $metrics.R1.SdaSyncMin) | $(F3 $syncDeltaMax) / $(F3 $syncDeltaMin) | Timed synchronous path |

The output max delta is $(P2 (100*$outDeltaMax/16.0))% of the 16-ns AXI clock and $(F6 (100*$outDeltaMax/5008.0))% of the 5.008-µs I²C midpoint. The input max delta is $(P2 (100*$inDeltaMax/16.0))% of the AXI clock and $(F6 (100*$inDeltaMax/5008.0))% of the midpoint. These nanosecond differences are measurable implementation facts, not proof of analog I²C margin.

Known external context: each line has a 4.7-kΩ pull-up to 3.3 V, or approximately 0.702 mA static current when driven low. External bus capacitance and rise time are unknown and unmeasured; they cannot be inferred from the FPGA route.
"@
Write-Utf8NoBom (Join-Path $TaskRoot '05_R1_SCL_SDA_TIMING\R1_SCL_SDA_PHYSICAL_SUMMARY.md') $physicalSummary

# Cross-image comparison CSVs.
$identityRows = @('image,status,source_commit,source_tree,top,part,vivado,routed_dcp_sha256,bit_sha256,dcp_to_bit_provenance')
foreach ($key in $images.Keys) {
    $i = $images[$key]
    $identityRows += ('"{0}",FOUND_EXACT,{1},{2},{3},xc7a35tcsg325-2,"2025.2 build 6299465",{4},{5},PASS_EXPLICIT_BUILD_CHAIN' -f $key,$i.Source,$i.Tree,$i.Top,$i.Dcp,$i.Bit)
}
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\IMAGE_IDENTITY_MATRIX.csv') (($identityRows -join "`r`n") + "`r`n")

$ioRows = @('image,line,package_pin,bank,iostandard,drive,slew,pulltype,diff_term,in_term,iob_site,offchip_term,iobuf_i_constant_zero,iob_packing')
foreach ($key in $images.Keys) {
    $ioRows += "$key,SCL,T17,14,LVCMOS33,12,SLOW,UNSET,0,NONE,IOB_X0Y18,FP_VTT_50,YES,NO_NOT_REPORTED"
    $ioRows += "$key,SDA,T18,14,LVCMOS33,12,SLOW,UNSET,0,NONE,IOB_X0Y19,FP_VTT_50,YES,NO_NOT_REPORTED"
}
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\SCL_SDA_IO_PROPERTY_COMPARISON.csv') (($ioRows -join "`r`n") + "`r`n")

$placementRows = @('image,line,semantic_role,cell,loc,bel,site,clock_region,iob')
foreach ($key in $images.Keys) {
    foreach ($row in Import-Csv -LiteralPath $images[$key].Placement) {
        $placementRows += ('"{0}","{1}","{2}","{3}","{4}","{5}","{6}","{7}","{8}"' -f $key,$row.line,$row.semantic_role,$row.cell,$row.loc,$row.bel,$row.site,$row.clock_region,$row.iob)
    }
}
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\SCL_SDA_PLACEMENT_COMPARISON.csv') (($placementRows -join "`r`n") + "`r`n")

$timingRows = @('image,line,path_class,max_ns,min_ns,route_max_ns,route_min_ns,logic_or_intrinsic_max_ns,logic_or_intrinsic_min_ns,route_share_max_pct,route_share_min_pct,node_count,wire_count,path_status,max_over_16ns_pct,max_over_5008ns_pct,note')
foreach ($key in $images.Keys) {
    $m = $metrics[$key]
    $image = $images[$key]
    foreach ($line in 'SCL','SDA') {
        $dOut = $m.Direct["$line|OEN_Q_TO_IOBUF_T"]
        $dIn = $m.Direct["$line|IBUF_O_TO_SYNC0"]
        $iOut = $m.DirectInterconnect["$line|OEN_Q_TO_IOBUF_T"]
        $iIn = $m.DirectInterconnect["$line|IBUF_O_TO_SYNC0"]
        $cOut = $m.RouteCounts["$line|OEN_Q_TO_IOBUF_T_NET"]
        $cIn = $m.RouteCounts["$line|IBUF_O_TO_SYNC0_NET"]
        $timingRows += "$key,$line,OEN_Q_TO_IOBUF_T,$(F3 $dOut.SlowMaxNs),$(F3 $dOut.FastMinNs),$(F3 $iOut.SlowMaxNs),$(F3 $iOut.FastMinNs),$(F3 ($dOut.SlowMaxNs-$iOut.SlowMaxNs)),$(F3 ($dOut.FastMinNs-$iOut.FastMinNs)),$(F6 (100*$iOut.SlowMaxNs/$dOut.SlowMaxNs)),$(F6 (100*$iOut.FastMinNs/$dOut.FastMinNs)),$($cOut.NodeCount),$($cOut.WireCount),PHYSICAL_DIRECT_PATH_REPORTED,$(F6 (100*$dOut.SlowMaxNs/16.0)),$(F6 (100*$dOut.SlowMaxNs/5008.0)),FULL_AND_INTERCONNECT_ONLY_get_net_delays"
        $timingRows += "$key,$line,IOBUF_O_TO_SYNC0_D,$(F3 $dIn.SlowMaxNs),$(F3 $dIn.FastMinNs),$(F3 $iIn.SlowMaxNs),$(F3 $iIn.FastMinNs),$(F3 ($dIn.SlowMaxNs-$iIn.SlowMaxNs)),$(F3 ($dIn.FastMinNs-$iIn.FastMinNs)),$(F6 (100*$iIn.SlowMaxNs/$dIn.SlowMaxNs)),$(F6 (100*$iIn.FastMinNs/$dIn.FastMinNs)),$($cIn.NodeCount),$($cIn.WireCount),UNCONSTRAINED_PATH_WITH_PHYSICAL_DELAY_REPORTED,$(F6 (100*$dIn.SlowMaxNs/16.0)),$(F6 (100*$dIn.SlowMaxNs/5008.0)),Setup_slack_not_interpreted"
    }
    foreach ($entry in @(
        @('SCL','SYNC0_Q_TO_SYNC1_D','SCL_SYNC0_Q_TO_SYNC1_D',$m.SclSyncMax,$m.SclSyncMin,'SYNC0_Q_TO_SYNC1_NET','Path_index_0'),
        @('SDA','SYNC0_Q_TO_SYNC1_D','SDA_SYNC0_Q_TO_SYNC1_D',$m.SdaSyncMax,$m.SdaSyncMin,'SYNC0_Q_TO_SYNC1_NET','Path_index_0'),
        @('SCL','FILTERED_TO_DECISION','SCL_FILTERED_TO_TIMEOUT_OR_STATE_DECISION',$m.SclDecisionMax,$m.SclDecisionMin,'FILTERED_Q_NET','Deterministically_sorted_path_index_0'),
        @('SDA','FILTERED_TO_ACK_DECISION','SDA_FILTERED_TO_ACK_DECISION',$m.SdaDecisionMax,$m.SdaDecisionMin,'FILTERED_Q_NET','Deterministically_sorted_path_index_0'),
        @('SCL','CONTROL_TO_OEN_REGISTER_D','SCL_CONTROL_TO_OEN_REGISTER_D',$m.SclControlMax,$m.SclControlMin,'','Path_index_0'),
        @('SDA','CONTROL_TO_OEN_REGISTER_D','SDA_CONTROL_TO_OEN_REGISTER_D',$m.SdaControlMax,$m.SdaControlMin,'','Path_index_0')
    )) {
        $ln=$entry[0]; $label=$entry[1]; $fileClass=$entry[2]; $max=[double]$entry[3]; $min=[double]$entry[4]; $routeSemantic=$entry[5]; $note=$entry[6]
        $bmax=Get-TimingBreakdown (Join-Path $image.TimingDir "$($image.Prefix)_${fileClass}_MAX.rpt")
        $bmin=Get-TimingBreakdown (Join-Path $image.TimingDir "$($image.Prefix)_${fileClass}_MIN.rpt")
        if ($routeSemantic) { $counts=$m.RouteCounts["$ln|$routeSemantic"]; $node=$counts.NodeCount; $wire=$counts.WireCount } else { $node='NOT_AGGREGATED'; $wire='NOT_AGGREGATED' }
        $timingRows += "$key,$ln,$label,$(F3 $max),$(F3 $min),$(F3 $bmax.Route),$(F3 $bmin.Route),$(F3 $bmax.Logic),$(F3 $bmin.Logic),$(F6 $bmax.RoutePct),$(F6 $bmin.RoutePct),$node,$wire,TIMED_SYNCHRONOUS_PATH,$(F6 (100*$max/16.0)),$(F6 (100*$max/5008.0)),$note"
    }
}
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\SCL_SDA_TIMING_PATH_COMPARISON.csv') (($timingRows -join "`r`n") + "`r`n")

$powerFields = [ordered]@{
    TOTAL_ON_CHIP_POWER='Total'; DYNAMIC_POWER='Dynamic'; DEVICE_STATIC_POWER='Static'; CLOCK_POWER='Clock'; SIGNAL_POWER='Signal';
    LOGIC_POWER='Logic'; BRAM_POWER='Bram'; DSP_POWER='Dsp'; IO_POWER='Io'; GT_POWER='Gt'; MMCM_POWER='Mmcm'; HARD_IP_POWER='HardIp';
    VCCINT_CURRENT='VccintCurrent'; VCCAUX_CURRENT='VccauxCurrent'; VCCO33_CURRENT='Vcco33Current'; VCCBRAM_CURRENT='VccbramCurrent'
}
$powerRows = @('metric,unit,r1,formal_phase2,rca,r1_minus_formal,percent_vs_formal,r1_minus_rca,percent_vs_rca,comparison_validity')
foreach ($metric in $powerFields.Keys) {
    $property = $powerFields[$metric]
    $unit = if ($metric -like '*CURRENT') { 'A' } else { 'W' }
    $a = [double]$metrics.R1.Power.$property
    $b = [double]$metrics.FORMAL_PHASE2.Power.$property
    $c = [double]$metrics.RCA.Power.$property
    $df = $a-$b; $dr = $a-$c
    $pf = if ($b -eq 0) { 'NOT_APPLICABLE' } else { F6 (100*$df/$b) }
    $pr = if ($c -eq 0) { 'NOT_APPLICABLE' } else { F6 (100*$dr/$c) }
    $powerRows += "$metric,$unit,$(F6 $a),$(F6 $b),$(F6 $c),$(F6 $df),$pf,$(F6 $dr),$pr,COMPARABLE_IDENTICAL_TOOL_AND_ACTIVITY_CLASS_LOW_CONFIDENCE"
}
$powerRows += 'RELEVANT_VCCO_BANK_POWER,W,NOT_AVAILABLE,NOT_AVAILABLE,NOT_AVAILABLE,NOT_AVAILABLE,NOT_APPLICABLE,NOT_AVAILABLE,NOT_APPLICABLE,NO_BANK14_DECOMPOSITION_FROM_UNMODIFIED_DCP'
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\POWER_COMPARISON.csv') (($powerRows -join "`r`n") + "`r`n")

$interpretation = @"
# Power and SCL/SDA Timing Interpretation

## Exact-control status

Both control checkpoints are admissible: the exact formal Phase-2 routed DCP has an explicit build-log chain to bit SHA-256 `7E4E...449A2`, and the RC-A routed DCP has an explicit chain to the passing `A43B...3B6` bit. All three were audited with Vivado 2025.2 using identical report scripts and unchanged power assumptions.

## I/O and routed implementation

SCL/SDA electrical properties are identical across all three exact images: T17/T18, bank 14, LVCMOS33, DRIVE 12, SLOW, blank/unset PULLTYPE, and constant-zero OBUFT data. All use one IBUF plus one OBUFT per line, and the two-stage input synchronizers retain `ASYNC_REG=TRUE` and `SHREG_EXTRACT=NO`. No IOB packing is reported for the OEN or synchronizer registers.

Placement and routing differ substantially. Slow-max direct path delays (ns) are:

| Path | R1 | Formal Phase-2 | RC-A |
|---|---:|---:|---:|
| SCL OEN→T | 2.303 | 3.256 | 4.273 |
| SDA OEN→T | 1.709 | 3.017 | 5.696 |
| SCL pad→sync0 | 1.246 | 2.134 | 3.788 |
| SDA pad→sync0 | 2.004 | 2.418 | 3.987 |

The passing RC-A image is often the longest. Therefore the DCP comparison proves implementation movement/sensitivity but contradicts a simple explanation in which a longer internal digital path causes the v41 failure. R1 synchronous worst paths remain comfortably within 16 ns. Nanosecond route differences are tiny relative to the 5.008-µs I²C midpoint and 10.016-µs state tick. Asynchronous pad-to-sync paths are unconstrained; their reported physical delay is not setup slack or analog margin.

`IMPLEMENTATION_IO_MARGIN_FINDING=SUPPORTED_BY_EXACT_DCP_COMPARISON` means relevant implementation differences exist. It does not mean that v41 has worse FPGA digital timing or that an analog root cause is proven.

## Power context

R1 and exact formal Phase-2 are nearly equal: total power differs by +0.005 W (+0.79%) and dynamic power by +0.005 W (+0.91%), so R1 observer overhead is small in this estimate. Against passing RC-A, R1 is materially higher: total 0.636 versus 0.401 W (+58.60%) and dynamic 0.557 versus 0.323 W (+72.45%). Clock, signal, logic, BRAM, and MMCM estimates are also materially higher; GTP is unchanged. Estimated VCCINT and VCCAUX currents are approximately +98.6% and +113.6% versus RC-A.

The comparison is valid for ranking because the same Vivado version, report commands, and vectorless/default activity class were used. Confidence is nevertheless Low overall, I/O activity confidence is Low, and internal-node activity confidence is Medium. Aggregate `Vcco33` is effectively identical at report precision and is not a bank-14 decomposition. The model therefore cannot prove board-level Vcco droop, ground bounce, SCL/SDA rise time, or VIH margin.

## Classification

~~~text
IMPLEMENTATION_IO_MARGIN_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

POWER_CONTEXT_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO

ROOT_CAUSE_SOLELY_PROVEN=
    NO
~~~

No hardware experiment is recommended automatically. Owner and auditor review is required before any hardware run.
"@
Write-Utf8NoBom (Join-Path $TaskRoot '08_COMPARISON\POWER_AND_TIMING_INTERPRETATION.md') $interpretation

# Append auditable consolidation facts without changing the required leading ledger lines.
$opLedger = Join-Path $TaskRoot 'OPERATION_LEDGER.md'
$opExisting = Get-Content -LiteralPath $opLedger -Raw
if ($opExisting -notmatch 'FINAL_CONSOLIDATION=') {
    $addition = @'

FINAL_CONSOLIDATION=PASS
R1_ROUTED_DCP_OPEN_OPERATIONS=1_PRIMARY_PLUS_REPORT_ONLY_REOPENS_BY_FOCUSED_SCRIPTS
FORMAL_COMPARATOR_REPORT_ONLY_AUDITS=1_SUITE
RCA_COMPARATOR_REPORT_ONLY_AUDITS=1_SUITE
HARDWARE_ACTIONS=0
FULL_BUILDS=0
IMPLEMENTATION_COMMANDS=0
SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
SSH_SESSIONS=0
JTAG_SESSIONS=0
MMIO_OPERATIONS=0
DMA_TRANSFERS=0
'@
    Write-Utf8NoBom $opLedger ($opExisting.TrimEnd()+$addition+"`r`n")
}

$toolLedger = Join-Path $TaskRoot 'TOOL_COMMAND_LEDGER.md'
$toolExisting = Get-Content -LiteralPath $toolLedger -Raw
if ($toolExisting -notmatch 'FINAL_REPORT_ADAPTATIONS') {
    $addition = @'

## FINAL_REPORT_ADAPTATIONS

- The prompt's duplicated launcher path `C:\AMDDesignTools\2025.2\Vivado\2025.2\bin\vivado.bat` was absent. The verified supported AMD wrapper installed with Vivado 2025.2 was `C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`, with `C:\AMDDesignTools\2025.2\Vivado\settings64.bat`.
- Vivado 2025.2 does not provide `report_delay_calculation`; captured help identified `get_net_delays` as the report-only physical-delay equivalent. `get_net_delays` supplied direct OEN-Q→OBUFT-T and IBUF-O→sync0-D delay evidence in picoseconds without altering timing exceptions or the checkpoint.
- The initial help-capture attempt used unavailable Tcl `redirect`; it failed before opening a checkpoint and was preserved under `raw\FAILED_HELP_CAPTURE_REDIRECT_UNAVAILABLE`. The corrected capture used documented `help -output`.
- The initial timing script failed on a typed-collection conversion before completing; partial output was quarantined under `raw\FAILED_R1_TIMING_TYPED_COLLECTION_1`. The corrected report-only script completed with an explicit success marker.
- Every Vivado invocation used batch mode, opened a routed checkpoint read-only, issued only queries/reports, and closed without saving.
'@
    Write-Utf8NoBom $toolLedger ($toolExisting.TrimEnd()+$addition+"`r`n")
}

Write-Output 'FINAL_SUMMARY_GENERATION=PASS'
