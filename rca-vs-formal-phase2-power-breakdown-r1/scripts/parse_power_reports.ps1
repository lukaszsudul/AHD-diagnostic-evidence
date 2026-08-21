[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FormalReportDir,

    [Parameter(Mandatory = $true)]
    [string]$RcaReportDir,

    [Parameter(Mandatory = $true)]
    [string]$OutputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Invariant = [System.Globalization.CultureInfo]::InvariantCulture
$script:PowerResolutionW = [decimal]'0.001'
$script:CurrentResolutionA = [decimal]'0.001'

function Fail-Closed {
    param([string]$Message)
    throw "FAIL_CLOSED_POWER_REPORT_PARSER: $Message"
}

function Decimal-Text {
    param(
        [AllowNull()][object]$Value,
        [int]$Places = 6
    )
    if ($null -eq $Value) { return '' }
    return ([decimal]$Value).ToString(('0.' + ('0' * $Places)), $script:Invariant)
}

function Percent-Text {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return 'NOT_MEANINGFUL' }
    return ([decimal]$Value).ToString('0.00', $script:Invariant)
}

function Parse-NumericToken {
    param([string]$Token)
    $raw = $Token.Trim()
    if ($raw -match '^<\s*([0-9]+(?:\.[0-9]+)?)$') {
        $v = [decimal]::Parse($Matches[1], $script:Invariant)
        $decimals = if ($Matches[1].Contains('.')) { $Matches[1].Split('.')[1].Length } else { 0 }
        $resolution = [decimal]1
        for ($i = 0; $i -lt $decimals; $i++) { $resolution = $resolution / [decimal]10 }
        return [pscustomobject]@{
            Raw = $raw; Kind = 'LESS_THAN'; Value = $null
            Lower = [decimal]0; UpperExclusive = $v
            Resolution = $resolution; HalfWidth = $null
        }
    }
    if ($raw -match '^[+-]?[0-9]+(?:\.[0-9]+)?$') {
        $v = [decimal]::Parse($raw, $script:Invariant)
        $decimals = if ($raw.Contains('.')) { $raw.Split('.')[1].Length } else { 0 }
        $resolution = [decimal]1
        for ($i = 0; $i -lt $decimals; $i++) { $resolution = $resolution / [decimal]10 }
        return [pscustomobject]@{
            Raw = $raw; Kind = 'EXACT_DISPLAY'; Value = $v
            Lower = $v; UpperExclusive = $v
            Resolution = $resolution; HalfWidth = $resolution / [decimal]2
        }
    }
    return [pscustomobject]@{
        Raw = $raw; Kind = 'NON_NUMERIC'; Value = $null
        Lower = $null; UpperExclusive = $null
        Resolution = $null; HalfWidth = $null
    }
}

function Split-BoxRow {
    param([string]$Line)
    if (-not $Line.StartsWith('|')) { return $null }
    $parts = $Line.Split([char]'|')
    if ($parts.Count -lt 3) { return $null }
    $result = New-Object System.Collections.Generic.List[string]
    for ($i = 1; $i -lt ($parts.Count - 1); $i++) { $result.Add($parts[$i]) }
    return ,$result.ToArray()
}

function Semantic-NameCell {
    param([string]$Cell)
    $value = $Cell.TrimEnd()
    if ($value.StartsWith(' ')) { $value = $value.Substring(1) }
    return $value
}

function Find-HeaderIndex {
    param(
        [string[]]$Lines,
        [string[]]$RequiredHeaders,
        [int]$StartIndex = 0
    )
    for ($i = $StartIndex; $i -lt $Lines.Count; $i++) {
        $cells = Split-BoxRow $Lines[$i]
        if ($null -eq $cells) { continue }
        $trimmed = @($cells | ForEach-Object { $_.Trim() })
        $all = $true
        foreach ($header in $RequiredHeaders) {
            if ($trimmed -notcontains $header) { $all = $false; break }
        }
        if ($all) { return $i }
    }
    return -1
}

function Read-TableRows {
    param(
        [string[]]$Lines,
        [int]$HeaderIndex
    )
    $headerCells = @(Split-BoxRow $Lines[$HeaderIndex] | ForEach-Object { $_.Trim() })
    $rows = New-Object System.Collections.Generic.List[object]
    $seenData = $false
    for ($i = $HeaderIndex + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line.StartsWith('+')) {
            if ($seenData) { break }
            continue
        }
        $cells = Split-BoxRow $line
        if ($null -eq $cells) {
            if ($seenData) { break }
            continue
        }
        if ($cells.Count -ne $headerCells.Count) {
            Fail-Closed "table at line $($HeaderIndex + 1) has malformed row at line $($i + 1)"
        }
        $seenData = $true
        $map = [ordered]@{}
        for ($c = 0; $c -lt $headerCells.Count; $c++) { $map[$headerCells[$c]] = $cells[$c] }
        $rows.Add([pscustomobject]@{ LineNumber = $i + 1; Cells = $map })
    }
    if ($rows.Count -eq 0) { Fail-Closed "mandatory table at line $($HeaderIndex + 1) contains no data rows" }
    return ,$rows.ToArray()
}

function Get-UniqueCompletePowerReport {
    param([string]$Directory)
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        Fail-Closed "report directory does not exist: $Directory"
    }
    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($file in Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter '*.rpt') {
        if ($file.FullName -match '[\\/]FAILED_[^\\/]+[\\/]') { continue }
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text.Contains('1.2 Power Supply Summary') -and
            $text.Contains('3.1 By Hierarchy') -and
            $text.Contains('3.2 By Clock Domain') -and
            $text.Contains('report_power') -and
            $text.Contains('-hier all') -and
            $text.Contains('-hierarchical_depth 0') -and
            $text.Contains('-l 0')) {
            $candidates.Add([pscustomobject]@{ File = $file; Text = $text })
        }
    }
    if ($candidates.Count -eq 0) {
        Fail-Closed "no complete -hier all/-depth 0/-l 0 power report found under $Directory"
    }
    $preferred = @($candidates | Where-Object { $_.File.Name -eq 'REPORT_POWER_HIERARCHY_ALL_VERBOSE.rpt' })
    if ($preferred.Count -ne 1) {
        Fail-Closed "expected one uniquely named REPORT_POWER_HIERARCHY_ALL_VERBOSE.rpt under $Directory; found $($preferred.Count) among $($candidates.Count) complete reports"
    }
    return $preferred[0]
}

function Get-UniqueReportIo {
    param([string]$Directory)
    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($file in Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter '*.rpt') {
        if ($file.FullName -match '[\\/]FAILED_[^\\/]+[\\/]') { continue }
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text.Contains('| Pin Number') -and $text.Contains('| Signal Name') -and $text.Contains('| IO Bank')) {
            $candidates.Add([pscustomobject]@{ File = $file; Text = $text })
        }
    }
    if ($candidates.Count -eq 0) { Fail-Closed "mandatory report_io output not found under $Directory" }
    $hashGroups = @($candidates | Group-Object { (Get-FileHash -LiteralPath $_.File.FullName -Algorithm SHA256).Hash })
    if ($hashGroups.Count -gt 1) {
        Fail-Closed "multiple non-identical report_io outputs found under $Directory"
    }
    return $candidates[0]
}

function Header-Scalar {
    param([string[]]$Lines, [string]$Label)
    $escaped = [regex]::Escape($Label)
    foreach ($line in $Lines) {
        if ($line -match "^\|\s*$escaped\s*:\s*(.*?)\s*$") { return $Matches[1].Trim() }
    }
    return $null
}

function Table-Scalar {
    param([string[]]$Lines, [string]$Label)
    $escaped = [regex]::Escape($Label)
    foreach ($line in $Lines) {
        if ($line -match "^\|\s*$escaped\s*\|\s*([^|]+)\|") { return $Matches[1].Trim() }
    }
    return $null
}

function Confidence-Entry {
    param([string[]]$Lines, [string]$Label)
    foreach ($line in $Lines) {
        $cells = Split-BoxRow $line
        if ($null -eq $cells -or $cells.Count -lt 3) { continue }
        if ($cells[0].Trim() -eq $Label) {
            return ($cells[1].Trim() + ':' + $cells[2].Trim())
        }
    }
    return $null
}

