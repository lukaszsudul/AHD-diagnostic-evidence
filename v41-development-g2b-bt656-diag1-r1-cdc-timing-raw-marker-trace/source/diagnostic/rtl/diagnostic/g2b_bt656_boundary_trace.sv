`timescale 1ns/1ps

// G2B_BT656_TRACE_ENTRY_V1 event-only frame-boundary trace.
// Source events and write controls are source-clock local. The dual-clock RAM
// is the only wide-data CDC mechanism. Frozen metadata is stored in entry 511
// before a single-bit completion-generation toggle crosses to AXI.
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
  localparam logic [31:0] TRACE_META_MAGIC = 32'h4d45_5431;
  localparam integer PRETRIGGER_EVENTS = 32;
  localparam integer POSTTRIGGER_EVENTS = 256;
  localparam integer PHYSICAL_ENTRIES = 512;
  localparam integer TRACE_META_ADDRESS = 511;
  localparam integer SOURCE_TIMEOUT_CLOCKS = 300000;

  localparam logic [31:0] STOP_NONE = 32'd0;
  localparam logic [31:0] STOP_NEXT_FRAME_LINE1 = 32'd1;
  localparam logic [31:0] STOP_EVENT_LIMIT = 32'd2;
  localparam logic [31:0] STOP_CLOCK_TIMEOUT = 32'd3;
  localparam logic [31:0] STOP_ABORTED = 32'd4;

  typedef enum logic [2:0] {
    TRACE_RUN,
    TRACE_META_DRIVE,
    TRACE_META_WAIT,
    TRACE_DONE_PUBLISH,
    TRACE_FROZEN
  } trace_freeze_state_t;

  localparam logic [1:0] RAM_READ_NONE = 2'd0;
  localparam logic [1:0] RAM_READ_EVENT = 2'd1;
  localparam logic [1:0] RAM_READ_META = 2'd2;

  // AXI-to-source commands: only first synchronizer stages consume AXI nets.
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
  logic done_generation_source = 1'b0;
  logic [31:0] trace_generation_source = '0;
  trace_freeze_state_t freeze_state_source = TRACE_RUN;
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

  function automatic [511:0] compose_metadata(
    input [31:0] generation_value,
    input [8:0] valid_entries_value,
    input [5:0] pre_count_value,
    input [8:0] post_count_value,
    input [4:0] pre_start_value,
    input [8:0] trigger_index_value,
    input [31:0] stop_reason_value,
    input [31:0] trigger_frame_value,
    input [31:0] trigger_line_value,
    input [63:0] trigger_clocks_value,
    input logic overflow_value,
    input [31:0] final_event_sequence_value,
    input trace_freeze_state_t source_state_value);
    logic [511:0] result;
    begin
      result = '0;
      result[0*32 +: 32] = TRACE_META_MAGIC;
      result[1*32 +: 32] = generation_value;
      result[2*32 +: 32] = {23'b0, valid_entries_value};
      result[3*32 +: 32] = {26'b0, pre_count_value};
      result[4*32 +: 32] = {23'b0, post_count_value};
      result[5*32 +: 32] = {27'b0, pre_start_value};
      result[6*32 +: 32] = {23'b0, trigger_index_value};
      result[7*32 +: 32] = stop_reason_value;
      result[8*32 +: 32] = trigger_frame_value;
      result[9*32 +: 32] = trigger_line_value;
      result[10*32 +: 32] = trigger_clocks_value[31:0];
      result[11*32 +: 32] = trigger_clocks_value[63:32];
      result[12*32 +: 32] = {31'b0, overflow_value};
      result[13*32 +: 32] = final_event_sequence_value;
      result[14*32 +: 32] = {29'b0, source_state_value};
      result[15*32 +: 32] = 32'b0;
      compose_metadata = result;
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
      done_generation_source <= 1'b0;
      trace_generation_source <= '0;
      freeze_state_source <= TRACE_RUN;
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
      trace_generation_source <= trace_generation_source + 1'b1;
      freeze_state_source <= TRACE_RUN;
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
    end else if (arm_command) begin
      arm_seen_source <= arm_sync2_source;
      armed_source <= 1'b1;
      triggered_source <= 1'b0;
      freeze_state_source <= TRACE_RUN;
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
      if (abort_command)
        abort_seen_source <= abort_sync2_source;

      case (freeze_state_source)
        TRACE_META_DRIVE: begin
          ram_we_source <= 1'b1;
          ram_write_addr_source <= TRACE_META_ADDRESS[8:0];
          ram_write_data_source <= compose_metadata(
              trace_generation_source, valid_entries_source,
              pre_count_source, post_count_source, pre_start_source,
              trigger_logical_index_source, stop_reason_source,
              trigger_frame_source, trigger_line_source,
              clocks_since_trigger_source, trace_overflow_source,
              event_sequence_source, TRACE_FROZEN);
          freeze_state_source <= TRACE_META_WAIT;
        end
        TRACE_META_WAIT: begin
          // RAM consumes the registered metadata controls on this edge.
          freeze_state_source <= TRACE_DONE_PUBLISH;
        end
        TRACE_DONE_PUBLISH: begin
          // One full source cycle separates metadata storage from publication.
          done_generation_source <= ~done_generation_source;
          freeze_state_source <= TRACE_FROZEN;
        end
        TRACE_FROZEN: begin
          // Trace and metadata stay immutable until the next CLEAR/ARM cycle.
        end
        default: begin
          if (armed_source) begin
            if (have_logged_source &&
                clocks_since_event_source != 32'hffff_ffff)
              clocks_since_event_source <= clocks_since_event_source + 1'b1;
            if (triggered_source &&
                clocks_since_trigger_source != 64'hffff_ffff_ffff_ffff)
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
            delta_value = have_logged_source ?
                              clocks_since_event_source + 1'b1 : 32'b0;

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
                armed_source <= 1'b0;
                stop_reason_source <= STOP_ABORTED;
                freeze_state_source <= TRACE_META_DRIVE;
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
                end

                if (stop_line1_now) begin
                  armed_source <= 1'b0;
                  stop_reason_source <= STOP_NEXT_FRAME_LINE1;
                  freeze_state_source <= TRACE_META_DRIVE;
                end else if (stop_event_limit_now) begin
                  armed_source <= 1'b0;
                  stop_reason_source <= STOP_EVENT_LIMIT;
                  freeze_state_source <= TRACE_META_DRIVE;
                end else if (stop_clock_timeout_now) begin
                  armed_source <= 1'b0;
                  stop_reason_source <= STOP_CLOCK_TIMEOUT;
                  freeze_state_source <= TRACE_META_DRIVE;
                end
              end
            end
          end
        end
      endcase
    end
  end

  // Source-to-AXI status crossings are single-bit only.
  (* ASYNC_REG = "TRUE" *) logic armed_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic armed_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic triggered_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic triggered_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic done_sync3_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync2_axi = 1'b0;

  logic completion_armed_axi = 1'b0;
  logic done_seen_axi = 1'b0;
  logic trace_meta_valid_axi = 1'b0;
  logic trace_done_axi = 1'b0;
  logic [31:0] trace_generation_axi = '0;
  logic [8:0] valid_entries_axi = '0;
  logic [5:0] pre_count_axi = '0;
  logic [8:0] post_count_axi = '0;
  logic [4:0] pre_start_axi = '0;
  logic [8:0] trigger_index_axi = '0;
  logic [31:0] stop_reason_axi = STOP_NONE;
  logic [31:0] trigger_frame_axi = '0;
  logic [31:0] trigger_line_axi = '0;
  logic [63:0] trigger_clocks_axi = '0;
  logic trace_overflow_axi = 1'b0;
  logic [31:0] final_event_sequence_axi = '0;

  logic [8:0] read_logical_index_axi = '0;
  logic read_data_valid_axi = 1'b0;
  logic [1:0] ram_read_kind_axi = RAM_READ_NONE;
  logic [1:0] ram_read_wait_axi = '0;

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
    mmio_req_ready = !mmio_rsp_valid &&
        !(mmio_req_valid && mmio_req_write &&
          mmio_req_addr == 17'h03c38 && ram_read_wait_axi != 0);
  end

  always_ff @(posedge axi_clk) begin : TRACE_AXI_DOMAIN
    integer read_word_index;
    logic [31:0] status_word;

    armed_sync1_axi <= armed_source;
    armed_sync2_axi <= armed_sync1_axi;
    triggered_sync1_axi <= triggered_source;
    triggered_sync2_axi <= triggered_sync1_axi;
    done_sync1_axi <= done_generation_source;
    done_sync2_axi <= done_sync1_axi;
    done_sync3_axi <= done_sync2_axi;
    overflow_sync1_axi <= trace_overflow_source;
    overflow_sync2_axi <= overflow_sync1_axi;

    ram_read_enable_axi <= 1'b0;
    if (ram_read_wait_axi != 0)
      ram_read_wait_axi <= ram_read_wait_axi - 1'b1;

    if (!axi_aresetn) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      clear_toggle_axi <= 1'b0;
      arm_toggle_axi <= 1'b0;
      abort_toggle_axi <= 1'b0;
      completion_armed_axi <= 1'b0;
      done_seen_axi <= 1'b0;
      trace_meta_valid_axi <= 1'b0;
      trace_done_axi <= 1'b0;
      trace_generation_axi <= '0;
      valid_entries_axi <= '0;
      pre_count_axi <= '0;
      post_count_axi <= '0;
      pre_start_axi <= '0;
      trigger_index_axi <= '0;
      stop_reason_axi <= STOP_NONE;
      trigger_frame_axi <= '0;
      trigger_line_axi <= '0;
      trigger_clocks_axi <= '0;
      trace_overflow_axi <= 1'b0;
      final_event_sequence_axi <= '0;
      read_logical_index_axi <= '0;
      ram_read_addr_axi <= '0;
      read_data_valid_axi <= 1'b0;
      ram_read_kind_axi <= RAM_READ_NONE;
      ram_read_wait_axi <= '0;
    end else begin
      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;

      // Absorb a stale done generation until source ARMED is observed.
      if (!completion_armed_axi) begin
        done_seen_axi <= done_sync3_axi;
        if (armed_sync2_axi)
          completion_armed_axi <= 1'b1;
      end

      if (completion_armed_axi && done_sync3_axi != done_seen_axi &&
          ram_read_wait_axi == 0) begin
        done_seen_axi <= done_sync3_axi;
        completion_armed_axi <= 1'b0;
        trace_meta_valid_axi <= 1'b0;
        trace_done_axi <= 1'b0;
        read_data_valid_axi <= 1'b0;
        ram_read_addr_axi <= TRACE_META_ADDRESS[8:0];
        ram_read_enable_axi <= 1'b1;
        ram_read_kind_axi <= RAM_READ_META;
        ram_read_wait_axi <= 2;
      end

      // READ_LATENCY_B is one; the extra wait cycle makes cache publication
      // unambiguously later than the BRAM read result.
      if (ram_read_wait_axi == 1) begin
        if (ram_read_kind_axi == RAM_READ_META) begin
          trace_generation_axi <= ram_read_data_axi[1*32 +: 32];
          valid_entries_axi <= ram_read_data_axi[2*32 +: 9];
          pre_count_axi <= ram_read_data_axi[3*32 +: 6];
          post_count_axi <= ram_read_data_axi[4*32 +: 9];
          pre_start_axi <= ram_read_data_axi[5*32 +: 5];
          trigger_index_axi <= ram_read_data_axi[6*32 +: 9];
          stop_reason_axi <= ram_read_data_axi[7*32 +: 32];
          trigger_frame_axi <= ram_read_data_axi[8*32 +: 32];
          trigger_line_axi <= ram_read_data_axi[9*32 +: 32];
          trigger_clocks_axi[31:0] <= ram_read_data_axi[10*32 +: 32];
          trigger_clocks_axi[63:32] <= ram_read_data_axi[11*32 +: 32];
          trace_overflow_axi <= ram_read_data_axi[12*32];
          final_event_sequence_axi <= ram_read_data_axi[13*32 +: 32];
          trace_meta_valid_axi <=
              ram_read_data_axi[0*32 +: 32] == TRACE_META_MAGIC;
          trace_done_axi <=
              ram_read_data_axi[0*32 +: 32] == TRACE_META_MAGIC;
        end else if (ram_read_kind_axi == RAM_READ_EVENT) begin
          read_data_valid_axi <= 1'b1;
        end
        ram_read_kind_axi <= RAM_READ_NONE;
      end

      if (mmio_req_valid && mmio_req_ready) begin
        if (mmio_req_write) begin
          if (mmio_req_addr == 17'h03c0c && mmio_req_be[0]) begin
            if (mmio_req_wdata[0]) begin
              clear_toggle_axi <= ~clear_toggle_axi;
              completion_armed_axi <= 1'b0;
              done_seen_axi <= done_sync3_axi;
              trace_meta_valid_axi <= 1'b0;
              trace_done_axi <= 1'b0;
              valid_entries_axi <= '0;
              pre_count_axi <= '0;
              post_count_axi <= '0;
              pre_start_axi <= '0;
              trigger_index_axi <= '0;
              stop_reason_axi <= STOP_NONE;
              trigger_frame_axi <= '0;
              trigger_line_axi <= '0;
              trigger_clocks_axi <= '0;
              trace_overflow_axi <= 1'b0;
              read_data_valid_axi <= 1'b0;
            end
            if (mmio_req_wdata[1]) begin
              arm_toggle_axi <= ~arm_toggle_axi;
              completion_armed_axi <= 1'b0;
              done_seen_axi <= done_sync3_axi;
              trace_meta_valid_axi <= 1'b0;
              trace_done_axi <= 1'b0;
              read_data_valid_axi <= 1'b0;
            end
            if (mmio_req_wdata[2])
              abort_toggle_axi <= ~abort_toggle_axi;
          end else if (mmio_req_addr == 17'h03c38 &&
                       mmio_req_addr[1:0] == 2'b00 &&
                       trace_done_axi && trace_meta_valid_axi &&
                       mmio_req_wdata < valid_entries_axi &&
                       ram_read_wait_axi == 0) begin
            read_logical_index_axi <= mmio_req_wdata[8:0];
            ram_read_addr_axi <= logical_to_physical(
                mmio_req_wdata[8:0], pre_count_axi, pre_start_axi);
            ram_read_enable_axi <= 1'b1;
            ram_read_kind_axi <= RAM_READ_EVENT;
            ram_read_wait_axi <= 2;
            read_data_valid_axi <= 1'b0;
          end
        end else begin
          status_word = 32'b0;
          status_word[0] = armed_sync2_axi;
          status_word[1] = triggered_sync2_axi;
          status_word[2] = trace_done_axi && trace_meta_valid_axi;
          status_word[3] = trace_done_axi ? trace_overflow_axi :
                                                   overflow_sync2_axi;
          status_word[4] = trace_done_axi &&
                           stop_reason_axi == STOP_NEXT_FRAME_LINE1;
          status_word[5] = trace_done_axi &&
                           stop_reason_axi == STOP_EVENT_LIMIT;
          status_word[6] = trace_done_axi &&
                           stop_reason_axi == STOP_CLOCK_TIMEOUT;
          status_word[7] = read_data_valid_axi;
          case (mmio_req_addr)
            17'h03c00: mmio_rsp_rdata <= TRACE_MAGIC;
            17'h03c04: mmio_rsp_rdata <= TRACE_VERSION;
            17'h03c08: mmio_rsp_rdata <= TRACE_CAPABILITIES;
            17'h03c0c: mmio_rsp_rdata <= 32'b0;
            17'h03c10: mmio_rsp_rdata <= status_word;
            17'h03c14: mmio_rsp_rdata <= {23'b0, valid_entries_axi};
            17'h03c18: mmio_rsp_rdata <= {26'b0, pre_count_axi};
            17'h03c1c: mmio_rsp_rdata <= {23'b0, post_count_axi};
            17'h03c20: mmio_rsp_rdata <= {23'b0, trigger_index_axi};
            17'h03c24: mmio_rsp_rdata <= stop_reason_axi;
            17'h03c28: mmio_rsp_rdata <= trigger_frame_axi;
            17'h03c2c: mmio_rsp_rdata <= trigger_line_axi;
            17'h03c30: mmio_rsp_rdata <= trigger_clocks_axi[31:0];
            17'h03c34: mmio_rsp_rdata <= trigger_clocks_axi[63:32];
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
