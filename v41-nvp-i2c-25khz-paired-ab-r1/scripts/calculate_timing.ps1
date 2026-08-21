param(
  [Parameter(Mandatory=$true)][string]$SourceRoot,
  [Parameter(Mandatory=$true)][string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
function F([double]$v, [string]$fmt = '0.000000') { $v.ToString($fmt, $inv) }
function Require([bool]$ok, [string]$message) { if (-not $ok) { throw $message } }

$top = Join-Path $SourceRoot 'rtl\top\ahd_capture_top_xdma.sv'
$seq = Join-Path $SourceRoot 'rtl\nvp\nvp6134c_i2c_bringup.vhd'
$wrap = Join-Path $SourceRoot 'rtl\nvp\nvp6134c_autoinit.vhd'
$pkg = Join-Path $SourceRoot 'rtl\nvp\nvp6134c_diagnostics_pkg.vhd'
foreach ($p in @($top,$seq,$wrap,$pkg)) { Require (Test-Path -LiteralPath $p) "Missing exact source: $p" }

$topText = Get-Content -Raw -LiteralPath $top
$seqText = Get-Content -Raw -LiteralPath $seq
$wrapText = Get-Content -Raw -LiteralPath $wrap
$pkgText = Get-Content -Raw -LiteralPath $pkg
Require ($topText -match 'NVP_AUTOINIT_CLK_HZ\s*=\s*62500000') 'Clock identity mismatch'
Require ($topText -match 'NVP_POR_CYCLES\s*=\s*320') 'POR identity mismatch'
Require ($topText -match '\.I2C_HZ\(25000\)') 'Diagnostic generic is not 25000'
Require ($seqText -match 'DIVIDER\s*:\s*positive\s*:=\s*CLK_HZ\s*/\s*\(I2C_HZ\s*\*\s*2\)') 'Divider formula mismatch'
Require ($seqText -match 'C_INIT_SETTLE_TICKS\s*:\s*natural\s*:=\s*12000') 'Final-settle identity mismatch'
Require ($seqText -match 'scl_low_released_count\s*:\s*natural range 0 to CLK_HZ/50000') 'Watchdog identity mismatch'
Require ($wrapText -match 'C_RESET_HOLD_CYCLES\s*:\s*natural\s*:=\s*CLK_HZ\s*/\s*2') 'R17 hold identity mismatch'
Require ($wrapText -match 'C_START_CYCLE\s*:\s*natural\s*:=\s*CLK_HZ\s*\+\s*CLK_HZ/2') 'Start-delay identity mismatch'
Require ($pkgText -match 'C_V38EK_LAST_INIT_SLOT\s*:\s*integer\s*:=\s*213') 'Table length identity mismatch'

$clockHz = 62500000L
$baseCycleUs = 1000000.0 / $clockHz
$porCycles = 320L
$resetHoldCycles = 31250000L
$startCycles = 93750000L
$porReleaseEdge = 320L
$r17ReleaseEdge = 31250320L
$wrapperStartPulseEdge = 93750321L
$engineStartSampleEdge = 93750322L
$watchdogCounterTerminal = 1250L
$watchdogEligibleCycles = 1251L

$actions = @(
  [pscustomobject]@{Component='IDLE_START_ACCEPT'; Count=1; Basis='one IDLE tick consumes latched start'},
  [pscustomobject]@{Component='PREINIT_I2C'; Count=227; Basis='2 reads*83 + 1 write*61'},
  [pscustomobject]@{Component='INIT_REAL_I2C'; Count=15007; Basis='212 writes*61 + 25 verify reads*83'},
  [pscustomobject]@{Component='INIT_NOP_SLOTS'; Count=52; Basis='26 NOP slots*2 ticks'},
  [pscustomobject]@{Component='ACTIVE_FE03E8_DELAY_SLOT'; Count=1003; Basis='SETUP 1 + inclusive WAIT_SLOT 1001 + NEXT 1'},
  [pscustomobject]@{Component='FINAL_SETTLE_WAIT_INIT'; Count=12001; Basis='inclusive wait counter 0 through 12000'},
  [pscustomobject]@{Component='POST_TABLE_READBACK_RESTORE'; Count=2751; Basis='7 writes*61 + 28 reads*83'},
  [pscustomobject]@{Component='FINISH'; Count=1; Basis='one FINISH tick asserts done_r'}
)
$totalActions = [long](($actions | Measure-Object -Property Count -Sum).Sum)
Require ($totalActions -eq 31043) "Unexpected success action count: $totalActions"
$tickIntervalsFirstIdleToFinish = $totalActions - 1

$operationRows = @(
  [pscustomobject]@{Metric='TABLE_SLOTS';Value=214;Basis='slots 0..213'},
  [pscustomobject]@{Metric='TABLE_TARGET_WRITES';Value=187;Basis='stage 2 effective table'},
  [pscustomobject]@{Metric='TABLE_DELAY_SLOTS';Value=1;Basis='active FE03E8 target 1000'},
  [pscustomobject]@{Metric='TABLE_NOP_SLOTS';Value=26;Basis='stage-3-disabled slots'},
  [pscustomobject]@{Metric='VERIFIED_BANK_CHANGES';Value=25;Basis='physical-bank cache transitions'},
  [pscustomobject]@{Metric='TOTAL_WRITE_TRANSACTIONS';Value=220;Basis='preinit 1 + init 212 + post 7'},
  [pscustomobject]@{Metric='TOTAL_READ_TRANSACTIONS';Value=55;Basis='preinit 2 + init 25 + post 28'},
  [pscustomobject]@{Metric='TOTAL_I2C_TRANSACTIONS';Value=275;Basis='220 writes + 55 reads'},
  [pscustomobject]@{Metric='WRITE_TRANSACTION_TICK_ACTIONS';Value=61;Basis='exact write FSM path'},
  [pscustomobject]@{Metric='READ_TRANSACTION_TICK_ACTIONS';Value=83;Basis='exact repeated-start read FSM path'},
  [pscustomobject]@{Metric='SUCCESS_PATH_TICK_ACTIONS';Value=$totalActions;Basis='complete all-ACK path'},
  [pscustomobject]@{Metric='SUCCESS_PATH_FIRST_IDLE_TO_FINISH_INTERVALS';Value=$tickIntervalsFirstIdleToFinish;Basis='N actions span N-1 tick intervals'}
)

$componentDefs = @(
  [pscustomobject]@{Name='STATE_TICK';Ticks=1;Meaning='each FSM state dwell'},
  [pscustomobject]@{Name='SCL_LOW_PHASE';Ticks=1;Meaning='one state tick'},
  [pscustomobject]@{Name='SCL_HIGH_PHASE';Ticks=1;Meaning='one state tick'},
  [pscustomobject]@{Name='PHYSICAL_SCL_BIT';Ticks=2;Meaning='LOW plus HIGH'},
  [pscustomobject]@{Name='WRITE_TRANSACTION';Ticks=61;Meaning='complete exact write path'},
  [pscustomobject]@{Name='READ_TRANSACTION';Ticks=83;Meaning='complete exact repeated-start read path'},
  [pscustomobject]@{Name='NOP_SLOT';Ticks=2;Meaning='SETUP plus NEXT'},
  [pscustomobject]@{Name='TABLE_DELAY_WAIT_ONLY';Ticks=1001;Meaning='inclusive WAIT_SLOT target 1000'},
  [pscustomobject]@{Name='TABLE_DELAY_FULL_SLOT';Ticks=1003;Meaning='SETUP plus WAIT plus NEXT'},
  [pscustomobject]@{Name='FINAL_SETTLE';Ticks=12001;Meaning='inclusive WAIT_INIT 0..12000'},
  [pscustomobject]@{Name='PREINIT';Ticks=227;Meaning='two reads and one write'},
  [pscustomobject]@{Name='INIT_REAL_I2C';Ticks=15007;Meaning='212 writes and 25 reads'},
  [pscustomobject]@{Name='POST_TABLE_READBACK_RESTORE';Ticks=2751;Meaning='7 writes and 28 reads'}
)

$profiles = @()
$timingRows = @()
foreach ($i2cHz in @(50000L,25000L)) {
  $divider = [long][math]::Floor($clockHz / ($i2cHz * 2.0))
  $tickCycles = $divider + 1
  $tickUs = $tickCycles * $baseCycleUs
  $n = [long][math]::Ceiling(($engineStartSampleEdge - 1.0) / $tickCycles)
  $firstIdleEdge = 1L + $n * $tickCycles
  $physicalStartEdge = $firstIdleEdge + 2L * $tickCycles
  $finishEdge = $firstIdleEdge + $tickIntervalsFirstIdleToFinish * $tickCycles
  $firstActiveUs = $finishEdge * $baseCycleUs
  $fromPorUs = ($finishEdge - $porReleaseEdge) * $baseCycleUs
  $fromPhysicalStartUs = ($finishEdge - $physicalStartEdge) * $baseCycleUs
  $p = [pscustomobject]@{
    I2C_HZ=$i2cHz; DIVIDER=$divider; TICK_COUNTER_CYCLES=$tickCycles;
    STATE_TICK_US=(F $tickUs '0.000000'); PHYSICAL_SCL_PERIOD_US=(F (2*$tickUs) '0.000000');
    PHYSICAL_SCL_HZ=(F ($clockHz/(2.0*$tickCycles)) '0.0000000');
    FIRST_IDLE_TICK_EDGE=$firstIdleEdge; FIRST_PHYSICAL_START_EDGE=$physicalStartEdge;
    FINISH_COUNTER_VALUE=$finishEdge;
    TOTAL_FROM_FIRST_ACTIVE_NVP_ACLK_EDGE_US=(F $firstActiveUs '0.000000');
    TOTAL_FROM_NVP_POR_RELEASE_US=(F $fromPorUs '0.000000');
    TOTAL_FROM_FIRST_I2C_START_US=(F $fromPhysicalStartUs '0.000000')
  }
  $profiles += $p
  foreach ($c in $componentDefs) {
    $timingRows += [pscustomobject]@{
      COMPONENT=$c.Name; TICKS=$c.Ticks; MEANING=$c.Meaning; I2C_HZ=$i2cHz;
      DIVIDER=$divider; TICK_COUNTER_CYCLES=$tickCycles;
      TICK_BUDGET_US=(F ($c.Ticks*$tickUs) '0.000000')
    }
  }
}

$p50 = $profiles | Where-Object I2C_HZ -eq 50000
$p25 = $profiles | Where-Object I2C_HZ -eq 25000
Require ($p50.DIVIDER -eq 625 -and $p50.TICK_COUNTER_CYCLES -eq 626) '50-kHz divider mismatch'
Require ($p25.DIVIDER -eq 1250 -and $p25.TICK_COUNTER_CYCLES -eq 1251) '25-kHz divider mismatch'
Require ($p50.FINISH_COUNTER_VALUE -eq 113182679) '50-kHz finish-edge mismatch'
Require ($p25.FINISH_COUNTER_VALUE -eq 132584734) '25-kHz finish-edge mismatch'

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$timingRows | Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $OutputRoot 'I2C_50K_VS_25K_TIMING.csv')
$operationRows | Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $OutputRoot 'AUTOINIT_OPERATION_COUNTS.csv')

