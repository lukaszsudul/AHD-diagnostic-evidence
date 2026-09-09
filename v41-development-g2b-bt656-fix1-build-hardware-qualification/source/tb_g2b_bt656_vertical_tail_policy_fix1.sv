`timescale 1ns/1ps

// FIX1 hardening regression for the bounded V-low vertical-tail policy.
// Each case establishes parser history only through real BT.656 byte traffic;
// no internal parser state is forced.
module tb_g2b_bt656_vertical_tail_policy_fix1;
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
  logic [31:0] record_frame [0:3];
  logic [31:0] record_line [0:3];
  logic [31:0] record_capture [0:3];
  logic [31:0] record_flags [0:3];
  logic [31:0] record_attempt [0:3];
  logic [31:0] record_global [0:3];

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
      $display("G2B_BT656_VERTICAL_TAIL_POLICY_FAIL time=%0t %s",
               $time, message);
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

  task automatic send_line;
    begin
      send_marker(8'h80);
      send_gap(3840);
      send_marker(8'h90);
      send_gap(16);
    end
  endtask

  task automatic send_vhigh_blanking_interval;
    begin
      send_marker(8'ha0);
      send_gap(3840);
      send_marker(8'hb0);
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
    integer i;
    begin
      @(negedge source_clk); source_reset = 1'b1;
      @(negedge axi_clk); axi_aresetn = 1'b0;
      repeat (12) @(posedge source_clk);
      repeat (8) @(posedge axi_clk);
      @(negedge source_clk); source_reset = 1'b0;
      @(negedge axi_clk); axi_aresetn = 1'b1;
      repeat (24) @(posedge axi_clk);
      source_byte = 8'h55;
      beat_index = 0;
      record_count = 0;
      for (i = 0; i < 4; i = i + 1) begin
        record_frame[i] = '0;
        record_line[i] = '0;
        record_capture[i] = '0;
        record_flags[i] = '0;
        record_attempt[i] = '0;
        record_global[i] = '0;
      end
    end
  endtask

  task automatic establish_line1079;
    integer i;
    begin
      reset_core();
      for (i = 0; i < 1079; i = i + 1)
        send_line();
      if (dut.source_line_sequence !== 32'd1078 ||
          dut.source_locked_source !== 1'b1)
        fail("canonical prehistory state");
      core_write(17'h0380c, 32'h0000_0001);
      for (i = 0; i < 100 && !dut.enable_applied_source; i = i + 1)
        @(posedge source_clk);
      if (!dut.enable_applied_source)
        fail("enable did not reach source domain");
      send_line();
    end
  endtask

  task automatic run_short_tail_case(input integer tail_lines);
    integer i;
    integer malformed_before;
    integer dropped_before;
    integer attempted_before;
    integer committed_before;
    integer overflow_before;
    integer capture_before;
    begin
      establish_line1079();
      malformed_before = dut.source_lifetime_malformed;
      dropped_before = dut.source_lifetime_dropped;
      attempted_before = dut.records_attempted_source;
      committed_before = dut.records_committed_source;
      overflow_before = dut.overflow_count_source;
      capture_before = dut.source_capture_sequence;

      for (i = 0; i < tail_lines; i = i + 1)
        send_line();

      if (dut.source_lifetime_malformed !== malformed_before)
        fail($sformatf("short tail %0d malformed", tail_lines));
      if (dut.source_lifetime_dropped !== dropped_before)
        fail($sformatf("short tail %0d dropped", tail_lines));
      if (dut.records_attempted_source !== attempted_before)
        fail($sformatf("short tail %0d attempted", tail_lines));
      if (dut.records_committed_source !== committed_before)
        fail($sformatf("short tail %0d committed", tail_lines));
      if (dut.overflow_count_source !== overflow_before)
        fail($sformatf("short tail %0d overflow", tail_lines));
      if (dut.source_capture_sequence !== capture_before + tail_lines)
        fail($sformatf("short tail %0d capture delta=%0d",
                       tail_lines,
                       dut.source_capture_sequence - capture_before));
      if (!dut.source_locked_source)
        fail($sformatf("short tail %0d lost lock", tail_lines));

      send_vhigh_blanking_interval();
      send_line();
      send_line();

      // The second line has only the canonical 16-byte post-EAV gap, so the
      // AXI formatter may still be draining its 512 beats when source driving
      // ends.  Wait on the observable record completion, not wall-clock time.
      for (i = 0; i < 700 && record_count < 3; i = i + 1)
        @(posedge axi_clk);

      if (record_count != 3)
        fail($sformatf("short tail %0d records=%0d", tail_lines,
                       record_count));
      if (record_frame[0] !== 32'd1 || record_line[0] !== 32'd1079)
        fail($sformatf("short tail %0d line1079 identity", tail_lines));
      if (record_frame[1] !== 32'd2 || record_line[1] !== 32'd0)
        fail($sformatf("short tail %0d line0 identity", tail_lines));
      if (record_flags[1] !== (FLAG_SOF | FLAG_VALID))
        fail($sformatf("short tail %0d line0 flags=%08x",
                       tail_lines, record_flags[1]));
      if (record_frame[2] !== 32'd2 || record_line[2] !== 32'd1)
        fail($sformatf("short tail %0d line1 identity", tail_lines));
      if (record_flags[2] !== FLAG_VALID)
        fail($sformatf("short tail %0d line1 flags=%08x",
                       tail_lines, record_flags[2]));
      if (record_capture[1] !== record_capture[0] + tail_lines + 1)
        fail($sformatf("short tail %0d capture boundary delta=%0d",
                       tail_lines, record_capture[1] - record_capture[0]));
      if (record_attempt[1] !== record_attempt[0] + 1'b1 ||
          record_global[1] !== record_global[0] + 1'b1)
        fail($sformatf("short tail %0d transport sequence", tail_lines));
      $display("G2B_BT656_SHORT_TAIL_CASE_PASS tail_lines=%0d",
               tail_lines);
    end
  endtask

  task automatic run_overlong_tail_case;
    integer i;
    integer malformed_before;
    integer dropped_before;
    integer attempted_before;
    integer committed_before;
    integer overflow_before;
    integer capture_before;
    begin
      establish_line1079();
      malformed_before = dut.source_lifetime_malformed;
      dropped_before = dut.source_lifetime_dropped;
      attempted_before = dut.records_attempted_source;
      committed_before = dut.records_committed_source;
      overflow_before = dut.overflow_count_source;
      capture_before = dut.source_capture_sequence;

      // Lines 1080..1100 are benign.  Line 1101 is the single overlong
      // complete interval and must be classified once, never transported.
      for (i = 0; i < 22; i = i + 1)
        send_line();

      if (dut.source_lifetime_malformed !== malformed_before + 1)
        fail($sformatf("overlong malformed delta=%0d",
                       dut.source_lifetime_malformed - malformed_before));
      if (dut.source_lifetime_dropped !== dropped_before)
        fail("overlong tail created source drop");
      if (dut.records_attempted_source !== attempted_before)
        fail("overlong tail created transport attempt");
      if (dut.records_committed_source !== committed_before)
        fail("overlong tail created committed record");
      if (dut.overflow_count_source !== overflow_before)
        fail("overlong tail created overflow");
      if (dut.source_capture_sequence !== capture_before + 21)
        fail($sformatf("overlong benign capture increments=%0d",
                       dut.source_capture_sequence - capture_before));
      if (dut.source_locked_source !== 1'b0)
        fail("overlong tail did not enter bounded reacquisition state");
      if (record_count != 1)
        fail($sformatf("overlong tail transported record count=%0d",
                       record_count));
      $display("G2B_BT656_OVERLONG_TAIL_CASE_PASS line=1101 malformed_delta=1 active_records=0 tail_capture_increments=21");
    end
  endtask

  always @(posedge axi_clk) begin
    if (axis_valid && axis_ready) begin
      if (axis_keep !== 8'hff)
        fail($sformatf("TKEEP beat=%0d", beat_index));
      if (axis_last !== (beat_index == 511))
        fail($sformatf("TLAST beat=%0d", beat_index));
      case (beat_index)
        1: record_frame[record_count] <= axis_data[63:32];
        2: begin
          record_line[record_count] <= axis_data[31:0];
          record_capture[record_count] <= axis_data[63:32];
        end
        3: record_flags[record_count] <= axis_data[63:32];
        7: begin
          record_attempt[record_count] <= axis_data[31:0];
          record_global[record_count] <= axis_data[63:32];
        end
        default: begin end
      endcase
      if (axis_last) begin
        beat_index <= 0;
        record_count <= record_count + 1;
      end else begin
        beat_index <= beat_index + 1;
      end
    end
  end

  initial begin
    run_short_tail_case(0);
    run_short_tail_case(1);
    run_short_tail_case(20);
    run_overlong_tail_case();

    if (errors == 0)
      $display("G2B_BT656_VERTICAL_TAIL_POLICY_FIX1_PASS shorter=0,1,20 overlong=1101 malformed_once=1");
    else
      $fatal(1, "G2B_BT656_VERTICAL_TAIL_POLICY_FIX1_FAIL errors=%0d",
             errors);
    $finish;
  end
endmodule
