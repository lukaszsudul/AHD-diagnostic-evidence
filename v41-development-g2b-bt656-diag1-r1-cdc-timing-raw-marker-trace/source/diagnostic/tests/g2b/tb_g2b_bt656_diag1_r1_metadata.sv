`timescale 1ns/1ps

module tb_g2b_bt656_diag1_r1_metadata;
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
  integer metadata_write_time = -1;
  integer done_toggle_time = -1;
  logic last_done_generation = 1'b0;

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
      $display("BT656_DIAG1_R1_T12_FAIL time=%0t %s", $time, message);
    end
  endtask

  always @(negedge source_clk) begin
    if (!source_reset) begin
      if (dut.ram_we_source && dut.ram_write_addr_source == 9'd511)
        metadata_write_time = $time;
      if (dut.done_generation_source != last_done_generation) begin
        done_toggle_time = $time;
        if (metadata_write_time < 0 || metadata_write_time >= $time)
          fail("DONE generation preceded frozen metadata write");
        last_done_generation = dut.done_generation_source;
      end
    end else begin
      last_done_generation = dut.done_generation_source;
    end
  end

  always @(negedge axi_clk) begin
    if (axi_aresetn && dut.trace_done_axi && !dut.trace_meta_valid_axi)
      fail("public DONE became visible before metadata valid");
  end

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
      wait_status(2, 1'b0);
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
        fail("event RAM read timeout");
        value = 'x;
      end else begin
        mmio_read(17'h03c40 + word_index*4, value);
      end
    end
  endtask

  initial begin : RUN
    logic [511:0] payload;
    logic [31:0] value;
    logic [31:0] stable_value;
    logic [31:0] old_generation;

    repeat (10) @(posedge source_clk);
    repeat (6) @(posedge axi_clk);
    @(negedge source_clk); source_reset = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (8) @(posedge axi_clk);
    last_done_generation = dut.done_generation_source;

    clear_and_arm();
    payload = '0;
    payload[2*32 +: 32] = 32'hfeed_1079;
    payload[4*32 +: 32] = 32'd77;
    payload[5*32 +: 32] = 32'd1079;
    emit(payload, 1'b1, 1'b0);
    payload[2*32 +: 32] = 32'hfeed_0001;
    payload[3*32 + 8] = 1'b1;
    payload[4*32 +: 32] = 32'd78;
    payload[5*32 +: 32] = 32'd1;
    emit(payload, 1'b0, 1'b1);
    wait_status(2, 1'b1);

    if (metadata_write_time < 0 || done_toggle_time <= metadata_write_time)
      fail("metadata/final DONE source ordering absent");
    if (!dut.trace_meta_valid_axi || !dut.trace_done_axi)
      fail("AXI metadata cache was not valid with DONE");
    if (dut.valid_entries_axi !== dut.valid_entries_source ||
        dut.pre_count_axi !== dut.pre_count_source ||
        dut.post_count_axi !== dut.post_count_source ||
        dut.trigger_index_axi !== dut.trigger_logical_index_source ||
        dut.stop_reason_axi !== dut.stop_reason_source ||
        dut.trigger_frame_axi !== dut.trigger_frame_source ||
        dut.trigger_line_axi !== dut.trigger_line_source ||
        dut.trigger_clocks_axi !== dut.clocks_since_trigger_source)
      fail("AXI cached metadata differs from frozen source metadata");

    mmio_read(17'h03c14, value);
    if (value !== 2) fail("cached valid-entry count mismatch");
    mmio_read(17'h03c18, value);
    if (value !== 0) fail("cached pretrigger count mismatch");
    mmio_read(17'h03c1c, value);
    if (value !== 2) fail("cached posttrigger count mismatch");
    mmio_read(17'h03c24, value);
    if (value !== 1) fail("cached stop reason mismatch");
    mmio_read(17'h03c28, value);
    if (value !== 77) fail("cached trigger frame mismatch");
    mmio_read(17'h03c2c, value);
    if (value !== 1079) fail("cached trigger line mismatch");

    read_entry_word(1, 2, value);
    if (value !== 32'hfeed_0001) fail("final event was not retained");
    read_entry_word(1, 3, value);
    if (!value[22]) fail("final event lacks aligned line1 stop bit");

    mmio_read(17'h03c14, stable_value);
    repeat (20) @(posedge axi_clk);
    mmio_read(17'h03c14, value);
    if (value !== stable_value) fail("repeated frozen metadata read changed");
    old_generation = dut.trace_generation_axi;

    // CLEAR invalidates the AXI cache immediately and establishes a new
    // source generation without accepting a stale prior DONE toggle.
    mmio_write(17'h03c0c, 32'h0000_0001);
    wait_status(2, 1'b0);
    wait_status(0, 1'b0);
    repeat (20) @(posedge axi_clk);
    mmio_read(17'h03c10, value);
    if (value[2]) fail("stale DONE reappeared after CLEAR");
    mmio_read(17'h03c14, value);
    if (value !== 0) fail("stale metadata remained after CLEAR");

    metadata_write_time = -1;
    done_toggle_time = -1;
    mmio_write(17'h03c0c, 32'h0000_0002);
    wait_status(0, 1'b1);
    payload = '0;
    payload[4*32 +: 32] = 32'd90;
    payload[5*32 +: 32] = 32'd1079;
    emit(payload, 1'b1, 1'b0);
    payload[3*32 + 8] = 1'b1;
    payload[4*32 +: 32] = 32'd91;
    payload[5*32 +: 32] = 32'd1;
    emit(payload, 1'b0, 1'b1);
    wait_status(2, 1'b1);
    if (dut.trace_generation_axi !== old_generation + 1'b1)
      fail("new CLEAR generation was not captured");
    mmio_read(17'h03c28, value);
    if (value !== 90) fail("new generation exposed stale trigger metadata");

    if (errors == 0)
      $display("BT656_DIAG1_R1_T12_PASS frozen_metadata_before_done_stable_new_generation");
    else
      $fatal(1, "BT656_DIAG1_R1_T12_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
