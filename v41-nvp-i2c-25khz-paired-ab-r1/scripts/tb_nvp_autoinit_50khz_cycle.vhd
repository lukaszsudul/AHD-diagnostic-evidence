library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.nvp6134c_diag_pkg_v38ek.all;

entity tb_g0p8c5d_autoinit is end entity;

architecture sim of tb_g0p8c5d_autoinit is
  constant CLK_HZ : positive := 1_000_000;
  -- Keep at least six clk samples between protocol-state ticks so the Z9
  -- two-stage synchronizers and three-sample filters can settle in simulation.
  constant I2C_HZ : positive := 50_000;
  -- Exact cycle-count cross-check constants.  The production lifecycle count
  -- uses the same counter convention as R1: the pre-increment counter value
  -- corresponding to the engine FINISH tick.  The wrapper output becomes high
  -- one 62.5-MHz base cycle later.
  constant C_TICK_COUNTER_CYCLES : natural := CLK_HZ / (I2C_HZ * 2) + 1;
  constant C_EXPECTED_TICK_INTERVALS : natural := 31_042;
  constant C_EXPECTED_START_TO_DONE_CYCLES : natural := 341465;
  constant C_PRODUCTION_CLK_HZ : natural := 62_500_000;
  constant C_PRODUCTION_TICK_CYCLES : natural := C_PRODUCTION_CLK_HZ / (I2C_HZ * 2) + 1;
  constant C_PRODUCTION_ENGINE_START_SAMPLE_EDGE : natural := 93_750_322;
  constant C_PRODUCTION_FIRST_IDLE_EDGE : natural := 1 +
    ((C_PRODUCTION_ENGINE_START_SAMPLE_EDGE - 1 + C_PRODUCTION_TICK_CYCLES - 1) /
      C_PRODUCTION_TICK_CYCLES) * C_PRODUCTION_TICK_CYCLES;
  constant C_PRODUCTION_FINISH_COUNTER : natural := C_PRODUCTION_FIRST_IDLE_EDGE +
    C_EXPECTED_TICK_INTERVALS * C_PRODUCTION_TICK_CYCLES;
  constant C_EXPECTED_PRODUCTION_LIFECYCLE_COUNT : natural := 113182679;
  signal clk, rst, start : std_logic := '0';
  signal scl_i, sda_i, scl_oen, sda_oen : std_logic;
  signal busy, done, any_error : std_logic;
  signal values, afe_values : std_logic_vector(127 downto 0);
  signal output_values : std_logic_vector(63 downto 0);
  signal read_errors, aux_errors, afe_errors : std_logic_vector(15 downto 0);
  signal write_errors : std_logic_vector(7 downto 0);
  signal original_ff, restored_ff, meta_bank, phys_bank : std_logic_vector(7 downto 0);
  signal phys_bank_valid : std_logic;
  signal range_dbg : std_logic_vector(1 downto 0);
  signal window_dbg : std_logic_vector(2 downto 0);
  signal poll_dbg : std_logic;
  signal output_dbg : std_logic_vector(3 downto 0);
  signal stage_dbg : std_logic_vector(1 downto 0);
  signal op6 : std_logic_vector(5 downto 0);
  signal state_legacy, phase8, step8, last_reg, last_wdata, last_rdata : std_logic_vector(7 downto 0);
  signal table_len, nack_count, timeout_count : std_logic_vector(15 downto 0);
  signal last_op : std_logic_vector(2 downto 0);
  signal last_ack, first_valid : std_logic;
  signal first_code, first_step, first_meta_bank, first_phys_bank, first_reg, first_data, i2c_state : std_logic_vector(7 downto 0);
  signal nack_log_count : std_logic_vector(3 downto 0);
  signal nack_log_overflow : std_logic;
  signal nack_log : std_logic_vector(511 downto 0);
  constant C_MODEL_ENTRY_BANK : std_logic_vector(7 downto 0) := x"07";
  signal fault_mode : natural range 0 to 8 := 0;
  signal short_sda_glitch_cycles : natural range 0 to 2 := 0;
  signal short_sda_glitch_armed : std_logic := '0';
  signal transaction_count : natural := 0;
  signal checked_table_writes : natural := 0;
  signal checked_bank_select_writes : natural := 0;
  signal checked_bank_verify_reads : natural := 0;
  signal previous_i2c_state : std_logic_vector(7 downto 0) := (others => '0');
  signal model_bank : std_logic_vector(7 downto 0) := C_MODEL_ENTRY_BANK;
  signal read_bit_idx : integer range 0 to 7 := 7;
  signal transaction_had_nack : std_logic := '0';
  signal guarded_step : std_logic_vector(7 downto 0) := (others => '0');
  signal guarded_step_valid : std_logic := '0';
  signal exact_cycle_index : natural := 0;
  signal exact_first_start_cycle : natural := 0;
  signal exact_first_setup_cycle : natural := 0;
  signal exact_start_seen : std_logic := '0';
  signal exact_setup_seen : std_logic := '0';
  signal exact_done_seen : std_logic := '0';

  function expected_init_writes return natural is
    variable n : natural := 0;
    variable op : std_logic_vector(23 downto 0);
  begin
    for slot in 0 to C_V38EK_LAST_INIT_SLOT loop
      op := c_v38ek_init_op_for_slot(slot, "10", x"A", "00", '0', "10");
      if op(23 downto 16) /= x"FD" and op(23 downto 16) /= x"FE" then n := n + 1; end if;
    end loop;
    return n;
  end function;

  function expected_init_bank_changes return natural is
    variable n : natural := 0;
    variable op : std_logic_vector(23 downto 0);
    variable current_bank : std_logic_vector(7 downto 0) := x"00";
  begin
    for slot in 0 to C_V38EK_LAST_INIT_SLOT loop
      op := c_v38ek_init_op_for_slot(slot, "10", x"A", "00", '0', "10");
      if op(23 downto 16) /= x"FD" and op(23 downto 16) /= x"FE" then
        if current_bank /= op(23 downto 16) then
          n := n + 1;
          current_bank := op(23 downto 16);
        end if;
        if op(15 downto 8) = C_V38EK_BANK_SELECT_REG then
          current_bank := op(7 downto 0);
        end if;
      end if;
    end loop;
    return n;
  end function;
