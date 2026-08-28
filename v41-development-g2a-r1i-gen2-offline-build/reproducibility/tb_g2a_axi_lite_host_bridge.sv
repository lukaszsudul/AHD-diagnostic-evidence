`timescale 1ns/1ps

// Evidence-only protocol regression for the byte-identical qualified R1i
// AXI-Lite bridge.  This file is outside the product repository.
module tb_g2a_axi_lite_host_bridge;
  logic clk = 0;
  logic reset = 1;
  always #5 clk = ~clk;

  logic [31:0] s_axi_awaddr = 0;
  logic [2:0] s_axi_awprot = 0;
  logic s_axi_awvalid = 0;
  logic s_axi_awready;
  logic [31:0] s_axi_wdata = 0;
  logic [3:0] s_axi_wstrb = 0;
  logic s_axi_wvalid = 0;
  logic s_axi_wready;
  logic [1:0] s_axi_bresp;
  logic s_axi_bvalid;
  logic s_axi_bready = 0;
  logic [31:0] s_axi_araddr = 0;
  logic [2:0] s_axi_arprot = 0;
  logic s_axi_arvalid = 0;
  logic s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_rvalid;
  logic s_axi_rready = 0;
  logic host_req_valid;
  logic host_req_ready = 0;
  logic host_req_write;
  logic [16:0] host_req_addr;
  logic [31:0] host_req_wdata;
  logic [3:0] host_req_be;
  logic host_rsp_valid = 0;
  logic host_rsp_ready;
  logic [31:0] host_rsp_rdata = 0;
  integer checks = 0;

  v41_axi_lite_host_bridge dut (
    .clk(clk), .reset(reset),
    .s_axi_awaddr(s_axi_awaddr), .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr), .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata)
  );

  task automatic require_true(input bit condition, input string reason);
    begin
      checks = checks + 1;
      if (!condition) $fatal(1, "G2A_AXI_LITE_BRIDGE_FAIL %s", reason);
    end
  endtask

  task automatic complete_write(
    input logic [31:0] address,
    input logic [31:0] data,
    input logic [3:0] strobes,
    input bit address_first
  );
    begin
      if (address_first) begin
        @(negedge clk);
        s_axi_awaddr = address;
        s_axi_awvalid = 1;
        #1;
        require_true(s_axi_awready, "AW was not accepted independently");
        @(posedge clk);
        @(negedge clk);
        s_axi_awvalid = 0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        s_axi_wdata = data;
        s_axi_wstrb = strobes;
        s_axi_wvalid = 1;
        #1;
        require_true(s_axi_wready, "W was not accepted after AW");
        @(posedge clk);
        @(negedge clk);
        s_axi_wvalid = 0;
      end else begin
        @(negedge clk);
        s_axi_wdata = data;
        s_axi_wstrb = strobes;
        s_axi_wvalid = 1;
        #1;
        require_true(s_axi_wready, "W was not accepted independently");
        @(posedge clk);
        @(negedge clk);
        s_axi_wvalid = 0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        s_axi_awaddr = address;
        s_axi_awvalid = 1;
        #1;
        require_true(s_axi_awready, "AW was not accepted after W");
        @(posedge clk);
        @(negedge clk);
        s_axi_awvalid = 0;
      end

      wait (host_req_valid);
      #1;
      require_true(host_req_write, "host request is not a write");
      require_true(host_req_addr == address[16:0], "write address translation changed");
      require_true(host_req_wdata == data, "write data changed");
      require_true(host_req_be == strobes, "write byte enables changed");
      repeat (2) begin
        @(posedge clk); #1;
        require_true(host_req_valid, "write host request did not hold under backpressure");
        require_true(host_req_addr == address[16:0] && host_req_wdata == data &&
                     host_req_be == strobes, "write request changed under backpressure");
      end
      @(negedge clk);
      host_req_ready = 1;
      @(posedge clk); #1;
      @(negedge clk);
      host_req_ready = 0;
      wait (s_axi_bvalid);
      require_true(s_axi_bresp == 2'b00, "write response is not OKAY");
      repeat (2) begin
        @(posedge clk); #1;
        require_true(s_axi_bvalid, "BVALID did not hold under backpressure");
      end
      @(negedge clk);
      s_axi_bready = 1;
      @(posedge clk); #1;
      @(negedge clk);
      s_axi_bready = 0;
      @(posedge clk); #1;
      require_true(!s_axi_bvalid, "BVALID did not clear after handshake");
    end
  endtask

  initial begin
    repeat (4) @(posedge clk);
    reset = 0;
    @(posedge clk); #1;
    require_true(s_axi_awready && s_axi_wready && s_axi_arready,
                 "bridge is not idle after reset");

    complete_write(32'h0001_2344, 32'hA55A_0FF0, 4'b1011, 1'b1);
    complete_write(32'h0000_00C0, 32'h1357_9BDF, 4'b0101, 1'b0);

    // Offering a write channel and AR together must give write priority.
    @(negedge clk);
    s_axi_awaddr = 32'h0000_0440;
    s_axi_awvalid = 1;
    s_axi_araddr = 32'h0000_0550;
    s_axi_arvalid = 1;
    #1;
    require_true(s_axi_awready && !s_axi_arready, "write priority over AR changed");
    @(posedge clk);
    @(negedge clk);
    s_axi_awvalid = 0;
    s_axi_arvalid = 0;
    s_axi_wdata = 32'hCAFE_BABE;
    s_axi_wstrb = 4'hF;
    s_axi_wvalid = 1;
    #1;
    require_true(s_axi_wready, "priority-test W was not accepted");
    @(posedge clk);
    @(negedge clk);
    s_axi_wvalid = 0;
    wait (host_req_valid);
    require_true(host_req_write && host_req_addr == 17'h00440,
                 "priority write was not issued exactly once");
    @(negedge clk);
    host_req_ready = 1;
    @(posedge clk); #1;
    @(negedge clk);
    host_req_ready = 0;
    s_axi_bready = 1;
    wait (s_axi_bvalid);
    @(posedge clk); #1;
    @(negedge clk);
    s_axi_bready = 0;

    // Read request/response must hold while both downstream and AXI stall.
    @(negedge clk);
    s_axi_araddr = 32'h0001_3604;
    s_axi_arvalid = 1;
    #1;
    require_true(s_axi_arready, "AR was not accepted in idle");
    @(posedge clk);
    @(negedge clk);
    s_axi_arvalid = 0;
    wait (host_req_valid);
    require_true(!host_req_write && host_req_addr == 17'h13604,
                 "read address translation changed");
    repeat (2) begin
      @(posedge clk); #1;
      require_true(host_req_valid && !host_req_write && host_req_addr == 17'h13604,
                   "read request changed under host backpressure");
    end
    @(negedge clk);
    host_req_ready = 1;
    @(posedge clk); #1;
    @(negedge clk);
    host_req_ready = 0;
    wait (host_rsp_ready);
    @(negedge clk);
    host_rsp_rdata = 32'h5AA5_C33C;
    host_rsp_valid = 1;
    @(posedge clk); #1;
    @(negedge clk);
    host_rsp_valid = 0;
    wait (s_axi_rvalid);
    require_true(s_axi_rresp == 2'b00 && s_axi_rdata == 32'h5AA5_C33C,
                 "read response payload/response changed");
    repeat (2) begin
      @(posedge clk); #1;
      require_true(s_axi_rvalid && s_axi_rdata == 32'h5AA5_C33C,
                   "read response did not hold under AXI backpressure");
    end
    @(negedge clk);
    s_axi_rready = 1;
    @(posedge clk); #1;
    @(negedge clk);
    s_axi_rready = 0;
    @(posedge clk); #1;
    require_true(!s_axi_rvalid, "RVALID did not clear after handshake");

    reset = 1;
    @(posedge clk); #1;
    require_true(!host_req_valid && !s_axi_bvalid && !s_axi_rvalid,
                 "reset did not return bridge to idle");
    $display("PASS G2A_AXI_LITE_HOST_BRIDGE_PROTOCOL checks=%0d", checks);
    $finish;
  end
endmodule
