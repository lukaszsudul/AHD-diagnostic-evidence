`timescale 1ns/1ps

// Fixed NVP6134C register transaction engine for the NVP video diagnostic.
//
// This is a deliberately small extraction of the already-qualified low-level
// engine in nvp_i2c_tri_phase_probe.sv.  The device bytes are compile-time
// constants and the interface supports only complete register reads and
// complete register writes.  It is therefore not an arbitrary host I2C
// service.  SCL/SDA outputs are open-drain release controls: 1 releases the
// pin and 0 pulls it low.
module nvp_i2c_fixed_master #(
  parameter integer CLK_HZ = 62500000,
  parameter integer I2C_HZ = 25000,
  parameter integer SCL_TIMEOUT_CYCLES = CLK_HZ / 50000,
  parameter integer BUS_IDLE_TIMEOUT_CYCLES = CLK_HZ / 1000
) (
  input  logic       clk,
  input  logic       rst,
  input  logic       raw_scl_i,
  input  logic       raw_sda_i,

  input  logic       cmd_valid,
  output logic       cmd_ready,
  input  logic       cmd_write,
  input  logic [7:0] cmd_reg,
  input  logic [7:0] cmd_wdata,

  output logic       cmd_accepted,
  output logic       busy,
  output logic       done,
  output logic       success,
  output logic       timeout,
  // Diagnostic-only completion cause.  This exposes the already-existing
  // internal phase that failed; it does not change transaction timing or the
  // open-drain state machine.
  output logic [3:0] error_cause,
  output logic [7:0] read_data,
  output logic [31:0] transaction_sequence,

  output logic       scl_release,
  output logic       sda_release,
  output logic       bus_idle
);
  localparam logic [7:0] NVP_ADDR_W = 8'h60;
  localparam logic [7:0] NVP_ADDR_R = 8'h61;
  localparam integer DIVIDER = CLK_HZ / (I2C_HZ * 2);
  localparam integer TICK_CYCLES = DIVIDER + 1;
  localparam logic [3:0] CAUSE_NONE = 4'h0;
  localparam logic [3:0] CAUSE_WADDR_NACK = 4'h1;
  localparam logic [3:0] CAUSE_REGADDR_NACK = 4'h2;
  localparam logic [3:0] CAUSE_RADDR_NACK = 4'h3;
  localparam logic [3:0] CAUSE_DATA_NACK = 4'h4;
  localparam logic [3:0] CAUSE_SCL_TIMEOUT = 4'h5;
  localparam logic [3:0] CAUSE_BUS_IDLE_TIMEOUT = 4'h6;

  initial begin
    if (DIVIDER < 1)
      $error("nvp_i2c_fixed_master: invalid I2C divider");
    if (SCL_TIMEOUT_CYCLES < 1 || BUS_IDLE_TIMEOUT_CYCLES < 1)
      $error("nvp_i2c_fixed_master: invalid timeout contract");
  end

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) logic [1:0] scl_sync;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) logic [1:0] sda_sync;
  logic scl_filter_candidate, sda_filter_candidate;
  logic [1:0] scl_filter_count, sda_filter_count;
  logic scl_filtered, sda_filtered;

  always_ff @(posedge clk) begin
    if (rst) begin
      scl_sync <= 2'b11;
      sda_sync <= 2'b11;
      scl_filter_candidate <= 1'b1;
      sda_filter_candidate <= 1'b1;
      scl_filter_count <= 2'b0;
      sda_filter_count <= 2'b0;
      scl_filtered <= 1'b1;
      sda_filtered <= 1'b1;
    end else begin
      scl_sync[0] <= raw_scl_i;
      scl_sync[1] <= scl_sync[0];
      sda_sync[0] <= raw_sda_i;
      sda_sync[1] <= sda_sync[0];

      if (scl_sync[1] != scl_filter_candidate) begin
        scl_filter_candidate <= scl_sync[1];
        scl_filter_count <= 2'd1;
      end else if (scl_filter_count < 2) begin
        scl_filter_count <= scl_filter_count + 1'b1;
      end else begin
        scl_filtered <= scl_filter_candidate;
      end

      if (sda_sync[1] != sda_filter_candidate) begin
        sda_filter_candidate <= sda_sync[1];
        sda_filter_count <= 2'd1;
      end else if (sda_filter_count < 2) begin
        sda_filter_count <= sda_filter_count + 1'b1;
      end else begin
        sda_filtered <= sda_filter_candidate;
      end
    end
  end

  typedef enum logic [5:0] {
    LL_IDLE,
    LL_WAIT_IDLE,
    LL_START_A,
    LL_START_B,
    LL_SEND_W_LOW,
    LL_SEND_W_HIGH,
    LL_ACK_W_LOW,
    LL_ACK_W_HIGH,
    LL_SEND_REG_LOW,
    LL_SEND_REG_HIGH,
    LL_ACK_REG_LOW,
    LL_ACK_REG_HIGH,
    LL_SEND_DATA_LOW,
    LL_SEND_DATA_HIGH,
    LL_ACK_DATA_LOW,
    LL_ACK_DATA_HIGH,
    LL_REP_LOW,
    LL_REP_HIGH,
    LL_REP_START_A,
    LL_REP_START_B,
    LL_SEND_R_LOW,
    LL_SEND_R_HIGH,
    LL_ACK_R_LOW,
    LL_ACK_R_HIGH,
    LL_READ_LOW,
    LL_READ_HIGH,
    LL_MASTER_NACK_LOW,
    LL_MASTER_NACK_HIGH,
    LL_STOP_A,
    LL_STOP_B,
    LL_STOP_C,
    LL_ABORT_RELEASE
  } ll_state_t;

  ll_state_t state;
  logic write_latched;
  logic [7:0] reg_latched, data_latched;
  logic [7:0] tx_byte, rx_byte;
  logic [2:0] bit_index;
  logic command_error;
  logic [31:0] divider_count;
  logic [31:0] idle_stable_count;
  logic [31:0] idle_wait_count;
  logic [31:0] scl_wait_count;

  wire state_tick = divider_count >= DIVIDER;
  wire sampled_bus_idle = scl_filtered && sda_filtered;
  wire requires_scl_high =
      state == LL_START_A || state == LL_START_B ||
      state == LL_SEND_W_HIGH || state == LL_ACK_W_HIGH ||
      state == LL_SEND_REG_HIGH || state == LL_ACK_REG_HIGH ||
      state == LL_SEND_DATA_HIGH || state == LL_ACK_DATA_HIGH ||
      state == LL_REP_HIGH || state == LL_REP_START_A ||
      state == LL_SEND_R_HIGH || state == LL_ACK_R_HIGH ||
      state == LL_READ_HIGH || state == LL_MASTER_NACK_HIGH ||
      state == LL_STOP_B || state == LL_STOP_C;

  always_comb begin
    scl_release = 1'b1;
    sda_release = 1'b1;
    case (state)
      LL_START_B: begin
        scl_release = 1'b1;
        sda_release = 1'b0;
      end
      LL_SEND_W_LOW, LL_SEND_REG_LOW, LL_SEND_DATA_LOW, LL_SEND_R_LOW: begin
        scl_release = 1'b0;
        sda_release = tx_byte[bit_index];
      end
      LL_SEND_W_HIGH, LL_SEND_REG_HIGH, LL_SEND_DATA_HIGH, LL_SEND_R_HIGH: begin
        scl_release = 1'b1;
        sda_release = tx_byte[bit_index];
      end
      LL_ACK_W_LOW, LL_ACK_REG_LOW, LL_ACK_DATA_LOW, LL_ACK_R_LOW,
      LL_READ_LOW, LL_MASTER_NACK_LOW, LL_REP_LOW: begin
        scl_release = 1'b0;
        sda_release = 1'b1;
      end
      LL_ACK_W_HIGH, LL_ACK_REG_HIGH, LL_ACK_DATA_HIGH, LL_ACK_R_HIGH,
      LL_READ_HIGH, LL_MASTER_NACK_HIGH, LL_REP_HIGH: begin
        scl_release = 1'b1;
        sda_release = 1'b1;
      end
      LL_REP_START_A: begin
        scl_release = 1'b1;
        sda_release = 1'b0;
      end
      LL_REP_START_B, LL_STOP_A: begin
        scl_release = 1'b0;
        sda_release = 1'b0;
      end
      LL_STOP_B: begin
        scl_release = 1'b1;
        sda_release = 1'b0;
      end
      default: begin
        scl_release = 1'b1;
        sda_release = 1'b1;
      end
    endcase
  end

  assign cmd_ready = !busy && state == LL_IDLE;
  assign bus_idle = sampled_bus_idle && !busy;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= LL_IDLE;
      write_latched <= 1'b0;
      reg_latched <= 8'b0;
      data_latched <= 8'b0;
      tx_byte <= 8'b0;
      rx_byte <= 8'b0;
      bit_index <= 3'd7;
      command_error <= 1'b0;
      divider_count <= 32'b0;
      idle_stable_count <= 32'b0;
      idle_wait_count <= 32'b0;
      scl_wait_count <= 32'b0;
      cmd_accepted <= 1'b0;
      busy <= 1'b0;
      done <= 1'b0;
      success <= 1'b0;
      timeout <= 1'b0;
      error_cause <= CAUSE_NONE;
      read_data <= 8'b0;
      transaction_sequence <= 32'b0;
    end else begin
      cmd_accepted <= 1'b0;
      done <= 1'b0;

      if (!busy) begin
        divider_count <= 32'b0;
        scl_wait_count <= 32'b0;
        if (cmd_valid && cmd_ready) begin
          busy <= 1'b1;
          cmd_accepted <= 1'b1;
          success <= 1'b0;
          timeout <= 1'b0;
          error_cause <= CAUSE_NONE;
          command_error <= 1'b0;
          write_latched <= cmd_write;
          reg_latched <= cmd_reg;
          data_latched <= cmd_wdata;
          read_data <= 8'b0;
          idle_stable_count <= 32'b0;
          idle_wait_count <= 32'b0;
          transaction_sequence <= transaction_sequence + 1'b1;
          state <= LL_WAIT_IDLE;
        end
      end else if (state == LL_WAIT_IDLE) begin
        if (sampled_bus_idle) begin
          idle_wait_count <= 32'b0;
          if (idle_stable_count + 1'b1 >= TICK_CYCLES) begin
            idle_stable_count <= TICK_CYCLES;
            state <= LL_START_A;
          end else begin
            idle_stable_count <= idle_stable_count + 1'b1;
          end
        end else begin
          idle_stable_count <= 32'b0;
          if (idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES) begin
            timeout <= 1'b1;
            command_error <= 1'b1;
            error_cause <= CAUSE_BUS_IDLE_TIMEOUT;
            state <= LL_ABORT_RELEASE;
          end else begin
            idle_wait_count <= idle_wait_count + 1'b1;
          end
        end
      end else if (state == LL_ABORT_RELEASE) begin
        busy <= 1'b0;
        success <= 1'b0;
        done <= 1'b1;
        state <= LL_IDLE;
      end else if (requires_scl_high && scl_release && !scl_filtered) begin
        divider_count <= 32'b0;
        if (scl_wait_count >= SCL_TIMEOUT_CYCLES) begin
          timeout <= 1'b1;
          command_error <= 1'b1;
          error_cause <= CAUSE_SCL_TIMEOUT;
          state <= LL_ABORT_RELEASE;
        end else begin
          scl_wait_count <= scl_wait_count + 1'b1;
        end
      end else if (state_tick) begin
        scl_wait_count <= 32'b0;
        divider_count <= 32'b0;
        case (state)
          LL_START_A: state <= LL_START_B;
          LL_START_B: begin
            tx_byte <= NVP_ADDR_W;
            bit_index <= 3'd7;
            state <= LL_SEND_W_LOW;
          end
          LL_SEND_W_LOW: state <= LL_SEND_W_HIGH;
          LL_SEND_W_HIGH: if (scl_filtered) begin
            if (bit_index == 0)
              state <= LL_ACK_W_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= LL_SEND_W_LOW;
            end
          end
          LL_ACK_W_LOW: state <= LL_ACK_W_HIGH;
          LL_ACK_W_HIGH: if (scl_filtered) begin
            if (sda_filtered) begin
              command_error <= 1'b1;
              error_cause <= CAUSE_WADDR_NACK;
              state <= LL_STOP_A;
            end else begin
              tx_byte <= reg_latched;
              bit_index <= 3'd7;
              state <= LL_SEND_REG_LOW;
            end
          end
          LL_SEND_REG_LOW: state <= LL_SEND_REG_HIGH;
          LL_SEND_REG_HIGH: if (scl_filtered) begin
            if (bit_index == 0)
              state <= LL_ACK_REG_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= LL_SEND_REG_LOW;
            end
          end
          LL_ACK_REG_LOW: state <= LL_ACK_REG_HIGH;
          LL_ACK_REG_HIGH: if (scl_filtered) begin
            if (sda_filtered) begin
              command_error <= 1'b1;
              error_cause <= CAUSE_REGADDR_NACK;
              state <= LL_STOP_A;
            end else if (write_latched) begin
              tx_byte <= data_latched;
              bit_index <= 3'd7;
              state <= LL_SEND_DATA_LOW;
            end else begin
              state <= LL_REP_LOW;
            end
          end
          LL_SEND_DATA_LOW: state <= LL_SEND_DATA_HIGH;
          LL_SEND_DATA_HIGH: if (scl_filtered) begin
            if (bit_index == 0)
              state <= LL_ACK_DATA_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= LL_SEND_DATA_LOW;
            end
          end
          LL_ACK_DATA_LOW: state <= LL_ACK_DATA_HIGH;
          LL_ACK_DATA_HIGH: if (scl_filtered) begin
            if (sda_filtered) begin
              command_error <= 1'b1;
              error_cause <= CAUSE_DATA_NACK;
            end
            state <= LL_STOP_A;
          end
          LL_REP_LOW: state <= LL_REP_HIGH;
          LL_REP_HIGH: if (scl_filtered) state <= LL_REP_START_A;
          LL_REP_START_A: if (scl_filtered) state <= LL_REP_START_B;
          LL_REP_START_B: begin
            tx_byte <= NVP_ADDR_R;
            bit_index <= 3'd7;
            state <= LL_SEND_R_LOW;
          end
          LL_SEND_R_LOW: state <= LL_SEND_R_HIGH;
          LL_SEND_R_HIGH: if (scl_filtered) begin
            if (bit_index == 0)
              state <= LL_ACK_R_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= LL_SEND_R_LOW;
            end
          end
          LL_ACK_R_LOW: state <= LL_ACK_R_HIGH;
          LL_ACK_R_HIGH: if (scl_filtered) begin
            if (sda_filtered) begin
              command_error <= 1'b1;
              error_cause <= CAUSE_RADDR_NACK;
              state <= LL_STOP_A;
            end else begin
              bit_index <= 3'd7;
              rx_byte <= 8'b0;
              state <= LL_READ_LOW;
            end
          end
          LL_READ_LOW: state <= LL_READ_HIGH;
          LL_READ_HIGH: if (scl_filtered) begin
            rx_byte[bit_index] <= sda_filtered;
            if (bit_index == 0)
              state <= LL_MASTER_NACK_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= LL_READ_LOW;
            end
          end
          LL_MASTER_NACK_LOW: state <= LL_MASTER_NACK_HIGH;
          LL_MASTER_NACK_HIGH: if (scl_filtered) begin
            read_data <= rx_byte;
            state <= LL_STOP_A;
          end
          LL_STOP_A: state <= LL_STOP_B;
          LL_STOP_B: if (scl_filtered) state <= LL_STOP_C;
          LL_STOP_C: if (scl_filtered) begin
            if (sda_filtered) begin
              busy <= 1'b0;
              success <= !command_error && !timeout;
              done <= 1'b1;
              idle_wait_count <= 32'b0;
              state <= LL_IDLE;
            end else if (idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES) begin
              timeout <= 1'b1;
              command_error <= 1'b1;
              error_cause <= CAUSE_BUS_IDLE_TIMEOUT;
              state <= LL_ABORT_RELEASE;
            end else begin
              idle_wait_count <= idle_wait_count + 1'b1;
            end
          end
          default: state <= LL_ABORT_RELEASE;
        endcase
      end else begin
        scl_wait_count <= 32'b0;
        divider_count <= divider_count + 1'b1;
      end
    end
  end
endmodule
