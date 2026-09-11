`timescale 1ns/1ps

// R3 core-level proof for the asymmetric downstream protocol: writes execute
// one side effect and create no response, while reads create one held response.
module tb_g2b_nvp_video_diag_mmio_protocol;
  logic clk = 1'b0;
  logic reset = 1'b1;
  always #5 clk = ~clk;

  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = '0;
  logic [31:0] mmio_req_wdata = '0;
  logic [3:0] mmio_req_be = 4'hf;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b0;
  logic [31:0] mmio_rsp_rdata;

  logic i2c_cmd_valid;
  logic i2c_cmd_write;
  logic [7:0] i2c_cmd_reg;
  logic [7:0] i2c_cmd_wdata;
  logic diagnostic_i2c_owns_bus;
  logic capture_ready;
  logic [15:0] current_session_id;
  logic [2:0] current_round;
  logic [2:0] current_channel;
  logic product_baseline_restored;

  integer control_pulse_count = 0;
  integer host_pulse_count = 0;
  integer protocol_error_count = 0;
  logic [31:0] last_control_pulse = 0;

  g2b_nvp_video_diag #(
    .CYCLES_PER_MS(1), .SETTLE_TIME_MS(2),
    .STATUS_SAMPLE_INTERVAL_MS(1), .REQUIRED_STABLE_SAMPLES(5),
    .MAX_STATUS_WAIT_MS(200)
  ) dut (
    .clk(clk), .reset(reset),
    .autoinit_done(1'b1), .autoinit_busy(1'b0),
    .autoinit_error(1'b0), .nvp_reset_released(1'b1),
    .transport_stream_enabled(1'b0), .transport_c2h_active(1'b0),
    .transport_ring_empty(1'b1), .transport_ring_full(1'b0),
    .i2c_cmd_valid(i2c_cmd_valid), .i2c_cmd_ready(1'b1),
    .i2c_cmd_write(i2c_cmd_write), .i2c_cmd_reg(i2c_cmd_reg),
    .i2c_cmd_wdata(i2c_cmd_wdata), .i2c_cmd_accepted(1'b0),
    .i2c_busy(1'b0), .i2c_done(1'b0), .i2c_success(1'b1),
    .i2c_timeout(1'b0), .i2c_read_data(8'h00), .i2c_bus_idle(1'b1),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata),
    .diagnostic_i2c_owns_bus(diagnostic_i2c_owns_bus),
    .capture_ready(capture_ready), .current_session_id(current_session_id),
    .current_round(current_round), .current_channel(current_channel),
    .product_baseline_restored(product_baseline_restored)
  );

  always @(posedge clk) begin
    if (!reset) begin
      if (dut.control_pulse != 0) begin
        control_pulse_count <= control_pulse_count + 1;
        last_control_pulse <= dut.control_pulse;
      end
      if (dut.host_response_pulse)
        host_pulse_count <= host_pulse_count + 1;
      if (dut.mmio_protocol_error_pulse)
        protocol_error_count <= protocol_error_count + 1;
    end
  end

  task automatic reset_dut;
    begin
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = '0;
      mmio_req_wdata = '0;
      mmio_req_be = 4'hf;
      mmio_rsp_ready = 1'b0;
      reset = 1'b1;
      repeat (4) @(posedge clk);
      reset = 1'b0;
      repeat (3) @(posedge clk);
      if (mmio_rsp_valid)
        $fatal(1, "response valid survived reset");
    end
  endtask

  task automatic direct_write(input logic [16:0] address,
                              input logic [31:0] value,
                              input logic [3:0] byte_enable);
    integer guard;
    begin
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      mmio_req_addr = address;
      mmio_req_wdata = value;
      mmio_req_be = byte_enable;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      guard = 0;
      while (!mmio_req_ready && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_req_ready)
        $fatal(1, "write request was not accepted");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = '0;
      mmio_req_wdata = '0;
      mmio_req_be = 4'hf;
      if (mmio_rsp_valid)
        $fatal(1, "accepted write created a downstream response");
      repeat (2) begin
        @(negedge clk);
        if (mmio_rsp_valid)
          $fatal(1, "accepted write left a latent response");
      end
    end
  endtask

  task automatic direct_read(input logic [16:0] address,
                             input logic [31:0] expected);
    integer guard;
    logic [31:0] held_data;
    begin
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      mmio_req_addr = address;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      guard = 0;
      while (!mmio_req_ready && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_req_ready)
        $fatal(1, "read request was not accepted");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_addr = '0;
      guard = 0;
      while (!mmio_rsp_valid && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_rsp_valid || mmio_rsp_rdata !== expected)
        $fatal(1, "read response mismatch address=%h got=%h expected=%h",
               address, mmio_rsp_rdata, expected);
      held_data = mmio_rsp_rdata;
      repeat (3) begin
        @(negedge clk);
        if (!mmio_rsp_valid || mmio_rsp_rdata !== held_data)
          $fatal(1, "read response changed under backpressure");
      end
      mmio_rsp_ready = 1'b1;
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      @(negedge clk);
      if (mmio_rsp_valid)
        $fatal(1, "read response did not clear after handshake");
    end
  endtask

  task automatic replace_response_with_read;
    integer guard;
    begin
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      mmio_req_addr = 17'h03c00;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      @(negedge clk);
      mmio_req_valid = 1'b0;
      guard = 0;
      while (!mmio_rsp_valid && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_rsp_valid)
        $fatal(1, "replacement setup response missing");
      mmio_rsp_ready = 1'b1;
      mmio_req_addr = 17'h03c04;
      mmio_req_valid = 1'b1;
      #1;
      if (!mmio_req_ready)
        $fatal(1, "same-cycle replacement read not ready");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_rsp_ready = 1'b0;
      if (!mmio_rsp_valid || mmio_rsp_rdata !== 32'h0001_0002)
        $fatal(1, "same-cycle read replacement failed");
      mmio_rsp_ready = 1'b1;
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      @(negedge clk);
    end
  endtask

  task automatic consume_response_with_write;
    integer before_count;
    begin
      @(negedge clk);
      mmio_rsp_ready = 1'b0;
      mmio_req_addr = 17'h03c00;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      @(negedge clk);
      mmio_req_valid = 1'b0;
      while (!mmio_rsp_valid) @(negedge clk);
      before_count = control_pulse_count;
      mmio_rsp_ready = 1'b1;
      mmio_req_addr = 17'h03c0c;
      mmio_req_wdata = 32'h0000_0001;
      mmio_req_be = 4'hf;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      #1;
      if (!mmio_req_ready)
        $fatal(1, "same-cycle consume/write not ready");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_rsp_ready = 1'b0;
      repeat (2) @(negedge clk);
      if (mmio_rsp_valid)
        $fatal(1, "write replacing consumed read left response valid");
      if (control_pulse_count != before_count + 1)
        $fatal(1, "same-cycle write side effect count mismatch");
    end
  endtask

  integer before_control;
  integer before_host;
  integer before_error;
  initial begin
    reset_dut();
    direct_read(17'h03c00, 32'h4e56_5034);
    direct_read(17'h03c04, 32'h0001_0002);
    direct_read(17'h03c08, 32'h0000_0bff);

    before_control = control_pulse_count;
    direct_write(17'h03c0c, 32'h0000_0001, 4'hf);
    if (control_pulse_count != before_control + 1 ||
        last_control_pulse != 32'h0000_0001)
      $fatal(1, "CLEAR side effect was not executed exactly once");
    direct_read(17'h03c10, 32'h0000_00a0);
    direct_read(17'h03c18, 32'h0000_0000);
    direct_read(17'h03c14, 32'h0000_0000);

    // Every defined command uses the same no-response write contract.
    direct_write(17'h03c0c, 32'h0000_0002, 4'hf);
    reset_dut();
    direct_write(17'h03c0c, 32'h0000_0004, 4'hf);
    reset_dut();
    direct_write(17'h03c0c, 32'h0000_0010, 4'hf);
    reset_dut();
    direct_write(17'h03c0c, 32'h0000_0008, 4'hf);
    reset_dut();
    before_host = host_pulse_count;
    direct_write(17'h03c34, 32'h0001_0009, 4'hf);
    if (host_pulse_count != before_host + 1)
      $fatal(1, "HOST_CAPTURE_RESPONSE pulse count mismatch");

    before_error = protocol_error_count;
    direct_write(17'h03c0c, 32'h0000_0001, 4'h3);
    direct_write(17'h03c38, 32'hfeed_beef, 4'hf);
    if (protocol_error_count != before_error + 2)
      $fatal(1, "invalid write protocol-error count mismatch");

    reset_dut();
    replace_response_with_read();
    consume_response_with_write();

    $display("PASS T20 CORE_WRITE_NO_RESPONSE_READ_RESPONSE_CONTRACT");
    $finish;
  end

  initial begin
    #200000;
    $fatal(1, "T20 global timeout");
  end
endmodule
