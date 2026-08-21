param(
  [Parameter(Mandatory=$true)][string]$SourceTestbench,
  [Parameter(Mandatory=$true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

function Require-Once {
  param([string]$Text,[string]$Needle,[string]$Label)
  $count = ([regex]::Matches($Text,[regex]::Escape($Needle))).Count
  if ($count -ne 1) { throw "$Label must occur exactly once; observed $count" }
}

function New-InstrumentedTestbench {
  param(
    [string]$BaseText,
    [int]$I2cHz,
    [int]$TimeoutMs,
    [int]$ExpectedStartToDoneCycles,
    [int]$ExpectedLifecycleCount,
    [string]$Destination
  )

  $text = $BaseText
  Require-Once $text '  constant I2C_HZ : positive := 50_000;' 'base I2C generic'
  Require-Once $text '  signal guarded_step_valid : std_logic := ''0'';' 'signal insertion anchor'
  Require-Once $text '  clk <= not clk after 500 ns;' 'monitor insertion anchor'
  Require-Once $text '      wait until done = ''1'' for 600 ms;' 'timeout anchor'

  $i2cLiteral = $I2cHz.ToString('0',$invariant)
  if ($i2cLiteral.Length -eq 5) {
    $i2cLiteral = $i2cLiteral.Substring(0,2) + '_' + $i2cLiteral.Substring(2)
  }
  $text = $text.Replace(
    '  constant I2C_HZ : positive := 50_000;',
    "  constant I2C_HZ : positive := $i2cLiteral;")

  $constantAnchor = '  constant I2C_HZ : positive := ' + $i2cLiteral + ';'
  $constantBlock = @"
$constantAnchor
  -- Exact cycle-count cross-check constants.  The production lifecycle count
  -- uses the same counter convention as R1: the pre-increment counter value
  -- corresponding to the engine FINISH tick.  The wrapper output becomes high
  -- one 62.5-MHz base cycle later.
  constant C_TICK_COUNTER_CYCLES : natural := CLK_HZ / (I2C_HZ * 2) + 1;
  constant C_EXPECTED_TICK_INTERVALS : natural := 31_042;
  constant C_EXPECTED_START_TO_DONE_CYCLES : natural := $ExpectedStartToDoneCycles;
  constant C_PRODUCTION_CLK_HZ : natural := 62_500_000;
  constant C_PRODUCTION_TICK_CYCLES : natural := C_PRODUCTION_CLK_HZ / (I2C_HZ * 2) + 1;
  constant C_PRODUCTION_ENGINE_START_SAMPLE_EDGE : natural := 93_750_322;
  constant C_PRODUCTION_FIRST_IDLE_EDGE : natural := 1 +
    ((C_PRODUCTION_ENGINE_START_SAMPLE_EDGE - 1 + C_PRODUCTION_TICK_CYCLES - 1) /
      C_PRODUCTION_TICK_CYCLES) * C_PRODUCTION_TICK_CYCLES;
  constant C_PRODUCTION_FINISH_COUNTER : natural := C_PRODUCTION_FIRST_IDLE_EDGE +
    C_EXPECTED_TICK_INTERVALS * C_PRODUCTION_TICK_CYCLES;
  constant C_EXPECTED_PRODUCTION_LIFECYCLE_COUNT : natural := $ExpectedLifecycleCount;
"@
  $text = $text.Replace($constantAnchor,$constantBlock.TrimEnd("`r","`n"))

  $signalAnchor = '  signal guarded_step_valid : std_logic := ''0'';'
  $signalBlock = @"
$signalAnchor
  signal exact_cycle_index : natural := 0;
  signal exact_first_start_cycle : natural := 0;
  signal exact_first_setup_cycle : natural := 0;
  signal exact_start_seen : std_logic := '0';
  signal exact_setup_seen : std_logic := '0';
  signal exact_done_seen : std_logic := '0';
"@
  $text = $text.Replace($signalAnchor,$signalBlock.TrimEnd("`r","`n"))

  $clockAnchor = '  clk <= not clk after 500 ns;'
  $monitorBlock = @"
$clockAnchor

  exact_cycle_count_monitor : process(clk)
    variable start_to_done_cycles_v : natural;
    variable setup_to_done_cycles_v : natural;
    variable tick_intervals_v : natural;
  begin
    if rising_edge(clk) then
      exact_cycle_index <= exact_cycle_index + 1;

      if exact_start_seen = '0' and start = '1' then
        exact_start_seen <= '1';
        exact_first_start_cycle <= exact_cycle_index;
      end if;

      -- t_state'pos(SETUP_OP)=1.  Observing SETUP_OP here is one base edge
      -- after the IDLE tick action; observing done is likewise one edge after
      -- FINISH.  Their difference therefore cancels observation latency and
      -- is exactly the FINISH-to-IDLE tick interval count times tick spacing.
      if exact_setup_seen = '0' and i2c_state = x"01" then
        exact_setup_seen <= '1';
        exact_first_setup_cycle <= exact_cycle_index;
      end if;

      if exact_done_seen = '0' and done = '1' then
        assert exact_start_seen = '1' and exact_setup_seen = '1'
          report "cycle monitor missed start or first SETUP" severity failure;
        start_to_done_cycles_v := exact_cycle_index - exact_first_start_cycle;
        setup_to_done_cycles_v := exact_cycle_index - exact_first_setup_cycle;
        assert setup_to_done_cycles_v mod C_TICK_COUNTER_CYCLES = 0
          report "SETUP-to-done span is not an integer number of state ticks" severity failure;
        tick_intervals_v := setup_to_done_cycles_v / C_TICK_COUNTER_CYCLES;
        assert tick_intervals_v = C_EXPECTED_TICK_INTERVALS
          report "success-path tick-interval count mismatch" severity failure;
        assert start_to_done_cycles_v = C_EXPECTED_START_TO_DONE_CYCLES
          report "start-to-done base-cycle count mismatch" severity failure;
        assert C_PRODUCTION_FINISH_COUNTER = C_EXPECTED_PRODUCTION_LIFECYCLE_COUNT
          report "production lifecycle-count arithmetic mismatch" severity failure;

        report "EXACT_CYCLE_I2C_HZ=" & integer'image(I2C_HZ) severity note;
        report "EXACT_TICK_COUNTER_CYCLES=" & integer'image(C_TICK_COUNTER_CYCLES) severity note;
        report "EXACT_FIRST_START_CYCLE=" & integer'image(exact_first_start_cycle) severity note;
        report "EXACT_FIRST_SETUP_OBSERVE_CYCLE=" & integer'image(exact_first_setup_cycle) severity note;
        report "EXACT_DONE_OBSERVE_CYCLE=" & integer'image(exact_cycle_index) severity note;
        report "EXACT_START_TO_DONE_BASE_CYCLES=" & integer'image(start_to_done_cycles_v) severity note;
        report "EXACT_SETUP_TO_DONE_BASE_CYCLES=" & integer'image(setup_to_done_cycles_v) severity note;
        report "EXACT_SUCCESS_PATH_TICK_INTERVALS=" & integer'image(tick_intervals_v) severity note;
        report "EXACT_SUCCESS_PATH_TICK_ACTIONS=" & integer'image(tick_intervals_v + 1) severity note;
        report "EXACT_PRODUCTION_FIRST_IDLE_EDGE=" & integer'image(C_PRODUCTION_FIRST_IDLE_EDGE) severity note;
        report "EXACT_PRODUCTION_LIFECYCLE_COUNTER=" & integer'image(C_PRODUCTION_FINISH_COUNTER) severity note;
        report "EXACT_WRAPPER_INIT_DONE_HIGH_EDGE=" & integer'image(C_PRODUCTION_FINISH_COUNTER + 1) severity note;
        report "EXACT_LIFECYCLE_COUNTER_CONVENTION=FINISH_EDGE_PREINCREMENT" severity note;
        report "PASS_EXACT_I2C_CYCLE_COUNT_CROSSCHECK" severity note;
        exact_done_seen <= '1';
      end if;
    end if;
  end process;
"@
  $text = $text.Replace($clockAnchor,$monitorBlock.TrimEnd("`r","`n"))

  $text = $text.Replace(
    '      wait until done = ''1'' for 600 ms;',
    "      wait until done = '1' for $TimeoutMs ms;")

  if ($text.Contains('constant I2C_HZ : positive := 50_000;') -and $I2cHz -ne 50000) {
    throw '25-kHz testbench still contains the 50-kHz generic'
  }
  if (-not $text.Contains('PASS_EXACT_I2C_CYCLE_COUNT_CROSSCHECK')) {
    throw 'cycle-count marker insertion failed'
  }
  [System.IO.File]::WriteAllText($Destination,$text,$utf8NoBom)
}

$source = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SourceTestbench))
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
New-InstrumentedTestbench -BaseText $source -I2cHz 50000 -TimeoutMs 600 `
  -ExpectedStartToDoneCycles 341465 -ExpectedLifecycleCount 113182679 `
  -Destination (Join-Path $OutputDirectory 'tb_nvp_autoinit_50khz_cycle.vhd')
New-InstrumentedTestbench -BaseText $source -I2cHz 25000 -TimeoutMs 1200 `
  -ExpectedStartToDoneCycles 651884 -ExpectedLifecycleCount 132584734 `
  -Destination (Join-Path $OutputDirectory 'tb_nvp_autoinit_25khz_cycle.vhd')

Write-Output 'CYCLE_COUNT_TESTBENCH_GENERATION=PASS'
