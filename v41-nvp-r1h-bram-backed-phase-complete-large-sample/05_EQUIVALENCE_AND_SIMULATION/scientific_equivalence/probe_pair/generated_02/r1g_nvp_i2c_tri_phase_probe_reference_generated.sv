`timescale 1ns/1ps

// R1f automatic post-autoinit tri-phase diagnostic.
//
// The production configuration is frozen to:
//   - 25 kHz open-drain I2C
//   - device write/read bytes 8'h60 / 8'h61
//   - safe Bank/Reg/Data 00/85/00
//   - round-robin WADDR, REGADDR, DATA target phases
//   - 10,000 physically reached target opportunities per phase
//   - 10 blocks per phase, 512 retained target-NACK indices per phase
//   - 12,000 transaction attempts per phase
//
// Count parameters exist only to make focused RTL simulation bounded.  The
// safe target and protocol bytes are localparams and cannot be retargeted.
module r1g_nvp_i2c_tri_phase_probe_reference #(
  parameter integer CLK_HZ = 62500000,
  parameter integer PROBE_I2C_HZ = 25000,
  parameter integer TARGET_OPPORTUNITIES_PER_PHASE = 10000,
  parameter integer BLOCK_COUNT_PER_PHASE = 10,
  parameter integer NACK_INDEX_CAPACITY_PER_PHASE = 512,
  parameter integer MAX_TRANSACTION_ATTEMPTS_PER_PHASE = 12000,
  parameter integer POST_INIT_GUARD_CYCLES = 62500,
  parameter integer SCL_TIMEOUT_CYCLES = CLK_HZ / 50000,
  parameter integer BUS_IDLE_TIMEOUT_CYCLES = CLK_HZ / 1000
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        init_done,
  input  logic        init_busy,
  input  logic        nvp_rst,
  input  logic        init_scl_release,
  input  logic        init_sda_release,
  input  logic        raw_scl_i,
  input  logic        raw_sda_i,
  input  logic [47:0] freerun_count,

  output logic        probe_scl_release,
  output logic        probe_sda_release,
  output logic        probe_active,
  output logic        probe_done,
  output logic        probe_aborted,
  output logic        probe_terminal,
  output logic [7:0]  probe_abort_code,
  output logic [7:0]  probe_restore_failure_code,
  output logic [31:0] probe_status,
  // Compatibility evidence for the preserved R1e lifecycle page.  These are
  // diagnostic-only sticky observations and have no fanout into probe control.
  output logic        legacy_init_done_seen,
  output logic        legacy_guard_complete,
  output logic        legacy_bus_idle_qualified,
  output logic        legacy_scl_timeout,
  output logic        legacy_bus_idle_timeout,
  output logic [47:0] probe_start_freerun,
  output logic [47:0] probe_done_freerun,

  output logic [7:0]  entry_bank,
  output logic        entry_bank_valid,
  output logic        safe_bank_select_write_ok,
  output logic        safe_bank_verify_ok,
  output logic [7:0]  safe_bank_readback,
  output logic        safe_bank_readback_valid,
  output logic [7:0]  safe_target_pre_value,
  output logic        safe_target_pre_valid,
  output logic        safe_target_pre_ok,
  output logic [7:0]  safe_target_post_value,
  output logic        safe_target_post_valid,
  output logic        safe_target_post_ok,
  output logic        original_bank_restored,
  output logic        original_bank_restore_verified,
  output logic [7:0]  restored_bank_readback,
  output logic        restored_bank_readback_valid,
  output logic        final_bus_idle,

  output logic [31:0] waddr_transaction_attempts,
  output logic [31:0] waddr_target_opportunities,
  output logic [31:0] waddr_target_acks,
  output logic [31:0] waddr_target_nacks,
  output logic [31:0] waddr_timeouts,
  output logic [15:0] waddr_first_nack_index,
  output logic [15:0] waddr_last_nack_index,
  output logic [31:0] waddr_max_consecutive_nacks,
  output logic [31:0] waddr_adjacent_nack_pairs,
  output logic [31:0] waddr_run_count,

  output logic [31:0] regaddr_transaction_attempts,
  output logic [31:0] regaddr_prereq_waddr_opportunities,
  output logic [31:0] regaddr_prereq_waddr_acks,
  output logic [31:0] regaddr_prereq_waddr_nacks,
  output logic [31:0] regaddr_target_opportunities,
  output logic [31:0] regaddr_target_acks,
  output logic [31:0] regaddr_target_nacks,
  output logic [31:0] regaddr_timeouts,
  output logic [15:0] regaddr_first_nack_index,
  output logic [15:0] regaddr_last_nack_index,
  output logic [31:0] regaddr_max_consecutive_nacks,
  output logic [31:0] regaddr_adjacent_nack_pairs,
  output logic [31:0] regaddr_run_count,

  output logic [31:0] data_transaction_attempts,
  output logic [31:0] data_prereq_waddr_opportunities,
  output logic [31:0] data_prereq_waddr_acks,
  output logic [31:0] data_prereq_waddr_nacks,
  output logic [31:0] data_prereq_regaddr_opportunities,
  output logic [31:0] data_prereq_regaddr_acks,
  output logic [31:0] data_prereq_regaddr_nacks,
  output logic [31:0] data_target_opportunities,
  output logic [31:0] data_target_acks,
  output logic [31:0] data_target_nacks,
  output logic [31:0] data_timeouts,
  output logic [15:0] data_first_nack_index,
  output logic [15:0] data_last_nack_index,
  output logic [31:0] data_max_consecutive_nacks,
  output logic [31:0] data_adjacent_nack_pairs,
  output logic [31:0] data_run_count,

  output logic [31:0] probe_timeout_count_total,
  output logic [31:0] round_robin_scheduler_rounds,
  output logic [1:0]  current_scheduler_phase,
  output logic [2:0]  attempt_limit_status,
  output logic [15:0] waddr_nack_index_stored_count,
  output logic [15:0] regaddr_nack_index_stored_count,
  output logic [15:0] data_nack_index_stored_count,
  output logic        waddr_nack_index_overflow,
  output logic        regaddr_nack_index_overflow,
  output logic        data_nack_index_overflow,

  input  logic [1:0]  index_read_phase,
  input  logic [7:0]  index_read_word,
  output logic [31:0] index_read_data,
  input  logic [1:0]  block_read_phase,
  input  logic [3:0]  block_read_index,
  output logic [31:0] block_read_nack_count
);
  localparam logic [7:0] NVP_ADDR_W = 8'h60;
  localparam logic [7:0] NVP_ADDR_R = 8'h61;
  localparam logic [7:0] SAFE_BANK = 8'h00;
  localparam logic [7:0] BANK_SELECT_REG = 8'hff;
  localparam logic [7:0] SAFE_REG = 8'h85;
  localparam logic [7:0] SAFE_DATA = 8'h00;
  localparam integer DIVIDER = CLK_HZ / (PROBE_I2C_HZ * 2);
  localparam integer TICK_CYCLES = DIVIDER + 1;
  localparam integer BLOCK_SIZE = TARGET_OPPORTUNITIES_PER_PHASE /
                                  BLOCK_COUNT_PER_PHASE;

  localparam logic [1:0] PH_WADDR = 2'd0;
  localparam logic [1:0] PH_REGADDR = 2'd1;
  localparam logic [1:0] PH_DATA = 2'd2;

  localparam logic [1:0] CMD_ADDRESS_ONLY = 2'd0;
  localparam logic [1:0] CMD_REGISTER_ONLY = 2'd1;
  localparam logic [1:0] CMD_DATA_WRITE = 2'd2;
  localparam logic [1:0] CMD_REGISTER_READ = 2'd3;

  localparam logic [7:0] ABORT_NONE = 8'h00;
  localparam logic [7:0] ABORT_ENTRY_BANK_READ = 8'h01;
  localparam logic [7:0] ABORT_SAFE_BANK_WRITE = 8'h02;
  localparam logic [7:0] ABORT_SAFE_BANK_VERIFY = 8'h03;
  localparam logic [7:0] ABORT_SAFE_TARGET_PRE = 8'h04;
  localparam logic [7:0] ABORT_ATTEMPT_LIMIT = 8'h05;
  localparam logic [7:0] ABORT_PROBE_TIMEOUT = 8'h06;
  localparam logic [7:0] ABORT_POST_BANK_VERIFY = 8'h07;
  localparam logic [7:0] ABORT_SAFE_TARGET_POST = 8'h08;
  localparam logic [7:0] ABORT_RESTORE_WRITE = 8'h09;
  localparam logic [7:0] ABORT_RESTORE_VERIFY = 8'h0a;
  localparam logic [7:0] ABORT_FINAL_BUS_IDLE = 8'h0b;

  initial begin
    if (DIVIDER < 1)
      $error("nvp_i2c_tri_phase_probe: invalid I2C divider");
    if (TARGET_OPPORTUNITIES_PER_PHASE < 1 ||
        TARGET_OPPORTUNITIES_PER_PHASE > 65535)
      $error("nvp_i2c_tri_phase_probe: target opportunities must fit 16 bits");
    if (BLOCK_COUNT_PER_PHASE < 1 || BLOCK_COUNT_PER_PHASE > 10 ||
        TARGET_OPPORTUNITIES_PER_PHASE % BLOCK_COUNT_PER_PHASE != 0)
      $error("nvp_i2c_tri_phase_probe: invalid block partition");
    if (NACK_INDEX_CAPACITY_PER_PHASE < 1 ||
        NACK_INDEX_CAPACITY_PER_PHASE > 512)
      $error("nvp_i2c_tri_phase_probe: invalid NACK index capacity");
    if (MAX_TRANSACTION_ATTEMPTS_PER_PHASE < TARGET_OPPORTUNITIES_PER_PHASE)
      $error("nvp_i2c_tri_phase_probe: attempt cap is below target count");
  end

  // Independent synchronizers and three-matching-sample filters.  No protocol
  // state consumes raw pin values directly.
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  logic [1:0] scl_sync;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  logic [1:0] sda_sync;
  logic scl_filter_candidate, sda_filter_candidate;
  logic [1:0] scl_filter_count, sda_filter_count;
  logic scl_filtered, sda_filtered;

  always_ff @(posedge clk) begin
    if (rst) begin
      scl_sync <= 2'b11;
      sda_sync <= 2'b11;
      scl_filter_candidate <= 1'b1;
      sda_filter_candidate <= 1'b1;
      scl_filter_count <= 2'b0;
      sda_filter_count <= 2'b0;
      scl_filtered <= 1'b1;
      sda_filtered <= 1'b1;
    end else begin
      scl_sync[0] <= raw_scl_i;
      scl_sync[1] <= scl_sync[0];
      sda_sync[0] <= raw_sda_i;
      sda_sync[1] <= sda_sync[0];

      if (scl_sync[1] != scl_filter_candidate) begin
        scl_filter_candidate <= scl_sync[1];
        scl_filter_count <= 2'd1;
      end else if (scl_filter_count < 2) begin
        scl_filter_count <= scl_filter_count + 1'b1;
      end else begin
        scl_filtered <= scl_filter_candidate;
      end

      if (sda_sync[1] != sda_filter_candidate) begin
        sda_filter_candidate <= sda_sync[1];
        sda_filter_count <= 2'd1;
      end else if (sda_filter_count < 2) begin
        sda_filter_count <= sda_filter_count + 1'b1;
      end else begin
        sda_filtered <= sda_filter_candidate;
      end
    end
  end

  wire bus_is_idle = scl_filtered && sda_filtered;
  wire init_terminal_gate = init_done && !init_busy && nvp_rst &&
                            init_scl_release && init_sda_release;

  typedef enum logic [5:0] {
    LL_IDLE,
    LL_WAIT_IDLE,
    LL_START_A,
    LL_START_B,
    LL_SEND_W_LOW,
    LL_SEND_W_HIGH,
    LL_ACK_W_LOW,
    LL_ACK_W_HIGH,
    LL_SEND_REG_LOW,
    LL_SEND_REG_HIGH,
    LL_ACK_REG_LOW,
    LL_ACK_REG_HIGH,
    LL_SEND_DATA_LOW,
    LL_SEND_DATA_HIGH,
    LL_ACK_DATA_LOW,
    LL_ACK_DATA_HIGH,
    LL_REP_LOW,
    LL_REP_HIGH,
    LL_REP_START_A,
    LL_REP_START_B,
    LL_SEND_R_LOW,
    LL_SEND_R_HIGH,
    LL_ACK_R_LOW,
    LL_ACK_R_HIGH,
    LL_READ_LOW,
    LL_READ_HIGH,
    LL_MASTER_NACK_LOW,
    LL_MASTER_NACK_HIGH,
    LL_STOP_A,
    LL_STOP_B,
    LL_STOP_C,
    LL_ABORT_RELEASE
  } ll_state_t;

  ll_state_t ll_state;
  logic ll_start;
  logic [1:0] ll_cmd_kind;
  logic [7:0] ll_cmd_reg, ll_cmd_data;
  logic ll_busy, ll_done, ll_success, ll_timeout;
  logic ll_waddr_reached, ll_waddr_ack;
  logic ll_reg_reached, ll_reg_ack;
  logic ll_data_reached, ll_data_ack;
  logic ll_raddr_reached, ll_raddr_ack;
  logic [7:0] ll_read_data;
  logic [1:0] ll_kind_latched;
  logic [7:0] ll_reg_latched, ll_data_latched;
  logic [7:0] ll_tx_byte;
  logic [7:0] ll_rx_byte;
  logic [2:0] ll_bit_index;
  logic ll_error;
  logic [31:0] ll_divider_count;
  logic [31:0] ll_idle_stable_count;
  logic [31:0] ll_idle_wait_count;
  logic [31:0] ll_scl_wait_count;
  logic legacy_init_done_seen_i;
  logic legacy_guard_complete_i;
  logic legacy_bus_idle_qualified_i;
  logic legacy_scl_timeout_i;
  logic legacy_ll_bus_idle_timeout_i;
  logic legacy_high_bus_idle_timeout_i;

  assign legacy_init_done_seen = legacy_init_done_seen_i;
  assign legacy_guard_complete = legacy_guard_complete_i;
  assign legacy_bus_idle_qualified = legacy_bus_idle_qualified_i;
  assign legacy_scl_timeout = legacy_scl_timeout_i;
  assign legacy_bus_idle_timeout = legacy_ll_bus_idle_timeout_i |
                                   legacy_high_bus_idle_timeout_i;

  wire ll_state_tick = ll_divider_count >= DIVIDER;
  wire ll_requires_scl_high =
    ll_state == LL_START_A || ll_state == LL_START_B ||
    ll_state == LL_SEND_W_HIGH || ll_state == LL_ACK_W_HIGH ||
    ll_state == LL_SEND_REG_HIGH || ll_state == LL_ACK_REG_HIGH ||
    ll_state == LL_SEND_DATA_HIGH || ll_state == LL_ACK_DATA_HIGH ||
    ll_state == LL_REP_HIGH || ll_state == LL_REP_START_A ||
    ll_state == LL_SEND_R_HIGH || ll_state == LL_ACK_R_HIGH ||
    ll_state == LL_READ_HIGH || ll_state == LL_MASTER_NACK_HIGH ||
    ll_state == LL_STOP_B || ll_state == LL_STOP_C;

  always_comb begin
    probe_scl_release = 1'b1;
    probe_sda_release = 1'b1;
    case (ll_state)
      LL_START_B: begin
        probe_scl_release = 1'b1;
        probe_sda_release = 1'b0;
      end
      LL_SEND_W_LOW, LL_SEND_REG_LOW, LL_SEND_DATA_LOW, LL_SEND_R_LOW: begin
        probe_scl_release = 1'b0;
        probe_sda_release = ll_tx_byte[ll_bit_index];
      end
      LL_SEND_W_HIGH, LL_SEND_REG_HIGH, LL_SEND_DATA_HIGH, LL_SEND_R_HIGH: begin
        probe_scl_release = 1'b1;
        probe_sda_release = ll_tx_byte[ll_bit_index];
      end
      LL_ACK_W_LOW, LL_ACK_REG_LOW, LL_ACK_DATA_LOW, LL_ACK_R_LOW,
      LL_READ_LOW, LL_MASTER_NACK_LOW, LL_REP_LOW: begin
        probe_scl_release = 1'b0;
        probe_sda_release = 1'b1;
      end
      LL_ACK_W_HIGH, LL_ACK_REG_HIGH, LL_ACK_DATA_HIGH, LL_ACK_R_HIGH,
      LL_READ_HIGH, LL_MASTER_NACK_HIGH, LL_REP_HIGH: begin
        probe_scl_release = 1'b1;
        probe_sda_release = 1'b1;
      end
      LL_REP_START_A: begin
        probe_scl_release = 1'b1;
        probe_sda_release = 1'b0;
      end
      LL_REP_START_B, LL_STOP_A: begin
        probe_scl_release = 1'b0;
        probe_sda_release = 1'b0;
      end
      LL_STOP_B: begin
        probe_scl_release = 1'b1;
        probe_sda_release = 1'b0;
      end
      default: begin
        probe_scl_release = 1'b1;
        probe_sda_release = 1'b1;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      ll_state <= LL_IDLE;
      ll_busy <= 1'b0;
      ll_done <= 1'b0;
      ll_success <= 1'b0;
      ll_timeout <= 1'b0;
      ll_waddr_reached <= 1'b0;
      ll_waddr_ack <= 1'b0;
      ll_reg_reached <= 1'b0;
      ll_reg_ack <= 1'b0;
      ll_data_reached <= 1'b0;
      ll_data_ack <= 1'b0;
      ll_raddr_reached <= 1'b0;
      ll_raddr_ack <= 1'b0;
      ll_read_data <= 8'b0;
      ll_kind_latched <= CMD_ADDRESS_ONLY;
      ll_reg_latched <= 8'b0;
      ll_data_latched <= 8'b0;
      ll_tx_byte <= 8'b0;
      ll_rx_byte <= 8'b0;
      ll_bit_index <= 3'd7;
      ll_error <= 1'b0;
      ll_divider_count <= 32'b0;
      ll_idle_stable_count <= 32'b0;
      ll_idle_wait_count <= 32'b0;
      ll_scl_wait_count <= 32'b0;
      probe_timeout_count_total <= 32'b0;
      legacy_bus_idle_qualified_i <= 1'b0;
      legacy_scl_timeout_i <= 1'b0;
      legacy_ll_bus_idle_timeout_i <= 1'b0;
    end else begin
      ll_done <= 1'b0;

      if (!ll_busy) begin
        ll_divider_count <= 32'b0;
        ll_scl_wait_count <= 32'b0;
        if (ll_start) begin
          ll_busy <= 1'b1;
          ll_success <= 1'b0;
          ll_timeout <= 1'b0;
          ll_error <= 1'b0;
          ll_kind_latched <= ll_cmd_kind;
          ll_reg_latched <= ll_cmd_reg;
          ll_data_latched <= ll_cmd_data;
          ll_waddr_reached <= 1'b0;
          ll_waddr_ack <= 1'b0;
          ll_reg_reached <= 1'b0;
          ll_reg_ack <= 1'b0;
          ll_data_reached <= 1'b0;
          ll_data_ack <= 1'b0;
          ll_raddr_reached <= 1'b0;
          ll_raddr_ack <= 1'b0;
          ll_read_data <= 8'b0;
          ll_idle_stable_count <= 32'b0;
          ll_idle_wait_count <= 32'b0;
          ll_state <= LL_WAIT_IDLE;
        end
      end else if (ll_state == LL_WAIT_IDLE) begin
        if (bus_is_idle) begin
          ll_idle_wait_count <= 32'b0;
          if (ll_idle_stable_count + 1'b1 >= TICK_CYCLES) begin
            ll_idle_stable_count <= TICK_CYCLES;
            legacy_bus_idle_qualified_i <= 1'b1;
            ll_state <= LL_START_A;
          end else begin
            ll_idle_stable_count <= ll_idle_stable_count + 1'b1;
          end
        end else begin
          ll_idle_stable_count <= 32'b0;
          if (ll_idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES) begin
            ll_timeout <= 1'b1;
            ll_error <= 1'b1;
            legacy_ll_bus_idle_timeout_i <= 1'b1;
            if (probe_timeout_count_total != 32'hffffffff)
              probe_timeout_count_total <= probe_timeout_count_total + 1'b1;
            ll_state <= LL_ABORT_RELEASE;
          end else begin
            ll_idle_wait_count <= ll_idle_wait_count + 1'b1;
          end
        end
      end else begin
        if (ll_state == LL_ABORT_RELEASE) begin
          ll_busy <= 1'b0;
          ll_success <= 1'b0;
          ll_done <= 1'b1;
          ll_state <= LL_IDLE;
        end else if (ll_requires_scl_high && probe_scl_release &&
                     !scl_filtered) begin
          // Clock stretching or a stuck-low SCL must hold the protocol state.
          // In particular, it must not race the normal state transition on the
          // same clock that declares the timeout.
          ll_divider_count <= 32'b0;
          if (ll_scl_wait_count >= SCL_TIMEOUT_CYCLES) begin
            ll_timeout <= 1'b1;
            ll_error <= 1'b1;
            legacy_scl_timeout_i <= 1'b1;
            if (probe_timeout_count_total != 32'hffffffff)
              probe_timeout_count_total <= probe_timeout_count_total + 1'b1;
            ll_state <= LL_ABORT_RELEASE;
          end else begin
            ll_scl_wait_count <= ll_scl_wait_count + 1'b1;
          end
        end else if (ll_state_tick) begin
          ll_scl_wait_count <= 32'b0;
          ll_divider_count <= 32'b0;
          case (ll_state)
            LL_START_A: ll_state <= LL_START_B;
            LL_START_B: begin
              ll_tx_byte <= NVP_ADDR_W;
              ll_bit_index <= 3'd7;
              ll_state <= LL_SEND_W_LOW;
            end
            LL_SEND_W_LOW: ll_state <= LL_SEND_W_HIGH;
            LL_SEND_W_HIGH: if (scl_filtered) begin
              if (ll_bit_index == 0)
                ll_state <= LL_ACK_W_LOW;
              else begin
                ll_bit_index <= ll_bit_index - 1'b1;
                ll_state <= LL_SEND_W_LOW;
              end
            end
            LL_ACK_W_LOW: ll_state <= LL_ACK_W_HIGH;
            LL_ACK_W_HIGH: if (scl_filtered) begin
              ll_waddr_reached <= 1'b1;
              ll_waddr_ack <= !sda_filtered;
              if (sda_filtered) begin
                ll_error <= 1'b1;
                ll_state <= LL_STOP_A;
              end else if (ll_kind_latched == CMD_ADDRESS_ONLY) begin
                ll_state <= LL_STOP_A;
              end else begin
                ll_tx_byte <= ll_reg_latched;
                ll_bit_index <= 3'd7;
                ll_state <= LL_SEND_REG_LOW;
              end
            end
            LL_SEND_REG_LOW: ll_state <= LL_SEND_REG_HIGH;
            LL_SEND_REG_HIGH: if (scl_filtered) begin
              if (ll_bit_index == 0)
                ll_state <= LL_ACK_REG_LOW;
              else begin
                ll_bit_index <= ll_bit_index - 1'b1;
                ll_state <= LL_SEND_REG_LOW;
              end
            end
            LL_ACK_REG_LOW: ll_state <= LL_ACK_REG_HIGH;
            LL_ACK_REG_HIGH: if (scl_filtered) begin
              ll_reg_reached <= 1'b1;
              ll_reg_ack <= !sda_filtered;
              if (sda_filtered) begin
                ll_error <= 1'b1;
                ll_state <= LL_STOP_A;
              end else if (ll_kind_latched == CMD_REGISTER_ONLY) begin
                ll_state <= LL_STOP_A;
              end else if (ll_kind_latched == CMD_DATA_WRITE) begin
                ll_tx_byte <= ll_data_latched;
                ll_bit_index <= 3'd7;
                ll_state <= LL_SEND_DATA_LOW;
              end else begin
                ll_state <= LL_REP_LOW;
              end
            end
            LL_SEND_DATA_LOW: ll_state <= LL_SEND_DATA_HIGH;
            LL_SEND_DATA_HIGH: if (scl_filtered) begin
              if (ll_bit_index == 0)
                ll_state <= LL_ACK_DATA_LOW;
              else begin
                ll_bit_index <= ll_bit_index - 1'b1;
                ll_state <= LL_SEND_DATA_LOW;
              end
            end
            LL_ACK_DATA_LOW: ll_state <= LL_ACK_DATA_HIGH;
            LL_ACK_DATA_HIGH: if (scl_filtered) begin
              ll_data_reached <= 1'b1;
              ll_data_ack <= !sda_filtered;
              if (sda_filtered)
                ll_error <= 1'b1;
              ll_state <= LL_STOP_A;
            end
            LL_REP_LOW: ll_state <= LL_REP_HIGH;
            LL_REP_HIGH: if (scl_filtered) ll_state <= LL_REP_START_A;
            LL_REP_START_A: if (scl_filtered) ll_state <= LL_REP_START_B;
            LL_REP_START_B: begin
              ll_tx_byte <= NVP_ADDR_R;
              ll_bit_index <= 3'd7;
              ll_state <= LL_SEND_R_LOW;
            end
            LL_SEND_R_LOW: ll_state <= LL_SEND_R_HIGH;
            LL_SEND_R_HIGH: if (scl_filtered) begin
              if (ll_bit_index == 0)
                ll_state <= LL_ACK_R_LOW;
              else begin
                ll_bit_index <= ll_bit_index - 1'b1;
                ll_state <= LL_SEND_R_LOW;
              end
            end
            LL_ACK_R_LOW: ll_state <= LL_ACK_R_HIGH;
            LL_ACK_R_HIGH: if (scl_filtered) begin
              ll_raddr_reached <= 1'b1;
              ll_raddr_ack <= !sda_filtered;
              if (sda_filtered) begin
                ll_error <= 1'b1;
                ll_state <= LL_STOP_A;
              end else begin
                ll_bit_index <= 3'd7;
                ll_rx_byte <= 8'b0;
                ll_state <= LL_READ_LOW;
              end
            end
            LL_READ_LOW: ll_state <= LL_READ_HIGH;
            LL_READ_HIGH: if (scl_filtered) begin
              ll_rx_byte[ll_bit_index] <= sda_filtered;
              if (ll_bit_index == 0)
                ll_state <= LL_MASTER_NACK_LOW;
              else begin
                ll_bit_index <= ll_bit_index - 1'b1;
                ll_state <= LL_READ_LOW;
              end
            end
            LL_MASTER_NACK_LOW: ll_state <= LL_MASTER_NACK_HIGH;
            LL_MASTER_NACK_HIGH: if (scl_filtered) begin
              ll_read_data <= ll_rx_byte;
              ll_state <= LL_STOP_A;
            end
            LL_STOP_A: ll_state <= LL_STOP_B;
            LL_STOP_B: if (scl_filtered) ll_state <= LL_STOP_C;
            LL_STOP_C: if (scl_filtered) begin
              ll_busy <= 1'b0;
              ll_success <= !ll_error && !ll_timeout;
              ll_done <= 1'b1;
              ll_state <= LL_IDLE;
            end
            default: ll_state <= LL_ABORT_RELEASE;
          endcase
        end else begin
          ll_scl_wait_count <= 32'b0;
          ll_divider_count <= ll_divider_count + 1'b1;
        end
      end
    end
  end

  typedef enum logic [5:0] {
    H_WAIT_INIT,
    H_READ_ENTRY_START,
    H_READ_ENTRY_WAIT,
    H_WRITE_SAFE_BANK_START,
    H_WRITE_SAFE_BANK_WAIT,
    H_VERIFY_SAFE_BANK_START,
    H_VERIFY_SAFE_BANK_WAIT,
    H_READ_TARGET_PRE_START,
    H_READ_TARGET_PRE_WAIT,
    H_PROBE_SELECT,
    H_PROBE_WAIT,
    H_VERIFY_POST_BANK_START,
    H_VERIFY_POST_BANK_WAIT,
    H_READ_TARGET_POST_START,
    H_READ_TARGET_POST_WAIT,
    H_RESTORE_START,
    H_RESTORE_WAIT,
    H_VERIFY_RESTORE_START,
    H_VERIFY_RESTORE_WAIT,
    H_FINAL_IDLE,
    H_ABORT_IDLE,
    H_ABORT_RESTORE_START,
    H_ABORT_RESTORE_WAIT,
    H_ABORT_VERIFY_START,
    H_ABORT_VERIFY_WAIT,
    H_ABORT_FINAL,
    H_DONE
  } high_state_t;

  high_state_t high_state;
  logic [1:0] current_phase;
  logic [1:0] round_robin_phase;
  logic [31:0] guard_count;
  logic [31:0] final_idle_count;
  logic [31:0] final_idle_wait_count;

  logic [31:0] transaction_attempts [0:2];
  logic [31:0] target_opportunities [0:2];
  logic [31:0] target_acks [0:2];
  logic [31:0] target_nacks [0:2];
  logic [31:0] phase_timeouts [0:2];
  logic [15:0] first_nack_index [0:2];
  logic [15:0] last_nack_index [0:2];
  logic [31:0] max_consecutive_nacks [0:2];
  logic [31:0] adjacent_nack_pairs [0:2];
  logic [31:0] run_count [0:2];
  logic [31:0] consecutive_nacks [0:2];
  logic previous_outcome_valid [0:2];
  logic previous_outcome_nack [0:2];
  logic [31:0] block_nack_count [0:2][0:BLOCK_COUNT_PER_PHASE-1];
  logic [15:0] nack_index_memory [0:2][0:NACK_INDEX_CAPACITY_PER_PHASE-1];
  logic [15:0] nack_index_stored_count [0:2];
  logic nack_index_overflow [0:2];

  logic [31:0] reg_prereq_waddr_opportunities;
  logic [31:0] reg_prereq_waddr_acks;
  logic [31:0] reg_prereq_waddr_nacks;
  logic [31:0] data_prereq_waddr_opportunities_i;
  logic [31:0] data_prereq_waddr_acks_i;
  logic [31:0] data_prereq_waddr_nacks_i;
  logic [31:0] data_prereq_regaddr_opportunities_i;
  logic [31:0] data_prereq_regaddr_acks_i;
  logic [31:0] data_prereq_regaddr_nacks_i;

  integer reset_phase;
  integer reset_block;
  integer target_block;

  task automatic launch_transaction(
    input logic [1:0] kind,
    input logic [7:0] reg_value,
    input logic [7:0] data_value
  );
    begin
      ll_cmd_kind <= kind;
      ll_cmd_reg <= reg_value;
      ll_cmd_data <= data_value;
      ll_start <= 1'b1;
    end
  endtask

  task automatic enter_abort(input logic [7:0] code);
    begin
      probe_aborted <= 1'b1;
      probe_active <= 1'b0;
      probe_abort_code <= code;
      if (code == ABORT_RESTORE_WRITE || code == ABORT_RESTORE_VERIFY ||
          code == ABORT_FINAL_BUS_IDLE)
        probe_restore_failure_code <= code;
      final_idle_count <= 32'b0;
      final_idle_wait_count <= 32'b0;
      // A failure of the one normal restoration write/verification, or of the
      // final-idle proof after a verified restore, must terminate without a
      // second restore attempt.  Earlier failures get one best-effort restore.
      if (entry_bank_valid && code != ABORT_RESTORE_WRITE &&
          code != ABORT_RESTORE_VERIFY && code != ABORT_FINAL_BUS_IDLE)
        high_state <= H_ABORT_IDLE;
      else
        high_state <= H_ABORT_FINAL;
    end
  endtask

  task automatic record_target_outcome(
    input integer phase_number,
    input logic outcome_nack
  );
    integer block_number;
    begin
      block_number = target_opportunities[phase_number] / BLOCK_SIZE;
      target_opportunities[phase_number] <= target_opportunities[phase_number] + 1'b1;
      if (!previous_outcome_valid[phase_number]) begin
        previous_outcome_valid[phase_number] <= 1'b1;
        previous_outcome_nack[phase_number] <= outcome_nack;
        run_count[phase_number] <= 32'd1;
      end else begin
        if (previous_outcome_nack[phase_number] != outcome_nack)
          run_count[phase_number] <= run_count[phase_number] + 1'b1;
        previous_outcome_nack[phase_number] <= outcome_nack;
      end

      if (outcome_nack) begin
        target_nacks[phase_number] <= target_nacks[phase_number] + 1'b1;
        // Indices preserve the inherited R1e convention: zero is the first
        // physically reached target-phase opportunity.
        if (first_nack_index[phase_number] == 16'hffff)
          first_nack_index[phase_number] <= target_opportunities[phase_number][15:0];
        last_nack_index[phase_number] <= target_opportunities[phase_number][15:0];
        if (previous_outcome_valid[phase_number] &&
            previous_outcome_nack[phase_number])
          adjacent_nack_pairs[phase_number] <= adjacent_nack_pairs[phase_number] + 1'b1;
        consecutive_nacks[phase_number] <= consecutive_nacks[phase_number] + 1'b1;
        if (consecutive_nacks[phase_number] + 1'b1 >
            max_consecutive_nacks[phase_number])
          max_consecutive_nacks[phase_number] <= consecutive_nacks[phase_number] + 1'b1;
        if (block_number < BLOCK_COUNT_PER_PHASE)
          block_nack_count[phase_number][block_number] <=
            block_nack_count[phase_number][block_number] + 1'b1;
        if (nack_index_stored_count[phase_number] <
            NACK_INDEX_CAPACITY_PER_PHASE) begin
          nack_index_memory[phase_number][nack_index_stored_count[phase_number]] <=
            target_opportunities[phase_number][15:0];
          nack_index_stored_count[phase_number] <=
            nack_index_stored_count[phase_number] + 1'b1;
        end else begin
          nack_index_overflow[phase_number] <= 1'b1;
        end
      end else begin
        target_acks[phase_number] <= target_acks[phase_number] + 1'b1;
        consecutive_nacks[phase_number] <= 32'b0;
      end
    end
  endtask

  always_ff @(posedge clk) begin
    if (rst) begin
      high_state <= H_WAIT_INIT;
      ll_start <= 1'b0;
      ll_cmd_kind <= CMD_ADDRESS_ONLY;
      ll_cmd_reg <= 8'b0;
      ll_cmd_data <= 8'b0;
      current_phase <= PH_WADDR;
      round_robin_phase <= PH_WADDR;
      guard_count <= 32'b0;
      final_idle_count <= 32'b0;
      final_idle_wait_count <= 32'b0;
      round_robin_scheduler_rounds <= 32'b0;
      attempt_limit_status <= 3'b0;
      probe_active <= 1'b0;
      probe_done <= 1'b0;
      probe_aborted <= 1'b0;
      probe_terminal <= 1'b0;
      probe_abort_code <= ABORT_NONE;
      probe_restore_failure_code <= ABORT_NONE;
      probe_start_freerun <= 48'b0;
      probe_done_freerun <= 48'b0;
      entry_bank <= 8'b0;
      entry_bank_valid <= 1'b0;
      safe_bank_select_write_ok <= 1'b0;
      safe_bank_verify_ok <= 1'b0;
      safe_bank_readback <= 8'b0;
      safe_bank_readback_valid <= 1'b0;
      safe_target_pre_value <= 8'b0;
      safe_target_pre_valid <= 1'b0;
      safe_target_pre_ok <= 1'b0;
      safe_target_post_value <= 8'b0;
      safe_target_post_valid <= 1'b0;
      safe_target_post_ok <= 1'b0;
      original_bank_restored <= 1'b0;
      original_bank_restore_verified <= 1'b0;
      restored_bank_readback <= 8'b0;
      restored_bank_readback_valid <= 1'b0;
      final_bus_idle <= 1'b0;
      legacy_init_done_seen_i <= 1'b0;
      legacy_guard_complete_i <= 1'b0;
      legacy_high_bus_idle_timeout_i <= 1'b0;
      reg_prereq_waddr_opportunities <= 32'b0;
      reg_prereq_waddr_acks <= 32'b0;
      reg_prereq_waddr_nacks <= 32'b0;
      data_prereq_waddr_opportunities_i <= 32'b0;
      data_prereq_waddr_acks_i <= 32'b0;
      data_prereq_waddr_nacks_i <= 32'b0;
      data_prereq_regaddr_opportunities_i <= 32'b0;
      data_prereq_regaddr_acks_i <= 32'b0;
      data_prereq_regaddr_nacks_i <= 32'b0;
      for (reset_phase = 0; reset_phase < 3; reset_phase = reset_phase + 1) begin
        transaction_attempts[reset_phase] <= 32'b0;
        target_opportunities[reset_phase] <= 32'b0;
        target_acks[reset_phase] <= 32'b0;
        target_nacks[reset_phase] <= 32'b0;
        phase_timeouts[reset_phase] <= 32'b0;
        first_nack_index[reset_phase] <= 16'hffff;
        last_nack_index[reset_phase] <= 16'hffff;
        max_consecutive_nacks[reset_phase] <= 32'b0;
        adjacent_nack_pairs[reset_phase] <= 32'b0;
        run_count[reset_phase] <= 32'b0;
        consecutive_nacks[reset_phase] <= 32'b0;
        previous_outcome_valid[reset_phase] <= 1'b0;
        previous_outcome_nack[reset_phase] <= 1'b0;
        nack_index_stored_count[reset_phase] <= 16'b0;
        nack_index_overflow[reset_phase] <= 1'b0;
        for (reset_block = 0; reset_block < BLOCK_COUNT_PER_PHASE;
             reset_block = reset_block + 1)
          block_nack_count[reset_phase][reset_block] <= 32'b0;
      end
    end else begin
      ll_start <= 1'b0;
      if (init_done)
        legacy_init_done_seen_i <= 1'b1;
      case (high_state)
        H_WAIT_INIT: begin
          if (!init_terminal_gate) begin
            guard_count <= 32'b0;
          end else if (guard_count + 1'b1 >= POST_INIT_GUARD_CYCLES) begin
            guard_count <= POST_INIT_GUARD_CYCLES;
            legacy_guard_complete_i <= 1'b1;
            probe_start_freerun <= freerun_count;
            high_state <= H_READ_ENTRY_START;
          end else begin
            guard_count <= guard_count + 1'b1;
          end
        end

        H_READ_ENTRY_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, BANK_SELECT_REG, 8'b0);
          high_state <= H_READ_ENTRY_WAIT;
        end
        H_READ_ENTRY_WAIT: if (ll_done) begin
          if (!ll_success) begin
            enter_abort(ABORT_ENTRY_BANK_READ);
          end else begin
            entry_bank <= ll_read_data;
            entry_bank_valid <= 1'b1;
            if (ll_read_data == SAFE_BANK) begin
              safe_bank_select_write_ok <= 1'b1;
              high_state <= H_VERIFY_SAFE_BANK_START;
            end else begin
              high_state <= H_WRITE_SAFE_BANK_START;
            end
          end
        end

        H_WRITE_SAFE_BANK_START: if (!ll_busy) begin
          launch_transaction(CMD_DATA_WRITE, BANK_SELECT_REG, SAFE_BANK);
          high_state <= H_WRITE_SAFE_BANK_WAIT;
        end
        H_WRITE_SAFE_BANK_WAIT: if (ll_done) begin
          if (!ll_success) begin
            enter_abort(ABORT_SAFE_BANK_WRITE);
          end else begin
            safe_bank_select_write_ok <= 1'b1;
            high_state <= H_VERIFY_SAFE_BANK_START;
          end
        end

        H_VERIFY_SAFE_BANK_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, BANK_SELECT_REG, 8'b0);
          high_state <= H_VERIFY_SAFE_BANK_WAIT;
        end
        H_VERIFY_SAFE_BANK_WAIT: if (ll_done) begin
          safe_bank_readback <= ll_read_data;
          safe_bank_readback_valid <= ll_success;
          if (!ll_success || ll_read_data != SAFE_BANK) begin
            enter_abort(ABORT_SAFE_BANK_VERIFY);
          end else begin
            safe_bank_verify_ok <= 1'b1;
            high_state <= H_READ_TARGET_PRE_START;
          end
        end

        H_READ_TARGET_PRE_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, SAFE_REG, 8'b0);
          high_state <= H_READ_TARGET_PRE_WAIT;
        end
        H_READ_TARGET_PRE_WAIT: if (ll_done) begin
          safe_target_pre_value <= ll_read_data;
          safe_target_pre_valid <= ll_success;
          if (!ll_success || ll_read_data != SAFE_DATA) begin
            enter_abort(ABORT_SAFE_TARGET_PRE);
          end else begin
            safe_target_pre_ok <= 1'b1;
            probe_active <= 1'b1;
            round_robin_phase <= PH_WADDR;
            high_state <= H_PROBE_SELECT;
          end
        end

        H_PROBE_SELECT: begin
          if (target_opportunities[0] >= TARGET_OPPORTUNITIES_PER_PHASE &&
              target_opportunities[1] >= TARGET_OPPORTUNITIES_PER_PHASE &&
              target_opportunities[2] >= TARGET_OPPORTUNITIES_PER_PHASE) begin
            probe_active <= 1'b0;
            high_state <= H_VERIFY_POST_BANK_START;
          end else if (target_opportunities[round_robin_phase] >=
                       TARGET_OPPORTUNITIES_PER_PHASE) begin
            if (round_robin_phase == PH_DATA) begin
              round_robin_phase <= PH_WADDR;
              round_robin_scheduler_rounds <=
                round_robin_scheduler_rounds + 1'b1;
            end else begin
              round_robin_phase <= round_robin_phase + 1'b1;
            end
          end else if (transaction_attempts[round_robin_phase] >=
                       MAX_TRANSACTION_ATTEMPTS_PER_PHASE) begin
            attempt_limit_status[round_robin_phase] <= 1'b1;
            enter_abort(ABORT_ATTEMPT_LIMIT);
          end else if (!ll_busy) begin
            current_phase <= round_robin_phase;
            transaction_attempts[round_robin_phase] <=
              transaction_attempts[round_robin_phase] + 1'b1;
            case (round_robin_phase)
              PH_WADDR: launch_transaction(CMD_ADDRESS_ONLY, SAFE_REG, SAFE_DATA);
              PH_REGADDR: launch_transaction(CMD_REGISTER_ONLY, SAFE_REG, SAFE_DATA);
              default: launch_transaction(CMD_DATA_WRITE, SAFE_REG, SAFE_DATA);
            endcase
            high_state <= H_PROBE_WAIT;
          end
        end

        H_PROBE_WAIT: if (ll_done) begin
          if (ll_timeout) begin
            phase_timeouts[current_phase] <= phase_timeouts[current_phase] + 1'b1;
            enter_abort(ABORT_PROBE_TIMEOUT);
          end else begin
            if (current_phase == PH_REGADDR && ll_waddr_reached) begin
              reg_prereq_waddr_opportunities <= reg_prereq_waddr_opportunities + 1'b1;
              if (ll_waddr_ack)
                reg_prereq_waddr_acks <= reg_prereq_waddr_acks + 1'b1;
              else
                reg_prereq_waddr_nacks <= reg_prereq_waddr_nacks + 1'b1;
            end
            if (current_phase == PH_DATA && ll_waddr_reached) begin
              data_prereq_waddr_opportunities_i <= data_prereq_waddr_opportunities_i + 1'b1;
              if (ll_waddr_ack)
                data_prereq_waddr_acks_i <= data_prereq_waddr_acks_i + 1'b1;
              else
                data_prereq_waddr_nacks_i <= data_prereq_waddr_nacks_i + 1'b1;
            end
            if (current_phase == PH_DATA && ll_reg_reached) begin
              data_prereq_regaddr_opportunities_i <= data_prereq_regaddr_opportunities_i + 1'b1;
              if (ll_reg_ack)
                data_prereq_regaddr_acks_i <= data_prereq_regaddr_acks_i + 1'b1;
              else
                data_prereq_regaddr_nacks_i <= data_prereq_regaddr_nacks_i + 1'b1;
            end

            case (current_phase)
              PH_WADDR: if (ll_waddr_reached)
                record_target_outcome(0, !ll_waddr_ack);
              PH_REGADDR: if (ll_reg_reached)
                record_target_outcome(1, !ll_reg_ack);
              PH_DATA: if (ll_data_reached)
                record_target_outcome(2, !ll_data_ack);
              default: begin end
            endcase

            if (round_robin_phase == PH_DATA) begin
              round_robin_phase <= PH_WADDR;
              round_robin_scheduler_rounds <=
                round_robin_scheduler_rounds + 1'b1;
            end else begin
              round_robin_phase <= round_robin_phase + 1'b1;
            end
            high_state <= H_PROBE_SELECT;
          end
        end

        H_VERIFY_POST_BANK_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, BANK_SELECT_REG, 8'b0);
          high_state <= H_VERIFY_POST_BANK_WAIT;
        end
        H_VERIFY_POST_BANK_WAIT: if (ll_done) begin
          if (!ll_success || ll_read_data != SAFE_BANK)
            enter_abort(ABORT_POST_BANK_VERIFY);
          else
            high_state <= H_READ_TARGET_POST_START;
        end

        H_READ_TARGET_POST_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, SAFE_REG, 8'b0);
          high_state <= H_READ_TARGET_POST_WAIT;
        end
        H_READ_TARGET_POST_WAIT: if (ll_done) begin
          safe_target_post_value <= ll_read_data;
          safe_target_post_valid <= ll_success;
          if (!ll_success || ll_read_data != SAFE_DATA ||
              ll_read_data != safe_target_pre_value) begin
            enter_abort(ABORT_SAFE_TARGET_POST);
          end else begin
            safe_target_post_ok <= 1'b1;
            high_state <= H_RESTORE_START;
          end
        end

        H_RESTORE_START: if (!ll_busy) begin
          launch_transaction(CMD_DATA_WRITE, BANK_SELECT_REG, entry_bank);
          high_state <= H_RESTORE_WAIT;
        end
        H_RESTORE_WAIT: if (ll_done) begin
          if (!ll_success) begin
            enter_abort(ABORT_RESTORE_WRITE);
          end else begin
            original_bank_restored <= 1'b1;
            high_state <= H_VERIFY_RESTORE_START;
          end
        end
        H_VERIFY_RESTORE_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, BANK_SELECT_REG, 8'b0);
          high_state <= H_VERIFY_RESTORE_WAIT;
        end
        H_VERIFY_RESTORE_WAIT: if (ll_done) begin
          restored_bank_readback <= ll_read_data;
          restored_bank_readback_valid <= ll_success;
          if (!ll_success || ll_read_data != entry_bank) begin
            enter_abort(ABORT_RESTORE_VERIFY);
          end else begin
            original_bank_restore_verified <= 1'b1;
            final_idle_count <= 32'b0;
            final_idle_wait_count <= 32'b0;
            high_state <= H_FINAL_IDLE;
          end
        end

        H_FINAL_IDLE: begin
          if (bus_is_idle && probe_scl_release && probe_sda_release) begin
            final_idle_wait_count <= 32'b0;
            if (final_idle_count + 1'b1 >= TICK_CYCLES) begin
              final_bus_idle <= 1'b1;
              probe_done <= 1'b1;
              probe_terminal <= 1'b1;
              probe_done_freerun <= freerun_count;
              high_state <= H_DONE;
            end else begin
              final_idle_count <= final_idle_count + 1'b1;
            end
          end else begin
            final_idle_count <= 32'b0;
            if (final_idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES) begin
              legacy_high_bus_idle_timeout_i <= 1'b1;
              enter_abort(ABORT_FINAL_BUS_IDLE);
            end else
              final_idle_wait_count <= final_idle_wait_count + 1'b1;
          end
        end

        H_ABORT_IDLE: begin
          if (bus_is_idle && probe_scl_release && probe_sda_release) begin
            final_idle_wait_count <= 32'b0;
            if (final_idle_count + 1'b1 >= TICK_CYCLES) begin
              final_idle_count <= 32'b0;
              high_state <= H_ABORT_RESTORE_START;
            end else begin
              final_idle_count <= final_idle_count + 1'b1;
            end
          end else begin
            final_idle_count <= 32'b0;
            if (final_idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES) begin
              legacy_high_bus_idle_timeout_i <= 1'b1;
              probe_restore_failure_code <= ABORT_FINAL_BUS_IDLE;
              high_state <= H_ABORT_FINAL;
            end else
              final_idle_wait_count <= final_idle_wait_count + 1'b1;
          end
        end
        H_ABORT_RESTORE_START: if (!ll_busy) begin
          launch_transaction(CMD_DATA_WRITE, BANK_SELECT_REG, entry_bank);
          high_state <= H_ABORT_RESTORE_WAIT;
        end
        H_ABORT_RESTORE_WAIT: if (ll_done) begin
          if (ll_success) begin
            original_bank_restored <= 1'b1;
            high_state <= H_ABORT_VERIFY_START;
          end else begin
            probe_restore_failure_code <= ABORT_RESTORE_WRITE;
            high_state <= H_ABORT_FINAL;
          end
        end
        H_ABORT_VERIFY_START: if (!ll_busy) begin
          launch_transaction(CMD_REGISTER_READ, BANK_SELECT_REG, 8'b0);
          high_state <= H_ABORT_VERIFY_WAIT;
        end
        H_ABORT_VERIFY_WAIT: if (ll_done) begin
          restored_bank_readback <= ll_read_data;
          restored_bank_readback_valid <= ll_success;
          if (ll_success && ll_read_data == entry_bank) begin
            original_bank_restore_verified <= 1'b1;
          end else begin
            probe_restore_failure_code <= ABORT_RESTORE_VERIFY;
          end
          high_state <= H_ABORT_FINAL;
        end
        H_ABORT_FINAL: begin
          probe_terminal <= 1'b1;
          probe_done_freerun <= freerun_count;
          high_state <= H_DONE;
        end
        H_DONE: begin
          // Terminal until reset.  Lines remain released because LL is idle.
        end
        default: enter_abort(ABORT_FINAL_BUS_IDLE);
      endcase
    end
  end

  always_comb begin
    waddr_transaction_attempts = transaction_attempts[0];
    waddr_target_opportunities = target_opportunities[0];
    waddr_target_acks = target_acks[0];
    waddr_target_nacks = target_nacks[0];
    waddr_timeouts = phase_timeouts[0];
    waddr_first_nack_index = first_nack_index[0];
    waddr_last_nack_index = last_nack_index[0];
    waddr_max_consecutive_nacks = max_consecutive_nacks[0];
    waddr_adjacent_nack_pairs = adjacent_nack_pairs[0];
    waddr_run_count = run_count[0];

    regaddr_transaction_attempts = transaction_attempts[1];
    regaddr_prereq_waddr_opportunities = reg_prereq_waddr_opportunities;
    regaddr_prereq_waddr_acks = reg_prereq_waddr_acks;
    regaddr_prereq_waddr_nacks = reg_prereq_waddr_nacks;
    regaddr_target_opportunities = target_opportunities[1];
    regaddr_target_acks = target_acks[1];
    regaddr_target_nacks = target_nacks[1];
    regaddr_timeouts = phase_timeouts[1];
    regaddr_first_nack_index = first_nack_index[1];
    regaddr_last_nack_index = last_nack_index[1];
    regaddr_max_consecutive_nacks = max_consecutive_nacks[1];
    regaddr_adjacent_nack_pairs = adjacent_nack_pairs[1];
    regaddr_run_count = run_count[1];

    data_transaction_attempts = transaction_attempts[2];
    data_prereq_waddr_opportunities = data_prereq_waddr_opportunities_i;
    data_prereq_waddr_acks = data_prereq_waddr_acks_i;
    data_prereq_waddr_nacks = data_prereq_waddr_nacks_i;
    data_prereq_regaddr_opportunities = data_prereq_regaddr_opportunities_i;
    data_prereq_regaddr_acks = data_prereq_regaddr_acks_i;
    data_prereq_regaddr_nacks = data_prereq_regaddr_nacks_i;
    data_target_opportunities = target_opportunities[2];
    data_target_acks = target_acks[2];
    data_target_nacks = target_nacks[2];
    data_timeouts = phase_timeouts[2];
    data_first_nack_index = first_nack_index[2];
    data_last_nack_index = last_nack_index[2];
    data_max_consecutive_nacks = max_consecutive_nacks[2];
    data_adjacent_nack_pairs = adjacent_nack_pairs[2];
    data_run_count = run_count[2];

    waddr_nack_index_stored_count = nack_index_stored_count[0];
    regaddr_nack_index_stored_count = nack_index_stored_count[1];
    data_nack_index_stored_count = nack_index_stored_count[2];
    waddr_nack_index_overflow = nack_index_overflow[0];
    regaddr_nack_index_overflow = nack_index_overflow[1];
    data_nack_index_overflow = nack_index_overflow[2];

    // Each 32-bit MMIO word packs two chronological 16-bit, zero-based
    // target-opportunity indices: {index[2w+1], index[2w]}.  Stored-count
    // bounds force every unused half-word to deterministic zero.
    index_read_data = 32'b0;
    if (index_read_phase < 3) begin
      if ({index_read_word, 1'b0} < NACK_INDEX_CAPACITY_PER_PHASE &&
          {index_read_word, 1'b0} <
            nack_index_stored_count[index_read_phase])
        index_read_data[15:0] =
          nack_index_memory[index_read_phase][{index_read_word, 1'b0}];
      if (({index_read_word, 1'b0} + 1'b1) <
            NACK_INDEX_CAPACITY_PER_PHASE &&
          ({index_read_word, 1'b0} + 1'b1) <
            nack_index_stored_count[index_read_phase])
        index_read_data[31:16] =
          nack_index_memory[index_read_phase][{index_read_word, 1'b0} + 1'b1];
    end

    block_read_nack_count = 32'b0;
    if (block_read_phase < 3 && block_read_index < BLOCK_COUNT_PER_PHASE)
      block_read_nack_count = block_nack_count[block_read_phase][block_read_index];

    probe_status = 32'b0;
    probe_status[0] = probe_done;
    probe_status[1] = probe_aborted;
    probe_status[2] = probe_active;
    probe_status[3] = probe_terminal;
    probe_status[4] = safe_bank_select_write_ok;
    probe_status[5] = safe_bank_verify_ok;
    probe_status[6] = safe_target_pre_ok;
    probe_status[7] = safe_target_post_ok;
    probe_status[8] = original_bank_restored;
    probe_status[9] = original_bank_restore_verified;
    probe_status[10] = final_bus_idle;
    probe_status[11] = probe_scl_release && probe_sda_release;
    probe_status[12] = 1'b1; // fixed 25-kHz production mode capability
    probe_status[13] = 1'b1; // WADDR target phase
    probe_status[14] = 1'b1; // REGADDR target phase
    probe_status[15] = 1'b1; // DATA target phase
    probe_status[23:16] = probe_abort_code;

    // Phase 3 means complete or inactive.  While active, round_robin_phase is
    // the slot whose transaction is in flight or will be selected next.
    current_scheduler_phase = probe_active ? round_robin_phase : 2'd3;
  end
endmodule