function Require-Scalar {
    param([AllowNull()][string]$Value, [string]$Description)
    if ([string]::IsNullOrWhiteSpace($Value)) { Fail-Closed "missing mandatory scalar: $Description" }
    return $Value
}

function Normalize-RailClass {
    param([string]$RawName)
    switch -Regex ($RawName.Trim()) {
        '^(?i)Vccint$' { return 'VCCINT' }
        '^(?i)Vccaux$' { return 'VCCAUX' }
        '^(?i)Vccbram$' { return 'VCCBRAM' }
        '^(?i)Vcco33$' { return 'AGGREGATE_VCCO33' }
        '^(?i)Vcco' { return 'OTHER_VCCO_CLASS' }
        '^(?i)MGTAVcc$' { return 'MGTAVCC' }
        '^(?i)MGTAVtt$' { return 'MGTAVTT' }
        '^(?i)MGTVCCAUX$' { return 'MGTVCCAUX' }
        '^(?i)MGT' { return 'OTHER_MGT_SUPPLY' }
        default { return 'OTHER_SUPPLY' }
    }
}

function Parse-SupplyRows {
    param(
        [string]$Role,
        [string]$SourceFile,
        [string[]]$Lines,
        [string]$Confidence,
        [string]$ActivityBasis
    )
    $header = Find-HeaderIndex $Lines @('Source', 'Voltage (V)', 'Total (A)', 'Dynamic (A)', 'Static (A)')
    if ($header -lt 0) { Fail-Closed "$Role report lacks Power Supply Summary table" }
    $rows = Read-TableRows $Lines $header
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        $rawName = $row.Cells['Source'].Trim()
        $voltage = Parse-NumericToken $row.Cells['Voltage (V)']
        if ($voltage.Kind -ne 'EXACT_DISPLAY') { Fail-Closed "$Role rail $rawName has non-numeric voltage" }
        foreach ($component in @('Total', 'Dynamic', 'Static')) {
            $column = "$component (A)"
            $current = Parse-NumericToken $row.Cells[$column]
            if ($current.Kind -ne 'EXACT_DISPLAY') { Fail-Closed "$Role rail $rawName has non-numeric $column" }
            $power = $voltage.Value * $current.Value
            $powerResolution = $voltage.Value * $current.Resolution
            $output.Add([pscustomobject]@{
                IMAGE_ROLE = $Role
                RAW_SUPPLY_NAME = $rawName
                NORMALIZED_SUPPLY_CLASS = Normalize-RailClass $rawName
                VOLTAGE_V = Decimal-Text $voltage.Value 3
                ESTIMATED_CURRENT_A = Decimal-Text $current.Value 6
                ESTIMATED_POWER_W = Decimal-Text $power 6
                STATIC_OR_DYNAMIC_IF_REPORTED = $component.ToUpperInvariant()
                RAW_CURRENT_TOKEN = $current.Raw
                CURRENT_REPORT_RESOLUTION_A = Decimal-Text $current.Resolution 6
                POWER_REPORT_RESOLUTION_W = Decimal-Text $powerResolution 6
                REPORT_SECTION = '1.2 Power Supply Summary'
                REPORT_CONFIDENCE = $Confidence
                ACTIVITY_BASIS = $ActivityBasis
                POWER_METHOD = 'DERIVED_REPORTED_VOLTAGE_TIMES_REPORTED_CURRENT'
                SOURCE_FILE = $SourceFile
                SOURCE_LINE_OR_TABLE = "line $($row.LineNumber)"
            })
        }
    }
    return $output.ToArray()
}

function Parse-HierarchyRows {
    param([string]$Role, [string]$SourceFile, [string[]]$Lines)
    $section = [array]::IndexOf($Lines, '3.1 By Hierarchy')
    if ($section -lt 0) { Fail-Closed "$Role report lacks 3.1 By Hierarchy" }
    $header = Find-HeaderIndex $Lines @('Name', 'Power (W)', 'Clock #', 'Clock (W)', 'Io (W)', 'Signal (W)', 'Logic (W)', 'Bram (W)', 'Clock IP (W)', 'Gt (W)', 'Pcie (W)') $section
    if ($header -lt 0) { Fail-Closed "$Role hierarchy table header is missing or incomplete" }
    $rows = Read-TableRows $Lines $header
    $stack = @{}
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        $semantic = Semantic-NameCell $row.Cells['Name']
        $leading = $semantic.Length - $semantic.TrimStart().Length
        if (($leading % 2) -ne 0) { Fail-Closed "$Role hierarchy indentation is not a multiple of two at line $($row.LineNumber)" }
        $depth = [int]($leading / 2)
        $name = $semantic.TrimStart()
        if ($depth -eq 0) { $path = $name }
        else {
            if (-not $stack.ContainsKey($depth - 1)) { Fail-Closed "$Role hierarchy parent missing for $name at line $($row.LineNumber)" }
            $path = "$($stack[$depth - 1])/$name"
        }
        foreach ($key in @($stack.Keys)) { if ([int]$key -ge $depth) { $stack.Remove($key) } }
        $stack[$depth] = $path
        $power = Parse-NumericToken $row.Cells['Power (W)']
        $clock = Parse-NumericToken $row.Cells['Clock (W)']
        $io = Parse-NumericToken $row.Cells['Io (W)']
        $signal = Parse-NumericToken $row.Cells['Signal (W)']
        $logic = Parse-NumericToken $row.Cells['Logic (W)']
        $bram = Parse-NumericToken $row.Cells['Bram (W)']
        $clockIp = Parse-NumericToken $row.Cells['Clock IP (W)']
        $gt = Parse-NumericToken $row.Cells['Gt (W)']
        $pcie = Parse-NumericToken $row.Cells['Pcie (W)']
        $output.Add([pscustomobject]@{
            IMAGE_ROLE = $Role; HIERARCHY_PATH = $path; RAW_NAME = $name; DEPTH = $depth
            TOTAL_DYNAMIC_POWER_W = $power.Raw; CLOCK_W = $clock.Raw; IO_W = $io.Raw
            SIGNAL_W = $signal.Raw; LOGIC_W = $logic.Raw; BRAM_W = $bram.Raw
            CLOCK_IP_W = $clockIp.Raw; GT_W = $gt.Raw; PCIE_W = $pcie.Raw
            OTHER_REPORTED_CATEGORIES = ''
            POWER_VALUE_W = if ($null -ne $power.Value) { Decimal-Text $power.Value 6 } else { '' }
            POWER_LOWER_BOUND_W = Decimal-Text $power.Lower 6
            POWER_UPPER_BOUND_EXCLUSIVE_W = Decimal-Text $power.UpperExclusive 6
            REPORT_RESOLUTION_W = Decimal-Text $power.Resolution 6
            SOURCE_TABLE = '3.1 By Hierarchy'
            SOURCE_FILE = $SourceFile; SOURCE_LINE = $row.LineNumber
        })
    }
    return $output.ToArray()
}

function Semantic-ClockDomain {
    param([string]$Name)
    if ($Name -match '(?i)userclk1|userclk2|axi_aclk') {
        return 'PCIE_USER_AXI_NVP_AUTOINIT_CAPTURE_CONTROL_COMBINED'
    }
    if ($Name -match '(?i)vclk1|idelay_refclk|idelay_mmcm') { return 'NVP_VIDEO' }
    if ($Name -match '(?i)clk_125|clk_250|mmcm_fb|sys_clk|refclk|txoutclk|gtpe2|gtp_channel') {
        return 'PCIE_REFERENCE_OR_GT_CLOCKING'
    }
    if ($Name -match '(?i)capture') { return 'CAPTURE_INTERNAL' }
    if ($Name -match '(?i)autoinit|nvp_aclk') { return 'NVP_AUTOINIT' }
    return 'OTHER'
}

