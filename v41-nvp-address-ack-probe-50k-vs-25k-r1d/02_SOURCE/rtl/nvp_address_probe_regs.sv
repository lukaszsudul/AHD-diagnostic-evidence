`timescale 1ns/1ps

// Diagnostic-only interposer for the formally zero/reserved 0x2200..0x2228
// window.  All requests outside this exact range are forwarded unchanged.
module nvp_address_probe_regs (
  input  logic        clk,
  input  logic        reset,
  input  logic        host_req_valid,
  output logic        host_req_ready,
  input  logic        host_req_write,
  input  logic [16:0] host_req_addr,
  input  logic [31:0] host_req_wdata,
  input  logic [3:0]  host_req_be,
  output logic        host_rsp_valid,
  input  logic        host_rsp_ready,
  output logic [31:0] host_rsp_rdata,
  output logic        app_req_valid,
  input  logic        app_req_ready,
  output logic        app_req_write,
  output logic [16:0] app_req_addr,
  output logic [31:0] app_req_wdata,
  output logic [3:0]  app_req_be,
  input  logic        app_rsp_valid,
  output logic        app_rsp_ready,
  input  logic [31:0] app_rsp_rdata,
  output logic        control_write,
  output logic [31:0] control_wdata,
  output logic [3:0]  control_be,
  input  logic [31:0] probe_status,
  input  logic [31:0] probe_count,
  input  logic [31:0] probe_nack_count,
  input  logic [31:0] probe_timeout_count,
  input  logic [31:0] probe_divider,
  input  logic [31:0] probe_tick_cycles,
  input  logic [31:0] probe_campaign_index
);
  localparam logic [16:0] PROBE_BASE = 17'h02200;
  localparam logic [31:0] PROBE_MAGIC = 32'h31425250;
  localparam logic [31:0] PROBE_VERSION = 32'd1;
  localparam logic [31:0] PROBE_TARGET_COUNT = 32'd10000;

  logic local_rsp_valid = 1'b0;
  logic [31:0] local_rsp_rdata = 32'b0;
  wire probe_select = host_req_addr >= PROBE_BASE &&
                      host_req_addr <= PROBE_BASE + 17'h00028;
  wire [5:0] probe_offset = host_req_addr[5:0];

  function automatic [31:0] probe_read(input [5:0] offset);
    begin
      case (offset)
        6'h00: probe_read = PROBE_MAGIC;
        6'h04: probe_read = PROBE_VERSION;
        6'h08: probe_read = 32'b0;
        6'h0C: probe_read = probe_status;
        6'h10: probe_read = probe_count;
        6'h14: probe_read = probe_nack_count;
        6'h18: probe_read = probe_timeout_count;
        6'h1C: probe_read = PROBE_TARGET_COUNT;
        6'h20: probe_read = probe_divider;
        6'h24: probe_read = probe_tick_cycles;
        6'h28: probe_read = probe_campaign_index;
        default: probe_read = 32'b0;
      endcase
    end
  endfunction

  assign app_req_valid = host_req_valid && !probe_select;
  assign app_req_write = host_req_write;
  assign app_req_addr = host_req_addr;
  assign app_req_wdata = host_req_wdata;
  assign app_req_be = host_req_be;
  assign host_req_ready = probe_select ? !local_rsp_valid : app_req_ready;
  assign host_rsp_valid = probe_select ? local_rsp_valid : app_rsp_valid;
  assign host_rsp_rdata = probe_select ? local_rsp_rdata : app_rsp_rdata;
  assign app_rsp_ready = !probe_select && host_rsp_ready;

  always_ff @(posedge clk) begin
    control_write <= 1'b0;
    if (reset) begin
      local_rsp_valid <= 1'b0;
      local_rsp_rdata <= 32'b0;
      control_wdata <= 32'b0;
      control_be <= 4'b0;
    end else begin
      if (local_rsp_valid && host_rsp_ready)
        local_rsp_valid <= 1'b0;
      if (host_req_valid && host_req_ready && probe_select) begin
        local_rsp_valid <= 1'b1;
        local_rsp_rdata <= 32'b0;
        if (host_req_write) begin
          // Writes outside CONTROL are RAZ/WI and have no downstream effect.
          if (host_req_addr[1:0] == 2'b00 && probe_offset == 6'h08) begin
            control_write <= 1'b1;
            control_wdata <= host_req_wdata;
            control_be <= host_req_be;
          end
        end else if (host_req_addr[1:0] == 2'b00) begin
          local_rsp_rdata <= probe_read(probe_offset);
        end
      end
    end
  end
endmodule
