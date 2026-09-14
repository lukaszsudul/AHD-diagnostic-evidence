`timescale 1ns/1ps

// DIAG2-RM1 bounded raw-marker monitor.
//
// Counters and trace writes are exclusively source-clock local.  The single
// synchronous dual-clock BRAM is the only wide source-to-AXI crossing.
// Frozen metadata entries 64..95 are written before DONE toggles.  AXI never
// treats a stopped-source-clock watchdog expiry as a valid snapshot.
module g2b_nvp_raw_marker_monitor #(
  parameter integer AXI_CYCLES_PER_MS = 62500,
  parameter integer RESPONSE_TIMEOUT_MS = 10,
  parameter integer COUNTER_WIDTH = 32,
  parameter logic [31:0] BUILD_FLAGS = 32'h0000_0000
) (
  input  logic        source_clk,
  input  logic        source_reset,
  input  logic        sample_valid,
  input  logic [7:0]  sample_byte,
  input  logic [1:0]  prefix_state,
  input  logic        candidate,
  input  logic        raw_parity_valid,
  input  logic        marker_f,
  input  logic        marker_v,
  input  logic        marker_h,
  input  logic        parser_qualified,
  input  logic [2:0]  parser_state,

  input  logic        axi_clk,
  input  logic        axi_aresetn,

  output logic        route_start_pulse,
  output logic        route_restore_pulse,
  output logic [2:0]  route_target_channel,
  input  logic        route_ready_pulse,
  input  logic        route_busy,
  input  logic        route_error,
  input  logic        route_error_pulse,
  input  logic [15:0] route_error_code,
  input  logic        route_restored,
  input  logic [7:0]  route_original,
  input  logic [7:0]  route_readback,

  input  logic        mmio_req_valid,
  output logic        mmio_req_ready,
  input  logic        mmio_req_write,
  input  logic [16:0] mmio_req_addr,
  input  logic [31:0] mmio_req_wdata,
  input  logic [3:0]  mmio_req_be,
  output logic        mmio_rsp_valid,
  input  logic        mmio_rsp_ready,
  output logic [31:0] mmio_rsp_rdata
);
  localparam logic [31:0] RM1_MAGIC = 32'h4e52_4d31; // "NRM1"
  localparam logic [31:0] RM1_VERSION = 32'h0001_0000;
  localparam logic [31:0] RM1_CAPABILITIES = 32'h0000_0fff;
  localparam logic [31:0] META_MAGIC = 32'h524d_314d;
  localparam integer TRACE_ENTRIES = 64;
  localparam integer META_BASE = 64;
  localparam integer META_ENTRIES = 32;
  localparam integer RAM_ENTRIES = 128;
  localparam integer ABORT_DRAIN_CYCLES = 4;
  localparam integer SOURCE_RESET_DRAIN_CYCLES = 4;
  localparam integer RESPONSE_TIMEOUT_CYCLES =
      AXI_CYCLES_PER_MS * RESPONSE_TIMEOUT_MS;

  localparam logic [31:0] STOP_NONE = 32'd0;
  localparam logic [31:0] STOP_WINDOW = 32'd1;
  localparam logic [31:0] STOP_MANUAL = 32'd2;
  localparam logic [31:0] STOP_SOURCE_RESET = 32'd3;
  localparam logic [31:0] STOP_AXI_TIMEOUT = 32'd4;
  localparam logic [31:0] STOP_ROUTE_ERROR = 32'd5;

  function automatic [COUNTER_WIDTH-1:0] sat_inc(
      input [COUNTER_WIDTH-1:0] value);
    begin
      sat_inc = (&value) ? value : value + 1'b1;
    end
  endfunction

  function automatic [31:0] extend_counter(
      input [COUNTER_WIDTH-1:0] value);
    begin
      extend_counter = 32'b0;
      extend_counter[COUNTER_WIDTH-1:0] = value;
    end
  endfunction

  function automatic [31:0] window_cycles(input logic [1:0] selection);
    begin
      case (selection)
        2'd0: window_cycles = AXI_CYCLES_PER_MS * 100;
        2'd1: window_cycles = AXI_CYCLES_PER_MS * 500;
        2'd2: window_cycles = AXI_CYCLES_PER_MS * 1000;
        default: window_cycles = AXI_CYCLES_PER_MS * 500;
      endcase
    end
  endfunction

  function automatic [31:0] window_ms(input logic [1:0] selection);
    begin
      case (selection)
        2'd0: window_ms = 32'd100;
        2'd1: window_ms = 32'd500;
        2'd2: window_ms = 32'd1000;
        default: window_ms = 32'd500;
      endcase
    end
  endfunction

  // AXI-to-source commands.  The route/session/window buses are stable from
  // ARM acceptance through ACK; the synchronized ARM toggle is their mailbox
  // validity token.
  logic clear_toggle_axi = 1'b0;
  logic arm_toggle_axi = 1'b0;
  logic freeze_toggle_axi = 1'b0;
  logic freeze_manual_toggle_axi = 1'b0;
  logic ack_toggle_axi = 1'b0;
  logic abort_epoch_toggle_axi = 1'b0;
  logic [15:0] arm_session_hold_axi = 16'b0;
  logic [2:0] arm_route_hold_axi = 3'd1;
  logic [1:0] arm_window_hold_axi = 2'd1;

  (* ASYNC_REG = "TRUE" *) logic clear_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic clear_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic arm_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic arm_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic freeze_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic freeze_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic freeze_manual_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic freeze_manual_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ack_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_epoch_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_epoch_sync2_source = 1'b0;
  logic clear_seen_source = 1'b0;
  logic arm_seen_source = 1'b0;
  logic freeze_seen_source = 1'b0;
  logic freeze_manual_seen_source = 1'b0;
  logic ack_seen_source = 1'b0;
  logic abort_epoch_seen_source = 1'b0;
  logic abort_ack_toggle_source = 1'b0;
  logic [2:0] abort_drain_count_source = 3'b0;
  logic abort_drain_ack_pending_source = 1'b0;
  logic [2:0] source_reset_drain_count_source = 3'b0;
  logic source_reset_drain_ack_pending_source = 1'b0;
  logic source_reset_publish_invalid_source = 1'b0;
  logic source_reset_return_frozen_source = 1'b0;
  logic source_reset_ack_requires_drain_source = 1'b0;

  typedef enum logic [2:0] {
    SM_IDLE,
    SM_MEASURE,
    SM_META_WRITE,
    SM_META_WAIT,
    SM_DONE_PUBLISH,
    SM_FROZEN,
    SM_ABORT_DRAIN,
    SM_SOURCE_RESET_DRAIN
  } source_monitor_state_t;
  source_monitor_state_t monitor_state_source = SM_IDLE;

  logic armed_source = 1'b0;
  logic done_toggle_source = 1'b0;
  logic ack_done_toggle_source = 1'b0;
  logic snapshot_valid_source = 1'b0;
  logic trace_overflow_source = 1'b0;
  logic [15:0] generation_source = 16'b0;
  logic [15:0] session_source = 16'b0;
  logic [2:0] route_source = 3'd1;
  logic [1:0] window_source = 2'd1;
  logic [2:0] parser_state_at_freeze = 3'b0;
  logic [31:0] stop_reason_source = STOP_NONE;

  logic [COUNTER_WIDTH-1:0] raw_sample_count = '0;
  logic [COUNTER_WIDTH-1:0] byte_change_count = '0;
  logic [COUNTER_WIDTH-1:0] byte_00_count = '0;
  logic [COUNTER_WIDTH-1:0] byte_ff_count = '0;
  logic [COUNTER_WIDTH-1:0] prefix_ff00_count = '0;
  logic [COUNTER_WIDTH-1:0] prefix_ff0000_count = '0;
  logic [COUNTER_WIDTH-1:0] candidate_count = '0;
  logic [COUNTER_WIDTH-1:0] parity_pass_count = '0;
  logic [COUNTER_WIDTH-1:0] parity_fail_count = '0;
  logic [COUNTER_WIDTH-1:0] legal_sav_count = '0;
  logic [COUNTER_WIDTH-1:0] legal_eav_count = '0;
  logic [COUNTER_WIDTH-1:0] sav_fv_count [0:3];
  logic [COUNTER_WIDTH-1:0] eav_fv_count [0:3];
  logic [COUNTER_WIDTH-1:0] qualified_sav_count = '0;
  logic [COUNTER_WIDTH-1:0] qualified_eav_count = '0;
  logic [COUNTER_WIDTH-1:0] parser_reject_count = '0;
  logic [COUNTER_WIDTH-1:0] min_sav_gap = {COUNTER_WIDTH{1'b1}};
  logic [COUNTER_WIDTH-1:0] max_sav_gap = '0;
  logic [COUNTER_WIDTH-1:0] last_sav_gap = '0;
  logic [COUNTER_WIDTH-1:0] min_sav_eav = {COUNTER_WIDTH{1'b1}};
  logic [COUNTER_WIDTH-1:0] max_sav_eav = '0;
  logic [COUNTER_WIDTH-1:0] last_sav_eav = '0;
  logic [COUNTER_WIDTH-1:0] samples_since_sav = '0;
  logic [COUNTER_WIDTH-1:0] samples_since_open_sav = '0;
  logic have_previous_byte = 1'b0;
  logic [7:0] previous_byte = 8'b0;
  logic have_legal_sav = 1'b0;
  logic have_open_sav = 1'b0;

  logic [5:0] trace_write_ptr_source = 6'b0;
  logic [6:0] trace_valid_count_source = 7'b0;
  logic [5:0] metadata_index_source = 6'b0;
  logic ram_we_source = 1'b0;
  logic [6:0] ram_write_addr_source = 7'b0;
  logic [63:0] ram_write_data_source = 64'b0;
  logic ram_read_enable_axi = 1'b0;
  logic [6:0] ram_read_addr_axi = 7'b0;
  logic [63:0] ram_read_data_axi;

  function automatic [63:0] trace_entry_value;
    logic [63:0] value;
    begin
      value = 64'b0;
      value[7:0] = sample_byte;
      value[9:8] = prefix_state;
      value[10] = candidate;
      value[11] = raw_parity_valid;
      value[12] = marker_f;
      value[13] = marker_v;
      value[14] = marker_h;
      value[15] = candidate && raw_parity_valid && !marker_h;
      value[16] = candidate && raw_parity_valid && marker_h;
      value[17] = parser_qualified;
      value[18] = parser_qualified;
      value[21:19] = parser_state;
      value[31:22] = samples_since_sav;
      value[47:32] = session_source;
      value[50:48] = route_source;
      value[52:51] = window_source;
      value[63:53] = generation_source[10:0];
      trace_entry_value = value;
    end
  endfunction

  function automatic [63:0] metadata_value(input logic [5:0] index);
    logic [63:0] value;
    begin
      value = 64'b0;
      case (index)
        0: begin value[31:0] = META_MAGIC; value[47:32] = generation_source; end
        1: begin
          value[15:0] = session_source;
          value[18:16] = route_source;
          value[20:19] = window_source;
          value[21] = snapshot_valid_source;
          value[24:22] = parser_state_at_freeze;
        end
        2: value[31:0] = extend_counter(raw_sample_count);
        3: value[31:0] = extend_counter(byte_change_count);
        4: value[31:0] = extend_counter(byte_00_count);
        5: value[31:0] = extend_counter(byte_ff_count);
        6: value[31:0] = extend_counter(prefix_ff00_count);
        7: value[31:0] = extend_counter(prefix_ff0000_count);
        8: value[31:0] = extend_counter(candidate_count);
        9: value[31:0] = extend_counter(parity_pass_count);
        10: value[31:0] = extend_counter(parity_fail_count);
        11: value[31:0] = extend_counter(legal_sav_count);
        12: value[31:0] = extend_counter(legal_eav_count);
        13: value[31:0] = extend_counter(sav_fv_count[0]);
        14: value[31:0] = extend_counter(sav_fv_count[1]);
        15: value[31:0] = extend_counter(sav_fv_count[2]);
        16: value[31:0] = extend_counter(sav_fv_count[3]);
        17: value[31:0] = extend_counter(eav_fv_count[0]);
        18: value[31:0] = extend_counter(eav_fv_count[1]);
        19: value[31:0] = extend_counter(eav_fv_count[2]);
        20: value[31:0] = extend_counter(eav_fv_count[3]);
        21: value[31:0] = extend_counter(qualified_sav_count);
        22: value[31:0] = extend_counter(qualified_eav_count);
        23: value[31:0] = extend_counter(parser_reject_count);
        24: value[31:0] = have_legal_sav ? extend_counter(min_sav_gap) :
                                                  32'hffff_ffff;
        25: value[31:0] = extend_counter(max_sav_gap);
        26: value[31:0] = extend_counter(last_sav_gap);
        27: value[31:0] = have_open_sav || last_sav_eav != 0 ?
                         extend_counter(min_sav_eav) : 32'hffff_ffff;
        28: value[31:0] = extend_counter(max_sav_eav);
        29: value[31:0] = extend_counter(last_sav_eav);
        30: begin
          value[6:0] = trace_valid_count_source;
          value[13:8] = trace_write_ptr_source;
          value[16] = trace_overflow_source;
        end
        31: value[31:0] = stop_reason_source;
        default: value = 64'b0;
      endcase
      metadata_value = value;
    end
  endfunction

  task automatic clear_source_counters;
    integer clear_index;
    begin
      raw_sample_count <= '0;
      byte_change_count <= '0;
      byte_00_count <= '0;
      byte_ff_count <= '0;
      prefix_ff00_count <= '0;
      prefix_ff0000_count <= '0;
      candidate_count <= '0;
      parity_pass_count <= '0;
      parity_fail_count <= '0;
      legal_sav_count <= '0;
      legal_eav_count <= '0;
      for (clear_index = 0; clear_index < 4; clear_index = clear_index + 1) begin
        sav_fv_count[clear_index] <= '0;
        eav_fv_count[clear_index] <= '0;
      end
      qualified_sav_count <= '0;
      qualified_eav_count <= '0;
      parser_reject_count <= '0;
      min_sav_gap <= {COUNTER_WIDTH{1'b1}};
      max_sav_gap <= '0;
      last_sav_gap <= '0;
      min_sav_eav <= {COUNTER_WIDTH{1'b1}};
      max_sav_eav <= '0;
      last_sav_eav <= '0;
      samples_since_sav <= '0;
      samples_since_open_sav <= '0;
      have_previous_byte <= 1'b0;
      previous_byte <= 8'b0;
      have_legal_sav <= 1'b0;
      have_open_sav <= 1'b0;
      trace_write_ptr_source <= 6'b0;
      trace_valid_count_source <= 7'b0;
      trace_overflow_source <= 1'b0;
    end
  endtask

  xpm_memory_sdpram #(
    .ADDR_WIDTH_A(7), .ADDR_WIDTH_B(7),
    .AUTO_SLEEP_TIME(0), .BYTE_WRITE_WIDTH_A(64),
    .CLOCKING_MODE("independent_clock"), .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"), .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"), .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(RAM_ENTRIES * 64), .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_B(64), .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("0"), .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(1), .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(0), .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(64), .WRITE_MODE_B("read_first")
  ) RM1_SNAPSHOT_RAM (
    .clka(source_clk), .ena(ram_we_source), .wea(ram_we_source),
    .addra(ram_write_addr_source), .dina(ram_write_data_source),
    .clkb(axi_clk), .enb(ram_read_enable_axi), .addrb(ram_read_addr_axi),
    .doutb(ram_read_data_axi), .rstb(~axi_aresetn), .regceb(1'b1),
    .sleep(1'b0), .injectsbiterra(1'b0), .injectdbiterra(1'b0),
    .sbiterrb(), .dbiterrb()
  );

  always_ff @(posedge source_clk) begin : SOURCE_MONITOR
    logic clear_command;
    logic arm_command;
    logic freeze_command;
    logic freeze_manual_command;
    logic ack_command;
    logic abort_epoch_command;
    logic raw_legal;
    logic trace_event;
    logic [COUNTER_WIDTH-1:0] distance_value;

    clear_sync1_source <= clear_toggle_axi;
    clear_sync2_source <= clear_sync1_source;
    arm_sync1_source <= arm_toggle_axi;
    arm_sync2_source <= arm_sync1_source;
    freeze_sync1_source <= freeze_toggle_axi;
    freeze_sync2_source <= freeze_sync1_source;
    freeze_manual_sync1_source <= freeze_manual_toggle_axi;
    freeze_manual_sync2_source <= freeze_manual_sync1_source;
    ack_sync1_source <= ack_toggle_axi;
    ack_sync2_source <= ack_sync1_source;
    abort_epoch_sync1_source <= abort_epoch_toggle_axi;
    abort_epoch_sync2_source <= abort_epoch_sync1_source;

    clear_command = clear_sync2_source != clear_seen_source;
    arm_command = arm_sync2_source != arm_seen_source;
    freeze_command = freeze_sync2_source != freeze_seen_source;
    freeze_manual_command =
        freeze_manual_sync2_source != freeze_manual_seen_source;
    ack_command = ack_sync2_source != ack_seen_source;
    abort_epoch_command =
        abort_epoch_sync2_source != abort_epoch_seen_source;
    raw_legal = candidate && raw_parity_valid;
    trace_event = sample_valid &&
        (sample_byte == 8'hff || prefix_state != 0 || candidate ||
         parser_qualified);
    distance_value = '0;
    ram_we_source <= 1'b0;

    if (abort_epoch_command) begin
      // Discard an orphaned source session without publishing its active
      // wide state.  Do not echo immediately: independently synchronized
      // pre-abort command tokens may still be behind this request.
      abort_epoch_seen_source <= abort_epoch_sync2_source;
      clear_seen_source <= clear_sync2_source;
      arm_seen_source <= arm_sync2_source;
      freeze_seen_source <= freeze_sync2_source;
      freeze_manual_seen_source <= freeze_manual_sync2_source;
      ack_seen_source <= ack_sync2_source;
      abort_drain_ack_pending_source <= ack_sync2_source != ack_seen_source;
      abort_drain_count_source <= 3'b0;
      armed_source <= 1'b0;
      snapshot_valid_source <= 1'b0;
      stop_reason_source <= STOP_AXI_TIMEOUT;
      monitor_state_source <= SM_ABORT_DRAIN;
    end else if (source_reset) begin
      clear_seen_source <= clear_sync2_source;
      arm_seen_source <= arm_sync2_source;
      freeze_seen_source <= freeze_sync2_source;
      freeze_manual_seen_source <= freeze_manual_sync2_source;
      armed_source <= 1'b0;
      source_reset_ack_requires_drain_source <= 1'b1;
      if (monitor_state_source == SM_ABORT_DRAIN) begin
        // Reset cannot terminate an outstanding abort mailbox.  Continue to
        // absorb all command stages and restart the quarantine interval once
        // source_reset is released.
        if (ack_sync2_source != ack_seen_source)
          abort_drain_ack_pending_source <= 1'b1;
        ack_seen_source <= ack_sync2_source;
        abort_drain_count_source <= 3'b0;
        monitor_state_source <= SM_ABORT_DRAIN;
      end else begin
        // A source reset is itself an asynchronous protocol boundary.  Do
        // not publish an incomplete record immediately after deassertion:
        // AUTO/MANUAL/ARM/ACK tokens already inside their independent two-
        // flop synchronizers may arrive later.  Restart a four-edge drain
        // while reset is asserted, continuously absorb every command, and
        // only then publish an invalid record or resume the prior frozen one.
        if (monitor_state_source != SM_SOURCE_RESET_DRAIN) begin
          source_reset_publish_invalid_source <=
              monitor_state_source == SM_MEASURE ||
              monitor_state_source == SM_META_WRITE ||
              monitor_state_source == SM_META_WAIT ||
              monitor_state_source == SM_DONE_PUBLISH ||
              arm_sync2_source != arm_seen_source;
          source_reset_return_frozen_source <=
              monitor_state_source == SM_FROZEN && snapshot_valid_source;
          source_reset_drain_ack_pending_source <=
              ack_sync2_source != ack_seen_source;
          if (monitor_state_source == SM_MEASURE ||
              monitor_state_source == SM_META_WRITE ||
              monitor_state_source == SM_META_WAIT ||
              monitor_state_source == SM_DONE_PUBLISH ||
              arm_sync2_source != arm_seen_source) begin
            snapshot_valid_source <= 1'b0;
            stop_reason_source <= STOP_SOURCE_RESET;
            parser_state_at_freeze <= parser_state;
          end
        end else if (ack_sync2_source != ack_seen_source)
          source_reset_drain_ack_pending_source <= 1'b1;
        ack_seen_source <= ack_sync2_source;
        source_reset_drain_count_source <= 3'b0;
        monitor_state_source <= SM_SOURCE_RESET_DRAIN;
      end
    end else if (clear_command && monitor_state_source == SM_IDLE) begin
      clear_seen_source <= clear_sync2_source;
      snapshot_valid_source <= 1'b0;
      stop_reason_source <= STOP_NONE;
      clear_source_counters();
    end else if (arm_command && monitor_state_source == SM_IDLE) begin
      arm_seen_source <= arm_sync2_source;
      session_source <= arm_session_hold_axi;
      route_source <= arm_route_hold_axi;
      window_source <= arm_window_hold_axi;
      generation_source <= generation_source + 1'b1;
      snapshot_valid_source <= 1'b0;
      stop_reason_source <= STOP_NONE;
      clear_source_counters();
      armed_source <= 1'b1;
      source_reset_ack_requires_drain_source <= 1'b0;
      monitor_state_source <= SM_MEASURE;
    end else if (ack_command &&
                 (monitor_state_source == SM_FROZEN ||
                  monitor_state_source == SM_IDLE)) begin
      ack_seen_source <= ack_sync2_source;
      armed_source <= 1'b0;
      if (source_reset_ack_requires_drain_source ||
          (monitor_state_source == SM_FROZEN &&
           !snapshot_valid_source &&
           stop_reason_source == STOP_SOURCE_RESET)) begin
        // An invalid source-reset record may have been published while an
        // AXI AUTO/MANUAL token was still in flight.  Delay the ACK echo and
        // drain once more before returning IDLE so that token cannot freeze
        // the next session.
        source_reset_drain_ack_pending_source <= 1'b1;
        source_reset_drain_count_source <= 3'b0;
        source_reset_publish_invalid_source <= 1'b0;
        source_reset_return_frozen_source <= 1'b0;
        monitor_state_source <= SM_SOURCE_RESET_DRAIN;
      end else begin
        monitor_state_source <= SM_IDLE;
        ack_done_toggle_source <= ~ack_done_toggle_source;
      end
    end else begin
      case (monitor_state_source)
        SM_MEASURE: begin
          if (freeze_command || freeze_manual_command) begin
            freeze_seen_source <= freeze_sync2_source;
            freeze_manual_seen_source <= freeze_manual_sync2_source;
            armed_source <= 1'b0;
            snapshot_valid_source <= 1'b1;
            stop_reason_source <= freeze_manual_command ?
                                  STOP_MANUAL : STOP_WINDOW;
            parser_state_at_freeze <= parser_state;
            metadata_index_source <= 6'b0;
            monitor_state_source <= SM_META_WRITE;
          end else if (sample_valid) begin
            raw_sample_count <= sat_inc(raw_sample_count);
            if (have_previous_byte && sample_byte != previous_byte)
              byte_change_count <= sat_inc(byte_change_count);
            previous_byte <= sample_byte;
            have_previous_byte <= 1'b1;
            if (sample_byte == 8'h00)
              byte_00_count <= sat_inc(byte_00_count);
            if (sample_byte == 8'hff)
              byte_ff_count <= sat_inc(byte_ff_count);
            if (prefix_state == 2'd1)
              prefix_ff00_count <= sat_inc(prefix_ff00_count);
            if (prefix_state == 2'd2)
              prefix_ff0000_count <= sat_inc(prefix_ff0000_count);

            if (candidate) begin
              candidate_count <= sat_inc(candidate_count);
              if (raw_parity_valid)
                parity_pass_count <= sat_inc(parity_pass_count);
              else
                parity_fail_count <= sat_inc(parity_fail_count);
            end
            if (raw_legal && !marker_h) begin
              legal_sav_count <= sat_inc(legal_sav_count);
              sav_fv_count[{marker_f, marker_v}] <=
                  sat_inc(sav_fv_count[{marker_f, marker_v}]);
              if (have_legal_sav) begin
                distance_value = sat_inc(samples_since_sav);
                last_sav_gap <= distance_value;
                if (distance_value < min_sav_gap)
                  min_sav_gap <= distance_value;
                if (distance_value > max_sav_gap)
                  max_sav_gap <= distance_value;
              end
              have_legal_sav <= 1'b1;
              have_open_sav <= 1'b1;
              samples_since_sav <= '0;
              samples_since_open_sav <= '0;
            end else begin
              if (have_legal_sav)
                samples_since_sav <= sat_inc(samples_since_sav);
              if (have_open_sav)
                samples_since_open_sav <= sat_inc(samples_since_open_sav);
            end
            if (raw_legal && marker_h) begin
              legal_eav_count <= sat_inc(legal_eav_count);
              eav_fv_count[{marker_f, marker_v}] <=
                  sat_inc(eav_fv_count[{marker_f, marker_v}]);
              if (have_open_sav) begin
                distance_value = sat_inc(samples_since_open_sav);
                last_sav_eav <= distance_value;
                if (distance_value < min_sav_eav)
                  min_sav_eav <= distance_value;
                if (distance_value > max_sav_eav)
                  max_sav_eav <= distance_value;
                have_open_sav <= 1'b0;
              end
            end
            if (parser_qualified && !marker_h)
              qualified_sav_count <= sat_inc(qualified_sav_count);
            if (parser_qualified && marker_h)
              qualified_eav_count <= sat_inc(qualified_eav_count);
            if (raw_legal && !parser_qualified)
              parser_reject_count <= sat_inc(parser_reject_count);

            if (trace_event) begin
              ram_we_source <= 1'b1;
              ram_write_addr_source <= {1'b0, trace_write_ptr_source};
              ram_write_data_source <= trace_entry_value();
              if (trace_valid_count_source < TRACE_ENTRIES)
                trace_valid_count_source <= trace_valid_count_source + 1'b1;
              else
                trace_overflow_source <= 1'b1;
              if (trace_write_ptr_source == TRACE_ENTRIES-1) begin
                trace_write_ptr_source <= 6'b0;
                if (trace_valid_count_source == TRACE_ENTRIES)
                  trace_overflow_source <= 1'b1;
              end else
                trace_write_ptr_source <= trace_write_ptr_source + 1'b1;
            end
          end
        end

        SM_META_WRITE: begin
          // Commands rejected by the AXI protocol must not remain pending in
          // the source domain and poison the next session after publication.
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
          ram_we_source <= 1'b1;
          ram_write_addr_source <= META_BASE + metadata_index_source;
          ram_write_data_source <= metadata_value(metadata_index_source);
          if (metadata_index_source == META_ENTRIES-1)
            monitor_state_source <= SM_META_WAIT;
          else
            metadata_index_source <= metadata_index_source + 1'b1;
        end

        SM_META_WAIT: begin
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
          monitor_state_source <= SM_DONE_PUBLISH;
        end

        SM_DONE_PUBLISH: begin
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
          done_toggle_source <= ~done_toggle_source;
          monitor_state_source <= SM_FROZEN;
        end

        SM_FROZEN: begin
          // Counter and BRAM contents remain immutable until ACK.
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
        end

        SM_ABORT_DRAIN: begin
          // Quarantine for longer than the two-flop command synchronizer
          // depth.  Continuously absorb late CLEAR/ARM/FREEZE/MANUAL/ACK
          // tokens, then echo the abort.  An absorbed ACK receives its own
          // completion echo so a route-error+ACK cannot strand ownership.
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
          if (ack_sync2_source != ack_seen_source)
            abort_drain_ack_pending_source <= 1'b1;
          ack_seen_source <= ack_sync2_source;
          if (abort_drain_count_source + 1'b1 >= ABORT_DRAIN_CYCLES) begin
            abort_ack_toggle_source <= abort_epoch_seen_source;
            if (abort_drain_ack_pending_source ||
                ack_sync2_source != ack_seen_source)
              ack_done_toggle_source <= ~ack_done_toggle_source;
            abort_drain_ack_pending_source <= 1'b0;
            abort_drain_count_source <= 3'b0;
            source_reset_ack_requires_drain_source <= 1'b0;
            monitor_state_source <= SM_IDLE;
          end else
            abort_drain_count_source <= abort_drain_count_source + 1'b1;
        end

        SM_SOURCE_RESET_DRAIN: begin
          // Like the AXI abort mailbox, source-reset recovery quarantines all
          // independently synchronized command tokens for four complete
          // source edges.  DONE cannot change while this state is active.
          clear_seen_source <= clear_sync2_source;
          arm_seen_source <= arm_sync2_source;
          freeze_seen_source <= freeze_sync2_source;
          freeze_manual_seen_source <= freeze_manual_sync2_source;
          if (arm_sync2_source != arm_seen_source) begin
            // ARM may have been launched by route_ready while source_reset
            // collided with source IDLE.  Absorb it, but remember that AXI
            // owns a discarded session and requires a terminal invalid DONE.
            source_reset_publish_invalid_source <= 1'b1;
            snapshot_valid_source <= 1'b0;
            stop_reason_source <= STOP_SOURCE_RESET;
            parser_state_at_freeze <= parser_state;
          end
          if (ack_sync2_source != ack_seen_source)
            source_reset_drain_ack_pending_source <= 1'b1;
          ack_seen_source <= ack_sync2_source;
          armed_source <= 1'b0;
          snapshot_valid_source <= source_reset_return_frozen_source;
          if (source_reset_drain_count_source + 1'b1 >=
              SOURCE_RESET_DRAIN_CYCLES) begin
            source_reset_drain_count_source <= 3'b0;
            if (source_reset_drain_ack_pending_source ||
                ack_sync2_source != ack_seen_source) begin
              // A timeout/invalid-DONE ACK may reach the stopped source while
              // it drains.  Echo it exactly once and do not strand FROZEN.
              ack_done_toggle_source <= ~ack_done_toggle_source;
              snapshot_valid_source <= 1'b0;
              source_reset_ack_requires_drain_source <= 1'b0;
              monitor_state_source <= SM_IDLE;
            end else if (source_reset_publish_invalid_source ||
                         arm_sync2_source != arm_seen_source) begin
              snapshot_valid_source <= 1'b0;
              stop_reason_source <= STOP_SOURCE_RESET;
              metadata_index_source <= 6'b0;
              monitor_state_source <= SM_META_WRITE;
            end else if (source_reset_return_frozen_source)
              monitor_state_source <= SM_FROZEN;
            else
              monitor_state_source <= SM_IDLE;
            source_reset_drain_ack_pending_source <= 1'b0;
            source_reset_publish_invalid_source <= 1'b0;
            source_reset_return_frozen_source <= 1'b0;
          end else
            source_reset_drain_count_source <=
                source_reset_drain_count_source + 1'b1;
        end

        default: begin
          armed_source <= 1'b0;
          monitor_state_source <= SM_IDLE;
        end
      endcase
    end
  end

  // Source-to-AXI status crossings are single-bit only.  All wide evidence is
  // consumed through RM1_SNAPSHOT_RAM after the completion toggle.
  (* ASYNC_REG = "TRUE" *) logic armed_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic armed_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync3_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic valid_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic valid_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ack_done_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ack_done_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ack_done_sync3_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_ack_sync2_axi = 1'b0;

  logic [2:0] configured_channel_axi = 3'd1;
  logic [1:0] configured_window_axi = 2'd1;
  logic [15:0] next_session_axi = 16'd1;
  logic [15:0] active_session_axi = 16'b0;
  logic awaiting_ack_axi = 1'b0;
  logic ack_pending_axi = 1'b0;
  logic source_ack_complete_axi = 1'b0;
  logic ack_done_seen_axi = 1'b0;
  logic abort_outstanding_axi = 1'b0;
  logic axi_recovery_pending = 1'b1;
  logic measurement_started_axi = 1'b0;
  logic freeze_issued_axi = 1'b0;
  logic completion_armed_axi = 1'b0;
  logic public_done_axi = 1'b0;
  logic public_valid_axi = 1'b0;
  logic stopped_clock_timeout_axi = 1'b0;
  logic done_seen_axi = 1'b0;
  logic [31:0] measurement_counter_axi = 32'b0;
  logic [31:0] response_counter_axi = 32'b0;
  logic [31:0] arm_rejected_count_axi = 32'b0;
  logic [31:0] protocol_error_count_axi = 32'b0;
  logic [5:0] trace_read_index_axi = 6'b0;
  logic [5:0] snapshot_read_index_axi = 6'b0;
  logic [1:0] ram_read_wait_axi = 2'b0;
  logic ram_read_high_axi = 1'b0;
  logic ram_read_inflight_axi = 1'b0;

  wire mmio_selected = mmio_req_addr >= 17'h03c00 &&
                       mmio_req_addr <= 17'h03fff;
  wire ram_data_read = mmio_req_addr == 17'h03c34 ||
                       mmio_req_addr == 17'h03c38 ||
                       mmio_req_addr == 17'h03c40 ||
                       mmio_req_addr == 17'h03c44;
  assign mmio_req_ready = mmio_selected && !mmio_rsp_valid &&
                          ram_read_wait_axi == 0;
  assign route_target_channel = configured_channel_axi;

  always_ff @(posedge axi_clk) begin : AXI_CONTROL_AND_MMIO
    logic [31:0] status_word;
    logic control_ok;

    armed_sync1_axi <= armed_source;
    armed_sync2_axi <= armed_sync1_axi;
    done_sync1_axi <= done_toggle_source;
    done_sync2_axi <= done_sync1_axi;
    done_sync3_axi <= done_sync2_axi;
    valid_sync1_axi <= snapshot_valid_source;
    valid_sync2_axi <= valid_sync1_axi;
    overflow_sync1_axi <= trace_overflow_source;
    overflow_sync2_axi <= overflow_sync1_axi;
    ack_done_sync1_axi <= ack_done_toggle_source;
    ack_done_sync2_axi <= ack_done_sync1_axi;
    ack_done_sync3_axi <= ack_done_sync2_axi;
    abort_ack_sync1_axi <= abort_ack_toggle_source;
    abort_ack_sync2_axi <= abort_ack_sync1_axi;

    route_start_pulse <= 1'b0;
    route_restore_pulse <= 1'b0;
    ram_read_enable_axi <= 1'b0;
    control_ok = mmio_req_be == 4'hf;

    if (!axi_aresetn) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      // Command toggles are intentionally retained across axi_aresetn.  A
      // forced 1->0 transition is itself a valid toggle-domain command and
      // could arrive after the independently synchronized abort request.
      // The persistent abort request/echo protocol drains source ownership;
      // reset must never manufacture CLEAR/ARM/FREEZE/MANUAL/ACK events.
      arm_session_hold_axi <= 16'b0;
      arm_route_hold_axi <= 3'd1;
      arm_window_hold_axi <= 2'd1;
      configured_channel_axi <= 3'd1;
      configured_window_axi <= 2'd1;
      next_session_axi <= 16'd1;
      active_session_axi <= 16'b0;
      awaiting_ack_axi <= 1'b0;
      ack_pending_axi <= 1'b0;
      source_ack_complete_axi <= 1'b0;
      ack_done_seen_axi <= ack_done_sync3_axi;
      axi_recovery_pending <= 1'b1;
      measurement_started_axi <= 1'b0;
      freeze_issued_axi <= 1'b0;
      completion_armed_axi <= 1'b0;
      public_done_axi <= 1'b0;
      public_valid_axi <= 1'b0;
      stopped_clock_timeout_axi <= 1'b0;
      done_seen_axi <= 1'b0;
      measurement_counter_axi <= 32'b0;
      response_counter_axi <= 32'b0;
      arm_rejected_count_axi <= 32'b0;
      protocol_error_count_axi <= 32'b0;
      trace_read_index_axi <= 6'b0;
      snapshot_read_index_axi <= 6'b0;
      ram_read_wait_axi <= 2'b0;
      ram_read_high_axi <= 1'b0;
      ram_read_inflight_axi <= 1'b0;
      ram_read_addr_axi <= 7'b0;
    end else begin
      if (abort_outstanding_axi &&
          abort_ack_sync2_axi == abort_epoch_toggle_axi)
        abort_outstanding_axi <= 1'b0;
      if (axi_recovery_pending) begin
        // The request and outstanding flag intentionally retain their values
        // through axi_aresetn.  Repeated reset/release cycles cannot cancel an
        // abort while source_clk is stopped; a new request launches only after
        // the previous source echo is visible.
        if (!abort_outstanding_axi ||
            abort_ack_sync2_axi == abort_epoch_toggle_axi) begin
          abort_epoch_toggle_axi <= ~abort_epoch_toggle_axi;
          abort_outstanding_axi <= 1'b1;
          axi_recovery_pending <= 1'b0;
        end
        ack_done_seen_axi <= ack_done_sync3_axi;
      end
      if (mmio_rsp_valid && mmio_rsp_ready) begin
        mmio_rsp_valid <= 1'b0;
        ram_read_inflight_axi <= 1'b0;
      end
      if (ram_read_wait_axi != 0)
        ram_read_wait_axi <= ram_read_wait_axi - 1'b1;
      if (ram_read_wait_axi == 1) begin
        // Revalidate the frozen publication window when synchronous BRAM
        // data returns, not only when the request was accepted.
        mmio_rsp_rdata <= public_done_axi && public_valid_axi &&
                          !route_error_pulse ?
                          (ram_read_high_axi ? ram_read_data_axi[63:32] :
                                                ram_read_data_axi[31:0]) :
                          32'b0;
        mmio_rsp_valid <= 1'b1;
      end

      if (route_ready_pulse && awaiting_ack_axi && !public_done_axi) begin
        arm_toggle_axi <= ~arm_toggle_axi;
        done_seen_axi <= done_sync3_axi;
        completion_armed_axi <= 1'b1;
        measurement_started_axi <= 1'b1;
        measurement_counter_axi <= 32'b0;
        response_counter_axi <= 32'b0;
      end

      if (measurement_started_axi && !freeze_issued_axi &&
          !public_done_axi &&
          !(completion_armed_axi && done_sync3_axi != done_seen_axi)) begin
        // A valid host MANUAL request on this edge has priority over the
        // automatic window.  This prevents both encoded toggles launching on
        // one edge at the exact window boundary.
        if (mmio_req_valid && mmio_req_ready && mmio_req_write &&
            mmio_req_be == 4'hf && mmio_req_addr == 17'h03c0c &&
            mmio_req_wdata[2]) begin
          measurement_counter_axi <= measurement_counter_axi;
        end else if (measurement_counter_axi + 1'b1 >=
            window_cycles(arm_window_hold_axi)) begin
          freeze_toggle_axi <= ~freeze_toggle_axi;
          freeze_issued_axi <= 1'b1;
          response_counter_axi <= 32'b0;
        end else
          measurement_counter_axi <= measurement_counter_axi + 1'b1;
      end

      if (freeze_issued_axi && completion_armed_axi && !public_done_axi &&
          done_sync3_axi == done_seen_axi) begin
        if (response_counter_axi + 1'b1 >= RESPONSE_TIMEOUT_CYCLES) begin
          public_done_axi <= 1'b1;
          public_valid_axi <= 1'b0;
          stopped_clock_timeout_axi <= 1'b1;
          completion_armed_axi <= 1'b0;
          measurement_started_axi <= 1'b0;
          freeze_issued_axi <= 1'b0;
          response_counter_axi <= 32'b0;
        end else
          response_counter_axi <= response_counter_axi + 1'b1;
      end

      if (completion_armed_axi && done_sync3_axi != done_seen_axi) begin
        done_seen_axi <= done_sync3_axi;
        completion_armed_axi <= 1'b0;
        measurement_started_axi <= 1'b0;
        freeze_issued_axi <= 1'b0;
        response_counter_axi <= 32'b0;
        public_done_axi <= 1'b1;
        public_valid_axi <= valid_sync2_axi && !stopped_clock_timeout_axi;
      end

      if (route_error_pulse && awaiting_ack_axi && !ack_pending_axi) begin
        // Loss of route/quiescence invalidates the entire source session,
        // including an already-published HOST READ window before ACK.  The
        // abort epoch discards active/frozen ownership and RAM visibility is
        // closed by public_valid=0.
        if (!abort_outstanding_axi ||
            abort_ack_sync2_axi == abort_epoch_toggle_axi) begin
          abort_epoch_toggle_axi <= ~abort_epoch_toggle_axi;
          abort_outstanding_axi <= 1'b1;
        end
        public_done_axi <= 1'b1;
        public_valid_axi <= 1'b0;
        completion_armed_axi <= 1'b0;
        measurement_started_axi <= 1'b0;
        freeze_issued_axi <= 1'b0;
        if (ram_read_inflight_axi) begin
          // Complete an already accepted read with zero.  Suppressing the
          // response would strand the MMIO bridge; returning prior evidence
          // after VALID revocation would violate the frozen-read contract.
          ram_read_wait_axi <= 2'b0;
          ram_read_enable_axi <= 1'b0;
          mmio_rsp_rdata <= 32'b0;
          mmio_rsp_valid <= 1'b1;
        end
      end

      if (ack_pending_axi && ack_done_sync3_axi != ack_done_seen_axi) begin
        ack_done_seen_axi <= ack_done_sync3_axi;
        source_ack_complete_axi <= 1'b1;
      end
      if (ack_pending_axi && source_ack_complete_axi && route_restored &&
          !route_busy) begin
        ack_pending_axi <= 1'b0;
        source_ack_complete_axi <= 1'b0;
        awaiting_ack_axi <= 1'b0;
        public_done_axi <= 1'b0;
        public_valid_axi <= 1'b0;
        stopped_clock_timeout_axi <= 1'b0;
      end

      if (mmio_req_valid && mmio_req_ready) begin
        if (mmio_req_write) begin
          if (!control_ok) begin
            if (protocol_error_count_axi != 32'hffff_ffff)
              protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
          end else begin
            case (mmio_req_addr)
              17'h03c0c: begin
                if (mmio_req_wdata[0]) begin // CLEAR
                  if (!awaiting_ack_axi && !route_busy && route_restored &&
                      !axi_recovery_pending && !abort_outstanding_axi) begin
                    clear_toggle_axi <= ~clear_toggle_axi;
                    public_done_axi <= 1'b0;
                    public_valid_axi <= 1'b0;
                    ram_read_wait_axi <= 2'b0;
                    ram_read_enable_axi <= 1'b0;
                    stopped_clock_timeout_axi <= 1'b0;
                    measurement_started_axi <= 1'b0;
                    freeze_issued_axi <= 1'b0;
                  end else if (protocol_error_count_axi != 32'hffff_ffff)
                    protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
                end
                if (mmio_req_wdata[1]) begin // ARM, route first
                  if (!awaiting_ack_axi && !route_busy && route_restored &&
                      !axi_recovery_pending && !abort_outstanding_axi &&
                      configured_channel_axi >= 3'd1 &&
                      configured_channel_axi <= 3'd4 &&
                      configured_window_axi <= 2'd2) begin
                    active_session_axi <= next_session_axi;
                    arm_session_hold_axi <= next_session_axi;
                    arm_route_hold_axi <= configured_channel_axi;
                    arm_window_hold_axi <= configured_window_axi;
                    next_session_axi <= next_session_axi + 1'b1;
                    awaiting_ack_axi <= 1'b1;
                    public_done_axi <= 1'b0;
                    public_valid_axi <= 1'b0;
                    stopped_clock_timeout_axi <= 1'b0;
                    measurement_started_axi <= 1'b0;
                    freeze_issued_axi <= 1'b0;
                    completion_armed_axi <= 1'b0;
                    route_start_pulse <= 1'b1;
                  end else if (arm_rejected_count_axi != 32'hffff_ffff)
                    arm_rejected_count_axi <= arm_rejected_count_axi + 1'b1;
                end
                if (mmio_req_wdata[2] && measurement_started_axi &&
                    !freeze_issued_axi && !public_done_axi &&
                    !(completion_armed_axi &&
                      done_sync3_axi != done_seen_axi)) begin
                  // bounded early FREEZE
                  // A distinct synchronized toggle encodes MANUAL; no
                  // independently synchronized data bit can race the token.
                  freeze_manual_toggle_axi <= ~freeze_manual_toggle_axi;
                  freeze_issued_axi <= 1'b1;
                  response_counter_axi <= 32'b0;
                end
                if (mmio_req_wdata[3]) begin // ACK
                  if (awaiting_ack_axi && public_done_axi &&
                      !ack_pending_axi) begin
                    ack_toggle_axi <= ~ack_toggle_axi;
                    route_restore_pulse <= 1'b1;
                    ack_pending_axi <= 1'b1;
                    source_ack_complete_axi <= 1'b0;
                    ack_done_seen_axi <= ack_done_sync3_axi;
                    measurement_started_axi <= 1'b0;
                    freeze_issued_axi <= 1'b0;
                    completion_armed_axi <= 1'b0;
                    // First ACK closes the host read window immediately.
                    // The session remains internally owned until both the
                    // source ACK echo and exact route restore complete.
                    public_done_axi <= 1'b0;
                    public_valid_axi <= 1'b0;
                    if (ram_read_inflight_axi) begin
                      ram_read_wait_axi <= 2'b0;
                      ram_read_enable_axi <= 1'b0;
                      mmio_rsp_rdata <= 32'b0;
                      mmio_rsp_valid <= 1'b1;
                    end
                  end else if (protocol_error_count_axi != 32'hffff_ffff)
                    protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
                end
              end
              17'h03c18: begin
                if (!awaiting_ack_axi && !route_busy && route_restored &&
                    !axi_recovery_pending && !abort_outstanding_axi &&
                    mmio_req_wdata[2:0] >= 3'd1 &&
                    mmio_req_wdata[2:0] <= 3'd4 &&
                    mmio_req_wdata[9:8] <= 2'd2) begin
                  configured_channel_axi <= mmio_req_wdata[2:0];
                  configured_window_axi <= mmio_req_wdata[9:8];
                end else if (protocol_error_count_axi != 32'hffff_ffff)
                  protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
              end
              17'h03c30: begin
                if (public_done_axi && public_valid_axi &&
                    mmio_req_wdata < TRACE_ENTRIES)
                  trace_read_index_axi <= mmio_req_wdata[5:0];
                else if (protocol_error_count_axi != 32'hffff_ffff)
                  protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
              end
              17'h03c3c: begin
                if (public_done_axi && public_valid_axi &&
                    mmio_req_wdata < META_ENTRIES)
                  snapshot_read_index_axi <= mmio_req_wdata[5:0];
                else if (protocol_error_count_axi != 32'hffff_ffff)
                  protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
              end
              default: begin
                if (protocol_error_count_axi != 32'hffff_ffff)
                  protocol_error_count_axi <= protocol_error_count_axi + 1'b1;
              end
            endcase
          end
        end else if (ram_data_read) begin
          if (public_done_axi && public_valid_axi && !route_error_pulse) begin
            ram_read_addr_axi <= (mmio_req_addr == 17'h03c34 ||
                                  mmio_req_addr == 17'h03c38) ?
                                 {1'b0, trace_read_index_axi} :
                                 META_BASE + snapshot_read_index_axi;
            ram_read_high_axi <= mmio_req_addr == 17'h03c38 ||
                                 mmio_req_addr == 17'h03c44;
            ram_read_enable_axi <= 1'b1;
            ram_read_wait_axi <= 2;
            ram_read_inflight_axi <= 1'b1;
          end else begin
            mmio_rsp_rdata <= 32'b0;
            mmio_rsp_valid <= 1'b1;
            ram_read_inflight_axi <= 1'b0;
          end
        end else begin
          status_word = 32'b0;
          status_word[0] = route_busy;
          status_word[1] = armed_sync2_axi;
          status_word[2] = measurement_started_axi;
          status_word[3] = freeze_issued_axi;
          status_word[4] = public_done_axi;
          status_word[5] = public_valid_axi;
          status_word[6] = awaiting_ack_axi;
          status_word[7] = stopped_clock_timeout_axi;
          status_word[8] = route_error;
          status_word[9] = route_restored;
          status_word[10] = overflow_sync2_axi;
          status_word[11] = ack_pending_axi;
          status_word[12] = abort_outstanding_axi;
          case (mmio_req_addr)
            17'h03c00: mmio_rsp_rdata <= RM1_MAGIC;
            17'h03c04: mmio_rsp_rdata <= RM1_VERSION;
            17'h03c08: mmio_rsp_rdata <= RM1_CAPABILITIES;
            17'h03c0c: mmio_rsp_rdata <= 32'b0;
            17'h03c10: mmio_rsp_rdata <= status_word;
            17'h03c14: mmio_rsp_rdata <= BUILD_FLAGS;
            17'h03c18: mmio_rsp_rdata <=
                {22'b0, configured_window_axi, 5'b0, configured_channel_axi};
            17'h03c1c: mmio_rsp_rdata <= {16'b0, active_session_axi};
            17'h03c20: mmio_rsp_rdata <= window_ms(arm_window_hold_axi);
            17'h03c24: mmio_rsp_rdata <=
                {8'b0, route_original, route_readback, 5'b0,
                 arm_route_hold_axi};
            17'h03c28: mmio_rsp_rdata <= {16'b0, route_error_code};
            17'h03c2c: mmio_rsp_rdata <= arm_rejected_count_axi;
            17'h03c30: mmio_rsp_rdata <= {26'b0, trace_read_index_axi};
            17'h03c3c: mmio_rsp_rdata <= {26'b0, snapshot_read_index_axi};
            17'h03c48: mmio_rsp_rdata <= protocol_error_count_axi;
            17'h03c4c: mmio_rsp_rdata <= STOP_AXI_TIMEOUT;
            17'h03c50: mmio_rsp_rdata <= STOP_ROUTE_ERROR;
            default: mmio_rsp_rdata <= 32'b0;
          endcase
          mmio_rsp_valid <= 1'b1;
        end
      end
    end
  end
endmodule