function Parse-ClockRows {
    param(
        [string]$Role,
        [string]$SourceFile,
        [string[]]$Lines,
        [string]$Confidence,
        [string]$ActivityBasis
    )
    $section = [array]::IndexOf($Lines, '3.2 By Clock Domain')
    if ($section -lt 0) { Fail-Closed "$Role report lacks 3.2 By Clock Domain" }
    $header = Find-HeaderIndex $Lines @('Name', 'Power (W)', 'Frequency (MHz)', 'Buffer', 'Bel Fanout') $section
    if ($header -lt 0) { Fail-Closed "$Role clock-domain table header is missing" }
    $rows = Read-TableRows $Lines $header
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        $semantic = Semantic-NameCell $row.Cells['Name']
        $leading = $semantic.Length - $semantic.TrimStart().Length
        if (($leading % 2) -ne 0) { Fail-Closed "$Role clock indentation is not a multiple of two at line $($row.LineNumber)" }
        $depth = [int]($leading / 2)
        $name = $semantic.TrimStart()
        $power = Parse-NumericToken $row.Cells['Power (W)']
        $frequency = Parse-NumericToken $row.Cells['Frequency (MHz)']
        $period = $null
        if ($null -ne $frequency.Value -and $frequency.Value -gt 0) { $period = [decimal]1000 / $frequency.Value }
        $output.Add([pscustomobject]@{
            IMAGE_ROLE = $Role; RAW_CLOCK_NAME = $name
            SOURCE_PIN_OR_PORT = if ($depth -eq 0) { 'ROOT_NOT_EXPLICIT_IN_REPORT_POWER' } else { 'CHILD_CLOCK_NETWORK_ROW' }
            PERIOD_NS = Decimal-Text $period 6; FREQUENCY_MHZ = if ($null -ne $frequency.Value) { Decimal-Text $frequency.Value 6 } else { '' }
            FANOUT = $row.Cells['Bel Fanout'].Trim(); CLOCK_NETWORK_POWER_W = $power.Raw
            CONFIDENCE = $Confidence; ACTIVITY_BASIS = $ActivityBasis
            REPORT_SECTION = '3.2 By Clock Domain'; DEPTH = $depth; IS_SUMMARY_ROOT = ($depth -eq 0)
            NORMALIZED_DOMAIN = if ($depth -eq 0) { Semantic-ClockDomain $name } else { '' }
            POWER_VALUE_W = if ($null -ne $power.Value) { Decimal-Text $power.Value 6 } else { '' }
            POWER_LOWER_BOUND_W = Decimal-Text $power.Lower 6
            POWER_UPPER_BOUND_EXCLUSIVE_W = Decimal-Text $power.UpperExclusive 6
            REPORT_RESOLUTION_W = Decimal-Text $power.Resolution 6
            SOURCE_FILE = $SourceFile; SOURCE_LINE = $row.LineNumber
        })
    }
    return $output.ToArray()
}

function Parse-ReportIoRows {
    param([string]$Role, [string]$SourceFile, [string[]]$Lines)
    $header = Find-HeaderIndex $Lines @('Pin Number', 'Signal Name', 'Use', 'IO Standard', 'IO Bank')
    if ($header -lt 0) { Fail-Closed "$Role report_io table header is missing" }
    $rows = Read-TableRows $Lines $header
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($row in $rows) {
        $signal = $row.Cells['Signal Name'].Trim()
        $bank = $row.Cells['IO Bank'].Trim()
        if ([string]::IsNullOrWhiteSpace($signal) -or $bank -notmatch '^\d+$') { continue }
        $category = 'OTHER'
        if ($signal -match '^nvp_(scl|sda)$') { $category = 'NVP_I2C' }
        elseif ($signal -match '^nvp_(rst|mpp)') { $category = 'NVP_CONTROL_STATUS' }
        elseif ($signal -match '^(vclk|vdo)') { $category = 'NVP_VIDEO' }
        elseif ($signal -match '^(pci_exp|sys_clk)') { $category = 'PCIE' }
        $output.Add([pscustomobject]@{
            IMAGE_ROLE = $Role; PORT = $signal; PACKAGE_PIN = $row.Cells['Pin Number'].Trim()
            DIRECTION = $row.Cells['Use'].Trim(); IOSTANDARD = $row.Cells['IO Standard'].Trim()
            DRIVE = $row.Cells['Drive (mA)'].Trim(); SLEW = $row.Cells['Slew'].Trim()
            PULLTYPE = $row.Cells['Pull Type'].Trim(); INPUT_OUTPUT_BIDIR = $row.Cells['Use'].Trim()
            IO_BANK = $bank; CLOCK_ASSOCIATION = 'NOT_EMITTED_BY_REPORT_IO'
            HIERARCHICAL_FUNCTIONAL_CATEGORY = $category
            SOURCE_FILE = $SourceFile; SOURCE_LINE = $row.LineNumber
        })
    }
    return $output.ToArray()
}

function Get-ActivityBasis {
    param([string[]]$Lines)
    $clock = Confidence-Entry $Lines 'Clock nodes activity'
    $io = Confidence-Entry $Lines 'I/O nodes activity'
    $internal = Confidence-Entry $Lines 'Internal nodes activity'
    if ([string]::IsNullOrWhiteSpace($clock) -or [string]::IsNullOrWhiteSpace($io) -or [string]::IsNullOrWhiteSpace($internal)) {
        Fail-Closed 'mandatory power-activity confidence details are missing'
    }
    $setting = Table-Scalar $Lines 'Setting File'
    $saif = Table-Scalar $Lines 'Simulation Activity File'
    return "SETTING_FILE=$setting;SAIF=$saif;DEFAULT_VECTORLESS_PROPAGATION;CLOCK=$clock;IO=$io;INTERNAL=$internal"
}

function Read-RoleReport {
    param(
        [string]$Role,
        [string]$Directory,
        [string]$ExpectedDesign
    )
    $power = Get-UniqueCompletePowerReport $Directory
    $io = Get-UniqueReportIo $Directory
    $lines = [System.IO.File]::ReadAllLines($power.File.FullName)
    $ioLines = [System.IO.File]::ReadAllLines($io.File.FullName)
    $tool = Require-Scalar (Header-Scalar $lines 'Tool Version') "$Role Tool Version"
    $design = Require-Scalar (Header-Scalar $lines 'Design') "$Role Design"
    $device = Require-Scalar (Header-Scalar $lines 'Device') "$Role Device"
    $state = Require-Scalar (Header-Scalar $lines 'Design State') "$Role Design State"
    if ($tool -notmatch 'Vivado v\.2025\.2.*Build 6299465') { Fail-Closed "$Role wrong Vivado build: $tool" }
    if ($design -ne $ExpectedDesign) { Fail-Closed "$Role wrong design: $design" }
    if ($device -ne 'xc7a35tcsg325-2') { Fail-Closed "$Role wrong device: $device" }
    if ($state -ne 'routed') { Fail-Closed "$Role checkpoint/report is not routed: $state" }
    $confidence = Require-Scalar (Table-Scalar $lines 'Confidence Level') "$Role confidence"
    $activity = Get-ActivityBasis $lines
    return [pscustomobject]@{
        Role = $Role; Directory = $Directory; PowerFile = $power.File.FullName; PowerLines = $lines
        IoFile = $io.File.FullName; IoLines = $ioLines; Tool = $tool; Design = $design; Device = $device
        State = $state; Grade = Header-Scalar $lines 'Grade'; Process = Header-Scalar $lines 'Process'
        Characterization = Header-Scalar $lines 'Characterization'; Confidence = $confidence; ActivityBasis = $activity
        Supply = Parse-SupplyRows $Role $power.File.FullName $lines $confidence $activity
        Hierarchy = Parse-HierarchyRows $Role $power.File.FullName $lines
        Clocks = Parse-ClockRows $Role $power.File.FullName $lines $confidence $activity
        IoRows = Parse-ReportIoRows $Role $io.File.FullName $ioLines
        DynamicPower = Parse-NumericToken (Require-Scalar (Table-Scalar $lines 'Dynamic (W)') "$Role Dynamic power")
        TotalPower = Parse-NumericToken (Require-Scalar (Table-Scalar $lines 'Total On-Chip Power (W)') "$Role Total power")
    }
}

function Export-CsvClosed {
    param(
        [object[]]$Rows,
        [string]$Path,
        [string[]]$Headers
    )
    if ($Rows.Count -gt 0) { $Rows | Select-Object $Headers | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8 }
    else { [System.IO.File]::WriteAllText($Path, (($Headers | ForEach-Object { '"' + $_.Replace('"','""') + '"' }) -join ',') + "`r`n", [System.Text.UTF8Encoding]::new($false)) }
}

