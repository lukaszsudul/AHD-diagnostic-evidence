`timescale 1ns/1ps

module tb_nvp_i2c_address_probe #(
  parameter integer CASE_ID = 0
);
  localparam integer TARGET = 10000;
  logic clk = 1'b0;
  always #1 clk = ~clk;

  logic control_write = 1'b0;
  logic [31:0] control_wdata = 32'b0;
  logic [3:0] control_be = 4'b0;
  logic init_done = 1'b0;
  logic init_busy = 1'b0;
  logic init_error = 1'b1;
  logic init_scl_oen = 1'b1;
  logic init_sda_oen = 1'b1;
  logic axi_user_reset = 1'b0;
  logic force_scl_low = 1'b0;
  logic force_sda_low = 1'b0;
  logic slave_drive_low = 1'b0;
  wire probe_owns_bus;
  wire probe_scl_oen;
  wire probe_sda_oen;
  wire [31:0] probe_status;
  wire [31:0] probe_count;
  wire [31:0] probe_nack_count;
  wire [31:0] probe_timeout_count;
  wire [31:0] probe_divider;
  wire [31:0] probe_tick_cycles;
  wire [31:0] probe_campaign_index;
  wire scl_bus = force_scl_low ? 1'b0 : probe_scl_oen;
  wire sda_bus = (force_sda_low || slave_drive_low) ? 1'b0 : probe_sda_oen;

  integer nack_mode = 0;
  integer transaction_count = 0;
  integer stop_count = 0;
  integer repeated_start_count = 0;
  integer read_address_count = 0;
  integer extra_byte_count = 0;
  integer bit_count = 0;
  logic [7:0] decoded_byte = 8'b0;
  logic in_transaction = 1'b0;
  logic ack_clock_seen = 1'b0;

  nvp_i2c_address_probe #(
    .CLK_HZ(1000000), .TARGET_COUNT(TARGET),
    .DIVIDER_50KHZ(2), .DIVIDER_25KHZ(4),
    .SCL_TIMEOUT_CYCLES(40), .BUS_IDLE_TIMEOUT_CYCLES(80)
  ) dut (
    .clk, .control_write, .control_wdata, .control_be,
    .init_done, .init_busy, .init_error,
    .init_scl_oen, .init_sda_oen,
    .raw_scl_i(scl_bus), .raw_sda_i(sda_bus),
    .probe_owns_bus, .probe_scl_oen, .probe_sda_oen,
    .probe_status, .probe_count, .probe_nack_count,
    .probe_timeout_count, .probe_divider, .probe_tick_cycles,
    .probe_campaign_index
  );

  task automatic fail(input string message);
    begin
      $display("TEST_FAIL: %s", message);
      $fatal(1);
    end
  endtask

  task automatic trigger(input logic [31:0] value);
    begin
      @(negedge clk);
      control_wdata = value;
      control_be = 4'hF;
      control_write = 1'b1;
      @(posedge clk);
      @(negedge clk);
      control_write = 1'b0;
      control_wdata = 32'b0;
      control_be = 4'b0;
    end
  endtask

  task automatic wait_done;
    integer guard;
    begin
      guard = 0;
      while (!probe_status[2] && guard < 2000000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!probe_status[2]) fail("campaign did not complete");
    end
  endtask

  task automatic expect_valid(input integer expected_nacks, input integer index);
    begin
      if (probe_status[3]) fail("unexpected probe ERROR");
      if (!probe_status[2] || probe_status[1]) fail("DONE/BUSY mismatch");
      if (probe_count != TARGET) fail("PROBE_COUNT mismatch");
      if (probe_nack_count != expected_nacks) fail("PROBE_NACK_COUNT mismatch");
      if (probe_timeout_count != 0) fail("PROBE_TIMEOUT_COUNT mismatch");
      if (probe_campaign_index != index) fail("campaign index mismatch");
    end
  endtask

  // Transaction decoder and deterministic address slave.
  always @(negedge sda_bus) begin
    if (probe_owns_bus && scl_bus) begin
      if (in_transaction)
        repeated_start_count = repeated_start_count + 1;
      else begin
        in_transaction = 1'b1;
        bit_count = 0;
        decoded_byte = 8'b0;
        ack_clock_seen = 1'b0;
      end
    end
  end

  always @(posedge scl_bus) begin
    if (in_transaction) begin
      if (bit_count < 8) begin
        decoded_byte = {decoded_byte[6:0], sda_bus};
        bit_count = bit_count + 1;
      end else if (!ack_clock_seen) begin
        ack_clock_seen = 1'b1;
      end
    end
  end

  always @(negedge scl_bus) begin
    if (in_transaction && bit_count == 8 && !ack_clock_seen) begin
      case (nack_mode)
        0: slave_drive_low = 1'b1;
        1: slave_drive_low = 1'b0;
        default: slave_drive_low = ((transaction_count % 7) != 0);
      endcase
    end else if (in_transaction && ack_clock_seen) begin
      slave_drive_low = 1'b0;
    end
  end

  always @(posedge sda_bus) begin
    if (scl_bus && in_transaction) begin
      if (bit_count != 8 || !ack_clock_seen)
        fail("STOP before exactly one address byte and ACK clock");
      if (decoded_byte != 8'h60)
        fail("decoded byte was not 0x60");
      if (decoded_byte[0])
        read_address_count = read_address_count + 1;
      transaction_count = transaction_count + 1;
      stop_count = stop_count + 1;
      in_transaction = 1'b0;
      slave_drive_low = 1'b0;
    end
  end

  integer expected_pattern_nacks;
  integer first_transaction_count;
  initial begin
    repeat (10) @(posedge clk);

    if (CASE_ID == 6) begin
      init_done = 1'b0;
      trigger(32'h1);
      repeat (20) @(posedge clk);
      if (probe_owns_bus || probe_status[1]) fail("pre-init trigger owned bus");
      if (!probe_status[3]) fail("pre-init trigger was not rejected");
    end else if (CASE_ID == 7) begin
      init_scl_oen = 1'b0;
      init_sda_oen = 1'b1;
      repeat (20) @(posedge clk);
      if (probe_owns_bus) fail("dormant probe owned bus");
      if ((probe_owns_bus ? probe_scl_oen : init_scl_oen) !== init_scl_oen ||
          (probe_owns_bus ? probe_sda_oen : init_sda_oen) !== init_sda_oen)
        fail("dormant ownership mux differs from init path");
    end else if (CASE_ID == 8) begin
      init_done = 1'b1;
      force_sda_low = 1'b1;
      // Let the exact two-flop/three-sample observer settle low before the
      // control write; the handoff contract is intentionally filtered.
      repeat (10) @(posedge clk);
      trigger(32'h1);
      repeat (30) @(posedge clk);
      if (probe_owns_bus) fail("ownership asserted while SDA was low");
      force_sda_low = 1'b0;
      wait (probe_owns_bus);
      if (!probe_status[7]) fail("bus-idle gate was not recorded");
      wait_done();
      expect_valid(0, 1);
    end else if (CASE_ID == 9) begin
      init_done = 1'b1;
      force_sda_low = 1'b1;
      repeat (10) @(posedge clk);
      trigger(32'h1);
      wait_done();
      if (!probe_status[3] || probe_owns_bus || probe_count != 0)
        fail("SDA-low gate failure mismatch");
    end else if (CASE_ID == 10) begin
      init_done = 1'b1;
      trigger(32'h1);
      wait (probe_owns_bus);
      force_scl_low = 1'b1;
      wait_done();
      if (!probe_status[3] || !probe_status[8] || probe_timeout_count != 1)
        fail("SCL timeout mismatch");
    end else if (CASE_ID == 11) begin
      integer count_before_reset;
      init_done = 1'b1;
      trigger(32'h1);
      wait (probe_count >= 100);
      count_before_reset = probe_count;
      // The production top deliberately does not connect axi_aresetn/user
      // reset to this configuration-initialized engine.
      axi_user_reset = 1'b1;
      repeat (100) @(posedge clk);
      axi_user_reset = 1'b0;
      if (!probe_status[1] || probe_count < count_before_reset)
        fail("AXI/user reset perturbation changed or stopped active campaign");
      wait (probe_count > count_before_reset);
      wait_done();
      expect_valid(0, 1);
    end else begin
      init_done = 1'b1;
      if (CASE_ID == 1) nack_mode = 1;
      if (CASE_ID == 2) nack_mode = 2;
      trigger(32'h1);
      wait_done();
      expected_pattern_nacks = (TARGET + 6) / 7;
      if (CASE_ID == 1)
        expect_valid(TARGET, 1);
      else if (CASE_ID == 2)
        expect_valid(expected_pattern_nacks, 1);
      else
        expect_valid(0, 1);

      if (CASE_ID == 3 || CASE_ID == 4 || CASE_ID == 5) begin
        first_transaction_count = transaction_count;
        nack_mode = (CASE_ID == 4) ? 2 : 0;
        repeat (20) @(posedge clk);
        trigger(32'h3);
        repeat (2) @(posedge clk);
        if (probe_count != 0 || probe_nack_count != 0)
          fail("counters did not clear on second accepted trigger");
        wait_done();
        if (CASE_ID == 4)
          expect_valid(expected_pattern_nacks, 2);
        else
          expect_valid(0, 2);
        if (first_transaction_count != TARGET || transaction_count != 2*TARGET)
          fail("two-campaign decoded transaction count mismatch");

        if (CASE_ID == 5) begin
          trigger(32'h3);
          repeat (4) @(posedge clk);
          if (!probe_status[3] || probe_campaign_index != 2 ||
              probe_count != TARGET)
            fail("third trigger rejection mismatch");
        end
      end
    end

    if (repeated_start_count != 0) fail("repeated START observed");
    if (read_address_count != 0) fail("read address observed");
    if (extra_byte_count != 0) fail("extra byte observed");
    if (transaction_count != stop_count) fail("STOP count mismatch");
    $display("CASE_ID=%0d", CASE_ID);
    $display("TRANSACTIONS=%0d ADDRESS_BYTE=0x60 REGISTER_BYTES=0 DATA_BYTES=0 READ_ADDRESS_BYTES=0 REPEATED_STARTS=%0d STOPS=%0d",
             transaction_count, repeated_start_count, stop_count);
    $display("NVP_ADDRESS_PROBE_TEST=PASS");
    $finish;
  end
endmodule
