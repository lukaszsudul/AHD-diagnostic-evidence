`timescale 1ns/1ps

// Bounded NVP6134C VDO1-route controller for DIAG2-RM1.
// The host selects only CH1..CH4.  Every I2C operation is compiled here;
// there is no host-supplied bank, register address, write byte, or delay.
module g2b_nvp_rm1_route_controller #(
  parameter integer CYCLES_PER_MS = 62500,
  parameter integer SETTLE_TIME_MS = 200
) (
  input  logic        clk,
  input  logic        reset,
  input  logic        start_pulse,
  input  logic        restore_pulse,
  input  logic [2:0]  target_channel,

  input  logic        autoinit_done,
  input  logic        autoinit_busy,
  input  logic        autoinit_error,
  input  logic        nvp_reset_released,
  input  logic        transport_quiescent,

  output logic        i2c_cmd_valid,
  input  logic        i2c_cmd_ready,
  output logic        i2c_cmd_write,
  output logic [7:0]  i2c_cmd_reg,
  output logic [7:0]  i2c_cmd_wdata,
  input  logic        i2c_cmd_accepted,
  input  logic        i2c_done,
  input  logic        i2c_success,
  input  logic        i2c_timeout,
  input  logic [7:0]  i2c_read_data,
  input  logic        i2c_bus_idle,

  output logic        diagnostic_i2c_owns_bus,
  output logic        route_busy,
  output logic        route_ready_pulse,
  output logic        route_error,
  output logic        route_error_pulse,
  output logic [15:0] route_error_code,
  output logic        route_restored,
  output logic [7:0]  original_bank,
  output logic [7:0]  original_route,
  output logic [7:0]  route_readback,
  output logic [31:0] i2c_transaction_count
);
  localparam logic [7:0] BANK_SELECT = 8'hff;
  localparam logic [7:0] BANK0 = 8'h00;
  localparam logic [7:0] BANK1 = 8'h01;
  localparam logic [7:0] REG_VDO1_ROUTE = 8'hc2;

  localparam logic [15:0] ERR_NONE = 16'h0000;
  localparam logic [15:0] ERR_NOT_READY = 16'h0001;
  localparam logic [15:0] ERR_I2C_NACK = 16'h0002;
  localparam logic [15:0] ERR_I2C_TIMEOUT = 16'h0003;
  localparam logic [15:0] ERR_ROUTE_MISMATCH = 16'h0004;
  localparam logic [15:0] ERR_RESTORE_MISMATCH = 16'h0005;
  localparam logic [15:0] ERR_QUIESCENCE_LOST = 16'h0006;
  localparam logic [15:0] ERR_AXI_RESET = 16'h0007;
  localparam logic [15:0] ERR_RUNTIME_ENV_LOST = 16'h0008;

  localparam integer SETTLE_CYCLES = SETTLE_TIME_MS * CYCLES_PER_MS;
  localparam integer SETTLE_WIDTH = $clog2(SETTLE_CYCLES + 1);

  typedef enum logic [4:0] {
    R_IDLE,
    R_READ_BANK,
    R_SELECT_BANK1,
    R_READ_ROUTE,
    R_WRITE_ROUTE,
    R_VERIFY_ROUTE,
    R_SELECT_BANK0,
    R_SETTLE,
    R_HELD,
    R_RESTORE_SELECT_BANK1,
    R_RESTORE_ROUTE,
    R_RESTORE_VERIFY,
    R_RESTORE_BANK,
    R_RESTORE_VERIFY_BANK,
    R_RESET_RECOVERY,
    R_WAIT_RESTORE_SAFE,
    R_TERMINAL_ERROR
  } route_state_t;

  route_state_t state = R_IDLE;
  logic txn_pending = 1'b0;
  logic original_bank_valid = 1'b0;
  logic original_route_valid = 1'b0;
  logic mutation_dirty = 1'b0;
  logic restore_route_verified = 1'b0;
  logic quiescence_lost_latched = 1'b0;
  logic environment_lost_latched = 1'b0;
  logic baseline_unproven = 1'b0;
  logic ever_released = 1'b0;
  logic restoring_after_error = 1'b0;
  logic [2:0] target_channel_hold = 3'd1;
  logic [SETTLE_WIDTH-1:0] settle_counter = '0;

  wire [7:0] target_route_value =
      {original_route[7:4], 1'b0, target_channel_hold - 3'd1};
  wire runtime_environment_ok = autoinit_done && !autoinit_busy &&
      !autoinit_error && nvp_reset_released;
  wire prerequisites_ok = runtime_environment_ok && i2c_bus_idle &&
      transport_quiescent && target_channel >= 3'd1 &&
      target_channel <= 3'd4;
  wire forward_route_owned = state == R_READ_BANK ||
      state == R_SELECT_BANK1 || state == R_READ_ROUTE ||
      state == R_WRITE_ROUTE || state == R_VERIFY_ROUTE ||
      state == R_SELECT_BANK0 || state == R_SETTLE || state == R_HELD;
  wire restore_route_owned = state == R_RESTORE_SELECT_BANK1 ||
      state == R_RESTORE_ROUTE || state == R_RESTORE_VERIFY ||
      state == R_RESTORE_BANK || state == R_RESTORE_VERIFY_BANK;

  task automatic issue_i2c(
      input logic write_value,
      input logic [7:0] register_value,
      input logic [7:0] data_value);
    begin
      i2c_cmd_write <= write_value;
      i2c_cmd_reg <= register_value;
      i2c_cmd_wdata <= data_value;
      i2c_cmd_valid <= 1'b1;
      txn_pending <= 1'b1;
    end
  endtask

  task automatic begin_failure(input logic [15:0] failure_code);
    begin
      route_error <= 1'b1;
      route_error_pulse <= 1'b1;
      route_error_code <= failure_code;
      route_ready_pulse <= 1'b0;
      txn_pending <= 1'b0;
      restoring_after_error <= 1'b1;
      if (original_bank_valid) begin
        if (mutation_dirty && original_route_valid)
          state <= R_RESTORE_SELECT_BANK1;
        else if (mutation_dirty)
          state <= R_RESTORE_BANK;
        else begin
          route_restored <= 1'b1;
          route_busy <= 1'b0;
          diagnostic_i2c_owns_bus <= 1'b0;
          state <= R_TERMINAL_ERROR;
        end
      end else begin
        route_restored <= !mutation_dirty;
        route_busy <= 1'b0;
        diagnostic_i2c_owns_bus <= 1'b0;
        state <= R_TERMINAL_ERROR;
      end
    end
  endtask

  task automatic begin_environment_failure;
    begin
      // A runtime loss of NVP/autoinit readiness is materially different
      // from an I2C result failure: the external device may have changed its
      // bank or C2 state.  Revoke the route immediately, drain any in-flight
      // master command, and restore only after the environment is safe.  If
      // both entry values were not captured, exact restore can never be
      // claimed for this ownership epoch.
      route_error <= 1'b1;
      route_error_pulse <= 1'b1;
      route_error_code <= ERR_RUNTIME_ENV_LOST;
      route_ready_pulse <= 1'b0;
      route_restored <= 1'b0;
      route_busy <= 1'b1;
      diagnostic_i2c_owns_bus <= 1'b0;
      txn_pending <= 1'b0;
      restoring_after_error <= 1'b1;
      environment_lost_latched <= 1'b1;
      if (!(original_bank_valid && original_route_valid))
        baseline_unproven <= 1'b1;
      state <= R_WAIT_RESTORE_SAFE;
    end
  endtask

  always_ff @(posedge clk) begin
    i2c_cmd_valid <= 1'b0;
    route_ready_pulse <= 1'b0;
    route_error_pulse <= 1'b0;

    if (reset && !ever_released) begin
      state <= R_IDLE;
      txn_pending <= 1'b0;
      original_bank_valid <= 1'b0;
      original_route_valid <= 1'b0;
      mutation_dirty <= 1'b0;
      restore_route_verified <= 1'b0;
      quiescence_lost_latched <= 1'b0;
      environment_lost_latched <= 1'b0;
      baseline_unproven <= 1'b0;
      restoring_after_error <= 1'b0;
      target_channel_hold <= 3'd1;
      settle_counter <= '0;
      i2c_cmd_valid <= 1'b0;
      i2c_cmd_write <= 1'b0;
      i2c_cmd_reg <= 8'b0;
      i2c_cmd_wdata <= 8'b0;
      diagnostic_i2c_owns_bus <= 1'b0;
      route_busy <= 1'b0;
      route_error <= 1'b0;
      route_error_pulse <= 1'b0;
      route_error_code <= ERR_NONE;
      route_restored <= 1'b1;
      original_bank <= BANK0;
      original_route <= 8'b0;
      route_readback <= 8'b0;
      i2c_transaction_count <= 32'b0;
    end else if (reset) begin
      // AXI reset is not permission to forget a possibly applied physical
      // bank/route write.  Retain the captured baseline and dirty flag, then
      // force a bounded restore immediately after reset release.
      txn_pending <= 1'b0;
      i2c_cmd_valid <= 1'b0;
      route_ready_pulse <= 1'b0;
      route_error <= 1'b1;
      route_error_code <= ERR_AXI_RESET;
      diagnostic_i2c_owns_bus <= 1'b0;
      restoring_after_error <= 1'b1;
      if (mutation_dirty) begin
        restore_route_verified <= 1'b0;
        route_restored <= 1'b0;
        route_busy <= 1'b1;
        state <= R_RESET_RECOVERY;
      end else if (baseline_unproven || !route_restored) begin
        // Never let a later AXI reset convert an earlier unprovable external
        // environment loss into a silent restore PASS.
        route_restored <= 1'b0;
        route_busy <= 1'b0;
        state <= R_TERMINAL_ERROR;
      end else begin
        route_restored <= 1'b1;
        route_busy <= 1'b0;
        state <= R_TERMINAL_ERROR;
      end
    end else begin
      ever_released <= 1'b1;
      if (i2c_cmd_accepted && i2c_transaction_count != 32'hffff_ffff)
        i2c_transaction_count <= i2c_transaction_count + 1'b1;

      // NVP reset/autoinit readiness is a live invariant.  Losing it in any
      // forward or restore transaction revokes the route immediately.  A
      // restore attempt is deferred until readiness and master-idle return;
      // an incomplete baseline remains permanently fail-closed.
      if ((forward_route_owned || restore_route_owned) &&
          !runtime_environment_ok) begin
        begin_environment_failure();
      end else
      // No-DMA quiescence is an invariant for the complete forward route
      // ownership interval, not just the C2 write and HELD states.  Catch a
      // one-cycle loss in every save/RMW/verify/bank0/settle/held state and
      // enter the exact bounded restore path immediately.  Restore states do
      // not re-test the failed invariant because restoring the physical
      // baseline is mandatory even after transport has become active.
      if (forward_route_owned &&
          (!transport_quiescent || quiescence_lost_latched)) begin
        quiescence_lost_latched <= 1'b1;
        begin_failure(ERR_QUIESCENCE_LOST);
      end else case (state)
        R_IDLE: begin
          route_busy <= 1'b0;
          diagnostic_i2c_owns_bus <= 1'b0;
          if (start_pulse) begin
            route_error <= 1'b0;
            route_error_code <= ERR_NONE;
            original_bank_valid <= 1'b0;
            original_route_valid <= 1'b0;
            mutation_dirty <= 1'b0;
            restore_route_verified <= 1'b0;
            quiescence_lost_latched <= 1'b0;
            environment_lost_latched <= 1'b0;
            baseline_unproven <= 1'b0;
            restoring_after_error <= 1'b0;
            if (!prerequisites_ok) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= ERR_NOT_READY;
              state <= R_TERMINAL_ERROR;
            end else begin
              target_channel_hold <= target_channel;
              route_busy <= 1'b1;
              route_restored <= 1'b0;
              diagnostic_i2c_owns_bus <= 1'b1;
              state <= R_READ_BANK;
            end
          end
        end

        R_READ_BANK: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b0, BANK_SELECT, 8'b0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else begin
              original_bank <= i2c_read_data;
              original_bank_valid <= 1'b1;
              state <= R_SELECT_BANK1;
            end
          end
        end

        R_SELECT_BANK1: begin
          if (!txn_pending && i2c_cmd_ready) begin
            issue_i2c(1'b1, BANK_SELECT, BANK1);
            mutation_dirty <= 1'b1;
          end
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else
              state <= R_READ_ROUTE;
          end
        end

        R_READ_ROUTE: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else begin
              original_route <= i2c_read_data;
              original_route_valid <= 1'b1;
              state <= R_WRITE_ROUTE;
            end
          end
        end

        R_WRITE_ROUTE: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b1, REG_VDO1_ROUTE, target_route_value);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else
              state <= R_VERIFY_ROUTE;
          end
        end

        R_VERIFY_ROUTE: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else begin
              route_readback <= i2c_read_data;
              if (i2c_read_data != target_route_value)
                begin_failure(ERR_ROUTE_MISMATCH);
              else
                state <= R_SELECT_BANK0;
            end
          end
        end

        R_SELECT_BANK0: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b1, BANK_SELECT, BANK0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success)
              begin_failure(i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK);
            else begin
              diagnostic_i2c_owns_bus <= 1'b0;
              settle_counter <= '0;
              state <= R_SETTLE;
            end
          end
        end

        R_SETTLE: begin
          if (settle_counter + 1'b1 >= SETTLE_CYCLES) begin
            settle_counter <= '0;
            route_busy <= 1'b0;
            route_ready_pulse <= 1'b1;
            state <= R_HELD;
          end else
            settle_counter <= settle_counter + 1'b1;
        end

        R_HELD: begin
          route_busy <= 1'b0;
          if (restore_pulse) begin
            route_busy <= 1'b1;
            diagnostic_i2c_owns_bus <= 1'b1;
            restoring_after_error <= 1'b0;
            state <= R_RESTORE_SELECT_BANK1;
          end
        end

        R_RESET_RECOVERY: begin
          // Baseline registers and mutation_dirty survived axi_aresetn.
          // Do not touch the device until reset/autoinit and the single fixed
          // master are safe again.
          diagnostic_i2c_owns_bus <= 1'b0;
          route_busy <= 1'b1;
          if (runtime_environment_ok && i2c_bus_idle) begin
            diagnostic_i2c_owns_bus <= 1'b1;
            if (original_route_valid)
              state <= R_RESTORE_SELECT_BANK1;
            else
              state <= R_RESTORE_BANK;
          end
        end

        R_WAIT_RESTORE_SAFE: begin
          route_ready_pulse <= 1'b0;
          route_restored <= 1'b0;
          diagnostic_i2c_owns_bus <= 1'b0;
          if (i2c_bus_idle && baseline_unproven) begin
            if (runtime_environment_ok && original_bank_valid &&
                mutation_dirty) begin
              // C2 is unprovable, but a completed/in-flight Bank1 select may
              // still have moved the physical bank.  Restore and verify the
              // known entry bank, then remain terminal-invalid.
              route_busy <= 1'b1;
              diagnostic_i2c_owns_bus <= 1'b1;
              restore_route_verified <= 1'b0;
              state <= R_RESTORE_BANK;
            end else if (!original_bank_valid || !mutation_dirty) begin
              // No exact entry bank+C2 pair exists and there is no known bank
              // mutation to repair.  Draining the old command is sufficient
              // to stop, never sufficient to advertise route_restored.
              route_busy <= 1'b0;
              state <= R_TERMINAL_ERROR;
            end
          end else if (runtime_environment_ok && i2c_bus_idle) begin
            route_busy <= 1'b1;
            diagnostic_i2c_owns_bus <= 1'b1;
            restore_route_verified <= 1'b0;
            state <= R_RESTORE_SELECT_BANK1;
          end
        end

        R_RESTORE_SELECT_BANK1: begin
          diagnostic_i2c_owns_bus <= 1'b1;
          route_busy <= 1'b1;
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b1, BANK_SELECT, BANK1);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK;
              state <= R_RESTORE_BANK;
            end else
              state <= R_RESTORE_ROUTE;
          end
        end

        R_RESTORE_ROUTE: begin
          if (!txn_pending && i2c_cmd_ready) begin
            issue_i2c(1'b1, REG_VDO1_ROUTE, original_route);
            restore_route_verified <= 1'b0;
          end
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK;
              state <= R_RESTORE_BANK;
            end else
              state <= R_RESTORE_VERIFY;
          end
        end

        R_RESTORE_VERIFY: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b0, REG_VDO1_ROUTE, 8'b0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success || i2c_read_data != original_route) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= !i2c_success ?
                  (i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK) :
                  ERR_RESTORE_MISMATCH;
              restore_route_verified <= 1'b0;
            end else begin
              route_readback <= i2c_read_data;
              restore_route_verified <= 1'b1;
            end
            state <= R_RESTORE_BANK;
          end
        end

        R_RESTORE_BANK: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b1, BANK_SELECT, original_bank);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            if (!i2c_success) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK;
              diagnostic_i2c_owns_bus <= 1'b0;
              route_busy <= 1'b0;
              route_restored <= 1'b0;
              state <= R_TERMINAL_ERROR;
            end else begin
              state <= R_RESTORE_VERIFY_BANK;
            end
          end
        end

        R_RESTORE_VERIFY_BANK: begin
          if (!txn_pending && i2c_cmd_ready)
            issue_i2c(1'b0, BANK_SELECT, 8'b0);
          if (i2c_done && txn_pending) begin
            txn_pending <= 1'b0;
            diagnostic_i2c_owns_bus <= 1'b0;
            route_busy <= 1'b0;
            if (!i2c_success || i2c_read_data != original_bank) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= !i2c_success ?
                  (i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK) :
                  ERR_RESTORE_MISMATCH;
              route_restored <= 1'b0;
              state <= R_TERMINAL_ERROR;
            end else if (baseline_unproven) begin
              // A known entry bank has been restored and read back, but the
              // missing C2 baseline makes the overall route unprovable.  Keep
              // the original runtime-environment error and fail closed.
              route_restored <= 1'b0;
              state <= R_TERMINAL_ERROR;
            end else if (!original_route_valid ||
                         !restore_route_verified) begin
              route_error <= 1'b1;
              route_error_pulse <= 1'b1;
              route_error_code <= !i2c_success ?
                  (i2c_timeout ? ERR_I2C_TIMEOUT : ERR_I2C_NACK) :
                  ERR_RESTORE_MISMATCH;
              route_restored <= 1'b0;
              state <= R_TERMINAL_ERROR;
            end else begin
              mutation_dirty <= 1'b0;
              baseline_unproven <= 1'b0;
              route_restored <= 1'b1;
              state <= route_error || restoring_after_error ?
                       R_TERMINAL_ERROR : R_IDLE;
            end
          end
        end

        R_TERMINAL_ERROR: begin
          route_busy <= 1'b0;
          diagnostic_i2c_owns_bus <= 1'b0;
          // A new bounded request may clear a historical error only after an
          // exact route+bank restore has already been proven.
          if (start_pulse && route_restored && !mutation_dirty &&
              prerequisites_ok) begin
            route_error <= 1'b0;
            route_error_code <= ERR_NONE;
            original_bank_valid <= 1'b0;
            original_route_valid <= 1'b0;
            restore_route_verified <= 1'b0;
            quiescence_lost_latched <= 1'b0;
            environment_lost_latched <= 1'b0;
            baseline_unproven <= 1'b0;
            target_channel_hold <= target_channel;
            restoring_after_error <= 1'b0;
            route_busy <= 1'b1;
            route_restored <= 1'b0;
            diagnostic_i2c_owns_bus <= 1'b1;
            state <= R_READ_BANK;
          end
        end

        default: state <= R_IDLE;
      endcase
    end
  end
endmodule
