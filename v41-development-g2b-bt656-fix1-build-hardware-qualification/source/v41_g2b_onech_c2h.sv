`timescale 1ns/1ps

// AHD v41 G2B one-channel C2H transport.
//
// The source side passively taps the qualified physical-input-0 byte stream
// after g0p8c3r1_physical_frontend.  It repeats the accepted BT.656 active-line
// validation without changing the legacy capture producer.  Four private
// dual-clock RAM slots carry complete records into axi_aclk.  All externally
// visible bytes and registers implement AHD_C2H_TRANSPORT_ABI_V1 / MMIO v1.
module v41_g2b_onech_c2h (
  input  logic        source_clk,
  input  logic        source_reset,
  input  logic        source_ready,
  input  logic [7:0]  source_byte,

  input  logic        axi_clk,
  input  logic        axi_aresetn,
  input  logic        standalone_transport_reset,

  input  logic        mmio_req_valid,
  output logic        mmio_req_ready,
  input  logic        mmio_req_write,
  input  logic [16:0] mmio_req_addr,
  input  logic [31:0] mmio_req_wdata,
  input  logic [3:0]  mmio_req_be,
  output logic        mmio_rsp_valid,
  input  logic        mmio_rsp_ready,
  output logic [31:0] mmio_rsp_rdata,

  output logic [63:0] m_axis_c2h_tdata,
  output logic [7:0]  m_axis_c2h_tkeep,
  output logic        m_axis_c2h_tlast,
  output logic        m_axis_c2h_tvalid,
  input  logic        m_axis_c2h_tready
);
  localparam logic [31:0] RECORD_MAGIC   = 32'h4c44_4841;
  localparam logic [31:0] RECORD_VERSION = 32'h0000_4101;
  localparam logic [31:0] C2H_MAGIC      = 32'h4332_4831;
  localparam logic [31:0] ABI_VERSION    = 32'h0001_0000;
  localparam logic [31:0] CAPABILITIES   = 32'h000b_001f;
  localparam integer PAYLOAD_BYTES = 3840;
  localparam integer PAYLOAD_WORDS = 480;
  localparam integer STORED_WORDS  = 488;

  // The qualified active picture is followed on physical input 0 by a
  // bounded V-low, line-shaped vertical tail.  Keep the limits explicit so
  // the accepted hardware pattern cannot turn into unbounded tolerance.
  localparam logic [31:0] LAST_ACTIVE_LINE = 32'd1079;
  localparam logic [31:0] FIRST_VERTICAL_TAIL_LINE = 32'd1080;
  localparam logic [31:0] LAST_BENIGN_VERTICAL_TAIL_LINE = 32'd1100;
  localparam integer MAX_BENIGN_VERTICAL_TAIL_LINES = 21;

  localparam logic [31:0] FLAG_SOF                 = 32'h0000_0001;
  localparam logic [31:0] FLAG_DISCONTINUITY       = 32'h0000_0004;
  localparam logic [31:0] FLAG_OVERFLOW_OCCURRED   = 32'h0000_0008;
  localparam logic [31:0] FLAG_MALFORMED_PRECEDING = 32'h0000_0010;
  localparam logic [31:0] FLAG_VALID               = 32'h0000_0020;

  localparam logic [2:0] SLOT_WRITABLE   = 3'd0;
  localparam logic [2:0] SLOT_FILLING    = 3'd1;
  localparam logic [2:0] SLOT_COMMITTED  = 3'd2;
  localparam logic [2:0] SLOT_DMA_OWNED  = 3'd3;
  localparam logic [2:0] SLOT_RELEASABLE = 3'd4;

  function automatic [31:0] gray_to_binary32(input [31:0] gray);
    integer bit_index;
    begin
      gray_to_binary32[31] = gray[31];
      for (bit_index = 30; bit_index >= 0; bit_index = bit_index - 1)
        gray_to_binary32[bit_index] = gray_to_binary32[bit_index+1] ^ gray[bit_index];
    end
  endfunction

  function automatic [31:0] apply_be32(
    input [31:0] old_value, input [31:0] new_value, input [3:0] byte_enable);
    integer byte_index;
    begin
      apply_be32 = old_value;
      for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
        if (byte_enable[byte_index])
          apply_be32[byte_index*8 +: 8] = new_value[byte_index*8 +: 8];
    end
  endfunction

  // ------------------------------------------------------------------------
  // Four private 4096-byte slots. Only words 0..487 are stored. Beats
  // 488..511 are formatter-generated zero padding in axi_clk, as required by
  // the frozen ABI. Each slot still has the exact 512x64 physical geometry.
  // ------------------------------------------------------------------------
  logic [1:0]  source_write_slot = '0;
  logic [8:0]  source_write_addr = '0;
  logic [63:0] source_write_data = '0;
  logic        source_write_enable = 1'b0;
  logic [3:0]  ram_ena;
  logic [3:0]  ram_enb;
  logic [8:0]  ram_addrb;
  logic [63:0] ram_dout [0:3];

  always_comb begin
    ram_ena = 4'b0;
    if (source_write_enable)
      ram_ena[source_write_slot] = 1'b1;
  end

  genvar ram_slot;
  generate
    for (ram_slot = 0; ram_slot < 4; ram_slot = ram_slot + 1) begin : GEN_G2B_SLOT
      xpm_memory_sdpram #(
        .ADDR_WIDTH_A(9), .ADDR_WIDTH_B(9),
        .AUTO_SLEEP_TIME(0), .BYTE_WRITE_WIDTH_A(64),
        .CLOCKING_MODE("independent_clock"), .ECC_MODE("no_ecc"),
        .MEMORY_INIT_FILE("none"), .MEMORY_INIT_PARAM("0"),
        .MEMORY_OPTIMIZATION("true"), .MEMORY_PRIMITIVE("block"),
        .MEMORY_SIZE(32768), .MESSAGE_CONTROL(0),
        .READ_DATA_WIDTH_B(64), .READ_LATENCY_B(1),
        .READ_RESET_VALUE_B("0"), .RST_MODE_B("SYNC"),
        .SIM_ASSERT_CHK(1), .USE_EMBEDDED_CONSTRAINT(0),
        .USE_MEM_INIT(0), .WAKEUP_TIME("disable_sleep"),
        .WRITE_DATA_WIDTH_A(64), .WRITE_MODE_B("read_first")
      ) SLOT_RAM (
        .clka(source_clk), .ena(ram_ena[ram_slot]), .wea(ram_ena[ram_slot]),
        .addra(source_write_addr), .dina(source_write_data),
        .clkb(axi_clk), .enb(ram_enb[ram_slot]), .addrb(ram_addrb),
        .doutb(ram_dout[ram_slot]), .rstb(~axi_aresetn), .regceb(1'b1),
        .sleep(1'b0), .injectsbiterra(1'b0), .injectdbiterra(1'b0),
        .sbiterrb(), .dbiterrb()
      );
    end
  endgenerate

  // ------------------------------------------------------------------------
  // Cross-domain stable-data mailboxes and event state.
  // ------------------------------------------------------------------------
  logic        enable_value_hold_axi = 1'b0;
  logic        enable_req_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic enable_req_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic enable_req_sync2_source = 1'b0;
  logic        enable_req_seen_source = 1'b0;
  logic        enable_ack_toggle_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic enable_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic enable_ack_sync2_axi = 1'b0;
  logic        enable_applied_source = 1'b0;

  logic [31:0] transport_epoch_hold_axi = '0;
  logic        transport_hard_hold_axi = 1'b0;
  logic [3:0]  transport_release_phase_hold_axi = '0;
  logic        transport_own_phase_hold_axi = 1'b0;
  logic [31:0] snapshot_epoch_hold_axi = '0;
  logic        transport_req_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic transport_req_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic transport_req_sync2_source = 1'b0;
  logic        transport_req_seen_source = 1'b0;
  logic        transport_ack_toggle_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic transport_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic transport_ack_sync2_axi = 1'b0;
  logic [2:0]  reset_abandoned_hold_source = '0;
  logic [2:0]  reset_filling_hold_source = '0;
  logic [3:0]  reset_commit_phase_hold_source = '0;

  // A hard reset publishes an explicit source-side clear boundary. The
  // baseline payload is stable before the returned transport acknowledgement,
  // so AXI can discard pre-clear requests yet retain every post-clear event.
  logic [3:0]  hard_event_baseline_hold_source = '0;
  logic        hard_event_clear_toggle_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] hard_event_baseline_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] hard_event_baseline_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic hard_event_clear_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic hard_event_clear_sync2_axi = 1'b0;
  logic        hard_event_clear_seen_axi = 1'b0;
  logic        hard_source_clear_observed_axi = 1'b0;
  logic        hard_event_clear_settle_axi = 1'b0;

  // The standalone formatter/transport reset input is source-clock-domain
  // level state. Convert each level episode into an acknowledged toggle; a
  // deferred episode is retained until the coordinator acknowledges it.
  logic        standalone_req_toggle_source = 1'b0;
  logic        standalone_req_pending_source = 1'b0;
  logic        standalone_level_episode_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic standalone_ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic standalone_ack_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic standalone_req_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic standalone_req_sync2_axi = 1'b0;
  logic        standalone_req_seen_axi = 1'b0;

  logic        stats_req_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic stats_req_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic stats_req_sync2_source = 1'b0;
  logic        stats_req_seen_source = 1'b0;
  logic        stats_ack_toggle_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic stats_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic stats_ack_sync2_axi = 1'b0;

  logic        snapshot_req_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic snapshot_req_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic snapshot_req_sync2_source = 1'b0;
  logic        snapshot_req_seen_source = 1'b0;
  logic        snapshot_ack_toggle_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic snapshot_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic snapshot_ack_sync2_axi = 1'b0;

  logic [1:0]  own_slot_hold_axi = '0;
  logic [23:0] own_generation_hold_axi = '0;
  logic [31:0] own_epoch_hold_axi = '0;
  logic        own_req_toggle_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic own_req_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic own_req_sync2_source = 1'b0;
  logic        own_req_seen_source = 1'b0;
  logic        own_ack_toggle_source = 1'b0;
  logic        own_ok_hold_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic own_ack_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic own_ack_sync2_axi = 1'b0;

  logic [23:0] release_generation_axi [0:3];
  logic [31:0] release_epoch_axi [0:3];
  logic [3:0]  release_toggle_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] release_sync1_source = '0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] release_sync2_source = '0;
  logic [3:0] release_seen_source = '0;
  logic       transport_retire_pending_source = 1'b0;

  // Descriptor buses remain stable from commit through matching release.
  logic [31:0] desc_frame_source [0:3];
  logic [31:0] desc_line_source [0:3];
  logic [31:0] desc_capture_source [0:3];
  logic [31:0] desc_flags_source [0:3];
  logic [31:0] desc_attempt_source [0:3];
  logic [23:0] desc_generation_source [0:3];
  logic [31:0] desc_epoch_source [0:3];
  logic [3:0]  commit_toggle_source = '0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] commit_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [3:0] commit_sync2_axi = '0;
  logic [3:0] commit_seen_axi = '0;

  logic [2:0] slot_state_source [0:3];
  logic [23:0] slot_generation_source [0:3];
  logic [3:0] slot_occupied_source;
  logic [3:0] slot_full_source;
  logic ring_empty_comb_source;
  logic ring_full_comb_source;
  logic ring_empty_source = 1'b1;
  logic ring_full_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ring_empty_sync1_axi = 1'b1;
  (* ASYNC_REG = "TRUE" *) logic ring_empty_sync2_axi = 1'b1;
  (* ASYNC_REG = "TRUE" *) logic ring_full_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ring_full_sync2_axi = 1'b0;

  logic source_locked_source = 1'b0;
  logic source_ready_live_source;
  (* ASYNC_REG = "TRUE" *) logic source_ready_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic source_ready_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic source_locked_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic source_locked_sync2_axi = 1'b0;

  logic source_overflow_event = 1'b0;
  logic source_drop_event = 1'b0;
  logic source_overflow_deferred = 1'b0;
  logic source_drop_deferred = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_ack_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic drop_ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic drop_ack_sync2_source = 1'b0;
  logic source_formatter_fatal = 1'b0;
  logic source_ownership_fatal = 1'b0;
  logic source_formatter_fatal_event = 1'b0;
  logic source_ownership_fatal_event = 1'b0;
  logic source_formatter_fatal_deferred = 1'b0;
  logic source_ownership_fatal_deferred = 1'b0;
  logic source_formatter_clear_pending = 1'b0;
  logic source_ownership_clear_pending = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic formatter_ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic formatter_ack_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ownership_ack_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ownership_ack_sync2_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic overflow_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic drop_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic drop_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic formatter_fatal_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic formatter_fatal_sync2_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ownership_fatal_sync1_axi = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic ownership_fatal_sync2_axi = 1'b0;
  logic overflow_seen_axi = 1'b0;
  logic drop_seen_axi = 1'b0;
  logic formatter_seen_axi = 1'b0;
  logic ownership_seen_axi = 1'b0;

  logic [5:0] error_status_axi = '0;
  wire fatal_error_axi = |error_status_axi[5:3];
  (* ASYNC_REG = "TRUE" *) logic fatal_sync1_source = 1'b0;
  (* ASYNC_REG = "TRUE" *) logic fatal_sync2_source = 1'b0;

  // ------------------------------------------------------------------------
  // Source-domain parser, formatter, admission controller, and ownership.
  // ------------------------------------------------------------------------
  typedef enum logic [2:0] {
    SRC_IDLE, SRC_CAPTURE, SRC_WAIT_EAV, SRC_HEADER, SRC_COMMIT
  } source_state_t;
  source_state_t source_state = SRC_IDLE;

  logic [7:0] marker_p0 = '0, marker_p1 = '0, marker_p2 = '0;
  logic [1:0] marker_fill = '0;
  logic marker_valid_pipe = 1'b0;
  logic marker_h_pipe = 1'b0;
  logic marker_v_pipe = 1'b0;
  logic previous_sav_v = 1'b1;

  logic [12:0] payload_byte_count = '0;
  logic [2:0] payload_byte_phase = '0;
  logic [8:0] payload_word_index = '0;
  logic [63:0] payload_pack = '0;
  logic [2:0] post_payload_count = '0;
  logic [2:0] header_index = '0;
  logic monitor_has_attempt = 1'b0;
  logic monitor_ring_drop = 1'b0;
  logic monitor_writes_slot = 1'b0;
  logic [1:0] filling_slot = '0;
  logic [23:0] filling_generation = '0;

  logic [31:0] source_frame_sequence = '0;
  logic [31:0] source_line_sequence = '0;
  logic [31:0] source_capture_sequence = '0;
  logic [31:0] next_source_line = 32'd1;
  logic [31:0] channel_attempt_next_source = '0;
  logic [31:0] reset_epoch_source = '0;
  logic [1:0] allocation_round_robin = '0;

  logic [31:0] pending_frame = '0;
  logic [31:0] pending_line = '0;
  logic [31:0] pending_capture = '0;
  logic [31:0] pending_flags = '0;
  logic [31:0] pending_attempt = '0;
  logic [31:0] pending_epoch = '0;
  logic pending_discontinuity = 1'b0;
  logic pending_overflow = 1'b0;
  logic pending_malformed = 1'b0;

  logic [31:0] source_lifetime_malformed = '0;
  logic [31:0] source_lifetime_dropped = '0;
  logic [31:0] records_attempted_source = '0;
  logic [31:0] records_committed_source = '0;
  logic [31:0] records_dropped_source = '0;
  logic [31:0] overflow_count_source = '0;

  logic [31:0] snapshot_attempted_gray_hold_source = '0;
  logic [31:0] snapshot_committed_gray_hold_source = '0;
  logic [31:0] snapshot_dropped_gray_hold_source = '0;
  logic [31:0] snapshot_overflow_gray_hold_source = '0;
  logic [31:0] snapshot_epoch_echo_source = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_attempted_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_attempted_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_committed_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_committed_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_dropped_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_dropped_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_overflow_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_overflow_sync2_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_epoch_sync1_axi = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] snapshot_epoch_sync2_axi = '0;

  logic source_in_reset = 1'b1;
  logic [2:0] allocation_choice;
  integer allocation_offset;

  // Configuration-time initialization is intentional. reset_epoch and the
  // cross-domain toggle phases must survive later axi_aresetn episodes; they
  // therefore cannot be tied to the XDMA reset pin.
  initial begin
    integer init_index;
    for (init_index = 0; init_index < 4; init_index = init_index + 1) begin
      slot_state_source[init_index] = SLOT_WRITABLE;
      slot_generation_source[init_index] = 24'b0;
      desc_frame_source[init_index] = 32'b0;
      desc_line_source[init_index] = 32'b0;
      desc_capture_source[init_index] = 32'b0;
      desc_flags_source[init_index] = 32'b0;
      desc_attempt_source[init_index] = 32'b0;
      desc_generation_source[init_index] = 24'b0;
      desc_epoch_source[init_index] = 32'b0;
      release_generation_axi[init_index] = 24'b0;
      release_epoch_axi[init_index] = 32'b0;
    end
  end

  always_comb begin
    allocation_choice = 3'b000;
    for (allocation_offset = 0; allocation_offset < 4; allocation_offset = allocation_offset + 1) begin
      if (!allocation_choice[2] &&
          slot_state_source[(allocation_round_robin + allocation_offset) & 2'b11] == SLOT_WRITABLE) begin
        allocation_choice[2] = 1'b1;
        allocation_choice[1:0] = (allocation_round_robin + allocation_offset) & 2'b11;
      end
    end
  end

  always_comb begin
    integer occupied_index;
    for (occupied_index = 0; occupied_index < 4; occupied_index = occupied_index + 1) begin
      slot_occupied_source[occupied_index] =
          slot_state_source[occupied_index] != SLOT_WRITABLE;
      slot_full_source[occupied_index] = slot_occupied_source[occupied_index];
    end
    // Only the two reduced status predicates cross domains.  Each is an
    // independent synchronized single bit; no ownership vector is sampled as
    // an incoherent multibit status value in AXI/MMIO.
    ring_empty_comb_source = !(|slot_occupied_source);
    ring_full_comb_source = &slot_occupied_source;
    source_ready_live_source = source_ready && !source_reset;
  end

  function automatic [63:0] source_header_word(
    input [2:0] word_index,
    input [31:0] frame_value,
    input [31:0] line_value,
    input [31:0] capture_value,
    input [31:0] flags_value,
    input [1:0] slot_value,
    input [23:0] generation_value,
    input [31:0] malformed_value,
    input [31:0] dropped_value,
    input [31:0] attempt_value,
    input [31:0] epoch_value);
    logic [31:0] low_word;
    logic [31:0] high_word;
    begin
      low_word = 32'b0;
      high_word = 32'b0;
      case (word_index)
        3'd0: begin low_word = RECORD_MAGIC; high_word = RECORD_VERSION; end
        3'd1: begin low_word = epoch_value; high_word = frame_value; end
        3'd2: begin low_word = line_value; high_word = capture_value; end
        3'd3: begin low_word = PAYLOAD_BYTES; high_word = flags_value; end
        3'd4: begin low_word = 32'd1; high_word = {generation_value, 6'b0, slot_value}; end
        3'd5: begin low_word = malformed_value; high_word = dropped_value; end
        3'd6: begin low_word = 32'd0; high_word = 32'd0; end
        3'd7: begin low_word = attempt_value; high_word = 32'd0; end
        default: begin low_word = 32'b0; high_word = 32'b0; end
      endcase
      source_header_word = {high_word, low_word};
    end
  endfunction

  always_ff @(posedge source_clk) begin : SOURCE_DOMAIN
    logic [63:0] packed_word;
    logic [31:0] observed_frame;
    logic [31:0] observed_line;
    logic [31:0] composed_flags;
    logic release_matches;
    logic [2:0] abandoned_count;
    logic [2:0] filling_count;
    logic overflow_event_now;
    logic drop_event_now;
    logic formatter_event_now;
    logic ownership_event_now;
    logic hard_event_clear_now;
    integer run_index;

    source_write_enable <= 1'b0;
    overflow_event_now = 1'b0;
    drop_event_now = 1'b0;
    formatter_event_now = 1'b0;
    ownership_event_now = 1'b0;
    hard_event_clear_now = 1'b0;

    // Synchronizers are active regardless of source readiness.
    enable_req_sync1_source <= enable_req_toggle_axi;
    enable_req_sync2_source <= enable_req_sync1_source;
    transport_req_sync1_source <= transport_req_toggle_axi;
    transport_req_sync2_source <= transport_req_sync1_source;
    stats_req_sync1_source <= stats_req_toggle_axi;
    stats_req_sync2_source <= stats_req_sync1_source;
    snapshot_req_sync1_source <= snapshot_req_toggle_axi;
    snapshot_req_sync2_source <= snapshot_req_sync1_source;
    own_req_sync1_source <= own_req_toggle_axi;
    own_req_sync2_source <= own_req_sync1_source;
    release_sync1_source <= release_toggle_axi;
    release_sync2_source <= release_sync1_source;
    overflow_ack_sync1_source <= overflow_seen_axi;
    overflow_ack_sync2_source <= overflow_ack_sync1_source;
    drop_ack_sync1_source <= drop_seen_axi;
    drop_ack_sync2_source <= drop_ack_sync1_source;
    formatter_ack_sync1_source <= formatter_seen_axi;
    formatter_ack_sync2_source <= formatter_ack_sync1_source;
    ownership_ack_sync1_source <= ownership_seen_axi;
    ownership_ack_sync2_source <= ownership_ack_sync1_source;
    standalone_ack_sync1_source <= standalone_req_seen_axi;
    standalone_ack_sync2_source <= standalone_ack_sync1_source;
    fatal_sync1_source <= fatal_error_axi;
    fatal_sync2_source <= fatal_sync1_source;
    // Register reduced ownership predicates in their native domain before
    // their independent single-bit synchronizers.  This prevents combinational
    // decode hazards from being sampled as live MMIO ring state.
    ring_empty_source <= ring_empty_comb_source;
    ring_full_source <= ring_full_comb_source;

    // Convert a source-domain reset level episode into a lossless request.
    // Multiple episodes while one transport reset is busy are coalesced by
    // the AXI coordinator, while one deferred request bit prevents loss.
    if (standalone_transport_reset && !standalone_level_episode_source) begin
      standalone_level_episode_source <= 1'b1;
      if (standalone_req_toggle_source == standalone_ack_sync2_source &&
          !standalone_req_pending_source)
        standalone_req_toggle_source <= ~standalone_req_toggle_source;
      else
        standalone_req_pending_source <= 1'b1;
    end else if (!standalone_transport_reset) begin
      standalone_level_episode_source <= 1'b0;
    end
    if (!(standalone_transport_reset && !standalone_level_episode_source) &&
        standalone_req_pending_source &&
        standalone_req_toggle_source == standalone_ack_sync2_source) begin
      standalone_req_toggle_source <= ~standalone_req_toggle_source;
      standalone_req_pending_source <= 1'b0;
    end

    // Any impossible encoded ownership state is itself a fatal ownership
    // violation.  Detect it proactively; do not wait for allocation/release to
    // happen to touch the corrupt slot.
    for (run_index = 0; run_index < 4; run_index = run_index + 1) begin
      if (slot_state_source[run_index] > SLOT_RELEASABLE &&
          !source_ownership_fatal) begin
        source_ownership_fatal <= 1'b1;
        ownership_event_now = 1'b1;
        enable_applied_source <= 1'b0;
      end
    end

      if (enable_req_sync2_source != enable_req_seen_source) begin
        enable_applied_source <= enable_value_hold_axi &&
                                 !source_formatter_fatal &&
                                 !source_ownership_fatal &&
                                 !fatal_sync2_source;
      enable_req_seen_source <= enable_req_sync2_source;
      enable_ack_toggle_source <= enable_req_sync2_source;
    end

    if (stats_req_sync2_source != stats_req_seen_source) begin
      records_attempted_source <= 32'b0;
      records_committed_source <= 32'b0;
      records_dropped_source <= 32'b0;
      overflow_count_source <= 32'b0;
      stats_req_seen_source <= stats_req_sync2_source;
      stats_ack_toggle_source <= stats_req_sync2_source;
    end

    if (snapshot_req_sync2_source != snapshot_req_seen_source) begin
      // Atomically capture the source-registered binary counters into their
      // registered Gray hold representation.  These mailbox values and the
      // captured epoch remain stable until a later request generation.
      snapshot_attempted_gray_hold_source <=
          records_attempted_source ^ (records_attempted_source >> 1);
      snapshot_committed_gray_hold_source <=
          records_committed_source ^ (records_committed_source >> 1);
      snapshot_dropped_gray_hold_source <=
          records_dropped_source ^ (records_dropped_source >> 1);
      snapshot_overflow_gray_hold_source <=
          overflow_count_source ^ (overflow_count_source >> 1);
      snapshot_epoch_echo_source <= snapshot_epoch_hold_axi;
      snapshot_req_seen_source <= snapshot_req_sync2_source;
      snapshot_ack_toggle_source <= snapshot_req_sync2_source;
    end

    // Explicit COMMITTED -> DMA_OWNED transition. The stable result accompanies
    // the acknowledged ownership request.
    if (!transport_retire_pending_source &&
        transport_req_sync2_source == transport_req_seen_source &&
        own_req_sync2_source != own_req_seen_source) begin
      own_ok_hold_source <= 1'b0;
      if (slot_state_source[own_slot_hold_axi] == SLOT_COMMITTED &&
          slot_generation_source[own_slot_hold_axi] == own_generation_hold_axi &&
          desc_epoch_source[own_slot_hold_axi] == own_epoch_hold_axi &&
          reset_epoch_source == own_epoch_hold_axi) begin
        slot_state_source[own_slot_hold_axi] <= SLOT_DMA_OWNED;
        own_ok_hold_source <= 1'b1;
      end else begin
        source_ownership_fatal <= 1'b1;
        ownership_event_now = 1'b1;
        enable_applied_source <= 1'b0;
      end
      own_req_seen_source <= own_req_sync2_source;
      own_ack_toggle_source <= own_req_sync2_source;
    end

    // A reset acknowledgement is withheld until every captured release phase
    // and the captured ownership-request phase have reached their source
    // synchronizers. This keeps a lagging old-epoch toggle from reappearing as
    // a reverse/new release or ownership request after all slots are WRITABLE.
    if (transport_retire_pending_source &&
        release_sync2_source == transport_release_phase_hold_axi &&
        own_req_sync2_source == transport_own_phase_hold_axi) begin
      release_seen_source <= transport_release_phase_hold_axi;
      own_req_seen_source <= transport_own_phase_hold_axi;
      own_ack_toggle_source <= transport_own_phase_hold_axi;
      transport_ack_toggle_source <= transport_req_seen_source;
      transport_retire_pending_source <= 1'b0;
    end

    // Generation- and epoch-qualified DMA_OWNED -> RELEASABLE transition.
    // Every token mismatch is fatal; a stale release is never silently
    // accepted and can never release a newer owner.  Suppress ordinary release
    // decoding while a new reset request or its retirement barrier is active.
    if (!transport_retire_pending_source &&
        transport_req_sync2_source == transport_req_seen_source) begin
      for (run_index = 0; run_index < 4; run_index = run_index + 1) begin
        if (slot_state_source[run_index] == SLOT_RELEASABLE)
          slot_state_source[run_index] <= SLOT_WRITABLE;
        if (release_sync2_source[run_index] != release_seen_source[run_index]) begin
          release_seen_source[run_index] <= release_sync2_source[run_index];
          if (release_generation_axi[run_index] == slot_generation_source[run_index] &&
              release_epoch_axi[run_index] == desc_epoch_source[run_index] &&
              release_epoch_axi[run_index] == reset_epoch_source &&
              slot_state_source[run_index] == SLOT_DMA_OWNED) begin
            slot_state_source[run_index] <= SLOT_RELEASABLE;
          end else begin
            source_ownership_fatal <= 1'b1;
            ownership_event_now = 1'b1;
            enable_applied_source <= 1'b0;
          end
        end
      end
    end

    // Transport reset has priority over source reset and parser progress. The
    // epoch value and hard-reset qualifier are stable-data mailbox payloads.
    if (transport_req_sync2_source != transport_req_seen_source) begin
      abandoned_count = 3'b0;
      filling_count = 3'b0;
      for (run_index = 0; run_index < 4; run_index = run_index + 1) begin
        release_matches =
            (transport_release_phase_hold_axi[run_index] !=
             release_seen_source[run_index]) &&
            (release_generation_axi[run_index] == slot_generation_source[run_index]) &&
            (release_epoch_axi[run_index] == desc_epoch_source[run_index]) &&
            (release_epoch_axi[run_index] == reset_epoch_source);
        if (slot_state_source[run_index] == SLOT_FILLING)
          filling_count = filling_count + 1'b1;
        if ((slot_state_source[run_index] == SLOT_COMMITTED ||
             slot_state_source[run_index] == SLOT_DMA_OWNED) && !release_matches)
          abandoned_count = abandoned_count + 1'b1;
        slot_state_source[run_index] <= SLOT_WRITABLE;
        slot_generation_source[run_index] <= 24'b0;
      end
      reset_abandoned_hold_source <= abandoned_count;
      reset_filling_hold_source <= filling_count;
      reset_commit_phase_hold_source <= commit_toggle_source;
      if (transport_hard_hold_axi) begin
        records_attempted_source <= 32'b0;
        records_committed_source <= 32'b0;
        records_dropped_source <= 32'b0;
        overflow_count_source <= 32'b0;
      end else if (filling_count != 0) begin
        records_dropped_source <= records_dropped_source + filling_count;
        source_lifetime_dropped <= source_lifetime_dropped + filling_count;
        drop_event_now = 1'b1;
      end
      enable_applied_source <= 1'b0;
      channel_attempt_next_source <= 32'b0;
      reset_epoch_source <= transport_epoch_hold_axi;
      allocation_round_robin <= 2'b0;
      pending_discontinuity <= 1'b0;
      pending_overflow <= 1'b0;
      pending_malformed <= 1'b0;
      hard_event_clear_now = transport_hard_hold_axi;
      // A normal transport reset clears the local admission latch only after
      // every fatal event request has been acknowledged.  A hard episode may
      // instead retire the entire event channel because AXI sticky state is
      // reset on that same episode.
      if (transport_hard_hold_axi) begin
        source_formatter_fatal <= 1'b0;
        source_ownership_fatal <= 1'b0;
        source_formatter_clear_pending <= 1'b0;
        source_ownership_clear_pending <= 1'b0;
        hard_event_baseline_hold_source <= {
          ownership_ack_sync2_source, formatter_ack_sync2_source,
          drop_ack_sync2_source, overflow_ack_sync2_source
        };
        hard_event_clear_toggle_source <= ~hard_event_clear_toggle_source;
      end else begin
        if (source_formatter_fatal_event == formatter_ack_sync2_source &&
            !source_formatter_fatal_deferred)
          source_formatter_fatal <= 1'b0;
        else
          source_formatter_clear_pending <= 1'b1;
        if (source_ownership_fatal_event == ownership_ack_sync2_source &&
            !source_ownership_fatal_deferred)
          source_ownership_fatal <= 1'b0;
        else
          source_ownership_clear_pending <= 1'b1;
      end
      // Invalidate/retire any older snapshot token before this transport reset
      // is acknowledged.  A post-reset request must therefore use a new token.
      snapshot_req_seen_source <= snapshot_req_sync2_source;
      snapshot_ack_toggle_source <= snapshot_req_sync2_source;
      source_state <= SRC_IDLE;
      monitor_has_attempt <= 1'b0;
      monitor_ring_drop <= 1'b0;
      monitor_writes_slot <= 1'b0;
      payload_byte_count <= '0;
      payload_byte_phase <= '0;
      payload_word_index <= '0;
      payload_pack <= '0;
      post_payload_count <= '0;
      // Retire every release issued no later than this transport request,
      // including a beat-511 release launched on the same AXI edge.  Return
      // the transport acknowledgement only after the independently
      // synchronized release vector has reached this captured phase.
      release_seen_source <= transport_release_phase_hold_axi;
      own_req_seen_source <= transport_own_phase_hold_axi;
      own_ack_toggle_source <= transport_own_phase_hold_axi;
      transport_req_seen_source <= transport_req_sync2_source;
      if (release_sync2_source == transport_release_phase_hold_axi &&
          own_req_sync2_source == transport_own_phase_hold_axi) begin
        transport_ack_toggle_source <= transport_req_sync2_source;
        transport_retire_pending_source <= 1'b0;
      end else begin
        transport_retire_pending_source <= 1'b1;
      end
      if (source_reset) begin
        // A coincident source reset still restarts the independent source
        // lifetime after the old-lifetime FILLING disposition above. The new
        // transport epoch clears old pending flags, so no old flag leaks.
        source_in_reset <= 1'b1;
        source_frame_sequence <= 32'b0;
        source_line_sequence <= 32'b0;
        source_capture_sequence <= 32'b0;
        source_lifetime_malformed <= 32'b0;
        source_lifetime_dropped <= 32'b0;
        next_source_line <= 32'd1;
        source_locked_source <= 1'b0;
        marker_p0 <= '0;
        marker_p1 <= '0;
        marker_p2 <= '0;
        marker_fill <= '0;
        marker_valid_pipe <= 1'b0;
        marker_h_pipe <= 1'b0;
        marker_v_pipe <= 1'b0;
        previous_sav_v <= 1'b1;
      end
    end else if (source_reset) begin
      if (!source_in_reset) begin
        if (source_state == SRC_CAPTURE || source_state == SRC_WAIT_EAV ||
            source_state == SRC_HEADER || source_state == SRC_COMMIT) begin
          if (monitor_has_attempt && monitor_writes_slot) begin
            slot_state_source[filling_slot] <= SLOT_WRITABLE;
            records_dropped_source <= records_dropped_source + 1'b1;
            drop_event_now = 1'b1;
          end
        end
      end
      source_in_reset <= 1'b1;
      source_locked_source <= 1'b0;
      source_state <= SRC_IDLE;
      marker_p0 <= '0;
      marker_p1 <= '0;
      marker_p2 <= '0;
      marker_fill <= '0;
      marker_valid_pipe <= 1'b0;
      marker_h_pipe <= 1'b0;
      marker_v_pipe <= 1'b0;
      previous_sav_v <= 1'b1;
      payload_byte_count <= '0;
      payload_byte_phase <= '0;
      payload_word_index <= '0;
      payload_pack <= '0;
      post_payload_count <= '0;
      monitor_has_attempt <= 1'b0;
      monitor_ring_drop <= 1'b0;
      monitor_writes_slot <= 1'b0;
      source_frame_sequence <= 32'b0;
      source_line_sequence <= 32'b0;
      source_capture_sequence <= 32'b0;
      next_source_line <= 32'd1;
      source_lifetime_malformed <= 32'b0;
      source_lifetime_dropped <= 32'b0;
      pending_discontinuity <= 1'b1;
      pending_overflow <= 1'b0;
      pending_malformed <= 1'b0;
    end else if (!source_ready_live_source) begin
      // Readiness loss is a source boundary, not a source formatter reset.
      // Preserve source frame/capture and lifetime banks, abort only an
      // already eligible allocation, and require a newly validated line to
      // re-establish lock. NVP/I2C activity therefore cannot reset ABI source
      // sequences or create a transport epoch.
      if (monitor_has_attempt && monitor_writes_slot) begin
        if (slot_state_source[filling_slot] == SLOT_FILLING)
          slot_state_source[filling_slot] <= SLOT_WRITABLE;
        records_dropped_source <= records_dropped_source + 1'b1;
        source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
        drop_event_now = 1'b1;
      end
      source_in_reset <= 1'b0;
      source_locked_source <= 1'b0;
      source_state <= SRC_IDLE;
      marker_p0 <= '0;
      marker_p1 <= '0;
      marker_p2 <= '0;
      marker_fill <= '0;
      marker_valid_pipe <= 1'b0;
      marker_h_pipe <= 1'b0;
      marker_v_pipe <= 1'b0;
      previous_sav_v <= 1'b1;
      payload_byte_count <= '0;
      payload_byte_phase <= '0;
      payload_word_index <= '0;
      payload_pack <= '0;
      post_payload_count <= '0;
      monitor_has_attempt <= 1'b0;
      monitor_ring_drop <= 1'b0;
      monitor_writes_slot <= 1'b0;
      pending_discontinuity <= 1'b1;
    end else begin
      source_in_reset <= 1'b0;

      // Qualified BT.656 marker detector copied at the accepted post-frontend
      // tap. Marker parity is checked by bits 7 and 3:0 exactly as in G2A.
      marker_h_pipe <= source_byte[4];
      marker_v_pipe <= source_byte[5];
      if (source_ready && marker_fill == 3 &&
          marker_p0 == 8'hff && marker_p1 == 8'h00 && marker_p2 == 8'h00 &&
          source_byte[7] && source_byte[3:0] == 4'b0000)
        marker_valid_pipe <= 1'b1;
      else
        marker_valid_pipe <= 1'b0;
      marker_p0 <= marker_p1;
      marker_p1 <= marker_p2;
      marker_p2 <= source_byte;
      if (marker_fill < 3)
        marker_fill <= marker_fill + 1'b1;

      case (source_state)
        SRC_IDLE: begin
          if (marker_valid_pipe && !marker_h_pipe) begin
            observed_frame = source_frame_sequence;
            observed_line = source_line_sequence;
            if (!marker_v_pipe) begin
              if (previous_sav_v) begin
                observed_frame = source_frame_sequence + 1'b1;
                observed_line = 32'b0;
                next_source_line <= 32'd1;
              end else begin
                observed_line = next_source_line;
                next_source_line <= next_source_line + 1'b1;
              end
              source_frame_sequence <= observed_frame;
              source_line_sequence <= observed_line;
              pending_frame <= observed_frame;
              pending_line <= observed_line;
              monitor_has_attempt <= 1'b0;
              monitor_ring_drop <= 1'b0;
              monitor_writes_slot <= 1'b0;
              payload_byte_count <= '0;
              payload_byte_phase <= '0;
              payload_word_index <= '0;
              payload_pack <= '0;
              post_payload_count <= '0;

              // Physical input 0 can keep V low for complete line-shaped
              // intervals after the 1080 qualified active lines and before
              // its V-high blanking markers.  Those out-of-range intervals
              // are vertical-boundary tail, not record attempts.
              if (observed_line <= LAST_ACTIVE_LINE &&
                  enable_applied_source && source_ready_live_source &&
                  source_locked_source && !fatal_sync2_source &&
                  !source_formatter_fatal && !source_ownership_fatal) begin
                monitor_has_attempt <= 1'b1;
                pending_attempt <= channel_attempt_next_source;
                pending_epoch <= reset_epoch_source;
                channel_attempt_next_source <= channel_attempt_next_source + 1'b1;
                records_attempted_source <= records_attempted_source + 1'b1;
                if (allocation_choice[2]) begin
                  filling_slot <= allocation_choice[1:0];
                  filling_generation <=
                      slot_generation_source[allocation_choice[1:0]] + 1'b1;
                  slot_generation_source[allocation_choice[1:0]] <=
                      slot_generation_source[allocation_choice[1:0]] + 1'b1;
                  slot_state_source[allocation_choice[1:0]] <= SLOT_FILLING;
                  monitor_writes_slot <= 1'b1;
                end else begin
                  monitor_ring_drop <= 1'b1;
                  records_dropped_source <= records_dropped_source + 1'b1;
                  overflow_count_source <= overflow_count_source + 1'b1;
                  source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
                  pending_discontinuity <= 1'b1;
                  pending_overflow <= 1'b1;
                  overflow_event_now = 1'b1;
                  drop_event_now = 1'b1;
                end
              end
              source_state <= SRC_CAPTURE;
            end
            previous_sav_v <= marker_v_pipe;
          end
        end

        SRC_CAPTURE: begin
          if (marker_valid_pipe) begin
            source_locked_source <= 1'b0;
            source_lifetime_malformed <= source_lifetime_malformed + 1'b1;
            pending_discontinuity <= 1'b1;
            pending_malformed <= 1'b1;
            if (monitor_has_attempt && !monitor_ring_drop) begin
              if (monitor_writes_slot)
                slot_state_source[filling_slot] <= SLOT_WRITABLE;
              records_dropped_source <= records_dropped_source + 1'b1;
              source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
              drop_event_now = 1'b1;
            end
            source_state <= SRC_IDLE;
          end else begin
            packed_word = payload_pack;
            case (payload_byte_phase)
              3'd0: packed_word[7:0]   = marker_p2;
              3'd1: packed_word[15:8]  = marker_p2;
              3'd2: packed_word[23:16] = marker_p2;
              3'd3: packed_word[31:24] = marker_p2;
              3'd4: packed_word[39:32] = marker_p2;
              3'd5: packed_word[47:40] = marker_p2;
              3'd6: packed_word[55:48] = marker_p2;
              default: packed_word[63:56] = marker_p2;
            endcase
            payload_pack <= packed_word;
            if (payload_byte_phase == 7) begin
              if (monitor_writes_slot) begin
                source_write_slot <= filling_slot;
                source_write_addr <= 9'd8 + payload_word_index;
                source_write_data <= packed_word;
                source_write_enable <= 1'b1;
              end
              payload_pack <= 64'b0;
              payload_byte_phase <= 3'b0;
              if (payload_byte_count == PAYLOAD_BYTES-1) begin
                payload_byte_count <= 13'b0;
                post_payload_count <= 3'b0;
                source_state <= SRC_WAIT_EAV;
              end else begin
                payload_byte_count <= payload_byte_count + 1'b1;
                payload_word_index <= payload_word_index + 1'b1;
              end
            end else begin
              payload_byte_phase <= payload_byte_phase + 1'b1;
              payload_byte_count <= payload_byte_count + 1'b1;
            end
          end
        end

        SRC_WAIT_EAV: begin
          if (marker_valid_pipe) begin
            if (marker_h_pipe && post_payload_count == 3) begin
              source_locked_source <= 1'b1;
              if (pending_line >= FIRST_VERTICAL_TAIL_LINE &&
                  pending_line <= LAST_BENIGN_VERTICAL_TAIL_LINE) begin
                // Preserve lock across the bounded, complete V-low vertical
                // tail. Each physical interval advances only the source-local
                // capture sequence; it is not a transport attempt or record.
                source_capture_sequence <= source_capture_sequence + 1'b1;
                source_state <= SRC_IDLE;
              end else if (pending_line > LAST_BENIGN_VERTICAL_TAIL_LINE) begin
                // A complete V-low line beyond the qualified 21-line tail is
                // an unexpected format/boundary event.  Count it once, keep
                // it out of the active transport, and follow the existing
                // bounded malformed/lock-reacquisition behavior.
                source_locked_source <= 1'b0;
                source_lifetime_malformed <= source_lifetime_malformed + 1'b1;
                pending_discontinuity <= 1'b1;
                pending_malformed <= 1'b1;
                source_state <= SRC_IDLE;
              end else if (monitor_has_attempt && monitor_writes_slot) begin
                pending_capture <= source_capture_sequence + 1'b1;
                composed_flags = FLAG_VALID;
                if (pending_line == 0)
                  composed_flags = composed_flags | FLAG_SOF;
                if (pending_discontinuity)
                  composed_flags = composed_flags | FLAG_DISCONTINUITY;
                if (pending_overflow)
                  composed_flags = composed_flags | FLAG_OVERFLOW_OCCURRED;
                if (pending_malformed)
                  composed_flags = composed_flags | FLAG_MALFORMED_PRECEDING;
                pending_flags <= composed_flags;
                header_index <= 3'b0;
                source_state <= SRC_HEADER;
              end else begin
                // Source capture numbering is source-local, not an admission
                // counter.  A valid line completed while disabled, unlocked,
                // or fatal-gated advances it.  An eligible ring-full attempt
                // deliberately does not.
                if (!monitor_has_attempt)
                  source_capture_sequence <= source_capture_sequence + 1'b1;
                if (!monitor_has_attempt)
                  pending_discontinuity <= 1'b1;
                source_state <= SRC_IDLE;
              end
            end else begin
              source_locked_source <= 1'b0;
              source_lifetime_malformed <= source_lifetime_malformed + 1'b1;
              pending_discontinuity <= 1'b1;
              pending_malformed <= 1'b1;
              if (monitor_has_attempt && !monitor_ring_drop) begin
                if (monitor_writes_slot)
                  slot_state_source[filling_slot] <= SLOT_WRITABLE;
                records_dropped_source <= records_dropped_source + 1'b1;
                source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
                drop_event_now = 1'b1;
              end
              source_state <= SRC_IDLE;
            end
          end else if (post_payload_count >= 4) begin
            source_locked_source <= 1'b0;
            source_lifetime_malformed <= source_lifetime_malformed + 1'b1;
            pending_discontinuity <= 1'b1;
            pending_malformed <= 1'b1;
            if (monitor_has_attempt && !monitor_ring_drop) begin
              if (monitor_writes_slot)
                slot_state_source[filling_slot] <= SLOT_WRITABLE;
              records_dropped_source <= records_dropped_source + 1'b1;
              source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
              drop_event_now = 1'b1;
            end
            source_state <= SRC_IDLE;
          end else begin
            post_payload_count <= post_payload_count + 1'b1;
          end
        end

        SRC_HEADER: begin
          source_write_slot <= filling_slot;
          source_write_addr <= {6'b0, header_index};
          source_write_data <= source_header_word(
              header_index, pending_frame, pending_line, pending_capture,
              pending_flags, filling_slot, filling_generation,
              source_lifetime_malformed, source_lifetime_dropped,
              pending_attempt, pending_epoch);
          source_write_enable <= 1'b1;
          if (header_index == 7)
            source_state <= SRC_COMMIT;
          else
            header_index <= header_index + 1'b1;
        end

        SRC_COMMIT: begin
          if (slot_state_source[filling_slot] != SLOT_FILLING ||
              slot_generation_source[filling_slot] != filling_generation ||
              reset_epoch_source != pending_epoch) begin
            source_formatter_fatal <= 1'b1;
            formatter_event_now = 1'b1;
            enable_applied_source <= 1'b0;
            if (monitor_has_attempt && !monitor_ring_drop) begin
              if (slot_state_source[filling_slot] == SLOT_FILLING)
                slot_state_source[filling_slot] <= SLOT_WRITABLE;
              records_dropped_source <= records_dropped_source + 1'b1;
              source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
              pending_discontinuity <= 1'b1;
              drop_event_now = 1'b1;
            end
          end else begin
            desc_frame_source[filling_slot] <= pending_frame;
            desc_line_source[filling_slot] <= pending_line;
            desc_capture_source[filling_slot] <= pending_capture;
            desc_flags_source[filling_slot] <= pending_flags;
            desc_attempt_source[filling_slot] <= pending_attempt;
            desc_generation_source[filling_slot] <= filling_generation;
            desc_epoch_source[filling_slot] <= pending_epoch;
            slot_state_source[filling_slot] <= SLOT_COMMITTED;
            commit_toggle_source[filling_slot] <= ~commit_toggle_source[filling_slot];
            records_committed_source <= records_committed_source + 1'b1;
            source_capture_sequence <= pending_capture;
            allocation_round_robin <= filling_slot + 1'b1;
            pending_discontinuity <= 1'b0;
            pending_overflow <= 1'b0;
            pending_malformed <= 1'b0;
          end
          monitor_has_attempt <= 1'b0;
          monitor_ring_drop <= 1'b0;
          monitor_writes_slot <= 1'b0;
          source_state <= SRC_IDLE;
        end

        default: begin
          source_formatter_fatal <= 1'b1;
          formatter_event_now = 1'b1;
          enable_applied_source <= 1'b0;
          if (monitor_has_attempt && !monitor_ring_drop) begin
            if (slot_state_source[filling_slot] == SLOT_FILLING)
              slot_state_source[filling_slot] <= SLOT_WRITABLE;
            records_dropped_source <= records_dropped_source + 1'b1;
            source_lifetime_dropped <= source_lifetime_dropped + 1'b1;
            pending_discontinuity <= 1'b1;
            drop_event_now = 1'b1;
          end
          source_state <= SRC_IDLE;
        end
      endcase
    end

    // Source error requests use acknowledged toggles.  A second event while
    // one request is outstanding is retained and re-issued after the first
    // acknowledgement, so no CDC pulse width assumption exists.
    if (hard_event_clear_now) begin
      source_overflow_event <= overflow_ack_sync2_source;
      source_drop_event <= drop_ack_sync2_source;
      source_formatter_fatal_event <= formatter_ack_sync2_source;
      source_ownership_fatal_event <= ownership_ack_sync2_source;
      source_overflow_deferred <= 1'b0;
      source_drop_deferred <= 1'b0;
      source_formatter_fatal_deferred <= 1'b0;
      source_ownership_fatal_deferred <= 1'b0;
      source_formatter_clear_pending <= 1'b0;
      source_ownership_clear_pending <= 1'b0;
    end else begin
      if (overflow_event_now) begin
        if (source_overflow_event == overflow_ack_sync2_source &&
            !source_overflow_deferred)
          source_overflow_event <= ~source_overflow_event;
        else
          source_overflow_deferred <= 1'b1;
      end else if (source_overflow_event == overflow_ack_sync2_source &&
                   source_overflow_deferred) begin
        source_overflow_event <= ~source_overflow_event;
        source_overflow_deferred <= 1'b0;
      end

      if (drop_event_now) begin
        if (source_drop_event == drop_ack_sync2_source &&
            !source_drop_deferred)
          source_drop_event <= ~source_drop_event;
        else
          source_drop_deferred <= 1'b1;
      end else if (source_drop_event == drop_ack_sync2_source &&
                   source_drop_deferred) begin
        source_drop_event <= ~source_drop_event;
        source_drop_deferred <= 1'b0;
      end

      if (formatter_event_now) begin
        if (source_formatter_fatal_event == formatter_ack_sync2_source &&
            !source_formatter_fatal_deferred)
          source_formatter_fatal_event <= ~source_formatter_fatal_event;
        else
          source_formatter_fatal_deferred <= 1'b1;
      end else if (source_formatter_fatal_event == formatter_ack_sync2_source &&
                   source_formatter_fatal_deferred) begin
        source_formatter_fatal_event <= ~source_formatter_fatal_event;
        source_formatter_fatal_deferred <= 1'b0;
      end

      if (ownership_event_now) begin
        if (source_ownership_fatal_event == ownership_ack_sync2_source &&
            !source_ownership_fatal_deferred)
          source_ownership_fatal_event <= ~source_ownership_fatal_event;
        else
          source_ownership_fatal_deferred <= 1'b1;
      end else if (source_ownership_fatal_event == ownership_ack_sync2_source &&
                   source_ownership_fatal_deferred) begin
        source_ownership_fatal_event <= ~source_ownership_fatal_event;
        source_ownership_fatal_deferred <= 1'b0;
      end

      if (source_formatter_clear_pending &&
          source_formatter_fatal_event == formatter_ack_sync2_source &&
          !source_formatter_fatal_deferred) begin
        source_formatter_fatal <= 1'b0;
        source_formatter_clear_pending <= 1'b0;
      end
      if (source_ownership_clear_pending &&
          source_ownership_fatal_event == ownership_ack_sync2_source &&
          !source_ownership_fatal_deferred) begin
        source_ownership_fatal <= 1'b0;
        source_ownership_clear_pending <= 1'b0;
      end
    end
  end

  // ------------------------------------------------------------------------
  // AXI-domain synchronizers, commit FIFO, fixed one-channel scheduler,
  // counter bank, coherent snapshot, reset epoch, and MMIO.
  // ------------------------------------------------------------------------
  typedef enum logic [2:0] {
    AXIS_IDLE, AXIS_WAIT_OWN, AXIS_PREFETCH, AXIS_STREAM, AXIS_ERROR_HOLD
  } axis_state_t;
  axis_state_t axis_state = AXIS_IDLE;
  logic [8:0] axis_beat_index = '0;
  logic [1:0] axis_slot = '0;
  logic [23:0] axis_generation = '0;
  logic [31:0] axis_epoch = '0;
  logic [31:0] axis_attempt = '0;
  logic [31:0] axis_global = '0;

  logic [1:0] commit_fifo [0:3];
  logic [1:0] commit_fifo_head = '0;
  logic [1:0] commit_fifo_tail = '0;
  logic [2:0] commit_fifo_count = '0;

  initial begin : INIT_COMMIT_FIFO
    integer fifo_init_index;
    for (fifo_init_index = 0; fifo_init_index < 4; fifo_init_index = fifo_init_index + 1)
      commit_fifo[fifo_init_index] = 2'b0;
  end

  logic [31:0] global_stream_next_axi = '0;
  logic [31:0] records_streamed_axi = '0;
  logic [63:0] beats_streamed_axi = '0;
  logic [31:0] discontinuities_axi = '0;
  logic [31:0] records_abandoned_axi = '0;
  logic [31:0] reset_events_axi = '0;
  logic [31:0] last_global_axi = 32'hffff_ffff;
  logic [31:0] last_channel_axi = 32'hffff_ffff;
  logic last_global_valid_axi = 1'b0;
  logic last_channel_valid_axi = 1'b0;

  logic [31:0] shadow_records_attempted = '0;
  logic [31:0] shadow_records_committed = '0;
  logic [31:0] shadow_records_streamed = '0;
  logic [31:0] shadow_records_dropped = '0;
  logic [31:0] shadow_overflow_count = '0;
  logic [31:0] shadow_discontinuities = '0;
  logic [63:0] shadow_beats_streamed = '0;
  logic [31:0] shadow_last_global = 32'hffff_ffff;
  logic [31:0] shadow_records_abandoned = '0;
  logic [31:0] shadow_reset_events = '0;
  logic [31:0] shadow_last_channel = 32'hffff_ffff;
  logic shadow_last_global_valid = 1'b0;
  logic shadow_last_channel_valid = 1'b0;
  logic [31:0] snapshot_generation_axi = '0;
  logic snapshot_busy_axi = 1'b0;
  logic snapshot_valid_axi = 1'b0;
  logic snapshot_ack_settled_axi = 1'b0;
  logic [31:0] reset_epoch_axi = '0;
  logic stream_reset_busy_axi = 1'b0;
  logic stream_reset_is_hard_axi = 1'b0;
  logic transport_followup_hard_axi = 1'b0;
  logic axi_seen_high = 1'b0;
  logic axi_hard_episode = 1'b0;
  logic stored_enable_axi = 1'b0;
  logic fatal_clear_qualified_axi = 1'b0;
  logic [31:0] fatal_generation_axi = '0;
  logic [31:0] reset_fatal_generation_hold_axi = '0;
  logic [31:0] last_error_cause_axi = '0;

  typedef enum logic [1:0] {MMIO_IDLE, MMIO_WAIT_ENABLE, MMIO_WAIT_STATS} mmio_state_t;
  mmio_state_t mmio_state = MMIO_IDLE;
  logic pending_enable_value_axi = 1'b0;
  logic pending_stats_then_stream_axi = 1'b0;
  logic pending_stats_enable_axi = 1'b0;
  logic enable_retry_after_reset_axi = 1'b0;

  wire ring_empty_axi = ring_empty_sync2_axi;
  wire ring_full_axi = ring_full_sync2_axi;
  wire c2h_active_axi = !ring_empty_axi || axis_state != AXIS_IDLE ||
                         commit_fifo_count != 0;
  wire [31:0] status_word_axi = {
      20'b0, fatal_error_axi, snapshot_valid_axi, snapshot_busy_axi,
      stream_reset_busy_axi, source_locked_sync2_axi, source_ready_sync2_axi,
      error_status_axi[1], error_status_axi[0], ring_full_axi, ring_empty_axi,
      c2h_active_axi, stored_enable_axi};

  wire [63:0] selected_ram_word = ram_dout[axis_slot];
  always_comb begin
    ram_enb = 4'b0;
    ram_addrb = axis_beat_index;
    if (axis_state == AXIS_PREFETCH) begin
      ram_enb[axis_slot] = 1'b1;
      ram_addrb = 9'b0;
    end else if (axis_state == AXIS_STREAM && axis_beat_index < STORED_WORDS) begin
      ram_enb[axis_slot] = 1'b1;
      if (m_axis_c2h_tvalid && m_axis_c2h_tready &&
          axis_beat_index < STORED_WORDS-1)
        ram_addrb = axis_beat_index + 1'b1;
    end
  end

  always_comb begin
    m_axis_c2h_tvalid = (axis_state == AXIS_STREAM);
    m_axis_c2h_tkeep = 8'hff;
    m_axis_c2h_tlast = (axis_beat_index == 9'd511);
    if (axis_beat_index >= STORED_WORDS)
      m_axis_c2h_tdata = 64'b0;
    else if (axis_beat_index == 9'd7)
      m_axis_c2h_tdata = {axis_global, selected_ram_word[31:0]};
    else
      m_axis_c2h_tdata = selected_ram_word;
  end

  function automatic [31:0] mmio_read_word(input [16:0] address_value);
    begin
      mmio_read_word = 32'b0;
      if (address_value[1:0] == 2'b00) begin
        case (address_value)
          17'h03800: mmio_read_word = C2H_MAGIC;
          17'h03804: mmio_read_word = ABI_VERSION;
          17'h03808: mmio_read_word = CAPABILITIES;
          17'h0380c: mmio_read_word = {31'b0, stored_enable_axi};
          17'h03810: mmio_read_word = status_word_axi;
          17'h03814: mmio_read_word = shadow_records_attempted;
          17'h03818: mmio_read_word = shadow_records_committed;
          17'h0381c: mmio_read_word = shadow_records_streamed;
          17'h03820: mmio_read_word = shadow_records_dropped;
          17'h03824: mmio_read_word = shadow_overflow_count;
          17'h03828: mmio_read_word = shadow_discontinuities;
          17'h0382c: mmio_read_word = shadow_beats_streamed[31:0];
          17'h03830: mmio_read_word = shadow_beats_streamed[63:32];
          17'h03834: mmio_read_word = shadow_last_global;
          17'h03838: mmio_read_word = reset_epoch_axi;
          17'h0383c: mmio_read_word = {26'b0, error_status_axi};
          17'h03840: mmio_read_word = last_error_cause_axi;
          17'h03844: mmio_read_word = 32'b0;
          17'h03848: mmio_read_word = {28'b0, shadow_last_channel_valid,
              shadow_last_global_valid, snapshot_valid_axi, snapshot_busy_axi};
          17'h0384c: mmio_read_word = snapshot_generation_axi;
          17'h03850: mmio_read_word = shadow_records_abandoned;
          17'h03854: mmio_read_word = shadow_reset_events;
          17'h03858: mmio_read_word = shadow_last_channel;
          default: mmio_read_word = 32'b0;
        endcase
      end
    end
  endfunction

  wire mmio_control_aligned = mmio_req_addr == 17'h0380c;
  wire mmio_error_aligned = mmio_req_addr == 17'h0383c;
  wire mmio_snapshot_aligned = mmio_req_addr == 17'h03844;
  wire control_stats_bit = mmio_req_be[0] && mmio_req_wdata[1];
  wire control_stream_bit = mmio_req_be[0] && mmio_req_wdata[2];
  wire control_enable_candidate = mmio_req_be[0] ? mmio_req_wdata[0]
                                                 : stored_enable_axi;
  wire stats_legal_axi = !stored_enable_axi && !c2h_active_axi && ring_empty_axi &&
                         !stream_reset_busy_axi && !snapshot_busy_axi;
  wire standalone_reset_rise_axi =
      standalone_req_sync2_axi != standalone_req_seen_axi;
  wire mmio_enable_request = mmio_req_valid && mmio_req_write &&
      mmio_control_aligned && !control_stats_bit && !control_stream_bit &&
      mmio_req_be[0] &&
      !(control_enable_candidate && fatal_error_axi);
  wire mmio_special_enable = mmio_enable_request && !stream_reset_busy_axi &&
                             !standalone_reset_rise_axi;
  wire mmio_special_stats = mmio_req_valid && mmio_req_write &&
      mmio_control_aligned && control_stats_bit && stats_legal_axi;
  wire mmio_illegal_stats = mmio_req_valid && mmio_req_write &&
      mmio_control_aligned && control_stats_bit && !stats_legal_axi;
  wire mmio_stream_accept = mmio_state == MMIO_IDLE && mmio_req_valid &&
      mmio_req_ready && mmio_req_write && mmio_control_aligned &&
      control_stream_bit;
  wire stats_stream_effective_axi = pending_stats_then_stream_axi ||
                                    standalone_reset_rise_axi;

  always_comb begin
    mmio_req_ready = 1'b0;
    case (mmio_state)
      MMIO_IDLE: begin
        if (!mmio_rsp_valid) begin
          if (mmio_enable_request || mmio_special_stats)
            mmio_req_ready = 1'b0;
          else
            mmio_req_ready = 1'b1;
        end
      end
      MMIO_WAIT_ENABLE:
        mmio_req_ready = (enable_ack_sync2_axi == enable_req_toggle_axi) &&
                         !enable_retry_after_reset_axi &&
                         !standalone_reset_rise_axi &&
                         !(pending_enable_value_axi && stream_reset_busy_axi);
      MMIO_WAIT_STATS:
        mmio_req_ready = (stats_ack_sync2_axi == stats_req_toggle_axi) &&
            (stats_stream_effective_axi ||
             (pending_stats_enable_axi && fatal_error_axi));
      default: mmio_req_ready = 1'b0;
    endcase
  end

  integer axi_slot_index;
  always_ff @(posedge axi_clk) begin : AXI_DOMAIN
    logic [3:0] commit_delta;
    logic [2:0] commit_delta_count;
    logic [1:0] commit_delta_slot;
    logic commit_enqueue;
    logic scheduler_pop;
    logic final_handshake;
    logic [5:0] requested_error_clear;
    logic fatal_clear_legal;
    logic event_overflow;
    logic event_drop;
    logic event_sequence;
    logic event_formatter;
    logic event_ownership;
    logic event_transport;
    logic event_stats_rejected;
    logic fatal_event_any;
    logic fatal_event_nonstats;
    logic hard_clear_event;
    logic hard_preclear_mask;
    logic [31:0] completion_reset_generation;
    logic [31:0] completion_fatal_generation;

    // Synchronizers and stable snapshot buses.
    enable_ack_sync1_axi <= enable_ack_toggle_source;
    enable_ack_sync2_axi <= enable_ack_sync1_axi;
    transport_ack_sync1_axi <= transport_ack_toggle_source;
    transport_ack_sync2_axi <= transport_ack_sync1_axi;
    stats_ack_sync1_axi <= stats_ack_toggle_source;
    stats_ack_sync2_axi <= stats_ack_sync1_axi;
    snapshot_ack_sync1_axi <= snapshot_ack_toggle_source;
    snapshot_ack_sync2_axi <= snapshot_ack_sync1_axi;
    own_ack_sync1_axi <= own_ack_toggle_source;
    own_ack_sync2_axi <= own_ack_sync1_axi;
    commit_sync1_axi <= commit_toggle_source;
    commit_sync2_axi <= commit_sync1_axi;
    ring_empty_sync1_axi <= ring_empty_source;
    ring_empty_sync2_axi <= ring_empty_sync1_axi;
    ring_full_sync1_axi <= ring_full_source;
    ring_full_sync2_axi <= ring_full_sync1_axi;
    source_ready_sync1_axi <= source_ready_live_source;
    source_ready_sync2_axi <= source_ready_sync1_axi;
    source_locked_sync1_axi <= source_locked_source;
    source_locked_sync2_axi <= source_locked_sync1_axi;
    overflow_sync1_axi <= source_overflow_event;
    overflow_sync2_axi <= overflow_sync1_axi;
    drop_sync1_axi <= source_drop_event;
    drop_sync2_axi <= drop_sync1_axi;
    formatter_fatal_sync1_axi <= source_formatter_fatal_event;
    formatter_fatal_sync2_axi <= formatter_fatal_sync1_axi;
    ownership_fatal_sync1_axi <= source_ownership_fatal_event;
    ownership_fatal_sync2_axi <= ownership_fatal_sync1_axi;
    standalone_req_sync1_axi <= standalone_req_toggle_source;
    standalone_req_sync2_axi <= standalone_req_sync1_axi;
    hard_event_clear_sync1_axi <= hard_event_clear_toggle_source;
    hard_event_clear_sync2_axi <= hard_event_clear_sync1_axi;
    hard_event_baseline_sync1_axi <= hard_event_baseline_hold_source;
    hard_event_baseline_sync2_axi <= hard_event_baseline_sync1_axi;
    snapshot_attempted_sync1_axi <= snapshot_attempted_gray_hold_source;
    snapshot_attempted_sync2_axi <= snapshot_attempted_sync1_axi;
    snapshot_committed_sync1_axi <= snapshot_committed_gray_hold_source;
    snapshot_committed_sync2_axi <= snapshot_committed_sync1_axi;
    snapshot_dropped_sync1_axi <= snapshot_dropped_gray_hold_source;
    snapshot_dropped_sync2_axi <= snapshot_dropped_sync1_axi;
    snapshot_overflow_sync1_axi <= snapshot_overflow_gray_hold_source;
    snapshot_overflow_sync2_axi <= snapshot_overflow_sync1_axi;
    snapshot_epoch_sync1_axi <= snapshot_epoch_echo_source;
    snapshot_epoch_sync2_axi <= snapshot_epoch_sync1_axi;

    commit_delta = commit_sync2_axi ^ commit_seen_axi;
    commit_delta_count = 3'b0;
    commit_delta_slot = 2'b0;
    for (axi_slot_index = 0; axi_slot_index < 4; axi_slot_index = axi_slot_index + 1) begin
      if (commit_delta[axi_slot_index]) begin
        commit_delta_count = commit_delta_count + 1'b1;
        commit_delta_slot = axi_slot_index[1:0];
      end
    end
    commit_enqueue = (commit_delta_count == 1) && !stream_reset_busy_axi && axi_aresetn;
    scheduler_pop = (axis_state == AXIS_IDLE) && (commit_fifo_count != 0) &&
                    !stream_reset_busy_axi && !mmio_stream_accept &&
                    !standalone_reset_rise_axi && !fatal_error_axi &&
                    (formatter_fatal_sync2_axi == formatter_seen_axi) &&
                    (ownership_fatal_sync2_axi == ownership_seen_axi) &&
                    !mmio_illegal_stats && axi_aresetn;
    final_handshake = (axis_state == AXIS_STREAM) && m_axis_c2h_tready &&
                      (axis_beat_index == 9'd511);
    hard_clear_event =
        hard_event_clear_sync2_axi != hard_event_clear_seen_axi;
    hard_preclear_mask = stream_reset_busy_axi && stream_reset_is_hard_axi &&
                         !hard_source_clear_observed_axi;
    event_overflow = (overflow_sync2_axi != overflow_seen_axi) &&
                     !hard_preclear_mask;
    event_drop = (drop_sync2_axi != drop_seen_axi) &&
                 !hard_preclear_mask;
    event_sequence = final_handshake && last_channel_valid_axi &&
                     axis_attempt != last_channel_axi + 1'b1;
    event_formatter = (formatter_fatal_sync2_axi != formatter_seen_axi) &&
                      !hard_preclear_mask;
    event_ownership = ((ownership_fatal_sync2_axi != ownership_seen_axi) &&
                       !hard_preclear_mask) ||
                      (!stream_reset_busy_axi && commit_delta_count > 1) ||
                      (commit_enqueue && commit_fifo_count == 4 &&
                       !scheduler_pop) ||
                      (axis_state == AXIS_WAIT_OWN &&
                       own_ack_sync2_axi == own_req_toggle_axi &&
                       !own_ok_hold_source);
    event_transport = 1'b0;
    event_stats_rejected = mmio_state == MMIO_IDLE && mmio_req_valid &&
                           mmio_req_ready && mmio_illegal_stats;
    fatal_event_any = event_formatter || event_ownership || event_transport ||
                      event_stats_rejected;
    fatal_event_nonstats = event_formatter || event_ownership || event_transport;
    completion_reset_generation = mmio_stream_accept ?
        (fatal_generation_axi + (event_stats_rejected ? 32'd1 : 32'd0)) :
        (standalone_reset_rise_axi ? fatal_generation_axi :
         reset_fatal_generation_hold_axi);
    completion_fatal_generation = fatal_generation_axi +
        (fatal_event_any ? 32'd1 : 32'd0);

    if (!axi_aresetn) begin
      mmio_rsp_valid <= 1'b0;
      mmio_state <= MMIO_IDLE;
      stored_enable_axi <= 1'b0;
      snapshot_busy_axi <= 1'b0;
      snapshot_valid_axi <= 1'b0;
      snapshot_ack_settled_axi <= 1'b0;
      snapshot_generation_axi <= 32'b0;
      shadow_records_attempted <= 32'b0;
      shadow_records_committed <= 32'b0;
      shadow_records_streamed <= 32'b0;
      shadow_records_dropped <= 32'b0;
      shadow_overflow_count <= 32'b0;
      shadow_discontinuities <= 32'b0;
      shadow_beats_streamed <= 64'b0;
      shadow_last_global <= 32'hffff_ffff;
      shadow_records_abandoned <= 32'b0;
      shadow_reset_events <= 32'b0;
      shadow_last_channel <= 32'hffff_ffff;
      shadow_last_global_valid <= 1'b0;
      shadow_last_channel_valid <= 1'b0;
      records_streamed_axi <= 32'b0;
      beats_streamed_axi <= 64'b0;
      discontinuities_axi <= 32'b0;
      records_abandoned_axi <= 32'b0;
      reset_events_axi <= 32'b0;
      last_global_axi <= 32'hffff_ffff;
      last_channel_axi <= 32'hffff_ffff;
      last_global_valid_axi <= 1'b0;
      last_channel_valid_axi <= 1'b0;
      global_stream_next_axi <= 32'b0;
      error_status_axi <= 6'b0;
      last_error_cause_axi <= 32'b0;
      fatal_clear_qualified_axi <= 1'b0;
      fatal_generation_axi <= 32'b0;
      reset_fatal_generation_hold_axi <= 32'b0;
      enable_retry_after_reset_axi <= 1'b0;
      axis_state <= AXIS_IDLE;
      axis_beat_index <= 9'b0;
      commit_fifo_head <= 2'b0;
      commit_fifo_tail <= 2'b0;
      commit_fifo_count <= 3'b0;
      overflow_seen_axi <= overflow_sync2_axi;
      drop_seen_axi <= drop_sync2_axi;
      formatter_seen_axi <= formatter_fatal_sync2_axi;
      ownership_seen_axi <= ownership_fatal_sync2_axi;
      standalone_req_seen_axi <= standalone_req_sync2_axi;
      hard_source_clear_observed_axi <= 1'b0;
      hard_event_clear_settle_axi <= 1'b0;
      if (!axi_seen_high)
        hard_event_clear_seen_axi <= hard_event_clear_sync2_axi;

      if (axi_seen_high && !axi_hard_episode) begin
        axi_hard_episode <= 1'b1;
        stream_reset_busy_axi <= 1'b1;
        stream_reset_is_hard_axi <= 1'b1;
        enable_value_hold_axi <= 1'b0;
        if (stream_reset_busy_axi) begin
          // A host/standalone request may already be crossing.  Do not toggle
          // it a second time and risk cancellation; follow it with a hard
          // clear using the same pending epoch before declaring completion.
          transport_followup_hard_axi <= 1'b1;
        end else begin
          transport_followup_hard_axi <= 1'b0;
          transport_epoch_hold_axi <= reset_epoch_axi + 1'b1;
          transport_hard_hold_axi <= 1'b1;
          transport_release_phase_hold_axi <= release_toggle_axi;
          transport_own_phase_hold_axi <= own_req_toggle_axi;
          transport_req_toggle_axi <= ~transport_req_toggle_axi;
        end
      end
    end else begin
      axi_seen_high <= 1'b1;

      // A standalone formatter/transport reset is an epoch-creating episode.
      // Its acknowledged source toggle is consumed once; any host or hard
      // cause overlapping the active reset coalesces into the same epoch.
      if (standalone_reset_rise_axi) begin
        standalone_req_seen_axi <= standalone_req_sync2_axi;
        stored_enable_axi <= 1'b0;
        if (mmio_state == MMIO_WAIT_ENABLE && pending_enable_value_axi)
          enable_retry_after_reset_axi <= 1'b1;
        if (mmio_state == MMIO_WAIT_STATS || mmio_special_stats) begin
          // Preserve the contract's clear-then-reset ordering when a
          // standalone cause overlaps an acknowledged statistics clear.
          pending_stats_then_stream_axi <= 1'b1;
        end else if (!stream_reset_busy_axi) begin
          stream_reset_busy_axi <= 1'b1;
          stream_reset_is_hard_axi <= 1'b0;
          transport_epoch_hold_axi <= reset_epoch_axi + 1'b1;
          transport_hard_hold_axi <= 1'b0;
          transport_followup_hard_axi <= 1'b0;
          transport_release_phase_hold_axi <= release_toggle_axi ^
              (final_handshake ? (4'b0001 << axis_slot) : 4'b0000);
          transport_own_phase_hold_axi <= own_req_toggle_axi;
          reset_fatal_generation_hold_axi <= fatal_generation_axi;
          transport_req_toggle_axi <= ~transport_req_toggle_axi;
          axis_state <= AXIS_IDLE;
          snapshot_busy_axi <= 1'b0;
          snapshot_valid_axi <= 1'b0;
          shadow_last_global <= 32'hffff_ffff;
          shadow_last_channel <= 32'hffff_ffff;
          shadow_last_global_valid <= 1'b0;
          shadow_last_channel_valid <= 1'b0;
        end else begin
          // This is a later reset issuance within the coalesced episode and
          // therefore qualifies fatal state already latched before the edge.
          reset_fatal_generation_hold_axi <= fatal_generation_axi;
        end
      end

      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;

      // Complete a hard or host transport reset only after source ack. A hard
      // episode additionally waits for synchronized axi_aresetn release.
      if (stream_reset_busy_axi &&
          transport_ack_sync2_axi == transport_req_toggle_axi &&
          commit_sync2_axi == reset_commit_phase_hold_source &&
          (!stream_reset_is_hard_axi || transport_followup_hard_axi ||
           hard_source_clear_observed_axi)) begin
        if (transport_followup_hard_axi) begin
          transport_followup_hard_axi <= 1'b0;
          transport_hard_hold_axi <= 1'b1;
          transport_release_phase_hold_axi <= release_toggle_axi;
          transport_own_phase_hold_axi <= own_req_toggle_axi;
          transport_req_toggle_axi <= ~transport_req_toggle_axi;
        end else begin
          reset_epoch_axi <= transport_epoch_hold_axi;
          global_stream_next_axi <= 32'b0;
          last_global_axi <= 32'hffff_ffff;
          last_channel_axi <= 32'hffff_ffff;
          last_global_valid_axi <= 1'b0;
          last_channel_valid_axi <= 1'b0;
          // A hard reset first clears statistics.  Only the non-hard transport
          // reset form retains prior counters and accounts discarded records.
          if (!stream_reset_is_hard_axi)
            records_abandoned_axi <= records_abandoned_axi + reset_abandoned_hold_source;
          if (stream_reset_is_hard_axi)
            reset_events_axi <= 32'd1;
          else
            reset_events_axi <= reset_events_axi + 1'b1;
          stream_reset_busy_axi <= 1'b0;
          stream_reset_is_hard_axi <= 1'b0;
          transport_followup_hard_axi <= 1'b0;
          commit_seen_axi <= reset_commit_phase_hold_source;
          commit_fifo_head <= 2'b0;
          commit_fifo_tail <= 2'b0;
          commit_fifo_count <= 3'b0;
          axis_state <= AXIS_IDLE;
          snapshot_busy_axi <= 1'b0;
          snapshot_valid_axi <= 1'b0;
          shadow_last_global <= 32'hffff_ffff;
          shadow_last_channel <= 32'hffff_ffff;
          shadow_last_global_valid <= 1'b0;
          shadow_last_channel_valid <= 1'b0;
          if (!axi_hard_episode)
            fatal_clear_qualified_axi <=
                (completion_fatal_generation ==
                 completion_reset_generation) &&
                !fatal_event_nonstats;
          axi_hard_episode <= 1'b0;
        end
      end

      // Source error events are toggle/level qualified so a sticky condition
      // cannot be lost while AXI software is stalled.
      if (hard_event_clear_settle_axi) begin
        // The clear token and baseline have independent synchronizers.  One
        // full AXI settling edge after token detection ensures every baseline
        // bit has reached sync2 before it retires the pre-clear event phases.
        overflow_seen_axi <= hard_event_baseline_sync2_axi[0];
        drop_seen_axi <= hard_event_baseline_sync2_axi[1];
        formatter_seen_axi <= hard_event_baseline_sync2_axi[2];
        ownership_seen_axi <= hard_event_baseline_sync2_axi[3];
        hard_source_clear_observed_axi <= 1'b1;
        hard_event_clear_settle_axi <= 1'b0;
      end else if (hard_clear_event) begin
        hard_event_clear_seen_axi <= hard_event_clear_sync2_axi;
        if (stream_reset_busy_axi && stream_reset_is_hard_axi)
          hard_event_clear_settle_axi <= 1'b1;
      end else if (hard_preclear_mask) begin
        overflow_seen_axi <= overflow_sync2_axi;
        drop_seen_axi <= drop_sync2_axi;
        formatter_seen_axi <= formatter_fatal_sync2_axi;
        ownership_seen_axi <= ownership_fatal_sync2_axi;
      end else if (overflow_sync2_axi != overflow_seen_axi) begin
        overflow_seen_axi <= overflow_sync2_axi;
        error_status_axi[0] <= 1'b1;
        last_error_cause_axi <= 32'd1;
      end
      if (!hard_preclear_mask &&
          drop_sync2_axi != drop_seen_axi) begin
        drop_seen_axi <= drop_sync2_axi;
        error_status_axi[1] <= 1'b1;
        if (overflow_sync2_axi == overflow_seen_axi)
          last_error_cause_axi <= 32'd2;
      end
      if (!hard_preclear_mask &&
          formatter_fatal_sync2_axi != formatter_seen_axi) begin
        formatter_seen_axi <= formatter_fatal_sync2_axi;
        error_status_axi[3] <= 1'b1;
        last_error_cause_axi <= 32'd4;
        stored_enable_axi <= 1'b0;
        fatal_clear_qualified_axi <= 1'b0;
      end
      if (!hard_preclear_mask &&
          ownership_fatal_sync2_axi != ownership_seen_axi) begin
        ownership_seen_axi <= ownership_fatal_sync2_axi;
        error_status_axi[4] <= 1'b1;
        last_error_cause_axi <= 32'd5;
        stored_enable_axi <= 1'b0;
        fatal_clear_qualified_axi <= 1'b0;
      end
      if (fatal_event_any) begin
        fatal_generation_axi <= fatal_generation_axi + 1'b1;
        fatal_clear_qualified_axi <= 1'b0;
      end

      // Coherent snapshot completion.  The acknowledgement and held Gray/epoch
      // payloads use independent two-stage synchronizers, so wait one complete
      // AXI settling edge after the acknowledgement first matches before
      // consuming every sync2 data bit. AXI-owned counters are captured on the
      // later completion edge as part of the same shadow generation.
      if (snapshot_busy_axi &&
          snapshot_ack_sync2_axi == snapshot_req_toggle_axi &&
          snapshot_epoch_sync2_axi == snapshot_epoch_hold_axi &&
          reset_epoch_axi == snapshot_epoch_hold_axi &&
          !stream_reset_busy_axi && !standalone_reset_rise_axi &&
          !mmio_stream_accept) begin
        if (!snapshot_ack_settled_axi) begin
          snapshot_ack_settled_axi <= 1'b1;
        end else begin
          shadow_records_attempted <= gray_to_binary32(snapshot_attempted_sync2_axi);
          shadow_records_committed <= gray_to_binary32(snapshot_committed_sync2_axi);
          shadow_records_dropped <= gray_to_binary32(snapshot_dropped_sync2_axi);
          shadow_overflow_count <= gray_to_binary32(snapshot_overflow_sync2_axi);
          shadow_records_streamed <= records_streamed_axi;
          shadow_beats_streamed <= beats_streamed_axi;
          shadow_discontinuities <= discontinuities_axi;
          shadow_records_abandoned <= records_abandoned_axi;
          shadow_reset_events <= reset_events_axi;
          shadow_last_global <= last_global_axi;
          shadow_last_channel <= last_channel_axi;
          shadow_last_global_valid <= last_global_valid_axi;
          shadow_last_channel_valid <= last_channel_valid_axi;
          snapshot_generation_axi <= snapshot_generation_axi + 1'b1;
          snapshot_busy_axi <= 1'b0;
          snapshot_valid_axi <= 1'b1;
          snapshot_ack_settled_axi <= 1'b0;
        end
      end else begin
        snapshot_ack_settled_axi <= 1'b0;
      end

      // Commit-order FIFO. The source emits at most one line commit per video
      // line; multiple simultaneous toggles are an ownership invariant error.
      if (!stream_reset_busy_axi) begin
        if (commit_delta_count > 1) begin
          commit_seen_axi <= commit_sync2_axi;
          error_status_axi[4] <= 1'b1;
          last_error_cause_axi <= 32'd5;
          stored_enable_axi <= 1'b0;
          fatal_clear_qualified_axi <= 1'b0;
        end else if (commit_enqueue) begin
          commit_seen_axi <= commit_sync2_axi;
          if (commit_fifo_count == 4 && !scheduler_pop) begin
            error_status_axi[4] <= 1'b1;
            last_error_cause_axi <= 32'd5;
            stored_enable_axi <= 1'b0;
            fatal_clear_qualified_axi <= 1'b0;
          end else begin
            commit_fifo[commit_fifo_tail] <= commit_delta_slot;
            commit_fifo_tail <= commit_fifo_tail + 1'b1;
          end
        end

        case ({commit_enqueue && !(commit_fifo_count == 4 && !scheduler_pop),
               scheduler_pop})
          2'b10: commit_fifo_count <= commit_fifo_count + 1'b1;
          2'b01: commit_fifo_count <= commit_fifo_count - 1'b1;
          default: ;
        endcase
        if (scheduler_pop)
          commit_fifo_head <= commit_fifo_head + 1'b1;
      end

      // Oldest committed record first. The source-domain acknowledged
      // transition establishes the single DMA owner before RAM prefetch.
      if (scheduler_pop) begin
        axis_slot <= commit_fifo[commit_fifo_head];
        axis_generation <= desc_generation_source[commit_fifo[commit_fifo_head]];
        axis_epoch <= desc_epoch_source[commit_fifo[commit_fifo_head]];
        axis_attempt <= desc_attempt_source[commit_fifo[commit_fifo_head]];
        own_slot_hold_axi <= commit_fifo[commit_fifo_head];
        own_generation_hold_axi <=
            desc_generation_source[commit_fifo[commit_fifo_head]];
        own_epoch_hold_axi <= desc_epoch_source[commit_fifo[commit_fifo_head]];
        own_req_toggle_axi <= ~own_req_toggle_axi;
        axis_state <= AXIS_WAIT_OWN;
      end

      if (axis_state == AXIS_WAIT_OWN && own_ack_sync2_axi == own_req_toggle_axi) begin
        if (own_ok_hold_source) begin
          if (fatal_error_axi || fatal_event_any) begin
            // No beat has been offered yet.  Preserve the newly DMA-owned
            // record intact and require stream-reset recovery instead of
            // publishing the next record after a fatal latch.
            axis_state <= AXIS_ERROR_HOLD;
          end else begin
            // Assignment occurs with the acknowledged COMMITTED -> DMA_OWNED
            // transition and remains locked through the final handshake.
            axis_global <= global_stream_next_axi;
            axis_beat_index <= 9'b0;
            axis_state <= AXIS_PREFETCH;
          end
        end else begin
          error_status_axi[4] <= 1'b1;
          last_error_cause_axi <= 32'd5;
          stored_enable_axi <= 1'b0;
          fatal_clear_qualified_axi <= 1'b0;
          axis_state <= AXIS_ERROR_HOLD;
        end
      end else if (axis_state == AXIS_PREFETCH) begin
        // A fatal which arrives after ownership acknowledgement but before
        // beat 0 is offered still blocks this next record.  Once AXIS_STREAM
        // begins, an integrity-valid in-flight record is allowed to finish.
        if (fatal_error_axi || fatal_event_any)
          axis_state <= AXIS_ERROR_HOLD;
        else
          axis_state <= AXIS_STREAM;
      end else if (axis_state == AXIS_STREAM && m_axis_c2h_tready) begin
        beats_streamed_axi <= beats_streamed_axi + 1'b1;
        if (axis_beat_index == 9'd511) begin
          records_streamed_axi <= records_streamed_axi + 1'b1;
          last_global_axi <= axis_global;
          last_channel_axi <= axis_attempt;
          last_global_valid_axi <= 1'b1;
          if (last_channel_valid_axi && axis_attempt != last_channel_axi + 1'b1) begin
            discontinuities_axi <= discontinuities_axi + 1'b1;
            error_status_axi[2] <= 1'b1;
            last_error_cause_axi <= 32'd3;
          end
          last_channel_valid_axi <= 1'b1;
          global_stream_next_axi <= global_stream_next_axi + 1'b1;
          release_generation_axi[axis_slot] <= axis_generation;
          release_epoch_axi[axis_slot] <= axis_epoch;
          release_toggle_axi[axis_slot] <= ~release_toggle_axi[axis_slot];
          axis_beat_index <= 9'b0;
          axis_state <= AXIS_IDLE;
        end else begin
          axis_beat_index <= axis_beat_index + 1'b1;
        end
      end

      // Launch special MMIO operations before request acceptance; the bridge
      // holds the original request stable until the acknowledged operation
      // raises mmio_req_ready.
      if (mmio_state == MMIO_IDLE && mmio_special_enable) begin
        pending_enable_value_axi <= control_enable_candidate;
        enable_value_hold_axi <= control_enable_candidate;
        enable_req_toggle_axi <= ~enable_req_toggle_axi;
        enable_retry_after_reset_axi <= 1'b0;
        mmio_state <= MMIO_WAIT_ENABLE;
      end else if (mmio_state == MMIO_IDLE && mmio_special_stats) begin
        pending_stats_then_stream_axi <= control_stream_bit ||
                                         standalone_reset_rise_axi;
        pending_stats_enable_axi <= control_enable_candidate;
        stats_req_toggle_axi <= ~stats_req_toggle_axi;
        mmio_state <= MMIO_WAIT_STATS;
      end

      // A standalone reset that overtook an already-launched enable request
      // makes the first acknowledgement stale with respect to reset. Reissue
      // the held enable value only after the reset episode has completed.
      if (mmio_state == MMIO_WAIT_ENABLE && enable_retry_after_reset_axi &&
          !stream_reset_busy_axi && !standalone_reset_rise_axi &&
          enable_ack_sync2_axi == enable_req_toggle_axi) begin
        enable_value_hold_axi <= pending_enable_value_axi;
        enable_req_toggle_axi <= ~enable_req_toggle_axi;
        enable_retry_after_reset_axi <= 1'b0;
      end

      if (mmio_state == MMIO_WAIT_ENABLE && mmio_req_valid && mmio_req_ready) begin
        if (!(pending_enable_value_axi &&
              (fatal_error_axi || stream_reset_busy_axi || fatal_event_any)))
          stored_enable_axi <= pending_enable_value_axi;
        enable_retry_after_reset_axi <= 1'b0;
        mmio_state <= MMIO_IDLE;
      end

      if (mmio_state == MMIO_WAIT_STATS && mmio_req_valid &&
          stats_ack_sync2_axi == stats_req_toggle_axi) begin
        records_streamed_axi <= 32'b0;
        beats_streamed_axi <= 64'b0;
        discontinuities_axi <= 32'b0;
        records_abandoned_axi <= 32'b0;
        reset_events_axi <= 32'b0;
        last_global_axi <= 32'hffff_ffff;
        last_channel_axi <= 32'hffff_ffff;
        last_global_valid_axi <= 1'b0;
        last_channel_valid_axi <= 1'b0;
        shadow_records_attempted <= 32'b0;
        shadow_records_committed <= 32'b0;
        shadow_records_streamed <= 32'b0;
        shadow_records_dropped <= 32'b0;
        shadow_overflow_count <= 32'b0;
        shadow_discontinuities <= 32'b0;
        shadow_beats_streamed <= 64'b0;
        shadow_last_global <= 32'hffff_ffff;
        shadow_records_abandoned <= 32'b0;
        shadow_reset_events <= 32'b0;
        shadow_last_channel <= 32'hffff_ffff;
        shadow_last_global_valid <= 1'b0;
        shadow_last_channel_valid <= 1'b0;
        snapshot_generation_axi <= 32'b0;
        snapshot_busy_axi <= 1'b0;
        snapshot_valid_axi <= 1'b0;
        last_error_cause_axi <= 32'b0;
        if (stats_stream_effective_axi && !stream_reset_busy_axi) begin
          stored_enable_axi <= 1'b0;
          stream_reset_busy_axi <= 1'b1;
          stream_reset_is_hard_axi <= 1'b0;
          transport_epoch_hold_axi <= reset_epoch_axi + 1'b1;
          transport_hard_hold_axi <= 1'b0;
          transport_followup_hard_axi <= 1'b0;
          transport_release_phase_hold_axi <= release_toggle_axi;
          transport_own_phase_hold_axi <= own_req_toggle_axi;
          reset_fatal_generation_hold_axi <= fatal_generation_axi;
          transport_req_toggle_axi <= ~transport_req_toggle_axi;
          mmio_state <= MMIO_IDLE;
        end else if (!(pending_stats_enable_axi && fatal_error_axi)) begin
          pending_enable_value_axi <= pending_stats_enable_axi;
          enable_value_hold_axi <= pending_stats_enable_axi;
          enable_req_toggle_axi <= ~enable_req_toggle_axi;
          enable_retry_after_reset_axi <= 1'b0;
          mmio_state <= MMIO_WAIT_ENABLE;
        end else begin
          mmio_state <= MMIO_IDLE;
        end
      end

      // Ordinary MMIO request acceptance.
      if (mmio_state == MMIO_IDLE && mmio_req_valid && mmio_req_ready) begin
        if (!mmio_req_write) begin
          mmio_rsp_rdata <= mmio_read_word(mmio_req_addr);
          mmio_rsp_valid <= 1'b1;
        end else if (mmio_req_addr[1:0] == 2'b00) begin
          if (mmio_control_aligned) begin
            if (control_stats_bit && !stats_legal_axi) begin
              error_status_axi[5] <= 1'b1;
              last_error_cause_axi <= 32'd7;
              stored_enable_axi <= 1'b0;
              fatal_clear_qualified_axi <= 1'b0;
            end
            if (control_stream_bit) begin
              stored_enable_axi <= 1'b0;
              if (!stream_reset_busy_axi) begin
                stream_reset_busy_axi <= 1'b1;
                stream_reset_is_hard_axi <= 1'b0;
                transport_epoch_hold_axi <= reset_epoch_axi + 1'b1;
                transport_hard_hold_axi <= 1'b0;
                transport_followup_hard_axi <= 1'b0;
                transport_release_phase_hold_axi <= release_toggle_axi ^
                    (final_handshake ? (4'b0001 << axis_slot) : 4'b0000);
                transport_own_phase_hold_axi <= own_req_toggle_axi;
                reset_fatal_generation_hold_axi <= fatal_generation_axi +
                    (event_stats_rejected ? 32'd1 : 32'd0);
                transport_req_toggle_axi <= ~transport_req_toggle_axi;
                axis_state <= AXIS_IDLE;
                snapshot_busy_axi <= 1'b0;
                snapshot_valid_axi <= 1'b0;
                shadow_last_global <= 32'hffff_ffff;
                shadow_last_channel <= 32'hffff_ffff;
                shadow_last_global_valid <= 1'b0;
                shadow_last_channel_valid <= 1'b0;
              end else begin
                // A later host reset command coalesces without another epoch,
                // but it still satisfies the "issued after fatal" ordering.
                reset_fatal_generation_hold_axi <= fatal_generation_axi +
                    (event_stats_rejected ? 32'd1 : 32'd0);
              end
            end else if (!control_stats_bit &&
                         !(control_enable_candidate && fatal_error_axi)) begin
              stored_enable_axi <= control_enable_candidate;
            end
          end else if (mmio_error_aligned) begin
            requested_error_clear = mmio_req_be[0] ? mmio_req_wdata[5:0] : 6'b0;
            fatal_clear_legal = fatal_clear_qualified_axi && !stored_enable_axi &&
                                !c2h_active_axi && ring_empty_axi &&
                                !stream_reset_busy_axi;
            error_status_axi[2:0] <= error_status_axi[2:0] &
                                           ~requested_error_clear[2:0];
            if (fatal_clear_legal)
              error_status_axi[5:3] <= error_status_axi[5:3] &
                                             ~requested_error_clear[5:3];
          end else if (mmio_snapshot_aligned && mmio_req_be[0] &&
                       mmio_req_wdata[0] && !snapshot_busy_axi &&
                       !stream_reset_busy_axi) begin
            snapshot_busy_axi <= 1'b1;
            snapshot_valid_axi <= 1'b0;
            snapshot_epoch_hold_axi <= reset_epoch_axi;
            snapshot_req_toggle_axi <= ~snapshot_req_toggle_axi;
          end
        end
      end

      // Event-set wins over same-cycle W1C.
      if (event_overflow)
        error_status_axi[0] <= 1'b1;
      if (event_drop)
        error_status_axi[1] <= 1'b1;
      if (event_sequence)
        error_status_axi[2] <= 1'b1;
      if (event_formatter)
        error_status_axi[3] <= 1'b1;
      if (event_ownership)
        error_status_axi[4] <= 1'b1;
      if (event_transport || event_stats_rejected)
        error_status_axi[5] <= 1'b1;

      // LAST_ERROR_CAUSE uses the frozen simultaneous-event priority,
      // independent of the textual order of the state-machine assignments.
      if (event_stats_rejected)
        last_error_cause_axi <= 32'd7;
      else if (event_transport)
        last_error_cause_axi <= 32'd6;
      else if (event_ownership)
        last_error_cause_axi <= 32'd5;
      else if (event_formatter)
        last_error_cause_axi <= 32'd4;
      else if (event_sequence)
        last_error_cause_axi <= 32'd3;
      else if (event_overflow)
        last_error_cause_axi <= 32'd1;
      else if (event_drop)
        last_error_cause_axi <= 32'd2;

      // A coincident standalone reset may invalidate a snapshot accepted on
      // the same documented pre-write BUSY state. Reset invalidation wins the
      // resulting state without adding an undocumented acceptance condition.
      if (standalone_reset_rise_axi) begin
        snapshot_busy_axi <= 1'b0;
        snapshot_valid_axi <= 1'b0;
      end
    end
  end

endmodule
