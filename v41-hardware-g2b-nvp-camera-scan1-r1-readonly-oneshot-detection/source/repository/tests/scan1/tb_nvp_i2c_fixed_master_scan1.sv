`timescale 1ns/1ps

module tb_nvp_i2c_fixed_master_scan1;
  logic clk = 1'b0;
  logic rst = 1'b1;
  always #5 clk = ~clk;

  logic cmd_valid = 1'b0;
  logic cmd_ready;
  logic cmd_write = 1'b0;
  logic [7:0] cmd_reg = 8'b0;
  logic [7:0] cmd_wdata = 8'b0;
  logic cmd_accepted, busy, done, success, timeout;
  logic [3:0] error_cause;
  logic [7:0] read_data;
  logic [31:0] transaction_sequence;
  logic scl_release, sda_release, bus_idle, raw_scl_i, raw_sda_i;
  logic [2:0] nack_phase = 3'b0;
  logic [7:0] slave_read_byte = 8'h5A;
  logic force_scl_low = 1'b0;
  logic force_sda_low = 1'b0;
  logic slave_sda_low;

  always_comb begin
    slave_sda_low = 1'b0;
    if ((dut.state == 6'd6 || dut.state == 6'd7) && nack_phase != 1)
      slave_sda_low = 1'b1;
    if ((dut.state == 6'd10 || dut.state == 6'd11) && nack_phase != 2)
      slave_sda_low = 1'b1;
    if ((dut.state == 6'd14 || dut.state == 6'd15) && nack_phase != 4)
      slave_sda_low = 1'b1;
    if ((dut.state == 6'd22 || dut.state == 6'd23) && nack_phase != 3)
      slave_sda_low = 1'b1;
    if ((dut.state == 6'd24 || dut.state == 6'd25) &&
        !slave_read_byte[dut.bit_index])
      slave_sda_low = 1'b1;
  end

  assign raw_scl_i = scl_release && !force_scl_low;
  assign raw_sda_i = sda_release && !slave_sda_low && !force_sda_low;

  nvp_i2c_fixed_master #(
    .CLK_HZ(1_000_000), .I2C_HZ(100_000),
    .SCL_TIMEOUT_CYCLES(20), .BUS_IDLE_TIMEOUT_CYCLES(30)
  ) dut (
    .clk(clk), .rst(rst), .raw_scl_i(raw_scl_i), .raw_sda_i(raw_sda_i),
    .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_write(cmd_write),
    .cmd_reg(cmd_reg), .cmd_wdata(cmd_wdata), .cmd_accepted(cmd_accepted),
    .busy(busy), .done(done), .success(success), .timeout(timeout),
    .error_cause(error_cause), .read_data(read_data),
    .transaction_sequence(transaction_sequence), .scl_release(scl_release),
    .sda_release(sda_release), .bus_idle(bus_idle)
  );

  task automatic run_command(input logic is_write,
                             input logic [7:0] address,
                             input logic [7:0] data);
    integer guard;
    begin
      guard = 0;
      while (!cmd_ready && guard < 1000) begin @(posedge clk); guard++; end
      if (!cmd_ready) $fatal(1, "command-ready timeout");
      @(negedge clk);
      cmd_write = is_write;
      cmd_reg = address;
      cmd_wdata = data;
      cmd_valid = 1'b1;
      @(negedge clk);
      cmd_valid = 1'b0;
      guard = 0;
      while (!done && guard < 10000) begin @(posedge clk); guard++; end
      if (!done) $fatal(1, "command completion timeout");
      @(negedge clk);
    end
  endtask

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    repeat (10) @(posedge clk);

    fork
      begin
        wait (dut.state == 6'd5);
        force_scl_low = 1'b1;
        repeat (8) @(posedge clk);
        force_scl_low = 1'b0;
      end
      run_command(1'b0, 8'hA8, 8'h00);
    join
    if (!success || timeout || error_cause != 0)
      $fatal(1, "legal clock stretch failed cause=%h", error_cause);
    $display("PASS T09 LEGAL_CLOCK_STRETCHING_COMPLETES");

    nack_phase = 1;
    run_command(1'b0, 8'hE0, 8'h00);
    if (success || timeout || error_cause != 1) $fatal(1, "WADDR cause failed");
    nack_phase = 2;
    run_command(1'b0, 8'hE0, 8'h00);
    if (success || timeout || error_cause != 2) $fatal(1, "REGADDR cause failed");
    nack_phase = 3;
    run_command(1'b0, 8'hE0, 8'h00);
    if (success || timeout || error_cause != 3) $fatal(1, "RADDR cause failed");
    nack_phase = 0;
    $display("PASS T10 ADDRESS_REGISTER_NACK_FROZEN_STATUS_CAUSE");

    fork
      begin
        wait (dut.state == 6'd5);
        force_scl_low = 1'b1;
        wait (done);
        @(negedge clk);
        force_scl_low = 1'b0;
      end
      run_command(1'b0, 8'hE1, 8'h00);
    join
    if (success || !timeout || error_cause != 5)
      $fatal(1, "SCL timeout cause failed cause=%h", error_cause);

    force_sda_low = 1'b1;
    run_command(1'b0, 8'hE1, 8'h00);
    if (success || !timeout || error_cause != 6)
      $fatal(1, "bus-idle timeout cause failed cause=%h", error_cause);
    force_sda_low = 1'b0;
    repeat (10) @(posedge clk);
    if (!scl_release || !sda_release)
      $fatal(1, "timeout path did not release open-drain pins");
    $display("PASS T11 FIXED_TIMEOUT_RECORDED_AND_SAFE_TERMINATION");
    $finish;
  end

  initial begin
    #4_000_000;
    $fatal(1, "SCAN1 fixed-master simulation timeout");
  end
endmodule
