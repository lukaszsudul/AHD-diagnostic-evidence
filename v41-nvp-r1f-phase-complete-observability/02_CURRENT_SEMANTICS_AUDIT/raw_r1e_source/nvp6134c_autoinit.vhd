library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- v40A G0.5: autonomous, reduced wrapper around the exact v38EK/v39A
-- I2C sequence. The heavy diagnostic core, page mux, VIO and activity
-- monitors are intentionally absent. The proven register operation table and
-- transaction engine remain unchanged.
entity v40a_nvp_autoinit is
  generic(
    CLK_HZ : positive := 50_000_000;
    -- Physical SCL target; the sequence engine uses two phases per bit.
    I2C_HZ : positive := 50_000;
    ENABLE_MAREK_INIT_TABLE : natural range 0 to 1 := 1
  );
  port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    scl_i        : in  std_logic;
    sda_i        : in  std_logic;
    scl_oen      : out std_logic;
    sda_oen      : out std_logic;
    nvp_rst      : out std_logic;
    nvp_en_vdd1x : out std_logic;
    nvp_en_vdd3x : out std_logic;
    init_busy    : out std_logic;
    init_done    : out std_logic;
    init_error   : out std_logic;
    diag_detail  : out std_logic_vector(735 downto 0)
  );
end entity;

architecture rtl of v40a_nvp_autoinit is
  constant C_RESET_HOLD_CYCLES : natural := CLK_HZ / 2;       -- 500 ms
  constant C_START_CYCLE       : natural := CLK_HZ + CLK_HZ/2; -- 1.5 s

  signal delay_count : natural range 0 to C_START_CYCLE := 0;
  signal start_pulse : std_logic := '0';
  signal started     : std_logic := '0';
  signal done_i      : std_logic;
  signal busy_i      : std_logic;
  signal error_i     : std_logic;
  signal done_latched  : std_logic := '0';
  signal error_latched : std_logic := '0';

  signal unused_values          : std_logic_vector(127 downto 0);
  signal unused_output_values   : std_logic_vector(63 downto 0);
  signal unused_afe_values      : std_logic_vector(127 downto 0);
  signal unused_read_errors     : std_logic_vector(15 downto 0);
  signal unused_aux_errors      : std_logic_vector(15 downto 0);
  signal unused_afe_errors      : std_logic_vector(15 downto 0);
  signal unused_write_errors    : std_logic_vector(7 downto 0);
  signal diag_original_ff       : std_logic_vector(7 downto 0);
  signal diag_restored_ff       : std_logic_vector(7 downto 0);
  signal diag_meta_bank         : std_logic_vector(7 downto 0);
  signal diag_phys_bank         : std_logic_vector(7 downto 0);
  signal diag_phys_bank_valid   : std_logic;
  signal unused_range_dbg       : std_logic_vector(1 downto 0);
  signal unused_window_dbg      : std_logic_vector(2 downto 0);
  signal unused_poll_dbg        : std_logic;
  signal unused_output_dbg      : std_logic_vector(3 downto 0);
  signal unused_stage_dbg       : std_logic_vector(1 downto 0);
  signal unused_op_index_dbg    : std_logic_vector(5 downto 0);
  signal unused_state_dbg       : std_logic_vector(7 downto 0);
  signal diag_phase             : std_logic_vector(7 downto 0);
  signal diag_step              : std_logic_vector(7 downto 0);
  signal diag_table_length      : std_logic_vector(15 downto 0);
  signal diag_last_op           : std_logic_vector(2 downto 0);
  signal diag_last_reg          : std_logic_vector(7 downto 0);
  signal diag_last_wdata        : std_logic_vector(7 downto 0);
  signal diag_last_rdata        : std_logic_vector(7 downto 0);
  signal diag_last_ack          : std_logic;
  signal diag_first_valid       : std_logic;
  signal diag_first_code        : std_logic_vector(7 downto 0);
  signal diag_first_step        : std_logic_vector(7 downto 0);
  signal diag_first_meta_bank   : std_logic_vector(7 downto 0);
  signal diag_first_phys_bank   : std_logic_vector(7 downto 0);
  signal diag_first_reg         : std_logic_vector(7 downto 0);
  signal diag_first_data        : std_logic_vector(7 downto 0);
  signal diag_nack_count        : std_logic_vector(15 downto 0);
  signal diag_nack_log_count    : std_logic_vector(3 downto 0);
  signal diag_nack_log_overflow : std_logic;
  signal diag_nack_log          : std_logic_vector(511 downto 0);
  signal diag_timeout_count     : std_logic_vector(15 downto 0);
  signal diag_i2c_state         : std_logic_vector(7 downto 0);
  signal nvp_rst_i              : std_logic;
