`timescale 1ns/1ps

// G2B_BT656_TRACE_ENTRY_V1 event-only frame-boundary trace.
//
// The source-side write path is observational and has no backpressure output.
// The AXI side can only control this diagnostic island and read frozen data.
// No camera payload is accepted or stored by this module.
module g2b_bt656_boundary_trace (
  input  logic         source_clk,
  input  logic         source_reset,
  input  logic         event_valid,
  input  logic         trigger_pulse,
  input  logic         next_frame_line1_commit,
  input  logic [511:0] event_payload,

  input  logic         axi_clk,
  input  logic         axi_aresetn,
  input  logic         mmio_req_valid,
  output logic         mmio_req_ready,
  input  logic         mmio_req_write,
  input  logic [16:0]  mmio_req_addr,
  input  logic [31:0]  mmio_req_wdata,
  input  logic [3:0]   mmio_req_be,
  output logic         mmio_rsp_valid,
  input  logic         mmio_rsp_ready,
  output logic [31:0]  mmio_rsp_rdata
);
  localparam logic [31:0] TRACE_MAGIC = 32'h4254_3635;
  localparam logic [31:0] TRACE_VERSION = 32'h0001_0000;
  localparam logic [31:0] TRACE_CAPABILITIES = 32'h0001_0120;
  localparam integer PRETRIGGER_EVENTS = 32;
  localparam integer POSTTRIGGER_EVENTS = 256;
  localparam integer MAX_LOGICAL_ENTRIES = 288;
  localparam integer PHYSICAL_ENTRIES = 512;
  localparam integer SOURCE_TIMEOUT_CLOCKS = 300000;

  localparam logic [31:0] STOP_NONE = 32'd0;
  localparam logic [31:0] STOP_NEXT_FRAME_LINE1 = 32'd1;
  localparam logic [31:0] STOP_EVENT_LIMIT = 32'd2;
  localparam logic [31:0] STOP_CLOCK_TIMEOUT = 32'd3;
  localparam logic [31:0] STOP_ABORTED = 32'd4;

  logic clear_toggle_axi = 1'b0;
  logic arm_toggle_axi = 1'b0;
  logic abort_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic clear_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic clear_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic arm_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic arm_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic abort_sync2_source = 1'b0;
  logic clear_seen_source = 1'b0;
  logic arm_seen_source = 1'b0;
  logic abort_seen_source = 1'b0;

  logic armed_source = 1'b0;
  logic triggered_source = 1'b0;
  logic done_source = 1'b0;
  logic trace_overflow_source = 1'b0;
  logic [5:0] pre_count_source = '0;
  logic [4:0] pre_write_ptr_source = '0;
  logic [4:0] pre_start_source = '0;
  logic [8:0] post_count_source = '0;
  logic [8:0] valid_entries_source = '0;
  logic [8:0] trigger_logical_index_source = '0;
  logic [31:0] stop_reason_source = STOP_NONE;
  logic [31:0] trigger_frame_source = '0;
  logic [31:0] trigger_line_source = '0;
  logic [63:0] clocks_since_trigger_source = '0;
  logic [31:0] event_sequence_source = '0;
  logic [31:0] clocks_since_event_source = '0;
  logic have_logged_source = 1'b0;

  logic ram_we_source = 1'b0;
  logic [8:0] ram_write_addr_source = '0;
  logic [511:0] ram_write_data_source = '0;
  logic ram_read_enable_axi = 1'b0;
  logic [8:0] ram_read_addr_axi = '0;
  logic [511:0] ram_read_data_axi;

  function automatic [511:0] compose_entry(
    input [511:0] payload,
    input [31:0] sequence_value,
    input [31:0] delta_value,
    input logic stop_line1,
    input logic stop_event_limit,
    input logic stop_clock_timeout);
    logic [511:0] result;
    begin
      result = payload;
      result[0*32 +: 32] = sequence_value;
      result[1*32 +: 32] = delta_value;
      result[3*32 + 22] = stop_line1;
      result[3*32 + 23] = stop_event_limit;
      result[3*32 + 24] = stop_clock_timeout;
      result[3*32 + 31] = 1'b0;
      result[15*32 + 31 -: 3] = 3'b000;
      compose_entry = result;
    end
  endfunction

  xpm_memory_sdpram #(
    .ADDR_WIDTH_A(9), .ADDR_WIDTH_B(9),
    .AUTO_SLEEP_TIME(0), .BYTE_WRITE_WIDTH_A(512),
    .CLOCKING_MODE("independent_clock"), .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"), .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"), .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(PHYSICAL_ENTRIES * 512), .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_B(512), .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("0"), .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(1), .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(0), .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(512), .WRITE_MODE_B("read_first")
  ) TRACE_RAM (
    .clka(source_clk), .ena(ram_we_source), .wea(ram_we_source),
    .addra(ram_write_addr_source), .dina(ram_write_data_source),
    .clkb(axi_clk), .enb(ram_read_enable_axi), .addrb(ram_read_addr_axi),
    .doutb(ram_read_data_axi), .rstb(~axi_aresetn), .regceb(1'b1),
    .sleep(1'b0), .injectsbiterra(1'b0), .injectdbiterra(1'b0),
    .sbiterrb(), .dbiterrb()
  );

  always_ff @(posedge source_clk) begin : TRACE_SOURCE_DOMAIN
    logic clear_command;
    logic arm_command;
    logic abort_command;
    logic timeout_due;
    logic stop_line1_now;
    logic stop_event_limit_now;
    logic stop_clock_timeout_now;
    logic log_now;
    logic [31:0] delta_value;

    clear_sync1_source <= clear_toggle_axi;
    clear_sync2_source <= clear_sync1_source;
    arm_sync1_source <= arm_toggle_axi;
    arm_sync2_source <= arm_sync1_source;
    abort_sync1_source <= abort_toggle_axi;
    abort_sync2_source <= abort_sync1_source;

    clear_command = clear_sync2_source != clear_seen_source;
    arm_command = arm_sync2_source != arm_seen_source;
    abort_command = abort_sync2_source != abort_seen_source;
    ram_we_source <= 1'b0;

    if (source_reset) begin
      clear_seen_source <= clear_sync2_source;
      arm_seen_source <= arm_sync2_source;
      abort_seen_source <= abort_sync2_source;
      armed_source <= 1'b0;
      triggered_source <= 1'b0;
      done_source <= 1'b0;
      trace_overflow_source <= 1'b0;
      pre_count_source <= '0;
      pre_write_ptr_source <= '0;
      pre_start_source <= '0;
      post_count_source <= '0;
      valid_entries_source <= '0;
      trigger_logical_index_source <= '0;
      stop_reason_source <= STOP_NONE;
      trigger_frame_source <= '0;
      trigger_line_source <= '0;
      clocks_since_trigger_source <= '0;
      event_sequence_source <= '0;
      clocks_since_event_source <= '0;
      have_logged_source <= 1'b0;
    end else if (clear_command) begin
      clear_seen_source <= clear_sync2_source;
      armed_source <= 1'b0;
      triggered_source <= 1'b0;
      done_source <= 1'b0;
      trace_overflow_source <= 1'b0;
      pre_count_source <= '0;
      pre_write_ptr_source <= '0;
      pre_start_source <= '0;
      post_count_source <= '0;
      valid_entries_source <= '0;
      trigger_logical_index_source <= '0;
      stop_reason_source <= STOP_NONE;
      trigger_frame_source <= '0;
      trigger_line_source <= '0;
      clocks_since_trigger_source <= '0;
      event_sequence_source <= '0;
      clocks_since_event_source <= '0;
      have_logged_source <= 1'b0;
    end else begin
      if (arm_command) begin
        arm_seen_source <= arm_sync2_source;
        armed_source <= 1'b1;
        triggered_source <= 1'b0;
        done_source <= 1'b0;
        trace_overflow_source <= 1'b0;
        pre_count_source <= '0;
        pre_write_ptr_source <= '0;
        pre_start_source <= '0;
        post_count_source <= '0;
        valid_entries_source <= '0;
        trigger_logical_index_source <= '0;
        stop_reason_source <= STOP_NONE;
        trigger_frame_source <= '0;
        trigger_line_source <= '0;
        clocks_since_trigger_source <= '0;
        event_sequence_source <= '0;
        clocks_since_event_source <= '0;
        have_logged_source <= 1'b0;
      end
      if (abort_command)
        abort_seen_source <= abort_sync2_source;

      if (armed_source && !done_source && !arm_command) begin
        if (have_logged_source && clocks_since_event_source != 32'hffff_ffff)
          clocks_since_event_source <= clocks_since_event_source + 1'b1;
        if (triggered_source && clocks_since_trigger_source != 64'hffff_ffff_ffff_ffff)
          clocks_since_trigger_source <= clocks_since_trigger_source + 1'b1;

        timeout_due = triggered_source &&
                      clocks_since_trigger_source >= SOURCE_TIMEOUT_CLOCKS-1;
        stop_line1_now = triggered_source && event_valid &&
                         next_frame_line1_commit &&
                         event_payload[4*32 +: 32] != trigger_frame_source;
        stop_event_limit_now = triggered_source && event_valid &&
                               post_count_source >= POSTTRIGGER_EVENTS-1;
        stop_clock_timeout_now = timeout_due;
        log_now = event_valid || timeout_due || abort_command;
        delta_value = have_logged_source ? clocks_since_event_source + 1'b1 :
                                           32'b0;

        if (log_now) begin
          ram_we_source <= 1'b1;
          ram_write_data_source <= compose_entry(
              event_payload, event_sequence_source, delta_value,
              stop_line1_now, stop_event_limit_now,
              stop_clock_timeout_now);
          event_sequence_source <= event_sequence_source + 1'b1;
          clocks_since_event_source <= 32'b0;
          have_logged_source <= 1'b1;

          if (abort_command) begin
            // ABORT_AND_FREEZE is valid both before and after trigger. The
            // terminating event is retained, then the memory becomes
            // immutable just like either bounded automatic stop.
            if (!triggered_source) begin
              ram_write_addr_source <= {4'b0, pre_write_ptr_source};
              if (pre_count_source < PRETRIGGER_EVENTS)
                pre_count_source <= pre_count_source + 1'b1;
              valid_entries_source <=
                  pre_count_source < PRETRIGGER_EVENTS ?
                      pre_count_source + 1'b1 : pre_count_source;
            end else if (post_count_source < POSTTRIGGER_EVENTS) begin
              ram_write_addr_source <= 9'd32 + post_count_source;
              post_count_source <= post_count_source + 1'b1;
              valid_entries_source <= pre_count_source +
                                      post_count_source + 1'b1;
            end else begin
              ram_we_source <= 1'b0;
            end
            done_source <= 1'b1;
            armed_source <= 1'b0;
            stop_reason_source <= STOP_ABORTED;
          end else if (!triggered_source && trigger_pulse && event_valid) begin
            ram_write_addr_source <= 9'd32;
            triggered_source <= 1'b1;
            pre_start_source <=
                pre_count_source == PRETRIGGER_EVENTS ?
                    pre_write_ptr_source : 5'b0;
            post_count_source <= 9'd1;
            valid_entries_source <= pre_count_source + 1'b1;
            trigger_logical_index_source <= pre_count_source;
            trigger_frame_source <= event_payload[4*32 +: 32];
            trigger_line_source <= event_payload[5*32 +: 32];
            clocks_since_trigger_source <= 64'b0;
          end else if (!triggered_source) begin
            ram_write_addr_source <= {4'b0, pre_write_ptr_source};
            if (pre_count_source < PRETRIGGER_EVENTS)
              pre_count_source <= pre_count_source + 1'b1;
            if (pre_write_ptr_source == PRETRIGGER_EVENTS-1)
              pre_write_ptr_source <= 5'b0;
            else
              pre_write_ptr_source <= pre_write_ptr_source + 1'b1;
            valid_entries_source <=
                pre_count_source < PRETRIGGER_EVENTS ?
                    pre_count_source + 1'b1 : pre_count_source;
          end else begin
            if (post_count_source < POSTTRIGGER_EVENTS) begin
              ram_write_addr_source <= 9'd32 + post_count_source;
              post_count_source <= post_count_source + 1'b1;
              valid_entries_source <= pre_count_source +
                                      post_count_source + 1'b1;
            end else begin
              ram_we_source <= 1'b0;
              trace_overflow_source <= 1'b1;
              done_source <= 1'b1;
              armed_source <= 1'b0;
              stop_reason_source <= STOP_EVENT_LIMIT;
            end

            if (stop_line1_now) begin
              done_source <= 1'b1;
              armed_source <= 1'b0;
              stop_reason_source <= STOP_NEXT_FRAME_LINE1;
            end else if (stop_event_limit_now) begin
              done_source <= 1'b1;
              armed_source <= 1'b0;
              stop_reason_source <= STOP_EVENT_LIMIT;
            end else if (stop_clock_timeout_now) begin
              done_source <= 1'b1;
              armed_source <= 1'b0;
              stop_reason_source <= STOP_CLOCK_TIMEOUT;
            end
          end
        end
      end
    end
  end

  (* ASYNC_REG = "TRUE" *) logic armed_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic armed_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic triggered_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic triggered_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync3_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync2_axi = 1'b0;

  // These buses are a frozen-data mailbox. DONE uses one additional
  // synchronizer stage, so software cannot observe DONE before the two-stage
  // bitwise metadata samplers have settled. The dedicated XDC also bounds
  // their first-stage datapaths and bus skew.
  (* ASYNC_REG = "TRUE" *) logic [8:0] valid_entries_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [8:0] valid_entries_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [5:0] pre_count_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [5:0] pre_count_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [4:0] pre_start_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [4:0] pre_start_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [8:0] post_count_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [8:0] post_count_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [8:0] trigger_index_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [8:0] trigger_index_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] stop_reason_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] stop_reason_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] trigger_frame_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] trigger_frame_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] trigger_line_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] trigger_line_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [63:0] trigger_clocks_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [63:0] trigger_clocks_sync2_axi = '0;

  logic [8:0] read_logical_index_axi = '0;
  logic read_issue_delay_axi = 1'b0;
  logic read_data_valid_axi = 1'b0;

  function automatic [8:0] logical_to_physical(
    input [8:0] logical_index,
    input [5:0] pre_count,
    input [4:0] pre_start);
    logic [5:0] pre_offset;
    begin
      if (logical_index < pre_count) begin
        if (pre_count < PRETRIGGER_EVENTS)
          logical_to_physical = logical_index;
        else begin
          pre_offset = pre_start + logical_index[4:0];
          logical_to_physical = {4'b0, pre_offset[4:0]};
        end
      end else begin
        logical_to_physical = 9'd32 + logical_index - pre_count;
      end
    end
  endfunction

  function automatic [31:0] read_data_word(input [3:0] word_index);
    begin
      if (read_logical_index_axi == 0 && word_index == 1)
        read_data_word = 32'b0;
      else
        read_data_word = ram_read_data_axi[word_index*32 +: 32];
    end
  endfunction

  always_comb begin
    mmio_req_ready = !mmio_rsp_valid;
  end

  always_ff @(posedge axi_clk) begin : TRACE_AXI_DOMAIN
    integer read_word_index;
    logic [31:0] status_word;

    armed_sync1_axi <= armed_source;
    armed_sync2_axi <= armed_sync1_axi;
    triggered_sync1_axi <= triggered_source;
    triggered_sync2_axi <= triggered_sync1_axi;
    done_sync1_axi <= done_source;
    done_sync2_axi <= done_sync1_axi;
    done_sync3_axi <= done_sync2_axi;
    overflow_sync1_axi <= trace_overflow_source;
    overflow_sync2_axi <= overflow_sync1_axi;
    valid_entries_sync1_axi <= valid_entries_source;
    valid_entries_sync2_axi <= valid_entries_sync1_axi;
    pre_count_sync1_axi <= pre_count_source;
    pre_count_sync2_axi <= pre_count_sync1_axi;
    pre_start_sync1_axi <= pre_start_source;
    pre_start_sync2_axi <= pre_start_sync1_axi;
    post_count_sync1_axi <= post_count_source;
    post_count_sync2_axi <= post_count_sync1_axi;
    trigger_index_sync1_axi <= trigger_logical_index_source;
    trigger_index_sync2_axi <= trigger_index_sync1_axi;
    stop_reason_sync1_axi <= stop_reason_source;
    stop_reason_sync2_axi <= stop_reason_sync1_axi;
    trigger_frame_sync1_axi <= trigger_frame_source;
    trigger_frame_sync2_axi <= trigger_frame_sync1_axi;
    trigger_line_sync1_axi <= trigger_line_source;
    trigger_line_sync2_axi <= trigger_line_sync1_axi;
    trigger_clocks_sync1_axi <= clocks_since_trigger_source;
    trigger_clocks_sync2_axi <= trigger_clocks_sync1_axi;

    ram_read_enable_axi <= 1'b0;
    read_issue_delay_axi <= ram_read_enable_axi;
    if (ram_read_enable_axi)
      read_data_valid_axi <= 1'b0;
    if (read_issue_delay_axi)
      read_data_valid_axi <= 1'b1;

    if (!axi_aresetn) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      clear_toggle_axi <= 1'b0;
      arm_toggle_axi <= 1'b0;
      abort_toggle_axi <= 1'b0;
      read_logical_index_axi <= '0;
      ram_read_addr_axi <= '0;
      read_data_valid_axi <= 1'b0;
      read_issue_delay_axi <= 1'b0;
    end else begin
      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;

      if (mmio_req_valid && mmio_req_ready) begin
        if (mmio_req_write) begin
          if (mmio_req_addr == 17'h03c0c && mmio_req_be[0]) begin
            if (mmio_req_wdata[0])
              clear_toggle_axi <= ~clear_toggle_axi;
            if (mmio_req_wdata[1])
              arm_toggle_axi <= ~arm_toggle_axi;
            if (mmio_req_wdata[2])
              abort_toggle_axi <= ~abort_toggle_axi;
          end else if (mmio_req_addr == 17'h03c38 &&
                       mmio_req_addr[1:0] == 2'b00 &&
                       done_sync3_axi &&
                       mmio_req_wdata < valid_entries_sync2_axi) begin
            read_logical_index_axi <= mmio_req_wdata[8:0];
            ram_read_addr_axi <= logical_to_physical(
                mmio_req_wdata[8:0], pre_count_sync2_axi,
                pre_start_sync2_axi);
            ram_read_enable_axi <= 1'b1;
            read_data_valid_axi <= 1'b0;
          end
        end else begin
          status_word = 32'b0;
          status_word[0] = armed_sync2_axi;
          status_word[1] = triggered_sync2_axi;
          status_word[2] = done_sync3_axi;
          status_word[3] = overflow_sync2_axi;
          status_word[4] = stop_reason_sync2_axi == STOP_NEXT_FRAME_LINE1;
          status_word[5] = stop_reason_sync2_axi == STOP_EVENT_LIMIT;
          status_word[6] = stop_reason_sync2_axi == STOP_CLOCK_TIMEOUT;
          status_word[7] = read_data_valid_axi;
          case (mmio_req_addr)
            17'h03c00: mmio_rsp_rdata <= TRACE_MAGIC;
            17'h03c04: mmio_rsp_rdata <= TRACE_VERSION;
            17'h03c08: mmio_rsp_rdata <= TRACE_CAPABILITIES;
            17'h03c0c: mmio_rsp_rdata <= 32'b0;
            17'h03c10: mmio_rsp_rdata <= status_word;
            17'h03c14: mmio_rsp_rdata <= {23'b0, valid_entries_sync2_axi};
            17'h03c18: mmio_rsp_rdata <= {26'b0, pre_count_sync2_axi};
            17'h03c1c: mmio_rsp_rdata <= {23'b0, post_count_sync2_axi};
            17'h03c20: mmio_rsp_rdata <= {23'b0, trigger_index_sync2_axi};
            17'h03c24: mmio_rsp_rdata <= stop_reason_sync2_axi;
            17'h03c28: mmio_rsp_rdata <= trigger_frame_sync2_axi;
            17'h03c2c: mmio_rsp_rdata <= trigger_line_sync2_axi;
            17'h03c30: mmio_rsp_rdata <= trigger_clocks_sync2_axi[31:0];
            17'h03c34: mmio_rsp_rdata <= trigger_clocks_sync2_axi[63:32];
            17'h03c38: mmio_rsp_rdata <= {23'b0, read_logical_index_axi};
            17'h03c3c: mmio_rsp_rdata <=
                {22'b0, read_logical_index_axi, read_data_valid_axi};
            default: begin
              mmio_rsp_rdata <= 32'b0;
              for (read_word_index = 0; read_word_index < 16;
                   read_word_index = read_word_index + 1)
                if (mmio_req_addr == 17'h03c40 + read_word_index*4)
                  mmio_rsp_rdata <= read_data_word(read_word_index[3:0]);
            end
          endcase
          mmio_rsp_valid <= 1'b1;
        end
      end
    end
  end
endmodule
