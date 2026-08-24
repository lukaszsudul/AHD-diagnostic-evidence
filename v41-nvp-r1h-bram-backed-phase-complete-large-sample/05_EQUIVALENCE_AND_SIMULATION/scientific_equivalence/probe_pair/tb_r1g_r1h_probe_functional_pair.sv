`timescale 1ns/1ps
`include "probe_common_outputs_generated.svh"

interface probe_observables_if;
`define PROBE_X(width, name) logic [(width)-1:0] name;
  `PROBE_COMMON_OUTPUTS
`undef PROBE_X
endinterface

module tb_r1g_r1h_probe_functional_pair;
  localparam integer CLK_HZ = 1000000;
  localparam integer TARGET = 8;

  logic clk = 1'b0;
  logic rst = 1'b1;
  logic init_done = 1'b0;
  logic init_busy = 1'b1;
  logic nvp_rst = 1'b0;
  logic init_scl_release = 1'b1;
  logic init_sda_release = 1'b1;
  logic raw_scl_i;
  logic raw_sda_i;
  logic [47:0] freerun_count = 48'b0;
  logic [1:0] block_read_phase = 2'b0;
  logic [3:0] block_read_index = 4'b0;

  logic [1:0] ref_index_read_phase = 2'b0;
  logic [7:0] ref_index_read_word = 8'b0;
  logic [31:0] ref_index_read_data;
  logic cand_index_read_req = 1'b0;
  logic [1:0] cand_index_read_phase = 2'b0;
  logic [8:0] cand_index_read_address = 9'b0;
  logic cand_index_read_valid;
  logic [15:0] cand_index_read_data;

  probe_observables_if ref_o();
  probe_observables_if cand_o();

  logic slave_sda_release;
  logic [7:0] slave_bank = 8'h02;
  logic [7:0] slave_read_value;
  logic slave_nack_waddr, slave_nack_regaddr, slave_nack_data;
  integer compared_cycles = 0;
  integer transaction_start_events = 0;
  integer transaction_done_events = 0;
  integer index_creation_events = 0;
  logic [15:0] previous_stored_count [0:2];

  always #500 clk = ~clk;
  always_ff @(posedge clk) freerun_count <= freerun_count + 1'b1;

  assign raw_scl_i = ref_o.probe_scl_release;
  assign raw_sda_i = ref_o.probe_sda_release && slave_sda_release;

  always_comb begin
    slave_nack_waddr = 1'b0;
    slave_nack_regaddr = 1'b0;
    slave_nack_data = 1'b0;
    if (ref_o.probe_active) begin
      case (ref_dut.current_phase)
        2'd0: slave_nack_waddr =
                (ref_o.waddr_target_opportunities == 1 ||
                 ref_o.waddr_target_opportunities == 5);
        2'd1: begin
          slave_nack_waddr = (ref_o.regaddr_transaction_attempts == 1);
          slave_nack_regaddr = (ref_o.regaddr_target_opportunities == 2);
        end
        2'd2: begin
          slave_nack_waddr = (ref_o.data_transaction_attempts == 1);
          slave_nack_regaddr = (ref_o.data_transaction_attempts == 2);
          slave_nack_data = (ref_o.data_target_opportunities == 0 ||
                             ref_o.data_target_opportunities == 1);
        end
        default: begin end
      endcase
    end
    slave_read_value = (ref_dut.ll_reg_latched == 8'hff) ? slave_bank : 8'h00;
    slave_sda_release = 1'b1;
    case (ref_dut.ll_state)
      6'd6, 6'd7: slave_sda_release = slave_nack_waddr;
      6'd10, 6'd11: slave_sda_release = slave_nack_regaddr;
      6'd14, 6'd15: slave_sda_release = slave_nack_data;
      6'd22, 6'd23: slave_sda_release = 1'b0;
      6'd24, 6'd25: slave_sda_release = slave_read_value[ref_dut.ll_bit_index];
      default: slave_sda_release = 1'b1;
    endcase
  end

  always_ff @(posedge clk) begin
    if (ref_dut.ll_done && ref_dut.ll_success &&
        ref_dut.ll_kind_latched == 2'd2 && ref_dut.ll_reg_latched == 8'hff)
      slave_bank <= ref_dut.ll_data_latched;
  end

`define PROBE_X(width, name) .name(ref_o.name),
  r1g_nvp_i2c_tri_phase_probe_reference #(
    .CLK_HZ(CLK_HZ), .PROBE_I2C_HZ(25000),
    .TARGET_OPPORTUNITIES_PER_PHASE(TARGET), .BLOCK_COUNT_PER_PHASE(2),
    .NACK_INDEX_CAPACITY_PER_PHASE(4), .MAX_TRANSACTION_ATTEMPTS_PER_PHASE(12),
    .POST_INIT_GUARD_CYCLES(4), .SCL_TIMEOUT_CYCLES(200),
    .BUS_IDLE_TIMEOUT_CYCLES(2000)
  ) ref_dut (
    .clk, .rst, .init_done, .init_busy, .nvp_rst,
    .init_scl_release, .init_sda_release, .raw_scl_i, .raw_sda_i,
    .freerun_count,
    `PROBE_COMMON_OUTPUTS
    .index_read_phase(ref_index_read_phase),
    .index_read_word(ref_index_read_word),
    .index_read_data(ref_index_read_data),
    .block_read_phase, .block_read_index
  );
`undef PROBE_X

`define PROBE_X(width, name) .name(cand_o.name),
  nvp_i2c_tri_phase_probe #(
    .CLK_HZ(CLK_HZ), .PROBE_I2C_HZ(25000),
    .TARGET_OPPORTUNITIES_PER_PHASE(TARGET), .BLOCK_COUNT_PER_PHASE(2),
    .NACK_INDEX_CAPACITY_PER_PHASE(4), .MAX_TRANSACTION_ATTEMPTS_PER_PHASE(12),
    .POST_INIT_GUARD_CYCLES(4), .SCL_TIMEOUT_CYCLES(200),
    .BUS_IDLE_TIMEOUT_CYCLES(2000)
  ) cand_dut (
    .clk, .rst, .init_done, .init_busy, .nvp_rst,
    .init_scl_release, .init_sda_release, .raw_scl_i, .raw_sda_i,
    .freerun_count,
    `PROBE_COMMON_OUTPUTS
    .index_read_req(cand_index_read_req),
    .index_read_phase(cand_index_read_phase),
    .index_read_address(cand_index_read_address),
    .index_read_valid(cand_index_read_valid),
    .index_read_data(cand_index_read_data),
    .block_read_phase, .block_read_index
  );