function Exact-DecimalFromRow {
    param([object]$Row, [string]$Property)
    $token = Parse-NumericToken ([string]$Row.$Property)
    if ($token.Kind -ne 'EXACT_DISPLAY') { Fail-Closed "normalization requires exact displayed value for $($Row.HIERARCHY_PATH)::$Property; got $($token.Raw)" }
    return $token.Value
}

function Unique-HierarchyPath {
    param([object[]]$Rows, [string]$Path)
    $matches = @($Rows | Where-Object { $_.HIERARCHY_PATH -eq $Path })
    if ($matches.Count -ne 1) { Fail-Closed "expected exactly one hierarchy row $Path; found $($matches.Count)" }
    return $matches[0]
}

function Add-NormalizedRow {
    param(
        [System.Collections.Generic.List[object]]$List,
        [string]$Role, [string]$View, [string]$Category, [decimal]$Power,
        [string]$OwnerPath, [decimal]$EmbeddedClockIp, [string]$Method
    )
    $List.Add([pscustomobject]@{
        IMAGE_ROLE = $Role; VIEW = $View; CATEGORY = $Category
        POWER_W = Decimal-Text $Power 6; OWNER_PATH = $OwnerPath
        EMBEDDED_CLOCK_IP_W = Decimal-Text $EmbeddedClockIp 6
        METHOD = $Method; REPORT_RESOLUTION_W = '0.001000'
    })
}

function Normalize-Hierarchy {
    param([object]$RoleReport)
    $rows = $RoleReport.Hierarchy
    $top = $RoleReport.Design
    $root = Unique-HierarchyPath $rows $top
    if ($RoleReport.Role -eq 'FORMAL_PHASE2_FAIL_CONTROL') {
        $transport = Unique-HierarchyPath $rows "$top/XDMA"
        $capture = Unique-HierarchyPath $rows "$top/CAPTURE_SUBSYSTEM"
        $auto = Unique-HierarchyPath $rows "$top/NVP_AUTOINIT"
        $physical = Unique-HierarchyPath $rows "$top/NVP_PHYSICAL_FRONTEND"
        $control = Unique-HierarchyPath $rows "$top/AXI_LITE_HOST_BRIDGE"
    }
    else {
        $transport = Unique-HierarchyPath $rows "$top/pcie7_g0p8c0_support_i"
        $capture = Unique-HierarchyPath $rows "$top/app/PIO/PIO_EP_inst/G0P8C2_CAPTURE"
        $auto = Unique-HierarchyPath $rows "$top/NVP_AUTOINIT"
        $physical = Unique-HierarchyPath $rows "$top/NVP_PHYSICAL_FRONTEND"
        $control = Unique-HierarchyPath $rows "$top/app/PIO/PIO_EP_inst/COMPLETER"
    }
    $rootP = Exact-DecimalFromRow $root 'TOTAL_DYNAMIC_POWER_W'
    $transportP = Exact-DecimalFromRow $transport 'TOTAL_DYNAMIC_POWER_W'
    $captureP = Exact-DecimalFromRow $capture 'TOTAL_DYNAMIC_POWER_W'
    $autoP = Exact-DecimalFromRow $auto 'TOTAL_DYNAMIC_POWER_W'
    $physicalP = Exact-DecimalFromRow $physical 'TOTAL_DYNAMIC_POWER_W'
    $controlP = Exact-DecimalFromRow $control 'TOTAL_DYNAMIC_POWER_W'
    $transportClockIp = Exact-DecimalFromRow $transport 'CLOCK_IP_W'
    $captureClockIp = Exact-DecimalFromRow $capture 'CLOCK_IP_W'
    $autoClockIp = Exact-DecimalFromRow $auto 'CLOCK_IP_W'
    $physicalClockIp = Exact-DecimalFromRow $physical 'CLOCK_IP_W'
    $controlClockIp = Exact-DecimalFromRow $control 'CLOCK_IP_W'
    $ownerSum = $transportP + $captureP + $autoP + $physicalP + $controlP
    $other = $rootP - $ownerSum
    if ($other -lt 0) { Fail-Closed "$($RoleReport.Role) normalized owner rows exceed root dynamic power" }
    if ([decimal]::Abs($rootP - $RoleReport.DynamicPower.Value) -gt $script:PowerResolutionW) {
        Fail-Closed "$($RoleReport.Role) hierarchy root does not reconcile to summary dynamic power"
    }
    $list = New-Object System.Collections.Generic.List[object]
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'TRANSPORT' $transportP $transport.HIERARCHY_PATH $transportClockIp 'EXACT_SELECTED_HIERARCHY_OWNER_ROW'
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'CAPTURE' $captureP $capture.HIERARCHY_PATH $captureClockIp 'EXACT_SELECTED_HIERARCHY_OWNER_ROW'
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'NVP_AUTOINIT' $autoP $auto.HIERARCHY_PATH $autoClockIp 'EXACT_SELECTED_HIERARCHY_OWNER_ROW'
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'NVP_PHYSICAL_FRONTEND' $physicalP $physical.HIERARCHY_PATH $physicalClockIp 'EXACT_SELECTED_HIERARCHY_OWNER_ROW'
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'CONTROL' $controlP $control.HIERARCHY_PATH $controlClockIp 'EXACT_SELECTED_HIERARCHY_OWNER_ROW'
    Add-NormalizedRow $list $RoleReport.Role 'FUNCTIONAL_OWNER_TOTAL' 'OTHER' $other $top 0 'ROOT_MINUS_MUTUALLY_EXCLUSIVE_SELECTED_OWNER_ROWS'
    $clocking = $transportClockIp + $captureClockIp + $autoClockIp + $physicalClockIp + $controlClockIp
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'TRANSPORT' ($transportP - $transportClockIp) $transport.HIERARCHY_PATH $transportClockIp 'OWNER_TOTAL_MINUS_OWNER_CLOCK_IP_COLUMN'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'CAPTURE' ($captureP - $captureClockIp) $capture.HIERARCHY_PATH $captureClockIp 'OWNER_TOTAL_MINUS_OWNER_CLOCK_IP_COLUMN'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'NVP_AUTOINIT' ($autoP - $autoClockIp) $auto.HIERARCHY_PATH $autoClockIp 'OWNER_TOTAL_MINUS_OWNER_CLOCK_IP_COLUMN'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'NVP_PHYSICAL_FRONTEND' ($physicalP - $physicalClockIp) $physical.HIERARCHY_PATH $physicalClockIp 'OWNER_TOTAL_MINUS_OWNER_CLOCK_IP_COLUMN'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'CONTROL' ($controlP - $controlClockIp) $control.HIERARCHY_PATH $controlClockIp 'OWNER_TOTAL_MINUS_OWNER_CLOCK_IP_COLUMN'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'CLOCKING_IP' $clocking $top $clocking 'SUM_OF_CLOCK_IP_COLUMNS_REMOVED_FROM_SELECTED_OWNER_ROWS'
    Add-NormalizedRow $list $RoleReport.Role 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' 'OTHER' $other $top 0 'ROOT_MINUS_MUTUALLY_EXCLUSIVE_SELECTED_OWNER_ROWS'
    $slicedSum = [decimal]0
    foreach ($row in @($list | Where-Object { $_.VIEW -eq 'MUTUALLY_EXCLUSIVE_RESOURCE_SLICED' })) {
        $slicedSum += [decimal]::Parse($row.POWER_W, $script:Invariant)
    }
    if ([decimal]::Abs($slicedSum - $rootP) -gt $script:PowerResolutionW) {
        Fail-Closed "$($RoleReport.Role) resource-sliced hierarchy fails reconciliation"
    }
    return $list.ToArray()
}

function Model-Class {
    param([decimal]$Rca, [decimal]$Phase, [decimal]$Resolution)
    $delta = $Phase - $Rca
    $abs = [decimal]::Abs($delta)
    $relative = $null
    if ($Rca -gt $Resolution) { $relative = ([decimal]100 * $abs) / $Rca }
    $clear = $abs -ge ([decimal]10 * $Resolution)
    if ($null -ne $relative) { $clear = $clear -and ($relative -ge [decimal]20) }
    if ($clear) {
        if ($delta -gt 0) { return 'CLEAR_INCREASE_PHASE2' }
        if ($delta -lt 0) { return 'CLEAR_DECREASE_PHASE2' }
    }
    $equal = $abs -le ([decimal]2 * $Resolution)
    if ($null -ne $relative) { $equal = $equal -and ($relative -le [decimal]5) }
    if ($equal) { return 'EQUAL_WITHIN_REPORT' }
    return 'INTERMEDIATE'
}

