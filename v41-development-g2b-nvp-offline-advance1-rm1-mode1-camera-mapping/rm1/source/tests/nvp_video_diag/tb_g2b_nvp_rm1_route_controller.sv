`timescale 1ns/1ps

module tb_g2b_nvp_rm1_route_controller;
  logic clk = 1'b0;
  logic reset = 1'b1;
  logic start_pulse = 1'b0;
  logic restore_pulse = 1'b0;
  logic [2:0] target_channel = 3'd1;
  logic i2c_cmd_valid;
  logic i2c_cmd_ready;
  logic i2c_cmd_write;
  logic [7:0] i2c_cmd_reg;
  logic [7:0] i2c_cmd_wdata;
  logic i2c_cmd_accepted = 1'b0;
  logic i2c_done = 1'b0;
  logic i2c_success = 1'b0;
  logic i2c_timeout = 1'b0;
  logic [7:0] i2c_read_data = 8'b0;
  logic autoinit_done = 1'b1;
  logic autoinit_busy = 1'b0;
  logic autoinit_error = 1'b0;
  logic nvp_reset_released = 1'b1;
  logic diagnostic_i2c_owns_bus;
  logic route_busy;
  logic route_ready_pulse;
  logic route_error;
  logic route_error_pulse;
  logic [15:0] route_error_code;
  logic route_restored;
  logic [7:0] original_bank;
  logic [7:0] original_route;
  logic [7:0] route_readback;
  logic [31:0] i2c_transaction_count;

  logic monitor_route_start_pulse;
  logic monitor_route_restore_pulse;
  logic [2:0] monitor_route_target_channel;
  logic monitor_mmio_req_valid = 1'b0;
  logic monitor_mmio_req_ready;
  logic monitor_mmio_req_write = 1'b0;
  logic [16:0] monitor_mmio_req_addr = 17'b0;
  logic [31:0] monitor_mmio_req_wdata = 32'b0;
  logic [3:0] monitor_mmio_req_be = 4'b0;
  logic monitor_mmio_rsp_valid;
  logic [31:0] monitor_mmio_rsp_rdata;

  logic [7:0] physical_bank = 8'h07;
  logic [7:0] physical_route = 8'ha5;
  logic transaction_pending = 1'b0;
  logic pending_write = 1'b0;
  logic [7:0] pending_reg = 8'b0;
  logic [7:0] pending_data = 8'b0;
  logic inject_final_bank_mismatch = 1'b0;
  logic expect_final_bank_read = 1'b0;
  logic transport_quiescent = 1'b1;
  logic loss_inflight_active = 1'b0;
  logic saw_loss_restore_bank1 = 1'b0;
  logic loss_held_active = 1'b0;
  logic saw_held_loss_restore_bank1 = 1'b0;
  logic overlap_error = 1'b0;
  logic unsafe_command_error = 1'b0;
  logic monitor_abort_outstanding_observed = 1'b0;
  integer monitor_abort_request_count = 0;
  integer route_ready_count = 0;
  integer final_bank_readback_count = 0;
  integer physical_outstanding = 0;
  integer max_physical_outstanding = 0;
  integer errors = 0;

  always #5 clk = ~clk;
  assign i2c_cmd_ready = !transaction_pending;
  wire i2c_bus_idle = !transaction_pending;
  wire runtime_environment_ok = autoinit_done && !autoinit_busy &&
      !autoinit_error && nvp_reset_released;
  wire controller_start_pulse = start_pulse | monitor_route_start_pulse;
  wire controller_restore_pulse = restore_pulse | monitor_route_restore_pulse;

  g2b_nvp_rm1_route_controller #(
    .CYCLES_PER_MS(1), .SETTLE_TIME_MS(2)
  ) dut (
    .clk(clk), .reset(reset), .start_pulse(controller_start_pulse),
    .restore_pulse(controller_restore_pulse),
    .target_channel(monitor_route_start_pulse ?
                    monitor_route_target_channel : target_channel),
    .autoinit_done(autoinit_done), .autoinit_busy(autoinit_busy),
    .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
    .transport_quiescent(transport_quiescent),
    .i2c_cmd_valid(i2c_cmd_valid), .i2c_cmd_ready(i2c_cmd_ready),
    .i2c_cmd_write(i2c_cmd_write), .i2c_cmd_reg(i2c_cmd_reg),
    .i2c_cmd_wdata(i2c_cmd_wdata),
    .i2c_cmd_accepted(i2c_cmd_accepted), .i2c_done(i2c_done),
    .i2c_success(i2c_success), .i2c_timeout(i2c_timeout),
    .i2c_read_data(i2c_read_data), .i2c_bus_idle(i2c_bus_idle),
    .diagnostic_i2c_owns_bus(diagnostic_i2c_owns_bus),
    .route_busy(route_busy), .route_ready_pulse(route_ready_pulse),
    .route_error(route_error), .route_error_pulse(route_error_pulse),
    .route_error_code(route_error_code),
    .route_restored(route_restored), .original_bank(original_bank),
    .original_route(original_route), .route_readback(route_readback),
    .i2c_transaction_count(i2c_transaction_count)
  );

  // End-to-end coupling proof for a HELD quiescence failure: this is the
  // actual monitor wired to the actual route controller, not a TB-generated
  // route-error stand-in.
  g2b_nvp_raw_marker_monitor #(
    .AXI_CYCLES_PER_MS(2), .RESPONSE_TIMEOUT_MS(30),
    .COUNTER_WIDTH(4), .BUILD_FLAGS(32'h0000_0802)
  ) monitor (
    .source_clk(clk), .source_reset(reset),
    .sample_valid(1'b1), .sample_byte(8'h55),
    .prefix_state(2'b0), .candidate(1'b0),
    .raw_parity_valid(1'b0), .marker_f(1'b0), .marker_v(1'b0),
    .marker_h(1'b0), .parser_qualified(1'b0), .parser_state(3'b0),
    .axi_clk(clk), .axi_aresetn(!reset),
    .route_start_pulse(monitor_route_start_pulse),
    .route_restore_pulse(monitor_route_restore_pulse),
    .route_target_channel(monitor_route_target_channel),
    .route_ready_pulse(route_ready_pulse), .route_busy(route_busy),
    .route_error(route_error), .route_error_pulse(route_error_pulse),
    .route_error_code(route_error_code), .route_restored(route_restored),
    .route_original(original_route), .route_readback(route_readback),
    .mmio_req_valid(monitor_mmio_req_valid),
    .mmio_req_ready(monitor_mmio_req_ready),
    .mmio_req_write(monitor_mmio_req_write),
    .mmio_req_addr(monitor_mmio_req_addr),
    .mmio_req_wdata(monitor_mmio_req_wdata),
    .mmio_req_be(monitor_mmio_req_be),
    .mmio_rsp_valid(monitor_mmio_rsp_valid), .mmio_rsp_ready(1'b1),
    .mmio_rsp_rdata(monitor_mmio_rsp_rdata)
  );

  always_ff @(posedge clk) begin
    i2c_cmd_accepted <= 1'b0;
    i2c_done <= 1'b0;
    i2c_success <= 1'b0;
    i2c_timeout <= 1'b0;
    if (monitor.abort_outstanding_axi &&
        !monitor_abort_outstanding_observed)
      monitor_abort_request_count <= monitor_abort_request_count + 1;
    monitor_abort_outstanding_observed <= monitor.abort_outstanding_axi;
    if (route_ready_pulse)
      route_ready_count <= route_ready_count + 1;
    if (i2c_cmd_valid && transaction_pending) begin
      overlap_error <= 1'b1;
      $display("RM1_ROUTE_FAIL time=%0t overlapping I2C command", $time);
    end
    if (i2c_cmd_valid && !runtime_environment_ok) begin
      unsafe_command_error <= 1'b1;
      $display("RM1_ROUTE_FAIL time=%0t I2C command while runtime environment unsafe", $time);
    end
    if (i2c_cmd_valid && !transaction_pending) begin
      transaction_pending <= 1'b1;
      physical_outstanding <= physical_outstanding + 1;
      if (physical_outstanding + 1 > max_physical_outstanding)
        max_physical_outstanding <= physical_outstanding + 1;
      pending_write <= i2c_cmd_write;
      pending_reg <= i2c_cmd_reg;
      pending_data <= i2c_cmd_wdata;
      i2c_cmd_accepted <= 1'b1;
      if (loss_inflight_active && i2c_cmd_write &&
          i2c_cmd_reg == 8'hff && i2c_cmd_wdata == 8'h01)
        saw_loss_restore_bank1 <= 1'b1;
      if (loss_held_active && i2c_cmd_write &&
          i2c_cmd_reg == 8'hff && i2c_cmd_wdata == 8'h01)
        saw_held_loss_restore_bank1 <= 1'b1;
    end else if (transaction_pending) begin
      transaction_pending <= 1'b0;
      physical_outstanding <= physical_outstanding - 1;
      i2c_done <= 1'b1;
      i2c_success <= 1'b1;
      if (pending_write) begin
        if (pending_reg == 8'hff) begin
          physical_bank <= pending_data;
          if (pending_data == original_bank)
            expect_final_bank_read <= 1'b1;
        end else if (pending_reg == 8'hc2 && physical_bank == 8'h01)
          physical_route <= pending_data;
      end else if (pending_reg == 8'hff) begin
        if (expect_final_bank_read) begin
          final_bank_readback_count <= final_bank_readback_count + 1;
          expect_final_bank_read <= 1'b0;
          if (inject_final_bank_mismatch)
            i2c_read_data <= physical_bank ^ 8'h01;
          else
            i2c_read_data <= physical_bank;
        end else
          i2c_read_data <= physical_bank;
      end else if (pending_reg == 8'hc2 && physical_bank == 8'h01)
        i2c_read_data <= physical_route;
      else
        i2c_read_data <= 8'b0;
    end
  end

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("RM1_ROUTE_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic pulse_start(input logic [2:0] channel);
    begin
      @(negedge clk); target_channel = channel; start_pulse = 1'b1;
      @(negedge clk); start_pulse = 1'b0;
    end
  endtask

  task automatic pulse_restore;
    begin
      @(negedge clk); restore_pulse = 1'b1;
      @(negedge clk); restore_pulse = 1'b0;
    end
  endtask

  task automatic monitor_mmio_write(
      input logic [16:0] address_value,
      input logic [31:0] data_value);
    begin
      @(negedge clk);
      monitor_mmio_req_addr = address_value;
      monitor_mmio_req_wdata = data_value;
      monitor_mmio_req_be = 4'hf;
      monitor_mmio_req_write = 1'b1;
      monitor_mmio_req_valid = 1'b1;
      while (!monitor_mmio_req_ready) @(posedge clk);
      @(negedge clk);
      monitor_mmio_req_valid = 1'b0;
      monitor_mmio_req_write = 1'b0;
      monitor_mmio_req_addr = 17'b0;
      monitor_mmio_req_wdata = 32'b0;
      monitor_mmio_req_be = 4'b0;
    end
  endtask

  task automatic wait_ready;
    integer tries;
    begin
      for (tries = 0; tries < 300 && !route_ready_pulse; tries = tries + 1)
        @(posedge clk);
      if (!route_ready_pulse) fail("route-ready timeout");
    end
  endtask

  task automatic wait_restore_terminal;
    integer tries;
    begin
      for (tries = 0; tries < 300 && (route_busy || !route_restored);
           tries = tries + 1)
        @(posedge clk);
      if (route_busy || !route_restored)
        fail("exact restore timeout/failure");
    end
  endtask

  task automatic wait_terminal_fail_closed;
    integer tries;
    begin
      for (tries = 0; tries < 300 && route_busy; tries = tries + 1)
        @(posedge clk);
      if (route_busy || route_restored)
        fail("fail-closed terminal timeout or false restore");
    end
  endtask

  initial begin
    integer monitor_abort_count_before;
    integer transactions_before_unsafe;
    integer ready_count_before_loss;
    integer final_bank_reads_before;
    repeat (5) @(posedge clk);
    @(negedge clk); reset = 1'b0;

    // Normal bounded route, full-byte RMW/readback, and exact route+bank restore.
    pulse_start(3'd2);
    wait_ready();
    if (physical_route != 8'ha1 || physical_bank != 8'h00)
      fail($sformatf("bounded route mismatch bank=%02x route=%02x",
                     physical_bank, physical_route));
    pulse_restore();
    wait_restore_terminal();
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        i2c_transaction_count != 11)
      fail("normal route/restore transaction contract");

    // AXI reset after physical mutation retains baseline/dirty and forces
    // recovery instead of silently asserting route_restored.
    pulse_start(3'd4);
    wait_ready();
    if (physical_route != 8'ha3) fail("pre-reset route not applied");
    @(negedge clk); reset = 1'b1;
    repeat (3) @(posedge clk);
    if (route_restored) fail("reset silently declared restored");
    @(negedge clk); reset = 1'b0;
    wait_restore_terminal();
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0007)
      fail("reset recovery did not retain/restore exact baseline");

    // Loss of no-DMA quiescence while the physical C2 write is still in
    // flight must invalidate the session, ignore that command's later DONE
    // as a restore completion, and then restore exact route+entry bank.
    transport_quiescent = 1'b1;
    loss_inflight_active = 1'b1;
    pulse_start(3'd2);
    wait (transaction_pending && pending_write && pending_reg == 8'hc2 &&
          pending_data == 8'ha1);
    @(negedge clk); transport_quiescent = 1'b0;
    wait (route_error_pulse && route_error_code == 16'h0006);
    @(negedge clk); transport_quiescent = 1'b1;
    wait_restore_terminal();
    loss_inflight_active = 1'b0;
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0006 ||
        !saw_loss_restore_bank1 || max_physical_outstanding != 1 ||
        physical_outstanding != 0 || overlap_error)
      fail("in-flight quiescence loss did not restore without overlap");

    // A one-cycle loss during the route verification read must be latched;
    // returning quiescent before SETTLE is not allowed to hide it.
    transport_quiescent = 1'b1;
    pulse_start(3'd3);
    wait (transaction_pending && !pending_write && pending_reg == 8'hc2 &&
          physical_route == 8'ha2);
    @(negedge clk); transport_quiescent = 1'b0;
    @(negedge clk); transport_quiescent = 1'b1;
    wait_restore_terminal();
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0006 ||
        max_physical_outstanding != 1 || physical_outstanding != 0 ||
        overlap_error)
      fail("short VERIFY_ROUTE quiescence loss was not latched/restored");

    // Loss after route_ready, while the controller is in R_HELD, is still
    // inside the no-DMA ownership interval.  It must emit the same terminal
    // error and perform a new exact route+entry-bank restore without ever
    // overlapping the fixed I2C master's single outstanding transaction.
    transport_quiescent = 1'b1;
    loss_held_active = 1'b1;
    monitor_abort_count_before = monitor_abort_request_count;
    wait (!monitor.axi_recovery_pending && !monitor.abort_outstanding_axi);
    monitor_mmio_write(17'h03c18, 32'h0000_0004);
    monitor_mmio_write(17'h03c0c, 32'h0000_0002);
    wait_ready();
    wait (monitor.measurement_started_axi);
    if (physical_route != 8'ha3 || physical_bank != 8'h00)
      fail("HELD-loss precondition route not applied");
    @(negedge clk); transport_quiescent = 1'b0;
    wait (route_error_pulse && route_error_code == 16'h0006);
    @(negedge clk); transport_quiescent = 1'b1;
    wait_restore_terminal();
    wait (monitor.public_done_axi);
    loss_held_active = 1'b0;
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0006 ||
        !saw_held_loss_restore_bank1 || max_physical_outstanding != 1 ||
        physical_outstanding != 0 || overlap_error ||
        monitor_abort_request_count <= monitor_abort_count_before ||
        monitor.public_valid_axi ||
        !monitor.awaiting_ack_axi)
      fail("HELD quiescence loss did not restore without overlap");
    monitor_mmio_write(17'h03c0c, 32'h0000_0008);
    wait (!monitor.awaiting_ack_axi);

    // Runtime NVP/autoinit readiness is a live interlock, not merely a start
    // prerequisite.  Loss while the C2 write is in flight must revoke the
    // route, wait for the old fixed-master command to drain, issue no command
    // while unsafe, and then repeat a full exact route+bank restore.
    nvp_reset_released = 1'b1;
    autoinit_done = 1'b1;
    autoinit_busy = 1'b0;
    autoinit_error = 1'b0;
    pulse_start(3'd2);
    wait (transaction_pending && pending_write && pending_reg == 8'hc2 &&
          pending_data == 8'ha1);
    @(negedge clk); nvp_reset_released = 1'b0;
    wait (route_error_pulse && route_error_code == 16'h0008);
    transactions_before_unsafe = i2c_transaction_count;
    repeat (6) @(posedge clk);
    if (route_restored || !route_busy || diagnostic_i2c_owns_bus ||
        i2c_transaction_count != transactions_before_unsafe)
      fail("in-flight environment loss did not wait fail-closed");
    @(negedge clk); nvp_reset_released = 1'b1;
    wait_restore_terminal();
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0008 ||
        max_physical_outstanding != 1 || physical_outstanding != 0 ||
        overlap_error || unsafe_command_error)
      fail("in-flight environment loss lacked exact deferred restore");

    // A one-cycle readiness loss during SETTLE must be sticky.  It may not
    // produce route_ready after readiness returns; exact restore comes first.
    pulse_start(3'd3);
    wait (dut.state == 5'd7); // R_SETTLE
    ready_count_before_loss = route_ready_count;
    @(negedge clk); autoinit_done = 1'b0;
    @(negedge clk); autoinit_done = 1'b1;
    wait_restore_terminal();
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        !route_error || route_error_code != 16'h0008 ||
        route_ready_count != ready_count_before_loss ||
        overlap_error || unsafe_command_error)
      fail("SETTLE environment loss emitted ready or lacked exact restore");

    // The same live interlock applies after route_ready in HELD.  Couple the
    // real controller to the real monitor and prove the already-running
    // session becomes terminal-invalid, then restore the exact entry state.
    monitor_abort_count_before = monitor_abort_request_count;
    wait (!monitor.axi_recovery_pending && !monitor.abort_outstanding_axi);
    monitor_mmio_write(17'h03c18, 32'h0000_0002);
    monitor_mmio_write(17'h03c0c, 32'h0000_0002);
    wait_ready();
    wait (monitor.measurement_started_axi);
    ready_count_before_loss = route_ready_count;
    @(negedge clk); autoinit_busy = 1'b1;
    wait (route_error_pulse && route_error_code == 16'h0008);
    repeat (4) @(posedge clk);
    if (route_restored || diagnostic_i2c_owns_bus)
      fail("HELD environment loss did not revoke while unsafe");
    @(negedge clk); autoinit_busy = 1'b0;
    wait_restore_terminal();
    wait (monitor.public_done_axi);
    if (physical_route != 8'ha5 || physical_bank != 8'h07 ||
        monitor.public_valid_axi || !monitor.awaiting_ack_axi ||
        monitor_abort_request_count <= monitor_abort_count_before ||
        route_ready_count != ready_count_before_loss ||
        overlap_error || unsafe_command_error)
      fail("HELD environment loss retained VALID/ready or lacked restore");
    monitor_mmio_write(17'h03c0c, 32'h0000_0008);
    wait (!monitor.awaiting_ack_axi);

    // Historical reset error may be cleared only after proven restore.
    pulse_start(3'd3);
    wait_ready();
    inject_final_bank_mismatch = 1'b1;
    pulse_restore();
    repeat (100) @(posedge clk);
    if (!route_error || route_restored || route_error_code != 16'h0005)
      fail("final bank mismatch incorrectly passed restore");

    // Recover the intentionally failed bank-readback case so the final test
    // can exercise an environment loss before C2 baseline capture.
    inject_final_bank_mismatch = 1'b0;
    @(negedge clk); reset = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk); reset = 1'b0;
    wait_restore_terminal();

    // If readiness disappears while Bank1 selection is in flight, the entry
    // bank is known but original C2 is not.  Restore+read back the bank after
    // safety returns, but never assert route_restored for an unknown route.
    pulse_start(3'd2);
    wait (transaction_pending && pending_write && pending_reg == 8'hff &&
          pending_data == 8'h01);
    final_bank_reads_before = final_bank_readback_count;
    @(negedge clk); autoinit_error = 1'b1;
    wait (route_error_pulse && route_error_code == 16'h0008);
    transactions_before_unsafe = i2c_transaction_count;
    repeat (6) @(posedge clk);
    if (route_restored || !route_busy || diagnostic_i2c_owns_bus ||
        i2c_transaction_count != transactions_before_unsafe)
      fail("partial-baseline environment loss did not wait fail-closed");
    @(negedge clk); autoinit_error = 1'b0;
    wait_terminal_fail_closed();
    if (physical_bank != 8'h07 || route_restored || !route_error ||
        route_error_code != 16'h0008 || max_physical_outstanding != 1 ||
        physical_outstanding != 0 || overlap_error || unsafe_command_error)
      fail("partial baseline did not restore bank then remain fail-closed");
    if (final_bank_readback_count != final_bank_reads_before + 1)
      fail("partial baseline lacked one exact final-bank readback");

    if (errors != 0) begin
      $display("RM1_ROUTE_INTEGRATION_FAIL errors=%0d", errors);
      $fatal(1);
    end
    $display("RM1_ROUTE_INTEGRATION_PASS exact_rmw_reset_quiescence_runtime_env_and_bank_verify");
    $finish;
  end
endmodule
