`timescale 1ns/1ps

module tb_nvp_probe_waveform #(
  parameter integer MODE_25 = 0
);
  logic clk = 1'b0;
  always #8 clk = ~clk; // 62.5 MHz
  logic control_write = 1'b0;
  logic [31:0] control_wdata = 32'b0;
  logic [3:0] control_be = 4'b0;
  logic slave_drive_low = 1'b0;
  wire owns, scl_oen, sda_oen;
  wire [31:0] status, count, nack_count, timeout_count;
  wire [31:0] divider, tick_cycles, campaign_index;
  wire scl_bus = scl_oen;
  wire sda_bus = slave_drive_low ? 1'b0 : sda_oen;
  integer bit_count = 0;
  logic in_transaction = 1'b0;
  logic ack_seen = 1'b0;
  integer fd;

  nvp_i2c_address_probe #(.TARGET_COUNT(2)) dut (
    .clk, .control_write, .control_wdata, .control_be,
    .init_done(1'b1), .init_busy(1'b0), .init_error(1'b1),
    .init_scl_oen(1'b1), .init_sda_oen(1'b1),
    .raw_scl_i(scl_bus), .raw_sda_i(sda_bus),
    .probe_owns_bus(owns), .probe_scl_oen(scl_oen),
    .probe_sda_oen(sda_oen), .probe_status(status), .probe_count(count),
    .probe_nack_count(nack_count), .probe_timeout_count(timeout_count),
    .probe_divider(divider), .probe_tick_cycles(tick_cycles),
    .probe_campaign_index(campaign_index)
  );

  always @(negedge sda_bus) if (owns && scl_bus && !in_transaction) begin
    in_transaction = 1'b1; bit_count = 0; ack_seen = 1'b0;
  end
  always @(posedge scl_bus) if (in_transaction) begin
    if (bit_count < 8) bit_count = bit_count + 1;
    else if (!ack_seen) ack_seen = 1'b1;
  end
  always @(negedge scl_bus) begin
    if (in_transaction && bit_count == 8 && !ack_seen)
      slave_drive_low = 1'b1;
    else if (ack_seen)
      slave_drive_low = 1'b0;
  end
  always @(posedge sda_bus) if (in_transaction && scl_bus) begin
    in_transaction = 1'b0; slave_drive_low = 1'b0;
  end

  always @(scl_bus or sda_bus or owns)
    if (fd) $fwrite(fd, "%0t,%0d,%0d,%0d,%0d,%0d\n",
                    $time, owns, scl_bus, sda_bus, count, nack_count);

  initial begin
    fd = $fopen(MODE_25 ? "../PROBE_WAVEFORM_25K.csv" :
                          "../PROBE_WAVEFORM_50K.csv", "w");
    $fwrite(fd, "time_ps,probe_owns_bus,scl,sda,probe_count,nack_count\n");
    repeat (10) @(posedge clk);
    @(negedge clk);
    control_wdata = MODE_25 ? 32'h3 : 32'h1;
    // A standalone 25-kHz waveform still must satisfy the lifecycle contract;
    // seed the campaign index/done state as if campaign 1 had completed.
    if (MODE_25) begin
      dut.probe_campaign_index = 1;
      dut.done = 1'b1;
    end
    control_be = 4'hF; control_write = 1'b1;
    @(posedge clk); @(negedge clk); control_write = 1'b0;
    wait (status[2]);
    if (status[3] || count != 2 || nack_count != 0 || timeout_count != 0)
      $fatal(1, "waveform probe failed");
    $fclose(fd);
    $display("PROBE_WAVEFORM_MODE_%0d=PASS", MODE_25);
    $finish;
  end
endmodule

module tb_nvp_probe_waveform_50;
  tb_nvp_probe_waveform #(.MODE_25(0)) tb();
endmodule

module tb_nvp_probe_waveform_25;
  tb_nvp_probe_waveform #(.MODE_25(1)) tb();
endmodule