function Build-SupplyDeltas {
    param([object[]]$Supply)
    $total = @($Supply | Where-Object { $_.STATIC_OR_DYNAMIC_IF_REPORTED -eq 'TOTAL' })
    $names = @($total.RAW_SUPPLY_NAME | Sort-Object -Unique)
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($name in $names) {
        $r = @($total | Where-Object { $_.IMAGE_ROLE -eq 'RCA_PASS_CONTROL' -and $_.RAW_SUPPLY_NAME -eq $name })
        $p = @($total | Where-Object { $_.IMAGE_ROLE -eq 'FORMAL_PHASE2_FAIL_CONTROL' -and $_.RAW_SUPPLY_NAME -eq $name })
        if ($r.Count -ne 1 -or $p.Count -ne 1) { Fail-Closed "supply rail row mismatch for $name" }
        $ri = [decimal]::Parse($r[0].ESTIMATED_CURRENT_A, $script:Invariant)
        $pi = [decimal]::Parse($p[0].ESTIMATED_CURRENT_A, $script:Invariant)
        $rw = [decimal]::Parse($r[0].ESTIMATED_POWER_W, $script:Invariant)
        $pw = [decimal]::Parse($p[0].ESTIMATED_POWER_W, $script:Invariant)
        $res = [decimal]::Parse($r[0].POWER_REPORT_RESOLUTION_W, $script:Invariant)
        if ($res -ne [decimal]::Parse($p[0].POWER_REPORT_RESOLUTION_W, $script:Invariant)) { Fail-Closed "power resolution mismatch for rail $name" }
        $pct = $null; if ($rw -gt $res) { $pct = ([decimal]100 * ($pw - $rw)) / $rw }
        $output.Add([pscustomobject]@{
            METRIC = $name; NORMALIZED_SUPPLY_CLASS = $r[0].NORMALIZED_SUPPLY_CLASS
            RC_A_VALUE = Decimal-Text $rw 6; PHASE2_VALUE = Decimal-Text $pw 6
            DELTA_PHASE2_MINUS_RCA = Decimal-Text ($pw - $rw) 6
            ABS_DELTA = Decimal-Text ([decimal]::Abs($pw - $rw)) 6
            PERCENT_DELTA_VS_RCA = Percent-Text $pct
            RC_A_CURRENT_A = Decimal-Text $ri 6; PHASE2_CURRENT_A = Decimal-Text $pi 6
            DELTA_CURRENT_A = Decimal-Text ($pi - $ri) 6; DELTA_POWER_W = Decimal-Text ($pw - $rw) 6
            REPORT_RESOLUTION = Decimal-Text $res 6
            METHOD = 'DERIVED_REPORTED_VOLTAGE_TIMES_REPORTED_TOTAL_CURRENT'
            CONFIDENCE = $r[0].REPORT_CONFIDENCE
            INTERPRETATION_ELIGIBLE = 'YES_LOW_VECTORLESS_CONFIDENCE'
            MODEL_CLASSIFICATION = Model-Class $rw $pw $res
        })
    }
    $mgtRows = @($output | Where-Object { $_.NORMALIZED_SUPPLY_CLASS -in @('MGTAVCC','MGTAVTT','MGTVCCAUX','OTHER_MGT_SUPPLY') })
    if ($mgtRows.Count -gt 0) {
        $rw = [decimal]0; $pw = [decimal]0; $res = [decimal]0
        foreach ($row in $mgtRows) {
            $rw += [decimal]::Parse($row.RC_A_VALUE, $script:Invariant)
            $pw += [decimal]::Parse($row.PHASE2_VALUE, $script:Invariant)
            $res += [decimal]::Parse($row.REPORT_RESOLUTION, $script:Invariant)
        }
        $pct = $null; if ($rw -gt $res) { $pct = ([decimal]100 * ($pw - $rw)) / $rw }
        $output.Add([pscustomobject]@{
            METRIC = 'MGT_SUPPLY_SUM'; NORMALIZED_SUPPLY_CLASS = 'MGT_SUPPLY_SUM'
            RC_A_VALUE = Decimal-Text $rw 6; PHASE2_VALUE = Decimal-Text $pw 6
            DELTA_PHASE2_MINUS_RCA = Decimal-Text ($pw - $rw) 6
            ABS_DELTA = Decimal-Text ([decimal]::Abs($pw - $rw)) 6
            PERCENT_DELTA_VS_RCA = Percent-Text $pct
            RC_A_CURRENT_A = 'NOT_ADDITIVE_DIFFERENT_VOLTAGES'; PHASE2_CURRENT_A = 'NOT_ADDITIVE_DIFFERENT_VOLTAGES'
            DELTA_CURRENT_A = 'NOT_ADDITIVE_DIFFERENT_VOLTAGES'; DELTA_POWER_W = Decimal-Text ($pw - $rw) 6
            REPORT_RESOLUTION = Decimal-Text $res 6; METHOD = 'SUM_OF_MUTUALLY_EXCLUSIVE_MGT_RAIL_POWER_ROWS'
            CONFIDENCE = 'LOW'; INTERPRETATION_ELIGIBLE = 'YES_LOW_VECTORLESS_CONFIDENCE'
            MODEL_CLASSIFICATION = Model-Class $rw $pw $res
        })
    }
    return $output.ToArray()
}

