`timescale 1ns/1ps

// Governed ACQ1-COMPAT0-R2 fixed-action executor.
//
// The host selects one of seven compiled actions.  No host-supplied bank,
// register, value, mask, channel, or delay reaches the I2C command interface.
// The only functional registers reachable here are CH1 Bank5/0x08 and 0x05.
module g2b_nvp_acq1_compat0_r2 (
  input  logic        clk,
  input  logic        reset,
  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,
  input  logic        scanner_busy,

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

  output logic        executor_i2c_owns_bus,
  output logic        executor_busy,
  output logic        executor_done,
  output logic        bank_context_lockout
);
  localparam logic [31:0] ACQ_MAGIC = 32'h4E56_4143;
  localparam logic [31:0] ACQ_VERSION = 32'h0001_0000;
  localparam logic [31:0] ACQ_CAPABILITIES = 32'h0000_00FF;
  localparam logic [31:0] SANITY_TOKEN = 32'h434F_4D50;

  localparam logic [7:0] BANK5 = 8'h05;
  localparam logic [7:0] BANK_SELECT = 8'hFF;
  localparam logic [7:0] REG_LEVEL = 8'h08;
  localparam logic [7:0] REG_COMPANION = 8'h05;
  localparam logic [7:0] COMPANION_VALUE = 8'hA4;

  localparam logic [3:0] CMD_NONE = 4'd0;
  localparam logic [3:0] CMD_PREPARE_BASELINE = 4'd1;
  localparam logic [3:0] CMD_DRYRUN_REWRITE_BASELINE = 4'd2;
  localparam logic [3:0] CMD_APPLY_SLICE_50 = 4'd3;
  localparam logic [3:0] CMD_APPLY_SLICE_40 = 4'd4;
  localparam logic [3:0] CMD_APPLY_SLICE_60 = 4'd5;
  localparam logic [3:0] CMD_ROLLBACK = 4'd6;
  localparam logic [3:0] CMD_ABORT_AND_ROLLBACK = 4'd7;

  localparam logic [7:0] RESULT_NONE = 8'h00;
  localparam logic [7:0] RESULT_PASS = 8'h01;
  localparam logic [7:0] RESULT_REJECTED = 8'h02;
  localparam logic [7:0] RESULT_FAILED_ROLLBACK_PASS = 8'h03;
  localparam logic [7:0] RESULT_HARD_FAIL = 8'hFF;

  localparam logic [7:0] ERR_NONE = 8'h00;
  localparam logic [7:0] ERR_PREREQUISITE = 8'h01;
  localparam logic [7:0] ERR_SEQUENCE = 8'h02;
  localparam logic [7:0] ERR_BASELINE_MISMATCH = 8'h03;
  localparam logic [7:0] ERR_I2C = 8'h10;
  localparam logic [7:0] ERR_TIMEOUT = 8'h11;
  localparam logic [7:0] ERR_BANK_VERIFY = 8'h12;
  localparam logic [7:0] ERR_READBACK = 8'h13;
  localparam logic [7:0] ERR_ENTRY_RESTORE = 8'h14;
  localparam logic [7:0] ERR_ABORTED = 8'h15;
  localparam logic [7:0] ERR_ROLLBACK = 8'h20;

  typedef enum logic [5:0] {
    ST_IDLE,
    ST_SAVE_ENTRY,
    ST_SELECT_BANK5,
    ST_VERIFY_BANK5,
    ST_BASE_READ05,
    ST_BASE_READ08,
    ST_WRITE08,
    ST_WRITE05,
    ST_READBACK08,
    ST_READBACK05,
    ST_RESTORE_ENTRY,
    ST_VERIFY_ENTRY,
    ST_RB_SAVE_ENTRY,
    ST_RB_SELECT_BANK5,
    ST_RB_VERIFY_BANK5,
    ST_RB_WRITE08,
    ST_RB_READ08,
    ST_RB_WRITE05,
    ST_RB_READ05,
    ST_RB_RESTORE_ENTRY,
    ST_RB_VERIFY_ENTRY,
    ST_FAIL_RESTORE_ENTRY,
    ST_FAIL_VERIFY_ENTRY,
    ST_HARD_FAIL
  } executor_state_t;

  executor_state_t state;
  logic [3:0] active_command;
  logic [3:0] command_pulse;
  logic abort_pulse;
  logic txn_inflight;
  logic abort_pending;
  logic rollback_active;
  logic prior_failure_pending;
  logic [7:0] pending_failure_code;
  logic write_occurred_campaign;
  logic campaign_closed;

  logic [31:0] command_sequence;
  logic [31:0] completed_sequence;
  logic [31:0] rejected_command_count;
  logic [31:0] functional_write_count;
  logic [31:0] nack_count;
  logic [31:0] timeout_count;
  logic [31:0] bank_verify_failure_count;
  logic [31:0] sanity_count;
  logic [31:0] sanity_readback;
  logic [7:0] last_result;
  logic [7:0] last_error;
  logic [3:0] last_command;

  logic baseline_valid;
  logic [1:0] baseline_pass_count;
  logic baseline_mismatch;
  logic dryrun_pass;
  logic rollback_invoked;
  logic rollback_pass;
  logic [1:0] slice_stage;
  logic [2:0] slice_executed_mask;
  logic [7:0] baseline_entry_bank;
  logic [7:0] baseline_reg05;
  logic [7:0] baseline_reg08;
  logic [7:0] observed_entry_bank;
  logic [7:0] observed_reg05;
  logic [7:0] observed_reg08;
  logic [7:0] action_entry_bank;
  logic [7:0] target_level;
  logic [7:0] last_level_readback;
  logic [7:0] last_companion_readback;
  logic [7:0] restored_entry_bank;
  logic [7:0] restored_reg05;
  logic [7:0] restored_reg08;

  function automatic logic active_state(input executor_state_t value);
    begin
      active_state = value != ST_IDLE && value != ST_HARD_FAIL;
    end
  endfunction

  function automatic logic is_rollback_state(input executor_state_t value);
    begin
      case (value)
        ST_RB_SAVE_ENTRY, ST_RB_SELECT_BANK5, ST_RB_VERIFY_BANK5, ST_RB_WRITE08,
        ST_RB_READ08, ST_RB_WRITE05, ST_RB_READ05,
        ST_RB_RESTORE_ENTRY, ST_RB_VERIFY_ENTRY: is_rollback_state = 1'b1;
        default: is_rollback_state = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [7:0] failure_code;
    begin
      failure_code = i2c_timeout ? ERR_TIMEOUT : ERR_I2C;
    end
  endfunction

  function automatic logic [31:0] status_word;
    begin
      status_word = 32'b0;
      status_word[0] = state == ST_IDLE;
      status_word[1] = executor_busy;
      status_word[2] = executor_done;
      status_word[3] = last_result == RESULT_HARD_FAIL;
      status_word[4] = autoinit_done;
      status_word[5] = autoinit_busy;
      status_word[6] = executor_i2c_owns_bus;
      status_word[7] = bank_context_lockout;
      status_word[13:8] = state;
      status_word[14] = baseline_valid;
      status_word[15] = baseline_mismatch;
      status_word[17:16] = baseline_pass_count;
      status_word[18] = dryrun_pass;
      status_word[19] = rollback_invoked;
      status_word[20] = rollback_pass;
      status_word[21] = campaign_closed;
      status_word[22] = scanner_busy;
      status_word[23] = i2c_bus_idle;
    end
  endfunction

  function automatic logic [31:0] mmio_read_word(input logic [16:0] address_value);
    begin
      case (address_value)
        17'h12400: mmio_read_word = ACQ_MAGIC;
        17'h12404: mmio_read_word = ACQ_VERSION;
        17'h12408: mmio_read_word = ACQ_CAPABILITIES;
        17'h1240C: mmio_read_word = 32'b0;
        17'h12410: mmio_read_word = status_word();
        17'h12414: mmio_read_word = command_sequence;
        17'h12418: mmio_read_word = completed_sequence;
        17'h1241C: mmio_read_word = {12'b0, last_command, last_error, last_result};
        17'h12420: mmio_read_word = {23'b0, slice_stage, rollback_pass,
                                           rollback_invoked, dryrun_pass,
                                           baseline_mismatch, baseline_pass_count,
                                           baseline_valid};
        17'h12424: mmio_read_word = {8'b0, baseline_entry_bank,
                                           baseline_reg05, baseline_reg08};
        17'h12428: mmio_read_word = {8'b0, observed_entry_bank,
                                           observed_reg05, observed_reg08};
        17'h1242C: mmio_read_word = functional_write_count;
        17'h12430: mmio_read_word = 32'b0;
        17'h12434: mmio_read_word = {bank_verify_failure_count[7:0],
                                           timeout_count[7:0], nack_count[15:0]};
        17'h12438: mmio_read_word = {16'b0, last_companion_readback,
                                            last_level_readback};
        17'h1243C: mmio_read_word = {16'h0805, COMPANION_VALUE, target_level};
        17'h12440: mmio_read_word = {21'b0, campaign_closed,
                                           slice_executed_mask, 5'b0,
                                           write_occurred_campaign, prior_failure_pending};
        17'h12444: mmio_read_word = {8'b0, restored_entry_bank,
                                           restored_reg05, restored_reg08};
        17'h12448: mmio_read_word = rejected_command_count;
        17'h1247C: mmio_read_word = sanity_readback;
        17'h12480: mmio_read_word = sanity_count;
        default: mmio_read_word = 32'b0;
      endcase
    end
  endfunction

  task automatic note_i2c_failure;
    begin
      last_error <= failure_code();
      if (i2c_timeout)
        timeout_count <= timeout_count + 1'b1;
      else
        nack_count <= nack_count + 1'b1;
    end
  endtask

  task automatic finish_failure_or_start_rollback(input logic [7:0] code);
    begin
      last_error <= code;
      prior_failure_pending <= 1'b1;
      if (write_occurred_campaign && baseline_valid) begin
        rollback_invoked <= 1'b1;
        rollback_active <= 1'b1;
        state <= ST_RB_SAVE_ENTRY;
      end else if (state != ST_SAVE_ENTRY) begin
        // No functional byte was written, but a successful Bank5 selection
        // may have changed the shared bank context.  Make exactly one bounded
        // restore/verify attempt before entering the permanent lockout.
        pending_failure_code <= code;
        state <= ST_FAIL_RESTORE_ENTRY;
      end else begin
        last_result <= RESULT_HARD_FAIL;
        completed_sequence <= command_sequence;
        state <= ST_HARD_FAIL;
      end
    end
  endtask

  assign mmio_req_ready = !mmio_rsp_valid || mmio_rsp_ready;

  always_comb begin
    executor_busy = active_state(state);
    executor_done = !executor_busy && command_sequence != 0 &&
                    completed_sequence == command_sequence;
    executor_i2c_owns_bus = executor_busy;

    i2c_cmd_valid = 1'b0;
    i2c_cmd_write = 1'b0;
    i2c_cmd_reg = 8'b0;
    i2c_cmd_wdata = 8'b0;
    if (!txn_inflight && !bank_context_lockout) begin
      case (state)
        ST_SAVE_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        ST_RB_SAVE_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        ST_SELECT_BANK5, ST_RB_SELECT_BANK5: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = BANK5;
        end
        ST_VERIFY_BANK5, ST_RB_VERIFY_BANK5: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        ST_BASE_READ05: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_COMPANION;
        end
        ST_BASE_READ08: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_LEVEL;
        end
        ST_WRITE08: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = REG_LEVEL;
          i2c_cmd_wdata = target_level;
        end
        ST_WRITE05: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = REG_COMPANION;
          i2c_cmd_wdata = active_command == CMD_DRYRUN_REWRITE_BASELINE ?
                          baseline_reg05 : COMPANION_VALUE;
        end
        ST_READBACK08: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_LEVEL;
        end
        ST_READBACK05: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_COMPANION;
        end
        ST_RESTORE_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = action_entry_bank;
        end
        ST_VERIFY_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        ST_RB_WRITE08: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = REG_LEVEL;
          i2c_cmd_wdata = baseline_reg08;
        end
        ST_RB_READ08: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_LEVEL;
        end
        ST_RB_WRITE05: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = REG_COMPANION;
          i2c_cmd_wdata = baseline_reg05;
        end
        ST_RB_READ05: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = REG_COMPANION;
        end
        ST_RB_RESTORE_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = baseline_entry_bank;
        end
        ST_RB_VERIFY_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        ST_FAIL_RESTORE_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = action_entry_bank;
        end
        ST_FAIL_VERIFY_ENTRY: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        default: begin end
      endcase
    end
  end

  // MMIO writes create only enumerated command pulses or the fixed sanity
  // token.  Reads produce one retained response.
  always_ff @(posedge clk) begin
    if (reset) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      command_pulse <= CMD_NONE;
      abort_pulse <= 1'b0;
      sanity_count <= 32'b0;
      sanity_readback <= 32'b0;
    end else begin
      command_pulse <= CMD_NONE;
      abort_pulse <= 1'b0;
      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;
      if (mmio_req_valid && mmio_req_ready) begin
        if (mmio_req_write) begin
          if (mmio_req_addr == 17'h1240C && mmio_req_be == 4'hF) begin
            case (mmio_req_wdata)
              32'h0000_0001: command_pulse <= CMD_PREPARE_BASELINE;
              32'h0000_0002: command_pulse <= CMD_DRYRUN_REWRITE_BASELINE;
              32'h0000_0003: command_pulse <= CMD_APPLY_SLICE_50;
              32'h0000_0004: command_pulse <= CMD_APPLY_SLICE_40;
              32'h0000_0005: command_pulse <= CMD_APPLY_SLICE_60;
              32'h0000_0006: command_pulse <= CMD_ROLLBACK;
              32'h0000_0007: abort_pulse <= 1'b1;
              default: command_pulse <= CMD_NONE;
            endcase
          end else if (mmio_req_addr == 17'h1247C &&
                       mmio_req_be == 4'hF && mmio_req_wdata == SANITY_TOKEN) begin
            sanity_readback <= SANITY_TOKEN;
            sanity_count <= sanity_count + 1'b1;
          end
        end else begin
          mmio_rsp_rdata <= mmio_read_word(mmio_req_addr);
          mmio_rsp_valid <= 1'b1;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= ST_IDLE;
      active_command <= CMD_NONE;
      txn_inflight <= 1'b0;
      abort_pending <= 1'b0;
      rollback_active <= 1'b0;
      prior_failure_pending <= 1'b0;
      pending_failure_code <= ERR_NONE;
      write_occurred_campaign <= 1'b0;
      campaign_closed <= 1'b0;
      bank_context_lockout <= 1'b0;
      command_sequence <= 32'b0;
      completed_sequence <= 32'b0;
      rejected_command_count <= 32'b0;
      functional_write_count <= 32'b0;
      nack_count <= 32'b0;
      timeout_count <= 32'b0;
      bank_verify_failure_count <= 32'b0;
      last_result <= RESULT_NONE;
      last_error <= ERR_NONE;
      last_command <= CMD_NONE;
      baseline_valid <= 1'b0;
      baseline_pass_count <= 2'b0;
      baseline_mismatch <= 1'b0;
      dryrun_pass <= 1'b0;
      rollback_invoked <= 1'b0;
      rollback_pass <= 1'b0;
      slice_stage <= 2'b0;
      slice_executed_mask <= 3'b0;
      baseline_entry_bank <= 8'b0;
      baseline_reg05 <= 8'b0;
      baseline_reg08 <= 8'b0;
      observed_entry_bank <= 8'b0;
      observed_reg05 <= 8'b0;
      observed_reg08 <= 8'b0;
      action_entry_bank <= 8'b0;
      target_level <= 8'b0;
      last_level_readback <= 8'b0;
      last_companion_readback <= 8'b0;
      restored_entry_bank <= 8'b0;
      restored_reg05 <= 8'b0;
      restored_reg08 <= 8'b0;
    end else begin
      if (i2c_cmd_accepted) begin
        txn_inflight <= 1'b1;
        if (i2c_cmd_write && i2c_cmd_reg != BANK_SELECT) begin
          functional_write_count <= functional_write_count + 1'b1;
          write_occurred_campaign <= 1'b1;
        end
      end

      if (abort_pulse) begin
        if (state == ST_IDLE && write_occurred_campaign && baseline_valid &&
            !campaign_closed) begin
          active_command <= CMD_ABORT_AND_ROLLBACK;
          last_command <= CMD_ABORT_AND_ROLLBACK;
          command_sequence <= command_sequence + 1'b1;
          last_error <= ERR_ABORTED;
          last_result <= RESULT_NONE;
          rollback_invoked <= 1'b1;
          rollback_active <= 1'b1;
          prior_failure_pending <= 1'b1;
          state <= ST_RB_SAVE_ENTRY;
        end else if (state != ST_IDLE && state != ST_HARD_FAIL) begin
          abort_pending <= 1'b1;
        end else begin
          rejected_command_count <= rejected_command_count + 1'b1;
        end
      end

      if (command_pulse != CMD_NONE) begin
        if (state != ST_IDLE || scanner_busy || campaign_closed ||
            !autoinit_done || autoinit_busy || autoinit_error ||
            !nvp_reset_released || !i2c_bus_idle) begin
          rejected_command_count <= rejected_command_count + 1'b1;
          last_command <= command_pulse;
          last_result <= RESULT_REJECTED;
          last_error <= ERR_PREREQUISITE;
        end else begin
          case (command_pulse)
            CMD_PREPARE_BASELINE: begin
              command_sequence <= command_sequence + 1'b1;
              active_command <= command_pulse;
              last_command <= command_pulse;
              last_result <= RESULT_NONE;
              last_error <= ERR_NONE;
              action_entry_bank <= 8'b0;
              state <= ST_SAVE_ENTRY;
            end
            CMD_DRYRUN_REWRITE_BASELINE: begin
              if (!baseline_valid || baseline_pass_count != 2'd3 ||
                  baseline_mismatch || dryrun_pass) begin
                rejected_command_count <= rejected_command_count + 1'b1;
                last_command <= command_pulse;
                last_result <= RESULT_REJECTED;
                last_error <= ERR_PREREQUISITE;
              end else begin
                command_sequence <= command_sequence + 1'b1;
                active_command <= command_pulse;
                last_command <= command_pulse;
                last_result <= RESULT_NONE;
                last_error <= ERR_NONE;
                action_entry_bank <= baseline_entry_bank;
                target_level <= baseline_reg08;
                state <= ST_SELECT_BANK5;
              end
            end
            CMD_APPLY_SLICE_50, CMD_APPLY_SLICE_40, CMD_APPLY_SLICE_60: begin
              if (!dryrun_pass ||
                  (command_pulse == CMD_APPLY_SLICE_50 && slice_stage != 0) ||
                  (command_pulse == CMD_APPLY_SLICE_40 && slice_stage != 1) ||
                  (command_pulse == CMD_APPLY_SLICE_60 && slice_stage != 2)) begin
                rejected_command_count <= rejected_command_count + 1'b1;
                last_command <= command_pulse;
                last_result <= RESULT_REJECTED;
                last_error <= ERR_SEQUENCE;
              end else begin
                command_sequence <= command_sequence + 1'b1;
                active_command <= command_pulse;
                last_command <= command_pulse;
                last_result <= RESULT_NONE;
                last_error <= ERR_NONE;
                target_level <= command_pulse == CMD_APPLY_SLICE_50 ? 8'h50 :
                                command_pulse == CMD_APPLY_SLICE_40 ? 8'h40 : 8'h60;
                state <= ST_SAVE_ENTRY;
              end
            end
            CMD_ROLLBACK: begin
              if (!baseline_valid || !write_occurred_campaign) begin
                rejected_command_count <= rejected_command_count + 1'b1;
                last_command <= command_pulse;
                last_result <= RESULT_REJECTED;
                last_error <= ERR_PREREQUISITE;
              end else begin
                command_sequence <= command_sequence + 1'b1;
                active_command <= command_pulse;
                last_command <= command_pulse;
                last_result <= RESULT_NONE;
                last_error <= ERR_NONE;
                rollback_invoked <= 1'b1;
                rollback_active <= 1'b1;
                prior_failure_pending <= 1'b0;
                state <= ST_RB_SAVE_ENTRY;
              end
            end
            default: begin
              rejected_command_count <= rejected_command_count + 1'b1;
            end
          endcase
        end
      end

      case (state)
        ST_IDLE: begin
          txn_inflight <= 1'b0;
          abort_pending <= 1'b0;
        end

        ST_SAVE_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else if (abort_pending) begin
              finish_failure_or_start_rollback(ERR_ABORTED);
            end else begin
              observed_entry_bank <= i2c_read_data;
              action_entry_bank <= i2c_read_data;
              if (active_command != CMD_PREPARE_BASELINE && baseline_valid &&
                  i2c_read_data != baseline_entry_bank) begin
                last_error <= ERR_BASELINE_MISMATCH;
                last_result <= RESULT_HARD_FAIL;
                completed_sequence <= command_sequence;
                bank_context_lockout <= 1'b1;
                state <= ST_HARD_FAIL;
              end else begin
                state <= ST_SELECT_BANK5;
              end
            end
          end
        end

        ST_SELECT_BANK5: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else if (abort_pending) begin
              finish_failure_or_start_rollback(ERR_ABORTED);
            end else begin
              state <= ST_VERIFY_BANK5;
            end
          end
        end

        ST_VERIFY_BANK5: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else if (i2c_read_data != BANK5) begin
              bank_verify_failure_count <= bank_verify_failure_count + 1'b1;
              finish_failure_or_start_rollback(ERR_BANK_VERIFY);
            end else if (abort_pending) begin
              finish_failure_or_start_rollback(ERR_ABORTED);
            end else if (active_command == CMD_PREPARE_BASELINE) begin
              state <= ST_BASE_READ05;
            end else begin
              state <= ST_WRITE08;
            end
          end
        end

        ST_BASE_READ05: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else begin
              observed_reg05 <= i2c_read_data;
              state <= ST_BASE_READ08;
            end
          end
        end

        ST_BASE_READ08: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else begin
              observed_reg08 <= i2c_read_data;
              state <= ST_RESTORE_ENTRY;
            end
          end
        end

        ST_WRITE08: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else begin
              state <= ST_WRITE05;
            end
          end
        end

        ST_WRITE05: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else begin
              state <= ST_READBACK08;
            end
          end
        end

        ST_READBACK08: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            last_level_readback <= i2c_read_data;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else if (i2c_read_data != target_level) begin
              finish_failure_or_start_rollback(ERR_READBACK);
            end else begin
              state <= ST_READBACK05;
            end
          end
        end

        ST_READBACK05: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            last_companion_readback <= i2c_read_data;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(failure_code());
            end else if (i2c_read_data !=
                         (active_command == CMD_DRYRUN_REWRITE_BASELINE ?
                          baseline_reg05 : COMPANION_VALUE)) begin
              finish_failure_or_start_rollback(ERR_READBACK);
            end else begin
              state <= ST_RESTORE_ENTRY;
            end
          end
        end

        ST_RESTORE_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              finish_failure_or_start_rollback(ERR_ENTRY_RESTORE);
            end else begin
              state <= ST_VERIFY_ENTRY;
            end
          end
        end

        ST_VERIFY_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success || i2c_read_data != action_entry_bank) begin
              if (!i2c_success) note_i2c_failure();
              finish_failure_or_start_rollback(ERR_ENTRY_RESTORE);
            end else if (abort_pending) begin
              finish_failure_or_start_rollback(ERR_ABORTED);
            end else if (active_command == CMD_PREPARE_BASELINE) begin
              if (!baseline_valid) begin
                baseline_entry_bank <= observed_entry_bank;
                baseline_reg05 <= observed_reg05;
                baseline_reg08 <= observed_reg08;
                baseline_valid <= 1'b1;
                baseline_pass_count <= 2'd1;
                last_result <= RESULT_PASS;
              end else if (observed_entry_bank == baseline_entry_bank &&
                           observed_reg05 == baseline_reg05 &&
                           observed_reg08 == baseline_reg08) begin
                if (baseline_pass_count != 2'd3)
                  baseline_pass_count <= baseline_pass_count + 1'b1;
                last_result <= RESULT_PASS;
              end else begin
                baseline_mismatch <= 1'b1;
                last_result <= RESULT_HARD_FAIL;
                last_error <= ERR_BASELINE_MISMATCH;
                bank_context_lockout <= 1'b1;
              end
              completed_sequence <= command_sequence;
              state <= (baseline_valid &&
                        (observed_entry_bank != baseline_entry_bank ||
                         observed_reg05 != baseline_reg05 ||
                         observed_reg08 != baseline_reg08)) ? ST_HARD_FAIL : ST_IDLE;
            end else begin
              if (active_command == CMD_DRYRUN_REWRITE_BASELINE)
                dryrun_pass <= 1'b1;
              else if (active_command == CMD_APPLY_SLICE_50) begin
                slice_stage <= 2'd1;
                slice_executed_mask[0] <= 1'b1;
              end else if (active_command == CMD_APPLY_SLICE_40) begin
                slice_stage <= 2'd2;
                slice_executed_mask[1] <= 1'b1;
              end else if (active_command == CMD_APPLY_SLICE_60) begin
                slice_stage <= 2'd3;
                slice_executed_mask[2] <= 1'b1;
              end
              last_result <= RESULT_PASS;
              last_error <= ERR_NONE;
              completed_sequence <= command_sequence;
              state <= ST_IDLE;
            end
          end
        end

        ST_RB_SAVE_ENTRY: begin
          rollback_active <= 1'b1;
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            observed_entry_bank <= i2c_read_data;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_SELECT_BANK5;
            end
          end
        end

        ST_RB_SELECT_BANK5: begin
          rollback_active <= 1'b1;
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_VERIFY_BANK5;
            end
          end
        end

        ST_RB_VERIFY_BANK5: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success || i2c_read_data != BANK5) begin
              if (!i2c_success) note_i2c_failure();
              bank_verify_failure_count <= bank_verify_failure_count + 1'b1;
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_WRITE08;
            end
          end
        end

        ST_RB_WRITE08: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_READ08;
            end
          end
        end

        ST_RB_READ08: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            restored_reg08 <= i2c_read_data;
            if (!i2c_success || i2c_read_data != baseline_reg08) begin
              if (!i2c_success) note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_WRITE05;
            end
          end
        end

        ST_RB_WRITE05: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_READ05;
            end
          end
        end

        ST_RB_READ05: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            restored_reg05 <= i2c_read_data;
            if (!i2c_success || i2c_read_data != baseline_reg05) begin
              if (!i2c_success) note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_RESTORE_ENTRY;
            end
          end
        end

        ST_RB_RESTORE_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_RB_VERIFY_ENTRY;
            end
          end
        end

        ST_RB_VERIFY_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            restored_entry_bank <= i2c_read_data;
            rollback_active <= 1'b0;
            campaign_closed <= 1'b1;
            completed_sequence <= command_sequence;
            if (!i2c_success || i2c_read_data != baseline_entry_bank) begin
              if (!i2c_success) note_i2c_failure();
              last_error <= ERR_ROLLBACK;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              state <= ST_HARD_FAIL;
            end else begin
              rollback_pass <= 1'b1;
              last_result <= prior_failure_pending ?
                             RESULT_FAILED_ROLLBACK_PASS : RESULT_PASS;
              state <= ST_IDLE;
            end
          end
        end

        ST_FAIL_RESTORE_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              note_i2c_failure();
              last_error <= pending_failure_code;
              last_result <= RESULT_HARD_FAIL;
              bank_context_lockout <= 1'b1;
              completed_sequence <= command_sequence;
              state <= ST_HARD_FAIL;
            end else begin
              state <= ST_FAIL_VERIFY_ENTRY;
            end
          end
        end

        ST_FAIL_VERIFY_ENTRY: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            restored_entry_bank <= i2c_read_data;
            last_error <= pending_failure_code;
            last_result <= RESULT_HARD_FAIL;
            bank_context_lockout <= 1'b1;
            completed_sequence <= command_sequence;
            state <= ST_HARD_FAIL;
            if (!i2c_success || i2c_read_data != action_entry_bank) begin
              if (!i2c_success) note_i2c_failure();
              last_error <= ERR_ENTRY_RESTORE;
            end
          end
        end

        ST_HARD_FAIL: begin
          txn_inflight <= 1'b0;
          bank_context_lockout <= 1'b1;
        end

        default: begin
          last_error <= ERR_SEQUENCE;
          last_result <= RESULT_HARD_FAIL;
          bank_context_lockout <= 1'b1;
          completed_sequence <= command_sequence;
          state <= ST_HARD_FAIL;
        end
      endcase
    end
  end

  // Keep separately qualified master status observable without using it as an
  // operand path.  The executor owns the bus for every complete action.
  wire [4:0] unused_i2c_status = {i2c_busy, i2c_error_cause};
  wire unused_rollback_state = is_rollback_state(state);
endmodule
