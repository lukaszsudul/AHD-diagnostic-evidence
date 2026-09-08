`timescale 1ns/1ps

module tb_g2b_bt656_diag1_trace;
  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic event_valid = 1'b0;
  logic trigger_pulse = 1'b0;
  logic next_frame_line1_commit = 1'b0;
  logic [511:0] event_payload = '0;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;
  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = '0;
  logic [31:0] mmio_req_wdata = '0;
  logic [3:0] mmio_req_be = '0;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b1;
  logic [31:0] mmio_rsp_rdata;
  integer errors = 0;

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  g2b_bt656_boundary_trace dut (
    .source_clk(source_clk), .source_reset(source_reset),
    .event_valid(event_valid), .trigger_pulse(trigger_pulse),
    .next_frame_line1_commit(next_frame_line1_commit),
    .event_payload(event_payload),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("BT656_DIAG1_TRACE_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic mmio_write(input logic [16:0] address,
                            input logic [31:0] data);
    begin
      @(negedge axi_clk);
      mmio_req_addr = address;
      mmio_req_wdata = data;
      mmio_req_be = 4'hf;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      do @(posedge axi_clk); while (!mmio_req_ready);
      @(negedge axi_clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = '0;
      mmio_req_wdata = '0;
      mmio_req_be = '0;
    end
  endtask

  task automatic mmio_read(input logic [16:0] address,
                           output logic [31:0] data);
    begin
      @(negedge axi_clk);
      mmio_req_addr = address;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      do @(posedge axi_clk); while (!mmio_req_ready);
      @(negedge axi_clk);
      mmio_req_valid = 1'b0;
      mmio_req_addr = '0;
      do @(posedge axi_clk); while (!mmio_rsp_valid);
      data = mmio_rsp_rdata;
      @(negedge axi_clk);
    end
  endtask

  task automatic wait_status(input integer bit_index, input logic value);
    logic [31:0] status;
    integer tries;
    begin
      status = '0;
      for (tries = 0; tries < 2000 && status[bit_index] != value;
           tries = tries + 1)
        mmio_read(17'h03c10, status);
      if (status[bit_index] != value)
        fail($sformatf("status bit %0d did not become %0d status=%08x",
                       bit_index, value, status));
    end
  endtask

  task automatic clear_and_arm;
    begin
      mmio_write(17'h03c0c, 32'h0000_0001);
      wait_status(0, 1'b0);
      mmio_write(17'h03c0c, 32'h0000_0002);
      wait_status(0, 1'b1);
    end
  endtask

  task automatic emit(input logic [511:0] payload,
                      input logic trigger_value,
                      input logic line1_value);
    begin
      @(negedge source_clk);
      event_payload = payload;
      event_valid = 1'b1;
      trigger_pulse = trigger_value;
      next_frame_line1_commit = line1_value;
      @(negedge source_clk);
      event_valid = 1'b0;
      trigger_pulse = 1'b0;
      next_frame_line1_commit = 1'b0;
      event_payload = '0;
    end
  endtask

  task automatic read_entry_word(input integer entry_index,
                                 input integer word_index,
                                 output logic [31:0] value);
    logic [31:0] read_status;
    integer tries;
    begin
      mmio_write(17'h03c38, entry_index);
      read_status = '0;
      for (tries = 0; tries < 100 && !read_status[0]; tries = tries + 1)
        mmio_read(17'h03c3c, read_status);
      if (!read_status[0]) begin
        fail($sformatf("read data timeout entry=%0d", entry_index));
        value = 32'hxxxx_xxxx;
      end else begin
        mmio_read(17'h03c40 + word_index*4, value);
      end
    end
  endtask

  initial begin : RUN
    logic [511:0] payload;
    logic [31:0] value;
    logic [31:0] status;
    integer i;

    repeat (10) @(posedge source_clk);
    repeat (6) @(posedge axi_clk);
    @(negedge source_clk); source_reset = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (8) @(posedge axi_clk);

    mmio_read(17'h03c00, value);
    if (value !== 32'h4254_3635) fail("TRACE_MAGIC mismatch");
    mmio_read(17'h03c04, value);
    if (value !== 32'h0001_0000) fail("TRACE_VERSION mismatch");

    clear_and_arm();
    mmio_read(17'h03c14, value);
    if (value !== 0) fail("CLEAR did not empty valid-entry count");
    $display("BT656_DIAG1_T1_PASS clear_arm_status");

    payload = '0;
    payload[2*32 +: 32] = 32'h9d00_00ff;
    payload[3*32 + 0] = 1'b1;
    payload[3*32 + 1] = 1'b1;
    payload[3*32 + 2] = 1'b0;
    payload[3*32 + 3] = 1'b0;
    payload[3*32 + 4] = 1'b1;
    payload[3*32 + 5] = 1'b1;
    payload[4*32 +: 32] = 32'd7;
    payload[5*32 +: 32] = 32'd1079;
    emit(payload, 1'b1, 1'b0);
    payload[4*32 +: 32] = 32'd8;
    payload[5*32 +: 32] = 32'd1;
    payload[3*32 + 8] = 1'b1;
    emit(payload, 1'b0, 1'b1);
    wait_status(2, 1'b1);
    read_entry_word(0, 2, value);
    if (value !== 32'h9d00_00ff)
      fail($sformatf("marker alignment expected 9d0000ff got %08x", value));
    $display("BT656_DIAG1_T2_PASS marker_byte_alignment");

    clear_and_arm();
    for (i = 0; i < 40; i = i + 1) begin
      payload = '0;
      payload[2*32 +: 32] = 32'h1000_0000 + i;
      payload[3*32 + 0] = 1'b1;
      emit(payload, 1'b0, 1'b0);
    end
    payload = '0;
    payload[2*32 +: 32] = 32'hfeed_1079;
    payload[4*32 +: 32] = 32'd20;
    payload[5*32 +: 32] = 32'd1079;
    emit(payload, 1'b1, 1'b0);
    payload[2*32 +: 32] = 32'hfeed_0001;
    payload[4*32 +: 32] = 32'd21;
    payload[5*32 +: 32] = 32'd1;
    payload[3*32 + 8] = 1'b1;
    emit(payload, 1'b0, 1'b1);
    wait_status(2, 1'b1);
    mmio_read(17'h03c14, value);
    if (value !== 34) fail($sformatf("expected 34 entries got %0d", value));
    for (i = 0; i < 32; i = i + 1) begin
      read_entry_word(i, 2, value);
      if (value !== 32'h1000_0008 + i)
        fail($sformatf("pretrigger ordering index=%0d got=%08x", i, value));
    end
    read_entry_word(32, 2, value);
    if (value !== 32'hfeed_1079) fail("trigger not first posttrigger entry");
    read_entry_word(33, 3, value);
    if (!value[22]) fail("line1 stop bit absent from terminating entry");
    mmio_read(17'h03c24, value);
    if (value !== 1) fail("line1 stop reason mismatch");
    $display("BT656_DIAG1_T3_PASS pretrigger_chronological_order");

    // The exhaustive word read above crossed the independent source/AXI
    // clocks. Check one full known 512-bit entry word-for-word as T8.
    clear_and_arm();
    payload = '0;
    for (i = 2; i < 16; i = i + 1)
      payload[i*32 +: 32] = 32'ha500_0000 + i;
    payload[4*32 +: 32] = 32'd30;
    emit(payload, 1'b1, 1'b0);
    payload[4*32 +: 32] = 32'd31;
    payload[5*32 +: 32] = 32'd1;
    emit(payload, 1'b0, 1'b1);
    wait_status(2, 1'b1);
    read_entry_word(0, 0, value);
    if (value !== 0) fail("known entry word0 mismatch");
    read_entry_word(0, 1, value);
    if (value !== 0) fail("first logical entry delta was not forced zero");
    for (i = 2; i < 16; i = i + 1) begin
      read_entry_word(0, i, value);
      if (i == 3) begin
        // compose_entry owns only stop/reserved bits in this non-stop entry.
        if (value !== (32'ha500_0003 & 32'h7e3f_ffff))
          fail($sformatf("known entry word3 mismatch got=%08x", value));
      end else if (i == 15) begin
        if (value !== (32'ha500_000f & 32'h1fff_ffff))
          fail($sformatf("known entry word15 mismatch got=%08x", value));
      end else if (i == 4) begin
        if (value !== 30) fail("known entry word4 mismatch");
      end else if (value !== 32'ha500_0000 + i)
        fail($sformatf("known entry word%0d mismatch got=%08x", i, value));
    end
    $display("BT656_DIAG1_T8_PASS dual_clock_mmio_readback");

    // Event-limit stop: trigger plus 255 later events is exactly 256
    // posttrigger entries. A later event must not modify frozen state.
    clear_and_arm();
    payload = '0;
    payload[4*32 +: 32] = 32'd40;
    emit(payload, 1'b1, 1'b0);
    for (i = 1; i < 256; i = i + 1) begin
      payload[2*32 +: 32] = i;
      emit(payload, 1'b0, 1'b0);
    end
    wait_status(2, 1'b1);
    mmio_read(17'h03c24, value);
    if (value !== 2) fail("event-limit stop reason mismatch");
    mmio_read(17'h03c14, value);
    if (value !== 256) fail("event-limit valid count mismatch");
    emit('1, 1'b0, 1'b0);
    mmio_read(17'h03c14, value);
    if (value !== 256) fail("frozen trace changed after event-limit stop");

    clear_and_arm();
    payload = '0;
    payload[4*32 +: 32] = 32'd50;
    emit(payload, 1'b1, 1'b0);
    repeat (300010) @(posedge source_clk);
    wait_status(2, 1'b1);
    mmio_read(17'h03c24, value);
    if (value !== 3) fail("clock-timeout stop reason mismatch");
    read_entry_word(1, 3, value);
    if (!value[24]) fail("clock-timeout stop bit absent");
    $display("BT656_DIAG1_T7_PASS event_limit_clock_timeout_freeze");

    mmio_read(17'h03c10, status);
    if (status[3]) fail("unexpected trace overflow");

    if (errors == 0)
      $display("BT656_DIAG1_TRACE_XSIM_PASS");
    else
      $fatal(1, "BT656_DIAG1_TRACE_XSIM_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
