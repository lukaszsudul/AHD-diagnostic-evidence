`timescale 1ns/1ps

// Integration fixture for the actual VDO1 parser boundary.  This deliberately
// drives the existing source_byte input of v41_g2b_onech_c2h and observes only
// the fanout-only RM1 outputs; it does not recreate the FF/00/00 detector in a
// stand-in monitor stimulus model.
module tb_g2b_nvp_rm1_parser_tap;
  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;

  logic rm1_sample_valid;
  logic [7:0] rm1_sample_byte;
  logic [1:0] rm1_prefix_state;
  logic rm1_candidate;
  logic rm1_raw_parity_valid;
  logic rm1_f;
  logic rm1_v;
  logic rm1_h;
  logic rm1_parser_qualified;
  logic [2:0] rm1_parser_state;
  integer errors = 0;
  integer combination;

  always #5 source_clk = ~source_clk;
  always #8 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h dut (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(1'b0), .mmio_req_ready(), .mmio_req_write(1'b0),
    .mmio_req_addr(17'b0), .mmio_req_wdata(32'b0), .mmio_req_be(4'b0),
    .mmio_rsp_valid(), .mmio_rsp_ready(1'b1), .mmio_rsp_rdata(),
    .m_axis_c2h_tdata(), .m_axis_c2h_tkeep(), .m_axis_c2h_tlast(),
    .m_axis_c2h_tvalid(), .m_axis_c2h_tready(1'b0),
    .diag_stored_enable(), .diag_c2h_active(), .diag_ring_empty(),
    .diag_ring_full(),
    .diag_rm1_sample_valid(rm1_sample_valid),
    .diag_rm1_sample_byte(rm1_sample_byte),
    .diag_rm1_prefix_state(rm1_prefix_state),
    .diag_rm1_candidate(rm1_candidate),
    .diag_rm1_raw_parity_valid(rm1_raw_parity_valid),
    .diag_rm1_f(rm1_f), .diag_rm1_v(rm1_v), .diag_rm1_h(rm1_h),
    .diag_rm1_parser_qualified(rm1_parser_qualified),
    .diag_rm1_parser_state(rm1_parser_state)
  );

  function automatic logic [7:0] legal_xy(
      input logic f, input logic v, input logic h);
    begin
      legal_xy = {1'b1, f, v, h, v ^ h, f ^ h, f ^ v,
                  f ^ v ^ h};
    end
  endfunction

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("RM1_PARSER_TAP_FAIL time=%0t %s", $time, message);
    end
  endtask

  task automatic drive_and_check(
      input logic [7:0] value,
      input logic [1:0] expected_prefix,
      input logic expected_candidate,
      input logic expected_parity,
      input logic expected_qualified);
    logic [2:0] state_on_observation_edge;
    begin
      @(negedge source_clk);
      source_byte = value;
      state_on_observation_edge = dut.source_state;
      @(posedge source_clk);
      #1;
      if (!rm1_sample_valid || rm1_sample_byte !== value)
        fail($sformatf("registered byte mismatch expected=%02x actual=%02x",
                       value, rm1_sample_byte));
      if (rm1_prefix_state !== expected_prefix ||
          rm1_candidate !== expected_candidate ||
          rm1_raw_parity_valid !== expected_parity ||
          rm1_parser_qualified !== expected_qualified)
        fail($sformatf("classification byte=%02x prefix=%0d cand=%0b parity=%0b qualified=%0b",
                       value, rm1_prefix_state, rm1_candidate,
                       rm1_raw_parity_valid, rm1_parser_qualified));
      if (rm1_parser_state !== state_on_observation_edge)
        fail("parser state was not registered atomically with observation");
    end
  endtask

  task automatic emit_candidate(
      input logic [7:0] xy,
      input logic expected_parity,
      input logic expected_qualified);
    begin
      drive_and_check(8'h55, 2'd0, 1'b0, 1'b0, 1'b0);
      drive_and_check(8'hff, 2'd0, 1'b0, 1'b0, 1'b0);
      drive_and_check(8'h00, 2'd1, 1'b0, 1'b0, 1'b0);
      drive_and_check(8'h00, 2'd2, 1'b0, 1'b0, 1'b0);
      drive_and_check(xy, 2'd3, 1'b1, expected_parity,
                      expected_qualified);
      if (rm1_f !== xy[6] || rm1_v !== xy[5] || rm1_h !== xy[4])
        fail("F/V/H decode not aligned to candidate byte");
    end
  endtask

  initial begin
    repeat (5) @(posedge source_clk);
    @(negedge source_clk);
    source_reset = 1'b0;
    axi_aresetn = 1'b1;

    // Fill the existing three-byte prefix history, then cover the complete
    // BT.656 F/V/H protection-bit matrix at the real parser boundary.
    repeat (4)
      drive_and_check(8'h55, 2'd0, 1'b0, 1'b0, 1'b0);
    for (combination = 0; combination < 8; combination = combination + 1)
      emit_candidate(legal_xy(combination[2], combination[1],
                              combination[0]), 1'b1,
                     combination == 0);

    // A single corrupt protection bit remains a candidate but is not raw
    // legal, while the legacy literal low-nibble predicate stays independent.
    emit_candidate(legal_xy(1'b0, 1'b1, 1'b0) ^ 8'h01,
                   1'b0, 1'b0);

    if (errors != 0) begin
      $display("RM1_PARSER_TAP_INTEGRATION_FAIL errors=%0d", errors);
      $fatal(1);
    end
    $display("RM1_PARSER_TAP_INTEGRATION_PASS real_prefix_full_parity_atomic_state");
    $finish;
  end
endmodule
