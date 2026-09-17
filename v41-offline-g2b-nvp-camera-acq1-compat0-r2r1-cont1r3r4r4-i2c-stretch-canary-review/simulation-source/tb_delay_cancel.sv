`timescale 1ns/1ps
// Unit negative control for the same cancel-on-repull digital input-rise
// mechanism used by the task-owned resolved-bus model. No RTL is compiled.
module tb_delay_cancel;
  logic driver_low = 1;
  tri1 scl_bus;
  logic raw_scl = 0;
  assign scl_bus = driver_low ? 1'b0 : 1'bz;
  always @(posedge scl_bus) begin
    #128;
    if (scl_bus === 1'b1) raw_scl = 1;
  end
  always @(negedge scl_bus) raw_scl = 0;
  initial begin
    #10; driver_low = 0; // pending delayed rise
    #16; driver_low = 1; // cancel before 128 ns
    #200;
    if (raw_scl !== 0 || scl_bus !== 0)
      $fatal(1, "STALE_RISE_GENERATED_AFTER_REPULL");
    #10; driver_low = 0;
    #160;
    if (raw_scl !== 1 || scl_bus !== 1)
      $fatal(1, "VALID_DELAYED_RISE_MISSING");
    #10; driver_low = 1;
    #1;
    if (raw_scl !== 0 || scl_bus !== 0)
      $fatal(1, "FALL_NOT_IMMEDIATE");
    $display("MODEL_DELAY_CANCELLATION_PASS");
    $finish;
  end
endmodule
