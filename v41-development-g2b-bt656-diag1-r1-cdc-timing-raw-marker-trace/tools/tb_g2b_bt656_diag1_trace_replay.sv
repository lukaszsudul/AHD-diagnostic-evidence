`timescale 1ns/1ps

// Replays the physical DIAG1-R1 marker sequence and marker-to-marker source
// clock intervals against the current, uncorrected PRODUCT parser.  A
// canonical clean prehistory establishes line 1078 and lock.  The replay is
// therefore functionally equivalent rather than an attempt to clone the
// hardware's lifetime counters or disabled trace session.
module tb_g2b_bt656_diag1_trace_replay;
  localparam logic [31:0] FLAG_DISCONTINUITY = 32'h0000_0004;
  localparam logic [31:0] FLAG_MALFORMED_PRECEDING = 32'h0000_0010;
  localparam logic [31:0] FLAG_VALID = 32'h0000_0020;

  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;

  logic req_valid = 1'b0;
  logic req_ready;
  logic req_write = 1'b0;
  logic [16:0] req_addr = '0;
  logic [31:0] req_wdata = '0;
  logic [3:0] req_be = '0;
  logic rsp_valid;
  logic rsp_ready = 1'b1;
  logic [31:0] rsp_rdata;

  logic diag_event_valid;
  logic diag_trigger_pulse;
  logic diag_next_frame_line1_commit;
  logic [511:0] diag_event_payload;
  logic [63:0] axis_data;
  logic [7:0] axis_keep;
  logic axis_last;
  logic axis_valid;
  logic axis_ready = 1'b1;

  integer errors = 0;
  integer replay_active = 0;
  integer replay_malformed = 0;
  integer replay_malformed_reason2 = 0;
  integer replay_drops = 0;
  integer replay_drop_reason2 = 0;
  integer replay_commits = 0;
  integer replay_line0_commits = 0;
  integer replay_line1_commits = 0;
  integer replay_line0_sav = 0;
  integer replay_line0_attempt = 0;
  integer replay_lock_loss = 0;
  integer replay_lock_reacquire = 0;
  logic [31:0] replay_line1_flags = '0;

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h core (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(req_valid), .mmio_req_ready(req_ready),
    .mmio_req_write(req_write), .mmio_req_addr(req_addr),
    .mmio_req_wdata(req_wdata), .mmio_req_be(req_be),
    .mmio_rsp_valid(rsp_valid), .mmio_rsp_ready(rsp_ready),
    .mmio_rsp_rdata(rsp_rdata),
    .bt656_diag_event_valid(diag_event_valid),
    .bt656_diag_trigger_pulse(diag_trigger_pulse),
    .bt656_diag_next_frame_line1_commit(diag_next_frame_line1_commit),
    .bt656_diag_event_payload(diag_event_payload),
    .m_axis_c2h_tdata(axis_data), .m_axis_c2h_tkeep(axis_keep),
    .m_axis_c2h_tlast(axis_last), .m_axis_c2h_tvalid(axis_valid),
    .m_axis_c2h_tready(axis_ready)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("BT656_DIAG1_TRACE_REPLAY_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic drive_source_byte(input logic [7:0] value);
    begin
      @(negedge source_clk);
      source_byte = value;
    end
  endtask

  task automatic send_marker(input logic [7:0] xy);
    begin
      drive_source_byte(8'hff);
      drive_source_byte(8'h00);
      drive_source_byte(8'h00);
      drive_source_byte(xy);
    end
  endtask

  task automatic send_gap(input integer count);
    integer i;
    begin
      for (i = 0; i < count; i = i + 1)
        drive_source_byte(8'h55);
    end
  endtask

  task automatic send_clean_line;
    begin
      send_marker(8'h80);
      send_gap(3840);
      send_marker(8'h90);
      send_gap(16);
    end
  endtask

  task automatic core_write(input logic [16:0] address,
                            input logic [31:0] data);
    begin
      @(negedge axi_clk);
      req_addr = address;
      req_wdata = data;
      req_be = 4'hf;
      req_write = 1'b1;
      req_valid = 1'b1;
      do @(posedge axi_clk); while (!req_ready);
      @(negedge axi_clk);
      req_valid = 1'b0;
      req_write = 1'b0;
      req_addr = '0;
      req_wdata = '0;
      req_be = '0;
    end
  endtask

  task automatic reset_core;
    begin
      @(negedge source_clk); source_reset = 1'b1;
      @(negedge axi_clk); axi_aresetn = 1'b0;
      repeat (12) @(posedge source_clk);
      repeat (8) @(posedge axi_clk);
      @(negedge source_clk); source_reset = 1'b0;
      @(negedge axi_clk); axi_aresetn = 1'b1;
      repeat (24) @(posedge axi_clk);
      source_byte = 8'h55;
    end
  endtask

  always @(posedge source_clk) begin : REPLAY_OBSERVER
    integer reason;
    integer drop_reason;
    logic [2:0] state_after;
    logic [31:0] pending_line;
    logic [31:0] pending_frame;
    logic [31:0] flags;
    if (replay_active && diag_event_valid) begin
      reason = diag_event_payload[15*32 + 21 +: 4];
      drop_reason = diag_event_payload[15*32 + 25 +: 4];
      state_after = diag_event_payload[3*32 + 28 +: 3];
      pending_frame = diag_event_payload[8*32 +: 32];
      pending_line = diag_event_payload[9*32 +: 32];
      flags = diag_event_payload[14*32 +: 32];
      if (diag_event_payload[3*32 + 6]) begin
        replay_malformed = replay_malformed + 1;
        $display("REPLAY_MALFORMED ordinal=%0d reason=%0d frame=%0d line=%0d state_after=%0d time=%0t",
                 replay_malformed, reason, pending_frame, pending_line,
                 state_after, $time);
        if (reason == 2)
          replay_malformed_reason2 = replay_malformed_reason2 + 1;
      end
      if (diag_event_payload[3*32 + 7]) begin
        replay_drops = replay_drops + 1;
        $display("REPLAY_DROP ordinal=%0d reason=%0d frame=%0d line=%0d time=%0t",
                 replay_drops, drop_reason, pending_frame, pending_line,
                 $time);
        if (drop_reason == 2)
          replay_drop_reason2 = replay_drop_reason2 + 1;
      end
      if (diag_event_payload[3*32 + 13] &&
          !diag_event_payload[3*32 + 14])
        replay_lock_loss = replay_lock_loss + 1;
      if (!diag_event_payload[3*32 + 13] &&
          diag_event_payload[3*32 + 14])
        replay_lock_reacquire = replay_lock_reacquire + 1;
      if (diag_event_payload[3*32 + 0] &&
          diag_event_payload[3*32 + 1] &&
          !diag_event_payload[3*32 + 3] &&
          !diag_event_payload[3*32 + 4] &&
          diag_event_payload[3*32 + 12] &&
          !diag_event_payload[3*32 + 13] &&
          state_after == 3'd1) begin
        replay_line0_sav = replay_line0_sav + 1;
        if (diag_event_payload[3*32 + 15])
          replay_line0_attempt = replay_line0_attempt + 1;
      end
      if (diag_event_payload[3*32 + 8]) begin
        replay_commits = replay_commits + 1;
        if (pending_frame == 2 && pending_line == 0)
          replay_line0_commits = replay_line0_commits + 1;
        if (pending_frame == 2 && pending_line == 1) begin
          replay_line1_commits = replay_line1_commits + 1;
          replay_line1_flags = flags;
        end
      end
    end
  end

  initial begin : RUN
    integer i;
    integer fixture;
    integer got;
    integer logical_index;
    integer gap_to_next;
    integer ready_value;
    integer replay_markers;
    reg [7:0] xy;
    reg [8*512-1:0] fixture_path;
    reg [8*512-1:0] header_line;

    reset_core();

    // Establish the same boundary state as the hardware: frame 1, line 1078,
    // parser locked, no in-flight attempt.  This prefix is canonical rather
    // than captured; the exact captured replay begins at logical entry 31.
    for (i = 0; i < 1079; i = i + 1)
      send_clean_line();
    if (core.source_line_sequence !== 32'd1078)
      fail($sformatf("prehistory line expected 1078 got %0d",
                     core.source_line_sequence));
    if (core.source_locked_source !== 1'b1)
      fail("prehistory did not establish source lock");

    core_write(17'h0380c, 32'h0000_0001);
    for (i = 0; i < 100 && !core.enable_applied_source; i = i + 1)
      @(posedge source_clk);
    if (!core.enable_applied_source)
      fail("enable did not reach source domain");

    if (!$value$plusargs("FIXTURE=%s", fixture_path))
      fixture_path = "trace-replay-fixture.txt";
    fixture = $fopen(fixture_path, "r");
    if (fixture == 0)
      $fatal(1, "cannot open replay fixture %s", fixture_path);
    got = $fgets(header_line, fixture);
    if (got == 0)
      $fatal(1, "cannot read replay fixture header");

    replay_active = 1;
    replay_markers = 0;
    while (!$feof(fixture)) begin
      got = $fscanf(fixture, "%d %h %d %d\n",
                    logical_index, xy, gap_to_next, ready_value);
      if (got == 4) begin
        source_ready = ready_value[0];
        send_marker(xy);
        send_gap(gap_to_next);
        replay_markers = replay_markers + 1;
      end else if (!$feof(fixture)) begin
        $fatal(1, "malformed fixture row after %0d markers", replay_markers);
      end
    end
    $fclose(fixture);
    // The hardware trace froze 2884 source clocks after the final captured
    // SAV, before this partial line could reach the parser's missing-EAV
    // timeout.  End replay observation at the identical boundary; later
    // simulator clocks are used only to drain already committed AXIS data.
    replay_active = 0;
    repeat (64) @(posedge source_clk);
    repeat (2048) @(posedge axi_clk);

    if (replay_markers != 115)
      fail($sformatf("expected 115 captured markers got %0d", replay_markers));
    if (replay_malformed != 21 || replay_malformed_reason2 != 21)
      fail($sformatf("malformed total=%0d reason2=%0d",
                     replay_malformed, replay_malformed_reason2));
    if (replay_drops != 1 || replay_drop_reason2 != 1)
      fail($sformatf("drop total=%0d reason2=%0d",
                     replay_drops, replay_drop_reason2));
    if (replay_lock_loss != 1)
      fail($sformatf("lock loss count=%0d", replay_lock_loss));
    if (replay_lock_reacquire != 1)
      fail($sformatf("lock reacquire count=%0d", replay_lock_reacquire));
    if (replay_line0_sav != 1 || replay_line0_attempt != 0)
      fail($sformatf("line0 SAV=%0d attempt=%0d",
                     replay_line0_sav, replay_line0_attempt));
    if (replay_line0_commits != 0)
      fail($sformatf("line0 commits=%0d", replay_line0_commits));
    if (replay_line1_commits != 1)
      fail($sformatf("line1 commits=%0d", replay_line1_commits));
    if (replay_line1_flags !=
        (FLAG_VALID | FLAG_DISCONTINUITY | FLAG_MALFORMED_PRECEDING))
      fail($sformatf("line1 flags expected 00000034 got %08x",
                     replay_line1_flags));

    if (errors == 0) begin
      $display("BT656_DIAG1_TRACE_REPLAY_PASS markers=%0d malformed=%0d reason2=%0d drops=%0d drop_reason2=%0d lock_loss=%0d lock_reacquire=%0d line0_sav=%0d line0_attempt=%0d line0_commit=%0d line1_commit=%0d line1_flags=%08x",
               replay_markers, replay_malformed, replay_malformed_reason2,
               replay_drops, replay_drop_reason2, replay_lock_loss,
               replay_lock_reacquire, replay_line0_sav, replay_line0_attempt,
               replay_line0_commits, replay_line1_commits,
               replay_line1_flags);
    end else begin
      $fatal(1, "BT656_DIAG1_TRACE_REPLAY_XSIM_FAIL errors=%0d", errors);
    end
    $finish;
  end
endmodule