`undef PROBE_X

  always @(posedge clk) begin : strict_cycle_comparator
    integer phase;
    #1;
    if (!rst) begin
`define PROBE_X(width, name) \
      if (cand_o.name !== ref_o.name) \
        $fatal(1, "common output mismatch at %0t", $time);
      `PROBE_COMMON_OUTPUTS
`undef PROBE_X
      if ({cand_dut.high_state, cand_dut.current_phase,
           cand_dut.ll_state, cand_dut.ll_start, cand_dut.ll_busy,
           cand_dut.ll_done, cand_dut.ll_success, cand_dut.ll_timeout,
           cand_dut.ll_waddr_reached, cand_dut.ll_waddr_ack,
           cand_dut.ll_reg_reached, cand_dut.ll_reg_ack,
           cand_dut.ll_data_reached, cand_dut.ll_data_ack,
           cand_dut.ll_raddr_reached, cand_dut.ll_raddr_ack,
           cand_dut.ll_kind_latched, cand_dut.ll_reg_latched,
           cand_dut.ll_data_latched, cand_dut.ll_read_data} !==
          {ref_dut.high_state, ref_dut.current_phase,
           ref_dut.ll_state, ref_dut.ll_start, ref_dut.ll_busy,
           ref_dut.ll_done, ref_dut.ll_success, ref_dut.ll_timeout,
           ref_dut.ll_waddr_reached, ref_dut.ll_waddr_ack,
           ref_dut.ll_reg_reached, ref_dut.ll_reg_ack,
           ref_dut.ll_data_reached, ref_dut.ll_data_ack,
           ref_dut.ll_raddr_reached, ref_dut.ll_raddr_ack,
           ref_dut.ll_kind_latched, ref_dut.ll_reg_latched,
           ref_dut.ll_data_latched, ref_dut.ll_read_data})
        $fatal(1, "functional/event stream mismatch at %0t", $time);
      compared_cycles = compared_cycles + 1;
      if (ref_dut.ll_start) transaction_start_events = transaction_start_events + 1;
      if (ref_dut.ll_done) transaction_done_events = transaction_done_events + 1;
      for (phase = 0; phase < 3; phase = phase + 1) begin
        if (ref_dut.nack_index_stored_count[phase] != previous_stored_count[phase]) begin
          if (!cand_dut.index_payload_write_valid ||
              cand_dut.index_payload_write_phase != phase[1:0] ||
              cand_dut.index_payload_write_address != previous_stored_count[phase][8:0] ||
              cand_dut.index_payload_write_data !==
                ref_dut.nack_index_memory[phase][previous_stored_count[phase]])
            $fatal(1, "index creation event mismatch phase=%0d at %0t", phase, $time);
          index_creation_events = index_creation_events + 1;
        end
        previous_stored_count[phase] = ref_dut.nack_index_stored_count[phase];
      end
    end else begin
      previous_stored_count[0] = 0;
      previous_stored_count[1] = 0;
      previous_stored_count[2] = 0;
    end
  end

  task automatic compare_index_entry(input integer phase, input integer entry);
    logic [15:0] expected;
    begin
      @(negedge clk);
      ref_index_read_phase = phase[1:0];
      ref_index_read_word = entry[8:1];
      cand_index_read_phase = phase[1:0];
      cand_index_read_address = entry[8:0];
      cand_index_read_req = 1'b1;
      #1;
      expected = entry[0] ? ref_index_read_data[31:16] : ref_index_read_data[15:0];
      @(posedge clk); #1;
      if (!cand_index_read_valid || cand_index_read_data !== expected)
        $fatal(1, "transactional index mismatch phase=%0d entry=%0d ref=%04x cand=%04x valid=%b",
               phase, entry, expected, cand_index_read_data, cand_index_read_valid);
      @(negedge clk); cand_index_read_req = 1'b0;
    end
  endtask

  initial begin : stimulus
    integer watchdog, phase, entry, block_index;
    repeat (8) @(posedge clk);
    rst <= 1'b0;
    repeat (8) @(posedge clk);
    nvp_rst <= 1'b1;
    init_busy <= 1'b0;
    init_done <= 1'b1;
    watchdog = 0;
    while (!ref_o.probe_terminal && watchdog < 200000) begin
      @(posedge clk); watchdog = watchdog + 1;
    end
    if (!ref_o.probe_terminal) $fatal(1, "reference did not terminate");
    repeat (3) @(posedge clk);
    if (!ref_o.probe_done || ref_o.probe_aborted || !cand_o.probe_done || cand_o.probe_aborted)
      $fatal(1, "unexpected terminal status");

    for (phase = 0; phase < 3; phase = phase + 1) begin
      case (phase)
        0: for (entry = 0; entry < ref_o.waddr_nack_index_stored_count; entry = entry + 1) compare_index_entry(phase,entry);
        1: for (entry = 0; entry < ref_o.regaddr_nack_index_stored_count; entry = entry + 1) compare_index_entry(phase,entry);
        2: for (entry = 0; entry < ref_o.data_nack_index_stored_count; entry = entry + 1) compare_index_entry(phase,entry);
      endcase
      for (block_index = 0; block_index < 2; block_index = block_index + 1) begin
        @(negedge clk); block_read_phase = phase[1:0]; block_read_index = block_index[3:0];
        #1;
        if (cand_o.block_read_nack_count !== ref_o.block_read_nack_count)
          $fatal(1, "block statistic mismatch phase=%0d block=%0d",phase,block_index);
      end
    end
    if (index_creation_events != 5) $fatal(1, "index event count=%0d expected=5",index_creation_events);
    if (transaction_start_events != transaction_done_events)
      $fatal(1, "transaction event imbalance starts=%0d done=%0d",transaction_start_events,transaction_done_events);
    $display("R1G_R1H_PROBE_CYCLE_BY_CYCLE_COMMON_OUTPUT_EQUIVALENCE=PASS");
    $display("R1G_R1H_PROBE_I2C_AND_FSM_EVENT_STREAM_EQUIVALENCE=PASS");
    $display("R1G_R1H_PROBE_BLOCK_STATISTICS_EQUIVALENCE=PASS");
    $display("R1G_R1H_PROBE_INDEX_TRANSACTION_EQUIVALENCE=PASS");
    $display("COMPARED_CYCLES=%0d",compared_cycles);
    $display("TRANSACTION_START_EVENTS=%0d",transaction_start_events);
    $display("TRANSACTION_DONE_EVENTS=%0d",transaction_done_events);
    $display("INDEX_CREATION_EVENTS=%0d",index_creation_events);
    $finish;
  end
endmodule
