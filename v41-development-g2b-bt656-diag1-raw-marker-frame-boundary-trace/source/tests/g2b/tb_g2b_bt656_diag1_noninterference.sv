`timescale 1ns/1ps

module tb_g2b_bt656_diag1_noninterference;
  logic source_clk = 1'b0;
  logic source_reset = 1'b1;
  logic source_ready = 1'b1;
  logic [7:0] source_byte = 8'h55;
  logic axi_clk = 1'b0;
  logic axi_aresetn = 1'b0;

  logic req_valid = 1'b0;
  logic req_write = 1'b0;
  logic [16:0] req_addr = '0;
  logic [31:0] req_wdata = '0;
  logic [3:0] req_be = '0;
  logic req_ready_product, req_ready_diag;
  logic rsp_valid_product, rsp_valid_diag;
  logic rsp_ready_product = 1'b0;
  logic rsp_ready_diag = 1'b0;
  logic [31:0] rsp_data_product, rsp_data_diag;

  logic diag_req_valid = 1'b0;
  logic diag_req_ready;
  logic diag_req_write = 1'b0;
  logic [16:0] diag_req_addr = '0;
  logic [31:0] diag_req_wdata = '0;
  logic [3:0] diag_req_be = '0;
  logic diag_rsp_valid;
  logic diag_rsp_ready = 1'b1;
  logic [31:0] diag_rsp_rdata;

  logic product_event_valid, product_trigger, product_line1;
  logic [511:0] product_payload;
  logic diag_event_valid, diag_trigger, diag_line1;
  logic [511:0] diag_payload;
  logic [63:0] product_axis_data, diag_axis_data;
  logic [7:0] product_axis_keep, diag_axis_keep;
  logic product_axis_last, diag_axis_last;
  logic product_axis_valid, diag_axis_valid;
  logic axis_ready = 1'b1;
  integer errors = 0;
  integer records = 0;
  logic comparisons_enabled = 1'b0;

  always #3.367 source_clk = ~source_clk;
  always #8.000 axi_clk = ~axi_clk;

  v41_g2b_onech_c2h product_parser (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(req_valid), .mmio_req_ready(req_ready_product),
    .mmio_req_write(req_write), .mmio_req_addr(req_addr),
    .mmio_req_wdata(req_wdata), .mmio_req_be(req_be),
    .mmio_rsp_valid(rsp_valid_product),
    .mmio_rsp_ready(rsp_ready_product),
    .mmio_rsp_rdata(rsp_data_product),
    .bt656_diag_event_valid(product_event_valid),
    .bt656_diag_trigger_pulse(product_trigger),
    .bt656_diag_next_frame_line1_commit(product_line1),
    .bt656_diag_event_payload(product_payload),
    .m_axis_c2h_tdata(product_axis_data),
    .m_axis_c2h_tkeep(product_axis_keep),
    .m_axis_c2h_tlast(product_axis_last),
    .m_axis_c2h_tvalid(product_axis_valid),
    .m_axis_c2h_tready(axis_ready)
  );

  v41_g2b_onech_c2h diag_parser (
    .source_clk(source_clk), .source_reset(source_reset),
    .source_ready(source_ready), .source_byte(source_byte),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(req_valid), .mmio_req_ready(req_ready_diag),
    .mmio_req_write(req_write), .mmio_req_addr(req_addr),
    .mmio_req_wdata(req_wdata), .mmio_req_be(req_be),
    .mmio_rsp_valid(rsp_valid_diag), .mmio_rsp_ready(rsp_ready_diag),
    .mmio_rsp_rdata(rsp_data_diag),
    .bt656_diag_event_valid(diag_event_valid),
    .bt656_diag_trigger_pulse(diag_trigger),
    .bt656_diag_next_frame_line1_commit(diag_line1),
    .bt656_diag_event_payload(diag_payload),
    .m_axis_c2h_tdata(diag_axis_data), .m_axis_c2h_tkeep(diag_axis_keep),
    .m_axis_c2h_tlast(diag_axis_last), .m_axis_c2h_tvalid(diag_axis_valid),
    .m_axis_c2h_tready(axis_ready)
  );

  g2b_bt656_boundary_trace armed_trace (
    .source_clk(source_clk), .source_reset(source_reset),
    .event_valid(diag_event_valid), .trigger_pulse(diag_trigger),
    .next_frame_line1_commit(diag_line1), .event_payload(diag_payload),
    .axi_clk(axi_clk), .axi_aresetn(axi_aresetn),
    .mmio_req_valid(diag_req_valid), .mmio_req_ready(diag_req_ready),
    .mmio_req_write(diag_req_write), .mmio_req_addr(diag_req_addr),
    .mmio_req_wdata(diag_req_wdata), .mmio_req_be(diag_req_be),
    .mmio_rsp_valid(diag_rsp_valid), .mmio_rsp_ready(diag_rsp_ready),
    .mmio_rsp_rdata(diag_rsp_rdata)
  );

  task automatic fail(input string message);
    begin
      errors = errors + 1;
      $display("BT656_DIAG1_NONINTERFERENCE_FAIL time=%0t %s", $time,
               message);
    end
  endtask

  task automatic drive_source_byte(input logic [7:0] value);
    begin @(negedge source_clk); source_byte = value; end
  endtask

  task automatic send_marker(input logic [7:0] xy);
    begin
      drive_source_byte(8'hff); drive_source_byte(8'h00);
      drive_source_byte(8'h00); drive_source_byte(xy);
    end
  endtask

  task automatic send_line(input logic [7:0] seed);
    integer i;
    begin
      send_marker(8'h80);
      for (i = 0; i < 3840; i = i + 1)
        drive_source_byte(seed + i[7:0]);
      send_marker(8'h90);
      for (i = 0; i < 16; i = i + 1)
        drive_source_byte(8'h55 ^ i[7:0]);
    end
  endtask

  task automatic common_write(input logic [16:0] address,
                              input logic [31:0] data);
    begin
      @(negedge axi_clk);
      req_addr = address; req_wdata = data; req_be = 4'hf;
      req_write = 1'b1; req_valid = 1'b1;
      do @(posedge axi_clk); while (!(req_ready_product && req_ready_diag));
      @(negedge axi_clk);
      req_valid = 1'b0; req_write = 1'b0; req_addr = '0;
      req_wdata = '0; req_be = '0;
    end
  endtask

  task automatic common_read_compare(input logic [16:0] address);
    logic [31:0] product_value;
    logic [31:0] diag_value;
    begin
      rsp_ready_product = 1'b0;
      rsp_ready_diag = 1'b0;
      @(negedge axi_clk);
      req_addr = address; req_write = 1'b0; req_valid = 1'b1;
      do @(posedge axi_clk); while (!(req_ready_product && req_ready_diag));
      @(negedge axi_clk); req_valid = 1'b0; req_addr = '0;
      do @(posedge axi_clk); while (!(rsp_valid_product && rsp_valid_diag));
      product_value = rsp_data_product;
      diag_value = rsp_data_diag;
      if (product_value !== diag_value)
        fail($sformatf("MMIO mismatch addr=%05x product=%08x diag=%08x",
                       address, product_value, diag_value));
      @(negedge axi_clk);
      rsp_ready_product = 1'b1;
      rsp_ready_diag = 1'b1;
      @(negedge axi_clk);
      rsp_ready_product = 1'b0;
      rsp_ready_diag = 1'b0;
    end
  endtask

  task automatic trace_write(input logic [31:0] data);
    begin
      @(negedge axi_clk);
      diag_req_addr = 17'h03c0c; diag_req_wdata = data;
      diag_req_be = 4'hf; diag_req_write = 1'b1; diag_req_valid = 1'b1;
      do @(posedge axi_clk); while (!diag_req_ready);
      @(negedge axi_clk);
      diag_req_valid = 1'b0; diag_req_write = 1'b0;
      diag_req_addr = '0; diag_req_wdata = '0; diag_req_be = '0;
    end
  endtask

  always @(posedge axi_clk) begin
    if (comparisons_enabled) begin
      if ({product_axis_valid, product_axis_last, product_axis_keep,
           product_axis_data} !==
          {diag_axis_valid, diag_axis_last, diag_axis_keep, diag_axis_data})
        fail("C2H AXIS output differs with trace armed");
      if (req_ready_product !== req_ready_diag)
        fail("functional MMIO request-ready differs");
    end
    if (product_axis_valid && axis_ready && product_axis_last)
      records = records + 1;
  end

  always @(posedge source_clk) begin
    integer slot_index;
    if (comparisons_enabled) begin
      if (product_parser.source_state !== diag_parser.source_state ||
          product_parser.source_locked_source !==
              diag_parser.source_locked_source ||
          product_parser.source_frame_sequence !==
              diag_parser.source_frame_sequence ||
          product_parser.source_line_sequence !==
              diag_parser.source_line_sequence ||
          product_parser.source_capture_sequence !==
              diag_parser.source_capture_sequence ||
          product_parser.source_lifetime_malformed !==
              diag_parser.source_lifetime_malformed ||
          product_parser.source_lifetime_dropped !==
              diag_parser.source_lifetime_dropped ||
          product_parser.records_attempted_source !==
              diag_parser.records_attempted_source ||
          product_parser.records_committed_source !==
              diag_parser.records_committed_source ||
          product_parser.records_dropped_source !==
              diag_parser.records_dropped_source ||
          product_parser.overflow_count_source !==
              diag_parser.overflow_count_source)
        fail("functional parser state or counter differs");
      for (slot_index = 0; slot_index < 4; slot_index = slot_index + 1)
        if (product_parser.slot_state_source[slot_index] !==
            diag_parser.slot_state_source[slot_index])
          fail($sformatf("slot state differs slot=%0d", slot_index));
    end
  end

  initial begin : RUN
    integer i;
    repeat (12) @(posedge source_clk);
    repeat (8) @(posedge axi_clk);
    @(negedge source_clk); source_reset = 1'b0;
    @(negedge axi_clk); axi_aresetn = 1'b1;
    repeat (24) @(posedge axi_clk);
    comparisons_enabled = 1'b1;

    // Establish lock while both instances are functionally disabled.
    send_line(8'h10);
    trace_write(32'h0000_0001);
    trace_write(32'h0000_0002);
    repeat (12) @(posedge source_clk);
    common_write(17'h0380c, 32'h0000_0001);
    for (i = 0; i < 8; i = i + 1)
      send_line(8'h40 + i[7:0]);
    while (records < 8)
      @(posedge axi_clk);

    for (i = 0; i <= 22; i = i + 1)
      common_read_compare(17'h03800 + i*4);

    if (product_event_valid !== diag_event_valid ||
        product_payload !== diag_payload)
      fail("passive diagnostic projection differs between parser instances");
    if (errors == 0)
      $display("BT656_DIAG1_T9_PASS side_by_side_product_equivalent_vs_trace_armed byte_identical");
    else
      $fatal(1, "BT656_DIAG1_T9_FAIL errors=%0d", errors);
    $finish;
  end
endmodule
