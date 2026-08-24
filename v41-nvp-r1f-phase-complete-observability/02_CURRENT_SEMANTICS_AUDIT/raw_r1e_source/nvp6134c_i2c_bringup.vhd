library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nvp6134c_diag_pkg_v38ek.all;

entity nvp_i2c_bringup_seq_v38ek is
  generic(
    CLK_HZ : positive := 62500000;
    -- Physical SCL target.  The FSM uses two state phases per SCL bit; the
    -- divider expression below preserves the qualified ~49.92-kHz waveform.
    I2C_HZ : positive := 50000;
    ENABLE_MAREK_INIT_TABLE : natural range 0 to 1 := 1
  );
  port(
    clk             : in  std_logic;
    rst             : in  std_logic;
    start           : in  std_logic;
    range_sel       : in  std_logic_vector(1 downto 0);
    window_sel      : in  std_logic_vector(2 downto 0);
    poll_only       : in  std_logic;
    output_sel      : in  std_logic_vector(3 downto 0); -- VCLK1 phase
    channel_sel     : in  std_logic_vector(1 downto 0); -- VDO1 source 0..3
    auto_enable     : in  std_logic;
    stage_sel       : in  std_logic_vector(1 downto 0);

    scl_i           : in  std_logic;
    sda_i           : in  std_logic;
    scl_oen         : out std_logic;
    sda_oen         : out std_logic;

    busy            : out std_logic;
    done            : out std_logic;
    any_error       : out std_logic;
    values          : out std_logic_vector(127 downto 0); -- selected Bank0 window, idx0 in bits 7:0
    output_values   : out std_logic_vector(63 downto 0);  -- Bank1 C2,C3,C4,C5,C8,C9,CA,CD
    afe_values      : out std_logic_vector(127 downto 0); -- low 32b: raw Bank5/6/7/8 F0 (CH1..4)
    read_error_mask : out std_logic_vector(15 downto 0);
    aux_error_mask  : out std_logic_vector(15 downto 0); -- [7:0] output reads
    afe_error_mask  : out std_logic_vector(15 downto 0);
    write_error_mask: out std_logic_vector(7 downto 0);
    original_ff     : out std_logic_vector(7 downto 0);
    restored_ff     : out std_logic_vector(7 downto 0);
    meta_bank       : out std_logic_vector(7 downto 0);
    phys_bank       : out std_logic_vector(7 downto 0);
    phys_bank_valid : out std_logic;
    range_dbg       : out std_logic_vector(1 downto 0);
    window_dbg      : out std_logic_vector(2 downto 0);
    poll_only_dbg   : out std_logic;
    output_dbg      : out std_logic_vector(3 downto 0);
    stage_dbg       : out std_logic_vector(1 downto 0);
    op_index_dbg    : out std_logic_vector(5 downto 0);
    state_dbg       : out std_logic_vector(7 downto 0);
    autoinit_fsm_dbg: out std_logic_vector(7 downto 0);
    step_index_dbg  : out std_logic_vector(7 downto 0);
    table_length_dbg: out std_logic_vector(15 downto 0);
    last_op_dbg     : out std_logic_vector(2 downto 0);
    last_reg_dbg    : out std_logic_vector(7 downto 0);
    last_wdata_dbg  : out std_logic_vector(7 downto 0);
    last_rdata_dbg  : out std_logic_vector(7 downto 0);
    last_ack_dbg    : out std_logic;
    first_error_valid_dbg : out std_logic;
    first_error_code_dbg  : out std_logic_vector(7 downto 0);
    first_error_step_dbg  : out std_logic_vector(7 downto 0);
    first_error_meta_bank_dbg : out std_logic_vector(7 downto 0);
    first_error_phys_bank_dbg : out std_logic_vector(7 downto 0);
    first_error_reg_dbg   : out std_logic_vector(7 downto 0);
    first_error_data_dbg  : out std_logic_vector(7 downto 0);
    nack_count_dbg        : out std_logic_vector(15 downto 0);
    nack_log_count_dbg    : out std_logic_vector(3 downto 0);
    nack_log_overflow_dbg : out std_logic;
    nack_log_dbg          : out std_logic_vector(511 downto 0);
    timeout_count_dbg     : out std_logic_vector(15 downto 0);
    i2c_fsm_dbg           : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of nvp_i2c_bringup_seq_v38ek is
  constant DIVIDER : positive := CLK_HZ / (I2C_HZ * 2);
  -- Confirmed board address: 7-bit 0x30, wire bytes 0x60/0x61.
  constant NVP_ADDR_W : std_logic_vector(7 downto 0) := x"60";
  constant NVP_ADDR_R : std_logic_vector(7 downto 0) := x"61";

  type t_state is (
    IDLE, SETUP_OP,
    START_W_A, START_W_B,
    SEND_W_LOW, SEND_W_HIGH, ACK_W_LOW, ACK_W_HIGH,
    SEND_REG_LOW, SEND_REG_HIGH, ACK_REG_LOW, ACK_REG_HIGH,
    SEND_DATA_LOW, SEND_DATA_HIGH, ACK_DATA_LOW, ACK_DATA_HIGH,
    REP_LOW, REP_HIGH, REP_START_A, REP_START_B,
    SEND_R_LOW, SEND_R_HIGH, ACK_R_LOW, ACK_R_HIGH,
    READ_LOW, READ_HIGH,
    MASTER_NACK_LOW, MASTER_NACK_HIGH,
    STOP_A, STOP_B, STORE_RESULT, NEXT_OP, WAIT_SLOT, WAIT_INIT, FINISH
  );

  type t_phase is (PH_ORIGINAL, PH_INIT, PH_WIN_BANK, PH_WIN_READ, PH_OUT_BANK, PH_OUT_READ, PH_AFE_BANK, PH_AFE_READ, PH_RESTORE);
  type t_preinit_action is (PREINIT_READ_ORIGINAL, PREINIT_FORCE_BANK0_WRITE, PREINIT_FORCE_BANK0_VERIFY);
  type t_init_action is (INIT_DECODE, INIT_BANK_WRITE, INIT_BANK_VERIFY, INIT_TARGET_WRITE);
  type t_nack_log is array (0 to 7) of std_logic_vector(63 downto 0);

  signal state          : t_state := IDLE;
  signal phase          : t_phase := PH_ORIGINAL;
  signal tick_cnt       : natural range 0 to DIVIDER := 0;
  signal tick           : std_logic := '0';
  signal start_latched  : std_logic := '0';
  signal range_latched  : std_logic_vector(1 downto 0) := "00";
  signal window_latched : std_logic_vector(2 downto 0) := "000";
  signal mode_poll_only_latched : std_logic := '0';
  signal output_latched : std_logic_vector(3 downto 0) := (others => '0');
  signal channel_latched: std_logic_vector(1 downto 0) := (others => '0');
  signal auto_latched   : std_logic := '0';
  signal stage_latched  : std_logic_vector(1 downto 0) := (others => '0');

  constant C_INIT_SETTLE_TICKS : natural := 12000; -- approx. 120 ms at the preserved 10.016-us state tick

  signal op_idx         : integer range 0 to 255 := 0;
  signal slot_idx       : integer range 0 to C_V38EK_LAST_INIT_SLOT := 0;
  signal result_idx     : integer range 0 to 15 := 0;
  signal out_idx        : integer range 0 to 7 := 0;
  signal afe_idx        : integer range 0 to 15 := 0;
  signal slot_wait_count : unsigned(15 downto 0) := (others => '0');
  signal slot_wait_target: unsigned(15 downto 0) := (others => '0');
  signal wait_cnt       : natural range 0 to C_INIT_SETTLE_TICKS := 0;
  signal is_read_op     : std_logic := '1';
  signal is_original_rd : std_logic := '0';
  signal is_restore_wr  : std_logic := '0';
  signal is_bank_verify_rd : std_logic := '0';
  signal defer_phys_bank_update : std_logic := '0';

  signal preinit_action : t_preinit_action := PREINIT_READ_ORIGINAL;
  signal init_action    : t_init_action := INIT_DECODE;
  signal pending_bank_r : std_logic_vector(7 downto 0) := (others => '0');
  signal pending_reg_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal pending_data_r : std_logic_vector(7 downto 0) := (others => '0');
  signal bank_verify_expected_r : std_logic_vector(7 downto 0) := (others => '0');
  signal bank_verify_ok_r       : std_logic := '0';
  signal original_ff_valid_r    : std_logic := '0';

  signal reg_addr       : std_logic_vector(7 downto 0) := (others => '0');
  signal write_data     : std_logic_vector(7 downto 0) := (others => '0');
  signal byte_tx        : std_logic_vector(7 downto 0) := (others => '0');
  signal data_rx        : std_logic_vector(7 downto 0) := (others => '0');
  signal bit_idx        : integer range 0 to 7 := 7;
  signal cur_error      : std_logic := '0';

  signal values_r       : std_logic_vector(127 downto 0) := (others => '0');
  signal output_values_r: std_logic_vector(63 downto 0) := (others => '0');
  signal afe_values_r   : std_logic_vector(127 downto 0) := (others => '0');
  signal read_err_r     : std_logic_vector(15 downto 0) := (others => '0');
  signal aux_err_r      : std_logic_vector(15 downto 0) := (others => '0');
  signal afe_err_r      : std_logic_vector(15 downto 0) := (others => '0');
  signal write_err_r    : std_logic_vector(7 downto 0) := (others => '0');
  signal original_ff_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal restored_ff_r  : std_logic_vector(7 downto 0) := (others => '0');
  -- meta_bank_r is the requested table/diagnostic bank.  phys_bank_r is the
  -- last bank proven by a successful 0xFF read, a verified D2 bank selection,
  -- or an acknowledged explicit 0xFF write outside the D2 selection helper.
  signal meta_bank_r       : std_logic_vector(7 downto 0) := (others => '0');
  signal phys_bank_r       : std_logic_vector(7 downto 0) := (others => '0');
  signal phys_bank_valid_r : std_logic := '0';
  signal any_error_r    : std_logic := '0';
  signal busy_r         : std_logic := '0';
  signal done_r         : std_logic := '0';
  signal scl_oen_r      : std_logic := '1';
  signal sda_oen_r      : std_logic := '1';
  signal last_op_r      : std_logic_vector(2 downto 0) := "000";
  signal last_ack_r     : std_logic := '1';
  signal first_error_valid_r : std_logic := '0';
  signal first_error_code_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal first_error_step_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal first_error_meta_bank_r : std_logic_vector(7 downto 0) := (others => '0');
  signal first_error_phys_bank_r : std_logic_vector(7 downto 0) := (others => '0');
  signal first_error_reg_r   : std_logic_vector(7 downto 0) := (others => '0');
  signal first_error_data_r  : std_logic_vector(7 downto 0) := (others => '0');
  signal nack_count_r        : unsigned(15 downto 0) := (others => '0');
  signal nack_log_count_r    : unsigned(3 downto 0) := (others => '0');
  signal nack_log_overflow_r : std_logic := '0';
  signal nack_log_r          : t_nack_log := (others => (others => '0'));
  signal timeout_count_r     : unsigned(15 downto 0) := (others => '0');
  signal scl_low_released_count : natural range 0 to CLK_HZ/50000 := 0;
  signal scl_timeout_seen_r  : std_logic := '0';
  signal scl_oen_previous_r  : std_logic := '1';
  signal scl_release_grace_r : natural range 0 to 5 := 0;

  -- Z9: the physical open-drain inputs are asynchronous to clk.  Each raw
  -- input is confined to the first stage of a dedicated two-register
  -- synchronizer.  Protocol logic consumes only the filtered value below.
  attribute ASYNC_REG : string;
  attribute SHREG_EXTRACT : string;
  signal sda_sync_r : std_logic_vector(1 downto 0) := (others => '1');
  signal scl_sync_r : std_logic_vector(1 downto 0) := (others => '1');
  attribute ASYNC_REG of sda_sync_r : signal is "TRUE";
  attribute ASYNC_REG of scl_sync_r : signal is "TRUE";
  attribute SHREG_EXTRACT of sda_sync_r : signal is "NO";
  attribute SHREG_EXTRACT of scl_sync_r : signal is "NO";

  signal sda_filter_candidate_r : std_logic := '1';
  signal scl_filter_candidate_r : std_logic := '1';
  signal sda_filter_count_r : natural range 0 to 2 := 0;
  signal scl_filter_count_r : natural range 0 to 2 := 0;
  signal sda_filtered_r : std_logic := '1';
  signal scl_filtered_r : std_logic := '1';
begin
  scl_oen         <= scl_oen_r;
  sda_oen         <= sda_oen_r;
  busy            <= busy_r;
  done            <= done_r;
  any_error       <= any_error_r;
  values          <= values_r;
  output_values   <= output_values_r;
  afe_values      <= afe_values_r;
  read_error_mask <= read_err_r;
  aux_error_mask  <= aux_err_r;
  afe_error_mask  <= afe_err_r;
  write_error_mask<= write_err_r;
  original_ff     <= original_ff_r;
  restored_ff     <= restored_ff_r;
  meta_bank       <= meta_bank_r;
  phys_bank       <= phys_bank_r;
  phys_bank_valid <= phys_bank_valid_r;
  range_dbg       <= range_latched;
  window_dbg      <= window_latched;
  poll_only_dbg   <= mode_poll_only_latched;
  output_dbg      <= output_latched;
  stage_dbg       <= stage_latched;
  op_index_dbg    <= std_logic_vector(to_unsigned(op_idx mod 64, 6));
  state_dbg        <= x"80" when mode_poll_only_latched = '1' else x"34";
  autoinit_fsm_dbg <= std_logic_vector(to_unsigned(t_phase'pos(phase), 8));
  step_index_dbg   <= std_logic_vector(to_unsigned(op_idx, 8));
  table_length_dbg <= std_logic_vector(to_unsigned(C_V38EK_LAST_INIT_SLOT + 1, 16));
  last_op_dbg      <= last_op_r;
  last_reg_dbg     <= reg_addr;
  last_wdata_dbg   <= write_data;
  last_rdata_dbg   <= data_rx;
  last_ack_dbg     <= last_ack_r;
  first_error_valid_dbg <= first_error_valid_r;
  first_error_code_dbg  <= first_error_code_r;
  first_error_step_dbg  <= first_error_step_r;
  first_error_meta_bank_dbg <= first_error_meta_bank_r;
  first_error_phys_bank_dbg <= first_error_phys_bank_r;
  first_error_reg_dbg   <= first_error_reg_r;
  first_error_data_dbg  <= first_error_data_r;
  nack_count_dbg        <= std_logic_vector(nack_count_r);
  nack_log_count_dbg    <= std_logic_vector(nack_log_count_r);
  nack_log_overflow_dbg <= nack_log_overflow_r;
  timeout_count_dbg     <= std_logic_vector(timeout_count_r);
  i2c_fsm_dbg           <= std_logic_vector(to_unsigned(t_state'pos(state), 8));

  gen_nack_log : for i in 0 to 7 generate
    nack_log_dbg((i + 1) * 64 - 1 downto i * 64) <= nack_log_r(i);
  end generate;

  -- Two flip-flops absorb asynchronous input timing.  A candidate transition
  -- reaches the protocol domain only after three consecutive matching samples
  -- from the second synchronizer stage.  This changes neither the I2C state
  -- sequence nor the ACK sampling state (Z8 remains deferred).
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sda_sync_r <= (others => '1');
        scl_sync_r <= (others => '1');
        sda_filter_candidate_r <= '1';
        scl_filter_candidate_r <= '1';
        sda_filter_count_r <= 0;
        scl_filter_count_r <= 0;
        sda_filtered_r <= '1';
        scl_filtered_r <= '1';
      else
        sda_sync_r(0) <= sda_i;
        sda_sync_r(1) <= sda_sync_r(0);
        scl_sync_r(0) <= scl_i;
        scl_sync_r(1) <= scl_sync_r(0);

        if sda_sync_r(1) /= sda_filter_candidate_r then
          sda_filter_candidate_r <= sda_sync_r(1);
          sda_filter_count_r <= 1;
        elsif sda_filter_count_r < 2 then
          sda_filter_count_r <= sda_filter_count_r + 1;
        else
          sda_filtered_r <= sda_filter_candidate_r;
        end if;

        if scl_sync_r(1) /= scl_filter_candidate_r then
          scl_filter_candidate_r <= scl_sync_r(1);
          scl_filter_count_r <= 1;
        elsif scl_filter_count_r < 2 then
          scl_filter_count_r <= scl_filter_count_r + 1;
        else
          scl_filtered_r <= scl_filter_candidate_r;
        end if;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if tick_cnt = DIVIDER then
        tick_cnt <= 0;
        tick <= '1';
      else
        tick_cnt <= tick_cnt + 1;
        tick <= '0';
      end if;
    end if;
  end process;

  -- Passive controller watchdog.  It never retries or changes the transaction
  -- stream; it records a bounded first failure if released SCL remains low for
  -- 20 us cumulatively during one transaction.  The five-clk release grace is
  -- exactly the maximum two-FF plus three-sample-filter observation latency;
  -- it prevents that intentional latency from looking like clock stretching.
  process(clk)
  begin
    if rising_edge(clk) then
      scl_oen_previous_r <= scl_oen_r;
      if rst = '1' or busy_r = '0' or state = SETUP_OP then
        scl_low_released_count <= 0;
        scl_timeout_seen_r <= '0';
        scl_release_grace_r <= 0;
      elsif scl_oen_r = '0' then
        scl_release_grace_r <= 0;
      elsif scl_oen_previous_r = '0' then
        scl_release_grace_r <= 5;
      elsif scl_release_grace_r > 0 then
        scl_release_grace_r <= scl_release_grace_r - 1;
      elsif scl_filtered_r = '0' and scl_timeout_seen_r = '0' then
        if scl_low_released_count = CLK_HZ/50000 then
          scl_timeout_seen_r <= '1';
        else
          scl_low_released_count <= scl_low_released_count + 1;
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable op_vec : std_logic_vector(23 downto 0);
    variable do_i2c : boolean;
    procedure record_nack(constant phase_code : in std_logic_vector(7 downto 0)) is
      variable entry_v : std_logic_vector(63 downto 0);
      variable index_v : natural range 0 to 7;
    begin
      if to_integer(nack_log_count_r) < 8 then
        index_v := to_integer(nack_log_count_r);
        entry_v := (others => '0');
        entry_v(7 downto 0)   := std_logic_vector(to_unsigned(op_idx, 8));
        entry_v(15 downto 8)  := phase_code;
        entry_v(23 downto 16) := reg_addr;
        entry_v(31 downto 24) := write_data;
        entry_v(39 downto 32) := phys_bank_r;
        entry_v(47 downto 40) := meta_bank_r;
        entry_v(48)            := '1';
        entry_v(49)            := phys_bank_valid_r;
        nack_log_r(index_v) <= entry_v;
        nack_log_count_r <= nack_log_count_r + 1;
      else
        nack_log_overflow_r <= '1';
      end if;
    end procedure;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
        phase <= PH_ORIGINAL;
        scl_oen_r <= '1';
        sda_oen_r <= '1';
        busy_r <= '0';
        done_r <= '0';
        start_latched <= '0';
        range_latched <= "00";
        window_latched <= "000";
        mode_poll_only_latched <= '0';
        output_latched <= (others => '0');
        channel_latched <= (others => '0');
        auto_latched <= '0';
        stage_latched <= (others => '0');
        any_error_r <= '0';
        values_r <= (others => '0');
        output_values_r <= (others => '0');
        afe_values_r <= (others => '0');
        read_err_r <= (others => '0');
        aux_err_r <= (others => '0');
        afe_err_r <= (others => '0');
        write_err_r <= (others => '0');
        original_ff_r <= (others => '0');
        restored_ff_r <= (others => '0');
        meta_bank_r <= (others => '0');
        phys_bank_r <= (others => '0');
        phys_bank_valid_r <= '0';
        op_idx <= 0;
        slot_idx <= 0;
        result_idx <= 0;
        out_idx <= 0;
        afe_idx <= 0;
        slot_wait_count <= (others => '0');
        slot_wait_target <= (others => '0');
        wait_cnt <= 0;
        reg_addr <= (others => '0');
        write_data <= (others => '0');
        byte_tx <= (others => '0');
        data_rx <= (others => '0');
        bit_idx <= 7;
        cur_error <= '0';
        last_op_r <= "000";
        last_ack_r <= '1';
        first_error_valid_r <= '0';
        first_error_code_r <= (others => '0');
        first_error_step_r <= (others => '0');
        first_error_meta_bank_r <= (others => '0');
        first_error_phys_bank_r <= (others => '0');
        first_error_reg_r <= (others => '0');
        first_error_data_r <= (others => '0');
        nack_count_r <= (others => '0');
        nack_log_count_r <= (others => '0');
        nack_log_overflow_r <= '0';
        nack_log_r <= (others => (others => '0'));
        timeout_count_r <= (others => '0');
        is_read_op <= '1';
        is_original_rd <= '0';
        is_restore_wr <= '0';
        is_bank_verify_rd <= '0';
        defer_phys_bank_update <= '0';
        preinit_action <= PREINIT_READ_ORIGINAL;
        init_action <= INIT_DECODE;
        pending_bank_r <= (others => '0');
        pending_reg_r <= (others => '0');
        pending_data_r <= (others => '0');
        bank_verify_expected_r <= (others => '0');
        bank_verify_ok_r <= '0';
        original_ff_valid_r <= '0';
      else
        if start = '1' and busy_r = '0' then
          start_latched <= '1';
        end if;

        if tick = '1' then
          case state is
            when IDLE =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              busy_r <= '0';
              if start = '1' or start_latched = '1' then
                start_latched <= '0';
                range_latched <= range_sel;
                window_latched <= window_sel;
                mode_poll_only_latched <= poll_only;
                output_latched <= output_sel;
                channel_latched <= channel_sel;
                auto_latched <= auto_enable;
                stage_latched <= stage_sel;
                busy_r <= '1';
                done_r <= '0';
                any_error_r <= '0';
                values_r <= (others => '0');
                output_values_r <= (others => '0');
                afe_values_r <= (others => '0');
                        read_err_r <= (others => '0');
                aux_err_r <= (others => '0');
                afe_err_r <= (others => '0');
                write_err_r <= (others => '0');
                original_ff_r <= (others => '0');
                restored_ff_r <= (others => '0');
                meta_bank_r <= (others => '0');
                phys_bank_r <= (others => '0');
                phys_bank_valid_r <= '0';
                last_op_r <= "000";
                last_ack_r <= '1';
                first_error_valid_r <= '0';
                first_error_code_r <= (others => '0');
                first_error_step_r <= (others => '0');
                first_error_meta_bank_r <= (others => '0');
                first_error_phys_bank_r <= (others => '0');
                first_error_reg_r <= (others => '0');
                first_error_data_r <= (others => '0');
                nack_count_r <= (others => '0');
                nack_log_count_r <= (others => '0');
                nack_log_overflow_r <= '0';
                nack_log_r <= (others => (others => '0'));
                timeout_count_r <= (others => '0');
                is_read_op <= '1';
                is_original_rd <= '0';
                is_restore_wr <= '0';
                is_bank_verify_rd <= '0';
                defer_phys_bank_update <= '0';
                preinit_action <= PREINIT_READ_ORIGINAL;
                init_action <= INIT_DECODE;
                pending_bank_r <= (others => '0');
                pending_reg_r <= (others => '0');
                pending_data_r <= (others => '0');
                bank_verify_expected_r <= (others => '0');
                bank_verify_ok_r <= '0';
                original_ff_valid_r <= '0';
                op_idx <= 0;
                slot_idx <= 0;
                result_idx <= 0;
                out_idx <= 0;
                afe_idx <= 0;
                slot_wait_count <= (others => '0');
                slot_wait_target <= (others => '0');
                        wait_cnt <= 0;
                phase <= PH_ORIGINAL;
                state <= SETUP_OP;
              end if;

            when SETUP_OP =>
              data_rx <= (others => '0');
              bit_idx <= 7;
              cur_error <= '0';
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              reg_addr <= C_V38EK_BANK_SELECT_REG;
              write_data <= (others => '0');
              is_read_op <= '1';
              is_original_rd <= '0';
              is_restore_wr <= '0';
              is_bank_verify_rd <= '0';
              defer_phys_bank_update <= '0';
              bank_verify_ok_r <= '0';
              do_i2c := true;
              last_op_r <= "001"; -- read

              -- SDA must be released before a START.  Preserve this as a bus
              -- stuck diagnosis even though a low SDA would look like ACKs.
              if sda_filtered_r = '0' and first_error_valid_r = '0' then
                first_error_valid_r <= '1';
                first_error_code_r <= x"06"; -- SDA_STUCK_LOW
                first_error_step_r <= std_logic_vector(to_unsigned(op_idx, 8));
                first_error_meta_bank_r <= meta_bank_r;
                first_error_phys_bank_r <= phys_bank_r;
                first_error_reg_r <= reg_addr;
                first_error_data_r <= write_data;
                any_error_r <= '1';
              end if;

              case phase is
                when PH_ORIGINAL =>
                  case preinit_action is
                    when PREINIT_READ_ORIGINAL =>
                      is_read_op <= '1';
                      is_original_rd <= '1';
                      reg_addr <= C_V38EK_BANK_SELECT_REG;

                    when PREINIT_FORCE_BANK0_WRITE =>
                      last_op_r <= "101"; -- verified-selection write
                      is_read_op <= '0';
                      defer_phys_bank_update <= '1';
                      reg_addr <= C_V38EK_BANK_SELECT_REG;
                      write_data <= C_V38EK_BANK0;
                      meta_bank_r <= C_V38EK_BANK0;
                      bank_verify_expected_r <= C_V38EK_BANK0;

                    when PREINIT_FORCE_BANK0_VERIFY =>
                      last_op_r <= "110"; -- verified-selection readback
                      is_read_op <= '1';
                      is_bank_verify_rd <= '1';
                      reg_addr <= C_V38EK_BANK_SELECT_REG;
                      meta_bank_r <= C_V38EK_BANK0;
                      bank_verify_expected_r <= C_V38EK_BANK0;
                  end case;

                when PH_INIT =>
                  case init_action is
                    when INIT_DECODE =>
                      op_vec := c_v38ek_effective_init_op_for_slot(slot_idx, range_latched, output_latched, channel_latched, auto_latched, stage_latched, ENABLE_MAREK_INIT_TABLE);
                      if op_vec(23 downto 16) = x"FD" then
                        last_op_r <= "100"; -- table NOP
                        do_i2c := false;
                        state <= NEXT_OP;
                      elsif op_vec(23 downto 16) = x"FE" then
                        last_op_r <= "011"; -- table delay
                        do_i2c := false;
                        slot_wait_count <= (others => '0');
                        slot_wait_target <= unsigned(op_vec(15 downto 0));
                        state <= WAIT_SLOT;
                      else
                        pending_bank_r <= op_vec(23 downto 16);
                        pending_reg_r <= op_vec(15 downto 8);
                        pending_data_r <= op_vec(7 downto 0);
                        meta_bank_r <= op_vec(23 downto 16);

                        -- Production D2 uses verified physical-bank selection.
                        -- The table-disabled D2b profile intentionally follows
                        -- the D1 direct-write path for the retained overlay so
                        -- that the experiment remains D1 + Z5-ALT, not a D2
                        -- hybrid.
                        if ENABLE_MAREK_INIT_TABLE = 0 then
                          last_op_r <= "010";
                          is_read_op <= '0';
                          reg_addr <= op_vec(15 downto 8);
                          write_data <= op_vec(7 downto 0);
                          init_action <= INIT_TARGET_WRITE;
                        elsif phys_bank_valid_r = '1' and phys_bank_r = op_vec(23 downto 16) then
                          last_op_r <= "010"; -- verified-bank target write
                          is_read_op <= '0';
                          reg_addr <= op_vec(15 downto 8);
                          write_data <= op_vec(7 downto 0);
                          init_action <= INIT_TARGET_WRITE;
                        else
                          last_op_r <= "101"; -- physical bank-select write
                          is_read_op <= '0';
                          defer_phys_bank_update <= '1';
                          reg_addr <= C_V38EK_BANK_SELECT_REG;
                          write_data <= op_vec(23 downto 16);
                          bank_verify_expected_r <= op_vec(23 downto 16);
                          init_action <= INIT_BANK_WRITE;
                        end if;
                      end if;

                    when INIT_BANK_WRITE =>
                      -- Defensive replay point.  Normal flow reaches this
                      -- action at NEXT_OP immediately after the selector write.
                      last_op_r <= "101";
                      is_read_op <= '0';
                      defer_phys_bank_update <= '1';
                      meta_bank_r <= pending_bank_r;
                      reg_addr <= C_V38EK_BANK_SELECT_REG;
                      write_data <= pending_bank_r;
                      bank_verify_expected_r <= pending_bank_r;

                    when INIT_BANK_VERIFY =>
                      last_op_r <= "110";
                      is_read_op <= '1';
                      is_bank_verify_rd <= '1';
                      meta_bank_r <= pending_bank_r;
                      reg_addr <= C_V38EK_BANK_SELECT_REG;
                      bank_verify_expected_r <= pending_bank_r;

                    when INIT_TARGET_WRITE =>
                      last_op_r <= "010";
                      is_read_op <= '0';
                      meta_bank_r <= pending_bank_r;
                      reg_addr <= pending_reg_r;
                      write_data <= pending_data_r;
                  end case;

                when PH_WIN_BANK =>
                  last_op_r <= "010";
                  is_read_op <= '0';
                  reg_addr <= C_V38EK_BANK_SELECT_REG;
                  write_data <= C_V38EK_BANK0;
                  meta_bank_r <= C_V38EK_BANK0;

                when PH_WIN_READ =>
                  is_read_op <= '1';
                  reg_addr <= c_v38ek_bank0_window_reg(window_latched, result_idx);
                  meta_bank_r <= C_V38EK_BANK0;

                when PH_OUT_BANK =>
                  last_op_r <= "010";
                  is_read_op <= '0';
                  reg_addr <= C_V38EK_BANK_SELECT_REG;
                  write_data <= C_V38EK_BANK1;
                  meta_bank_r <= C_V38EK_BANK1;

                when PH_OUT_READ =>
                  is_read_op <= '1';
                  reg_addr <= c_v38ek_bank1_output_reg(out_idx);
                  meta_bank_r <= C_V38EK_BANK1;

                when PH_AFE_BANK =>
                  last_op_r <= "010";
                  is_read_op <= '0';
                  reg_addr <= C_V38EK_BANK_SELECT_REG;
                  write_data <= c_v38ek_format_bank(afe_idx);
                  meta_bank_r <= c_v38ek_format_bank(afe_idx);

                when PH_AFE_READ =>
                  is_read_op <= '1';
                  reg_addr <= x"F0";
                  meta_bank_r <= c_v38ek_format_bank(afe_idx);

                when PH_RESTORE =>
                  if ENABLE_MAREK_INIT_TABLE = 0 or original_ff_valid_r = '1' then
                    last_op_r <= "010";
                    is_read_op <= '0';
                    is_restore_wr <= '1';
                    reg_addr <= C_V38EK_BANK_SELECT_REG;
                    write_data <= original_ff_r;
                    restored_ff_r <= original_ff_r;
                    meta_bank_r <= original_ff_r;
                  else
                    -- Never write an untrusted op-0 readback into 0xFF.
                    do_i2c := false;
                    write_err_r(7) <= '1';
                    state <= NEXT_OP;
                  end if;
              end case;

              if do_i2c then
                byte_tx <= NVP_ADDR_W;
                state <= START_W_A;
              end if;

            when START_W_A =>
              scl_oen_r <= '1';
              sda_oen_r <= '0';
              state <= START_W_B;

            when START_W_B =>
              scl_oen_r <= '0';
              sda_oen_r <= '0';
              state <= SEND_W_LOW;

            when SEND_W_LOW =>
              scl_oen_r <= '0';
              if byte_tx(bit_idx) = '1' then sda_oen_r <= '1'; else sda_oen_r <= '0'; end if;
              state <= SEND_W_HIGH;

            when SEND_W_HIGH =>
              scl_oen_r <= '1';
              if bit_idx = 0 then
                state <= ACK_W_LOW;
              else
                bit_idx <= bit_idx - 1;
                state <= SEND_W_LOW;
              end if;

            when ACK_W_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= ACK_W_HIGH;

            when ACK_W_HIGH =>
              scl_oen_r <= '1';
              if sda_filtered_r /= '0' then
                cur_error <= '1'; last_ack_r <= '0';
                if nack_count_r /= x"FFFF" then nack_count_r <= nack_count_r + 1; end if;
                record_nack(x"01");
                if first_error_valid_r = '0' then
                  first_error_valid_r <= '1'; first_error_code_r <= x"01";
                  first_error_step_r <= std_logic_vector(to_unsigned(op_idx,8));
                  first_error_meta_bank_r <= meta_bank_r;
                  first_error_phys_bank_r <= phys_bank_r;
                  first_error_reg_r <= reg_addr;
                  first_error_data_r <= write_data;
                end if;
              else last_ack_r <= '1'; end if;
              byte_tx <= reg_addr;
              bit_idx <= 7;
              state <= SEND_REG_LOW;

            when SEND_REG_LOW =>
              scl_oen_r <= '0';
              if byte_tx(bit_idx) = '1' then sda_oen_r <= '1'; else sda_oen_r <= '0'; end if;
              state <= SEND_REG_HIGH;

            when SEND_REG_HIGH =>
              scl_oen_r <= '1';
              if bit_idx = 0 then
                state <= ACK_REG_LOW;
              else
                bit_idx <= bit_idx - 1;
                state <= SEND_REG_LOW;
              end if;

            when ACK_REG_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= ACK_REG_HIGH;

            when ACK_REG_HIGH =>
              scl_oen_r <= '1';
              if sda_filtered_r /= '0' then
                cur_error <= '1'; last_ack_r <= '0';
                if nack_count_r /= x"FFFF" then nack_count_r <= nack_count_r + 1; end if;
                record_nack(x"02");
                if first_error_valid_r = '0' then
                  first_error_valid_r <= '1'; first_error_code_r <= x"02";
                  first_error_step_r <= std_logic_vector(to_unsigned(op_idx,8));
                  first_error_meta_bank_r <= meta_bank_r;
                  first_error_phys_bank_r <= phys_bank_r;
                  first_error_reg_r <= reg_addr;
                  first_error_data_r <= write_data;
                end if;
              else last_ack_r <= '1'; end if;
              if is_read_op = '1' then
                state <= REP_LOW;
              else
                byte_tx <= write_data;
                bit_idx <= 7;
                state <= SEND_DATA_LOW;
              end if;

            when SEND_DATA_LOW =>
              scl_oen_r <= '0';
              if byte_tx(bit_idx) = '1' then sda_oen_r <= '1'; else sda_oen_r <= '0'; end if;
              state <= SEND_DATA_HIGH;

            when SEND_DATA_HIGH =>
              scl_oen_r <= '1';
              if bit_idx = 0 then
                state <= ACK_DATA_LOW;
              else
                bit_idx <= bit_idx - 1;
                state <= SEND_DATA_LOW;
              end if;

            when ACK_DATA_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= ACK_DATA_HIGH;

            when ACK_DATA_HIGH =>
              scl_oen_r <= '1';
              if sda_filtered_r /= '0' then
                cur_error <= '1'; last_ack_r <= '0';
                if nack_count_r /= x"FFFF" then nack_count_r <= nack_count_r + 1; end if;
                record_nack(x"03");
                if first_error_valid_r = '0' then
                  first_error_valid_r <= '1'; first_error_code_r <= x"03";
                  first_error_step_r <= std_logic_vector(to_unsigned(op_idx,8));
                  first_error_meta_bank_r <= meta_bank_r;
                  first_error_phys_bank_r <= phys_bank_r;
                  first_error_reg_r <= reg_addr;
                  first_error_data_r <= write_data;
                end if;
              else last_ack_r <= '1'; end if;
              state <= STOP_A;

            when REP_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= REP_HIGH;

            when REP_HIGH =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              state <= REP_START_A;

            when REP_START_A =>
              scl_oen_r <= '1';
              sda_oen_r <= '0';
              state <= REP_START_B;

            when REP_START_B =>
              scl_oen_r <= '0';
              sda_oen_r <= '0';
              byte_tx <= NVP_ADDR_R;
              bit_idx <= 7;
              state <= SEND_R_LOW;

            when SEND_R_LOW =>
              scl_oen_r <= '0';
              if byte_tx(bit_idx) = '1' then sda_oen_r <= '1'; else sda_oen_r <= '0'; end if;
              state <= SEND_R_HIGH;

            when SEND_R_HIGH =>
              scl_oen_r <= '1';
              if bit_idx = 0 then
                state <= ACK_R_LOW;
              else
                bit_idx <= bit_idx - 1;
                state <= SEND_R_LOW;
              end if;

            when ACK_R_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= ACK_R_HIGH;

            when ACK_R_HIGH =>
              scl_oen_r <= '1';
              if sda_filtered_r /= '0' then
                cur_error <= '1'; last_ack_r <= '0';
                if nack_count_r /= x"FFFF" then nack_count_r <= nack_count_r + 1; end if;
                record_nack(x"04");
                if first_error_valid_r = '0' then
                  first_error_valid_r <= '1'; first_error_code_r <= x"04";
                  first_error_step_r <= std_logic_vector(to_unsigned(op_idx,8));
                  first_error_meta_bank_r <= meta_bank_r;
                  first_error_phys_bank_r <= phys_bank_r;
                  first_error_reg_r <= reg_addr;
                  first_error_data_r <= write_data;
                end if;
              else last_ack_r <= '1'; end if;
              bit_idx <= 7;
              state <= READ_LOW;

            when READ_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= READ_HIGH;

            when READ_HIGH =>
              scl_oen_r <= '1';
              data_rx(bit_idx) <= sda_filtered_r;
              if bit_idx = 0 then
                state <= MASTER_NACK_LOW;
              else
                bit_idx <= bit_idx - 1;
                state <= READ_LOW;
              end if;

            when MASTER_NACK_LOW =>
              scl_oen_r <= '0';
              sda_oen_r <= '1';
              state <= MASTER_NACK_HIGH;

            when MASTER_NACK_HIGH =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              state <= STOP_A;

            when STOP_A =>
              scl_oen_r <= '0';
              sda_oen_r <= '0';
              state <= STOP_B;

            when STOP_B =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              state <= STORE_RESULT;

            when STORE_RESULT =>
              if scl_timeout_seen_r = '1' then
                any_error_r <= '1';
                if timeout_count_r /= x"FFFF" then timeout_count_r <= timeout_count_r + 1; end if;
                if first_error_valid_r = '0' then
                  first_error_valid_r <= '1'; first_error_code_r <= x"07";
                  first_error_step_r <= std_logic_vector(to_unsigned(op_idx,8));
                  first_error_meta_bank_r <= meta_bank_r;
                  first_error_phys_bank_r <= phys_bank_r;
                  first_error_reg_r <= reg_addr;
                  first_error_data_r <= write_data;
                end if;
              end if;
              if cur_error = '1' then any_error_r <= '1'; end if;

              if is_read_op = '1' then
                if is_bank_verify_rd = '1' then
                  if cur_error = '0' and scl_timeout_seen_r = '0' and
                     data_rx = bank_verify_expected_r then
                    phys_bank_r <= bank_verify_expected_r;
                    phys_bank_valid_r <= '1';
                    bank_verify_ok_r <= '1';
                  else
                    -- A target write is permitted only after exact selector
                    -- readback.  Transport failure or a value mismatch makes
                    -- the physical-bank cache unusable for that target.
                    phys_bank_valid_r <= '0';
                    bank_verify_ok_r <= '0';
                    write_err_r(1) <= '1';
                    any_error_r <= '1';
                    if cur_error = '0' and scl_timeout_seen_r = '0' and
                       data_rx /= bank_verify_expected_r and
                       first_error_valid_r = '0' then
                      first_error_valid_r <= '1';
                      first_error_code_r <= x"08"; -- BANK_VERIFY_MISMATCH
                      first_error_step_r <= std_logic_vector(to_unsigned(op_idx, 8));
                      first_error_meta_bank_r <= meta_bank_r;
                      first_error_phys_bank_r <= phys_bank_r;
                      first_error_reg_r <= C_V38EK_BANK_SELECT_REG;
                      first_error_data_r <= bank_verify_expected_r;
                    end if;
                  end if;
                elsif is_original_rd = '1' then
                  original_ff_r <= data_rx;
                  if cur_error = '0' and scl_timeout_seen_r = '0' then
                    meta_bank_r <= data_rx;
                    phys_bank_r <= data_rx;
                    phys_bank_valid_r <= '1';
                    original_ff_valid_r <= '1';
                  else
                    original_ff_valid_r <= '0';
                  end if;
                  if cur_error = '1' or scl_timeout_seen_r = '1' then
                    write_err_r(0) <= '1';
                  end if;
                elsif phase = PH_WIN_READ then
                  case result_idx is
                    when 0  => values_r(7 downto 0) <= data_rx; read_err_r(0) <= cur_error;
                    when 1  => values_r(15 downto 8) <= data_rx; read_err_r(1) <= cur_error;
                    when 2  => values_r(23 downto 16) <= data_rx; read_err_r(2) <= cur_error;
                    when 3  => values_r(31 downto 24) <= data_rx; read_err_r(3) <= cur_error;
                    when 4  => values_r(39 downto 32) <= data_rx; read_err_r(4) <= cur_error;
                    when 5  => values_r(47 downto 40) <= data_rx; read_err_r(5) <= cur_error;
                    when 6  => values_r(55 downto 48) <= data_rx; read_err_r(6) <= cur_error;
                    when 7  => values_r(63 downto 56) <= data_rx; read_err_r(7) <= cur_error;
                    when 8  => values_r(71 downto 64) <= data_rx; read_err_r(8) <= cur_error;
                    when 9  => values_r(79 downto 72) <= data_rx; read_err_r(9) <= cur_error;
                    when 10 => values_r(87 downto 80) <= data_rx; read_err_r(10) <= cur_error;
                    when 11 => values_r(95 downto 88) <= data_rx; read_err_r(11) <= cur_error;
                    when 12 => values_r(103 downto 96) <= data_rx; read_err_r(12) <= cur_error;
                    when 13 => values_r(111 downto 104) <= data_rx; read_err_r(13) <= cur_error;
                    when 14 => values_r(119 downto 112) <= data_rx; read_err_r(14) <= cur_error;
                    when others => values_r(127 downto 120) <= data_rx; read_err_r(15) <= cur_error;
                  end case;
                elsif phase = PH_OUT_READ then
                  case out_idx is
                    when 0 => output_values_r(7 downto 0) <= data_rx; aux_err_r(0) <= cur_error;
                    when 1 => output_values_r(15 downto 8) <= data_rx; aux_err_r(1) <= cur_error;
                    when 2 => output_values_r(23 downto 16) <= data_rx; aux_err_r(2) <= cur_error;
                    when 3 => output_values_r(31 downto 24) <= data_rx; aux_err_r(3) <= cur_error;
                    when 4 => output_values_r(39 downto 32) <= data_rx; aux_err_r(4) <= cur_error;
                    when 5 => output_values_r(47 downto 40) <= data_rx; aux_err_r(5) <= cur_error;
                    when 6 => output_values_r(55 downto 48) <= data_rx; aux_err_r(6) <= cur_error;
                    when others => output_values_r(63 downto 56) <= data_rx; aux_err_r(7) <= cur_error;
                  end case;
                elsif phase = PH_AFE_READ then
                  case afe_idx is
                    when 0  => afe_values_r(7 downto 0) <= data_rx; afe_err_r(0) <= cur_error;
                    when 1  => afe_values_r(15 downto 8) <= data_rx; afe_err_r(1) <= cur_error;
                    when 2  => afe_values_r(23 downto 16) <= data_rx; afe_err_r(2) <= cur_error;
                    when 3  => afe_values_r(31 downto 24) <= data_rx; afe_err_r(3) <= cur_error;
                    when 4  => afe_values_r(39 downto 32) <= data_rx; afe_err_r(4) <= cur_error;
                    when 5  => afe_values_r(47 downto 40) <= data_rx; afe_err_r(5) <= cur_error;
                    when 6  => afe_values_r(55 downto 48) <= data_rx; afe_err_r(6) <= cur_error;
                    when 7  => afe_values_r(63 downto 56) <= data_rx; afe_err_r(7) <= cur_error;
                    when 8  => afe_values_r(71 downto 64) <= data_rx; afe_err_r(8) <= cur_error;
                    when 9  => afe_values_r(79 downto 72) <= data_rx; afe_err_r(9) <= cur_error;
                    when 10 => afe_values_r(87 downto 80) <= data_rx; afe_err_r(10) <= cur_error;
                    when 11 => afe_values_r(95 downto 88) <= data_rx; afe_err_r(11) <= cur_error;
                    when 12 => afe_values_r(103 downto 96) <= data_rx; afe_err_r(12) <= cur_error;
                    when 13 => afe_values_r(111 downto 104) <= data_rx; afe_err_r(13) <= cur_error;
                    when 14 => afe_values_r(119 downto 112) <= data_rx; afe_err_r(14) <= cur_error;
                    when others => afe_values_r(127 downto 120) <= data_rx; afe_err_r(15) <= cur_error;
                  end case;
                end if;
              else
                if reg_addr = C_V38EK_BANK_SELECT_REG and
                   cur_error = '0' and scl_timeout_seen_r = '0' and
                   defer_phys_bank_update = '0' then
                  phys_bank_r <= write_data;
                  phys_bank_valid_r <= '1';
                elsif reg_addr = C_V38EK_BANK_SELECT_REG and
                      defer_phys_bank_update = '1' and
                      (cur_error = '1' or scl_timeout_seen_r = '1') then
                  phys_bank_valid_r <= '0';
                end if;
                if is_restore_wr = '1' then
                  if cur_error = '1' or scl_timeout_seen_r = '1' then
                    write_err_r(7) <= '1';
                  end if;
                else
                  if cur_error = '1' or scl_timeout_seen_r = '1' then
                    if reg_addr = C_V38EK_BANK_SELECT_REG then
                      write_err_r(1) <= '1';
                    else
                      write_err_r(6) <= '1';
                    end if;
                  end if;
                end if;
              end if;
              state <= NEXT_OP;

            when NEXT_OP =>
              case phase is
                when PH_ORIGINAL =>
                  case preinit_action is
                    when PREINIT_READ_ORIGINAL =>
                      if mode_poll_only_latched = '1' then
                        phase <= PH_WIN_BANK;
                        if op_idx < 255 then op_idx <= op_idx + 1; end if;
                      elsif ENABLE_MAREK_INIT_TABLE = 0 then
                        -- D2b starts retained operation 149 from the original
                        -- D1 entry sequence.  Overlay slot 0 performs the
                        -- explicit Bank-0 write.
                        phase <= PH_INIT;
                        slot_idx <= 0;
                        init_action <= INIT_DECODE;
                        if op_idx < 255 then op_idx <= op_idx + 1; end if;
                      else
                        -- Z4: always establish and verify physical Bank 0
                        -- before the first table operation.  The original bank
                        -- remains retained solely for the final restore.
                        preinit_action <= PREINIT_FORCE_BANK0_WRITE;
                      end if;
                      state <= SETUP_OP;

                    when PREINIT_FORCE_BANK0_WRITE =>
                      if cur_error = '0' and scl_timeout_seen_r = '0' then
                        preinit_action <= PREINIT_FORCE_BANK0_VERIFY;
                        state <= SETUP_OP;
                      else
                        -- The table cannot start from an unverified bank.
                        wait_cnt <= 0;
                        if op_idx < 255 then op_idx <= op_idx + 1; end if;
                        state <= WAIT_INIT;
                      end if;

                    when PREINIT_FORCE_BANK0_VERIFY =>
                      if bank_verify_ok_r = '1' then
                        phase <= PH_INIT;
                        slot_idx <= 0;
                        init_action <= INIT_DECODE;
                        if op_idx < 255 then op_idx <= op_idx + 1; end if;
                        state <= SETUP_OP;
                      else
                        -- A readback mismatch has already been logged as 0x08.
                        wait_cnt <= 0;
                        if op_idx < 255 then op_idx <= op_idx + 1; end if;
                        state <= WAIT_INIT;
                      end if;
                  end case;

                when PH_INIT =>
                  if ENABLE_MAREK_INIT_TABLE = 0 then
                    -- Direct D1 sequencing: every table slot consumes exactly
                    -- one operation index, including the disabled NOP range.
                    init_action <= INIT_DECODE;
                    if slot_idx = C_V38EK_LAST_INIT_SLOT then
                      wait_cnt <= 0;
                      state <= WAIT_INIT;
                    else
                      slot_idx <= slot_idx + 1;
                      if op_idx < 255 then op_idx <= op_idx + 1; end if;
                      state <= SETUP_OP;
                    end if;
                  elsif init_action = INIT_BANK_WRITE and
                     cur_error = '0' and scl_timeout_seen_r = '0' then
                    init_action <= INIT_BANK_VERIFY;
                    state <= SETUP_OP;
                  elsif init_action = INIT_BANK_VERIFY and bank_verify_ok_r = '1' then
                    init_action <= INIT_TARGET_WRITE;
                    state <= SETUP_OP;
                  else
                    -- NOP/delay, completed target, or a failed selector all
                    -- finish this table entry.  Selector failure deliberately
                    -- reaches here without issuing INIT_TARGET_WRITE.
                    init_action <= INIT_DECODE;
                    if slot_idx = C_V38EK_LAST_INIT_SLOT then
                      wait_cnt <= 0;
                      state <= WAIT_INIT;
                    else
                      slot_idx <= slot_idx + 1;
                      if op_idx < 255 then op_idx <= op_idx + 1; end if;
                      state <= SETUP_OP;
                    end if;
                  end if;

                when PH_WIN_BANK =>
                  result_idx <= 0;
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  phase <= PH_WIN_READ;
                  state <= SETUP_OP;

                when PH_WIN_READ =>
                  if result_idx = 15 then
                    out_idx <= 0;
                afe_idx <= 0;
                slot_wait_count <= (others => '0');
                slot_wait_target <= (others => '0');
                    phase <= PH_OUT_BANK;
                  else
                    result_idx <= result_idx + 1;
                  end if;
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  state <= SETUP_OP;

                when PH_OUT_BANK =>
                  out_idx <= 0;
                afe_idx <= 0;
                slot_wait_count <= (others => '0');
                slot_wait_target <= (others => '0');
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  phase <= PH_OUT_READ;
                  state <= SETUP_OP;

                when PH_OUT_READ =>
                  if out_idx = 7 then
                    afe_idx <= 0;
                    phase <= PH_AFE_BANK;
                  else
                    out_idx <= out_idx + 1;
                  end if;
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  state <= SETUP_OP;

                when PH_AFE_BANK =>
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  phase <= PH_AFE_READ;
                  state <= SETUP_OP;

                when PH_AFE_READ =>
                  if afe_idx = 3 then
                    phase <= PH_RESTORE;
                  else
                    afe_idx <= afe_idx + 1;
                    phase <= PH_AFE_BANK;
                  end if;
                  if op_idx < 255 then op_idx <= op_idx + 1; end if;
                  state <= SETUP_OP;

                when PH_RESTORE =>
                  state <= FINISH;
              end case;

            when WAIT_SLOT =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              if slot_wait_count >= slot_wait_target then
                state <= NEXT_OP;
              else
                slot_wait_count <= slot_wait_count + 1;
              end if;

            when WAIT_INIT =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              if wait_cnt < C_INIT_SETTLE_TICKS then
                wait_cnt <= wait_cnt + 1;
              else
                phase <= PH_WIN_BANK;
                if op_idx < 255 then op_idx <= op_idx + 1; end if;
                state <= SETUP_OP;
              end if;

            when FINISH =>
              scl_oen_r <= '1';
              sda_oen_r <= '1';
              busy_r <= '0';
              done_r <= '1';
              state <= IDLE;
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture;
