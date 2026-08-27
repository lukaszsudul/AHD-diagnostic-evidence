`timescale 1ns/1ps

// Pin-level C1 isolation proof. The test observes only the unchanged public
// debug state and open-drain pins; it never reaches into candidate internals.
module tb_r1i_a_c1_semantics;
  localparam integer TICK = 20;
  // Frozen C3 path: five filter-pipeline clocks before the first protocol
  // observation, then the unchanged DIVIDER+1 dwell and terminal edge.
  localparam integer C3_ACK_HIGH_RESIDENCY = TICK + 6;
  localparam logic [7:0] ACK_W_LOW = 8'd6;
  localparam logic [7:0] ACK_W_HIGH = 8'd7;
  localparam logic [7:0] SEND_REG_LOW = 8'd8;
  localparam logic [7:0] ACK_REG_LOW = 8'd10;
  localparam logic [7:0] ACK_REG_HIGH = 8'd11;
  localparam logic [7:0] ACK_DATA_LOW = 8'd14;
  localparam logic [7:0] ACK_DATA_HIGH = 8'd15;
  localparam logic [7:0] REP_LOW = 8'd16;
  localparam logic [7:0] ACK_R_LOW = 8'd22;
  localparam logic [7:0] ACK_R_HIGH = 8'd23;
  localparam logic [7:0] READ_LOW = 8'd24;
  localparam logic [7:0] READ_HIGH = 8'd25;
  localparam logic [7:0] STOP_A = 8'd28;

  logic clk = 0;
  logic rst = 1;
  logic start = 0;
  logic slave_scl = 1;
  logic slave_sda = 1;
  wire scl_oen, sda_oen;
  wire scl_i = scl_oen & slave_scl;
  wire sda_i = sda_oen & slave_sda;
  wire busy, done, any_error;
  wire [127:0] values, afe_values;
  wire [63:0] output_values;
  wire [15:0] read_errors, aux_errors, afe_errors, nack_count;
  wire [15:0] timeout_count, serial_next;
  wire [7:0] write_errors, original_ff, restored_ff, meta_bank, phys_bank;
  wire phys_bank_valid, first_valid, record_valid;
  wire [7:0] phase_dbg, step_dbg, last_reg, last_wdata, last_rdata;
  wire [7:0] i2c_state, first_code;
  wire [2:0] last_op;
  wire [255:0] phase_counts;
  wire [127:0] txn_counts;
  wire [191:0] failed_record;
  wire [31:0] bank_errors;
  wire [1023:0] poc;
  integer cycle = 0;
  logic automatic_slave = 0;

  always #500 clk = ~clk;
  always @(posedge clk) cycle <= cycle + 1;
  always @(negedge clk) begin
    if (rst) begin
      slave_scl = 1;
      slave_sda = 1;
    end else if (automatic_slave) begin
      slave_scl = 1;
      case (i2c_state)
        ACK_W_LOW, ACK_W_HIGH, ACK_REG_LOW, ACK_REG_HIGH,
        ACK_DATA_LOW, ACK_DATA_HIGH, ACK_R_LOW, ACK_R_HIGH,
        READ_LOW, READ_HIGH: slave_sda = 0;
        default: slave_sda = 1;
      endcase
    end
  end

  r1i_master_test_adapter #(.CLK_HZ(1000000), .I2C_HZ(25000)) dut (
    .clk(clk), .rst(rst), .start(start), .scl_i(scl_i), .sda_i(sda_i),
    .scl_oen(scl_oen), .sda_oen(sda_oen), .busy(busy), .done(done),
    .any_error(any_error), .values(values), .afe_values(afe_values),
    .output_values(output_values), .read_errors(read_errors),
    .aux_errors(aux_errors), .afe_errors(afe_errors),
    .write_errors(write_errors), .original_ff(original_ff),
    .restored_ff(restored_ff), .meta_bank(meta_bank), .phys_bank(phys_bank),
    .phys_bank_valid(phys_bank_valid), .first_valid(first_valid),
    .phase_dbg(phase_dbg), .step_dbg(step_dbg), .last_reg(last_reg),
    .last_wdata(last_wdata), .last_rdata(last_rdata), .i2c_state(i2c_state),
    .first_code(first_code), .last_op(last_op), .nack_count(nack_count),
    .timeout_count(timeout_count), .serial_next(serial_next),
    .phase_counts(phase_counts), .txn_counts(txn_counts),
    .record_valid(record_valid), .failed_record(failed_record),
    .bank_errors(bank_errors), .poc(poc));

  task automatic require_true(input bit condition, input string reason);
    if (!condition) $fatal(1, "R1I_A_C1_FAIL %s state=%0d cycle=%0d", reason, i2c_state, cycle);
  endtask

  task automatic wait_state(input logic [7:0] wanted, input integer limit);
    integer count;
    begin
      count = 0;
      while (i2c_state !== wanted && count < limit) begin
        @(posedge clk); #1; count = count + 1;
      end
      require_true(i2c_state === wanted, "state wait timed out");
    end
  endtask

  function automatic logic [7:0] ack_low_state(input integer phase);
    case (phase)
      0: return ACK_W_LOW;
      1: return ACK_REG_LOW;
      2: return ACK_DATA_LOW;
      default: return ACK_R_LOW;
    endcase
  endfunction

  function automatic logic [7:0] ack_high_state(input integer phase);
    case (phase)
      0: return ACK_W_HIGH;
      1: return ACK_REG_HIGH;
      2: return ACK_DATA_HIGH;
      default: return ACK_R_HIGH;
    endcase
  endfunction

  function automatic logic [7:0] ack_successor(input integer phase);
    case (phase)
      0: return SEND_REG_LOW;
      1: return REP_LOW;
      2: return STOP_A;
      default: return READ_LOW;
    endcase
  endfunction

  task automatic start_to_ack_low(input integer phase);
    begin
      rst = 1; start = 0; automatic_slave = 1;
      slave_scl = 1; slave_sda = 1;
      repeat (10) @(posedge clk);
      #1 rst = 0;
      repeat (10) @(posedge clk);
      #1 start = 1;
      repeat (3) @(posedge clk);
      #1 start = 0;
      wait_state(ack_low_state(phase), 200000);
      automatic_slave = 0;
      require_true(scl_i === 1'b0 && sda_oen === 1'b1,
                   "ACK low must hold SCL low and release SDA");
    end
  endtask

  task automatic wait_ack_exit(input logic [7:0] high_state,
                               input integer entered,
                               output logic [7:0] next_state,
                               output integer high_cycles);
    begin
      while (i2c_state === high_state && cycle - entered < 200) begin
        @(posedge clk); #1;
      end
      require_true(i2c_state !== high_state, "ACK high did not terminate");
      high_cycles = cycle - entered;
      next_state = i2c_state;
    end
  endtask

  logic [7:0] next_state;
  integer high_cycles;
  integer normal_ack_cycles;
  integer ack_entry_cycle;
  integer phase;

  initial begin
    // C1-A: exercise the complete three-stage observation at every ACK phase:
    // passive end-of-LOW=NACK, first filtered-HIGH=ACK, terminal live SDA=NACK.
    // The selected result is ACK while early/false-early telemetry reconciles.
    for (phase = 0; phase < 4; phase = phase + 1) begin
      start_to_ack_low(phase);
      slave_sda = 1;
      // Make raw SDA lead raw SCL by four clocks. The unchanged filters make
      // selected SDA become ACK on the first observed-SCL-HIGH edge, then raw
      // SDA returns NACK so filtered SDA changes exactly one clock later.
      repeat (TICK - 3) @(posedge clk); #1;
      require_true(i2c_state === ack_low_state(phase),
                   "ACK-low preparation did not retain frozen dwell");
      slave_sda = 0;
      wait_state(ack_high_state(phase), 100);
      ack_entry_cycle = cycle;
      repeat (1) @(posedge clk); #1;
      slave_sda = 1;
      repeat (TICK - 2) begin
        @(posedge clk); #1;
        require_true(i2c_state === ack_high_state(phase),
                     "decision moved earlier than the original terminal tick");
      end
      wait_ack_exit(ack_high_state(phase), ack_entry_cycle,
                    next_state, high_cycles);
      require_true(next_state === ack_successor(phase),
                   "terminal decision used live SDA instead of held first-HIGH ACK");
      require_true(high_cycles == C3_ACK_HIGH_RESIDENCY,
                   "terminal timing differs from the frozen qualified-C3 schedule");
      require_true(poc[(3 + 4*phase)*32 +: 32] == 1 &&
                   poc[(4 + 4*phase)*32 +: 32] == 1 &&
                   poc[(5 + 4*phase)*32 +: 32] == 0 &&
                   poc[(6 + 4*phase)*32 +: 32] == 1,
                   "opportunity/early/selected/false-early lane mismatch");
      require_true(poc[19*32 +: 32] == 0 && nack_count == 0,
                   "held ACK was counted as selected NACK");
      if (phase == 0)
        normal_ack_cycles = high_cycles;
      else
        require_true(high_cycles == normal_ack_cycles,
                     "ACK phase changed the frozen terminal schedule");
      $display("PASS C1_PHASE%0d_FIRST_FILTERED_HIGH_ACK_HELD terminal_cycles=%0d",
               phase, high_cycles);
    end

    // C1-B: symmetric all-phase proof. First-HIGH NACK remains selected after
    // live SDA becomes ACK, and every phase aborts before any later phase.
    for (phase = 0; phase < 4; phase = phase + 1) begin
      start_to_ack_low(phase);
      slave_sda = 1;
      wait_state(ack_high_state(phase), 100);
      ack_entry_cycle = cycle;
      // Raw SDA changes one clock after raw SCL release, so the unchanged
      // filters change SDA exactly one controller edge after first SCL-HIGH.
      repeat (1) @(posedge clk); #1;
      slave_sda = 0;
      wait_ack_exit(ack_high_state(phase), ack_entry_cycle,
                    next_state, high_cycles);
      require_true(next_state === STOP_A,
                   "terminal decision did not retain first-HIGH NACK");
      require_true(high_cycles == normal_ack_cycles,
                   "selected value changed the frozen terminal schedule");
      require_true(poc[(3 + 4*phase)*32 +: 32] == 1 &&
                   poc[(4 + 4*phase)*32 +: 32] == 1 &&
                   poc[(5 + 4*phase)*32 +: 32] == 1 &&
                   poc[(6 + 4*phase)*32 +: 32] == 0,
                   "held-NACK phase lane mismatch");
      require_true(poc[19*32 +: 32] == 1 && nack_count == 1,
                   "held NACK was not counted exactly once");
      $display("PASS C1_PHASE%0d_FIRST_FILTERED_HIGH_NACK_HELD terminal_cycles=%0d",
               phase, high_cycles);
    end

    // C1-C: break the first HIGH interval after it selected NACK. The broken
    // interval must invalidate that value; the completing interval selects ACK.
    start_to_ack_low(0);
    slave_sda = 1;
    wait_state(ACK_W_HIGH, 100);
    ack_entry_cycle = cycle;
    repeat (7) @(posedge clk); #1;
    slave_scl = 0;
    repeat (7) @(posedge clk); #1;
    require_true(i2c_state === ACK_W_HIGH,
                 "broken HIGH interval advanced the protocol");
    // On the completing interval, give SDA the same four-clock physical lead
    // and one-clock filtered trailing transition used by the first-edge test.
    slave_sda = 0;
    repeat (4) @(posedge clk); #1;
    slave_scl = 1;
    repeat (1) @(posedge clk); #1;
    slave_sda = 1;
    wait_ack_exit(ACK_W_HIGH, ack_entry_cycle, next_state, high_cycles);
    require_true(next_state === SEND_REG_LOW,
                 "broken-interval value was not invalidated/resampled");
    require_true(high_cycles == normal_ack_cycles + 18,
                 "broken interval did not restart the exact qualified dwell schedule");
    $display("PASS C1_COMPLETING_INTERVAL_RESAMPLE terminal_cycles=%0d", high_cycles);

    // C1-D: delayed physical HIGH retains the exact C3 wait shell and then a
    // full terminal dwell. This is below the inherited 20-cycle timeout bound.
    start_to_ack_low(0);
    slave_sda = 0;
    slave_scl = 0;
    wait_state(ACK_W_HIGH, 100);
    ack_entry_cycle = cycle;
    repeat (8) @(posedge clk); #1;
    require_true(i2c_state === ACK_W_HIGH && phase_counts[31:0] == 0,
                 "SCL-low interval sampled or advanced ACK");
    slave_scl = 1;
    repeat (1) @(posedge clk); #1;
    slave_sda = 1;
    wait_ack_exit(ACK_W_HIGH, ack_entry_cycle, next_state, high_cycles);
    require_true(next_state === SEND_REG_LOW,
                 "delayed filtered HIGH did not complete normally");
    require_true(high_cycles == normal_ack_cycles + 8,
                 "delayed HIGH did not retain the exact divider reset/stall schedule");
    require_true(timeout_count == 0,
                 "sub-timeout delayed HIGH entered recovery");
    $display("PASS C1_DELAYED_FILTERED_HIGH_FULL_DWELL terminal_cycles=%0d", high_cycles);

    require_true(poc[31:0] == 32'h52314950 && poc[63:32] == 1 &&
                 poc[95:64] == 32'h3f,
                 "telemetry magic/version/policy changed");
    require_true(bank_errors == 0, "bank invariant changed");
    $display("PASS R1I_A_C1_SEMANTIC_SUITE");
    $finish;
  end

  initial begin
    #100000000;
    $fatal(1, "R1I_A_C1_TIMEOUT state=%0d", i2c_state);
  end
endmodule