function Build-ClockDomainOutputs {
    param([object[]]$ClockRows)
    $roots = @($ClockRows | Where-Object { $_.IS_SUMMARY_ROOT -eq $true })
    $map = @($roots | ForEach-Object {
        [pscustomobject]@{
            IMAGE_ROLE = $_.IMAGE_ROLE; RAW_CLOCK_NAME = $_.RAW_CLOCK_NAME
            NORMALIZED_DOMAIN = $_.NORMALIZED_DOMAIN
            ROOT_TRACE_EVIDENCE = 'REPORT_POWER_ROOT_ROW_PLUS_SEMANTIC_CONNECTIVITY_REVIEW_REQUIRED'
            FREQUENCY_MHZ = $_.FREQUENCY_MHZ; RAW_POWER_TOKEN = $_.CLOCK_NETWORK_POWER_W
        }
    })
    $grouped = New-Object System.Collections.Generic.List[object]
    foreach ($group in $roots | Group-Object IMAGE_ROLE, NORMALIZED_DOMAIN) {
        $role = $group.Group[0].IMAGE_ROLE; $domain = $group.Group[0].NORMALIZED_DOMAIN
        $exact = [decimal]0; $subCount = 0
        foreach ($row in $group.Group) {
            $token = Parse-NumericToken $row.CLOCK_NETWORK_POWER_W
            if ($token.Kind -eq 'EXACT_DISPLAY') { $exact += $token.Value }
            elseif ($token.Kind -eq 'LESS_THAN') { $subCount++ }
            else { Fail-Closed "non-numeric clock power token $($token.Raw)" }
        }
        $upper = $exact + ([decimal]$subCount * $script:PowerResolutionW)
        $grouped.Add([pscustomobject]@{
            IMAGE_ROLE = $role; NORMALIZED_DOMAIN = $domain
            DISPLAYED_EXACT_SUM_W = Decimal-Text $exact 6
            SUBTHRESHOLD_ROW_COUNT = $subCount
            LOWER_BOUND_W = Decimal-Text $exact 6
            UPPER_BOUND_EXCLUSIVE_W = Decimal-Text $upper 6
            DISPLAY_EXPRESSION = if ($subCount -gt 0) { "$(Decimal-Text $exact 3) + $subCount*<0.001" } else { Decimal-Text $exact 3 }
            SUM_METHOD = 'DEPTH_ZERO_ROWS_ONLY_NO_PARENT_CHILD_DOUBLE_COUNT'
            REPORT_RESOLUTION_W = '0.001000'
        })
    }
    $deltas = New-Object System.Collections.Generic.List[object]
    $domains = @($grouped.NORMALIZED_DOMAIN | Sort-Object -Unique)
    foreach ($domain in $domains) {
        $r = @($grouped | Where-Object { $_.IMAGE_ROLE -eq 'RCA_PASS_CONTROL' -and $_.NORMALIZED_DOMAIN -eq $domain })
        $p = @($grouped | Where-Object { $_.IMAGE_ROLE -eq 'FORMAL_PHASE2_FAIL_CONTROL' -and $_.NORMALIZED_DOMAIN -eq $domain })
        $rl = [decimal]0; $ru = [decimal]0; $pl = [decimal]0; $pu = [decimal]0
        if ($r.Count -eq 1) { $rl=[decimal]::Parse($r[0].LOWER_BOUND_W,$script:Invariant);$ru=[decimal]::Parse($r[0].UPPER_BOUND_EXCLUSIVE_W,$script:Invariant) }
        if ($p.Count -eq 1) { $pl=[decimal]::Parse($p[0].LOWER_BOUND_W,$script:Invariant);$pu=[decimal]::Parse($p[0].UPPER_BOUND_EXCLUSIVE_W,$script:Invariant) }
        $deltaLow = $pl - $ru; $deltaHigh = $pu - $rl
        $classification = 'INTERVAL_REVIEW_REQUIRED'
        if (($r.Count -eq 0 -or $r[0].SUBTHRESHOLD_ROW_COUNT -eq 0) -and ($p.Count -eq 0 -or $p[0].SUBTHRESHOLD_ROW_COUNT -eq 0)) {
            $classification = Model-Class $rl $pl $script:PowerResolutionW
        }
        $deltas.Add([pscustomobject]@{
            NORMALIZED_DOMAIN = $domain; RC_A_VALUE = Decimal-Text $rl 6; PHASE2_VALUE = Decimal-Text $pl 6
            DELTA_PHASE2_MINUS_RCA = Decimal-Text ($pl-$rl) 6
            DELTA_LOWER_BOUND_W = Decimal-Text $deltaLow 6; DELTA_UPPER_BOUND_EXCLUSIVE_W = Decimal-Text $deltaHigh 6
            ABS_DELTA = if ($deltaLow -ge 0) { Decimal-Text $deltaLow 6 } elseif ($deltaHigh -le 0) { Decimal-Text ([decimal]::Abs($deltaHigh)) 6 } else { '0.000000' }
            PERCENT_DELTA_VS_RCA = if ($rl -gt $script:PowerResolutionW) { Percent-Text (([decimal]100*($pl-$rl))/$rl) } else { 'NOT_MEANINGFUL' }
            REPORT_RESOLUTION = '0.001000'; METHOD = 'DEPTH_ZERO_CLOCK_ROOT_INTERVAL_SUM'
            CONFIDENCE = 'LOW_VECTORLESS_OVERALL_CLOCK_ACTIVITY_HIGH'; INTERPRETATION_ELIGIBLE = 'YES_WITH_INTERVALS'
            MODEL_CLASSIFICATION = $classification
        })
    }
    return [pscustomobject]@{ Map=$map; Grouped=$grouped.ToArray(); Deltas=$deltas.ToArray() }
}

function Build-NormalizedDeltas {
    param([object[]]$Normalized)
    $output = New-Object System.Collections.Generic.List[object]
    $keys = @($Normalized | ForEach-Object { "$($_.VIEW)|$($_.CATEGORY)" } | Sort-Object -Unique)
    foreach ($key in $keys) {
        $parts=$key.Split('|');$view=$parts[0];$category=$parts[1]
        $r=@($Normalized|Where-Object{$_.IMAGE_ROLE -eq 'RCA_PASS_CONTROL' -and $_.VIEW -eq $view -and $_.CATEGORY -eq $category})
        $p=@($Normalized|Where-Object{$_.IMAGE_ROLE -eq 'FORMAL_PHASE2_FAIL_CONTROL' -and $_.VIEW -eq $view -and $_.CATEGORY -eq $category})
        if($r.Count-ne 1 -or $p.Count-ne 1){Fail-Closed "normalized hierarchy role mismatch for $key"}
        $rw=[decimal]::Parse($r[0].POWER_W,$script:Invariant);$pw=[decimal]::Parse($p[0].POWER_W,$script:Invariant)
        $pct=$null;if($rw-gt $script:PowerResolutionW){$pct=([decimal]100*($pw-$rw))/$rw}
        $output.Add([pscustomobject]@{
            VIEW=$view;CATEGORY=$category;RC_A_VALUE=Decimal-Text $rw 6;PHASE2_VALUE=Decimal-Text $pw 6
            DELTA_PHASE2_MINUS_RCA=Decimal-Text ($pw-$rw) 6;ABS_DELTA=Decimal-Text ([decimal]::Abs($pw-$rw)) 6
            PERCENT_DELTA_VS_RCA=Percent-Text $pct;REPORT_RESOLUTION='0.001000'
            METHOD='EXACT_NORMALIZED_HIERARCHY_OWNER_OR_RESOURCE_SLICE';CONFIDENCE='LOW_VECTORLESS'
            INTERPRETATION_ELIGIBLE='YES_LOW_VECTORLESS_CONFIDENCE';MODEL_CLASSIFICATION=Model-Class $rw $pw $script:PowerResolutionW
        })
    }
    return $output.ToArray()
}

function Build-AssumptionRows {
    param([object]$Formal,[object]$Rca)
    $keys = [ordered]@{
        'TOOL_VERSION'=@($Formal.Tool,$Rca.Tool,'YES');'DEVICE'=@($Formal.Device,$Rca.Device,'YES')
        'DESIGN_STATE'=@($Formal.State,$Rca.State,'YES');'GRADE'=@($Formal.Grade,$Rca.Grade,'YES')
        'PROCESS'=@($Formal.Process,$Rca.Process,'YES');'CHARACTERIZATION'=@($Formal.Characterization,$Rca.Characterization,'YES')
        'AMBIENT_TEMP_C'=@((Table-Scalar $Formal.PowerLines 'Ambient Temp (C)'),(Table-Scalar $Rca.PowerLines 'Ambient Temp (C)'),'YES')
        'THETA_JA_C_PER_W'=@((Table-Scalar $Formal.PowerLines 'ThetaJA (C/W)'), (Table-Scalar $Rca.PowerLines 'ThetaJA (C/W)'),'YES')
        'AIRFLOW_LFM'=@((Table-Scalar $Formal.PowerLines 'Airflow (LFM)'), (Table-Scalar $Rca.PowerLines 'Airflow (LFM)'),'YES')
        'HEAT_SINK'=@((Table-Scalar $Formal.PowerLines 'Heat Sink'), (Table-Scalar $Rca.PowerLines 'Heat Sink'),'YES')
        'THETA_SA_C_PER_W'=@((Table-Scalar $Formal.PowerLines 'ThetaSA (C/W)'), (Table-Scalar $Rca.PowerLines 'ThetaSA (C/W)'),'YES')
        'BOARD_SELECTION'=@((Table-Scalar $Formal.PowerLines 'Board Selection'), (Table-Scalar $Rca.PowerLines 'Board Selection'),'YES')
        'BOARD_LAYERS'=@((Table-Scalar $Formal.PowerLines '# of Board Layers'), (Table-Scalar $Rca.PowerLines '# of Board Layers'),'YES')
        'BOARD_TEMP_C'=@((Table-Scalar $Formal.PowerLines 'Board Temperature (C)'), (Table-Scalar $Rca.PowerLines 'Board Temperature (C)'),'YES')
        'SETTING_FILE'=@((Table-Scalar $Formal.PowerLines 'Setting File'), (Table-Scalar $Rca.PowerLines 'Setting File'),'YES')
        'SIMULATION_ACTIVITY_FILE'=@((Table-Scalar $Formal.PowerLines 'Simulation Activity File'), (Table-Scalar $Rca.PowerLines 'Simulation Activity File'),'YES')
        'ACTIVITY_BASIS'=@($Formal.ActivityBasis,$Rca.ActivityBasis,'YES')
        'OVERALL_CONFIDENCE'=@($Formal.Confidence,$Rca.Confidence,'YES')
        'REPORT_METHOD'=@('report_power -hier all -hierarchical_depth 0 -l 0 -verbose','report_power -hier all -hierarchical_depth 0 -l 0 -verbose','YES')
        'VECTORLESS_PROPAGATION'=@('ENABLED_DEFAULT_NO_NO_PROPAGATION_OPTION','ENABLED_DEFAULT_NO_NO_PROPAGATION_OPTION','YES')
    }
    $rows=New-Object System.Collections.Generic.List[object]
    foreach($key in $keys.Keys){
        $v=$keys[$key]
        if($v[2] -eq 'YES' -and ([string]::IsNullOrWhiteSpace([string]$v[0]) -or [string]::IsNullOrWhiteSpace([string]$v[1]))){Fail-Closed "mandatory comparable assumption is missing: $key"}
        $match=($v[0] -eq $v[1])
        $rows.Add([pscustomobject]@{FIELD=$key;FORMAL_PHASE2=$v[0];RCA=$v[1];MATCH=if($match){'YES'}else{'NO'};MATERIAL=$v[2]})
    }
    $formalVolt=@($Formal.Supply|Where-Object{$_.STATIC_OR_DYNAMIC_IF_REPORTED -eq 'TOTAL'})
    $rcaVolt=@($Rca.Supply|Where-Object{$_.STATIC_OR_DYNAMIC_IF_REPORTED -eq 'TOTAL'})
    foreach($name in @($formalVolt.RAW_SUPPLY_NAME|Sort-Object -Unique)){
        $f=@($formalVolt|Where-Object{$_.RAW_SUPPLY_NAME -eq $name});$r=@($rcaVolt|Where-Object{$_.RAW_SUPPLY_NAME -eq $name})
        if($f.Count-ne 1 -or $r.Count-ne 1){Fail-Closed "voltage assumption row mismatch $name"}
        $match=$f[0].VOLTAGE_V -eq $r[0].VOLTAGE_V
        $rows.Add([pscustomobject]@{FIELD="VOLTAGE::$name";FORMAL_PHASE2=$f[0].VOLTAGE_V;RCA=$r[0].VOLTAGE_V;MATCH=if($match){'YES'}else{'NO'};MATERIAL='YES'})
    }
    return $rows.ToArray()
}

