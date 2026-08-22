`timescale 1ns/1ps

// R1d post-init address-only probe.  This controller never loads or sends a
// register, data, or read-address byte: every transaction is exactly
// START, 8'h60, address ACK/NACK, STOP.
module nvp_i2c_address_probe #(
  parameter integer CLK_HZ = 62500000,
  parameter integer TARGET_COUNT = 10000,
  parameter integer DIVIDER_50KHZ = 625,
  parameter integer DIVIDER_25KHZ = 1250,
  parameter integer SCL_TIMEOUT_CYCLES = CLK_HZ / 50000,
  parameter integer BUS_IDLE_TIMEOUT_CYCLES = CLK_HZ / 1000
) (
  input  logic        clk,
  input  logic        control_write,
  input  logic [31:0] control_wdata,
  input  logic [3:0]  control_be,
  input  logic        init_done,
  input  logic        init_busy,
  input  logic        init_error,
  input  logic        init_scl_oen,
  input  logic        init_sda_oen,
  input  logic        raw_scl_i,
  input  logic        raw_sda_i,
  output logic        probe_owns_bus = 1'b0,
  output logic        probe_scl_oen,
  output logic        probe_sda_oen,
  output logic [31:0] probe_status,
  output logic [31:0] probe_count = 32'b0,
  output logic [31:0] probe_nack_count = 32'b0,
  output logic [31:0] probe_timeout_count = 32'b0,
  output logic [31:0] probe_divider = DIVIDER_50KHZ,
  output logic [31:0] probe_tick_cycles = DIVIDER_50KHZ + 1,
  output logic [31:0] probe_campaign_index = 32'b0
);
  localparam logic [7:0] ADDRESS_BYTE = 8'h60;

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_WAIT_HANDOFF,
    ST_PREAMBLE,
    ST_BUS_FREE,
    ST_START_A,
    ST_START_B,
    ST_SEND_ADDR_LOW,
    ST_SEND_ADDR_HIGH,
    ST_ACK_LOW,
    ST_ACK_HIGH,
    ST_STOP_A,
    ST_STOP_B
  } state_t;

  state_t state = ST_IDLE;
  logic busy = 1'b0;
  logic done = 1'b0;
  logic error = 1'b0;
  logic mode_25khz = 1'b0;
  logic init_done_seen = 1'b0;
  logic init_error_snapshot = 1'b0;
  logic bus_idle_gate_passed = 1'b0;
  logic scl_timeout = 1'b0;
  logic sampled_nack = 1'b0;
  logic [2:0] bit_index = 3'd7;
  logic [1:0] preamble_ticks = 2'b0;
  logic [31:0] divider_count = 32'b0;
  logic [31:0] bus_idle_wait_count = 32'b0;
  logic [31:0] scl_low_released_count = 32'b0;
  logic [2:0] scl_release_grace = 3'b0;
  logic previous_scl_oen = 1'b1;

  // Match the accepted NVP master's two-flop synchronizers and three-matching-
  // sample filter exactly.  Raw pins fan out only to stage zero.
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  logic [1:0] scl_sync = 2'b11;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  logic [1:0] sda_sync = 2'b11;
  logic scl_filter_candidate = 1'b1;
  logic sda_filter_candidate = 1'b1;
  logic [1:0] scl_filter_count = 2'b0;
  logic [1:0] sda_filter_count = 2'b0;
  logic scl_filtered = 1'b1;
  logic sda_filtered = 1'b1;

  wire released_scl_phase =
    state == ST_PREAMBLE || state == ST_BUS_FREE ||
    state == ST_START_A || state == ST_START_B ||
    state == ST_SEND_ADDR_HIGH || state == ST_ACK_HIGH ||
    state == ST_STOP_B;
  wire bus_idle_waiting = state == ST_WAIT_HANDOFF || state == ST_BUS_FREE;
  wire bus_is_idle = scl_filtered && sda_filtered;
  wire bus_idle_failure_now = busy && bus_idle_waiting && !bus_is_idle &&
                               bus_idle_wait_count >= BUS_IDLE_TIMEOUT_CYCLES;
  wire scl_timeout_now = busy && probe_owns_bus && released_scl_phase &&
                         probe_scl_oen && previous_scl_oen &&
                         scl_release_grace == 0 && !scl_filtered &&
                         scl_low_released_count >= SCL_TIMEOUT_CYCLES;
  wire control_is_50 = control_wdata == 32'h00000001;
  wire control_is_25 = control_wdata == 32'h00000003;
  wire control_is_full_word = control_be == 4'b1111;

  always_comb begin
    probe_scl_oen = 1'b1;
    probe_sda_oen = 1'b1;
    case (state)
      ST_START_B: begin
        probe_scl_oen = 1'b1;
        probe_sda_oen = 1'b0;
      end
      ST_SEND_ADDR_LOW: begin
        probe_scl_oen = 1'b0;
        probe_sda_oen = ADDRESS_BYTE[bit_index];
      end
      ST_SEND_ADDR_HIGH: begin
        probe_scl_oen = 1'b1;
        probe_sda_oen = ADDRESS_BYTE[bit_index];
      end
      ST_ACK_LOW: begin
        probe_scl_oen = 1'b0;
        probe_sda_oen = 1'b1;
      end
      ST_ACK_HIGH: begin
        probe_scl_oen = 1'b1;
        probe_sda_oen = 1'b1;
      end
      ST_STOP_A: begin
        probe_scl_oen = 1'b0;
        probe_sda_oen = 1'b0;
      end
      ST_STOP_B: begin
        probe_scl_oen = 1'b1;
        probe_sda_oen = 1'b0;
      end
      default: begin
        probe_scl_oen = 1'b1;
        probe_sda_oen = 1'b1;
      end
    endcase
  end

  // Status map: IDLE, BUSY, DONE, ERROR, MODE_25KHZ, INIT_DONE_SEEN,
  // INIT_ERROR_SNAPSHOT, BUS_IDLE_GATE_PASSED, SCL_TIMEOUT, then the two-bit
  // completed-campaign count in [10:9].
  always_comb begin
    probe_status = 32'b0;
    probe_status[0] = !busy;
    probe_status[1] = busy;
    probe_status[2] = done;
    probe_status[3] = error;
    probe_status[4] = mode_25khz;
    probe_status[5] = init_done_seen;
    probe_status[6] = init_error_snapshot;
    probe_status[7] = bus_idle_gate_passed;
    probe_status[8] = scl_timeout;
    probe_status[10:9] = probe_campaign_index[1:0];
  end

  always_ff @(posedge clk) begin
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

    previous_scl_oen <= probe_scl_oen;

    // Every control-register write is consumed exactly once by the register
    // bridge.  The engine accepts only the declared 50-then-25 sequence.
    if (control_write) begin
      if (!control_is_full_word || busy || error ||
          (probe_campaign_index == 0 && !control_is_50) ||
          (probe_campaign_index == 1 && (!done || !control_is_25)) ||
          (probe_campaign_index >= 2) ||
          !init_done || init_busy) begin
        error <= 1'b1;
      end else begin
        busy <= 1'b1;
        done <= 1'b0;
        mode_25khz <= control_is_25;
        bus_idle_gate_passed <= 1'b0;
        scl_timeout <= 1'b0;
        sampled_nack <= 1'b0;
        probe_count <= 32'b0;
        probe_nack_count <= 32'b0;
        probe_timeout_count <= 32'b0;
        probe_divider <= control_is_25 ? DIVIDER_25KHZ : DIVIDER_50KHZ;
        probe_tick_cycles <= control_is_25 ? DIVIDER_25KHZ + 1
                                            : DIVIDER_50KHZ + 1;
        divider_count <= 32'b0;
        bus_idle_wait_count <= 32'b0;
        scl_low_released_count <= 32'b0;
        scl_release_grace <= 3'b0;
        preamble_ticks <= 2'b0;
        state <= ST_WAIT_HANDOFF;
        if (probe_campaign_index == 0) begin
          init_done_seen <= init_done;
          init_error_snapshot <= init_error;
        end
      end
    end

    if (busy) begin
      if (bus_idle_failure_now) begin
        busy <= 1'b0;
        done <= 1'b1;
        error <= 1'b1;
        state <= ST_IDLE;
      end else if (scl_timeout_now) begin
        if (probe_timeout_count != 32'hFFFFFFFF)
          probe_timeout_count <= probe_timeout_count + 1'b1;
        busy <= 1'b0;
        done <= 1'b1;
        error <= 1'b1;
        scl_timeout <= 1'b1;
        state <= ST_IDLE;
      end else begin
        if (bus_idle_waiting && !bus_is_idle)
          bus_idle_wait_count <= bus_idle_wait_count + 1'b1;
        else if (!bus_idle_waiting)
          bus_idle_wait_count <= 32'b0;

        if (!probe_owns_bus || !released_scl_phase || !probe_scl_oen) begin
          scl_low_released_count <= 32'b0;
          scl_release_grace <= 3'b0;
        end else if (!previous_scl_oen) begin
          scl_release_grace <= 3'd5;
        end else if (scl_release_grace != 0) begin
          scl_release_grace <= scl_release_grace - 1'b1;
        end else if (!scl_filtered) begin
          scl_low_released_count <= scl_low_released_count + 1'b1;
        end

        if (state == ST_WAIT_HANDOFF) begin
        divider_count <= 32'b0;
        if (init_done && !init_busy && init_scl_oen && init_sda_oen &&
            bus_is_idle) begin
          probe_owns_bus <= 1'b1;
          bus_idle_gate_passed <= 1'b1;
          bus_idle_wait_count <= 32'b0;
          preamble_ticks <= 2'b0;
          state <= ST_PREAMBLE;
        end
        end else if (divider_count >= probe_divider) begin
        divider_count <= 32'b0;
        case (state)
          ST_PREAMBLE: begin
            if (preamble_ticks == 1) begin
              state <= ST_BUS_FREE;
              bus_idle_wait_count <= 32'b0;
            end else begin
              preamble_ticks <= preamble_ticks + 1'b1;
            end
          end
          ST_BUS_FREE: begin
            if (bus_is_idle) begin
              state <= ST_START_A;
              bus_idle_wait_count <= 32'b0;
            end
          end
          ST_START_A: state <= ST_START_B;
          ST_START_B: begin
            bit_index <= 3'd7;
            sampled_nack <= 1'b0;
            scl_low_released_count <= 32'b0;
            state <= ST_SEND_ADDR_LOW;
          end
          ST_SEND_ADDR_LOW: state <= ST_SEND_ADDR_HIGH;
          ST_SEND_ADDR_HIGH: if (scl_filtered) begin
            if (bit_index == 0)
              state <= ST_ACK_LOW;
            else begin
              bit_index <= bit_index - 1'b1;
              state <= ST_SEND_ADDR_LOW;
            end
          end
          ST_ACK_LOW: state <= ST_ACK_HIGH;
          ST_ACK_HIGH: if (scl_filtered) begin
            sampled_nack <= sda_filtered;
            state <= ST_STOP_A;
          end
          ST_STOP_A: state <= ST_STOP_B;
          ST_STOP_B: if (scl_filtered) begin
            if (probe_count == 32'hFFFFFFFF) begin
              busy <= 1'b0;
              done <= 1'b1;
              error <= 1'b1;
              state <= ST_IDLE;
            end else begin
              probe_count <= probe_count + 1'b1;
              if (sampled_nack) begin
                if (probe_nack_count == 32'hFFFFFFFF) begin
                  busy <= 1'b0;
                  done <= 1'b1;
                  error <= 1'b1;
                  state <= ST_IDLE;
                end else begin
                  probe_nack_count <= probe_nack_count + 1'b1;
                end
              end
              if (probe_count + 1'b1 == TARGET_COUNT) begin
                busy <= 1'b0;
                done <= 1'b1;
                if (probe_campaign_index != 32'hFFFFFFFF)
                  probe_campaign_index <= probe_campaign_index + 1'b1;
                state <= ST_IDLE;
              end else begin
                bus_idle_wait_count <= 32'b0;
                state <= ST_BUS_FREE;
              end
            end
          end
          default: state <= ST_IDLE;
        endcase
        end else begin
          divider_count <= divider_count + 1'b1;
        end
      end
    end
  end
endmodule
