`timescale 1ns/1ps

// Mutually-exclusive DIAG2-RM1 profile island.  It combines the bounded
// C2-only route controller with the passive source-domain marker monitor.
module g2b_nvp_video_diag2_rm1 #(
  parameter integer CYCLES_PER_MS = 62500,
  parameter integer SETTLE_TIME_MS = 200,
  parameter integer RESPONSE_TIMEOUT_MS = 10,
  parameter logic [31:0] BUILD_FLAGS = 32'h0000_0000
) (
  input  logic        axi_clk,
  input  logic        axi_aresetn,
  input  logic        source_clk,
  input  logic        source_reset,
  input  logic        sample_valid,
  input  logic [7:0]  sample_byte,
  input  logic [1:0]  prefix_state,
  input  logic        candidate,
  input  logic        raw_parity_valid,
  input  logic        marker_f,
  input  logic        marker_v,
  input  logic        marker_h,
  input  logic        parser_qualified,
  input  logic [2:0]  parser_state,

  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,
  input  logic        transport_stream_enabled,
  input  logic        transport_c2h_active,
  input  logic        transport_ring_empty,
  input  logic        transport_ring_full,

  output logic        i2c_cmd_valid,
  input  logic        i2c_cmd_ready,
  output logic        i2c_cmd_write,
  output logic [7:0]  i2c_cmd_reg,
  output logic [7:0]  i2c_cmd_wdata,
  input  logic        i2c_cmd_accepted,
  input  logic        i2c_done,
  input  logic        i2c_success,
  input  logic        i2c_timeout,
  input  logic [7:0]  i2c_read_data,
  input  logic        i2c_bus_idle,

  input  logic        mmio_req_valid,
  output logic        mmio_req_ready,
  input  logic        mmio_req_write,
  input  logic [16:0] mmio_req_addr,
  input  logic [31:0] mmio_req_wdata,
  input  logic [3:0]  mmio_req_be,
  output logic        mmio_rsp_valid,
  input  logic        mmio_rsp_ready,
  output logic [31:0] mmio_rsp_rdata,

  output logic        diagnostic_i2c_owns_bus,
  output logic        product_baseline_restored
);
  wire transport_quiescent = !transport_stream_enabled &&
      !transport_c2h_active && transport_ring_empty && !transport_ring_full;

  logic route_start_pulse;
  logic route_restore_pulse;
  logic [2:0] route_target_channel;
  logic route_ready_pulse;
  logic route_busy;
  logic route_error;
  logic route_error_pulse;
  logic [15:0] route_error_code;
  logic route_restored;
  logic [7:0] original_bank;
  logic [7:0] original_route;
  logic [7:0] route_readback;
  logic [31:0] i2c_transaction_count;

  assign product_baseline_restored = route_restored;

  g2b_nvp_rm1_route_controller #(
    .CYCLES_PER_MS(CYCLES_PER_MS),
    .SETTLE_TIME_MS(SETTLE_TIME_MS)
  ) RM1_ROUTE_CONTROLLER (
    .clk(axi_clk), .reset(~axi_aresetn),
    .start_pulse(route_start_pulse),
    .restore_pulse(route_restore_pulse),
    .target_channel(route_target_channel),
    .autoinit_done(autoinit_done), .autoinit_busy(autoinit_busy),
    .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
    .transport_quiescent(transport_quiescent),
    .i2c_cmd_valid(i2c_cmd_valid), .i2c_cmd_ready(i2c_cmd_ready),
    .i2c_cmd_write(i2c_cmd_write), .i2c_cmd_reg(i2c_cmd_reg),
    .i2c_cmd_wdata(i2c_cmd_wdata),
    .i2c_cmd_accepted(i2c_cmd_accepted), .i2c_done(i2c_done),
    .i2c_success(i2c_success), .i2c_timeout(i2c_timeout),
    .i2c_read_data(i2c_read_data), .i2c_bus_idle(i2c_bus_idle),
    .diagnostic_i2c_owns_bus(diagnostic_i2c_owns_bus),
    .route_busy(route_busy), .route_ready_pulse(route_ready_pulse),
    .route_error(route_error), .route_error_pulse(route_error_pulse),
    .route_error_code(route_error_code),
    .route_restored(route_restored), .original_bank(original_bank),
    .original_route(original_route), .route_readback(route_readback),
    .i2c_transaction_count(i2c_transaction_count)
  );

  g2b_nvp_raw_marker_monitor #(
    .AXI_CYCLES_PER_MS(CYCLES_PER_MS),
    .RESPONSE_TIMEOUT_MS(RESPONSE_TIMEOUT_MS),
    .BUILD_FLAGS(BUILD_FLAGS)
  ) RM1_RAW_MARKER_MONITOR (
    .source_clk(source_clk), .source_reset(source_reset),
    .sample_valid(sample_valid), .sample_byte(sample_byte),
    .prefix_state(prefix_state), .candidate(candidate),
    .raw_parity_valid(raw_parity_valid),
    .marker_f(marker_f), .marker_v(marker_v), .marker_h(marker_h),
    .parser_qualified(parser_qualified), .parser_state(parser_state),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .route_start_pulse(route_start_pulse),
    .route_restore_pulse(route_restore_pulse),
    .route_target_channel(route_target_channel),
    .route_ready_pulse(route_ready_pulse), .route_busy(route_busy),
    .route_error(route_error), .route_error_pulse(route_error_pulse),
    .route_error_code(route_error_code),
    .route_restored(route_restored), .route_original(original_route),
    .route_readback(route_readback),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata)
  );
endmodule