$formal = Read-RoleReport 'FORMAL_PHASE2_FAIL_CONTROL' $FormalReportDir 'ahd_capture_top_xdma'
$rca = Read-RoleReport 'RCA_PASS_CONTROL' $RcaReportDir 'ahd_capture_top_pcie'

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$allSupply = @($formal.Supply) + @($rca.Supply)
$supplyDelta = Build-SupplyDeltas $allSupply
$allHierarchy = @($formal.Hierarchy) + @($rca.Hierarchy)
$normalized = @(Normalize-Hierarchy $formal) + @(Normalize-Hierarchy $rca)
$hierDelta = Build-NormalizedDeltas $normalized
$allClocks = @($formal.Clocks) + @($rca.Clocks)
$clockOutputs = Build-ClockDomainOutputs $allClocks
$allIo = @($formal.IoRows) + @($rca.IoRows)
$assumptions = Build-AssumptionRows $formal $rca
$materialMismatch = @($assumptions | Where-Object { $_.MATERIAL -eq 'YES' -and $_.MATCH -ne 'YES' })
$assumptionsComparable = if ($materialMismatch.Count -eq 0) { 'YES' } else { 'NO' }

$supplyHeaders=@('IMAGE_ROLE','RAW_SUPPLY_NAME','NORMALIZED_SUPPLY_CLASS','VOLTAGE_V','ESTIMATED_CURRENT_A','ESTIMATED_POWER_W','STATIC_OR_DYNAMIC_IF_REPORTED','RAW_CURRENT_TOKEN','CURRENT_REPORT_RESOLUTION_A','POWER_REPORT_RESOLUTION_W','REPORT_SECTION','REPORT_CONFIDENCE','ACTIVITY_BASIS','POWER_METHOD','SOURCE_FILE','SOURCE_LINE_OR_TABLE')
$deltaHeaders=@('METRIC','NORMALIZED_SUPPLY_CLASS','RC_A_VALUE','PHASE2_VALUE','DELTA_PHASE2_MINUS_RCA','ABS_DELTA','PERCENT_DELTA_VS_RCA','RC_A_CURRENT_A','PHASE2_CURRENT_A','DELTA_CURRENT_A','DELTA_POWER_W','REPORT_RESOLUTION','METHOD','CONFIDENCE','INTERPRETATION_ELIGIBLE','MODEL_CLASSIFICATION')
$ioHeaders=@('IMAGE_ROLE','PORT','PACKAGE_PIN','DIRECTION','IOSTANDARD','DRIVE','SLEW','PULLTYPE','INPUT_OUTPUT_BIDIR','IO_BANK','CLOCK_ASSOCIATION','HIERARCHICAL_FUNCTIONAL_CATEGORY','SOURCE_FILE','SOURCE_LINE')
$clockHeaders=@('IMAGE_ROLE','RAW_CLOCK_NAME','SOURCE_PIN_OR_PORT','PERIOD_NS','FREQUENCY_MHZ','FANOUT','CLOCK_NETWORK_POWER_W','CONFIDENCE','ACTIVITY_BASIS','REPORT_SECTION','DEPTH','IS_SUMMARY_ROOT','NORMALIZED_DOMAIN','POWER_VALUE_W','POWER_LOWER_BOUND_W','POWER_UPPER_BOUND_EXCLUSIVE_W','REPORT_RESOLUTION_W','SOURCE_FILE','SOURCE_LINE')
$clockMapHeaders=@('IMAGE_ROLE','RAW_CLOCK_NAME','NORMALIZED_DOMAIN','ROOT_TRACE_EVIDENCE','FREQUENCY_MHZ','RAW_POWER_TOKEN')
$clockGroupHeaders=@('IMAGE_ROLE','NORMALIZED_DOMAIN','DISPLAYED_EXACT_SUM_W','SUBTHRESHOLD_ROW_COUNT','LOWER_BOUND_W','UPPER_BOUND_EXCLUSIVE_W','DISPLAY_EXPRESSION','SUM_METHOD','REPORT_RESOLUTION_W')
$clockDeltaHeaders=@('NORMALIZED_DOMAIN','RC_A_VALUE','PHASE2_VALUE','DELTA_PHASE2_MINUS_RCA','DELTA_LOWER_BOUND_W','DELTA_UPPER_BOUND_EXCLUSIVE_W','ABS_DELTA','PERCENT_DELTA_VS_RCA','REPORT_RESOLUTION','METHOD','CONFIDENCE','INTERPRETATION_ELIGIBLE','MODEL_CLASSIFICATION')
$hierHeaders=@('IMAGE_ROLE','HIERARCHY_PATH','RAW_NAME','DEPTH','TOTAL_DYNAMIC_POWER_W','CLOCK_W','IO_W','SIGNAL_W','LOGIC_W','BRAM_W','CLOCK_IP_W','GT_W','PCIE_W','OTHER_REPORTED_CATEGORIES','POWER_VALUE_W','POWER_LOWER_BOUND_W','POWER_UPPER_BOUND_EXCLUSIVE_W','REPORT_RESOLUTION_W','SOURCE_TABLE','SOURCE_FILE','SOURCE_LINE')
$normHeaders=@('IMAGE_ROLE','VIEW','CATEGORY','POWER_W','OWNER_PATH','EMBEDDED_CLOCK_IP_W','METHOD','REPORT_RESOLUTION_W')
$normDeltaHeaders=@('VIEW','CATEGORY','RC_A_VALUE','PHASE2_VALUE','DELTA_PHASE2_MINUS_RCA','ABS_DELTA','PERCENT_DELTA_VS_RCA','REPORT_RESOLUTION','METHOD','CONFIDENCE','INTERPRETATION_ELIGIBLE','MODEL_CLASSIFICATION')