begin
  clk <= not clk after 500 ns;

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

  -- Open-drain bus model. State codes are t_state'pos values from the DUT.
  scl_i <= '0' when fault_mode = 5 else scl_oen;
  process(all)
    variable ack_state, inject_nack : boolean;
    variable st, ph, step : natural;
    variable read_byte : std_logic_vector(7 downto 0);
  begin
    st := to_integer(unsigned(i2c_state));
    ph := to_integer(unsigned(phase8));
    step := to_integer(unsigned(step8));
    ack_state := st = 7 or st = 11 or st = 15 or st = 23;
    inject_nack := (fault_mode = 1 and ph = 0 and step = 0 and last_op = "001") or
                   (fault_mode = 2 and ph = 1 and step = 101 and last_op = "010") or
                   (fault_mode = 3 and ph = 8) or
                   (fault_mode = 6 and ph = 1 and last_op = "101");
    read_byte := (others => '0');
    if last_reg = C_V38EK_BANK_SELECT_REG then
      read_byte := model_bank;
    end if;
    if fault_mode = 7 and ph = 1 and last_op = "110" then
      read_byte := not meta_bank;
    end if;
    if fault_mode = 4 then
      sda_i <= '0';
    elsif ack_state and short_sda_glitch_cycles > 0 then
      sda_i <= '1';
    elsif ack_state and inject_nack then
      sda_i <= '1';
    elsif ack_state then
      sda_i <= '0';
    elsif st = 25 then
      sda_i <= read_byte(read_bit_idx);
    else
      sda_i <= '1';
    end if;
  end process;

  -- Fault mode 8 injects a two-clk raw-SDA pulse during the first address ACK.
  -- Z9 must reject it because it never produces three consecutive matching
  -- samples at the second synchronizer stage.
  short_glitch : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or fault_mode /= 8 then
        short_sda_glitch_cycles <= 0;
        short_sda_glitch_armed <= '0';
      elsif i2c_state = x"07" and previous_i2c_state /= x"07" and
            short_sda_glitch_armed = '0' then
        short_sda_glitch_cycles <= 2;
        short_sda_glitch_armed <= '1';
      elsif short_sda_glitch_cycles > 0 then
        short_sda_glitch_cycles <= short_sda_glitch_cycles - 1;
      end if;
    end if;
  end process;

  dut : entity work.nvp_i2c_bringup_seq_v38ek
    generic map(CLK_HZ => CLK_HZ, I2C_HZ => I2C_HZ)
    port map(
      clk=>clk, rst=>rst, start=>start, range_sel=>"10", window_sel=>"000",
      poll_only=>'0', output_sel=>x"A", channel_sel=>"00", auto_enable=>'0', stage_sel=>"10",
      scl_i=>scl_i, sda_i=>sda_i, scl_oen=>scl_oen, sda_oen=>sda_oen,
      busy=>busy, done=>done, any_error=>any_error, values=>values,
      output_values=>output_values, afe_values=>afe_values,
      read_error_mask=>read_errors, aux_error_mask=>aux_errors,
      afe_error_mask=>afe_errors, write_error_mask=>write_errors,
      original_ff=>original_ff, restored_ff=>restored_ff,
      meta_bank=>meta_bank, phys_bank=>phys_bank, phys_bank_valid=>phys_bank_valid,
      range_dbg=>range_dbg, window_dbg=>window_dbg, poll_only_dbg=>poll_dbg,
      output_dbg=>output_dbg, stage_dbg=>stage_dbg, op_index_dbg=>op6, state_dbg=>state_legacy,
      autoinit_fsm_dbg=>phase8, step_index_dbg=>step8, table_length_dbg=>table_len,
      last_op_dbg=>last_op, last_reg_dbg=>last_reg, last_wdata_dbg=>last_wdata,
      last_rdata_dbg=>last_rdata, last_ack_dbg=>last_ack,
      first_error_valid_dbg=>first_valid, first_error_code_dbg=>first_code,
      first_error_step_dbg=>first_step, first_error_meta_bank_dbg=>first_meta_bank,
      first_error_phys_bank_dbg=>first_phys_bank,
      first_error_reg_dbg=>first_reg, first_error_data_dbg=>first_data,
      nack_count_dbg=>nack_count, nack_log_count_dbg=>nack_log_count,
      nack_log_overflow_dbg=>nack_log_overflow, nack_log_dbg=>nack_log,
      timeout_count_dbg=>timeout_count, i2c_fsm_dbg=>i2c_state);

  monitor : process(clk)
    variable op : std_logic_vector(23 downto 0);
    variable slot : integer;
    variable ack_state : boolean;
  begin
    if rising_edge(clk) then
      previous_i2c_state <= i2c_state;
      ack_state := i2c_state = x"07" or i2c_state = x"0B" or
                   i2c_state = x"0F" or i2c_state = x"17";
      if rst = '1' then
        transaction_count <= 0;
        checked_table_writes <= 0;
        checked_bank_select_writes <= 0;
        checked_bank_verify_reads <= 0;
        model_bank <= C_MODEL_ENTRY_BANK;
        read_bit_idx <= 7;
        transaction_had_nack <= '0';
        guarded_step <= (others => '0');
        guarded_step_valid <= '0';
      elsif i2c_state = x"02" and previous_i2c_state /= x"02" then
        transaction_count <= transaction_count + 1;
        transaction_had_nack <= '0';

        if last_op = "101" then
          assert last_reg = C_V38EK_BANK_SELECT_REG
            report "D2 bank-select helper did not address 0xFF" severity failure;
          checked_bank_select_writes <= checked_bank_select_writes + 1;
          if fault_mode = 6 and phase8 = x"01" then
            guarded_step <= step8;
            guarded_step_valid <= '1';
          end if;
        elsif last_op = "110" then
          assert last_reg = C_V38EK_BANK_SELECT_REG
            report "D2 bank-verify helper did not read 0xFF" severity failure;
          checked_bank_verify_reads <= checked_bank_verify_reads + 1;
          if fault_mode = 7 and phase8 = x"01" then
            guarded_step <= step8;
            guarded_step_valid <= '1';
          end if;
        end if;

        if phase8 = x"01" and last_op = "010" then
          slot := to_integer(unsigned(step8)) - 1;
          op := c_v38ek_init_op_for_slot(slot, "10", x"A", "00", '0', "10");
          assert op(23 downto 16) /= x"FD" and op(23 downto 16) /= x"FE"
            report "pseudo-operation incorrectly issued on I2C" severity failure;
          assert meta_bank = op(23 downto 16) and last_reg = op(15 downto 8) and last_wdata = op(7 downto 0)
            report "bank/register/data differs from audited init table" severity failure;
          assert phys_bank_valid = '1' and phys_bank = op(23 downto 16)
            report "table target write issued without matching verified physical bank" severity failure;
          assert not (guarded_step_valid = '1' and step8 = guarded_step)
            report "table target write was not blocked after selector failure" severity failure;
          checked_table_writes <= checked_table_writes + 1;
        end if;
      else
        if ack_state and sda_i = '1' then
          transaction_had_nack <= '1';
        end if;

        if i2c_state = x"18" and previous_i2c_state = x"17" then
          read_bit_idx <= 7;
        elsif i2c_state = x"18" and previous_i2c_state = x"19" and read_bit_idx > 0 then
          read_bit_idx <= read_bit_idx - 1;
        end if;

        if i2c_state = x"1C" and previous_i2c_state = x"0F" and
           transaction_had_nack = '0' and last_reg = C_V38EK_BANK_SELECT_REG then
          model_bank <= last_wdata;
        end if;
      end if;
    end if;
  end process;

  stimulus : process
    procedure begin_run(constant mode : natural) is
    begin
      fault_mode <= mode; rst <= '1'; start <= '0'; wait for 10 us;
      rst <= '0'; wait for 10 us; start <= '1'; wait for 2 us; start <= '0';
    end procedure;
    procedure await_done is
    begin
      wait until done = '1' for 600 ms;
      assert done = '1' report "bounded completion timeout" severity failure;
      wait for 2 us;
    end procedure;
  begin
    begin_run(0); await_done;
    assert any_error='0' and first_valid='0' and unsigned(nack_count)=0 and unsigned(timeout_count)=0
      report "all-ACK status failed" severity failure;
    assert unsigned(table_len)=C_V38EK_LAST_INIT_SLOT+1 report "table length mismatch" severity failure;
    assert checked_table_writes=expected_init_writes report "not every audited table write occurred once" severity failure;
    assert checked_bank_select_writes=1+expected_init_bank_changes
      report "unexpected D2 bank-select helper count" severity failure;
    assert checked_bank_verify_reads=1+expected_init_bank_changes
      report "unexpected D2 bank-verify helper count" severity failure;
    assert transaction_count=expected_init_writes+38+(2*expected_init_bank_changes)
      report "unexpected total I2C transaction count" severity failure;
    assert original_ff=C_MODEL_ENTRY_BANK and restored_ff=C_MODEL_ENTRY_BANK and
           phys_bank=C_MODEL_ENTRY_BANK and phys_bank_valid='1'
      report "physical/original/restored bank tracking failed on all-ACK run" severity failure;
    assert nack_log_count=x"0" and nack_log_overflow='0'
      report "clean run produced unexpected NACK log content" severity failure;
    report "PASS all transactions ACK" severity note;

    begin_run(1); await_done;
    assert any_error='1' and first_valid='1' and first_code=x"01" and first_step=x"00" and unsigned(nack_count)>0
      report "first-operation NACK diagnosis failed" severity failure;
    assert nack_log_count=x"3" and nack_log_overflow='0'
      report "all three operation-0 NACK phases were not retained" severity failure;
    assert nack_log(7 downto 0)=x"00" and nack_log(15 downto 8)=x"01" and
           nack_log(23 downto 16)=x"FF" and nack_log(48)='1'
      report "operation-0 address NACK log entry mismatch" severity failure;
    assert nack_log(79 downto 72)=x"02" and nack_log(143 downto 136)=x"04"
      report "operation-0 register/read-address NACK phase log mismatch" severity failure;
    report "PASS NACK at first operation" severity note;

    begin_run(2); await_done;
    assert first_valid='1' and first_step=x"65" and first_code=x"01" report "middle-step NACK diagnosis failed" severity failure;
    assert nack_log_count=x"3" and nack_log(49)='1' and
           first_phys_bank=nack_log(39 downto 32)
      report "middle-step physical-bank/NACK log tracking failed" severity failure;
    report "PASS NACK at middle table step and frozen metadata" severity note;

    begin_run(3); await_done;
    assert first_valid='1' and first_code=x"01" and unsigned(first_step)>220 report "final-operation NACK diagnosis failed" severity failure;
    report "PASS NACK at final operation" severity note;

    begin_run(4); await_done;
    assert any_error='1' and first_code=x"06" and unsigned(nack_count)=0 report "SDA-stuck-low diagnosis failed" severity failure;
    report "PASS SDA stuck low" severity note;

    begin_run(5); await_done;
    report "SCL timeout observed code=" & integer'image(to_integer(unsigned(first_code))) &
      " count=" & integer'image(to_integer(unsigned(timeout_count))) &
      " error=" & std_logic'image(any_error) severity note;
    assert any_error='1' and first_code=x"07" and unsigned(timeout_count)>0 report "SCL/controller timeout diagnosis failed" severity failure;
    report "PASS SCL stuck low and bounded controller timeout" severity note;

    begin_run(6); await_done;
    assert any_error='1' and first_valid='1' and first_reg=x"FF" and
           write_errors(1)='1' and guarded_step_valid='1'
      report "bank-select failure diagnosis/interlock failed" severity failure;
    report "PASS bank-select write failure blocks wrong-bank target" severity note;

    begin_run(7); await_done;
    assert any_error='1' and first_valid='1' and first_code=x"08" and
           first_reg=x"FF" and unsigned(nack_count)=0 and write_errors(1)='1' and
           guarded_step_valid='1'
      report "bank-select readback mismatch diagnosis/interlock failed" severity failure;
    report "PASS bank-select readback mismatch blocks wrong-bank target" severity note;

    begin_run(8); await_done;
    assert any_error='0' and first_valid='0' and unsigned(nack_count)=0 and
           unsigned(timeout_count)=0
      report "two-cycle raw SDA glitch escaped the three-sample filter" severity failure;
    report "PASS two-cycle raw SDA glitch rejected by Z9 filter" severity note;

    -- Reset during an active table run clears every sticky diagnostic, then a
    -- clean restart proves done/error latch behavior and index boundaries.
    begin_run(0); wait until busy='1'; wait for 2 ms; rst<='1'; wait for 10 us;
    assert done='0' and any_error='0' and first_valid='0' and nack_log_count=x"0"
      report "reset-during-init did not clear state" severity failure;
    rst<='0'; wait for 10 us; start<='1'; wait for 2 us; start<='0'; await_done;
    assert any_error='0' and unsigned(step8) <= 255 report "clean rerun/index boundary failed" severity failure;
    report "PASS reset during init, table boundary, and done/error latch" severity note;
    report "PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION" severity note;
    stop;
    wait;
  end process;
end architecture;