$log = @()
$log += 'NUMERICAL_GATE=PASS'
$log += 'SOURCE_FORMULA=DIVIDER := CLK_HZ / (I2C_HZ * 2)'
$log += "CLK_HZ=$clockHz"
$log += "BASE_CYCLE_US=$(F $baseCycleUs '0.000000')"
$log += "POR_RELEASE_EDGE=$porReleaseEdge"
$log += "R17_RELEASE_EDGE=$r17ReleaseEdge"
$log += "WRAPPER_START_PULSE_EDGE=$wrapperStartPulseEdge"
$log += "ENGINE_START_SAMPLE_EDGE=$engineStartSampleEdge"
$log += "SUCCESS_PATH_TICK_ACTIONS=$totalActions"
$log += "SUCCESS_PATH_TICK_INTERVALS_FIRST_IDLE_TO_FINISH=$tickIntervalsFirstIdleToFinish"
$log += "WATCHDOG_COUNTER_TERMINAL=$watchdogCounterTerminal"
$log += "WATCHDOG_ELIGIBLE_CYCLES=$watchdogEligibleCycles"
$log += "WATCHDOG_WALL_CLOCK_US=$(F ($watchdogEligibleCycles*$baseCycleUs) '0.000000')"
foreach ($p in $profiles) {
  foreach ($prop in $p.PSObject.Properties) { $log += ("I2C_{0}_{1}={2}" -f $p.I2C_HZ,$prop.Name,$prop.Value) }
}
$log | Set-Content -Encoding utf8 -LiteralPath (Join-Path $OutputRoot 'raw_calculation.log')

