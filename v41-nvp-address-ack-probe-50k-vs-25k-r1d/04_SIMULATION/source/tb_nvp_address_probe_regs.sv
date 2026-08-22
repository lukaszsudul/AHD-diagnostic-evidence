`timescale 1ns/1ps

module tb_nvp_address_probe_regs;
  logic clk = 1'b0;
  always #2 clk = ~clk;
  logic reset = 1'b1;
  logic host_req_valid = 1'b0;
  wire host_req_ready;
  logic host_req_write = 1'b0;
  logic [16:0] host_req_addr = 17'b0;
  logic [31:0] host_req_wdata = 32'b0;
  logic [3:0] host_req_be = 4'b0;
  wire host_rsp_valid;
  logic host_rsp_ready = 1'b0;
  wire [31:0] host_rsp_rdata;
  wire app_req_valid;
  logic app_req_ready = 1'b0;
  wire app_req_write;
  wire [16:0] app_req_addr;
  wire [31:0] app_req_wdata;
  wire [3:0] app_req_be;
  logic app_rsp_valid = 1'b0;
  wire app_rsp_ready;
  logic [31:0] app_rsp_rdata = 32'b0;
  wire control_write;
  wire [31:0] control_wdata;
  wire [3:0] control_be;
  integer control_pulses = 0;

  nvp_address_probe_regs dut (
    .clk, .reset, .host_req_valid, .host_req_ready, .host_req_write,
    .host_req_addr, .host_req_wdata, .host_req_be,
    .host_rsp_valid, .host_rsp_ready, .host_rsp_rdata,
    .app_req_valid, .app_req_ready, .app_req_write, .app_req_addr,
    .app_req_wdata, .app_req_be, .app_rsp_valid, .app_rsp_ready,
    .app_rsp_rdata, .control_write, .control_wdata, .control_be,
    .probe_status(32'h000004A5), .probe_count(32'd10000),
    .probe_nack_count(32'd17), .probe_timeout_count(32'd0),
    .probe_divider(32'd625), .probe_tick_cycles(32'd626),
    .probe_campaign_index(32'd1)
  );

  always @(posedge clk) if (control_write) control_pulses = control_pulses + 1;

  task automatic fail(input string message);
    begin $display("TEST_FAIL: %s", message); $fatal(1); end
  endtask

  task automatic transact(input logic wr, input logic [16:0] addr,
                           input logic [31:0] data, input logic [3:0] be,
                           input logic [31:0] expected);
    begin
      @(negedge clk);
      host_req_write = wr; host_req_addr = addr; host_req_wdata = data;
      host_req_be = be; host_req_valid = 1'b1;
      do @(posedge clk); while (!host_req_ready);
      @(negedge clk); host_req_valid = 1'b0;
      while (!host_rsp_valid) @(negedge clk);
      if (host_rsp_rdata !== expected) fail("local response mismatch");
      host_rsp_ready = 1'b1;
      @(posedge clk); @(negedge clk); host_rsp_ready = 1'b0;
    end
  endtask

  initial begin
    repeat (4) @(posedge clk);
    @(negedge clk); reset = 1'b0;
    transact(0, 17'h02200, 0, 0, 32'h31425250);
    transact(0, 17'h02204, 0, 0, 32'd1);
    transact(0, 17'h02208, 0, 0, 32'd0);
    transact(0, 17'h0220C, 0, 0, 32'h000004A5);
    transact(0, 17'h02210, 0, 0, 32'd10000);
    transact(0, 17'h02214, 0, 0, 32'd17);
    transact(0, 17'h02218, 0, 0, 32'd0);
    transact(0, 17'h0221C, 0, 0, 32'd10000);
    transact(0, 17'h02220, 0, 0, 32'd625);
    transact(0, 17'h02224, 0, 0, 32'd626);
    transact(0, 17'h02228, 0, 0, 32'd1);
    transact(0, 17'h02202, 0, 0, 32'd0);

    transact(1, 17'h02200, 32'hFFFFFFFF, 4'hF, 32'd0);
    transact(1, 17'h02210, 32'hFFFFFFFF, 4'hF, 32'd0);
    if (control_pulses != 0) fail("non-control write had an effect");
    transact(1, 17'h02208, 32'h00000001, 4'hF, 32'd0);
    transact(1, 17'h02208, 32'h00000003, 4'hF, 32'd0);
    if (control_pulses != 2) fail("control write pulse count mismatch");
    if (control_wdata != 32'h00000003 || control_be != 4'hF)
      fail("control write payload mismatch");

    // Outside the diagnostic window, preserve the original downstream path.
    @(negedge clk);
    host_req_valid = 1'b1; host_req_write = 1'b0; host_req_addr = 17'h10000;
    repeat (2) begin
      @(posedge clk);
      if (!app_req_valid || app_req_addr != 17'h10000)
        fail("forwarded request changed under backpressure");
    end
    @(negedge clk); app_req_ready = 1'b1;
    @(posedge clk); @(negedge clk);
    host_req_valid = 1'b0; app_req_ready = 1'b0;
    app_rsp_rdata = 32'hA5A55A5A; app_rsp_valid = 1'b1;
    @(posedge clk); @(negedge clk); app_rsp_valid = 1'b0;
    if (!host_rsp_valid || host_rsp_rdata != 32'hA5A55A5A)
      fail("forwarded response mismatch");
    host_rsp_ready = 1'b1;
    @(posedge clk); @(negedge clk); host_rsp_ready = 1'b0;

    $display("PROBE_REGISTER_CONTROL_PULSES=%0d", control_pulses);
    $display("NVP_ADDRESS_PROBE_REGS_TEST=PASS");
    $finish;
  end
endmodule
