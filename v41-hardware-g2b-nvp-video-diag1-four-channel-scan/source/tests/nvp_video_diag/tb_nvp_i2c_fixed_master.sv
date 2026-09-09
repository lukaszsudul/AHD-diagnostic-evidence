`timescale 1ns/1ps

module tb_nvp_i2c_fixed_master;
  logic clk = 1'b0;
  logic rst = 1'b1;
  always #5 clk = ~clk;

  logic cmd_valid = 1'b0;
  logic cmd_ready;
  logic cmd_write = 1'b0;
  logic [7:0] cmd_reg = 8'b0;
  logic [7:0] cmd_wdata = 8'b0;
  logic cmd_accepted;
  logic busy;
  logic done;
  logic success;
  logic timeout;
  logic [7:0] read_data;
  logic [31:0] transaction_sequence;
  logic scl_release;
  logic sda_release;
  logic bus_idle;
  logic raw_scl_i;
  logic raw_sda_i;

  logic acknowledge = 1'b1;
  logic [7:0] slave_read_byte = 8'h5a;
  logic force_scl_low = 1'b0;
  logic force_sda_low = 1'b0;
  logic force_stop_sda_low = 1'b0;
  logic slave_sda_low;

  // White-box slave pins are used only to verify the extracted physical
  // engine's byte phases, open-drain behavior and bounded failure paths.
  always_comb begin
    slave_sda_low = 1'b0;
    if (acknowledge &&
        (dut.state == 6'd6 || dut.state == 6'd7 ||
         dut.state == 6'd10 || dut.state == 6'd11 ||
         dut.state == 6'd14 || dut.state == 6'd15 ||
         dut.state == 6'd22 || dut.state == 6'd23))
      slave_sda_low = 1'b1;
    if ((dut.state == 6'd24 || dut.state == 6'd25) &&
        !slave_read_byte[dut.bit_index])
      slave_sda_low = 1'b1;
    if (force_stop_sda_low && dut.state == 6'd30)
      slave_sda_low = 1'b1;
  end

  assign raw_scl_i = scl_release && !force_scl_low;
  assign raw_sda_i = sda_release && !slave_sda_low && !force_sda_low;

  nvp_i2c_fixed_master #(
    .CLK_HZ(1000000), .I2C_HZ(100000),
    .SCL_TIMEOUT_CYCLES(20), .BUS_IDLE_TIMEOUT_CYCLES(30)
  ) dut (
    .clk(clk), .rst(rst), .raw_scl_i(raw_scl_i), .raw_sda_i(raw_sda_i),
    .cmd_valid(cmd_valid), .cmd_ready(cmd_ready),
    .cmd_write(cmd_write), .cmd_reg(cmd_reg), .cmd_wdata(cmd_wdata),
    .cmd_accepted(cmd_accepted), .busy(busy), .done(done),
    .success(success), .timeout(timeout), .read_data(read_data),
    .transaction_sequence(transaction_sequence),
    .scl_release(scl_release), .sda_release(sda_release),
    .bus_idle(bus_idle)
  );

  task automatic run_command(input logic is_write,
                             input logic [7:0] address,
                             input logic [7:0] data);
    integer guard;
    begin
      guard = 0;
      while (!cmd_ready && guard < 1000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!cmd_ready) $fatal(1, "Command-ready timeout");
      @(negedge clk);
      cmd_write = is_write;
      cmd_reg = address;
      cmd_wdata = data;
      cmd_valid = 1'b1;
      @(negedge clk);
      cmd_valid = 1'b0;
      guard = 0;
      while (!done && guard < 10000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!done) $fatal(1, "Command completion timeout");
      @(negedge clk);
    end
  endtask

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    repeat (10) @(posedge clk);
    if (!cmd_ready || !bus_idle || !scl_release || !sda_release)
      $fatal(1, "Reset/idle open-drain state invalid");

    run_command(1'b1, 8'h78, 8'h46);
    if (!success || timeout) $fatal(1, "Documented register write failed");

    slave_read_byte = 8'ha5;
    run_command(1'b0, 8'ha8, 8'h00);
    if (!success || timeout || read_data != 8'ha5)
      $fatal(1, "Documented register read failed got=%h", read_data);

    acknowledge = 1'b0;
    run_command(1'b0, 8'he0, 8'h00);
    if (success || timeout) $fatal(1, "NACK classification failed");
    acknowledge = 1'b1;

    force_sda_low = 1'b1;
    run_command(1'b0, 8'he1, 8'h00);
    if (success || !timeout) $fatal(1, "Bus-idle timeout not bounded");
    force_sda_low = 1'b0;
    repeat (10) @(posedge clk);

    force_stop_sda_low = 1'b1;
    run_command(1'b1, 8'h79, 8'h13);
    if (success || !timeout)
      $fatal(1, "Final bus-idle qualification timeout not enforced");
    force_stop_sda_low = 1'b0;
    repeat (10) @(posedge clk);

    if (transaction_sequence != 5)
      $fatal(1, "Transaction sequence count mismatch: %0d",
             transaction_sequence);
    if (!scl_release || !sda_release)
      $fatal(1, "Failure path did not release open-drain pins");

    $display("PASS NVP_I2C_FIXED_MASTER_PHYSICAL_TRANSACTION_GATE");
    $display("PASS OPEN_DRAIN_RELEASE_AND_ONE_MASTER_INTERFACE");
    $display("PASS BOUNDED_NACK_BUS_IDLE_AND_FINAL_IDLE_FAILURES");
    $finish;
  end

  initial begin
    #3000000;
    $fatal(1, "Physical I2C engine simulation timeout");
  end
endmodule
