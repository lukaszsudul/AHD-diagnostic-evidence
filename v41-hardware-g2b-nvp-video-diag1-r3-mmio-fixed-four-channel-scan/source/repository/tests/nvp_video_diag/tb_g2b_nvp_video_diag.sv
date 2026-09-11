`timescale 1ns/1ps

// Deterministic contract simulation for the NVP four-channel diagnostic.
// The register model is deliberately transaction-level: the diagnostic core
// can request only fixed register operations, while the physical open-drain
// transaction engine is compiled and checked independently by the gate runner.
module tb_g2b_nvp_video_diag;
  localparam logic [7:0] CLASS_ACTIVE_STABLE = 8'd1;
  localparam logic [7:0] CLASS_NO_VIDEO_STABLE = 8'd2;
  localparam logic [7:0] CLASS_LOCK_UNSTABLE = 8'd3;
  localparam logic [7:0] CLASS_STATUS_CONTRADICTORY = 8'd4;

  logic clk = 1'b0;
  logic reset = 1'b1;
  always #5 clk = ~clk;

  logic autoinit_done = 1'b0;
  logic autoinit_busy = 1'b1;
  logic autoinit_error = 1'b0;
  logic nvp_reset_released = 1'b0;
  logic transport_stream_enabled = 1'b0;
  logic transport_c2h_active = 1'b0;
  logic transport_ring_empty = 1'b1;
  logic transport_ring_full = 1'b0;

  logic i2c_cmd_valid;
  logic i2c_cmd_ready;
  logic i2c_cmd_write;
  logic [7:0] i2c_cmd_reg;
  logic [7:0] i2c_cmd_wdata;
  logic i2c_cmd_accepted;
  logic i2c_busy;
  logic i2c_done;
  logic i2c_success;
  logic i2c_timeout;
  logic [7:0] i2c_read_data;
  logic i2c_bus_idle;

  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = 17'b0;
  logic [31:0] mmio_req_wdata = 32'b0;
  logic [3:0] mmio_req_be = 4'hf;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b1;
  logic [31:0] mmio_rsp_rdata;

  logic diagnostic_i2c_owns_bus;
  logic capture_ready;
  logic [15:0] current_session_id;
  logic [2:0] current_round;
  logic [2:0] current_channel;
  logic product_baseline_restored;

  g2b_nvp_video_diag #(
    .CYCLES_PER_MS(1),
    .SETTLE_TIME_MS(2),
    .STATUS_SAMPLE_INTERVAL_MS(1),
    .REQUIRED_STABLE_SAMPLES(5),
    .MAX_STATUS_WAIT_MS(200)
  ) dut (
    .clk(clk), .reset(reset),
    .autoinit_done(autoinit_done), .autoinit_busy(autoinit_busy),
    .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
    .transport_stream_enabled(transport_stream_enabled),
    .transport_c2h_active(transport_c2h_active),
    .transport_ring_empty(transport_ring_empty),
    .transport_ring_full(transport_ring_full),
    .i2c_cmd_valid(i2c_cmd_valid), .i2c_cmd_ready(i2c_cmd_ready),
    .i2c_cmd_write(i2c_cmd_write), .i2c_cmd_reg(i2c_cmd_reg),
    .i2c_cmd_wdata(i2c_cmd_wdata),
    .i2c_cmd_accepted(i2c_cmd_accepted), .i2c_busy(i2c_busy),
    .i2c_done(i2c_done), .i2c_success(i2c_success),
    .i2c_timeout(i2c_timeout), .i2c_read_data(i2c_read_data),
    .i2c_bus_idle(i2c_bus_idle),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata),
    .diagnostic_i2c_owns_bus(diagnostic_i2c_owns_bus),
    .capture_ready(capture_ready),
    .current_session_id(current_session_id),
    .current_round(current_round), .current_channel(current_channel),
    .product_baseline_restored(product_baseline_restored)
  );

  logic [7:0] bank0 [0:255];
  logic [7:0] bank1 [0:255];
  logic [7:0] selected_bank;
  logic model_pending;
  logic model_write;
  logic [7:0] model_reg;
  logic [7:0] model_wdata;
  logic [7:0] model_bank;
  logic inject_nack_once;
  logic inject_timeout_once;
  logic inject_route_mismatch;
  logic route_written_after_injection;
  integer illegal_write_count;
  integer route_while_active_count;
  integer route_while_snapshot_valid_count;
  integer route_write_count;
  integer bg78_write_count;
  integer bg79_write_count;
  logic [3:0] route_log [0:31];
  logic [7:0] bg78_log [0:15];
  logic [7:0] bg79_log [0:15];
  logic unstable_flip;
  logic [31:0] coherent_snapshot [0:7];
  logic [31:0] host_snapshot_history [0:15][0:7];
  logic [15:0] host_snapshot_generation [0:15];
  logic [15:0] host_snapshot_session [0:15];
  logic [15:0] host_session_seen;
  integer snapshot_coherence_retries;

  assign i2c_cmd_ready = !model_pending;
  assign i2c_cmd_accepted = i2c_cmd_valid && i2c_cmd_ready;
  assign i2c_busy = model_pending;
  assign i2c_bus_idle = !model_pending;

  integer init_index;
  task automatic initialize_register_model;
    begin
      for (init_index = 0; init_index < 256; init_index = init_index + 1) begin
        bank0[init_index] = 8'h00;
        bank1[init_index] = 8'h00;
      end
      // Exact PRODUCT all-channel forced-1080p25 baseline.
      bank0[8'h78] = 8'h88;
      bank0[8'h79] = 8'h88;
      bank0[8'h80] = 8'h0f;
      bank0[8'h00] = 8'h00; bank0[8'h01] = 8'h00;
      bank0[8'h02] = 8'h00; bank0[8'h03] = 8'h00;
      bank0[8'h08] = 8'h00; bank0[8'h09] = 8'h00;
      bank0[8'h0a] = 8'h00; bank0[8'h0b] = 8'h00;
      bank0[8'h81] = 8'h03; bank0[8'h82] = 8'h03;
      bank0[8'h83] = 8'h03; bank0[8'h84] = 8'h03;
      bank0[8'h85] = 8'h00; bank0[8'h86] = 8'h00;
      bank0[8'h87] = 8'h00; bank0[8'h88] = 8'h00;

      // CH1 ACTIVE, CH2 NO_VIDEO, CH3 contradictory, CH4 unstable.
      bank0[8'ha8] = 8'h0a;
      bank0[8'he0] = 8'h01;
      bank0[8'he1] = 8'h01;
      bank0[8'he2] = 8'h01;
      bank0[8'he8] = 8'h02;
      bank0[8'he9] = 8'h01;
      bank0[8'hea] = 8'h00;
      bank0[8'heb] = 8'h01;
      bank1[8'hc2] = 8'ha0;
      selected_bank = 8'h00;
      unstable_flip = 1'b0;
      inject_nack_once = 1'b0;
      inject_timeout_once = 1'b0;
      inject_route_mismatch = 1'b0;
      route_written_after_injection = 1'b0;
      illegal_write_count = 0;
      route_while_active_count = 0;
      route_while_snapshot_valid_count = 0;
      route_write_count = 0;
      bg78_write_count = 0;
      bg79_write_count = 0;
    end
  endtask

  function automatic logic write_is_whitelisted(
      input logic [7:0] bank, input logic [7:0] reg_address);
    begin
      write_is_whitelisted = reg_address == 8'hff ||
          (bank == 8'h00 && (reg_address == 8'h78 || reg_address == 8'h79)) ||
          (bank == 8'h01 && reg_address == 8'hc2);
    end
  endfunction

  always @(posedge clk) begin
    if (reset) begin
      model_pending <= 1'b0;
      model_write <= 1'b0;
      model_reg <= 8'b0;
      model_wdata <= 8'b0;
      model_bank <= 8'b0;
      i2c_done <= 1'b0;
      i2c_success <= 1'b0;
      i2c_timeout <= 1'b0;
      i2c_read_data <= 8'b0;
    end else begin
      i2c_done <= 1'b0;
      i2c_success <= 1'b0;
      i2c_timeout <= 1'b0;
      if (i2c_cmd_accepted) begin
        model_pending <= 1'b1;
        model_write <= i2c_cmd_write;
        model_reg <= i2c_cmd_reg;
        model_wdata <= i2c_cmd_wdata;
        model_bank <= selected_bank;
      end else if (model_pending) begin
        model_pending <= 1'b0;
        i2c_done <= 1'b1;
        if (inject_timeout_once) begin
          inject_timeout_once <= 1'b0;
          i2c_success <= 1'b0;
          i2c_timeout <= 1'b1;
        end else if (inject_nack_once) begin
          inject_nack_once <= 1'b0;
          i2c_success <= 1'b0;
        end else begin
          i2c_success <= 1'b1;
          if (model_write) begin
            if (!write_is_whitelisted(model_bank, model_reg))
              illegal_write_count <= illegal_write_count + 1;
            if (model_reg == 8'hff) begin
              selected_bank <= model_wdata;
            end else if (model_bank == 8'h00) begin
              bank0[model_reg] <= model_wdata;
              if (model_reg == 8'h78) begin
                bg78_log[bg78_write_count] <= model_wdata;
                bg78_write_count <= bg78_write_count + 1;
              end
              if (model_reg == 8'h79) begin
                bg79_log[bg79_write_count] <= model_wdata;
                bg79_write_count <= bg79_write_count + 1;
              end
            end else if (model_bank == 8'h01) begin
              bank1[model_reg] <= model_wdata;
              if (model_reg == 8'hc2) begin
                route_log[route_write_count] <= model_wdata[3:0];
                route_write_count <= route_write_count + 1;
                if (transport_stream_enabled || transport_c2h_active ||
                    !transport_ring_empty || transport_ring_full)
                  route_while_active_count <= route_while_active_count + 1;
                if (dut.current_result_valid)
                  route_while_snapshot_valid_count <=
                      route_while_snapshot_valid_count + 1;
                if (inject_route_mismatch)
                  route_written_after_injection <= 1'b1;
              end
            end
          end else if (model_reg == 8'hff) begin
            i2c_read_data <= selected_bank;
          end else if (model_bank == 8'h00) begin
            if (model_reg == 8'heb) begin
              // Never permit five identical samples for CH4.
              unstable_flip <= ~unstable_flip;
              i2c_read_data <= unstable_flip ? 8'h01 : 8'h00;
            end else begin
              i2c_read_data <= bank0[model_reg];
            end
          end else begin
            if (model_reg == 8'hc2 && inject_route_mismatch &&
                route_written_after_injection) begin
              i2c_read_data <= bank1[model_reg] ^ 8'h01;
              inject_route_mismatch <= 1'b0;
              route_written_after_injection <= 1'b0;
            end else begin
              i2c_read_data <= bank1[model_reg];
            end
          end
        end
      end
    end
  end

  task automatic mmio_write(input logic [16:0] address,
                            input logic [31:0] value);
    integer guard;
    begin
      @(negedge clk);
      mmio_req_addr = address;
      mmio_req_wdata = value;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      guard = 0;
      while (!mmio_req_ready && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_req_ready) $fatal(1, "MMIO write ready timeout");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = 17'b0;
      mmio_req_wdata = 32'b0;
    end
  endtask

  task automatic mmio_read(input logic [16:0] address,
                           output logic [31:0] value);
    integer guard;
    begin
      @(negedge clk);
      mmio_req_addr = address;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      guard = 0;
      while (!mmio_req_ready && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_req_ready) $fatal(1, "MMIO read ready timeout");
      @(negedge clk);
      mmio_req_valid = 1'b0;
      mmio_req_addr = 17'b0;
      guard = 0;
      while (!mmio_rsp_valid && guard < 20) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (!mmio_rsp_valid) $fatal(1, "MMIO response timeout");
      value = mmio_rsp_rdata;
    end
  endtask

  task automatic reset_scenario;
    begin
      reset = 1'b1;
      autoinit_done = 1'b0;
      autoinit_busy = 1'b1;
      nvp_reset_released = 1'b0;
      transport_stream_enabled = 1'b0;
      transport_c2h_active = 1'b0;
      transport_ring_empty = 1'b1;
      transport_ring_full = 1'b0;
      mmio_req_valid = 1'b0;
      initialize_register_model();
      repeat (5) @(posedge clk);
      reset = 1'b0;
      repeat (3) @(posedge clk);
      if (diagnostic_i2c_owns_bus || i2c_cmd_valid)
        $fatal(1, "Diagnostic bus activity before autoinit handoff");
      autoinit_done = 1'b1;
      autoinit_busy = 1'b0;
      nvp_reset_released = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic prepare_diagnostic;
    integer guard;
    begin
      mmio_write(17'h03c0c, 32'h0000_0002);
      guard = 0;
      while (!dut.prepared && !dut.error_flag && guard < 2000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!dut.prepared || dut.error_flag)
        $fatal(1, "Diagnostic prepare failed state=%0d error=%h",
               dut.state, dut.error_code);
      if (!product_baseline_restored || diagnostic_i2c_owns_bus)
        $fatal(1, "Prepare did not return bus/baseline to idle");
    end
  endtask

  task automatic start_scan;
    begin
      mmio_write(17'h03c0c, 32'h0000_0004);
    end
  endtask

  function automatic integer expected_channel(input integer session);
    integer position;
    integer round_index;
    begin
      round_index = (session - 1) / 4;
      position = (session - 1) % 4;
      case (round_index)
        0: case (position) 0: expected_channel=1; 1: expected_channel=2;
             2: expected_channel=3; default: expected_channel=4; endcase
        1: case (position) 0: expected_channel=4; 1: expected_channel=3;
             2: expected_channel=2; default: expected_channel=1; endcase
        2: case (position) 0: expected_channel=2; 1: expected_channel=3;
             2: expected_channel=4; default: expected_channel=1; endcase
        default: case (position) 0: expected_channel=3; 1: expected_channel=4;
             2: expected_channel=1; default: expected_channel=2; endcase
      endcase
    end
  endfunction

  function automatic logic [7:0] expected_class(input integer channel);
    begin
      case (channel)
        1: expected_class = CLASS_ACTIVE_STABLE;
        2: expected_class = CLASS_NO_VIDEO_STABLE;
        3: expected_class = CLASS_STATUS_CONTRADICTORY;
        default: expected_class = CLASS_LOCK_UNSTABLE;
      endcase
    end
  endfunction

  function automatic logic [3:0] expected_color(input integer round_number,
                                                 input integer channel);
    begin
      case (round_number)
        1: case (channel) 1: expected_color=4'h6; 2: expected_color=4'h4;
             3: expected_color=4'h3; default: expected_color=4'h1; endcase
        2: case (channel) 1: expected_color=4'h1; 2: expected_color=4'h6;
             3: expected_color=4'h4; default: expected_color=4'h3; endcase
        3: case (channel) 1: expected_color=4'h3; 2: expected_color=4'h1;
             3: expected_color=4'h6; default: expected_color=4'h4; endcase
        default: case (channel) 1: expected_color=4'h4; 2: expected_color=4'h3;
             3: expected_color=4'h1; default: expected_color=4'h6; endcase
      endcase
    end
  endfunction

  task automatic wait_capture_ready(input integer expected_session);
    integer guard;
    begin
      guard = 0;
      while (!capture_ready && !dut.error_flag && guard < 4000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!capture_ready || dut.error_flag)
        $fatal(1, "Capture-ready timeout session=%0d state=%0d sub=%0d error=%h txn=%0b valid=%0b accept=%0b ready=%0b model=%0b bank=%h round=%0d channel=%0d txcount=%0d done=%0b success=%0b",
               expected_session, dut.state, dut.substep, dut.error_code,
               dut.txn_pending, i2c_cmd_valid, i2c_cmd_accepted,
               i2c_cmd_ready, model_pending, selected_bank,
               current_round, current_channel, dut.i2c_transaction_count,
               i2c_done, i2c_success);
      if (current_session_id != expected_session)
        $fatal(1, "Session mismatch expected=%0d actual=%0d",
               expected_session, current_session_id);
      if (current_channel != expected_channel(expected_session))
        $fatal(1, "Channel order mismatch session=%0d expected=%0d actual=%0d",
               expected_session, expected_channel(expected_session),
               current_channel);
      if (current_round != (expected_session - 1) / 4)
        $fatal(1, "Round mismatch session=%0d", expected_session);
      if (dut.current_classification !=
          expected_class(expected_channel(expected_session)))
        $fatal(1, "Classification mismatch session=%0d channel=%0d got=%0d",
               expected_session, current_channel,
               dut.current_classification);
      if (diagnostic_i2c_owns_bus)
        $fatal(1, "Diagnostic retained I2C ownership at CAPTURE_READY");
      if (!dut.current_result_valid)
        $fatal(1, "CAPTURE_READY asserted without a valid result snapshot");
      if (dut.current_result_session_id != current_session_id)
        $fatal(1, "Snapshot session does not match current session");
      if (expected_channel(expected_session) == 4 &&
          dut.current_classification == CLASS_LOCK_UNSTABLE &&
          dut.status_wait_counter != 200)
        $fatal(1, "Bounded status counter did not saturate at timeout");
    end
  endtask

  task automatic collect_coherent_snapshot(input integer expected_session);
    logic [31:0] valid0;
    logic [31:0] valid1;
    logic [31:0] generation0;
    logic [31:0] generation1;
    logic [31:0] session0;
    logic [31:0] session1;
    logic coherent;
    integer attempt;
    integer word_index;
    begin
      coherent = 1'b0;
      attempt = 0;
      while (!coherent && attempt < 4) begin
        mmio_read(17'h03d20, valid0);
        mmio_read(17'h03d28, generation0);
        mmio_read(17'h03d24, session0);
        for (word_index = 0; word_index < 8; word_index = word_index + 1)
          mmio_read(17'h03d00 + word_index * 4,
                    coherent_snapshot[word_index]);
        mmio_read(17'h03d28, generation1);
        mmio_read(17'h03d24, session1);
        mmio_read(17'h03d20, valid1);
        coherent = valid0[0] && valid1[0] &&
            generation0 == generation1 && session0 == session1 &&
            coherent_snapshot[0][15:0] == session0[15:0] &&
            session0[15:0] == current_session_id;
        attempt = attempt + 1;
      end
      if (!coherent)
        $fatal(1, "Current-session snapshot was not coherent after 3 retries");
      snapshot_coherence_retries = snapshot_coherence_retries + attempt - 1;
      if (session0[15:0] != expected_session)
        $fatal(1, "Snapshot session mismatch expected=%0d actual=%0d",
               expected_session, session0[15:0]);
      if (generation0[15:0] != expected_session)
        $fatal(1, "Snapshot generation is not once-per-session expected=%0d actual=%0d",
               expected_session, generation0[15:0]);
      if (coherent_snapshot[0][20:18] != ((expected_session - 1) / 4) + 1)
        $fatal(1, "Snapshot round packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[0][23:21] != expected_channel(expected_session))
        $fatal(1, "Snapshot channel packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[0][31:24] !=
          expected_class(expected_channel(expected_session)))
        $fatal(1, "Snapshot classification packing mismatch session=%0d",
               expected_session);
      if (coherent_snapshot[0][17:16] != 0)
        $fatal(1, "Snapshot word 0 reserved bits are nonzero");
      if (coherent_snapshot[1][31:24] != expected_channel(expected_session)-1 ||
          coherent_snapshot[1][23:16] != dut.current_route_readback ||
          coherent_snapshot[1][15:8] !=
              {4'b0, expected_color((expected_session-1)/4+1,
                                     expected_channel(expected_session))} ||
          coherent_snapshot[1][7:0] != dut.stable_sample_count)
        $fatal(1, "Snapshot word 1 packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[2] != {dut.raw_novid, dut.raw_agc_lock,
          dut.raw_cmp_lock, dut.raw_h_lock})
        $fatal(1, "Snapshot word 2 packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[3] != {dut.raw_channel_status,
          dut.current_bg78_readback, dut.current_bg79_readback,
          dut.total_status_samples})
        $fatal(1, "Snapshot word 3 packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[4][31:24] != 0 ||
          coherent_snapshot[4][23:16] !=
              expected_class(expected_channel(expected_session)) ||
          coherent_snapshot[4][15:9] != 0 ||
          coherent_snapshot[4][8:6] != (expected_session-1)%4 ||
          coherent_snapshot[4][5:3] != (expected_session-1)/4 ||
          coherent_snapshot[4][2:0] != expected_channel(expected_session))
        $fatal(1, "Snapshot word 4 packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[5] != dut.i2c_transaction_count)
        $fatal(1, "Snapshot word 5 packing mismatch session=%0d", expected_session);
      if (coherent_snapshot[6] != 0 || coherent_snapshot[7] != 0)
        $fatal(1, "Snapshot error/counter summary unexpectedly nonzero");
      if (host_session_seen[expected_session-1])
        $fatal(1, "Duplicate host snapshot session=%0d", expected_session);
      host_session_seen[expected_session-1] = 1'b1;
      host_snapshot_generation[expected_session-1] = generation0[15:0];
      host_snapshot_session[expected_session-1] = session0[15:0];
      for (word_index = 0; word_index < 8; word_index = word_index + 1)
        host_snapshot_history[expected_session-1][word_index] =
            coherent_snapshot[word_index];
    end
  endtask

  task automatic emulate_capture_and_pass;
    logic [2:0] held_channel;
    logic [15:0] held_generation;
    logic [15:0] held_snapshot_session;
    integer guard;
    integer word_index;
    begin
      held_channel = current_channel;
      held_generation = dut.current_result_generation;
      held_snapshot_session = dut.current_result_session_id;
      transport_stream_enabled = 1'b1;
      transport_c2h_active = 1'b1;
      transport_ring_empty = 1'b0;
      repeat (8) begin
        @(posedge clk);
        if (current_channel != held_channel)
          $fatal(1, "Route/channel changed during active transport");
        if (i2c_cmd_valid)
          $fatal(1, "I2C command emitted during active transport");
        if (!dut.current_result_valid ||
            dut.current_result_generation != held_generation ||
            dut.current_result_session_id != held_snapshot_session)
          $fatal(1, "Snapshot coherence metadata changed while host was active");
        if (dut.current_result_word_0 != coherent_snapshot[0] ||
            dut.current_result_word_1 != coherent_snapshot[1] ||
            dut.current_result_word_2 != coherent_snapshot[2] ||
            dut.current_result_word_3 != coherent_snapshot[3] ||
            dut.current_result_word_4 != coherent_snapshot[4] ||
            dut.current_result_word_5 != coherent_snapshot[5] ||
            dut.current_result_word_6 != coherent_snapshot[6] ||
            dut.current_result_word_7 != coherent_snapshot[7])
          $fatal(1, "Snapshot payload changed during capture");
      end
      transport_stream_enabled = 1'b0;
      transport_c2h_active = 1'b0;
      transport_ring_empty = 1'b1;
      repeat (2) @(posedge clk);
      mmio_write(17'h03c34, {current_session_id, 12'b0, 4'b1001});
      guard = 0;
      while (capture_ready && !dut.error_flag && guard < 100) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (capture_ready || dut.error_flag)
        $fatal(1, "Capture acknowledgement was not accepted");
      if (dut.current_result_valid)
        $fatal(1, "Snapshot valid did not clear after matching response");
    end
  endtask

  task automatic wait_error_and_restore;
    integer guard;
    begin
      guard = 0;
      while ((!dut.error_flag || !product_baseline_restored ||
              dut.state != 6'd22) && guard < 4000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (!dut.error_flag || !product_baseline_restored)
        $fatal(1, "Error-safe restoration did not complete state=%0d err=%h",
               dut.state, dut.error_code);
      if (bank0[8'h78] != 8'h88 || bank0[8'h79] != 8'h88 ||
          bank1[8'hc2] != 8'ha0 || selected_bank != 8'h00)
        $fatal(1, "Error-safe restore did not recover exact baseline");
      if (route_while_snapshot_valid_count != 0)
        $fatal(1, "Error-safe restore changed route while snapshot was valid");
    end
  endtask

  logic [31:0] read_value;
  integer session;
  integer active_seen;
  integer no_video_seen;
  integer contradictory_seen;
  integer unstable_seen;
  integer error_restore_passes;
  integer reserved_address;
  integer previous_status_counter;
  integer status_counter_wraps;
  integer previous_state;
  integer settle_cycle_count;
  integer settle_boundary_checks;
  integer sample_delay_cycle_count;
  integer sample_delay_boundary_checks;
  integer status_window_cycle_count;
  integer status_timeout_boundary_checks;
  logic previous_sample_delay_active;

  always @(posedge clk) begin
    if (reset) begin
      previous_status_counter <= 0;
      status_counter_wraps <= 0;
      previous_state <= 0;
      settle_cycle_count <= 0;
      settle_boundary_checks <= 0;
      sample_delay_cycle_count <= 0;
      sample_delay_boundary_checks <= 0;
      status_window_cycle_count <= 0;
      status_timeout_boundary_checks <= 0;
      previous_sample_delay_active <= 1'b0;
    end else begin
      // With CYCLES_PER_MS=1, WAIT_SETTLE must execute for exactly the
      // configured two clock cycles before SAMPLE_STATUS becomes active.
      if (dut.state == 6'd10) begin
        settle_cycle_count <= settle_cycle_count + 1;
      end else begin
        if (previous_state == 6'd10) begin
          if (settle_cycle_count != 2)
            $fatal(1, "Accelerated settle boundary mismatch cycles=%0d",
                   settle_cycle_count);
          settle_boundary_checks <= settle_boundary_checks + 1;
        end
        settle_cycle_count <= 0;
      end

      // Each non-final status sample loads delay_counter=1.  For the
      // accelerated SAMPLE_INTERVAL_CYCLES=1 contract it must remain active
      // for exactly one SAMPLE_STATUS clock, neither zero nor two clocks.
      if (dut.state == 6'd11) begin
        if (dut.delay_counter != 0)
          sample_delay_cycle_count <= sample_delay_cycle_count + 1;
        if (previous_sample_delay_active && dut.delay_counter == 0) begin
          if (sample_delay_cycle_count != 1)
            $fatal(1, "Accelerated sample interval mismatch cycles=%0d",
                   sample_delay_cycle_count);
          sample_delay_boundary_checks <= sample_delay_boundary_checks + 1;
          sample_delay_cycle_count <= 0;
        end
        previous_sample_delay_active <= dut.delay_counter != 0;
      end else begin
        sample_delay_cycle_count <= 0;
        previous_sample_delay_active <= 1'b0;
      end

      // The elapsed status window is an exact cycle counter until 200, then
      // saturates while any in-flight I2C read is reaped.  This checks both
      // the first-hit boundary and every held-at-maximum cycle.
      if (dut.state == 6'd11) begin
        if (dut.status_wait_counter !=
            ((status_window_cycle_count >= 200) ?
             200 : status_window_cycle_count))
          $fatal(1, "Accelerated status boundary mismatch elapsed=%0d counter=%0d",
                 status_window_cycle_count, dut.status_wait_counter);
        if (dut.status_wait_counter == 200 && previous_status_counter < 200) begin
          if (status_window_cycle_count != 200)
            $fatal(1, "Status maximum reached at wrong cycle=%0d",
                   status_window_cycle_count);
          status_timeout_boundary_checks <=
              status_timeout_boundary_checks + 1;
        end
        status_window_cycle_count <= status_window_cycle_count + 1;
      end else begin
        status_window_cycle_count <= 0;
      end

      if (dut.state == 6'd11 && previous_state == 6'd11 &&
          previous_status_counter >
          dut.status_wait_counter)
        status_counter_wraps <= status_counter_wraps + 1;
      previous_status_counter <= dut.status_wait_counter;
      previous_state <= dut.state;
    end
  end
  initial begin
    initialize_register_model();
    repeat (5) @(posedge clk);
    reset_scenario();
    if ($bits(dut.delay_counter) != 2 ||
        $bits(dut.status_wait_counter) != 8)
      $fatal(1, "Derived wait-counter widths are not minimal for test parameters");
    if (dut.SETTLE_CYCLES != 2 || dut.SAMPLE_INTERVAL_CYCLES != 1 ||
        dut.MAX_STATUS_WAIT_CYCLES != 200)
      $fatal(1, "Accelerated timing constants do not equal 2/1/200 cycles");

    mmio_read(17'h03c00, read_value);
    if (read_value != 32'h4e56_5034) $fatal(1, "DIAG_MAGIC mismatch");
    mmio_read(17'h03c04, read_value);
    if (read_value != 32'h0001_0002) $fatal(1, "DIAG_VERSION mismatch");
    mmio_read(17'h03c08, read_value);
    if (read_value != 32'h0000_0bff || read_value[9:8] != 2'b11 ||
        read_value[10] != 1'b0 || read_value[11] != 1'b1)
      $fatal(1, "R1 snapshot capability bits mismatch");
    mmio_read(17'h03d20, read_value);
    if (read_value != 0) $fatal(1, "Snapshot unexpectedly valid after reset");
    for (reserved_address = 17'h03d2c; reserved_address <= 17'h03efc;
         reserved_address = reserved_address + 4) begin
      mmio_read(reserved_address[16:0], read_value);
      if (read_value != 0)
        $fatal(1, "Reserved snapshot address nonzero: 0x%05x",
               reserved_address);
    end

    prepare_diagnostic();
    if (bank0[8'h80] != 8'h0f || bank0[8'h81] != 8'h03 ||
        bank0[8'h84] != 8'h03)
      $fatal(1, "All-channel configuration verify altered baseline");
    start_scan();

    active_seen = 0;
    no_video_seen = 0;
    contradictory_seen = 0;
    unstable_seen = 0;
    host_session_seen = 16'b0;
    snapshot_coherence_retries = 0;
    for (session = 1; session <= 16; session = session + 1) begin
      wait_capture_ready(session);
      collect_coherent_snapshot(session);
      case (dut.current_classification)
        CLASS_ACTIVE_STABLE: active_seen = active_seen + 1;
        CLASS_NO_VIDEO_STABLE: no_video_seen = no_video_seen + 1;
        CLASS_STATUS_CONTRADICTORY:
          contradictory_seen = contradictory_seen + 1;
        CLASS_LOCK_UNSTABLE: unstable_seen = unstable_seen + 1;
        default: $fatal(1, "Unexpected classification");
      endcase
      emulate_capture_and_pass();
    end

    session = 0;
    while ((!dut.done_flag || !product_baseline_restored) && session < 4000) begin
      @(posedge clk);
      session = session + 1;
    end
    if (!dut.done_flag || dut.scan_completed_sessions != 16)
      $fatal(1, "4x4 scan did not finish exactly 16 sessions");
    if (active_seen != 4 || no_video_seen != 4 ||
        contradictory_seen != 4 || unstable_seen != 4)
      $fatal(1, "Status-class coverage failed A=%0d N=%0d C=%0d U=%0d",
             active_seen, no_video_seen, contradictory_seen, unstable_seen);
    if (illegal_write_count != 0 || route_while_active_count != 0 ||
        route_while_snapshot_valid_count != 0 || status_counter_wraps != 0)
      $fatal(1, "Whitelist/freeze/counter failure illegal=%0d active=%0d snapshot=%0d wraps=%0d",
             illegal_write_count, route_while_active_count,
             route_while_snapshot_valid_count, status_counter_wraps);
    if (route_write_count != 17)
      $fatal(1, "Expected 16 route selections plus one restore, got %0d",
             route_write_count);
    for (session = 0; session < 16; session = session + 1)
      if (route_log[session] != expected_channel(session + 1) - 1)
        $fatal(1, "Route log mismatch index=%0d", session);
    if (bg78_write_count != 5 || bg79_write_count != 5)
      $fatal(1, "Expected four BG rounds plus restore");
    if (bg78_log[0] != 8'h46 || bg79_log[0] != 8'h13 ||
        bg78_log[1] != 8'h61 || bg79_log[1] != 8'h34 ||
        bg78_log[2] != 8'h13 || bg79_log[2] != 8'h46 ||
        bg78_log[3] != 8'h34 || bg79_log[3] != 8'h61)
      $fatal(1, "Latin-square BGDCOL programming mismatch");
    if (bank0[8'h78] != 8'h88 || bank0[8'h79] != 8'h88 ||
        bank1[8'hc2] != 8'ha0 || selected_bank != 8'h00)
      $fatal(1, "Normal completion did not restore exact PRODUCT baseline");
    if (host_session_seen != 16'hffff)
      $fatal(1, "Host-owned history missing sessions mask=%h", host_session_seen);
    for (session = 0; session < 16; session = session + 1) begin
      if (host_snapshot_session[session] != session + 1)
        $fatal(1, "Host history session order mismatch index=%0d", session);
      if (host_snapshot_generation[session] != session + 1)
        $fatal(1, "Host history generation order mismatch index=%0d", session);
    end
    if (settle_boundary_checks != 16)
      $fatal(1, "Settle timing boundary coverage mismatch checks=%0d",
             settle_boundary_checks);
    if (sample_delay_boundary_checks == 0)
      $fatal(1, "Sample interval timing boundary was not exercised");
    if (status_timeout_boundary_checks != 4)
      $fatal(1, "Status timeout boundary coverage mismatch checks=%0d",
             status_timeout_boundary_checks);

    // Independently inject every mandatory error-safe restoration path.
    error_restore_passes = 0;

    reset_scenario(); prepare_diagnostic(); inject_nack_once = 1'b1;
    start_scan(); wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    reset_scenario(); prepare_diagnostic(); inject_timeout_once = 1'b1;
    start_scan(); wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    reset_scenario(); prepare_diagnostic(); inject_route_mismatch = 1'b1;
    start_scan(); wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    reset_scenario(); prepare_diagnostic(); start_scan(); wait_capture_ready(1);
    mmio_write(17'h03c34, {current_session_id, 12'b0, 4'b0010});
    wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    reset_scenario(); prepare_diagnostic(); start_scan(); wait_capture_ready(1);
    mmio_write(17'h03c34, {16'h7777, 12'b0, 4'b1001});
    wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    reset_scenario(); prepare_diagnostic(); start_scan(); wait_capture_ready(1);
    mmio_write(17'h03c0c, 32'h0000_0008);
    wait_error_and_restore(); error_restore_passes = error_restore_passes + 1;

    if (error_restore_passes != 6)
      $fatal(1, "Mandatory error-safe restore coverage incomplete");

    $display("PASS T1 AUTOINIT_DIAGNOSTIC_I2C_OWNERSHIP");
    $display("PASS T2 FIXED_REGISTER_WRITE_WHITELIST");
    $display("PASS T3 BANK_PAGE_SAVE_AND_RESTORE");
    $display("PASS T4 FOUR_CHANNEL_ROUTE_SWITCH_AND_READBACK");
    $display("PASS T5 BGDCOL_NIBBLE_PACKING");
    $display("PASS T6 ACTIVE_NOVID_UNSTABLE_CONTRADICTORY_STATUS");
    $display("PASS T7 FIVE_CONSECUTIVE_SAMPLE_STABILITY_RULE");
    $display("PASS T8 EXACT_4X4_ROTATED_ROUND_SEQUENCE");
    $display("PASS T9 SESSION_MATCH_CAPTURE_HANDSHAKE_AND_FAILURE_PATHS");
    $display("PASS T10 NO_ROUTE_CHANGE_DURING_ACTIVE_TRANSPORT");
    $display("PASS T11 NACK_TIMEOUT_CAPTURE_READBACK_ERROR_SAFE_RESTORE");
    $display("PASS T12 EXACT_PRODUCT_BASELINE_RESTORE");
    $display("PASS T13 DIAGNOSTIC_MMIO_MAP_AND_CURRENT_SNAPSHOT");
    $display("PASS T14 DIAGNOSTIC_IDLE_TRANSPORT_NONINTERFERENCE");
    $display("PASS T15 ALL_CHANNEL_FORCED_1080P25_CONFIGURATION_VERIFY");
    $display("PASS T16 FOUR_COLOR_LATIN_SQUARE_ROTATION");
    $display("PASS T17 CURRENT_SNAPSHOT_ATOMICITY_AND_IMMUTABILITY");
    $display("PASS T18 HOST_OWNED_16_SESSION_HISTORY");
    $display("PASS TIMING_BOUNDARIES ACCELERATED_SETTLE_2_SAMPLE_1_STATUS_200");
    $display("PASS INHERITED_NVP_VIDEO_DIAG1_SIMULATION_GATE 16/16");
    $display("PASS NVP_VIDEO_DIAG1_R1_RUNTIME_SIMULATION_GATE 18/18");
    $finish;
  end

  initial begin
    #2000000;
    $fatal(1, "Global simulation timeout");
  end
endmodule
