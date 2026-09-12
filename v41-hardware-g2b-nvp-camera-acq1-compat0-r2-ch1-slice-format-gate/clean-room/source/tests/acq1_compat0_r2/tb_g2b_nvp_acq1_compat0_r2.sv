`timescale 1ns/1ps

module tb_g2b_nvp_acq1_compat0_r2;
  logic clk = 0;
  always #5 clk = ~clk;

  logic reset;
  logic autoinit_done = 1;
  logic autoinit_busy = 0;
  logic autoinit_error = 0;
  logic nvp_reset_released = 1;
  logic scanner_busy = 0;
  logic i2c_cmd_valid;
  logic i2c_cmd_ready = 1;
  logic i2c_cmd_write;
  logic [7:0] i2c_cmd_reg;
  logic [7:0] i2c_cmd_wdata;
  wire i2c_cmd_accepted;
  logic i2c_busy = 0;
  wire i2c_done;
  wire i2c_success;
  wire i2c_timeout;
  wire [3:0] i2c_error_cause;
  logic [7:0] i2c_read_data;
  logic i2c_bus_idle = 1;
  logic mmio_req_valid = 0;
  logic mmio_req_ready;
  logic mmio_req_write = 0;
  logic [16:0] mmio_req_addr = 0;
  logic [31:0] mmio_req_wdata = 0;
  logic [3:0] mmio_req_be = 0;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1;
  logic [31:0] mmio_rsp_rdata;
  logic executor_i2c_owns_bus;
  logic executor_busy;
  logic executor_done;
  logic bank_context_lockout;

  g2b_nvp_acq1_compat0_r2 dut (.*);

  logic pending;
  logic pending_write;
  logic [7:0] pending_reg;
  logic [7:0] pending_wdata;
  integer pending_index;
  integer transaction_count;
  integer unauthorized_model_writes;
  logic [7:0] initial_bank = 8'h02;
  logic [7:0] initial_reg05 = 8'h24;
  logic [7:0] initial_reg08 = 8'h34;
  logic [7:0] current_bank;
  logic [7:0] reg05_model;
  logic [7:0] reg08_model;
  logic mutate05 = 0;
  logic mutate08 = 0;
  logic [7:0] mutation_value = 0;
  integer fault_at;
  integer fault_kind; // 1=NACK, 2=timeout, 3=successful corrupt read

  logic trace_write [0:4095];
  logic [7:0] trace_reg [0:4095];
  logic [7:0] trace_data [0:4095];
  logic [7:0] trace_bank [0:4095];

  wire fault_now = pending && pending_index == fault_at;
  assign i2c_cmd_accepted = i2c_cmd_valid && i2c_cmd_ready && !pending;
  assign i2c_done = pending;
  assign i2c_success = pending && !(fault_now && (fault_kind == 1 || fault_kind == 2));
  assign i2c_timeout = pending && fault_now && fault_kind == 2;
  assign i2c_error_cause = i2c_timeout ? 4'h2 :
                           (pending && fault_now && fault_kind == 1) ? 4'h1 : 4'h0;

  always_comb begin
    if (pending_reg == 8'hFF)
      i2c_read_data = current_bank;
    else if (current_bank == 8'h05 && pending_reg == 8'h05)
      i2c_read_data = reg05_model;
    else if (current_bank == 8'h05 && pending_reg == 8'h08)
      i2c_read_data = reg08_model;
    else
      i2c_read_data = 8'h00;
    if (pending && fault_now && fault_kind == 3 && !pending_write)
      i2c_read_data = i2c_read_data ^ 8'hFF;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      pending <= 0;
      pending_write <= 0;
      pending_reg <= 0;
      pending_wdata <= 0;
      pending_index <= 0;
      transaction_count <= 0;
      unauthorized_model_writes <= 0;
      current_bank <= initial_bank;
      reg05_model <= initial_reg05;
      reg08_model <= initial_reg08;
    end else begin
      if (pending) begin
        if (i2c_success && pending_write) begin
          if (pending_reg == 8'hFF)
            current_bank <= pending_wdata;
          else if (current_bank == 8'h05 && pending_reg == 8'h05)
            reg05_model <= pending_wdata;
          else if (current_bank == 8'h05 && pending_reg == 8'h08)
            reg08_model <= pending_wdata;
          else
            unauthorized_model_writes <= unauthorized_model_writes + 1;
        end
        pending <= 0;
      end
      if (i2c_cmd_accepted) begin
        trace_write[transaction_count] <= i2c_cmd_write;
        trace_reg[transaction_count] <= i2c_cmd_reg;
        trace_data[transaction_count] <= i2c_cmd_wdata;
        trace_bank[transaction_count] <= current_bank;
        transaction_count <= transaction_count + 1;
        pending_index <= transaction_count + 1;
        pending_write <= i2c_cmd_write;
        pending_reg <= i2c_cmd_reg;
        pending_wdata <= i2c_cmd_wdata;
        pending <= 1;
      end
      if (mutate05)
        reg05_model <= mutation_value;
      if (mutate08)
        reg08_model <= mutation_value;
    end
  end

  task automatic require(input logic condition, input string reason);
    if (condition !== 1'b1)
      $fatal(1, "ACQ1_COMPAT0_R2_TEST_FAIL %s", reason);
  endtask

  task automatic reset_case;
    begin
      fault_at = -1;
      fault_kind = 0;
      mmio_req_valid = 0;
      reset = 1;
      repeat (5) @(posedge clk);
      reset = 0;
      repeat (3) @(posedge clk);
    end
  endtask

  task automatic mmio_write(input logic [31:0] value);
    begin
      @(negedge clk);
      mmio_req_valid = 1;
      mmio_req_write = 1;
      mmio_req_addr = 17'h1240C;
      mmio_req_wdata = value;
      mmio_req_be = 4'hF;
      @(negedge clk);
      require(mmio_req_ready, "MMIO_COMMAND_NOT_READY");
      mmio_req_valid = 0;
      mmio_req_write = 0;
      mmio_req_be = 0;
    end
  endtask

  task automatic run_command(input logic [31:0] value);
    integer expected;
    integer cycles;
    begin
      expected = dut.command_sequence + 1;
      mmio_write(value);
      cycles = 0;
      while (dut.completed_sequence != expected && cycles < 2000) begin
        @(posedge clk);
        #1;
        cycles = cycles + 1;
      end
      require(cycles < 2000, "COMMAND_DID_NOT_COMPLETE");
      require(dut.command_sequence == expected, "COMMAND_SEQUENCE_MISMATCH");
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic mutate_reg05(input logic [7:0] value);
    begin
      @(negedge clk); mutation_value = value; mutate05 = 1;
      @(negedge clk); mutate05 = 0;
    end
  endtask

  task automatic mutate_reg08(input logic [7:0] value);
    begin
      @(negedge clk); mutation_value = value; mutate08 = 1;
      @(negedge clk); mutate08 = 0;
    end
  endtask

  task automatic prepare_three;
    begin
      run_command(1);
      run_command(1);
      run_command(1);
      require(dut.baseline_valid && dut.baseline_pass_count == 3,
              "THREE_PASS_BASELINE_NOT_VALID");
    end
  endtask

  task automatic bootstrap_dryrun;
    begin
      prepare_three();
      run_command(2);
      require(dut.dryrun_pass, "DRYRUN_NOT_PASS");
    end
  endtask

  task automatic check_txn(input integer index, input logic wr,
                           input logic [7:0] regaddr, input logic [7:0] data,
                           input string reason);
    begin
      require(trace_write[index] == wr, {reason, "_DIRECTION"});
      require(trace_reg[index] == regaddr, {reason, "_REGISTER"});
      if (wr)
        require(trace_data[index] == data, {reason, "_DATA"});
    end
  endtask

  task automatic check_slice(input integer start, input logic [7:0] level);
    begin
      require(transaction_count == start + 9, "SLICE_TRANSACTION_COUNT_NOT_9");
      check_txn(start+0, 0, 8'hFF, 0, "SLICE_CAPTURE_ENTRY");
      check_txn(start+1, 1, 8'hFF, 8'h05, "SLICE_SELECT_BANK5");
      check_txn(start+2, 0, 8'hFF, 0, "SLICE_VERIFY_BANK5");
      check_txn(start+3, 1, 8'h08, level, "SLICE_WRITE08");
      check_txn(start+4, 1, 8'h05, 8'hA4, "SLICE_WRITE05");
      check_txn(start+5, 0, 8'h08, 0, "SLICE_READ08");
      check_txn(start+6, 0, 8'h05, 0, "SLICE_READ05");
      check_txn(start+7, 1, 8'hFF, initial_bank, "SLICE_RESTORE_ENTRY");
      check_txn(start+8, 0, 8'hFF, 0, "SLICE_VERIFY_ENTRY");
      require(trace_bank[start+3] == 8'h05 && trace_bank[start+4] == 8'h05,
              "SLICE_FUNCTIONAL_WRITE_OUTSIDE_BANK5");
    end
  endtask

  task automatic check_exact_rollback;
    begin
      require(dut.rollback_invoked && dut.rollback_pass && dut.campaign_closed,
              "ROLLBACK_STATUS_NOT_PASS");
      require(current_bank == initial_bank && reg05_model == initial_reg05 &&
              reg08_model == initial_reg08, "ROLLBACK_MODEL_NOT_EXACT");
      require(dut.restored_entry_bank == initial_bank &&
              dut.restored_reg05 == initial_reg05 &&
              dut.restored_reg08 == initial_reg08, "ROLLBACK_READBACK_NOT_EXACT");
    end
  endtask

  integer start;
  initial begin
    reset = 1;

    // E09: pass A, pass B, and immediate prewrite pass capture all full bytes.
    reset_case();
    prepare_three();
    require(dut.baseline_entry_bank == initial_bank &&
            dut.baseline_reg05 == initial_reg05 && dut.baseline_reg08 == initial_reg08,
            "E09_BASELINE_BYTES");
    require(dut.functional_write_count == 0 && current_bank == initial_bank,
            "E09_BASELINE_SIDE_EFFECT");
    $display("PASS E09 baseline pass A/B captures full bytes and entry bank");

    // E10: pass-B mismatch is terminal before either functional register write.
    reset_case();
    run_command(1);
    mutate_reg05(initial_reg05 ^ 8'h01);
    run_command(1);
    require(dut.baseline_mismatch && bank_context_lockout &&
            dut.functional_write_count == 0 && current_bank == initial_bank,
            "E10_UNSTABLE_BASELINE_NOT_LOCKED_OUT");
    $display("PASS E10 unstable baseline blocks all functional writes");

    // E11: the third, immediate prewrite pass must still equal pass A/B.
    reset_case();
    run_command(1);
    run_command(1);
    mutate_reg08(initial_reg08 ^ 8'h01);
    run_command(1);
    require(dut.baseline_mismatch && bank_context_lockout &&
            dut.functional_write_count == 0 && current_bank == initial_bank,
            "E11_PREWRITE_MISMATCH_NOT_BLOCKED");
    $display("PASS E11 prewrite mismatch blocks all functional writes");

    // E12: the idempotent action writes 08 then 05 and reads both back.
    reset_case();
    prepare_three();
    start = transaction_count;
    run_command(2);
    require(transaction_count == start + 8 && dut.functional_write_count == 2,
            "E12_DRYRUN_COUNTS");
    check_txn(start+0, 1, 8'hFF, 8'h05, "DRY_SELECT_BANK5");
    check_txn(start+1, 0, 8'hFF, 0, "DRY_VERIFY_BANK5");
    check_txn(start+2, 1, 8'h08, initial_reg08, "DRY_WRITE08");
    check_txn(start+3, 1, 8'h05, initial_reg05, "DRY_WRITE05");
    check_txn(start+4, 0, 8'h08, 0, "DRY_READ08");
    check_txn(start+5, 0, 8'h05, 0, "DRY_READ05");
    check_txn(start+6, 1, 8'hFF, initial_bank, "DRY_RESTORE_ENTRY");
    check_txn(start+7, 0, 8'hFF, 0, "DRY_VERIFY_ENTRY");
    require(dut.dryrun_pass && reg05_model == initial_reg05 && reg08_model == initial_reg08,
            "E12_DRYRUN_RESULT");
    $display("PASS E12 idempotent baseline rewrite/readback dry run passes");

    reset_case(); bootstrap_dryrun(); start = transaction_count; run_command(3);
    check_slice(start, 8'h50);
    $display("PASS E13 SLICE_50 emits exact allowed transaction order");

    reset_case(); bootstrap_dryrun(); run_command(3); start = transaction_count; run_command(4);
    check_slice(start, 8'h40);
    $display("PASS E14 SLICE_40 emits exact allowed transaction order");

    reset_case(); bootstrap_dryrun(); run_command(3); run_command(4);
    start = transaction_count; run_command(5);
    check_slice(start, 8'h60);
    $display("PASS E15 SLICE_60 emits exact allowed transaction order");

    // E16: one NACK, one timeout, and one successful-but-wrong readback each
    // enter the same bounded rollback and permanently close that campaign.
    reset_case(); bootstrap_dryrun(); start = transaction_count;
    fault_at = transaction_count + 5; fault_kind = 1; run_command(3);
    check_exact_rollback();
    require(dut.last_result == 8'h03 && dut.nack_count == 1,
            "E16_NACK_ROLLBACK_RESULT");
    reset_case(); bootstrap_dryrun();
    fault_at = transaction_count + 6; fault_kind = 2; run_command(3);
    check_exact_rollback();
    require(dut.last_result == 8'h03 && dut.timeout_count == 1,
            "E16_TIMEOUT_ROLLBACK_RESULT");
    reset_case(); bootstrap_dryrun();
    fault_at = transaction_count + 6; fault_kind = 3; run_command(3);
    check_exact_rollback();
    require(dut.last_result == 8'h03 && dut.last_error == 8'h13,
            "E16_READBACK_ROLLBACK_RESULT");
    $display("PASS E16 NACK/timeout/readback failure triggers bounded abort/rollback");

    // E17: a Bank5 verify mismatch gets one entry-bank restore/verify attempt,
    // emits no functional register write, and then locks out the executor.
    reset_case();
    fault_at = 3; fault_kind = 3; run_command(1);
    require(dut.functional_write_count == 0 && bank_context_lockout &&
            dut.bank_verify_failure_count == 1 && current_bank == initial_bank &&
            transaction_count == 5, "E17_BANK_VERIFY_GUARD");
    $display("PASS E17 bank-verify failure prevents functional write");

    require(unauthorized_model_writes == 0, "UNAUTHORIZED_FUNCTIONAL_WRITE_OBSERVED");
    $display("UNAUTHORIZED_FUNCTIONAL_WRITE_COUNT=0");
    $display("ACQ1_COMPAT0_R2_EXECUTOR_SIMULATION_PASS E09-E17");
    $finish;
  end

  initial begin
    #2000000;
    $fatal(1, "ACQ1_COMPAT0_R2_TEST_TIMEOUT");
  end
endmodule
