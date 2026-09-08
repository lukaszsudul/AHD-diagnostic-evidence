`timescale 1ns/1ps

// Regression derived from the DIAG1-R1 hardware marker trace.  It establishes
// a canonical prehistory through line 1078, then reproduces the captured
// line-1079, 21 V-low vertical-tail lines, V-high interval, next-frame lines
// 0..10, and the captured partial line 11 using the observed 1436/3844 marker
// spacing.  No internal parser state is forced.
module tb_g2b_bt656_line0_sof_fix;
  localparam logic [31:0] RECORD_MAGIC = 32'h4c44_4841;
  localparam logic [31:0] RECORD_VERSION = 32'h0000_4101;
  localparam logic [31:0] FLAG_SOF = 32'h0000_0001;
  localparam logic [31:0] FLAG_DISCONTINUITY = 32'h0000_0004;
  localparam logic [31:0] FLAG_OVERFLOW = 32'h0000_0008;
  localparam logic [31:0] FLAG_MALFORMED = 32'h0000_0010;
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
  logic [63:0] axis_data;
  logic [7:0] axis_keep;
  logic axis_last;
  logic axis_valid;
  logic axis_ready = 1'b1;

  integer errors = 0;
  integer beat_index = 0;
  integer record_count = 0;
  integer lane;
  logic [31:0] record_frame [0:15];
  logic [31:0] record_line [0:15];
  logic [31:0] record_flags [0:15];

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h dut (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(req_valid), .mmio_req_ready(req_ready),
    .mmio_req_write(req_write), .mmio_req_addr(req_addr),
    .mmio_req_wdata(req_wdata), .mmio_req_be(req_be),
    .mmio_rsp_valid(rsp_valid), .mmio_rsp_ready(rsp_ready),
    .mmio_rsp_rdata(rsp_rdata),
    .m_axis_c2h_tdata(axis_data), .m_axis_c2h_tkeep(axis_keep),
    .m_axis_c2h_tlast(axis_last), .m_axis_c2h_tvalid(axis_valid),
    .m_axis_c2h_tready(axis_ready)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("G2B_BT656_LINE0_SOF_FIX_FAIL time=%0t %s", $time, message);
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

  task automatic send_canonical_line;
    begin
      send_marker(8'h80);
      send_gap(3840);
      send_marker(8'h90);
      send_gap(16);
    end
  endtask

  task automatic send_captured_active_line(input logic [7:0] eav_xy);
    begin
      send_marker(8'h80);
      send_gap(3840);
      send_marker(eav_xy);
      send_gap(1432);
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

  always @(posedge axi_clk) begin
    if (axis_valid && axis_ready) begin
      if (axis_keep !== 8'hff)
        fail($sformatf("TKEEP beat=%0d value=%02x", beat_index, axis_keep));
      if (axis_last !== (beat_index == 511))
        fail($sformatf("TLAST beat=%0d value=%0b", beat_index, axis_last));
      case (beat_index)
        0: begin
          if (axis_data[31:0] !== RECORD_MAGIC)
            fail("record magic");
          if (axis_data[63:32] !== RECORD_VERSION)
            fail("record version");
        end
        1: record_frame[record_count] <= axis_data[63:32];
        2: record_line[record_count] <= axis_data[31:0];
        3: begin
          if (axis_data[31:0] !== 32'd3840)
            fail("payload length");
          record_flags[record_count] <= axis_data[63:32];
        end
        4: if (axis_data[31:0] !== 32'd1)
          fail("active channel count");
        6: if (axis_data !== 64'b0)
          fail("logical/physical channel");
        default: begin
          if (beat_index >= 488 && axis_data !== 64'b0)
            fail($sformatf("nonzero padding beat=%0d", beat_index));
        end
      endcase
      if (axis_last) begin
        beat_index <= 0;
        record_count <= record_count + 1;
      end else begin
        beat_index <= beat_index + 1;
      end
    end
  end

  initial begin : RUN
    integer i;
    integer malformed_before;
    integer dropped_before;

    reset_core();
    for (i = 0; i < 1079; i = i + 1)
      send_canonical_line();
    if (dut.source_line_sequence !== 32'd1078 ||
        dut.source_locked_source !== 1'b1)
      fail("canonical prehistory state");

    core_write(17'h0380c, 32'h0000_0001);
    for (i = 0; i < 100 && !dut.enable_applied_source; i = i + 1)
      @(posedge source_clk);
    if (!dut.enable_applied_source)
      fail("enable did not reach source domain");

    // Captured line 1079.
    send_captured_active_line(8'h90);
    malformed_before = dut.source_lifetime_malformed;
    dropped_before = dut.source_lifetime_dropped;

    // Captured V-low vertical tail: lines 1080..1099 end with EAV 0x90;
    // line 1100 ends with the observed V-high EAV 0xb0.
    for (i = 0; i < 20; i = i + 1)
      send_captured_active_line(8'h90);
    send_captured_active_line(8'hb0);

    if (dut.source_lifetime_malformed !== malformed_before)
      fail($sformatf("vertical tail malformed delta=%0d",
                     dut.source_lifetime_malformed - malformed_before));
    if (dut.source_lifetime_dropped !== dropped_before)
      fail($sformatf("vertical tail drop delta=%0d",
                     dut.source_lifetime_dropped - dropped_before));
    if (dut.source_locked_source !== 1'b1)
      fail("vertical tail lost source lock");

    // Captured V-high interval: 23 A0/B0 pairs, one final A0, and the
    // observed V-low EAV 0x90 immediately before the next active SAV.
    for (i = 0; i < 23; i = i + 1) begin
      send_marker(8'ha0); send_gap(3840);
      send_marker(8'hb0); send_gap(1432);
    end
    send_marker(8'ha0); send_gap(3840);
    send_marker(8'h90); send_gap(1432);

    // Captured next-frame lines 0..10, followed by the partial line 11 at
    // the exact 2884-clock trace-freeze boundary.
    for (i = 0; i < 11; i = i + 1)
      send_captured_active_line(8'h90);
    send_marker(8'h80);
    send_gap(2880);

    if (record_count != 12)
      fail($sformatf("expected 12 records got %0d", record_count));
    if (record_frame[0] !== 32'd1 || record_line[0] !== 32'd1079)
      fail("line1079 record identity");
    if (record_frame[1] !== 32'd2 || record_line[1] !== 32'd0)
      fail("next-frame line0 was not committed");
    if ((record_flags[1] &
         (FLAG_SOF | FLAG_VALID | FLAG_DISCONTINUITY |
          FLAG_OVERFLOW | FLAG_MALFORMED)) !== (FLAG_SOF | FLAG_VALID))
      fail($sformatf("line0 flags expected 00000021 got %08x",
                     record_flags[1]));
    if (record_frame[2] !== 32'd2 || record_line[2] !== 32'd1)
      fail("next-frame line1 record identity");
    if ((record_flags[2] &
         (FLAG_SOF | FLAG_VALID | FLAG_DISCONTINUITY |
          FLAG_OVERFLOW | FLAG_MALFORMED)) !== FLAG_VALID)
      fail($sformatf("line1 flags expected 00000020 got %08x",
                     record_flags[2]));
    if (dut.source_lifetime_malformed !== malformed_before ||
        dut.source_lifetime_dropped !== dropped_before)
      fail("boundary introduced late malformed/drop event");

    if (errors == 0)
      $display("G2B_BT656_LINE0_SOF_FIX_PASS records=%0d line0_commit=1 line0_flags=%08x line1_commit=1 line1_flags=%08x malformed_delta=0 drop_delta=0",
               record_count, record_flags[1], record_flags[2]);
    else
      $fatal(1, "G2B_BT656_LINE0_SOF_FIX_XSIM_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
