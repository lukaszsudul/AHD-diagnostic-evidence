`timescale 1ns/1ps

// AHD v41 SCAN1-R1 read-only NVP6134C survey scanner.
//
// The host can request only a compiled ONESHOT, ACK, or ABORT.  The only NVP
// write reachable from this module is register 0xFF (bank select/restore).
// The manifest, order, bank groups, and semantic identity are compile-time
// constants generated from the frozen SCAN0 authority.
module g2b_nvp_camera_scan1 (
  input  logic        clk,
  input  logic        reset,
  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,

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

  output logic        scanner_i2c_owns_bus,
  output logic        scanner_busy,
  output logic        scanner_done,
  output logic        bank_context_lockout
);
  import g2b_nvp_camera_scan1_manifest_pkg::*;

  localparam logic [7:0] BANK_SELECT = 8'hFF;

  localparam logic [7:0] ENTRY_VALUE_VALID = 8'h01;
  localparam logic [7:0] ENTRY_RETRIED = 8'h02;
  localparam logic [7:0] ENTRY_BANK_VERIFIED = 8'h04;
  localparam logic [7:0] ENTRY_SKIPPED_AFTER_ABORT = 8'h08;

  localparam logic [3:0] ERR_NONE = 4'h0;
  localparam logic [3:0] ERR_WADDR_NACK = 4'h1;
  localparam logic [3:0] ERR_REGADDR_NACK = 4'h2;
  localparam logic [3:0] ERR_RADDR_NACK = 4'h3;
  localparam logic [3:0] ERR_SCL_TIMEOUT = 4'h4;
  localparam logic [3:0] ERR_BUS_IDLE_TIMEOUT = 4'h5;
  localparam logic [3:0] ERR_BANK_VERIFY_MISMATCH = 4'h6;
  localparam logic [3:0] ERR_ENTRY_BANK_READ_FAILURE = 4'h7;
  localparam logic [3:0] ERR_ENTRY_BANK_RESTORE_FAILURE = 4'h8;
  localparam logic [3:0] ERR_AUTOINIT_PREEMPTED = 4'h9;
  localparam logic [3:0] ERR_INTERNAL_PROTOCOL = 4'hA;

  typedef enum logic [4:0] {
    IDLE,
    ONESHOT_REQUESTED,
    WAIT_AUTOINIT,
    SAVE_ENTRY_BANK,
    SELECT_GROUP_BANK,
    VERIFY_GROUP_BANK,
    READ_GROUP_ENTRIES,
    RESTORE_ENTRY_BANK,
    VERIFY_ENTRY_BANK,
    PUBLISH_SNAPSHOT,
    WAIT_HOST_ACK,
    ABORTED_NOT_PUBLISHED,
    ERROR_NOT_PUBLISHED
  } scan_state_t;

  scan_state_t state;
  logic [63:0] tick_counter;
  logic [63:0] snapshot_start_ticks;
  logic [63:0] snapshot_end_ticks;
  logic [31:0] snapshot_generation;
  logic [31:0] valid_entry_count;
  logic [31:0] failed_entry_count;
  logic [31:0] retried_entry_count;
  logic [31:0] first_error_index;
  logic [31:0] first_error_detail;
  logic [7:0] entry_bank;
  logic [7:0] exit_bank;
  logic       entry_bank_valid;
  logic       restore_verified;
  logic [7:0] a8_pre;
  logic [7:0] a8_post;
  logic [15:0] scan_transaction_count;
  logic [31:0] scan_flags;
  logic [6:0] entry_index;
  logic [3:0] group_index;
  logic       txn_inflight;
  logic       retry_used;
  logic       abort_pending;
  logic       preempt_pending;
  logic       fatal_error_pending;
  logic       start_pulse;
  logic       ack_pulse;
  logic       abort_pulse;
  logic [31:0] rejected_start_count;

  (* ram_style = "distributed" *) logic [31:0] snapshot_entry [0:81];
  logic [31:0] group_start_ticks [0:9];
  logic [31:0] group_end_ticks [0:9];
  logic [31:0] group_flags [0:9];

  function automatic logic scan_active(input scan_state_t value);
    begin
      case (value)
        ONESHOT_REQUESTED, WAIT_AUTOINIT, SAVE_ENTRY_BANK,
        SELECT_GROUP_BANK, VERIFY_GROUP_BANK, READ_GROUP_ENTRIES,
        RESTORE_ENTRY_BANK, VERIFY_ENTRY_BANK, PUBLISH_SNAPSHOT:
          scan_active = 1'b1;
        default: scan_active = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [3:0] frozen_error_code(
      input logic [3:0] master_cause, input logic timeout_value);
    begin
      if (timeout_value) begin
        frozen_error_code = (master_cause == 4'h6) ?
                            ERR_BUS_IDLE_TIMEOUT : ERR_SCL_TIMEOUT;
      end else begin
        case (master_cause)
          4'h1: frozen_error_code = ERR_WADDR_NACK;
          4'h2: frozen_error_code = ERR_REGADDR_NACK;
          4'h3: frozen_error_code = ERR_RADDR_NACK;
          default: frozen_error_code = ERR_INTERNAL_PROTOCOL;
        endcase
      end
    end
  endfunction

  function automatic logic [31:0] status_word;
    begin
      status_word = 32'b0;
      status_word[0] = state == IDLE;
      status_word[1] = scanner_busy;
      status_word[2] = scanner_done;
      status_word[3] = state == ERROR_NOT_PUBLISHED;
      status_word[4] = autoinit_done;
      status_word[5] = autoinit_busy;
      status_word[6] = bank_context_lockout;
      status_word[7] = scanner_i2c_owns_bus;
      status_word[12:8] = state;
      status_word[31:16] = rejected_start_count[15:0];
    end
  endfunction

  function automatic logic [31:0] mmio_read_word(input logic [16:0] address_value);
    integer word_index;
    integer directory_group;
    integer directory_word;
    begin
      mmio_read_word = 32'b0;
      case (address_value)
        17'h12000: mmio_read_word = SCAN1_MAGIC;
        17'h12004: mmio_read_word = SCAN1_VERSION;
        17'h12008: mmio_read_word = SCAN1_CAPABILITIES;
        17'h1200C: mmio_read_word = 32'b0;
        17'h12010: mmio_read_word = status_word();
        17'h12014: mmio_read_word = snapshot_generation;
        17'h12018: mmio_read_word = SCAN1_ENTRY_COUNT;
        17'h1201C: mmio_read_word = valid_entry_count;
        17'h12020: mmio_read_word = failed_entry_count;
        17'h12024: mmio_read_word = retried_entry_count;
        17'h12028: mmio_read_word = first_error_index;
        17'h1202C: mmio_read_word = first_error_detail;
        17'h12030: mmio_read_word = {23'b0, entry_bank_valid, entry_bank};
        17'h12034: mmio_read_word = {23'b0, restore_verified, exit_bank};
        17'h12038: mmio_read_word = {16'b0, a8_post, a8_pre};
        17'h1203C: mmio_read_word = scan_flags;
        17'h12040: mmio_read_word = snapshot_start_ticks[31:0];
        17'h12044: mmio_read_word = snapshot_start_ticks[63:32];
        17'h12048: mmio_read_word = snapshot_end_ticks[31:0];
        17'h1204C: mmio_read_word = snapshot_end_ticks[63:32];
        17'h12050: mmio_read_word = scan1_manifest_digest_word(3'd0);
        17'h12054: mmio_read_word = scan1_manifest_digest_word(3'd1);
        17'h12058: mmio_read_word = scan1_manifest_digest_word(3'd2);
        17'h1205C: mmio_read_word = scan1_manifest_digest_word(3'd3);
        17'h12060: mmio_read_word = scan1_manifest_digest_word(3'd4);
        17'h12064: mmio_read_word = scan1_manifest_digest_word(3'd5);
        17'h12068: mmio_read_word = scan1_manifest_digest_word(3'd6);
        17'h1206C: mmio_read_word = scan1_manifest_digest_word(3'd7);
        default: begin
          if (address_value >= 17'h12080 && address_value <= 17'h1211F &&
              address_value[1:0] == 2'b00) begin
            word_index = (address_value - 17'h12080) >> 2;
            directory_group = word_index >> 2;
            directory_word = word_index & 3;
            if (directory_group < SCAN1_GROUP_COUNT) begin
              case (directory_word)
                0: mmio_read_word = {
                    directory_group[7:0], scan1_group_bank(directory_group[3:0]),
                    1'b0, scan1_group_count(directory_group[3:0]),
                    1'b0, scan1_group_start(directory_group[3:0])};
                1: mmio_read_word = group_start_ticks[directory_group];
                2: mmio_read_word = group_end_ticks[directory_group];
                default: mmio_read_word = group_flags[directory_group];
              endcase
            end
          end else if (address_value >= 17'h12180 &&
                       address_value <= 17'h122C7 &&
                       address_value[1:0] == 2'b00) begin
            word_index = (address_value - 17'h12180) >> 2;
            if (word_index < SCAN1_ENTRY_COUNT)
              mmio_read_word = snapshot_entry[word_index];
          end
        end
      endcase
    end
  endfunction

  task automatic record_first_error(
      input logic [31:0] index_value,
      input logic [7:0] bank_value,
      input logic [7:0] register_value,
      input logic [3:0] error_value);
    begin
      if (first_error_index == 32'hFFFF_FFFF) begin
        first_error_index <= index_value;
        first_error_detail <= {8'b0, bank_value, register_value,
                               4'b0, error_value};
      end
    end
  endtask

  assign mmio_req_ready = !mmio_rsp_valid || mmio_rsp_ready;

  always_comb begin
    scanner_busy = scan_active(state);
    scanner_done = state == WAIT_HOST_ACK;
    scanner_i2c_owns_bus = state == SAVE_ENTRY_BANK ||
        state == SELECT_GROUP_BANK || state == VERIFY_GROUP_BANK ||
        state == READ_GROUP_ENTRIES || state == RESTORE_ENTRY_BANK ||
        state == VERIFY_ENTRY_BANK;

    i2c_cmd_valid = 1'b0;
    i2c_cmd_write = 1'b0;
    i2c_cmd_reg = 8'b0;
    i2c_cmd_wdata = 8'b0;
    if (!txn_inflight && !bank_context_lockout) begin
      case (state)
        SAVE_ENTRY_BANK: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        SELECT_GROUP_BANK: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = scan1_group_bank(group_index);
        end
        VERIFY_GROUP_BANK: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        READ_GROUP_ENTRIES: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = scan1_entry_register(entry_index);
        end
        RESTORE_ENTRY_BANK: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_write = 1'b1;
          i2c_cmd_reg = BANK_SELECT;
          i2c_cmd_wdata = entry_bank;
        end
        VERIFY_ENTRY_BANK: begin
          i2c_cmd_valid = i2c_cmd_ready;
          i2c_cmd_reg = BANK_SELECT;
        end
        default: begin end
      endcase
    end
  end

  // Accepted writes are side effects only.  Reads create exactly one response,
  // retained until the shared AXI-Lite bridge accepts it.
  always_ff @(posedge clk) begin
    if (reset) begin
      mmio_rsp_valid <= 1'b0;
      mmio_rsp_rdata <= 32'b0;
      start_pulse <= 1'b0;
      ack_pulse <= 1'b0;
      abort_pulse <= 1'b0;
    end else begin
      start_pulse <= 1'b0;
      ack_pulse <= 1'b0;
      abort_pulse <= 1'b0;
      if (mmio_rsp_valid && mmio_rsp_ready)
        mmio_rsp_valid <= 1'b0;
      if (mmio_req_valid && mmio_req_ready) begin
        if (mmio_req_write) begin
          if (mmio_req_addr == 17'h1200C && mmio_req_be == 4'hF) begin
            case (mmio_req_wdata)
              32'h0000_0001: start_pulse <= 1'b1;
              32'h0000_0002: ack_pulse <= 1'b1;
              32'h0000_0004: abort_pulse <= 1'b1;
              default: begin end
            endcase
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
      state <= IDLE;
      tick_counter <= 64'b0;
      snapshot_start_ticks <= 64'b0;
      snapshot_end_ticks <= 64'b0;
      snapshot_generation <= 32'b0;
      valid_entry_count <= 32'b0;
      failed_entry_count <= 32'b0;
      retried_entry_count <= 32'b0;
      first_error_index <= 32'hFFFF_FFFF;
      first_error_detail <= 32'b0;
      entry_bank <= 8'b0;
      exit_bank <= 8'b0;
      entry_bank_valid <= 1'b0;
      restore_verified <= 1'b0;
      a8_pre <= 8'b0;
      a8_post <= 8'b0;
      scan_transaction_count <= 16'b0;
      scan_flags <= 32'b0;
      entry_index <= 7'b0;
      group_index <= 4'b0;
      txn_inflight <= 1'b0;
      retry_used <= 1'b0;
      abort_pending <= 1'b0;
      preempt_pending <= 1'b0;
      fatal_error_pending <= 1'b0;
      bank_context_lockout <= 1'b0;
      rejected_start_count <= 32'b0;
    end else begin
      tick_counter <= tick_counter + 1'b1;

      if (start_pulse && state != IDLE)
        rejected_start_count <= rejected_start_count + 1'b1;

      if (scan_active(state) && state != WAIT_AUTOINIT &&
          state != ONESHOT_REQUESTED && (autoinit_busy || !autoinit_done))
        preempt_pending <= 1'b1;
      if (scan_active(state) && abort_pulse)
        abort_pending <= 1'b1;

      // cmd_accepted is registered by the fixed master.  On the cycle in
      // which this scanner observes the pulse, cmd_ready/valid are already
      // low because the master is busy with the accepted transaction.
      if (i2c_cmd_accepted) begin
        txn_inflight <= 1'b1;
        scan_transaction_count <= scan_transaction_count + 1'b1;
      end

      case (state)
        IDLE: begin
          txn_inflight <= 1'b0;
          abort_pending <= 1'b0;
          preempt_pending <= 1'b0;
          fatal_error_pending <= 1'b0;
          if (start_pulse && !bank_context_lockout)
            state <= ONESHOT_REQUESTED;
        end

        ONESHOT_REQUESTED: begin
          valid_entry_count <= 32'b0;
          failed_entry_count <= 32'b0;
          retried_entry_count <= 32'b0;
          first_error_index <= 32'hFFFF_FFFF;
          first_error_detail <= 32'b0;
          entry_bank_valid <= 1'b0;
          restore_verified <= 1'b0;
          a8_pre <= 8'b0;
          a8_post <= 8'b0;
          scan_transaction_count <= 16'b0;
          scan_flags <= 32'b0;
          group_index <= 4'b0;
          entry_index <= 7'b0;
          retry_used <= 1'b0;
          state <= WAIT_AUTOINIT;
        end

        WAIT_AUTOINIT: begin
          if (abort_pulse) begin
            state <= ABORTED_NOT_PUBLISHED;
          end else if (autoinit_done && !autoinit_busy &&
                       !autoinit_error && nvp_reset_released && i2c_bus_idle) begin
            snapshot_start_ticks <= tick_counter;
            state <= SAVE_ENTRY_BANK;
          end
        end

        SAVE_ENTRY_BANK: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              record_first_error(32'hFFFF_FFFF, 8'hFF, BANK_SELECT,
                                 ERR_ENTRY_BANK_READ_FAILURE);
              fatal_error_pending <= 1'b1;
              bank_context_lockout <= 1'b1;
              state <= ERROR_NOT_PUBLISHED;
            end else begin
              entry_bank <= i2c_read_data;
              entry_bank_valid <= 1'b1;
              group_start_ticks[0] <= tick_counter[31:0];
              group_flags[0] <= 32'b0;
              state <= SELECT_GROUP_BANK;
            end
          end
        end

        SELECT_GROUP_BANK: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              record_first_error({25'b0, entry_index},
                  scan1_group_bank(group_index), BANK_SELECT,
                  frozen_error_code(i2c_error_cause, i2c_timeout));
              fatal_error_pending <= 1'b1;
              state <= RESTORE_ENTRY_BANK;
            end else begin
              state <= VERIFY_GROUP_BANK;
            end
          end
        end

        VERIFY_GROUP_BANK: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success || i2c_read_data != scan1_group_bank(group_index)) begin
              record_first_error({25'b0, entry_index},
                  scan1_group_bank(group_index), BANK_SELECT,
                  i2c_success ? ERR_BANK_VERIFY_MISMATCH :
                  frozen_error_code(i2c_error_cause, i2c_timeout));
              fatal_error_pending <= 1'b1;
              group_flags[group_index] <= 32'h0000_0004;
              state <= RESTORE_ENTRY_BANK;
            end else begin
              entry_index <= scan1_group_start(group_index);
              retry_used <= 1'b0;
              state <= READ_GROUP_ENTRIES;
            end
          end
        end

        READ_GROUP_ENTRIES: begin
          if (i2c_done && txn_inflight) begin
            logic [3:0] entry_error;
            logic [7:0] entry_status;
            logic [7:0] expected_bank;
            logic [7:0] expected_register;
            txn_inflight <= 1'b0;
            expected_bank = scan1_entry_bank(entry_index);
            expected_register = scan1_entry_register(entry_index);
            if (i2c_success) begin
              entry_status = ENTRY_VALUE_VALID | ENTRY_BANK_VERIFIED |
                             (retry_used ? ENTRY_RETRIED : 8'b0);
              snapshot_entry[entry_index] <= {
                  expected_bank, expected_register, i2c_read_data, entry_status};
              valid_entry_count <= valid_entry_count + 1'b1;
              if (retry_used)
                retried_entry_count <= retried_entry_count + 1'b1;
              if (entry_index == 0)
                a8_pre <= i2c_read_data;
              if (entry_index == 81)
                a8_post <= i2c_read_data;
              retry_used <= 1'b0;
              if (entry_index + 1'b1 ==
                  scan1_group_start(group_index) + scan1_group_count(group_index)) begin
                group_end_ticks[group_index] <= tick_counter[31:0];
                group_flags[group_index] <= {
                    scan1_group_bank(group_index),
                    1'b0, scan1_group_count(group_index),
                    1'b0, scan1_group_count(group_index) + 7'd2,
                    6'b0, 1'b1, 1'b1};
                if (abort_pending || preempt_pending || abort_pulse ||
                    autoinit_busy || !autoinit_done) begin
                  if (autoinit_busy || !autoinit_done || preempt_pending)
                    record_first_error({25'b0, entry_index}, expected_bank,
                                       expected_register, ERR_AUTOINIT_PREEMPTED);
                  state <= RESTORE_ENTRY_BANK;
                end else if (group_index == SCAN1_GROUP_COUNT-1) begin
                  state <= RESTORE_ENTRY_BANK;
                end else begin
                  group_index <= group_index + 1'b1;
                  group_start_ticks[group_index + 1'b1] <= tick_counter[31:0];
                  group_flags[group_index + 1'b1] <= 32'b0;
                  state <= SELECT_GROUP_BANK;
                end
              end else begin
                entry_index <= entry_index + 1'b1;
              end
            end else if (!i2c_timeout && !retry_used &&
                         (i2c_error_cause == 4'h1 || i2c_error_cause == 4'h2 ||
                          i2c_error_cause == 4'h3)) begin
              retry_used <= 1'b1;
            end else begin
              entry_error = frozen_error_code(i2c_error_cause, i2c_timeout);
              entry_status = {entry_error, 1'b0, 1'b1, retry_used, 1'b0};
              snapshot_entry[entry_index] <= {
                  expected_bank, expected_register, 8'b0, entry_status};
              failed_entry_count <= failed_entry_count + 1'b1;
              if (retry_used)
                retried_entry_count <= retried_entry_count + 1'b1;
              record_first_error({25'b0, entry_index}, expected_bank,
                                 expected_register, entry_error);
              fatal_error_pending <= 1'b1;
              state <= RESTORE_ENTRY_BANK;
            end
          end
        end

        RESTORE_ENTRY_BANK: begin
          if (!entry_bank_valid) begin
            bank_context_lockout <= 1'b1;
            state <= ERROR_NOT_PUBLISHED;
          end else if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            if (!i2c_success) begin
              record_first_error(32'hFFFF_FFFF, entry_bank, BANK_SELECT,
                                 ERR_ENTRY_BANK_RESTORE_FAILURE);
              bank_context_lockout <= 1'b1;
              fatal_error_pending <= 1'b1;
              state <= ERROR_NOT_PUBLISHED;
            end else begin
              state <= VERIFY_ENTRY_BANK;
            end
          end
        end

        VERIFY_ENTRY_BANK: begin
          if (i2c_done && txn_inflight) begin
            txn_inflight <= 1'b0;
            exit_bank <= i2c_read_data;
            snapshot_end_ticks <= tick_counter;
            if (!i2c_success || i2c_read_data != entry_bank) begin
              record_first_error(32'hFFFF_FFFF, entry_bank, BANK_SELECT,
                                 ERR_ENTRY_BANK_RESTORE_FAILURE);
              restore_verified <= 1'b0;
              bank_context_lockout <= 1'b1;
              fatal_error_pending <= 1'b1;
              state <= ERROR_NOT_PUBLISHED;
            end else begin
              restore_verified <= 1'b1;
              if (fatal_error_pending)
                state <= ERROR_NOT_PUBLISHED;
              else if (abort_pending || preempt_pending)
                state <= ABORTED_NOT_PUBLISHED;
              else
                state <= PUBLISH_SNAPSHOT;
            end
          end
        end

        PUBLISH_SNAPSHOT: begin
          scan_flags <= {scan_transaction_count, 12'b0,
                         1'b0, restore_verified,
                         (a8_pre != a8_post), 1'b1};
          snapshot_generation <= snapshot_generation + 1'b1;
          state <= WAIT_HOST_ACK;
        end

        WAIT_HOST_ACK: begin
          if (ack_pulse) begin
            scan_flags <= 32'b0;
            state <= IDLE;
          end
        end

        ABORTED_NOT_PUBLISHED: begin
          scan_flags <= {scan_transaction_count, 12'b0,
                         1'b0, restore_verified, 1'b0, 1'b0};
          if (ack_pulse && !bank_context_lockout)
            state <= IDLE;
        end

        ERROR_NOT_PUBLISHED: begin
          scan_flags <= {scan_transaction_count, 12'b0,
                         1'b0, restore_verified, 1'b0, 1'b0};
          if (ack_pulse && !bank_context_lockout)
            state <= IDLE;
        end

        default: begin
          record_first_error(32'hFFFF_FFFF, 8'b0, 8'b0,
                             ERR_INTERNAL_PROTOCOL);
          fatal_error_pending <= 1'b1;
          state <= entry_bank_valid ? RESTORE_ENTRY_BANK : ERROR_NOT_PUBLISHED;
        end
      endcase
    end
  end

  // Structural contract: these inputs may affect only scanner admission and
  // error metadata; no scanner signal has fanout to video, parser, route,
  // BGDCOL, C2H, or XDMA stream control.
  wire [1:0] unused_i2c_status = {i2c_busy, i2c_bus_idle};
endmodule
