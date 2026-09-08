`timescale 1ns/1ps

module tb_g2b_bt656_diag1_r1_event_register;
  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;
  logic mmio_req_ready, mmio_rsp_valid;
  logic [31:0] mmio_rsp_rdata;
  logic event_valid, trigger_pulse, line1_commit;
  logic [511:0] event_payload;
  logic [63:0] axis_data;
  logic [7:0] axis_keep;
  logic axis_last, axis_valid;

  logic forced_valid = 1'b0;
  logic forced_trigger = 1'b0;
  logic forced_line1 = 1'b0;
  logic [511:0] forced_payload = '0;
  integer errors = 0;

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h core (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(1'b0), .mmio_req_ready(mmio_req_ready),
    .mmio_req_write(1'b0), .mmio_req_addr(17'b0),
    .mmio_req_wdata(32'b0), .mmio_req_be(4'b0),
    .mmio_rsp_valid(mmio_rsp_valid), .mmio_rsp_ready(1'b1),
    .mmio_rsp_rdata(mmio_rsp_rdata),
    .bt656_diag_event_valid(event_valid),
    .bt656_diag_trigger_pulse(trigger_pulse),
    .bt656_diag_next_frame_line1_commit(line1_commit),
    .bt656_diag_event_payload(event_payload),
    .m_axis_c2h_tdata(axis_data), .m_axis_c2h_tkeep(axis_keep),
    .m_axis_c2h_tlast(axis_last), .m_axis_c2h_tvalid(axis_valid),
    .m_axis_c2h_tready(1'b1)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("BT656_DIAG1_R1_T11_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic check_output(
      input logic expected_valid,
      input logic expected_trigger,
      input logic expected_line1,
      input logic [511:0] expected_payload,
      input string label);
    begin
      if ({event_valid, trigger_pulse, line1_commit, event_payload} !==
          {expected_valid, expected_trigger, expected_line1,
           expected_payload})
        fail($sformatf("%s registered tuple mismatch", label));
    end
  endtask

  initial begin : RUN
    logic [511:0] payload_a;
    logic [511:0] payload_b;

    payload_a = '0;
    payload_a[2*32 +: 32] = 32'ha11a_0001;
    payload_a[3*32 + 0] = 1'b1;
    payload_a[3*32 + 6] = 1'b1;
    payload_a[3*32 + 7] = 1'b1;
    payload_a[3*32 + 8] = 1'b1;
    payload_a[4*32 +: 32] = 32'd1079;

    payload_b = '0;
    payload_b[2*32 +: 32] = 32'hb22b_0002;
    payload_b[3*32 + 0] = 1'b1;
    payload_b[3*32 + 8] = 1'b1;
    payload_b[4*32 +: 32] = 32'd1080;
    payload_b[5*32 +: 32] = 32'd1;

    repeat (8) @(posedge source_clk);
    repeat (4) @(posedge axi_clk);
    @(negedge source_clk); source_reset = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (3) @(posedge source_clk);

    force core.bt656_diag_event_valid_d = forced_valid;
    force core.bt656_diag_trigger_pulse_d = forced_trigger;
    force core.bt656_diag_next_frame_line1_commit_d = forced_line1;
    force core.bt656_diag_event_payload_d = forced_payload;

    // Change the producer tuple midway through a cycle. Registered outputs
    // must remain unchanged until the next source edge.
    @(negedge source_clk);
    forced_valid = 1'b1;
    forced_trigger = 1'b1;
    forced_line1 = 1'b0;
    forced_payload = payload_a;
    #1;
    check_output(1'b0, 1'b0, 1'b0, '0, "pre-edge stability");
    @(posedge source_clk); #1;
    check_output(1'b1, 1'b1, 1'b0, payload_a, "event A");

    // A second event on the immediately following source cycle must retain
    // order and keep its qualifier tuple aligned with its own payload.
    @(negedge source_clk);
    forced_valid = 1'b1;
    forced_trigger = 1'b0;
    forced_line1 = 1'b1;
    forced_payload = payload_b;
    #1;
    check_output(1'b1, 1'b1, 1'b0, payload_a, "between adjacent events");
    @(posedge source_clk); #1;
    check_output(1'b1, 1'b0, 1'b1, payload_b, "event B");

    if (!(event_payload[3*32 + 8] && line1_commit) || trigger_pulse)
      fail("multiple event bits or line1 qualifier lost");

    @(negedge source_clk);
    forced_valid = 1'b0;
    forced_trigger = 1'b0;
    forced_line1 = 1'b0;
    forced_payload = '0;
    @(posedge source_clk); #1;
    check_output(1'b0, 1'b0, 1'b0, '0, "idle tuple");

    release core.bt656_diag_event_valid_d;
    release core.bt656_diag_trigger_pulse_d;
    release core.bt656_diag_next_frame_line1_commit_d;
    release core.bt656_diag_event_payload_d;

    if (errors == 0)
      $display("BT656_DIAG1_R1_T11_PASS source_registered_aligned_adjacent_events");
    else
      $fatal(1, "BT656_DIAG1_R1_T11_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