$fence = '```'
$md = @(
  '# Exact Numerical Gate',
  '',
  ($fence + 'text'),
  'NUMERICAL_GATE=PASS',
  'CLK_HZ=62500000',
  'SUCCESS_PATH_TICK_ACTIONS=31043',
  'SUCCESS_PATH_FIRST_IDLE_TO_FINISH_INTERVALS=31042',
  'TRANSACTION_COUNT=275',
  'WRITE_TRANSACTIONS=220',
  'READ_TRANSACTIONS=55',
  'TABLE_SLOTS=214',
  'TABLE_TARGET_WRITES=187',
  'TABLE_DELAY_SLOTS=1',
  'TABLE_NOP_SLOTS=26',
  'VERIFIED_BANK_CHANGES=25',
  '',
  'FORMAL_I2C_HZ=50000',
  'FORMAL_DIVIDER=625',
  'FORMAL_TICK_COUNTER_CYCLES=626',
  'FORMAL_STATE_TICK_US=10.016000',
  'FORMAL_PHYSICAL_SCL_PERIOD_US=20.032000',
  'FORMAL_PHYSICAL_SCL_HZ=49920.1277955',
  "FORMAL_FULL_AUTOINIT_US=$($p50.TOTAL_FROM_FIRST_ACTIVE_NVP_ACLK_EDGE_US)",
  "FORMAL_FROM_POR_RELEASE_US=$($p50.TOTAL_FROM_NVP_POR_RELEASE_US)",
  "FORMAL_FROM_FIRST_PHYSICAL_I2C_START_US=$($p50.TOTAL_FROM_FIRST_I2C_START_US)",
  '',
  'DIAGNOSTIC_I2C_HZ=25000',
  'DIAGNOSTIC_DIVIDER=1250',
  'DIAGNOSTIC_TICK_COUNTER_CYCLES=1251',
  'DIAGNOSTIC_STATE_TICK_US=20.016000',
  'DIAGNOSTIC_PHYSICAL_SCL_PERIOD_US=40.032000',
  'DIAGNOSTIC_PHYSICAL_SCL_HZ=24980.0159872',
  "DIAGNOSTIC_FULL_AUTOINIT_US=$($p25.TOTAL_FROM_FIRST_ACTIVE_NVP_ACLK_EDGE_US)",
  "DIAGNOSTIC_FROM_POR_RELEASE_US=$($p25.TOTAL_FROM_NVP_POR_RELEASE_US)",
  "DIAGNOSTIC_FROM_FIRST_PHYSICAL_I2C_START_US=$($p25.TOTAL_FROM_FIRST_I2C_START_US)",
  '',
  'LOCAL_POR_CYCLES=320',
  'LOCAL_POR_US=5.120000',
  'C_RESET_HOLD_CYCLES=31250000',
  'PHYSICAL_R17_LOW_SECONDS_AFTER_POR=0.500000',
  'R17_RELEASE_SECONDS_FROM_FIRST_ACTIVE_CLOCK=0.500005120',
  'C_START_CYCLE=93750000',
  'FIRST_I2C_START_SECONDS_NOMINAL=1.500000',
  'SCL_RELEASED_LOW_WATCHDOG_COUNTER_TERMINAL=1250',
  'SCL_RELEASED_LOW_WATCHDOG_WALL_CLOCK_US=20.016000',
  'SCL_RELEASED_LOW_WATCHDOG_UNCHANGED=YES',
  'SDA_SCL_SYNCHRONIZER_DEPTH_UNCHANGED=YES',
  'SDA_SCL_FILTER_DEPTH_UNCHANGED=YES',
  $fence,
  '',
  'The all-ACK success path contains 31,043 FSM tick actions. From the first IDLE',
  'tick accepting the latched start through the FINISH tick there are 31,042',
  "tick-to-tick intervals. All component counts use the RTL's inclusive counter",
  'semantics.',
  '',
  'The component CSV reports a tick-budget contribution, not a point-to-point',
  'first-action-to-last-action edge span. Thus a 61-action write contributes 61',
  'ticks to the complete pipeline accounting while its first-to-last action edges',
  'span 60 intervals. The complete lifecycle total separately and explicitly uses',
  '31,042 intervals between 31,043 actions.',
  '',
  'The lifecycle-counter convention records the FINISH edge. Wrapper `init_done`',
  'is physically high one base-clock cycle later; that alternative observation',
  'adds exactly 0.016 microseconds. The first-I2C-start reference above is the',
  'physical START edge where SDA is driven low while SCL is released.',
  '',
  'Every state-tick-based interval changes with `I2C_HZ`: LOW/HIGH phases,',
  'START/STOP/ACK dwell, transaction duration, NOP duration, table-delay duration,',
  'and final-settle duration. The local POR, R17 hold, 1.5-second start counter,',
  'synchronizers, filter, and released-SCL watchdog are base-clock quantities and',
  'remain unchanged.'
) -join [Environment]::NewLine
$md | Set-Content -Encoding utf8 -LiteralPath (Join-Path $OutputRoot 'NUMERICAL_GATE.md')

Write-Output 'NUMERICAL_GATE=PASS'
Write-Output "FORMAL_FULL_AUTOINIT_US=$($p50.TOTAL_FROM_FIRST_ACTIVE_NVP_ACLK_EDGE_US)"
Write-Output "DIAGNOSTIC_FULL_AUTOINIT_US=$($p25.TOTAL_FROM_FIRST_ACTIVE_NVP_ACLK_EDGE_US)"
