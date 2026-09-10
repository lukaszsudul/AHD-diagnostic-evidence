`timescale 1ns/1ps

// AHD v41 four-channel NVP6134C video diagnostic.
//
// The host can start only fixed, compiled operations.  No bank, register, or
// write-data field is host supplied.  All NVP writes are constrained to the
// documented route/BGDCOL whitelist and product-baseline restoration.
module g2b_nvp_video_diag #(
  parameter integer CYCLES_PER_MS = 62500,
  parameter integer SETTLE_TIME_MS = 200,
  parameter integer STATUS_SAMPLE_INTERVAL_MS = 100,
  parameter integer REQUIRED_STABLE_SAMPLES = 5,
  parameter integer MAX_STATUS_WAIT_MS = 2000
) (
  input  logic        clk,
  input  logic        reset,
  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,

  input  logic        transport_stream_enabled,
  input  logic        transport_c2h_active,
  input  logic        transport_ring_empty,
  input  logic        transport_ring_full,

  output logic        i2c_cmd_valid,
  input  logic        i2c_cmd_ready,
  output logic        i2c_cmd_write,
  output logic [7:0]  i2c_cmd_reg,
  output logic [7:0]  i2c_cmd_wdata,
  input  logic        i2c_cmd_accepted,
  input  logic        i2c_busy,
  input  logic        i2c_done,
  input  logic        i2c_success,
  input  logic        i2c_timeout,
  input  logic [7:0]  i2c_read_data,
  input  logic        i2c_bus_idle,

  input  logic        mmio_req_valid,
  output logic        mmio_req_ready,
  input  logic        mmio_req_write,
  input  logic [16:0] mmio_req_addr,
  input  logic [31:0] mmio_req_wdata,
  input  logic [3:0]  mmio_req_be,
  output logic        mmio_rsp_valid,
  input  logic        mmio_rsp_ready,
  output logic [31:0] mmio_rsp_rdata,

  output logic        diagnostic_i2c_owns_bus,
  output logic        capture_ready,
  output logic [15:0] current_session_id,
  output logic [2:0]  current_round,
  output logic [2:0]  current_channel,
  output logic        product_baseline_restored
);
  localparam logic [31:0] DIAG_MAGIC = 32'h4e56_5034;
  localparam logic [31:0] DIAG_VERSION = 32'h0001_0001;
  localparam logic [31:0] INHERITED_DIAG_CAPABILITIES = 32'h0000_00ff;
  localparam logic [31:0] CAP_CURRENT_SESSION_SNAPSHOT_V1 = 32'h0000_0100;
  localparam logic [31:0] CAP_HOST_OWNED_SESSION_HISTORY = 32'h0000_0200;
  localparam logic [31:0] CAP_ONCHIP_16_SESSION_HISTORY = 32'h0000_0400;
  // Bits 7:0 retain the DIAG1 capabilities.  R1 adds a coherent current-
  // session snapshot (bit 8) and host-owned session history (bit 9).
  // Bit 10 is deliberately zero: no on-chip multi-session history exists.
  localparam logic [31:0] DIAG_CAPABILITIES =
      INHERITED_DIAG_CAPABILITIES | CAP_CURRENT_SESSION_SNAPSHOT_V1 |
      CAP_HOST_OWNED_SESSION_HISTORY;

  localparam logic [7:0] BANK_SELECT = 8'hff;
  localparam logic [7:0] BANK0 = 8'h00;
  localparam logic [7:0] BANK1 = 8'h01;
  localparam logic [7:0] REG_BGDCOL_12 = 8'h78;
  localparam logic [7:0] REG_BGDCOL_34 = 8'h79;
  localparam logic [7:0] REG_VDO1_ROUTE = 8'hc2;
  localparam logic [7:0] REG_NOVID = 8'ha8;
  localparam logic [7:0] REG_AGC_LOCK = 8'he0;
  localparam logic [7:0] REG_CMP_LOCK = 8'he1;
  localparam logic [7:0] REG_H_LOCK = 8'he2;

  localparam logic [3:0] COLOR_RED = 4'h6;
  localparam logic [3:0] COLOR_GREEN = 4'h4;
  localparam logic [3:0] COLOR_CYAN = 4'h3;
  localparam logic [3:0] COLOR_WHITE75 = 4'h1;
  localparam logic [3:0] COLOR_BLACK = 4'h8;

  localparam logic [7:0] CLASS_NONE = 8'd0;
  localparam logic [7:0] CLASS_ACTIVE_STABLE = 8'd1;
  localparam logic [7:0] CLASS_NO_VIDEO_STABLE = 8'd2;
  localparam logic [7:0] CLASS_LOCK_UNSTABLE = 8'd3;
  localparam logic [7:0] CLASS_STATUS_CONTRADICTORY = 8'd4;
  localparam logic [7:0] CLASS_I2C_STATUS_ERROR = 8'd5;

  localparam logic [15:0] ERR_NONE = 16'h0000;
  localparam logic [15:0] ERR_NOT_READY = 16'h0001;
  localparam logic [15:0] ERR_I2C_NACK = 16'h0002;
  localparam logic [15:0] ERR_I2C_TIMEOUT = 16'h0003;
  localparam logic [15:0] ERR_CONFIG_MISMATCH = 16'h0004;
  localparam logic [15:0] ERR_BGDCOL_MISMATCH = 16'h0005;
  localparam logic [15:0] ERR_ROUTE_MISMATCH = 16'h0006;
  localparam logic [15:0] ERR_HOST_PROTOCOL = 16'h0007;
  localparam logic [15:0] ERR_CAPTURE_FAILED = 16'h0008;
  localparam logic [15:0] ERR_OWNER_ABORT = 16'h0009;
  localparam logic [15:0] ERR_RESTORE_FAILED = 16'h000a;
  localparam logic [15:0] ERR_TRANSPORT_NOT_QUIESCENT = 16'h000b;

  localparam integer SETTLE_CYCLES = SETTLE_TIME_MS * CYCLES_PER_MS;
  localparam integer SAMPLE_INTERVAL_CYCLES =
      STATUS_SAMPLE_INTERVAL_MS * CYCLES_PER_MS;
  localparam integer MAX_STATUS_WAIT_CYCLES =
      MAX_STATUS_WAIT_MS * CYCLES_PER_MS;
  localparam integer SETTLE_COUNTER_WIDTH = $clog2(SETTLE_CYCLES + 1);
  localparam integer SAMPLE_COUNTER_WIDTH = $clog2(SAMPLE_INTERVAL_CYCLES + 1);
  localparam integer STATUS_WAIT_COUNTER_WIDTH =
      $clog2(MAX_STATUS_WAIT_CYCLES + 1);
  localparam integer DELAY_COUNTER_WIDTH =
      (SETTLE_COUNTER_WIDTH > SAMPLE_COUNTER_WIDTH) ?
      SETTLE_COUNTER_WIDTH : SAMPLE_COUNTER_WIDTH;

  typedef enum logic [5:0] {
    IDLE,
    SAVE_PRODUCT_BASELINE,
    TAKE_I2C_OWNERSHIP,
    CONFIGURE_ALL_CHANNELS,
    VERIFY_ALL_CHANNELS,
    BEGIN_ROUND,
    PROGRAM_ROUND_BGDCOL,
    VERIFY_ROUND_BGDCOL,
    SELECT_CHANNEL,
    VERIFY_ROUTE,
    WAIT_SETTLE,
    SAMPLE_STATUS,
    CLASSIFY_STATUS,
    LATCH_SESSION_RESULT,
    SIGNAL_CAPTURE_READY,
    WAIT_HOST_CAPTURE,
    NEXT_CHANNEL,
    NEXT_ROUND,
    RESTORE_PRODUCT_BASELINE,
    VERIFY_RESTORE,
    DONE,
    ERROR_SAFE_RESTORE,
    ERROR
  } diag_state_t;

  diag_state_t state;
  logic [7:0] substep;
  logic [2:0] round_position;
  logic prepared;
  logic scan_active;
  logic done_flag;
  logic error_flag;
  logic baseline_valid;
  logic restore_to_error;
  logic restore_in_progress;
  logic [15:0] error_code;
  logic [15:0] first_i2c_error;
  logic [15:0] last_i2c_error;
  logic [31:0] i2c_transaction_count;
  logic [31:0] i2c_nack_count;
  logic [31:0] i2c_timeout_count;
  logic [31:0] i2c_bus_recovery_count;
  logic [31:0] scan_completed_sessions;

  logic [7:0] original_bank;
  logic [7:0] original_bg78;
  logic [7:0] original_bg79;
  logic [7:0] original_route;
  logic [7:0] route_before_select;
  logic [7:0] current_route_readback;
  logic [7:0] current_bg78_readback;
  logic [7:0] current_bg79_readback;
  logic [7:0] current_classification;
  logic [31:0] last_host_capture_response;
  logic [31:0] restore_status;

  logic [7:0] raw_novid;
  logic [7:0] raw_agc_lock;
  logic [7:0] raw_cmp_lock;
  logic [7:0] raw_h_lock;
  logic [7:0] raw_channel_status;
  logic [39:0] first_sample_signature;
  logic [39:0] current_sample_signature;
  logic [7:0] stable_sample_count;
  logic [7:0] total_status_samples;
  logic [DELAY_COUNTER_WIDTH-1:0] delay_counter;
  logic [STATUS_WAIT_COUNTER_WIDTH-1:0] status_wait_counter;
  logic [7:0] config_verify_index;
  logic txn_pending;

  // The FPGA retains only the immutable result for the current session.  The
  // complete 16-session history is collected by the host before capture.
  logic [31:0] current_result_word_0;
  logic [31:0] current_result_word_1;
  logic [31:0] current_result_word_2;
  logic [31:0] current_result_word_3;
  logic [31:0] current_result_word_4;
  logic [31:0] current_result_word_5;
  logic [31:0] current_result_word_6;
  logic [31:0] current_result_word_7;
  logic        current_result_valid;
  logic [15:0] current_result_session_id;
  logic [15:0] current_result_generation;

  logic [31:0] control_pulse;
  logic host_response_pulse;
  logic [31:0] host_response_data;
  logic mmio_protocol_error_pulse;

  wire transport_quiescent = !transport_stream_enabled &&
      !transport_c2h_active && transport_ring_empty && !transport_ring_full;

  function automatic [2:0] scan_channel(
      input logic [2:0] round_index, input logic [2:0] position);
    begin
      case (round_index)
        3'd0: case (position)
          0: scan_channel = 3'd1; 1: scan_channel = 3'd2;
          2: scan_channel = 3'd3; default: scan_channel = 3'd4;
        endcase
        3'd1: case (position)
          0: scan_channel = 3'd4; 1: scan_channel = 3'd3;
          2: scan_channel = 3'd2; default: scan_channel = 3'd1;
        endcase
        3'd2: case (position)
          0: scan_channel = 3'd2; 1: scan_channel = 3'd3;
          2: scan_channel = 3'd4; default: scan_channel = 3'd1;
        endcase
        default: case (position)
          0: scan_channel = 3'd3; 1: scan_channel = 3'd4;
          2: scan_channel = 3'd1; default: scan_channel = 3'd2;
        endcase
      endcase
    end
  endfunction

  function automatic [3:0] round_color(
      input logic [2:0] round_index, input logic [2:0] channel_number);
    begin
      case (round_index)
        3'd0: case (channel_number)
          1: round_color = COLOR_RED; 2: round_color = COLOR_GREEN;
          3: round_color = COLOR_CYAN; default: round_color = COLOR_WHITE75;
        endcase
        3'd1: case (channel_number)
          1: round_color = COLOR_WHITE75; 2: round_color = COLOR_RED;
          3: round_color = COLOR_GREEN; default: round_color = COLOR_CYAN;
        endcase
        3'd2: case (channel_number)
          1: round_color = COLOR_CYAN; 2: round_color = COLOR_WHITE75;
          3: round_color = COLOR_RED; default: round_color = COLOR_GREEN;
        endcase
        default: case (channel_number)
          1: round_color = COLOR_GREEN; 2: round_color = COLOR_CYAN;
          3: round_color = COLOR_WHITE75; default: round_color = COLOR_RED;
        endcase
      endcase
    end
  endfunction

  function automatic [7:0] round_bg78(input logic [2:0] round_index);
    begin
      round_bg78 = {round_color(round_index, 3'd2),
                    round_color(round_index, 3'd1)};
    end
  endfunction

  function automatic [7:0] round_bg79(input logic [2:0] round_index);
    begin
      round_bg79 = {round_color(round_index, 3'd4),
                    round_color(round_index, 3'd3)};
    end
  endfunction

  function automatic [7:0] channel_status_reg(input logic [2:0] channel_number);
    begin
      case (channel_number)
        3'd1: channel_status_reg = 8'he8;
        3'd2: channel_status_reg = 8'he9;
        3'd3: channel_status_reg = 8'hea;
        default: channel_status_reg = 8'heb;
      endcase
    end
  endfunction

  function automatic [7:0] verify_reg(input logic [7:0] index);
    begin
      case (index)
        0: verify_reg = 8'h80;
        1: verify_reg = 8'h00; 2: verify_reg = 8'h01;
        3: verify_reg = 8'h02; 4: verify_reg = 8'h03;
        5: verify_reg = 8'h08; 6: verify_reg = 8'h09;
        7: verify_reg = 8'h0a; 8: verify_reg = 8'h0b;
        9: verify_reg = 8'h81; 10: verify_reg = 8'h82;
        11: verify_reg = 8'h83; 12: verify_reg = 8'h84;
        13: verify_reg = 8'h85; 14: verify_reg = 8'h86;
        15: verify_reg = 8'h87; default: verify_reg = 8'h88;
      endcase
    end
  endfunction

  function automatic [7:0] verify_value(input logic [7:0] index);
    begin
      if (index == 0)
        verify_value = 8'h0f;
      else if (index >= 9 && index <= 12)
        verify_value = 8'h03;
      else
        verify_value = 8'h00;
    end
  endfunction

  function automatic [31:0] mmio_read_word(input logic [16:0] address);
    begin
      case (address)
        17'h03c00: mmio_read_word = DIAG_MAGIC;
        17'h03c04: mmio_read_word = DIAG_VERSION;
        17'h03c08: mmio_read_word = DIAG_CAPABILITIES;
        17'h03c0c: mmio_read_word = 32'b0;
        17'h03c10: mmio_read_word = {
          15'b0, scan_active, i2c_bus_idle, diagnostic_i2c_owns_bus,
          product_baseline_restored, error_flag, done_flag, capture_ready,
          prepared, state != IDLE && state != DONE && state != ERROR};
        17'h03c14: mmio_read_word = {16'b0, error_code};
        17'h03c18: mmio_read_word = {26'b0, state};
        17'h03c1c: mmio_read_word =
            {21'b0, round_position, current_round, current_channel};
        17'h03c20: mmio_read_word = {16'b0, current_session_id};
        17'h03c24: mmio_read_word = SETTLE_TIME_MS;
        17'h03c28: mmio_read_word = STATUS_SAMPLE_INTERVAL_MS;
        17'h03c2c: mmio_read_word = REQUIRED_STABLE_SAMPLES;
        17'h03c30: mmio_read_word = MAX_STATUS_WAIT_MS;
        17'h03c34: mmio_read_word = last_host_capture_response;
        17'h03c38: mmio_read_word = {24'b0, current_route_readback};
        17'h03c3c: mmio_read_word = {24'b0, current_bg78_readback};
        17'h03c40: mmio_read_word = {24'b0, current_bg79_readback};
        17'h03c44: mmio_read_word = {24'b0, original_route};
        17'h03c48: mmio_read_word = {24'b0, original_bg78};
        17'h03c4c: mmio_read_word = {24'b0, original_bg79};
        17'h03c50: mmio_read_word = i2c_transaction_count;
        17'h03c54: mmio_read_word = i2c_nack_count;
        17'h03c58: mmio_read_word = i2c_timeout_count;
        17'h03c5c: mmio_read_word = {16'b0, first_i2c_error};
        17'h03c60: mmio_read_word = {16'b0, last_i2c_error};
        17'h03c64: mmio_read_word = scan_completed_sessions;
        17'h03c68: mmio_read_word = 32'd16;
        17'h03c6c: mmio_read_word = restore_status;
        17'h03c70: mmio_read_word = i2c_bus_recovery_count;
        17'h03c74: mmio_read_word = {24'b0, current_classification};
        17'h03c78: mmio_read_word =
            {24'b0, COLOR_BLACK, round_color(current_round, current_channel)};
        17'h03c7c: mmio_read_word = {24'b0, raw_novid};
        17'h03c80: mmio_read_word = {24'b0, raw_agc_lock};
        17'h03c84: mmio_read_word = {24'b0, raw_cmp_lock};
        17'h03c88: mmio_read_word = {24'b0, raw_h_lock};
        17'h03c8c: mmio_read_word = {24'b0, raw_channel_status};
        17'h03c90: mmio_read_word =
            {16'b0, total_status_samples, stable_sample_count};
        17'h03d00: mmio_read_word = current_result_word_0;
        17'h03d04: mmio_read_word = current_result_word_1;
        17'h03d08: mmio_read_word = current_result_word_2;
        17'h03d0c: mmio_read_word = current_result_word_3;
        17'h03d10: mmio_read_word = current_result_word_4;
        17'h03d14: mmio_read_word = current_result_word_5;
        17'h03d18: mmio_read_word = current_result_word_6;
        17'h03d1c: mmio_read_word = current_result_word_7;
        17'h03d20: mmio_read_word = {31'b0, current_result_valid};
        17'h03d24: mmio_read_word = {16'b0, current_result_session_id};
        17'h03d28: mmio_read_word = {16'b0, current_result_generation};
        default: mmio_read_word = 32'b0;
      endcase
    end
  endfunction

  assign mmio_req_ready = !mmio_rsp_valid || mmio_rsp_ready;

  always_ff @(posedge clk) begin
    if (reset) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      control_pulse <= 32'b0;
      host_response_pulse <= 1'b0;
      host_response_data <= 32'b0;
      mmio_protocol_error_pulse <= 1'b0;
    end else begin
      control_pulse <= 32'b0;
      host_response_pulse <= 1'b0;
      mmio_protocol_error_pulse <= 1'b0;
      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;
      if (mmio_req_valid && mmio_req_ready) begin
        mmio_rsp_valid <= 1'b1;
        mmio_rsp_rdata <= mmio_read_word(mmio_req_addr);
        if (mmio_req_write) begin
          if (mmio_req_be != 4'hf) begin
            mmio_protocol_error_pulse <= 1'b1;
          end else if (mmio_req_addr == 17'h03c0c) begin
            control_pulse <= mmio_req_wdata;
          end else if (mmio_req_addr == 17'h03c34) begin
            host_response_data <= mmio_req_wdata;
            host_response_pulse <= 1'b1;
          end else begin
            mmio_protocol_error_pulse <= 1'b1;
          end
        end
      end
    end
  end

  task automatic launch_i2c(
      input logic is_write, input logic [7:0] reg_address,
      input logic [7:0] write_value);
    begin
      i2c_cmd_write <= is_write;
      i2c_cmd_reg <= reg_address;
      i2c_cmd_wdata <= write_value;
      i2c_cmd_valid <= 1'b1;
      txn_pending <= 1'b1;
    end
  endtask

  task automatic latch_error(input logic [15:0] value);
    begin
      error_code <= value;
      error_flag <= 1'b1;
      done_flag <= 1'b0;
      capture_ready <= 1'b0;
      scan_active <= 1'b0;
      if (first_i2c_error == ERR_NONE &&
          (value == ERR_I2C_NACK || value == ERR_I2C_TIMEOUT))
        first_i2c_error <= value;
      if (value == ERR_I2C_NACK || value == ERR_I2C_TIMEOUT)
        last_i2c_error <= value;
      restore_to_error <= 1'b1;
      substep <= 8'b0;
      state <= baseline_valid ? ERROR_SAFE_RESTORE : ERROR;
    end
  endtask

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      substep <= 8'b0;
      round_position <= 3'b0;
      current_round <= 3'b0;
      current_channel <= 3'd1;
      current_session_id <= 16'b0;
      prepared <= 1'b0;
      scan_active <= 1'b0;
      capture_ready <= 1'b0;
      done_flag <= 1'b0;
      error_flag <= 1'b0;
      baseline_valid <= 1'b0;
      restore_to_error <= 1'b0;
      restore_in_progress <= 1'b0;
      diagnostic_i2c_owns_bus <= 1'b0;
      product_baseline_restored <= 1'b1;
      error_code <= ERR_NONE;
      first_i2c_error <= ERR_NONE;
      last_i2c_error <= ERR_NONE;
      i2c_transaction_count <= 32'b0;
      i2c_nack_count <= 32'b0;
      i2c_timeout_count <= 32'b0;
      i2c_bus_recovery_count <= 32'b0;
      scan_completed_sessions <= 32'b0;
      original_bank <= BANK0;
      original_bg78 <= 8'h88;
      original_bg79 <= 8'h88;
      original_route <= 8'h00;
      route_before_select <= 8'h00;
      current_route_readback <= 8'h00;
      current_bg78_readback <= 8'h88;
      current_bg79_readback <= 8'h88;
      current_classification <= CLASS_NONE;
      last_host_capture_response <= 32'b0;
      restore_status <= 32'h0000_0001;
      raw_novid <= 8'b0;
      raw_agc_lock <= 8'b0;
      raw_cmp_lock <= 8'b0;
      raw_h_lock <= 8'b0;
      raw_channel_status <= 8'b0;
      first_sample_signature <= 40'b0;
      current_sample_signature <= 40'b0;
      stable_sample_count <= 8'b0;
      total_status_samples <= 8'b0;
      delay_counter <= '0;
      status_wait_counter <= '0;
      config_verify_index <= 8'b0;
      txn_pending <= 1'b0;
      i2c_cmd_valid <= 1'b0;
      i2c_cmd_write <= 1'b0;
      i2c_cmd_reg <= 8'b0;
      i2c_cmd_wdata <= 8'b0;
      current_result_word_0 <= 32'b0;
      current_result_word_1 <= 32'b0;
      current_result_word_2 <= 32'b0;
      current_result_word_3 <= 32'b0;
      current_result_word_4 <= 32'b0;
      current_result_word_5 <= 32'b0;
      current_result_word_6 <= 32'b0;
      current_result_word_7 <= 32'b0;
      current_result_valid <= 1'b0;
      current_result_session_id <= 16'b0;
      current_result_generation <= 16'b0;
    end else begin
      i2c_cmd_valid <= 1'b0;

      if (i2c_cmd_accepted)
        i2c_transaction_count <= i2c_transaction_count + 1'b1;

      if (mmio_protocol_error_pulse && state != ERROR && state != ERROR_SAFE_RESTORE)
        latch_error(ERR_HOST_PROTOCOL);
      else if (control_pulse[3] && state != IDLE && state != DONE && state != ERROR)
        latch_error(ERR_OWNER_ABORT);
      else begin
        case (state)
          IDLE: begin
            capture_ready <= 1'b0;
            scan_active <= 1'b0;
            if (control_pulse[0]) begin
              prepared <= 1'b0;
              done_flag <= 1'b0;
              error_flag <= 1'b0;
              baseline_valid <= 1'b0;
              error_code <= ERR_NONE;
              first_i2c_error <= ERR_NONE;
              last_i2c_error <= ERR_NONE;
              i2c_transaction_count <= 32'b0;
              i2c_nack_count <= 32'b0;
              i2c_timeout_count <= 32'b0;
              scan_completed_sessions <= 32'b0;
              current_session_id <= 16'b0;
              product_baseline_restored <= 1'b1;
              restore_status <= 32'h0000_0001;
              current_result_word_0 <= 32'b0;
              current_result_word_1 <= 32'b0;
              current_result_word_2 <= 32'b0;
              current_result_word_3 <= 32'b0;
              current_result_word_4 <= 32'b0;
              current_result_word_5 <= 32'b0;
              current_result_word_6 <= 32'b0;
              current_result_word_7 <= 32'b0;
              current_result_valid <= 1'b0;
              current_result_session_id <= 16'b0;
              current_result_generation <= 16'b0;
            end else if (control_pulse[1]) begin
              if (!transport_quiescent || !autoinit_done || autoinit_busy ||
                  autoinit_error || !nvp_reset_released)
                latch_error(ERR_NOT_READY);
              else begin
                product_baseline_restored <= 1'b0;
                diagnostic_i2c_owns_bus <= 1'b0;
                substep <= 8'b0;
                state <= TAKE_I2C_OWNERSHIP;
              end
            end else if (control_pulse[2]) begin
              if (!prepared || !baseline_valid || !transport_quiescent)
                latch_error(ERR_NOT_READY);
              else begin
                current_round <= 3'd0;
                round_position <= 3'd0;
                current_channel <= 3'd1;
                current_session_id <= 16'd1;
                scan_active <= 1'b1;
                done_flag <= 1'b0;
                substep <= 8'b0;
                state <= BEGIN_ROUND;
              end
            end else if (control_pulse[4] && baseline_valid) begin
              restore_to_error <= 1'b0;
              restore_in_progress <= 1'b1;
              substep <= 8'b0;
              state <= RESTORE_PRODUCT_BASELINE;
            end
          end

          TAKE_I2C_OWNERSHIP: begin
            if (autoinit_done && !autoinit_busy && !autoinit_error &&
                nvp_reset_released && i2c_bus_idle && transport_quiescent) begin
              diagnostic_i2c_owns_bus <= 1'b1;
              substep <= 8'b0;
              state <= SAVE_PRODUCT_BASELINE;
            end
          end

          SAVE_PRODUCT_BASELINE: begin
            if (!txn_pending && i2c_cmd_ready) begin
              case (substep)
                0: launch_i2c(1'b0, BANK_SELECT, 8'b0);
                1: launch_i2c(1'b1, BANK_SELECT, BANK0);
                2: launch_i2c(1'b0, REG_BGDCOL_12, 8'b0);
                3: launch_i2c(1'b0, REG_BGDCOL_34, 8'b0);
                4: launch_i2c(1'b1, BANK_SELECT, BANK1);
                5: launch_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
                default: launch_i2c(1'b1, BANK_SELECT, original_bank);
              endcase
            end
            if (i2c_done && txn_pending) begin
              txn_pending <= 1'b0;
              if (!i2c_success) begin
                if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                else i2c_nack_count <= i2c_nack_count + 1'b1;
                latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
              end else begin
                case (substep)
                  0: original_bank <= i2c_read_data;
                  2: original_bg78 <= i2c_read_data;
                  3: original_bg79 <= i2c_read_data;
                  5: original_route <= i2c_read_data;
                  default: ;
                endcase
                if (substep == 6) begin
                  baseline_valid <= 1'b1;
                  substep <= 8'b0;
                  state <= CONFIGURE_ALL_CHANNELS;
                end else begin
                  substep <= substep + 1'b1;
                end
              end
            end
          end

          CONFIGURE_ALL_CHANNELS: begin
            // Product autoinit already configures all four channels for forced
            // 1080p25.  The diagnostic does not rewrite those registers; it
            // verifies the compiled product values below.
            config_verify_index <= 8'b0;
            substep <= 8'b0;
            state <= VERIFY_ALL_CHANNELS;
          end

          VERIFY_ALL_CHANNELS: begin
            if (!txn_pending && i2c_cmd_ready) begin
              if (substep == 0)
                launch_i2c(1'b1, BANK_SELECT, BANK0);
              else if (substep == 1)
                launch_i2c(1'b0, verify_reg(config_verify_index), 8'b0);
              else
                launch_i2c(1'b1, BANK_SELECT, original_bank);
            end
            if (i2c_done && txn_pending) begin
              txn_pending <= 1'b0;
              if (!i2c_success) begin
                if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                else i2c_nack_count <= i2c_nack_count + 1'b1;
                latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
              end else if (substep == 1 &&
                           i2c_read_data != verify_value(config_verify_index)) begin
                latch_error(ERR_CONFIG_MISMATCH);
              end else if (substep == 0) begin
                substep <= 8'd1;
              end else if (substep == 1 && config_verify_index < 16) begin
                config_verify_index <= config_verify_index + 1'b1;
              end else if (substep == 1) begin
                substep <= 8'd2;
              end else begin
                prepared <= 1'b1;
                product_baseline_restored <= 1'b1;
                diagnostic_i2c_owns_bus <= 1'b0;
                substep <= 8'b0;
                state <= IDLE;
              end
            end
          end

          BEGIN_ROUND: begin
            if (!transport_quiescent)
              latch_error(ERR_TRANSPORT_NOT_QUIESCENT);
            else begin
              current_channel <= scan_channel(current_round, 3'd0);
              round_position <= 3'd0;
              substep <= 8'b0;
              diagnostic_i2c_owns_bus <= 1'b1;
              product_baseline_restored <= 1'b0;
              state <= PROGRAM_ROUND_BGDCOL;
            end
          end

          PROGRAM_ROUND_BGDCOL: begin
            if (!transport_quiescent)
              latch_error(ERR_TRANSPORT_NOT_QUIESCENT);
            else begin
              if (!txn_pending && i2c_cmd_ready) begin
                case (substep)
                  0: launch_i2c(1'b1, BANK_SELECT, BANK0);
                  1: launch_i2c(1'b1, REG_BGDCOL_12,
                                round_bg78(current_round));
                  default: launch_i2c(1'b1, REG_BGDCOL_34,
                                     round_bg79(current_round));
                endcase
              end
              if (i2c_done && txn_pending) begin
                txn_pending <= 1'b0;
                if (!i2c_success) begin
                  if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                  else i2c_nack_count <= i2c_nack_count + 1'b1;
                  latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
                end else if (substep == 2) begin
                  substep <= 8'b0;
                  state <= VERIFY_ROUND_BGDCOL;
                end else begin
                  substep <= substep + 1'b1;
                end
              end
            end
          end

          VERIFY_ROUND_BGDCOL: begin
            if (!txn_pending && i2c_cmd_ready) begin
              if (substep == 0)
                launch_i2c(1'b0, REG_BGDCOL_12, 8'b0);
              else
                launch_i2c(1'b0, REG_BGDCOL_34, 8'b0);
            end
            if (i2c_done && txn_pending) begin
              txn_pending <= 1'b0;
              if (!i2c_success) begin
                if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                else i2c_nack_count <= i2c_nack_count + 1'b1;
                latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
              end else if (substep == 0) begin
                current_bg78_readback <= i2c_read_data;
                if (i2c_read_data != round_bg78(current_round))
                  latch_error(ERR_BGDCOL_MISMATCH);
                else
                  substep <= 8'd1;
              end else begin
                current_bg79_readback <= i2c_read_data;
                if (i2c_read_data != round_bg79(current_round))
                  latch_error(ERR_BGDCOL_MISMATCH);
                else begin
                  substep <= 8'b0;
                  state <= SELECT_CHANNEL;
                end
              end
            end
          end

          SELECT_CHANNEL: begin
            if (!transport_quiescent)
              latch_error(ERR_TRANSPORT_NOT_QUIESCENT);
            else begin
              if (!txn_pending && i2c_cmd_ready) begin
                case (substep)
                  0: launch_i2c(1'b1, BANK_SELECT, BANK1);
                  1: launch_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
                  default: launch_i2c(1'b1, REG_VDO1_ROUTE,
                      {route_before_select[7:4], 1'b0,
                       current_channel - 3'd1});
                endcase
              end
              if (i2c_done && txn_pending) begin
                txn_pending <= 1'b0;
                if (!i2c_success) begin
                  if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                  else i2c_nack_count <= i2c_nack_count + 1'b1;
                  latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
                end else begin
                  if (substep == 1)
                    route_before_select <= i2c_read_data;
                  if (substep == 2) begin
                    substep <= 8'b0;
                    state <= VERIFY_ROUTE;
                  end else
                    substep <= substep + 1'b1;
                end
              end
            end
          end

          VERIFY_ROUTE: begin
            if (!txn_pending && i2c_cmd_ready) begin
              if (substep == 0)
                launch_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
              else
                launch_i2c(1'b1, BANK_SELECT, BANK0);
            end
            if (i2c_done && txn_pending) begin
              txn_pending <= 1'b0;
              if (!i2c_success) begin
                if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                else i2c_nack_count <= i2c_nack_count + 1'b1;
                latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
              end else if (substep == 0) begin
                current_route_readback <= i2c_read_data;
                if (i2c_read_data[3:0] != current_channel - 1'b1)
                  latch_error(ERR_ROUTE_MISMATCH);
                else
                  substep <= 8'd1;
              end else begin
                delay_counter <= '0;
                substep <= 8'b0;
                state <= WAIT_SETTLE;
              end
            end
          end

          WAIT_SETTLE: begin
            if (!transport_quiescent)
              latch_error(ERR_TRANSPORT_NOT_QUIESCENT);
            else if (delay_counter + 1'b1 >= SETTLE_CYCLES) begin
              delay_counter <= '0;
              status_wait_counter <= '0;
              stable_sample_count <= 8'b0;
              total_status_samples <= 8'b0;
              first_sample_signature <= 40'b0;
              substep <= 8'b0;
              state <= SAMPLE_STATUS;
            end else begin
              delay_counter <= delay_counter + 1'b1;
            end
          end

          SAMPLE_STATUS: begin
            if (status_wait_counter < MAX_STATUS_WAIT_CYCLES)
              status_wait_counter <= status_wait_counter + 1'b1;
            // Never abandon a physical transaction at the status-window
            // boundary.  Reap the in-flight read first, then classify the
            // channel as unstable with the transaction interface idle.
            if (status_wait_counter >= MAX_STATUS_WAIT_CYCLES &&
                !txn_pending) begin
              current_classification <= CLASS_LOCK_UNSTABLE;
              substep <= 8'b0;
              state <= LATCH_SESSION_RESULT;
            end else if (delay_counter != 0) begin
              if (delay_counter + 1'b1 >= SAMPLE_INTERVAL_CYCLES) begin
                delay_counter <= '0;
                substep <= 8'b0;
              end else begin
                delay_counter <= delay_counter + 1'b1;
              end
            end else begin
              if (!txn_pending && i2c_cmd_ready) begin
                case (substep)
                  0: launch_i2c(1'b0, REG_NOVID, 8'b0);
                  1: launch_i2c(1'b0, REG_AGC_LOCK, 8'b0);
                  2: launch_i2c(1'b0, REG_CMP_LOCK, 8'b0);
                  3: launch_i2c(1'b0, REG_H_LOCK, 8'b0);
                  default: launch_i2c(1'b0,
                      channel_status_reg(current_channel), 8'b0);
                endcase
              end
              if (i2c_done && txn_pending) begin
                txn_pending <= 1'b0;
                if (!i2c_success) begin
                  current_classification <= CLASS_I2C_STATUS_ERROR;
                  if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                  else i2c_nack_count <= i2c_nack_count + 1'b1;
                  latch_error(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
                end else begin
                  case (substep)
                    0: raw_novid <= i2c_read_data;
                    1: raw_agc_lock <= i2c_read_data;
                    2: raw_cmp_lock <= i2c_read_data;
                    3: raw_h_lock <= i2c_read_data;
                    default: raw_channel_status <= i2c_read_data;
                  endcase
                  if (substep < 4) begin
                    substep <= substep + 1'b1;
                  end else begin
                    current_sample_signature <= {raw_novid, raw_agc_lock,
                        raw_cmp_lock, raw_h_lock, i2c_read_data};
                    total_status_samples <= total_status_samples + 1'b1;
                    if (stable_sample_count == 0 ||
                        {raw_novid, raw_agc_lock, raw_cmp_lock,
                         raw_h_lock, i2c_read_data} != first_sample_signature) begin
                      first_sample_signature <= {raw_novid, raw_agc_lock,
                          raw_cmp_lock, raw_h_lock, i2c_read_data};
                      stable_sample_count <= 8'd1;
                    end else begin
                      stable_sample_count <= stable_sample_count + 1'b1;
                    end
                    if (stable_sample_count + 1'b1 >= REQUIRED_STABLE_SAMPLES &&
                        stable_sample_count != 0 &&
                        {raw_novid, raw_agc_lock, raw_cmp_lock,
                         raw_h_lock, i2c_read_data} == first_sample_signature) begin
                      substep <= 8'b0;
                      state <= CLASSIFY_STATUS;
                    end else begin
                      delay_counter <= {{(DELAY_COUNTER_WIDTH-1){1'b0}}, 1'b1};
                    end
                  end
                end
              end
            end
          end

          CLASSIFY_STATUS: begin
            if (raw_novid[current_channel-1'b1] && raw_channel_status[0])
              current_classification <= CLASS_NO_VIDEO_STABLE;
            else if (!raw_novid[current_channel-1'b1] &&
                     !raw_channel_status[0] && raw_channel_status[1] &&
                     raw_agc_lock[current_channel-1'b1] &&
                     raw_cmp_lock[current_channel-1'b1] &&
                     raw_h_lock[current_channel-1'b1])
              current_classification <= CLASS_ACTIVE_STABLE;
            else
              current_classification <= CLASS_STATUS_CONTRADICTORY;
            state <= LATCH_SESSION_RESULT;
          end

          LATCH_SESSION_RESULT: begin
            // All snapshot payload and coherence metadata are committed in
            // this one clocked operation.  CAPTURE_READY is asserted only in
            // the following state, when these registered values are stable.
            current_result_word_0 <=
                {current_classification, current_channel,
                 current_round + 1'b1, 2'b0, current_session_id};
            current_result_word_1 <=
                {{5'b0, current_channel - 1'b1}, current_route_readback,
                 {4'b0, round_color(current_round, current_channel)},
                 stable_sample_count};
            current_result_word_2 <=
                {raw_novid, raw_agc_lock, raw_cmp_lock, raw_h_lock};
            current_result_word_3 <=
                {raw_channel_status, current_bg78_readback,
                 current_bg79_readback, total_status_samples};
            current_result_word_4 <=
                {8'b0, current_classification, 7'b0, round_position,
                 current_round, current_channel};
            current_result_word_5 <= i2c_transaction_count;
            current_result_word_6 <=
                {5'b0, |i2c_bus_recovery_count[31:8],
                 |i2c_timeout_count[31:8], |i2c_nack_count[31:8],
                 i2c_bus_recovery_count[7:0],
                 i2c_timeout_count[7:0], i2c_nack_count[7:0]};
            current_result_word_7 <=
                {last_i2c_error[7:0], first_i2c_error[7:0], error_code};
            current_result_session_id <= current_session_id;
            current_result_generation <= current_result_generation + 1'b1;
            current_result_valid <= 1'b1;
            state <= SIGNAL_CAPTURE_READY;
          end

          SIGNAL_CAPTURE_READY: begin
            if (!current_result_valid ||
                current_result_session_id != current_session_id) begin
              latch_error(ERR_HOST_PROTOCOL);
            end else begin
              capture_ready <= 1'b1;
              diagnostic_i2c_owns_bus <= 1'b0;
              state <= WAIT_HOST_CAPTURE;
            end
          end

          WAIT_HOST_CAPTURE: begin
            if (host_response_pulse) begin
              last_host_capture_response <= host_response_data;
              if (!current_result_valid ||
                  current_result_session_id != current_session_id ||
                  host_response_data[31:16] != current_session_id)
                latch_error(ERR_HOST_PROTOCOL);
              else begin
                capture_ready <= 1'b0;
                current_result_valid <= 1'b0;
                if (host_response_data[2])
                  latch_error(ERR_OWNER_ABORT);
                else if (host_response_data[1])
                  latch_error(ERR_CAPTURE_FAILED);
                else if (!host_response_data[0] || !host_response_data[3] ||
                         !transport_quiescent)
                  latch_error(ERR_HOST_PROTOCOL);
                else begin
                  diagnostic_i2c_owns_bus <= 1'b1;
                  scan_completed_sessions <= scan_completed_sessions + 1'b1;
                  state <= NEXT_CHANNEL;
                end
              end
            end
          end

          NEXT_CHANNEL: begin
            if (round_position == 3) begin
              state <= NEXT_ROUND;
            end else begin
              round_position <= round_position + 1'b1;
              current_channel <= scan_channel(current_round,
                                               round_position + 1'b1);
              current_session_id <= current_session_id + 1'b1;
              substep <= 8'b0;
              state <= SELECT_CHANNEL;
            end
          end

          NEXT_ROUND: begin
            if (current_round == 3) begin
              restore_to_error <= 1'b0;
              restore_in_progress <= 1'b1;
              substep <= 8'b0;
              state <= RESTORE_PRODUCT_BASELINE;
            end else begin
              current_round <= current_round + 1'b1;
              current_session_id <= current_session_id + 1'b1;
              state <= BEGIN_ROUND;
            end
          end

          ERROR_SAFE_RESTORE: begin
            capture_ready <= 1'b0;
            current_result_valid <= 1'b0;
            if (baseline_valid && transport_quiescent && !i2c_busy) begin
              diagnostic_i2c_owns_bus <= 1'b1;
              restore_in_progress <= 1'b1;
              restore_status <= 32'h0000_0002;
              substep <= 8'b0;
              state <= RESTORE_PRODUCT_BASELINE;
            end
          end

          RESTORE_PRODUCT_BASELINE: begin
            if (!transport_quiescent) begin
              if (!restore_to_error)
                latch_error(ERR_TRANSPORT_NOT_QUIESCENT);
            end else begin
              diagnostic_i2c_owns_bus <= 1'b1;
              if (!txn_pending && i2c_cmd_ready) begin
                case (substep)
                  0: launch_i2c(1'b1, BANK_SELECT, BANK0);
                  1: launch_i2c(1'b1, REG_BGDCOL_12, original_bg78);
                  2: launch_i2c(1'b1, REG_BGDCOL_34, original_bg79);
                  3: launch_i2c(1'b1, BANK_SELECT, BANK1);
                  4: launch_i2c(1'b1, REG_VDO1_ROUTE, original_route);
                  default: launch_i2c(1'b1, BANK_SELECT, original_bank);
                endcase
              end
              if (i2c_done && txn_pending) begin
                txn_pending <= 1'b0;
                if (!i2c_success) begin
                  if (i2c_timeout) i2c_timeout_count <= i2c_timeout_count + 1'b1;
                  else i2c_nack_count <= i2c_nack_count + 1'b1;
                  error_code <= ERR_RESTORE_FAILED;
                  error_flag <= 1'b1;
                  restore_status <= 32'h0000_0006;
                  state <= ERROR;
                end else if (substep == 5) begin
                  substep <= 8'b0;
                  state <= VERIFY_RESTORE;
                end else begin
                  substep <= substep + 1'b1;
                end
              end
            end
          end

          VERIFY_RESTORE: begin
            if (!txn_pending && i2c_cmd_ready) begin
              case (substep)
                0: launch_i2c(1'b1, BANK_SELECT, BANK0);
                1: launch_i2c(1'b0, REG_BGDCOL_12, 8'b0);
                2: launch_i2c(1'b0, REG_BGDCOL_34, 8'b0);
                3: launch_i2c(1'b1, BANK_SELECT, BANK1);
                4: launch_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
                5: launch_i2c(1'b1, BANK_SELECT, original_bank);
                default: launch_i2c(1'b0, BANK_SELECT, 8'b0);
              endcase
            end
            if (i2c_done && txn_pending) begin
              txn_pending <= 1'b0;
              if (i2c_success) begin
                if (substep == 1)
                  current_bg78_readback <= i2c_read_data;
                else if (substep == 2)
                  current_bg79_readback <= i2c_read_data;
                else if (substep == 4)
                  current_route_readback <= i2c_read_data;
              end
              if (!i2c_success ||
                  (substep == 1 && i2c_read_data != original_bg78) ||
                  (substep == 2 && i2c_read_data != original_bg79) ||
                  (substep == 4 && i2c_read_data != original_route) ||
                  (substep == 6 && i2c_read_data != original_bank)) begin
                error_code <= ERR_RESTORE_FAILED;
                error_flag <= 1'b1;
                restore_status <= 32'h0000_0006;
                state <= ERROR;
              end else if (substep == 6) begin
                product_baseline_restored <= 1'b1;
                diagnostic_i2c_owns_bus <= 1'b0;
                restore_in_progress <= 1'b0;
                restore_status <= 32'h0000_0003;
                scan_active <= 1'b0;
                if (restore_to_error) begin
                  state <= ERROR;
                end else begin
                  done_flag <= 1'b1;
                  state <= DONE;
                end
              end else begin
                substep <= substep + 1'b1;
              end
            end
          end

          DONE: begin
            scan_active <= 1'b0;
            capture_ready <= 1'b0;
            diagnostic_i2c_owns_bus <= 1'b0;
            if (control_pulse[0]) begin
              state <= IDLE;
              done_flag <= 1'b0;
              prepared <= 1'b0;
              baseline_valid <= 1'b0;
              error_code <= ERR_NONE;
            end
          end

          ERROR: begin
            scan_active <= 1'b0;
            capture_ready <= 1'b0;
            diagnostic_i2c_owns_bus <= 1'b0;
            if (control_pulse[0] && product_baseline_restored) begin
              state <= IDLE;
              error_flag <= 1'b0;
              prepared <= 1'b0;
              baseline_valid <= 1'b0;
              error_code <= ERR_NONE;
            end
          end

          default: latch_error(ERR_HOST_PROTOCOL);
        endcase
      end
    end
  end
endmodule
