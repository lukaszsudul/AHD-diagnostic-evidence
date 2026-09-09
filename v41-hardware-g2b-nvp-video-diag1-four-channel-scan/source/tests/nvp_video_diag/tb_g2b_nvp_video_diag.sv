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
  integer route_write_count;
  integer bg78_write_count;
  integer bg79_write_count;
  logic [3:0] route_log [0:31];
  logic [7:0] bg78_log [0:15];
  logic [7:0] bg79_log [0:15];
  logic unstable_flip;

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
    end
  endtask

  task automatic emulate_capture_and_pass;
    logic [2:0] held_channel;
    integer guard;
    begin
      held_channel = current_channel;
      transport_stream_enabled = 1'b1;
      transport_c2h_active = 1'b1;
      transport_ring_empty = 1'b0;
      repeat (8) begin
        @(posedge clk);
        if (current_channel != held_channel)
          $fatal(1, "Route/channel changed during active transport");
        if (i2c_cmd_valid)
          $fatal(1, "I2C command emitted during active transport");
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
    end
  endtask

  logic [31:0] read_value;
  integer session;
  integer active_seen;
  integer no_video_seen;
  integer contradictory_seen;
  integer unstable_seen;
  integer error_restore_passes;
  initial begin
    initialize_register_model();
    repeat (5) @(posedge clk);
    reset_scenario();

    mmio_read(17'h03c00, read_value);
    if (read_value != 32'h4e56_5034) $fatal(1, "DIAG_MAGIC mismatch");
    mmio_read(17'h03c04, read_value);
    if (read_value != 32'h0001_0000) $fatal(1, "DIAG_VERSION mismatch");

    prepare_diagnostic();
    if (bank0[8'h80] != 8'h0f || bank0[8'h81] != 8'h03 ||
        bank0[8'h84] != 8'h03)
      $fatal(1, "All-channel configuration verify altered baseline");
    start_scan();

    active_seen = 0;
    no_video_seen = 0;
    contradictory_seen = 0;
    unstable_seen = 0;
    for (session = 1; session <= 16; session = session + 1) begin
      wait_capture_ready(session);
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
    if (illegal_write_count != 0 || route_while_active_count != 0)
      $fatal(1, "Whitelist/transport-freeze failure illegal=%0d active=%0d",
             illegal_write_count, route_while_active_count);
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

    if (error_restore_passes != 5)
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
    $display("PASS T13 DIAGNOSTIC_MMIO_MAP_AND_RESULT_TABLE");
    $display("PASS T14 DIAGNOSTIC_IDLE_TRANSPORT_NONINTERFERENCE");
    $display("PASS T15 ALL_CHANNEL_FORCED_1080P25_CONFIGURATION_VERIFY");
    $display("PASS T16 FOUR_COLOR_LATIN_SQUARE_ROTATION");
    $display("PASS NVP_VIDEO_DIAG1_SIMULATION_GATE 16/16");
    $finish;
  end

  initial begin
    #2000000;
    $fatal(1, "Global simulation timeout");
  end
endmodule