begin
  nvp_en_vdd1x <= '1';
  nvp_en_vdd3x <= '1';
  nvp_rst_i <= '0' when rst = '1' or delay_count < C_RESET_HOLD_CYCLES else '1';
  nvp_rst <= nvp_rst_i;

  init_busy  <= busy_i;
  init_done  <= done_latched;
  init_error <= error_latched;

  -- D0..D5 retain the frozen diagnostic layout.  D5's formerly reserved
  -- bytes expose original/restored/physical-first-error bank state.  The
  -- diagnostics-only D1 extension appends a header and eight 64-bit NACK
  -- records; it does not alter the I2C transaction stream.
  process(diag_phase, diag_step, diag_table_length, diag_last_op, diag_last_ack,
          scl_i, sda_i, nvp_rst_i, diag_meta_bank, diag_phys_bank,
          diag_phys_bank_valid, diag_original_ff, diag_restored_ff,
          diag_first_phys_bank, diag_nack_log_count, diag_nack_log_overflow,
          diag_nack_log, diag_last_reg,
          diag_last_wdata, diag_last_rdata, diag_first_valid, diag_first_code,
          diag_first_step, diag_first_meta_bank, diag_first_reg, diag_first_data,
          diag_nack_count, diag_timeout_count, diag_i2c_state)
    variable d : std_logic_vector(735 downto 0);
  begin
    d := (others => '0');
    d(7 downto 0)     := diag_phase;
    d(15 downto 8)    := diag_step;
    d(31 downto 16)   := diag_table_length;
    d(34 downto 32)   := diag_last_op;
    d(35)             := diag_last_ack;
    d(36)             := scl_i;
    d(37)             := sda_i;
    d(38)             := nvp_rst_i;
    d(39)             := '1';
    d(40)             := '1';
    d(55 downto 48)   := diag_meta_bank;
    d(63 downto 56)   := diag_last_reg;
    d(71 downto 64)   := diag_last_wdata;
    d(79 downto 72)   := diag_last_rdata;
    d(80)             := diag_first_valid;
    d(95 downto 88)   := diag_first_code;
    d(103 downto 96)  := diag_first_step;
    d(111 downto 104) := diag_first_meta_bank;
    d(119 downto 112) := diag_first_reg;
    d(127 downto 120) := diag_first_data;
    d(143 downto 128) := diag_nack_count;
    d(159 downto 144) := diag_timeout_count;
    d(167 downto 160) := diag_i2c_state;
    d(175 downto 168) := diag_original_ff;
    d(183 downto 176) := diag_restored_ff;
    d(191 downto 184) := diag_first_phys_bank;
    d(195 downto 192) := diag_nack_log_count;
    d(196)            := diag_nack_log_overflow;
    d(197)            := diag_phys_bank_valid;
    d(207 downto 200) := diag_meta_bank;
    d(215 downto 208) := diag_phys_bank;
    d(223 downto 216) := x"08"; -- fixed NACK-log capacity
    d(735 downto 224) := diag_nack_log;
    diag_detail <= d;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      start_pulse <= '0';
      if rst = '1' then
        delay_count   <= 0;
        started       <= '0';
        done_latched  <= '0';
        error_latched <= '0';
      else
        if delay_count < C_START_CYCLE then
          delay_count <= delay_count + 1;
        elsif started = '0' then
          start_pulse <= '1';
          started <= '1';
        end if;

        if done_i = '1' then
          done_latched <= '1';
          error_latched <= error_i;
        end if;
      end if;
    end if;
  end process;

  u_sequence : entity work.nvp_i2c_bringup_seq_v38ek
    generic map(
      CLK_HZ => CLK_HZ,
      I2C_HZ => I2C_HZ,
      ENABLE_MAREK_INIT_TABLE => ENABLE_MAREK_INIT_TABLE
    )
    port map(
      clk              => clk,
      rst              => rst,
      start            => start_pulse,
      range_sel        => "10",  -- profile 2: AHD 1080p25
      window_sel       => "000",
      poll_only        => '0',
      output_sel       => x"A", -- confirmed VCLK1 phase 10
      channel_sel      => "00", -- confirmed CH1 routed to VDO1
      auto_enable      => '0',
      stage_sel        => "10", -- confirmed stage 2
      scl_i            => scl_i,
      sda_i            => sda_i,
      scl_oen          => scl_oen,
      sda_oen          => sda_oen,
      busy             => busy_i,
      done             => done_i,
      any_error        => error_i,
      values           => unused_values,
      output_values    => unused_output_values,
      afe_values       => unused_afe_values,
      read_error_mask  => unused_read_errors,
      aux_error_mask   => unused_aux_errors,
      afe_error_mask   => unused_afe_errors,
      write_error_mask => unused_write_errors,
      original_ff      => diag_original_ff,
      restored_ff      => diag_restored_ff,
      meta_bank        => diag_meta_bank,
      phys_bank        => diag_phys_bank,
      phys_bank_valid  => diag_phys_bank_valid,
      range_dbg        => unused_range_dbg,
      window_dbg       => unused_window_dbg,
      poll_only_dbg    => unused_poll_dbg,
      output_dbg       => unused_output_dbg,
      stage_dbg        => unused_stage_dbg,
      op_index_dbg     => unused_op_index_dbg,
      state_dbg        => unused_state_dbg,
      autoinit_fsm_dbg => diag_phase,
      step_index_dbg   => diag_step,
      table_length_dbg => diag_table_length,
      last_op_dbg      => diag_last_op,
      last_reg_dbg     => diag_last_reg,
      last_wdata_dbg   => diag_last_wdata,
      last_rdata_dbg   => diag_last_rdata,
      last_ack_dbg     => diag_last_ack,
      first_error_valid_dbg => diag_first_valid,
      first_error_code_dbg  => diag_first_code,
      first_error_step_dbg  => diag_first_step,
      first_error_meta_bank_dbg => diag_first_meta_bank,
      first_error_phys_bank_dbg => diag_first_phys_bank,
      first_error_reg_dbg   => diag_first_reg,
      first_error_data_dbg  => diag_first_data,
      nack_count_dbg        => diag_nack_count,
      nack_log_count_dbg    => diag_nack_log_count,
      nack_log_overflow_dbg => diag_nack_log_overflow,
      nack_log_dbg          => diag_nack_log,
      timeout_count_dbg     => diag_timeout_count,
      i2c_fsm_dbg           => diag_i2c_state
    );
end architecture;
