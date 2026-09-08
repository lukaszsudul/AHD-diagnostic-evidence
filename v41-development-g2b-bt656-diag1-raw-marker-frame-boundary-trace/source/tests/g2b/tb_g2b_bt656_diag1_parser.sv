`timescale 1ns/1ps

module tb_g2b_bt656_diag1_parser;
  localparam logic [31:0] FLAG_SOF = 32'h0000_0001;
  localparam logic [31:0] FLAG_VALID = 32'h0000_0020;

  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;

  logic core_req_valid = 1'b0;
  logic core_req_ready;
  logic core_req_write = 1'b0;
  logic [16:0] core_req_addr = '0;
  logic [31:0] core_req_wdata = '0;
  logic [3:0] core_req_be = '0;
  logic core_rsp_valid;
  logic core_rsp_ready = 1'b1;
  logic [31:0] core_rsp_rdata;

  logic trace_req_valid = 1'b0;
  logic trace_req_ready;
  logic trace_req_write = 1'b0;
  logic [16:0] trace_req_addr = '0;
  logic [31:0] trace_req_wdata = '0;
  logic [3:0] trace_req_be = '0;
  logic trace_rsp_valid;
  logic trace_rsp_ready = 1'b1;
  logic [31:0] trace_rsp_rdata;

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
  integer malformed_reason_count [0:15];
  integer drop_reason_count [0:15];
  integer marker_alignment_hits = 0;
  integer record_count = 0;
  integer beat_index = 0;
  logic [31:0] record_frame [0:7];
  logic [31:0] record_line [0:7];
  logic [31:0] record_flags [0:7];

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h core (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(core_req_valid), .mmio_req_ready(core_req_ready),
    .mmio_req_write(core_req_write), .mmio_req_addr(core_req_addr),
    .mmio_req_wdata(core_req_wdata), .mmio_req_be(core_req_be),
    .mmio_rsp_valid(core_rsp_valid), .mmio_rsp_ready(core_rsp_ready),
    .mmio_rsp_rdata(core_rsp_rdata),
    .bt656_diag_event_valid(diag_event_valid),
    .bt656_diag_trigger_pulse(diag_trigger_pulse),
    .bt656_diag_next_frame_line1_commit(diag_next_frame_line1_commit),
    .bt656_diag_event_payload(diag_event_payload),
    .m_axis_c2h_tdata(axis_data), .m_axis_c2h_tkeep(axis_keep),
    .m_axis_c2h_tlast(axis_last), .m_axis_c2h_tvalid(axis_valid),
    .m_axis_c2h_tready(axis_ready)
  );

  g2b_bt656_boundary_trace trace (
    .source_clk(source_clk), .source_reset(source_reset),
    .event_valid(diag_event_valid), .trigger_pulse(diag_trigger_pulse),
    .next_frame_line1_commit(diag_next_frame_line1_commit),
    .event_payload(diag_event_payload),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .mmio_req_valid(trace_req_valid), .mmio_req_ready(trace_req_ready),
    .mmio_req_write(trace_req_write), .mmio_req_addr(trace_req_addr),
    .mmio_req_wdata(trace_req_wdata), .mmio_req_be(trace_req_be),
    .mmio_rsp_valid(trace_rsp_valid), .mmio_rsp_ready(trace_rsp_ready),
    .mmio_rsp_rdata(trace_rsp_rdata)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("BT656_DIAG1_PARSER_FAIL time=%0t %s", $time, message);
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
        drive_source_byte(8'h55 ^ i[7:0]);
    end
  endtask

  task automatic send_payload(input logic [7:0] seed);
    integer i;
    begin
      for (i = 0; i < 3840; i = i + 1)
        drive_source_byte(seed + i[7:0]);
    end
  endtask

  task automatic send_valid_line(input logic [7:0] seed);
    begin
      send_marker(8'h80);
      send_payload(seed);
      send_marker(8'h90);
      send_gap(16);
    end
  endtask

  task automatic send_project_vblank;
    begin
      send_marker(8'ha0);
      send_marker(8'hb0);
      send_gap(8);
    end
  endtask

  task automatic core_write(input logic [16:0] address,
                            input logic [31:0] data);
    begin
      @(negedge axi_clk);
      core_req_addr = address;
      core_req_wdata = data;
      core_req_be = 4'hf;
      core_req_write = 1'b1;
      core_req_valid = 1'b1;
      do @(posedge axi_clk); while (!core_req_ready);
      @(negedge axi_clk);
      core_req_valid = 1'b0;
      core_req_write = 1'b0;
      core_req_addr = '0;
      core_req_wdata = '0;
      core_req_be = '0;
    end
  endtask

  task automatic trace_write(input logic [16:0] address,
                             input logic [31:0] data);
    begin
      @(negedge axi_clk);
      trace_req_addr = address;
      trace_req_wdata = data;
      trace_req_be = 4'hf;
      trace_req_write = 1'b1;
      trace_req_valid = 1'b1;
      do @(posedge axi_clk); while (!trace_req_ready);
      @(negedge axi_clk);
      trace_req_valid = 1'b0;
      trace_req_write = 1'b0;
      trace_req_addr = '0;
      trace_req_wdata = '0;
      trace_req_be = '0;
    end
  endtask

  task automatic trace_read(input logic [16:0] address,
                            output logic [31:0] data);
    begin
      @(negedge axi_clk);
      trace_req_addr = address;
      trace_req_write = 1'b0;
      trace_req_valid = 1'b1;
      do @(posedge axi_clk); while (!trace_req_ready);
      @(negedge axi_clk);
      trace_req_valid = 1'b0;
      trace_req_addr = '0;
      do @(posedge axi_clk); while (!trace_rsp_valid);
      data = trace_rsp_rdata;
      @(negedge axi_clk);
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

  task automatic wait_trace_status(input integer bit_index,
                                   input logic value);
    logic [31:0] status;
    integer tries;
    begin
      status = '0;
      for (tries = 0; tries < 2000 && status[bit_index] != value;
           tries = tries + 1)
        trace_read(17'h03c10, status);
      if (status[bit_index] != value)
        fail($sformatf("trace status bit %0d timeout status=%08x",
                       bit_index, status));
    end
  endtask

  task automatic read_trace_word(input integer entry_index,
                                 input integer word_index,
                                 output logic [31:0] data);
    logic [31:0] ready;
    integer tries;
    begin
      trace_write(17'h03c38, entry_index);
      ready = '0;
      for (tries = 0; tries < 100 && !ready[0]; tries = tries + 1)
        trace_read(17'h03c3c, ready);
      if (!ready[0]) begin
        fail("trace entry read timeout");
        data = 'x;
      end else begin
        trace_read(17'h03c40 + word_index*4, data);
      end
    end
  endtask

  always @(posedge source_clk) begin : DIAG_OBSERVER
    integer malformed_reason;
    integer drop_reason;
    if (diag_event_valid) begin
      malformed_reason = diag_event_payload[15*32 + 21 +: 4];
      drop_reason = diag_event_payload[15*32 + 25 +: 4];
      if (diag_event_payload[3*32 + 6]) begin
        if (malformed_reason == 0)
          fail("malformed increment without reason");
        else
          malformed_reason_count[malformed_reason] =
              malformed_reason_count[malformed_reason] + 1;
      end else if (malformed_reason != 0) begin
        fail("malformed reason without increment");
      end
      if (diag_event_payload[3*32 + 7]) begin
        if (drop_reason == 0)
          fail("drop increment without reason");
        else
          drop_reason_count[drop_reason] = drop_reason_count[drop_reason] + 1;
      end else if (drop_reason != 0) begin
        fail("drop reason without increment");
      end
      if (diag_event_payload[3*32 + 0] &&
          diag_event_payload[2*32 +: 32] == 32'h9000_00ff &&
          diag_event_payload[3*32 + 4] &&
          diag_event_payload[3*32 + 5])
        marker_alignment_hits = marker_alignment_hits + 1;
    end
  end

  always @(posedge axi_clk) begin
    if (axis_valid && axis_ready) begin
      if (record_count < 8) begin
        case (beat_index)
          1: record_frame[record_count] <= axis_data[63:32];
          2: record_line[record_count] <= axis_data[31:0];
          3: record_flags[record_count] <= axis_data[63:32];
        endcase
      end
      if (axis_last) begin
        if (beat_index != 511)
          fail($sformatf("record TLAST beat=%0d", beat_index));
        record_count <= record_count + 1;
        beat_index <= 0;
      end else begin
        beat_index <= beat_index + 1;
      end
    end
  end

  initial begin : RUN
    integer i;
    integer initial_record_count;
    integer mal_before_boundary;
    logic [31:0] value;
    logic found_line0_commit;
    logic found_line1_stop;

    for (i = 0; i < 16; i = i + 1) begin
      malformed_reason_count[i] = 0;
      drop_reason_count[i] = 0;
    end

    reset_core();

    // T2 uses the parser's actual four-byte detector pipeline, rather than a
    // constructed trace payload.
    send_marker(8'h90);
    send_gap(4);
    if (marker_alignment_hits != 1)
      fail($sformatf("exact marker alignment hit count=%0d",
                     marker_alignment_hits));
    $display("BT656_DIAG1_T2_PARSER_PASS exact_detector_window");

    // Reachable malformed site 2: a qualified but unexpected SAV where EAV
    // is required after one exact payload.
    reset_core();
    send_marker(8'h80);
    send_payload(8'h10);
    send_marker(8'h80);
    send_gap(8);

    // Reachable malformed site 3: no EAV inside the four-byte post-payload
    // window.
    reset_core();
    send_marker(8'h80);
    send_payload(8'h20);
    send_gap(12);

    // Reachable malformed site 1 and independent source-drop reason 2: after
    // a valid disabled line establishes lock, an admitted line is aborted by
    // an early qualified marker.
    reset_core();
    send_valid_line(8'h30);
    core_write(17'h0380c, 32'h0000_0001);
    repeat (12) @(posedge source_clk);
    send_marker(8'h80);
    send_gap(24);
    send_marker(8'h90);
    send_gap(8);

    // Independent source-drop reason 1: hold AXIS backpressure while four
    // complete lines fill the unchanged functional ring, then present a fifth
    // active SAV. No internal functional state is forced.
    reset_core();
    send_valid_line(8'h40);
    core_write(17'h0380c, 32'h0000_0001);
    repeat (12) @(posedge source_clk);
    axis_ready = 1'b0;
    send_valid_line(8'h41);
    send_valid_line(8'h42);
    send_valid_line(8'h43);
    send_valid_line(8'h44);
    send_marker(8'h80);
    send_gap(6);
    axis_ready = 1'b1;
    repeat (8) @(posedge source_clk);

    if (malformed_reason_count[1] < 1 ||
        malformed_reason_count[2] < 1 ||
        malformed_reason_count[3] < 1)
      fail($sformatf("malformed coverage r1=%0d r2=%0d r3=%0d",
                     malformed_reason_count[1], malformed_reason_count[2],
                     malformed_reason_count[3]));
    $display("BT656_DIAG1_T5_PASS malformed_reason_1_2_3_exact");
    if (drop_reason_count[1] < 1 || drop_reason_count[2] < 1)
      fail($sformatf("drop coverage ring=%0d malformed=%0d",
                     drop_reason_count[1], drop_reason_count[2]));
    $display("BT656_DIAG1_T6_PASS ring_full_and_malformed_drop_independent");

    // T4: start afresh, reproduce the existing project VBI fixture, and let
    // the trace trigger on line-1079 EAV then freeze on next-frame line-1
    // commit. The full disabled synthetic frame establishes parser history.
    reset_core();
    record_count = 0;
    beat_index = 0;
    for (i = 0; i < 1078; i = i + 1)
      send_valid_line(i[7:0]);
    trace_write(17'h03c0c, 32'h0000_0001);
    wait_trace_status(0, 1'b0);
    trace_write(17'h03c0c, 32'h0000_0002);
    wait_trace_status(0, 1'b1);
    send_valid_line(8'hf6);
    send_valid_line(8'hf7);
    if (core.source_line_sequence !== 32'd1079)
      fail($sformatf("expected line1079 got %0d",
                     core.source_line_sequence));
    mal_before_boundary = core.source_lifetime_malformed;
    send_project_vblank();
    core_write(17'h0380c, 32'h0000_0001);
    repeat (12) @(posedge source_clk);
    initial_record_count = record_count;
    send_valid_line(8'hc0);
    send_valid_line(8'hc1);
    while (record_count < initial_record_count + 2)
      @(posedge axi_clk);
    wait_trace_status(2, 1'b1);

    if (core.source_lifetime_malformed != mal_before_boundary)
      fail("project VBI boundary caused malformed increment");
    if (record_frame[initial_record_count] !== 32'd2 ||
        record_line[initial_record_count] !== 32'd0 ||
        (record_flags[initial_record_count] & (FLAG_VALID | FLAG_SOF)) !==
        (FLAG_VALID | FLAG_SOF))
      fail("next-frame line0/SOF record mismatch");
    if (record_frame[initial_record_count+1] !== 32'd2 ||
        record_line[initial_record_count+1] !== 32'd1)
      fail("next-frame line1 record mismatch");
    trace_read(17'h03c24, value);
    if (value !== 1) fail("trace did not stop on next-frame line1 commit");
    trace_read(17'h03c2c, value);
    if (value !== 1079) fail("trace trigger line was not 1079");

    found_line0_commit = 1'b0;
    found_line1_stop = 1'b0;
    trace_read(17'h03c14, value);
    for (i = 0; i < value; i = i + 1) begin
      logic [31:0] bits;
      logic [31:0] frame_value;
      logic [31:0] line_value;
      logic [31:0] flags_value;
      read_trace_word(i, 3, bits);
      if (bits[8]) begin
        read_trace_word(i, 4, frame_value);
        read_trace_word(i, 5, line_value);
        read_trace_word(i, 14, flags_value);
        if (frame_value == 2 && line_value == 0 &&
            (flags_value & (FLAG_VALID | FLAG_SOF)) ==
            (FLAG_VALID | FLAG_SOF))
          found_line0_commit = 1'b1;
        if (frame_value == 2 && line_value == 1 && bits[22])
          found_line1_stop = 1'b1;
      end
    end
    if (!found_line0_commit || !found_line1_stop)
      fail($sformatf("boundary entries line0=%0b line1stop=%0b",
                     found_line0_commit, found_line1_stop));
    $display("BT656_DIAG1_T4_PASS line1079_eav_next_frame_line0_line1_stop malformed=0");

    if (errors == 0)
      $display("BT656_DIAG1_PARSER_XSIM_PASS");
    else
      $fatal(1, "BT656_DIAG1_PARSER_XSIM_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
