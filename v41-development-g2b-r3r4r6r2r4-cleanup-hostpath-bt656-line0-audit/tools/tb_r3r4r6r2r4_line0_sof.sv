`timescale 1ns/1ps

// Task-local, device-free audit fixture.  The DUT is the unmodified PRODUCT
// source file from C:/FPGA/V41_G2B.  This fixture deliberately uses only the
// BT.656 marker sequence already present in the project testbench; it does not
// claim that this synthetic vertical-blanking sequence is an authoritative
// trace of the physical NVP6134C output.
module tb_r3r4r6r2r4_line0_sof;
  localparam logic [31:0] FLAG_SOF       = 32'h0000_0001;
  localparam logic [31:0] FLAG_DISC      = 32'h0000_0004;
  localparam logic [31:0] FLAG_OVERFLOW  = 32'h0000_0008;
  localparam logic [31:0] FLAG_MALFORMED = 32'h0000_0010;
  localparam logic [31:0] FLAG_VALID     = 32'h0000_0020;

  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;
  logic standalone_transport_reset = 1'b0;
  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = 17'b0;
  logic [31:0] mmio_req_wdata = 32'b0;
  logic [3:0] mmio_req_be = 4'b0;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b1;
  logic [31:0] mmio_rsp_rdata;
  logic [63:0] m_axis_c2h_tdata;
  logic [7:0] m_axis_c2h_tkeep;
  logic m_axis_c2h_tlast;
  logic m_axis_c2h_tvalid;
  logic m_axis_c2h_tready = 1'b1;

  integer errors = 0;
  integer record_count = 0;
  integer beat_index = 0;
  logic [31:0] rec_epoch [0:15];
  logic [31:0] rec_frame [0:15];
  logic [31:0] rec_line [0:15];
  logic [31:0] rec_capture [0:15];
  logic [31:0] rec_flags [0:15];
  logic [31:0] rec_malformed [0:15];
  logic [31:0] rec_dropped [0:15];
  logic line0_lock_observed;
  logic line0_attempt_observed;
  logic unlocked_line0_lock_observed;
  logic unlocked_line0_attempt_observed;

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h dut (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(standalone_transport_reset),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata),
    .m_axis_c2h_tdata(m_axis_c2h_tdata),
    .m_axis_c2h_tkeep(m_axis_c2h_tkeep),
    .m_axis_c2h_tlast(m_axis_c2h_tlast),
    .m_axis_c2h_tvalid(m_axis_c2h_tvalid),
    .m_axis_c2h_tready(m_axis_c2h_tready)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("R3R4R6R2R4_DIRECTED_FAIL time=%0t %s", $time, message);
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

  task automatic send_valid_line(input logic [7:0] seed);
    integer i;
    begin
      send_marker(8'h80);
      for (i = 0; i < 3840; i = i + 1)
        drive_source_byte(seed + i[7:0]);
      send_marker(8'h90);
      send_gap(16);
    end
  endtask

  // This is copied from the existing project testbench.  It is a documented
  // project stimulus, but the repository does not establish it as a complete
  // cycle-accurate NVP6134C vertical-blanking trace.
  task automatic send_project_vblank_marker;
    begin
      send_marker(8'ha0);
      send_marker(8'hb0);
      send_gap(8);
    end
  endtask

  task automatic mmio_write(
    input logic [16:0] address,
    input logic [31:0] data,
    input logic [3:0] byte_enable);
    integer wait_cycles;
    begin
      @(negedge axi_clk);
      mmio_req_addr = address;
      mmio_req_wdata = data;
      mmio_req_be = byte_enable;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      wait_cycles = 0;
      @(posedge axi_clk);
      while (!mmio_req_ready && wait_cycles < 2000) begin
        wait_cycles = wait_cycles + 1;
        @(posedge axi_clk);
      end
      if (!mmio_req_ready)
        fail($sformatf("MMIO write timeout addr=%05x data=%08x", address, data));
      @(negedge axi_clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = 17'b0;
      mmio_req_wdata = 32'b0;
      mmio_req_be = 4'b0;
    end
  endtask

  task automatic wait_record_count(
    input integer target, input integer limit, input string label);
    integer count;
    begin
      count = 0;
      while (record_count < target && count < limit) begin
        @(posedge axi_clk);
        count = count + 1;
      end
      if (record_count < target)
        fail($sformatf("%s record timeout target=%0d actual=%0d", label,
                       target, record_count));
    end
  endtask

  always @(posedge axi_clk) begin
    if (m_axis_c2h_tvalid && m_axis_c2h_tready) begin
      if (record_count < 16) begin
        case (beat_index)
          1: begin
            rec_epoch[record_count] <= m_axis_c2h_tdata[31:0];
            rec_frame[record_count] <= m_axis_c2h_tdata[63:32];
          end
          2: begin
            rec_line[record_count] <= m_axis_c2h_tdata[31:0];
            rec_capture[record_count] <= m_axis_c2h_tdata[63:32];
          end
          3: rec_flags[record_count] <= m_axis_c2h_tdata[63:32];
          5: begin
            rec_malformed[record_count] <= m_axis_c2h_tdata[31:0];
            rec_dropped[record_count] <= m_axis_c2h_tdata[63:32];
          end
        endcase
      end
      if (m_axis_c2h_tlast) begin
        if (beat_index != 511)
          fail($sformatf("TLAST at beat %0d", beat_index));
        record_count <= record_count + 1;
        beat_index <= 0;
      end else begin
        beat_index <= beat_index + 1;
      end
    end
  end

  initial begin : DIRECTED_SEQUENCE
    integer i;
    integer before_unlocked_line0;
    logic [31:0] malformed_before_boundary;

    repeat (12) @(posedge source_clk);
    repeat (8) @(posedge axi_clk);
    @(negedge source_clk); source_reset = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (24) @(posedge axi_clk);

    // Build a complete synthetic frame while capture is disabled.  The first
    // active line establishes lock; the remaining 1079 lines advance through
    // source line 1079 using the unmodified parser.
    for (i = 0; i < 1080; i = i + 1)
      send_valid_line(i[7:0]);
    if (dut.source_line_sequence !== 32'd1079)
      fail($sformatf("pre-boundary line expected 1079 actual %0d",
                     dut.source_line_sequence));
    if (!dut.source_locked_source)
      fail("source was not locked after complete synthetic frame");

    malformed_before_boundary = dut.source_lifetime_malformed;
    send_project_vblank_marker();
    mmio_write(17'h0380c, 32'h0000_0001, 4'h1);

    // Observe admission at the first active SAV with lock retained across the
    // project vertical-blanking fixture.
    fork
      begin
        wait (dut.source_state == 3'd1 && dut.source_line_sequence == 32'd0);
        #1ps;
        line0_lock_observed = dut.source_locked_source;
        line0_attempt_observed = dut.monitor_has_attempt;
      end
      begin
        send_valid_line(8'hc0);
      end
    join
    wait_record_count(1, 10000, "project-vblank line0");
    send_valid_line(8'hc1);
    wait_record_count(2, 10000, "project-vblank line1");
    #1ps;

    if (rec_frame[0] !== 32'd2 || rec_line[0] !== 32'd0 ||
        (rec_flags[0] & (FLAG_VALID | FLAG_SOF)) !==
        (FLAG_VALID | FLAG_SOF))
      fail($sformatf("line0/SOF record mismatch frame=%0d line=%0d flags=%08x",
                     rec_frame[0], rec_line[0], rec_flags[0]));
    if (rec_frame[1] !== 32'd2 || rec_line[1] !== 32'd1)
      fail($sformatf("line1 record mismatch frame=%0d line=%0d",
                     rec_frame[1], rec_line[1]));
    if (dut.source_lifetime_malformed !== malformed_before_boundary ||
        (rec_flags[0] & FLAG_MALFORMED) != 0 ||
        (rec_flags[1] & FLAG_MALFORMED) != 0)
      fail("project-vblank sequence created malformed context");
    if (!line0_lock_observed || !line0_attempt_observed)
      fail($sformatf("locked line0 admission expected lock=1 attempt=1 got %0b/%0b",
                     line0_lock_observed, line0_attempt_observed));

    $display("R3R4R6R2R4_TEST2_PROJECT_FRAME_BOUNDARY_PASS line1079_to_line0_to_line1 malformed_delta=0");
    $display("R3R4R6R2R4_TEST3_OBSERVED_FAILURE_NOT_REPRODUCED project_fixture_delta=0 authoritative_nvp_trace=absent");

    // Exercise the exact nonblocking-assignment admission mechanism.  A
    // source reset leaves capture enabled but clears source lock.  The first
    // active line is observed and validated as line 0, yet is not admitted;
    // its valid EAV establishes lock, and the following line 1 is admitted.
    @(negedge source_clk); source_reset = 1'b1;
    repeat (8) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    send_gap(8);
    before_unlocked_line0 = record_count;
    fork
      begin
        wait (dut.source_state == 3'd1 && dut.source_line_sequence == 32'd0);
        #1ps;
        unlocked_line0_lock_observed = dut.source_locked_source;
        unlocked_line0_attempt_observed = dut.monitor_has_attempt;
      end
      begin
        send_valid_line(8'hd0);
      end
    join
    repeat (32) @(posedge axi_clk);
    if (record_count != before_unlocked_line0)
      fail("unlocked line0 was unexpectedly committed");
    if (unlocked_line0_lock_observed || unlocked_line0_attempt_observed)
      fail($sformatf("unlocked line0 expected lock=0 attempt=0 got %0b/%0b",
                     unlocked_line0_lock_observed,
                     unlocked_line0_attempt_observed));
    if (!dut.source_locked_source)
      fail("valid unlocked line0 did not establish source lock at EAV");

    send_valid_line(8'hd1);
    wait_record_count(before_unlocked_line0 + 1, 10000, "post-lock line1");
    #1ps;
    if (rec_line[before_unlocked_line0] !== 32'd1)
      fail($sformatf("post-lock first record expected line1 actual=%0d",
                     rec_line[before_unlocked_line0]));
    $display("R3R4R6R2R4_TEST6_LOCK_ADMISSION_PASS unlocked_line0_observed=1 admitted=0 valid_eav_relocks=1 next_committed_line=1");

    // Later lines form a clean stable subset after the transition record.
    send_valid_line(8'hd2);
    send_valid_line(8'hd3);
    wait_record_count(before_unlocked_line0 + 3, 20000, "stable lines");
    #1ps;
    if (rec_line[before_unlocked_line0 + 1] !== 32'd2 ||
        rec_line[before_unlocked_line0 + 2] !== 32'd3 ||
        (rec_flags[before_unlocked_line0 + 1] &
         (FLAG_DISC | FLAG_OVERFLOW | FLAG_MALFORMED)) != 0 ||
        (rec_flags[before_unlocked_line0 + 2] &
         (FLAG_DISC | FLAG_OVERFLOW | FLAG_MALFORMED)) != 0)
      fail("stable-line subset did not remain clean and consecutive");
    $display("R3R4R6R2R4_TEST1_STABLE_ACTIVE_LINE_PASS lines=2,3 malformed_delta=0 discontinuity=0");

    if (errors == 0) begin
      $display("R3R4R6R2R4_FOCUSED_LINE0_SOF_XSIM_PASS");
      $finish;
    end
    $display("R3R4R6R2R4_FOCUSED_LINE0_SOF_XSIM_FAIL errors=%0d", errors);
    $fatal(1);
  end

  initial begin
    #80ms;
    fail("global simulation timeout");
    $fatal(1);
  end
endmodule
