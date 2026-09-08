`timescale 1ns/1ps

// Transparent full-address extension router. Requests through 0x37ff retain
// the accepted legacy combinational path. G2B exclusively claims
// 0x3800..0x3bff. The diagnostic trace claims 0x3c00..0x3fff only in the
// explicitly selected DIAG1 profile; with the default parameter, that range
// remains on the byte-equivalent legacy path.
module v41_g2b_mmio_router #(
  parameter integer ENABLE_BT656_DIAG1 = 0
) (
  input  logic        host_req_valid,
  output logic        host_req_ready,
  input  logic        host_req_write,
  input  logic [16:0] host_req_addr,
  input  logic [31:0] host_req_wdata,
  input  logic [3:0]  host_req_be,
  output logic        host_rsp_valid,
  input  logic        host_rsp_ready,
  output logic [31:0] host_rsp_rdata,

  output logic        legacy_req_valid,
  input  logic        legacy_req_ready,
  output logic        legacy_req_write,
  output logic [16:0] legacy_req_addr,
  output logic [31:0] legacy_req_wdata,
  output logic [3:0]  legacy_req_be,
  input  logic        legacy_rsp_valid,
  output logic        legacy_rsp_ready,
  input  logic [31:0] legacy_rsp_rdata,

  output logic        g2b_req_valid,
  input  logic        g2b_req_ready,
  output logic        g2b_req_write,
  output logic [16:0] g2b_req_addr,
  output logic [31:0] g2b_req_wdata,
  output logic [3:0]  g2b_req_be,
  input  logic        g2b_rsp_valid,
  output logic        g2b_rsp_ready,
  input  logic [31:0] g2b_rsp_rdata,

  output logic        diag_req_valid,
  input  logic        diag_req_ready,
  output logic        diag_req_write,
  output logic [16:0] diag_req_addr,
  output logic [31:0] diag_req_wdata,
  output logic [3:0]  diag_req_be,
  input  logic        diag_rsp_valid,
  output logic        diag_rsp_ready,
  input  logic [31:0] diag_rsp_rdata
);
  wire g2b_select = host_req_addr >= 17'h03800 &&
                    host_req_addr <= 17'h03bff;
  wire diag_select = ENABLE_BT656_DIAG1 != 0 &&
                     host_req_addr >= 17'h03c00 &&
                     host_req_addr <= 17'h03fff;
  wire diag_rsp_active = ENABLE_BT656_DIAG1 != 0 && diag_rsp_valid;

  assign legacy_req_valid = host_req_valid && !g2b_select && !diag_select;
  assign legacy_req_write = host_req_write;
  assign legacy_req_addr = host_req_addr;
  assign legacy_req_wdata = host_req_wdata;
  assign legacy_req_be = host_req_be;

  assign g2b_req_valid = host_req_valid && g2b_select;
  assign g2b_req_write = host_req_write;
  assign g2b_req_addr = host_req_addr;
  assign g2b_req_wdata = host_req_wdata;
  assign g2b_req_be = host_req_be;

  assign diag_req_valid = host_req_valid && diag_select;
  assign diag_req_write = host_req_write;
  assign diag_req_addr = host_req_addr;
  assign diag_req_wdata = host_req_wdata;
  assign diag_req_be = host_req_be;

  assign host_req_ready = diag_select ? diag_req_ready :
                          g2b_select ? g2b_req_ready : legacy_req_ready;

  // Only one downstream request can be outstanding. ORing response-valid and
  // directly returning the selected responder preserves the legacy path.
  assign host_rsp_valid = legacy_rsp_valid || g2b_rsp_valid || diag_rsp_active;
  assign host_rsp_rdata = diag_rsp_active ? diag_rsp_rdata :
                          g2b_rsp_valid ? g2b_rsp_rdata : legacy_rsp_rdata;
  assign legacy_rsp_ready = host_rsp_ready && !g2b_rsp_valid &&
                            !diag_rsp_active;
  assign g2b_rsp_ready = host_rsp_ready && !diag_rsp_active;
  assign diag_rsp_ready = host_rsp_ready;
endmodule
