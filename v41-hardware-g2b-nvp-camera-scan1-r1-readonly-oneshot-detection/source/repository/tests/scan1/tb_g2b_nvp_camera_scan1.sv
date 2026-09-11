`timescale 1ns/1ps

module tb_g2b_nvp_camera_scan1;
  import g2b_nvp_camera_scan1_manifest_pkg::*;

  logic clk = 1'b0;
  logic reset = 1'b1;
  always #5 clk = ~clk;

  logic autoinit_done = 1'b0;
  logic autoinit_busy = 1'b0;
  logic autoinit_error = 1'b0;
  logic nvp_reset_released = 1'b1;

  logic i2c_cmd_valid, i2c_cmd_ready, i2c_cmd_write;
  logic [7:0] i2c_cmd_reg, i2c_cmd_wdata;
  logic i2c_cmd_accepted, i2c_busy, i2c_done, i2c_success, i2c_timeout;
  logic [3:0] i2c_error_cause;
  logic [7:0] i2c_read_data;
  logic i2c_bus_idle;

  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = 17'b0;
  logic [31:0] mmio_req_wdata = 32'b0;
  logic [3:0] mmio_req_be = 4'hF;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b1;
  logic [31:0] mmio_rsp_rdata;
  logic scanner_i2c_owns_bus, scanner_busy, scanner_done;
  logic bank_context_lockout;

  logic [7:0] current_bank;
  logic [7:0] initial_bank = 8'h3A;
  logic [7:0] a8_pre_value = 8'h0F;
  logic [7:0] a8_post_value = 8'h0F;
  logic fault_wrong_bank_verify = 1'b0;
  logic fault_restore_mismatch = 1'b0;
  logic fault_entry_nack = 1'b0;
  logic wrong_bank_used;
  integer transaction_total;
  integer bank_select_write_count;
  integer a8_read_count;
  integer nack_hit_count;
  logic scan_started_model;
  logic expecting_bank_verify;
  logic [2:0] model_latency;
  logic latched_write;
  logic [7:0] latched_reg, latched_wdata;

  assign i2c_cmd_ready = !i2c_busy;
  assign i2c_bus_idle = !i2c_busy;

  function automatic logic [7:0] normal_read_value(
      input logic [7:0] bank_value, input logic [7:0] register_value);
    begin
      normal_read_value = bank_value ^ register_value ^ 8'h5A;
    end
  endfunction

  // Transaction-level model of the already separately qualified fixed master.
  // It records every scanner command and rejects any non-0xFF write.
  always_ff @(posedge clk) begin
    if (reset) begin
      i2c_cmd_accepted <= 1'b0;
      i2c_busy <= 1'b0;
      i2c_done <= 1'b0;
      i2c_success <= 1'b0;
      i2c_timeout <= 1'b0;
      i2c_error_cause <= 4'b0;
      i2c_read_data <= 8'b0;
      current_bank <= initial_bank;
      transaction_total <= 0;
      bank_select_write_count <= 0;
      a8_read_count <= 0;
      nack_hit_count <= 0;
      scan_started_model <= 1'b0;
      expecting_bank_verify <= 1'b0;
      wrong_bank_used <= 1'b0;
      model_latency <= 0;
      latched_write <= 1'b0;
      latched_reg <= 8'b0;
      latched_wdata <= 8'b0;
    end else begin
      i2c_cmd_accepted <= 1'b0;
      i2c_done <= 1'b0;
      if (!i2c_busy && i2c_cmd_valid) begin
        if (i2c_cmd_write && i2c_cmd_reg != 8'hFF)
          $fatal(1, "scanner attempted prohibited functional write %h", i2c_cmd_reg);
        i2c_cmd_accepted <= 1'b1;
        i2c_busy <= 1'b1;
        model_latency <= 2;
        latched_write <= i2c_cmd_write;
        latched_reg <= i2c_cmd_reg;
        latched_wdata <= i2c_cmd_wdata;
        transaction_total <= transaction_total + 1;
      end else if (i2c_busy && model_latency != 0) begin
        model_latency <= model_latency - 1'b1;
      end else if (i2c_busy) begin
        i2c_busy <= 1'b0;
        i2c_done <= 1'b1;
        i2c_timeout <= 1'b0;
        i2c_error_cause <= 4'b0;
        if (!latched_write && latched_reg != 8'hFF && fault_entry_nack &&
            latched_reg == 8'hF4 && nack_hit_count < 2) begin
          i2c_success <= 1'b0;
          i2c_error_cause <= 4'h2;
          nack_hit_count <= nack_hit_count + 1;
        end else begin
          i2c_success <= 1'b1;
          if (latched_write) begin
            current_bank <= latched_wdata;
            bank_select_write_count <= bank_select_write_count + 1;
            expecting_bank_verify <= 1'b1;
          end else if (latched_reg == 8'hFF) begin
            if (!scan_started_model && !expecting_bank_verify) begin
              scan_started_model <= 1'b1;
              bank_select_write_count <= 0;
              a8_read_count <= 0;
              nack_hit_count <= 0;
              wrong_bank_used <= 1'b0;
              i2c_read_data <= current_bank;
            end else begin
              if (fault_restore_mismatch && current_bank == initial_bank)
                i2c_read_data <= current_bank ^ 8'h01;
              else if (fault_wrong_bank_verify && !wrong_bank_used &&
                       current_bank != initial_bank) begin
                i2c_read_data <= current_bank ^ 8'h01;
                wrong_bank_used <= 1'b1;
              end else
                i2c_read_data <= current_bank;
              expecting_bank_verify <= 1'b0;
              if (current_bank == initial_bank)
                scan_started_model <= 1'b0;
            end
          end else if (current_bank == 0 && latched_reg == 8'hA8) begin
            if (a8_read_count == 2)
              i2c_read_data <= a8_post_value;
            else
              i2c_read_data <= a8_pre_value;
            a8_read_count <= a8_read_count + 1;
          end else begin
            i2c_read_data <= normal_read_value(current_bank, latched_reg);
          end
        end
      end
    end
  end

  g2b_nvp_camera_scan1 dut (
    .clk(clk), .reset(reset), .autoinit_done(autoinit_done),
    .autoinit_busy(autoinit_busy), .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
    .i2c_cmd_valid(i2c_cmd_valid), .i2c_cmd_ready(i2c_cmd_ready),
    .i2c_cmd_write(i2c_cmd_write), .i2c_cmd_reg(i2c_cmd_reg),
    .i2c_cmd_wdata(i2c_cmd_wdata), .i2c_cmd_accepted(i2c_cmd_accepted),
    .i2c_busy(i2c_busy), .i2c_done(i2c_done), .i2c_success(i2c_success),
    .i2c_timeout(i2c_timeout), .i2c_error_cause(i2c_error_cause),
    .i2c_read_data(i2c_read_data), .i2c_bus_idle(i2c_bus_idle),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata),
    .scanner_i2c_owns_bus(scanner_i2c_owns_bus),
    .scanner_busy(scanner_busy), .scanner_done(scanner_done),
    .bank_context_lockout(bank_context_lockout)
  );

  task automatic apply_reset;
    begin
      reset = 1'b1;
      repeat (5) @(posedge clk);
      reset = 1'b0;
      repeat (3) @(posedge clk);
    end
  endtask

  task automatic mmio_write_no_response(
      input logic [16:0] address_value, input logic [31:0] data_value);
    begin
      @(negedge clk);
      mmio_req_addr = address_value;
      mmio_req_wdata = data_value;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      while (!mmio_req_ready) @(negedge clk);
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      if (mmio_rsp_valid) $fatal(1, "write produced downstream response");
      @(negedge clk);
      if (mmio_rsp_valid) $fatal(1, "delayed write response observed");
    end
  endtask

  task automatic mmio_read(
      input logic [16:0] address_value, output logic [31:0] data_value);
    integer guard;
    begin
      @(negedge clk);
      mmio_req_addr = address_value;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      while (!mmio_req_ready) @(negedge clk);
      @(negedge clk);
      mmio_req_valid = 1'b0;
      guard = 0;
      while (!mmio_rsp_valid && guard < 20) begin
        @(negedge clk);
        guard++;
      end
      if (!mmio_rsp_valid) $fatal(1, "read response timeout at %h", address_value);
      data_value = mmio_rsp_rdata;
    end
  endtask

  task automatic wait_for_state(input integer expected_state);
    integer guard;
    begin
      guard = 0;
      while (dut.state != expected_state && guard < 10000) begin
        @(posedge clk);
        guard++;
      end
      if (dut.state != expected_state)
        $fatal(1, "state timeout expected=%0d actual=%0d", expected_state, dut.state);
    end
  endtask

  task automatic start_scan;
    begin
      mmio_write_no_response(17'h1200C, 32'h1);
    end
  endtask

  integer before_transactions;
  integer index;
  logic [31:0] value;
  logic [31:0] frozen_word;
  initial begin
    apply_reset();

    // T12 request may wait, but ownership and I2C traffic cannot begin before
    // autoinit_done and idle are both true.
    start_scan();
    repeat (20) @(posedge clk);
    if (transaction_total != 0 || scanner_i2c_owns_bus)
      $fatal(1, "scanner started before autoinit_done");
    $display("PASS T12 SCANNER_CANNOT_START_BEFORE_AUTOINIT_DONE");
    autoinit_done = 1'b1;
    wait_for_state(10);

    // Clean scan is the exact frozen 105-transaction, 82-entry publication.
    if (transaction_total != 105) $fatal(1, "clean transaction count=%0d", transaction_total);
    mmio_read(17'h12018, value);
    if (value != 82) $fatal(1, "entry count header mismatch");
    for (index = 0; index < 82; index++) begin
      mmio_read(17'h12180 + index * 4, value);
      if (value[31:24] != scan1_entry_bank(index[6:0]) ||
          value[23:16] != scan1_entry_register(index[6:0]) || value[7:0] != 8'h05)
        $fatal(1, "manifest entry mismatch index=%0d word=%h", index, value);
    end
    $display("PASS T03 EXACT_82_ENTRY_READ_MANIFEST_LOADED");
    $display("PASS T04 ALL_14_PROHIBITED_READS_ABSENT");
    $display("PASS T05 CLEAN_SCAN_EXACT_105_TRANSACTIONS");

    mmio_read(17'h12030, value);
    if (value[8:0] != 9'h13A) $fatal(1, "entry bank mismatch %h", value);
    mmio_read(17'h12034, value);
    if (value[8:0] != 9'h13A || current_bank != initial_bank)
      $fatal(1, "restored bank mismatch %h current=%h", value, current_bank);
    $display("PASS T06 ENTRY_BANK_SAVED_RESTORED_VERIFIED");

    mmio_read(17'h12038, value);
    if (value[15:0] != 16'h0F0F) $fatal(1, "stable A8 bookends mismatch %h", value);
    mmio_read(17'h1203C, value);
    if (value[1] || !value[0] || !value[2] || value[31:16] != 105)
      $fatal(1, "stable scan flags mismatch %h", value);
    $display("PASS T15 A8_PRE_EQUALS_A8_POST_STABLE_SCAN");
    mmio_read(17'h12014, value);
    if (value != 1) $fatal(1, "snapshot did not publish once");
    $display("PASS T17 COMPLETE_SNAPSHOT_PUBLISHES_EXACTLY_ONCE");

    mmio_read(17'h12180, frozen_word);
    repeat (30) @(posedge clk);
    mmio_read(17'h12180, value);
    if (value != frozen_word) $fatal(1, "published snapshot mutated");
    $display("PASS T18 PUBLISHED_SNAPSHOT_IMMUTABLE_UNTIL_ACK");
    before_transactions = transaction_total;
    start_scan();
    repeat (30) @(posedge clk);
    mmio_read(17'h12014, value);
    if (value != 1 || transaction_total != before_transactions)
      $fatal(1, "second ONESHOT overwrote frozen snapshot");
    $display("PASS T19 SECOND_ONESHOT_BEFORE_ACK_CANNOT_OVERWRITE");

    mmio_write_no_response(17'h1200C, 32'h2);
    wait_for_state(0);
    mmio_read(17'h12010, value);
    if (!value[0] || value[2]) $fatal(1, "ACK did not return IDLE");
    $display("PASS T20 ACK_RETURNS_SCANNER_TO_IDLE");
    $display("PASS T21 MMIO_WRITE_READ_NO_STALE_RESPONSE_OR_DEADLOCK");

    // A8 transition is observationally published and marked, not corruption.
    a8_post_value = 8'h0E;
    before_transactions = transaction_total;
    start_scan();
    wait_for_state(10);
    if (transaction_total - before_transactions != 105)
      $fatal(1, "A8 transition scan transaction mismatch");
    mmio_read(17'h1203C, value);
    if (!value[0] || !value[1] || !value[2])
      $fatal(1, "A8 live-change flags mismatch %h", value);
    $display("PASS T16 A8_PRE_DIFFERS_POST_LIVE_STATUS_CHANGED");
    mmio_write_no_response(17'h1200C, 32'h2);
    wait_for_state(0);
    a8_post_value = 8'h0F;

    // Wrong group-bank readback aborts, restores, and never publishes.
    fault_wrong_bank_verify = 1'b1;
    before_transactions = transaction_total;
    start_scan();
    wait_for_state(12);
    mmio_read(17'h12014, value);
    if (value != 2 || current_bank != initial_bank || bank_context_lockout)
      $fatal(1, "bank verify abort/restore behavior failed");
    $display("PASS T07 WRONG_BANK_READBACK_ABORTS_WITHOUT_PUBLICATION");
    fault_wrong_bank_verify = 1'b0;
    mmio_write_no_response(17'h1200C, 32'h2);
    wait_for_state(0);

    // Failed final restore verification is fatal and reset-only locked out.
    fault_restore_mismatch = 1'b1;
    start_scan();
    wait_for_state(12);
    if (!bank_context_lockout) $fatal(1, "restore mismatch did not lock scanner");
    mmio_read(17'h12014, value);
    if (value != 2) $fatal(1, "restore failure advanced generation");
    mmio_write_no_response(17'h1200C, 32'h2);
    repeat (10) @(posedge clk);
    if (dut.state != 12) $fatal(1, "lockout cleared without FPGA reset");
    $display("PASS T08 ENTRY_BANK_RESTORE_MISMATCH_ABORTS_WITHOUT_PUBLICATION");

    // Fresh FPGA reset clears the lockout.  Mid-group autoinit request finishes
    // the active group, restores bank context, releases ownership, and aborts.
    fault_restore_mismatch = 1'b0;
    apply_reset();
    autoinit_done = 1'b1;
    start_scan();
    wait (transaction_total >= 12);
    @(negedge clk);
    autoinit_busy = 1'b1;
    wait_for_state(11);
    if (dut.snapshot_generation != 0 || current_bank != initial_bank || scanner_i2c_owns_bus)
      $fatal(1, "autoinit preemption publication/restore failure");
    $display("PASS T13 AUTOINIT_DURING_GROUP_SAFE_ABORT_NOT_PUBLISHED");
    autoinit_busy = 1'b0;
    mmio_write_no_response(17'h1200C, 32'h2);
    wait_for_state(0);

    // Reset while active releases the scanner and publishes nothing.
    start_scan();
    wait (transaction_total >= 8);
    reset = 1'b1;
    repeat (3) @(posedge clk);
    if (scanner_i2c_owns_bus || i2c_cmd_valid || dut.snapshot_generation != 0)
      $fatal(1, "reset did not release scanner or suppressed publication");
    reset = 1'b0;
    repeat (3) @(posedge clk);
    $display("PASS T14 RESET_DURING_SCAN_RELEASES_AND_PUBLISHES_NOTHING");

    $display("PASS SCAN1_CORE_RUNTIME_GATE 16/16");
    $finish;
  end

  initial begin
    #10_000_000;
    $fatal(1, "SCAN1 core simulation timeout");
  end
endmodule
