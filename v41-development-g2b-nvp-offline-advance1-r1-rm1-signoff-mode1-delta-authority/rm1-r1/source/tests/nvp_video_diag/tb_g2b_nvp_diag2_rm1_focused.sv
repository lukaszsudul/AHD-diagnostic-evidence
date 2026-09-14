`timescale 1ns/1ps

module tb_g2b_nvp_diag2_rm1_focused;
  logic source_clk_raw = 1'b0;
  logic source_clock_enable = 1'b1;
  wire source_clk = source_clk_raw & source_clock_enable;
  logic source_reset = 1'b1;
  logic sample_valid = 1'b0;
  logic [7:0] sample_byte = 8'b0;
  logic [1:0] prefix_state = 2'b0;
  logic candidate = 1'b0;
  logic raw_parity_valid = 1'b0;
  logic marker_f = 1'b0;
  logic marker_v = 1'b0;
  logic marker_h = 1'b0;
  logic parser_qualified = 1'b0;
  logic [2:0] parser_state = 3'b0;

  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;
  logic route_start_pulse;
  logic route_restore_pulse;
  logic [2:0] route_target_channel;
  logic route_ready_pulse = 1'b0;
  logic route_busy = 1'b0;
  logic route_error = 1'b0;
  logic route_error_pulse = 1'b0;
  logic [15:0] route_error_code = 16'b0;
  logic route_restored = 1'b1;
  logic [7:0] route_original = 8'ha0;
  logic [7:0] route_readback = 8'ha0;
  logic [2:0] route_delay = 3'b0;
  logic route_restore_test_override = 1'b0;

  logic mmio_req_valid = 1'b0;
  logic mmio_req_ready;
  logic mmio_req_write = 1'b0;
  logic [16:0] mmio_req_addr = 17'b0;
  logic [31:0] mmio_req_wdata = 32'b0;
  logic [3:0] mmio_req_be = 4'b0;
  logic mmio_rsp_valid;
  logic mmio_rsp_ready = 1'b1;
  logic [31:0] mmio_rsp_rdata;
  integer errors = 0;
  integer ack_done_change_count = 0;
  logic ack_done_observed = 1'b0;
  logic abort_drain_tracking = 1'b0;
  logic abort_ack_at_drain_entry = 1'b0;
  integer abort_drain_sample_count = 0;
  integer abort_quarantine_checks = 0;
  logic source_reset_drain_tracking = 1'b0;
  logic done_at_source_reset_drain_entry = 1'b0;
  integer source_reset_drain_sample_count = 0;
  integer source_reset_quarantine_checks = 0;

  always #3 source_clk_raw = ~source_clk_raw;
  always #5 axi_clk = ~axi_clk;

  always @(posedge source_clk) begin
    if (dut.ack_done_toggle_source != ack_done_observed) begin
      ack_done_change_count = ack_done_change_count + 1;
      ack_done_observed = dut.ack_done_toggle_source;
    end
  end

  // Sample after each source-domain active edge.  Every abort echo must stay
  // unchanged for the first three complete quarantine edges and may change
  // only as the state exits on edge four or later.
  always @(negedge source_clk) begin
    if (!abort_drain_tracking && dut.monitor_state_source == 3'd6) begin
      abort_drain_tracking = 1'b1;
      abort_ack_at_drain_entry = dut.abort_ack_toggle_source;
      abort_drain_sample_count = 0;
    end else if (abort_drain_tracking &&
                 dut.monitor_state_source == 3'd6) begin
      abort_drain_sample_count = abort_drain_sample_count + 1;
      if (dut.abort_ack_toggle_source != abort_ack_at_drain_entry)
        fail("abort echo changed inside quarantine");
    end else if (abort_drain_tracking) begin
      abort_drain_sample_count = abort_drain_sample_count + 1;
      if (abort_drain_sample_count < 4 ||
          dut.abort_ack_toggle_source == abort_ack_at_drain_entry)
        fail("abort echo did not wait four complete quarantine edges");
      abort_quarantine_checks = abort_quarantine_checks + 1;
      abort_drain_tracking = 1'b0;
    end
  end

  // A source reset restarts this observer while asserted.  Once deasserted,
  // DONE must remain unchanged for four complete drain edges and the state
  // may leave SM_SOURCE_RESET_DRAIN only on/after the fourth edge.
  always @(posedge source_clk) begin
    if (source_reset) begin
      source_reset_drain_tracking = 1'b0;
      source_reset_drain_sample_count = 0;
    end else if (dut.monitor_state_source == 3'd7) begin
      if (!source_reset_drain_tracking) begin
        source_reset_drain_tracking = 1'b1;
        done_at_source_reset_drain_entry = dut.done_toggle_source;
        source_reset_drain_sample_count = 0;
      end
      source_reset_drain_sample_count = source_reset_drain_sample_count + 1;
      if (dut.done_toggle_source != done_at_source_reset_drain_entry)
        fail("source-reset DONE changed inside command quarantine");
    end else if (source_reset_drain_tracking) begin
      source_reset_drain_sample_count = source_reset_drain_sample_count + 1;
      if (source_reset_drain_sample_count < 4 ||
          dut.done_toggle_source != done_at_source_reset_drain_entry)
        fail("source-reset quarantine exited before four stable DONE edges");
      source_reset_quarantine_checks = source_reset_quarantine_checks + 1;
      source_reset_drain_tracking = 1'b0;
    end
  end

  g2b_nvp_raw_marker_monitor #(
    .AXI_CYCLES_PER_MS(2), .RESPONSE_TIMEOUT_MS(30),
    .COUNTER_WIDTH(4), .BUILD_FLAGS(32'h0000_0802)
  ) dut (
    .source_clk(source_clk), .source_reset(source_reset),
    .sample_valid(sample_valid), .sample_byte(sample_byte),
    .prefix_state(prefix_state), .candidate(candidate),
    .raw_parity_valid(raw_parity_valid),
    .marker_f(marker_f), .marker_v(marker_v), .marker_h(marker_h),
    .parser_qualified(parser_qualified), .parser_state(parser_state),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .route_start_pulse(route_start_pulse),
    .route_restore_pulse(route_restore_pulse),
    .route_target_channel(route_target_channel),
    .route_ready_pulse(route_ready_pulse), .route_busy(route_busy),
    .route_error(route_error), .route_error_pulse(route_error_pulse),
    .route_error_code(route_error_code),
    .route_restored(route_restored), .route_original(route_original),
    .route_readback(route_readback),
    .mmio_req_valid(mmio_req_valid), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(mmio_req_write), .mmio_req_addr(mmio_req_addr),
    .mmio_req_wdata(mmio_req_wdata), .mmio_req_be(mmio_req_be),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(mmio_rsp_ready),
    .mmio_rsp_rdata(mmio_rsp_rdata)
  );

  // Deterministic stand-in for the independently tested bounded route FSM.
  always_ff @(posedge axi_clk) begin
    route_ready_pulse <= 1'b0;
    if (!axi_aresetn) begin
      route_busy <= 1'b0;
      route_restored <= 1'b1;
      route_delay <= 3'b0;
      route_readback <= route_original;
    end else begin
      if (route_start_pulse) begin
        route_busy <= 1'b1;
        route_restored <= 1'b0;
        route_delay <= 3'd3;
        route_readback <= {route_original[7:4], 1'b0,
                           route_target_channel - 3'd1};
      end else if (route_delay != 0) begin
        route_delay <= route_delay - 1'b1;
        if (route_delay == 1) begin
          route_busy <= 1'b0;
          route_ready_pulse <= 1'b1;
        end
      end
      if (route_restore_pulse || route_restore_test_override) begin
        route_busy <= 1'b0;
        route_restored <= 1'b1;
        route_readback <= route_original;
      end
    end
  end

  function automatic [7:0] legal_xy(
      input logic f, input logic v, input logic h);
    begin
      legal_xy = {1'b1, f, v, h, v ^ h, f ^ h, f ^ v, f ^ v ^ h};
    end
  endfunction

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("RM1_FOCUSED_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic mmio_write(input logic [16:0] address,
                            input logic [31:0] value);
    begin
      @(negedge axi_clk);
      mmio_req_addr = address;
      mmio_req_wdata = value;
      mmio_req_be = 4'hf;
      mmio_req_write = 1'b1;
      mmio_req_valid = 1'b1;
      do @(posedge axi_clk); while (!mmio_req_ready);
      @(negedge axi_clk);
      mmio_req_valid = 1'b0;
      mmio_req_write = 1'b0;
      mmio_req_addr = 17'b0;
      mmio_req_wdata = 32'b0;
      mmio_req_be = 4'b0;
    end
  endtask

  task automatic mmio_read(input logic [16:0] address,
                           output logic [31:0] value);
    begin
      @(negedge axi_clk);
      mmio_req_addr = address;
      mmio_req_write = 1'b0;
      mmio_req_valid = 1'b1;
      do @(posedge axi_clk); while (!mmio_req_ready);
      @(negedge axi_clk);
      mmio_req_valid = 1'b0;
      mmio_req_addr = 17'b0;
      do @(posedge axi_clk); while (!mmio_rsp_valid);
      value = mmio_rsp_rdata;
      @(negedge axi_clk);
    end
  endtask

  task automatic wait_status(input integer bit_index, input logic wanted);
    logic [31:0] status;
    integer tries;
    begin
      status = 32'b0;
      status[bit_index] = ~wanted;
      for (tries = 0; tries < 5000 && status[bit_index] != wanted;
           tries = tries + 1)
        mmio_read(17'h03c10, status);
      if (status[bit_index] != wanted)
        fail($sformatf("status[%0d] timeout wanted=%0d status=%08x",
                       bit_index, wanted, status));
    end
  endtask

  task automatic read_meta(input integer index, output logic [31:0] value);
    begin
      mmio_write(17'h03c3c, index);
      mmio_read(17'h03c40, value);
    end
  endtask

  task automatic drive_observation(
      input logic [7:0] value,
      input logic [1:0] prefix,
      input logic is_candidate,
      input logic parity_ok,
      input logic f,
      input logic v,
      input logic h,
      input logic qualified);
    begin
      @(negedge source_clk);
      sample_byte = value;
      prefix_state = prefix;
      candidate = is_candidate;
      raw_parity_valid = parity_ok;
      marker_f = f;
      marker_v = v;
      marker_h = h;
      parser_qualified = qualified;
      sample_valid = 1'b1;
      @(negedge source_clk);
      sample_valid = 1'b0;
      prefix_state = 2'b0;
      candidate = 1'b0;
      raw_parity_valid = 1'b0;
      parser_qualified = 1'b0;
    end
  endtask

  task automatic emit_marker(
      input logic f, input logic v, input logic h,
      input logic corrupt_parity);
    logic [7:0] xy;
    logic qualified;
    begin
      xy = legal_xy(f, v, h);
      if (corrupt_parity)
        xy[0] = ~xy[0];
      qualified = xy[7] && xy[3:0] == 4'b0000;
      drive_observation(8'hff, 2'd0, 1'b0, 1'b0,
                        1'b0, 1'b0, 1'b0, 1'b0);
      drive_observation(8'h00, 2'd1, 1'b0, 1'b0,
                        1'b0, 1'b0, 1'b0, 1'b0);
      drive_observation(8'h00, 2'd2, 1'b0, 1'b0,
                        1'b0, 1'b0, 1'b0, 1'b0);
      drive_observation(xy, 2'd3, 1'b1, !corrupt_parity,
                        f, v, h, qualified);
    end
  endtask

  task automatic start_session(input logic [2:0] route,
                               input logic [1:0] window_sel);
    begin
      mmio_write(17'h03c0c, 32'h0000_0001);
      repeat (8) @(posedge source_clk);
      mmio_write(17'h03c18, {22'b0, window_sel, 5'b0, route});
      mmio_write(17'h03c0c, 32'h0000_0002);
      wait_status(1, 1'b1);
    end
  endtask

  task automatic freeze_session;
    begin
      mmio_write(17'h03c0c, 32'h0000_0004);
      wait_status(4, 1'b1);
    end
  endtask

  task automatic ack_session;
    begin
      mmio_write(17'h03c0c, 32'h0000_0008);
      repeat (12) @(posedge source_clk);
      repeat (8) @(posedge axi_clk);
    end
  endtask

  initial begin : RUN
    logic [31:0] value;
    logic [31:0] value2;
    logic [31:0] identity;
    logic [4:0] command_toggles_before_reset;
    logic arm_seen_before_skew;
    logic manual_seen_before_skew;
    logic auto_seen_before_reset;
    logic auto_toggle_after_invalid;
    logic manual_toggle_before_reset;
    logic abort_ack_before_drain;
    logic [31:0] protocol_after;
    integer i;
    integer f;
    integer v;
    integer h;
    integer drain_edges;
    integer ack_count_before;
    integer ack_count_after;
    integer quarantine_checks_before;
    integer source_reset_checks_before;
    integer automatic_window_cycles;

    repeat (8) @(posedge axi_clk);
    repeat (8) @(posedge source_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    @(negedge source_clk); source_reset = 1'b0;
    repeat (8) @(posedge axi_clk);

    // T1 constant stream.
    start_session(3'd1, 2'd0);
    for (i = 0; i < 8; i = i + 1)
      drive_observation(8'h55, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    read_meta(3, value);
    read_meta(8, value2);
    if (value != 0 || value2 != 0) fail("T1 constant stream counters");
    else $display("RM1_T1_PASS constant_byte_stream");
    ack_session();

    // T2 arbitrary changes without prefix.
    start_session(3'd1, 2'd0);
    for (i = 0; i < 8; i = i + 1)
      drive_observation(i[7:0] + 8'h20, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    read_meta(3, value);
    read_meta(8, value2);
    if (value == 0 || value2 != 0) fail("T2 changing no-prefix counters");
    else $display("RM1_T2_PASS changing_without_prefix");
    ack_session();

    // T3 full-parity legal F0/V0 SAV, also accepted by the current parser.
    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 0);
    freeze_session();
    read_meta(8, value); if (value != 1) fail("T3 candidate");
    read_meta(9, value); if (value != 1) fail("T3 parity pass");
    read_meta(11, value); if (value != 1) fail("T3 SAV");
    if (errors == 0) $display("RM1_T3_PASS legal_sav");
    ack_session();

    // T4 full-parity legal EAV.
    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 1, 0);
    freeze_session();
    read_meta(8, value); if (value != 1) fail("T4 candidate");
    read_meta(9, value); if (value != 1) fail("T4 parity pass");
    read_meta(12, value); if (value != 1) fail("T4 EAV");
    if (errors == 0) $display("RM1_T4_PASS legal_eav");
    ack_session();

    // T5 bad protection bit.
    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 1);
    freeze_session();
    read_meta(8, value); if (value != 1) fail("T5 candidate");
    read_meta(10, value); if (value != 1) fail("T5 parity fail");
    read_meta(11, value); if (value != 0) fail("T5 illegal SAV counted");
    if (errors == 0) $display("RM1_T5_PASS bad_xy_parity");
    ack_session();

    // T6 all eight F/V/H legal protection-bit combinations.
    start_session(3'd1, 2'd0);
    for (f = 0; f < 2; f = f + 1)
      for (v = 0; v < 2; v = v + 1)
        for (h = 0; h < 2; h = h + 1)
          emit_marker(f[0], v[0], h[0], 0);
    freeze_session();
    read_meta(11, value); if (value != 4) fail("T6 SAV total");
    read_meta(12, value); if (value != 4) fail("T6 EAV total");
    for (i = 13; i <= 20; i = i + 1) begin
      read_meta(i, value);
      if (value != 1) fail($sformatf("T6 classification index=%0d", i));
    end
    if (errors == 0) $display("RM1_T6_PASS mixed_fvh_combinations");
    ack_session();

    // T7 legal raw F0/V1 SAV is rejected by literal low-nibble-zero parser.
    start_session(3'd2, 2'd0);
    emit_marker(0, 1, 0, 0);
    freeze_session();
    read_meta(11, value); if (value != 1) fail("T7 raw SAV");
    read_meta(21, value); if (value != 0) fail("T7 qualified SAV");
    read_meta(23, value); if (value != 1) fail("T7 reject");
    if (errors == 0) $display("RM1_T7_PASS raw_legal_parser_reject");
    ack_session();

    // T8 source clock stops: AXI publishes deterministic invalid timeout.
    start_session(3'd2, 2'd0);
    source_clock_enable = 1'b0;
    repeat (400) @(posedge axi_clk);
    mmio_read(17'h03c10, value);
    if (!value[4] || value[5] || !value[7])
      fail($sformatf("T8 stopped-clock status=%08x", value));
    mmio_read(17'h03c40, value2);
    if (value2 != 0)
      fail("T8 invalid incomplete session exposed snapshot RAM");
    source_clock_enable = 1'b1;
    repeat (100) @(posedge source_clk);
    ack_session();
    start_session(3'd3, 2'd0);
    drive_observation(8'h66, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    mmio_read(17'h03c10, value);
    if (!value[5]) fail("T8 recovery session did not publish valid");
    ack_session();

    // Route/quiescence abort plus ACK may arrive while source_clk is stopped.
    // Abort must not consume the ACK without its source completion echo.
    start_session(3'd2, 2'd0);
    source_clock_enable = 1'b0;
    @(negedge axi_clk);
    route_error = 1'b1;
    route_error_code = 16'h0006;
    route_error_pulse = 1'b1;
    @(negedge axi_clk);
    route_error_pulse = 1'b0;
    wait_status(4, 1'b1);
    ack_count_before = ack_done_change_count;
    mmio_write(17'h03c0c, 32'h0000_0008);
    repeat (20) @(posedge axi_clk);
    mmio_read(17'h03c10, value);
    if (!value[6] || !value[11])
      fail("T8 stopped-source abort ACK ownership released without echo");
    source_clock_enable = 1'b1;
    wait_status(6, 1'b0);
    repeat (2) @(posedge source_clk);
    if (ack_done_change_count != ack_count_before + 1)
      fail("T8 abort quarantine did not return exactly one ACK completion");
    ack_count_after = ack_done_change_count;
    repeat (6) @(posedge source_clk);
    if (ack_done_change_count != ack_count_after)
      fail("T8 abort quarantine emitted a duplicate ACK completion");
    route_error = 1'b0;
    route_error_code = 16'b0;
    start_session(3'd3, 2'd0);
    drive_observation(8'h67, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    mmio_read(17'h03c10, value);
    if (!value[5]) fail("T8 post-abort session did not recover");
    else $display("RM1_T8_PASS stopped_clock_timeout_abort_ack_then_recovered");
    ack_session();

    // T9 coherent CLEAR/ARM/DONE/READ/ACK lifecycle.
    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 0);
    freeze_session();
    mmio_read(17'h03c10, value);
    read_meta(0, value2);
    read_meta(31, identity);
    if (!value[4] || !value[5] || value2 != 32'h524d_314d)
      fail("T9 coherent DONE metadata");
    if (identity != 32'd2)
      fail("T9 encoded manual FREEZE did not publish STOP_MANUAL");
    ack_session();
    mmio_read(17'h03c10, value);
    if (value[6]) fail("T9 ACK did not release session");
    else $display("RM1_T9_PASS clear_arm_done_read_ack");

    // T10 ARM remains blocked until ACK.
    start_session(3'd1, 2'd0);
    mmio_write(17'h03c0c, 32'h0000_0002);
    mmio_read(17'h03c2c, value);
    if (value == 0) fail("T10 second ARM not rejected");
    freeze_session();
    mmio_read(17'h03c48, value2);
    mmio_write(17'h03c0c, 32'h0000_0008);
    mmio_read(17'h03c10, identity);
    if (identity[4] || identity[5])
      fail("T10 first ACK did not close frozen read window");
    mmio_write(17'h03c0c, 32'h0000_0008);
    repeat (12) @(posedge source_clk);
    repeat (8) @(posedge axi_clk);
    mmio_read(17'h03c48, identity);
    mmio_read(17'h03c10, value);
    if (identity != value2 + 1 || value[6])
      fail("T10 repeated ACK was accepted or session stayed owned");
    mmio_read(17'h03c18, value2);
    mmio_read(17'h03c48, identity);
    force route_restored = 1'b0;
    mmio_write(17'h03c18, 32'h0000_0004);
    mmio_read(17'h03c18, value);
    mmio_read(17'h03c48, protocol_after);
    release route_restored;
    @(negedge axi_clk); route_restore_test_override = 1'b1;
    @(negedge axi_clk); route_restore_test_override = 1'b0;
    if (value != value2 || protocol_after != identity + 1'b1)
      fail("T10 CONFIG accepted while exact route restore was unproven");
    else $display("RM1_T10_PASS second_arm_and_repeated_ack_rejected");

    // T11 64-entry event ring wraps and then freezes coherently.
    start_session(3'd1, 2'd0);
    for (i = 0; i < 70; i = i + 1)
      drive_observation(8'hff, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    read_meta(30, value);
    mmio_write(17'h03c30, 5);
    mmio_read(17'h03c34, value2);
    mmio_read(17'h03c34, identity);
    if (value[6:0] != 7'd64 || !value[16] || value2 != identity)
      fail("T11 wrap/frozen trace metadata");
    else $display("RM1_T11_PASS trace_wrap_freeze");
    ack_session();

    // T12 monitor observes TB-owned source signals and has no return port.
    start_session(3'd1, 2'd0);
    sample_byte = 8'h3c;
    drive_observation(8'h3c, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    if (sample_byte !== 8'h3c || route_target_channel !== 3'd1)
      fail("T12 observation changed functional stimulus");
    else $display("RM1_T12_PASS fanout_only_noninterference");
    freeze_session();
    ack_session();

    // T13 reset before DONE in every active publication phase remains invalid.
    start_session(3'd1, 2'd0);
    drive_observation(8'h44, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5]) fail("T13 reset snapshot published valid");
    ack_session();

    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 0);
    mmio_write(17'h03c0c, 32'h0000_0004);
    wait (dut.monitor_state_source == 3'd2); // SM_META_WRITE
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5]) fail("T13 META_WRITE reset published valid");
    ack_session();

    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 0);
    mmio_write(17'h03c0c, 32'h0000_0004);
    wait (dut.monitor_state_source == 3'd3); // SM_META_WAIT
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5]) fail("T13 META_WAIT reset published valid");
    ack_session();

    start_session(3'd1, 2'd0);
    emit_marker(0, 0, 0, 0);
    mmio_write(17'h03c0c, 32'h0000_0004);
    wait (dut.monitor_state_source == 3'd4); // SM_DONE_PUBLISH
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5]) fail("T13 DONE_PUBLISH reset published valid");
    ack_session();

    // Hold a genuine MANUAL command behind its source synchronizer until
    // after source_reset deasserts.  The reset quarantine must absorb it,
    // publish only an invalid record, and drain again before ACK completion.
    start_session(3'd1, 2'd2);
    drive_observation(8'h45, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    manual_seen_before_skew = dut.freeze_manual_seen_source;
    force dut.freeze_manual_sync1_source = manual_seen_before_skew;
    force dut.freeze_manual_sync2_source = manual_seen_before_skew;
    mmio_write(17'h03c0c, 32'h0000_0004);
    manual_toggle_before_reset = dut.freeze_manual_toggle_axi;
    if (manual_toggle_before_reset == manual_seen_before_skew)
      fail("T13 late-MANUAL setup did not launch a source token");
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait (dut.monitor_state_source == 3'd7);
    source_reset_checks_before = source_reset_quarantine_checks;
    @(posedge source_clk);
    release dut.freeze_manual_sync1_source;
    release dut.freeze_manual_sync2_source;
    wait (dut.monitor_state_source == 3'd5); // invalid SM_FROZEN
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5] || dut.freeze_manual_seen_source !=
                    dut.freeze_manual_toggle_axi ||
        source_reset_quarantine_checks <= source_reset_checks_before)
      fail("T13 delayed MANUAL escaped source-reset quarantine");
    ack_session();
    if (dut.monitor_state_source != 3'd0 ||
        dut.freeze_manual_seen_source != dut.freeze_manual_toggle_axi)
      fail("T13 invalid source-reset ACK left MANUAL pending");

    // Exercise the independently synchronized AUTO token as well, this time
    // after the initial reset drain has already exited.  Force the AXI window
    // to expire during invalid metadata publication, hold the token behind
    // its source synchronizer, and prove META/DONE/FROZEN plus the ACK drain
    // absorb it.  Invalid DONE must also cancel any later AXI timer activity.
    start_session(3'd1, 2'd0);
    drive_observation(8'h46, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    auto_seen_before_reset = dut.freeze_seen_source;
    force dut.freeze_sync1_source = auto_seen_before_reset;
    force dut.freeze_sync2_source = auto_seen_before_reset;
    @(negedge source_clk); source_reset = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait (dut.monitor_state_source == 3'd7);
    source_reset_checks_before = source_reset_quarantine_checks;
    wait (dut.monitor_state_source == 3'd2); // invalid SM_META_WRITE
    force dut.measurement_counter_axi = 32'd199;
    for (i = 0; i < 10 &&
         dut.freeze_toggle_axi == auto_seen_before_reset; i = i + 1)
      @(posedge axi_clk);
    release dut.measurement_counter_axi;
    if (dut.freeze_toggle_axi == auto_seen_before_reset)
      fail("T13 AUTO did not launch during invalid metadata publication");
    repeat (2) @(posedge source_clk);
    release dut.freeze_sync1_source;
    release dut.freeze_sync2_source;
    wait (dut.monitor_state_source == 3'd5); // invalid SM_FROZEN
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    auto_toggle_after_invalid = dut.freeze_toggle_axi;
    repeat (240) @(posedge axi_clk);
    if (value[5] || dut.measurement_started_axi || dut.freeze_issued_axi ||
        dut.freeze_toggle_axi != auto_toggle_after_invalid ||
        dut.freeze_seen_source != dut.freeze_toggle_axi ||
        source_reset_quarantine_checks <= source_reset_checks_before)
      fail("T13 delayed AUTO or post-invalid timer escaped quarantine");
    ack_session();

    // ARM may be accepted by AXI and launched by route_ready while the source
    // FSM is still IDLE and its clock is stopped.  A coincident source reset
    // must recognize the ARM absorbed by its drain as a discarded owned
    // session, publish invalid DONE, and re-drain on ACK.
    @(negedge source_clk); source_clock_enable = 1'b0;
    mmio_write(17'h03c0c, 32'h0000_0001);
    mmio_write(17'h03c18, 32'h0000_0001);
    mmio_write(17'h03c0c, 32'h0000_0002);
    wait (dut.measurement_started_axi);
    arm_seen_before_skew = dut.arm_seen_source;
    if (dut.arm_toggle_axi == arm_seen_before_skew ||
        dut.monitor_state_source != 3'd0)
      fail("T13 ARM/IDLE collision setup was not in flight");
    @(negedge source_clk_raw);
    source_reset = 1'b1;
    source_clock_enable = 1'b1;
    repeat (2) @(posedge source_clk);
    @(negedge source_clk); source_reset = 1'b0;
    wait (dut.monitor_state_source == 3'd5); // discarded-session invalid
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (value[5] || dut.arm_seen_source != dut.arm_toggle_axi ||
        !dut.source_reset_ack_requires_drain_source)
      fail("T13 ARM/IDLE reset collision was not terminal-invalid");
    ack_session();
    if (dut.source_reset_ack_requires_drain_source ||
        dut.monitor_state_source != 3'd0)
      fail("T13 ARM/IDLE invalid ACK did not finish its drain");

    // The following session must consume a complete new automatic window;
    // neither delayed AUTO nor MANUAL may freeze it immediately after ARM.
    start_session(3'd2, 2'd0);
    automatic_window_cycles = 0;
    while (!dut.freeze_issued_axi && automatic_window_cycles < 400) begin
      @(posedge axi_clk);
      automatic_window_cycles = automatic_window_cycles + 1;
    end
    if (!dut.freeze_issued_axi || automatic_window_cycles < 150)
      fail($sformatf("T13 next session did not run a full window cycles=%0d",
                     automatic_window_cycles));
    wait_status(4, 1'b1);
    mmio_read(17'h03c10, value);
    if (!value[5])
      fail("T13 full-window session after reset was not valid");
    ack_session();

    // A persistent abort request survives two AXI resets while source_clk is
    // stopped.  The two reset releases cannot cancel the toggle before the
    // source observes and echoes it.
    start_session(3'd1, 2'd0);
    drive_observation(8'h5a, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    source_clock_enable = 1'b0;
    command_toggles_before_reset = {
      dut.clear_toggle_axi, dut.arm_toggle_axi, dut.freeze_toggle_axi,
      dut.freeze_manual_toggle_axi, dut.ack_toggle_axi
    };
    @(negedge axi_clk); axi_aresetn = 1'b0;
    repeat (4) @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (4) @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b0;
    repeat (4) @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (8) @(posedge axi_clk);
    if ({dut.clear_toggle_axi, dut.arm_toggle_axi, dut.freeze_toggle_axi,
         dut.freeze_manual_toggle_axi, dut.ack_toggle_axi} !==
        command_toggles_before_reset)
      fail("T13 AXI reset manufactured a source command toggle");
    mmio_read(17'h03c10, value);
    if (value[5] || !value[12])
      fail("T13 stopped-source double reset lost persistent abort ownership");
    source_clock_enable = 1'b1;
    repeat (16) @(posedge source_clk);
    repeat (8) @(posedge axi_clk);
    mmio_read(17'h03c10, value);
    if (value[5] || value[12] || dut.monitor_state_source != 3'd0)
      fail("T13 AXI reset did not fail closed to source IDLE");

    // Delayed-echo boundary: source services abort A immediately before a
    // one-cycle reset B, but A's echo reaches AXI only after B releases.
    // recovery_pending must wait for that echo and then launch a distinct B.
    start_session(3'd1, 2'd0);
    drive_observation(8'h5b, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    source_clock_enable = 1'b0;
    command_toggles_before_reset = {
      dut.clear_toggle_axi, dut.arm_toggle_axi, dut.freeze_toggle_axi,
      dut.freeze_manual_toggle_axi, dut.ack_toggle_axi
    };
    @(negedge axi_clk); axi_aresetn = 1'b0;
    @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (2) @(posedge axi_clk);
    source_clock_enable = 1'b1;
    wait (dut.abort_ack_toggle_source == dut.abort_epoch_toggle_axi);
    @(negedge source_clk); source_clock_enable = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b0;
    @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (4) @(posedge axi_clk);
    if ({dut.clear_toggle_axi, dut.arm_toggle_axi, dut.freeze_toggle_axi,
         dut.freeze_manual_toggle_axi, dut.ack_toggle_axi} !==
        command_toggles_before_reset)
      fail("T13 delayed-echo reset manufactured a source command toggle");
    if (!dut.abort_outstanding_axi || dut.axi_recovery_pending)
      fail("T13 delayed echo did not launch a post-reset abort");
    source_clock_enable = 1'b1;
    wait_status(12, 1'b0);
    mmio_read(17'h03c10, value);
    if (value[5] || dut.monitor_state_source != 3'd0)
      fail($sformatf("T13 delayed-echo stale state status=%08x state=%0d source_valid=%0d",
                     value, dut.monitor_state_source,
                     dut.snapshot_valid_source));

    // Adversarial CDC ordering: a genuine pre-reset ARM token is held behind
    // the abort synchronizer, then released only after abort detection.  The
    // source quarantine must absorb it before returning the abort echo.
    source_clock_enable = 1'b0;
    mmio_write(17'h03c18, 32'h0000_0001);
    mmio_write(17'h03c0c, 32'h0000_0002);
    wait (dut.measurement_started_axi);
    mmio_write(17'h03c0c, 32'h0000_0004);
    arm_seen_before_skew = dut.arm_seen_source;
    manual_seen_before_skew = dut.freeze_manual_seen_source;
    if (dut.arm_toggle_axi == arm_seen_before_skew)
      fail("T13 skew setup did not create a pending ARM token");
    if (dut.freeze_manual_toggle_axi == manual_seen_before_skew)
      fail("T13 skew setup did not create a pending MANUAL token");
    force dut.arm_sync1_source = arm_seen_before_skew;
    force dut.arm_sync2_source = arm_seen_before_skew;
    force dut.freeze_manual_sync1_source = manual_seen_before_skew;
    force dut.freeze_manual_sync2_source = manual_seen_before_skew;
    @(negedge axi_clk); axi_aresetn = 1'b0;
    @(posedge axi_clk);
    @(negedge axi_clk); axi_aresetn = 1'b1;
    source_clock_enable = 1'b1;
    for (i = 0; i < 50 && dut.monitor_state_source != 3'd6; i = i + 1)
      @(posedge source_clk);
    if (dut.monitor_state_source != 3'd6)
      fail("T13 abort quarantine was not entered");
    abort_ack_before_drain = dut.abort_ack_toggle_source;
    quarantine_checks_before = abort_quarantine_checks;
    release dut.arm_sync1_source;
    release dut.arm_sync2_source;
    release dut.freeze_manual_sync1_source;
    release dut.freeze_manual_sync2_source;
    drain_edges = 0;
    while (drain_edges < 12 &&
           dut.abort_ack_toggle_source == abort_ack_before_drain) begin
      @(posedge source_clk);
      @(negedge source_clk);
      drain_edges = drain_edges + 1;
    end
    if (dut.abort_ack_toggle_source == abort_ack_before_drain)
      fail("T13 abort quarantine did not return an echo");
    if (abort_quarantine_checks <= quarantine_checks_before)
      fail("T13 directed abort quarantine was not cycle-checked");
    wait_status(12, 1'b0);
    repeat (8) @(posedge source_clk);
    if (dut.monitor_state_source != 3'd0 || dut.armed_source ||
        dut.arm_seen_source != dut.arm_toggle_axi ||
        dut.freeze_manual_seen_source != dut.freeze_manual_toggle_axi)
      fail("T13 late pre-reset ARM escaped abort quarantine");

    start_session(3'd2, 2'd0);
    drive_observation(8'h77, 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    mmio_read(17'h03c10, value);
    if (!value[5]) fail("T13 post-reset session did not recover");
    else $display("RM1_T13_PASS all_pre_done_resets_double_axi_reset_invalid_then_recovered");
    ack_session();

    // T14 four-bit simulation counter saturates deterministically at 15.
    start_session(3'd1, 2'd0);
    for (i = 0; i < 20; i = i + 1)
      drive_observation(i[7:0], 2'd0, 1'b0, 1'b0, 0, 0, 0, 0);
    freeze_session();
    read_meta(2, value);
    if (value != 15) fail($sformatf("T14 saturation=%0d", value));
    else $display("RM1_T14_PASS saturating_counter_overflow");
    ack_session();

    // T15 route/session/window are frozen in metadata entry 1.
    start_session(3'd4, 2'd2);
    mmio_read(17'h03c1c, value2);
    freeze_session();
    read_meta(1, identity);
    if (identity[15:0] != value2[15:0] || identity[18:16] != 3'd4 ||
        identity[20:19] != 2'd2)
      fail($sformatf("T15 identity=%08x active=%08x", identity, value2));
    else $display("RM1_T15_PASS exact_route_session_tag");

    // T16 metadata is complete before DONE and stable while awaiting ACK.
    read_meta(0, value);
    repeat (20) @(posedge axi_clk);
    read_meta(0, value2);
    if (value != value2 || value != 32'h524d_314d)
      fail("T16 metadata stability");
    // No-DMA quiescence is a whole-session invariant.  A route-controller
    // error after DONE must atomically revoke VALID and all BRAM reads before
    // the host ACKs the session.
    // Accept a synchronous BRAM read, then revoke VALID before its response.
    // The outstanding request must complete with zero, never the old word.
    @(negedge axi_clk);
    mmio_req_addr = 17'h03c40;
    mmio_req_write = 1'b0;
    mmio_req_valid = 1'b1;
    do @(posedge axi_clk); while (!mmio_req_ready);
    @(negedge axi_clk);
    mmio_req_valid = 1'b0;
    mmio_req_addr = 17'b0;
    route_error = 1'b1;
    route_error_code = 16'h0006;
    route_error_pulse = 1'b1;
    @(negedge axi_clk);
    if (!mmio_rsp_valid || mmio_rsp_rdata != 0)
      fail("T16 in-flight RAM response leaked revoked evidence");
    identity = mmio_rsp_rdata;
    route_error_pulse = 1'b0;
    mmio_read(17'h03c10, value2);
    mmio_read(17'h03c40, value);
    if (!value2[4] || value2[5] || identity != 0 || value != 0)
      fail("T16 post-DONE quiescence loss retained valid/read access");
    else $display("RM1_T16_PASS cdc_snapshot_and_post_done_revoke");
    ack_session();
    route_error = 1'b0;
    route_error_code = 16'b0;

    // T18 only the profile-specific diagnostic range can be accepted.
    @(negedge axi_clk);
    mmio_req_addr = 17'h03800;
    mmio_req_valid = 1'b1;
    mmio_req_write = 1'b0;
    repeat (3) @(posedge axi_clk);
    if (mmio_req_ready) fail("T18 accepted address outside RM1 range");
    @(negedge axi_clk); mmio_req_valid = 1'b0; mmio_req_addr = 17'b0;
    mmio_read(17'h03c00, value);
    if (value != 32'h4e52_4d31) fail("T18 in-range identity");
    else $display("RM1_T18_PASS mmio_address_isolation");

    if (errors != 0) begin
      $display("RM1_FOCUSED_GATE_FAIL errors=%0d", errors);
      $fatal(1);
    end
    $display("RM1_FOCUSED_SIMULATION_PASS tests=17 static_t17_pending=1");
    $finish;
  end
endmodule