Export-CsvClosed $allSupply (Join-Path $OutputDir 'SUPPLY_RAILS_ALL.csv') $supplyHeaders
Export-CsvClosed $supplyDelta (Join-Path $OutputDir 'SUPPLY_RAIL_DELTA.csv') $deltaHeaders
Export-CsvClosed @($allIo|Where-Object{$_.IO_BANK -eq '14'}) (Join-Path $OutputDir 'IO_BANK_14_INVENTORY.csv') $ioHeaders
Export-CsvClosed @($allIo|Where-Object{$_.IO_BANK -eq '16'}) (Join-Path $OutputDir 'IO_BANK_16_INVENTORY.csv') $ioHeaders
Export-CsvClosed $allClocks (Join-Path $OutputDir 'CLOCK_NETWORK_POWER_RAW.csv') $clockHeaders
Export-CsvClosed $clockOutputs.Map (Join-Path $OutputDir 'CLOCK_DOMAIN_MAP.csv') $clockMapHeaders
Export-CsvClosed $clockOutputs.Grouped (Join-Path $OutputDir 'CLOCK_NETWORK_POWER_BY_DOMAIN.csv') $clockGroupHeaders
Export-CsvClosed $clockOutputs.Deltas (Join-Path $OutputDir 'CLOCK_NETWORK_DOMAIN_DELTA.csv') $clockDeltaHeaders
Export-CsvClosed $allHierarchy (Join-Path $OutputDir 'HIERARCHY_POWER_RAW.csv') $hierHeaders
Export-CsvClosed $normalized (Join-Path $OutputDir 'HIERARCHY_POWER_NORMALIZED.csv') $normHeaders
Export-CsvClosed $hierDelta (Join-Path $OutputDir 'HIERARCHY_NORMALIZED_DELTA.csv') $normDeltaHeaders
Export-CsvClosed $assumptions (Join-Path $OutputDir 'POWER_ASSUMPTION_COMPARISON.csv') @('FIELD','FORMAL_PHASE2','RCA','MATCH','MATERIAL')

$logicDomainUnavailable=@([pscustomobject]@{STATUS='NOT_DIRECTLY_AVAILABLE_FROM_UNMODIFIED_DCP';REASON='Vivado report_power By Clock Domain reports clock-network power, not total cell dynamic power by clock ownership.';SUBSTITUTE='CLOCK_NETWORK_POWER_BY_DOMAIN plus non-power sequential/utilization inventories when separately emitted by Tcl.'})
Export-CsvClosed $logicDomainUnavailable (Join-Path $OutputDir 'LOGIC_POWER_BY_CLOCK_DOMAIN.csv') @('STATUS','REASON','SUBSTITUTE')
$nonPowerFallback=@([pscustomobject]@{STATUS='NOT_EMITTED_BY_POWER_REPORT';IMAGE_ROLE='BOTH';NORMALIZED_DOMAIN='NOT_APPLICABLE';COUNT='';SOURCE='A separate read-only Tcl connectivity inventory is required; this parser never treats utilization as power.'})
Export-CsvClosed $nonPowerFallback (Join-Path $OutputDir 'SEQUENTIAL_CELL_COUNT_BY_CLOCK_DOMAIN.csv') @('STATUS','IMAGE_ROLE','NORMALIZED_DOMAIN','COUNT','SOURCE')
Export-CsvClosed $nonPowerFallback (Join-Path $OutputDir 'UTILIZATION_BY_CLOCK_DOMAIN.csv') @('STATUS','IMAGE_ROLE','NORMALIZED_DOMAIN','COUNT','SOURCE')

$vccint=@($supplyDelta|Where-Object{$_.NORMALIZED_SUPPLY_CLASS -eq 'VCCINT'})[0]
$vccaux=@($supplyDelta|Where-Object{$_.NORMALIZED_SUPPLY_CLASS -eq 'VCCAUX'})[0]
$mgt=@($supplyDelta|Where-Object{$_.NORMALIZED_SUPPLY_CLASS -eq 'MGT_SUPPLY_SUM'})[0]
$bankExplicitFormal=Join-Path $FormalReportDir 'EXPLICIT_IOBANK_POWER.csv'
$bankExplicitRca=Join-Path $RcaReportDir 'EXPLICIT_IOBANK_POWER.csv'
$bank14Available=(Test-Path -LiteralPath $bankExplicitFormal) -and (Test-Path -LiteralPath $bankExplicitRca)
$decisionCase='CASE_D_INCONCLUSIVE_REPORT_POWER_LIMITATION'
if($assumptionsComparable -ne 'YES'){$decisionCase='CASE_E_INCONCLUSIVE_ASSUMPTION_MISMATCH'}
elseif($bank14Available){$decisionCase='BANK14_EXPLICIT_FILE_PRESENT_REQUIRES_SEPARATE_DOCUMENTED_PROPERTY_VALIDATION'}
$onChipContext=if($vccint.MODEL_CLASSIFICATION -eq 'CLEAR_INCREASE_PHASE2' -or $vccaux.MODEL_CLASSIFICATION -eq 'CLEAR_INCREASE_PHASE2'){'SUPPORTED_BY_CLEAR_CORE_RAIL_CLOCK_AND_HIERARCHY_DELTAS'}else{'NOT_CLEAR_FROM_CORE_RAILS'}
$decision=@"
# Decision matrix result

~~~text
POWER_ASSUMPTIONS_COMPARABLE=$assumptionsComparable

VCCO_14_DIRECT_BREAKDOWN_AVAILABLE=$(if($bank14Available){'PENDING_DOCUMENTED_EXPLICIT_OBJECT_VALIDATION'}else{'NO'})
VCCO_14_BREAKDOWN_METHOD=$(if($bank14Available){'EXPLICIT_FILE_PRESENT_NOT_AUTO_ACCEPTED'}else{'NOT_AVAILABLE_FROM_UNMODIFIED_DCP'})
VCCO_14_MODEL_CLASSIFICATION=$(if($bank14Available){'PENDING_VALIDATION'}else{'NOT_AVAILABLE'})

VCCO_16_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_16_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_16_MODEL_CLASSIFICATION=NOT_AVAILABLE

VCCINT_MODEL_CLASSIFICATION=$($vccint.MODEL_CLASSIFICATION)
VCCAUX_MODEL_CLASSIFICATION=$($vccaux.MODEL_CLASSIFICATION)
MGT_MODEL_CLASSIFICATION=$($mgt.MODEL_CLASSIFICATION)

POWER_BREAKDOWN_DECISION_CASE=$decisionCase
STATIC_OR_LOW_FREQUENCY_VCCO_LOADING_HYPOTHESIS=INCONCLUSIVE_REPORT_POWER_LIMITATION
STATIC_FPGA_IO_BANK14_DC_LOAD_DIFFERENCE=INCONCLUSIVE_PER_BANK_VCCO_UNAVAILABLE
ON_CHIP_SWITCHING_RETURN_PATH_CONTEXT=$onChipContext

BOARD_VCCO_DROOP_PROVEN=NO
GROUND_BOUNCE_PROVEN=NO
SSN_PROVEN=NO
ANALOG_I2C_MARGIN_PROVEN=NO
ROOT_CAUSE_SOLELY_PROVEN=NO
~~~

Aggregate Vcco33 is never substituted for a bank-14 or bank-16 result. Case D recommends direct bank-14 Vcco measurement or a separately authorized activity-aware analysis.
"@
[System.IO.File]::WriteAllText((Join-Path $OutputDir 'DECISION_MATRIX_RESULT.md'),$decision,[System.Text.UTF8Encoding]::new($false))

$summary=[ordered]@{
    ParserStatus='PASS'
    FormalPowerReport=$formal.PowerFile
    RcaPowerReport=$rca.PowerFile
    FormalReportIo=$formal.IoFile
    RcaReportIo=$rca.IoFile
    PowerAssumptionsComparable=$assumptionsComparable
    FormalConfidence=$formal.Confidence
    RcaConfidence=$rca.Confidence
    FormalDynamicPowerW=Decimal-Text $formal.DynamicPower.Value 6
    RcaDynamicPowerW=Decimal-Text $rca.DynamicPower.Value 6
    DecisionCase=$decisionCase
    Vcco14BreakdownMethod=if($bank14Available){'PENDING_EXPLICIT_PROPERTY_VALIDATION'}else{'NOT_AVAILABLE_FROM_UNMODIFIED_DCP'}
    Vcco16BreakdownMethod='NOT_AVAILABLE_FROM_UNMODIFIED_DCP'
}
$summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDir 'PARSER_SUMMARY.json') -Encoding UTF8

Write-Output "POWER_REPORT_PARSER=PASS"
Write-Output "OUTPUT_DIR=$OutputDir"
Write-Output "POWER_ASSUMPTIONS_COMPARABLE=$assumptionsComparable"
Write-Output "POWER_BREAKDOWN_DECISION_CASE=$decisionCase"
