`timescale 1ns/1ps

// Combined diagnostic profile wrapper.  The accepted SCAN1 core is unchanged;
// this wrapper adds the separate fixed executor and arbitrates their single
// shared I2C command port at whole-action ownership boundaries.
module g2b_nvp_camera_scan1_acq1_compat0_r2 (
  input  logic        clk,
  input  logic        reset,
  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,

  output logic        i2c_cmd_valid,
  input  logic        i2c_cmd_ready,
  output logic        i2c_cmd_write,
  output logic [7:0]  i2c_cmd_reg,
  output logic [7:0]  i2c_cmd_wdata,
  input  logic        i2c_cmd_accepted,
  input  logic        i2c_busy,
  input  logic        i2c_done,
  input  logic        i2c_success,
  input  logic        i2c_timeout,
  input  logic [3:0]  i2c_error_cause,
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
  output logic        scanner_busy,
  output logic        scanner_done,
  output logic        executor_busy,
  output logic        executor_done,
  output logic        bank_context_lockout
);
  wire scan_select = mmio_req_addr >= 17'h12000 &&
                     mmio_req_addr <= 17'h123FF;
  wire acq_select = mmio_req_addr >= 17'h12400 &&
                    mmio_req_addr <= 17'h127FF;
  wire scan_start_blocked = executor_busy && mmio_req_write &&
                            mmio_req_addr == 17'h1200C &&
                            mmio_req_wdata == 32'h0000_0001;

  logic scan_mmio_req_ready, scan_mmio_rsp_valid;
  logic [31:0] scan_mmio_rsp_rdata;
  logic acq_mmio_req_ready, acq_mmio_rsp_valid;
  logic [31:0] acq_mmio_rsp_rdata;
  logic scan_i2c_cmd_valid, scan_i2c_cmd_write;
  logic [7:0] scan_i2c_cmd_reg, scan_i2c_cmd_wdata;
  logic acq_i2c_cmd_valid, acq_i2c_cmd_write;
  logic [7:0] acq_i2c_cmd_reg, acq_i2c_cmd_wdata;
  logic scan_owns, acq_owns;
  logic scan_lockout, acq_lockout;

  wire scan_grant = scan_owns || (scan_i2c_cmd_valid && !acq_owns);
  wire acq_grant = acq_owns || (acq_i2c_cmd_valid && !scan_owns);

  assign mmio_req_ready = scan_select ?
      (scan_start_blocked ? 1'b1 : scan_mmio_req_ready) :
      acq_select ? acq_mmio_req_ready : 1'b0;
  assign mmio_rsp_valid = scan_mmio_rsp_valid || acq_mmio_rsp_valid;
  assign mmio_rsp_rdata = acq_mmio_rsp_valid ? acq_mmio_rsp_rdata :
                                                scan_mmio_rsp_rdata;

  assign i2c_cmd_valid = scan_grant ? scan_i2c_cmd_valid :
                         acq_grant ? acq_i2c_cmd_valid : 1'b0;
  assign i2c_cmd_write = scan_grant ? scan_i2c_cmd_write :
                         acq_grant ? acq_i2c_cmd_write : 1'b0;
  assign i2c_cmd_reg = scan_grant ? scan_i2c_cmd_reg :
                       acq_grant ? acq_i2c_cmd_reg : 8'b0;
  assign i2c_cmd_wdata = scan_grant ? scan_i2c_cmd_wdata :
                         acq_grant ? acq_i2c_cmd_wdata : 8'b0;
  assign diagnostic_i2c_owns_bus = scan_owns || acq_owns;
  assign bank_context_lockout = scan_lockout || acq_lockout;

  g2b_nvp_camera_scan1 SCAN1_CORE (
    .clk(clk), .reset(reset), .autoinit_done(autoinit_done),
    .autoinit_busy(autoinit_busy), .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
    .i2c_cmd_valid(scan_i2c_cmd_valid),
    .i2c_cmd_ready(i2c_cmd_ready && !acq_owns),
    .i2c_cmd_write(scan_i2c_cmd_write), .i2c_cmd_reg(scan_i2c_cmd_reg),
    .i2c_cmd_wdata(scan_i2c_cmd_wdata),
    .i2c_cmd_accepted(i2c_cmd_accepted && scan_grant),
    .i2c_busy(i2c_busy), .i2c_done(i2c_done && scan_grant),
    .i2c_success(i2c_success), .i2c_timeout(i2c_timeout),
    .i2c_error_cause(i2c_error_cause), .i2c_read_data(i2c_read_data),
    .i2c_bus_idle(i2c_bus_idle && !acq_owns),
    .mmio_req_valid(mmio_req_valid && scan_select && !scan_start_blocked),
    .mmio_req_ready(scan_mmio_req_ready), .mmio_req_write(mmio_req_write),
    .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
    .mmio_req_be(mmio_req_be), .mmio_rsp_valid(scan_mmio_rsp_valid),
    .mmio_rsp_ready(mmio_rsp_ready), .mmio_rsp_rdata(scan_mmio_rsp_rdata),
    .scanner_i2c_owns_bus(scan_owns), .scanner_busy(scanner_busy),
    .scanner_done(scanner_done), .bank_context_lockout(scan_lockout)
  );

  g2b_nvp_acq1_compat0_r2 ACQ_EXECUTOR (
    .clk(clk), .reset(reset), .autoinit_done(autoinit_done),
    .autoinit_busy(autoinit_busy), .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released), .scanner_busy(scanner_busy),
    .i2c_cmd_valid(acq_i2c_cmd_valid),
    .i2c_cmd_ready(i2c_cmd_ready && !scan_owns),
    .i2c_cmd_write(acq_i2c_cmd_write), .i2c_cmd_reg(acq_i2c_cmd_reg),
    .i2c_cmd_wdata(acq_i2c_cmd_wdata),
    .i2c_cmd_accepted(i2c_cmd_accepted && acq_grant),
    .i2c_busy(i2c_busy), .i2c_done(i2c_done && acq_grant),
    .i2c_success(i2c_success), .i2c_timeout(i2c_timeout),
    .i2c_error_cause(i2c_error_cause), .i2c_read_data(i2c_read_data),
    .i2c_bus_idle(i2c_bus_idle && !scan_owns),
    .mmio_req_valid(mmio_req_valid && acq_select),
    .mmio_req_ready(acq_mmio_req_ready), .mmio_req_write(mmio_req_write),
    .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
    .mmio_req_be(mmio_req_be), .mmio_rsp_valid(acq_mmio_rsp_valid),
    .mmio_rsp_ready(mmio_rsp_ready), .mmio_rsp_rdata(acq_mmio_rsp_rdata),
    .executor_i2c_owns_bus(acq_owns), .executor_busy(executor_busy),
    .executor_done(executor_done), .bank_context_lockout(acq_lockout)
  );

  always_ff @(posedge clk) begin
    if (!reset && scan_i2c_cmd_valid && acq_i2c_cmd_valid)
      $error("SCAN1 and ACQ executor requested I2C simultaneously");
    if (!reset && scan_owns && acq_owns)
      $error("SCAN1 and ACQ executor ownership overlap");
  end
endmodule
