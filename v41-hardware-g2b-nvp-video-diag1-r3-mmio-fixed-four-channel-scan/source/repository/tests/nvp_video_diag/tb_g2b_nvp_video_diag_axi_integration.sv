`timescale 1ns/1ps

// R3 bridge-level command regression.  This instantiates the shipped AXI-Lite
// bridge and G2B router, the diagnostic range intercept, the real diagnostic
// core, and bounded PRODUCT/legacy responder models.
module tb_g2b_nvp_video_diag_axi_integration;
  logic clk = 1'b0;
  logic reset = 1'b1;
  always #5 clk = ~clk;

  logic [31:0] s_axi_awaddr = '0;
  logic [2:0] s_axi_awprot = '0;
  logic s_axi_awvalid = 1'b0;
  logic s_axi_awready;
  logic [31:0] s_axi_wdata = '0;
  logic [3:0] s_axi_wstrb = 4'hf;
  logic s_axi_wvalid = 1'b0;
  logic s_axi_wready;
  logic [1:0] s_axi_bresp;
  logic s_axi_bvalid;
  logic s_axi_bready = 1'b0;
  logic [31:0] s_axi_araddr = '0;
  logic [2:0] s_axi_arprot = '0;
  logic s_axi_arvalid = 1'b0;
  logic s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_rvalid;
  logic s_axi_rready = 1'b0;

  logic host_req_valid;
  logic host_req_ready;
  logic host_req_write;
  logic [16:0] host_req_addr;
  logic [31:0] host_req_wdata;
  logic [3:0] host_req_be;
  logic host_rsp_valid;
  logic host_rsp_ready;
  logic [31:0] host_rsp_rdata;

  logic legacy_req_valid;
  logic legacy_req_ready;
  logic legacy_req_write;
  logic [16:0] legacy_req_addr;
  logic [31:0] legacy_req_wdata;
  logic [3:0] legacy_req_be;
  logic legacy_rsp_valid;
  logic legacy_rsp_ready;
  logic [31:0] legacy_rsp_rdata;

  logic g2b_req_valid;
  logic g2b_req_ready;
  logic g2b_req_write;
  logic [16:0] g2b_req_addr;
  logic [31:0] g2b_req_wdata;
  logic [3:0] g2b_req_be;
  logic g2b_rsp_valid;
  logic g2b_rsp_ready;
  logic [31:0] g2b_rsp_rdata;

  logic product_legacy_req_valid;
  logic product_legacy_req_ready;
  logic product_legacy_rsp_valid;
  logic product_legacy_rsp_ready;
  logic [31:0] product_legacy_rsp_rdata;
  logic diag_req_valid;
  logic diag_req_ready;
  logic diag_rsp_valid;
  logic diag_rsp_ready;
  logic [31:0] diag_rsp_rdata;
  wire diag_select = legacy_req_addr >= 17'h03c00 &&
                     legacy_req_addr <= 17'h03fff;

  logic autoinit_done = 1'b1;
  logic autoinit_busy = 1'b0;
  logic autoinit_error = 1'b0;
  logic nvp_reset_released = 1'b1;
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

  logic diagnostic_i2c_owns_bus;
  logic capture_ready;
  logic [15:0] current_session_id;
  logic [2:0] current_round;
  logic [2:0] current_channel;
  logic product_baseline_restored;

  v41_axi_lite_host_bridge bridge (
    .clk(clk), .reset(reset),
    .s_axi_awaddr(s_axi_awaddr), .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr), .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata)
  );

  v41_g2b_mmio_router router (
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata),
    .legacy_req_valid(legacy_req_valid), .legacy_req_ready(legacy_req_ready),
    .legacy_req_write(legacy_req_write), .legacy_req_addr(legacy_req_addr),
    .legacy_req_wdata(legacy_req_wdata), .legacy_req_be(legacy_req_be),
    .legacy_rsp_valid(legacy_rsp_valid),
    .legacy_rsp_ready(legacy_rsp_ready),
    .legacy_rsp_rdata(legacy_rsp_rdata),
    .g2b_req_valid(g2b_req_valid), .g2b_req_ready(g2b_req_ready),
    .g2b_req_write(g2b_req_write), .g2b_req_addr(g2b_req_addr),
    .g2b_req_wdata(g2b_req_wdata), .g2b_req_be(g2b_req_be),
    .g2b_rsp_valid(g2b_rsp_valid), .g2b_rsp_ready(g2b_rsp_ready),
    .g2b_rsp_rdata(g2b_rsp_rdata)
  );

  assign product_legacy_req_valid = legacy_req_valid && !diag_select;
  assign diag_req_valid = legacy_req_valid && diag_select;
  assign legacy_req_ready = diag_select ? diag_req_ready :
                                          product_legacy_req_ready;
  assign legacy_rsp_valid = diag_rsp_valid || product_legacy_rsp_valid;
  assign legacy_rsp_rdata = diag_rsp_valid ? diag_rsp_rdata :
                                             product_legacy_rsp_rdata;
  assign diag_rsp_ready = legacy_rsp_ready;
  assign product_legacy_rsp_ready = legacy_rsp_ready;

  g2b_nvp_video_diag #(
    .CYCLES_PER_MS(1), .SETTLE_TIME_MS(2),
    .STATUS_SAMPLE_INTERVAL_MS(1), .REQUIRED_STABLE_SAMPLES(5),
    .MAX_STATUS_WAIT_MS(200)
  ) diag (
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
    .mmio_req_valid(diag_req_valid), .mmio_req_ready(diag_req_ready),
    .mmio_req_write(legacy_req_write), .mmio_req_addr(legacy_req_addr),
    .mmio_req_wdata(legacy_req_wdata), .mmio_req_be(legacy_req_be),
    .mmio_rsp_valid(diag_rsp_valid), .mmio_rsp_ready(diag_rsp_ready),
    .mmio_rsp_rdata(diag_rsp_rdata),
    .diagnostic_i2c_owns_bus(diagnostic_i2c_owns_bus),
    .capture_ready(capture_ready), .current_session_id(current_session_id),
    .current_round(current_round), .current_channel(current_channel),
    .product_baseline_restored(product_baseline_restored)
  );

  // Minimal PRODUCT/G2B responder used solely for address-isolation proof.
  logic [31:0] product_control;
  integer product_write_count = 0;
  assign g2b_req_ready = !g2b_rsp_valid || g2b_rsp_ready;
  always_ff @(posedge clk) begin
    if (reset) begin
      g2b_rsp_valid <= 1'b0;
      g2b_rsp_rdata <= 32'b0;
      product_control <= 32'b0;
    end else begin
      if (g2b_rsp_valid && g2b_rsp_ready)
        g2b_rsp_valid <= 1'b0;
      if (g2b_req_valid && g2b_req_ready) begin
        if (g2b_req_write) begin
          if (g2b_req_addr == 17'h0380c && g2b_req_be == 4'hf) begin
            product_control <= g2b_req_wdata;
            product_write_count <= product_write_count + 1;
          end
        end else begin
          g2b_rsp_valid <= 1'b1;
          g2b_rsp_rdata <= (g2b_req_addr == 17'h0380c) ?
                           product_control : 32'h4752_4231;
        end
      end
    end
  end

  // Non-diagnostic legacy stub.  It also follows write-no-response semantics.
  assign product_legacy_req_ready =
      !product_legacy_rsp_valid || product_legacy_rsp_ready;
  always_ff @(posedge clk) begin
    if (reset) begin
      product_legacy_rsp_valid <= 1'b0;
      product_legacy_rsp_rdata <= 32'b0;
    end else begin
      if (product_legacy_rsp_valid && product_legacy_rsp_ready)
        product_legacy_rsp_valid <= 1'b0;
      if (product_legacy_req_valid && product_legacy_req_ready &&
          !legacy_req_write) begin
        product_legacy_rsp_valid <= 1'b1;
        product_legacy_rsp_rdata <= 32'h1e9a_c001;
      end
    end
  end

  // Transaction-level fixed-register NVP model.
  logic [7:0] bank0 [0:255];
  logic [7:0] bank1 [0:255];
  logic [7:0] selected_bank;
  logic model_pending;
  logic model_write;
  logic [7:0] model_reg;
  logic [7:0] model_wdata;
  logic [7:0] model_bank;
  integer init_index;

  assign i2c_cmd_ready = !model_pending;
  assign i2c_cmd_accepted = i2c_cmd_valid && i2c_cmd_ready;
  assign i2c_busy = model_pending;
  assign i2c_bus_idle = !model_pending;

  task automatic initialize_register_model;
    begin
      for (init_index = 0; init_index < 256; init_index = init_index + 1) begin
        bank0[init_index] = 8'h00;
        bank1[init_index] = 8'h00;
      end
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
      bank0[8'ha8] = 8'h0f;
      bank0[8'he0] = 8'h00;
      bank0[8'he1] = 8'h00;
      bank0[8'he2] = 8'h00;
      bank0[8'he8] = 8'h01;
      bank0[8'he9] = 8'h01;
      bank0[8'hea] = 8'h01;
      bank0[8'heb] = 8'h01;
      bank1[8'hc2] = 8'ha0;
      selected_bank = 8'h00;
    end
  endtask

  always_ff @(posedge clk) begin
    if (reset) begin
      model_pending <= 1'b0;
      model_write <= 1'b0;
      model_reg <= 8'b0;
      model_wdata <= 8'b0;
      model_bank <= 8'b0;
      i2c_done <= 1'b0;
      i2c_success <= 1'b1;
      i2c_timeout <= 1'b0;
      i2c_read_data <= 8'b0;
    end else begin
      i2c_done <= 1'b0;
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
        i2c_success <= 1'b1;
        if (model_write) begin
          if (model_reg == 8'hff)
            selected_bank <= model_wdata;
          else if (model_bank == 8'h00)
            bank0[model_reg] <= model_wdata;
          else if (model_bank == 8'h01)
            bank1[model_reg] <= model_wdata;
        end else begin
          if (model_reg == 8'hff)
            i2c_read_data <= selected_bank;
          else if (model_bank == 8'h00)
            i2c_read_data <= bank0[model_reg];
          else if (model_bank == 8'h01)
            i2c_read_data <= bank1[model_reg];
          else
            i2c_read_data <= 8'h00;
        end
      end
    end
  end

  integer aw_handshakes = 0;
  integer w_handshakes = 0;
  integer b_handshakes = 0;
  integer ar_handshakes = 0;
  integer r_handshakes = 0;
  logic [31:0] last_rdata = 0;
  integer diag_write_accepts = 0;
  integer diag_read_accepts = 0;
  integer diag_read_responses = 0;
  integer diag_control_side_effects = 0;
  integer diag_host_side_effects = 0;
  integer diag_protocol_error_side_effects = 0;
  logic previous_diag_write = 1'b0;
  logic held_response_previous = 1'b0;
  logic [31:0] held_response_data = 0;

  always @(posedge clk) begin
    if (s_axi_awvalid && s_axi_awready) aw_handshakes = aw_handshakes + 1;
    if (s_axi_wvalid && s_axi_wready) w_handshakes = w_handshakes + 1;
    if (s_axi_bvalid && s_axi_bready) b_handshakes = b_handshakes + 1;
    if (s_axi_arvalid && s_axi_arready) ar_handshakes = ar_handshakes + 1;
    if (s_axi_rvalid && s_axi_rready) begin
      r_handshakes = r_handshakes + 1;
      last_rdata = s_axi_rdata;
    end

    if (reset) begin
      previous_diag_write <= 1'b0;
      held_response_previous <= 1'b0;
    end else begin
      if (previous_diag_write && diag_rsp_valid)
        $fatal(1, "diagnostic write created or retained downstream response");
      previous_diag_write <= diag_req_valid && diag_req_ready &&
                             legacy_req_write;
      if (held_response_previous &&
          (!diag_rsp_valid || diag_rsp_rdata !== held_response_data))
        $fatal(1, "diagnostic response changed while backpressured");
      held_response_previous <= diag_rsp_valid && !diag_rsp_ready;
      if (diag_rsp_valid && !diag_rsp_ready)
        held_response_data <= diag_rsp_rdata;

      if (diag_req_valid && diag_req_ready) begin
        if (legacy_req_write)
          diag_write_accepts = diag_write_accepts + 1;
        else
          diag_read_accepts = diag_read_accepts + 1;
      end
      if (diag_rsp_valid && diag_rsp_ready)
        diag_read_responses = diag_read_responses + 1;
      if (diag.control_pulse != 0)
        diag_control_side_effects = diag_control_side_effects + 1;
      if (diag.host_response_pulse)
        diag_host_side_effects = diag_host_side_effects + 1;
      if (diag.mmio_protocol_error_pulse)
        diag_protocol_error_side_effects =
            diag_protocol_error_side_effects + 1;
    end
  end

  task automatic reset_system;
    begin
      s_axi_awvalid = 1'b0;
      s_axi_wvalid = 1'b0;
      s_axi_bready = 1'b0;
      s_axi_arvalid = 1'b0;
      s_axi_rready = 1'b0;
      transport_stream_enabled = 1'b0;
      transport_c2h_active = 1'b0;
      transport_ring_empty = 1'b1;
      transport_ring_full = 1'b0;
      reset = 1'b1;
      initialize_register_model();
      repeat (5) @(posedge clk);
      reset = 1'b0;
      repeat (4) @(posedge clk);
    end
  endtask

  task automatic drive_aw(input logic [31:0] address, input integer delay,
                          input integer starting_count);
    integer guard;
    begin
      repeat (delay) @(negedge clk);
      s_axi_awaddr = address;
      s_axi_awvalid = 1'b1;
      guard = 0;
      while (aw_handshakes == starting_count && guard < 200) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (aw_handshakes != starting_count + 1)
        $fatal(1, "AXI AW timeout");
      s_axi_awvalid = 1'b0;
    end
  endtask

  task automatic drive_w(input logic [31:0] data, input integer delay,
                         input integer starting_count);
    integer guard;
    begin
      repeat (delay) @(negedge clk);
      s_axi_wdata = data;
      s_axi_wstrb = 4'hf;
      s_axi_wvalid = 1'b1;
      guard = 0;
      while (w_handshakes == starting_count && guard < 200) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (w_handshakes != starting_count + 1)
        $fatal(1, "AXI W timeout");
      s_axi_wvalid = 1'b0;
    end
  endtask

  task automatic axi_write(input logic [31:0] address,
                           input logic [31:0] data,
                           input integer aw_delay,
                           input integer w_delay,
                           input integer bready_delay);
    integer aw_start;
    integer w_start;
    integer b_start;
    integer guard;
    begin
      aw_start = aw_handshakes;
      w_start = w_handshakes;
      b_start = b_handshakes;
      fork
        drive_aw(address, aw_delay, aw_start);
        drive_w(data, w_delay, w_start);
      join
      repeat (bready_delay) @(negedge clk);
      s_axi_bready = 1'b1;
      guard = 0;
      while (b_handshakes == b_start && guard < 300) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (b_handshakes != b_start + 1 || s_axi_bresp != 2'b00)
        $fatal(1, "AXI B response timeout/mismatch");
      s_axi_bready = 1'b0;
    end
  endtask

  task automatic axi_read(input logic [31:0] address,
                          input integer ar_delay,
                          input integer rready_delay,
                          output logic [31:0] value);
    integer ar_start;
    integer r_start;
    integer guard;
    begin
      ar_start = ar_handshakes;
      r_start = r_handshakes;
      repeat (ar_delay) @(negedge clk);
      s_axi_araddr = address;
      s_axi_arvalid = 1'b1;
      guard = 0;
      while (ar_handshakes == ar_start && guard < 300) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (ar_handshakes != ar_start + 1)
        $fatal(1, "AXI AR timeout");
      s_axi_arvalid = 1'b0;
      repeat (rready_delay) @(negedge clk);
      s_axi_rready = 1'b1;
      guard = 0;
      while (r_handshakes == r_start && guard < 300) begin
        @(negedge clk);
        guard = guard + 1;
      end
      if (r_handshakes != r_start + 1 || s_axi_rresp != 2'b00)
        $fatal(1, "AXI R response timeout/mismatch");
      value = last_rdata;
      s_axi_rready = 1'b0;
    end
  endtask

  task automatic expect_read(input logic [31:0] address,
                             input logic [31:0] expected,
                             input integer ar_delay,
                             input integer rready_delay);
    logic [31:0] value;
    begin
      axi_read(address, ar_delay, rready_delay, value);
      if (value !== expected)
        $fatal(1, "AXI read mismatch address=%h got=%h expected=%h",
               address, value, expected);
    end
  endtask

  task automatic wait_prepared;
    integer guard;
    logic [31:0] value;
    begin
      guard = 0;
      value = 0;
      while ((!value[1] || value[0] || value[4]) && guard < 1000) begin
        axi_read(32'h0000_3c10, 0, 0, value);
        guard = guard + 1;
      end
      if (!value[1] || value[0] || value[4])
        $fatal(1, "PREPARE failed to reach prepared IDLE status=%h", value);
    end
  endtask

  task automatic wait_capture_session(input integer session);
    integer guard;
    logic [31:0] status_value;
    logic [31:0] session_value;
    begin
      guard = 0;
      status_value = 0;
      session_value = 0;
      while ((!status_value[2] || session_value[15:0] != session) &&
             guard < 3000) begin
        axi_read(32'h0000_3c10, 0, 0, status_value);
        axi_read(32'h0000_3c20, 0, 0, session_value);
        guard = guard + 1;
      end
      if (!status_value[2] || session_value[15:0] != session)
        $fatal(1, "CAPTURE_READY timeout expected session=%0d status=%h current=%h",
               session, status_value, session_value);
    end
  endtask

  task automatic wait_done_restored;
    integer guard;
    logic [31:0] value;
    begin
      guard = 0;
      value = 0;
      while ((!value[3] || !value[5] || value[0] || value[4]) &&
             guard < 3000) begin
        axi_read(32'h0000_3c10, 0, 0, value);
        guard = guard + 1;
      end
      if (!value[3] || !value[5] || value[0] || value[4])
        $fatal(1, "DONE/restore timeout status=%h", value);
    end
  endtask

  integer iteration;
  integer session;
  integer start_aw;
  integer start_w;
  integer start_b;
  integer start_ar;
  integer start_r;
  integer start_diag_writes;
  integer start_diag_reads;
  integer start_diag_responses;
  integer start_control_effects;
  integer start_host_effects;
  integer product_before;
  integer control_before;
  logic [31:0] value;

  initial begin
    initialize_register_model();
    reset_system();

    // T21: actual bridge/router/diagnostic sequence that previously deadlocked.
    expect_read(32'h0000_3c00, 32'h4e56_5034, 0, 0);
    expect_read(32'h0000_3c04, 32'h0001_0002, 0, 1);
    expect_read(32'h0000_3c10, 32'h0000_00a0, 0, 0);
    axi_write(32'h0000_3c0c, 32'h0000_0001, 0, 0, 2);
    expect_read(32'h0000_3c10, 32'h0000_00a0, 0, 2);
    expect_read(32'h0000_3c18, 32'h0000_0000, 0, 0);
    expect_read(32'h0000_3c14, 32'h0000_0000, 0, 0);
    axi_write(32'h0000_3c0c, 32'h0000_0002, 2, 0, 1);
    wait_prepared();
    axi_write(32'h0000_3c0c, 32'h0000_0004, 0, 2, 0);
    wait_capture_session(1);
    axi_write(32'h0000_3c34, 32'h0001_0009, 1, 0, 2);
    wait_capture_session(2);
    axi_write(32'h0000_3c0c, 32'h0000_0010, 0, 1, 0);
    axi_read(32'h0000_3c6c, 0, 2, value);
    $display("PASS T21 ACTUAL_AXI_LITE_BRIDGE_INTEGRATION");

    // T22: independent AW/W ordering, response backpressure, and tight mixes.
    reset_system();
    axi_write(32'h0000_3c0c, 32'h1, 0, 3, 0);  // AW before W
    axi_write(32'h0000_3c0c, 32'h1, 3, 0, 2);  // W before AW
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 4);  // simultaneous, delayed BREADY
    expect_read(32'h0000_3c00, 32'h4e56_5034, 0, 5);
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    expect_read(32'h0000_3c04, 32'h0001_0002, 0, 0);
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    expect_read(32'h0000_3c00, 32'h4e56_5034, 0, 0);
    expect_read(32'h0000_3c08, 32'h0000_0bff, 0, 3);
    $display("PASS T22 AXI_LITE_ORDERING_AND_BACKPRESSURE");

    // T23: 1000 complete command/read iterations with randomized legal delays.
    reset_system();
    for (iteration = 0; iteration < 1000; iteration = iteration + 1) begin
      axi_write(32'h0000_3c0c, 32'h1,
                $urandom_range(0, 3), $urandom_range(0, 3),
                $urandom_range(0, 3));
      expect_read(32'h0000_3c00, 32'h4e56_5034,
                  $urandom_range(0, 2), $urandom_range(0, 3));
      expect_read(32'h0000_3c04, 32'h0001_0002,
                  $urandom_range(0, 2), $urandom_range(0, 3));
      expect_read(32'h0000_3c10, 32'h0000_00a0,
                  $urandom_range(0, 2), $urandom_range(0, 3));
      expect_read(32'h0000_3c18, 32'h0000_0000,
                  $urandom_range(0, 2), $urandom_range(0, 3));
      expect_read(32'h0000_3c14, 32'h0000_0000,
                  $urandom_range(0, 2), $urandom_range(0, 3));
    end
    $display("PASS T23 1000_CYCLE_COMMAND_STRESS");

    // T24: prove 0x3c0c and 0x380c reach only their intended responders.
    reset_system();
    product_before = product_write_count;
    control_before = diag_control_side_effects;
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    repeat (2) @(negedge clk);
    if (product_write_count != product_before || product_control != 0 ||
        diag_control_side_effects != control_before + 1)
      $fatal(1, "diagnostic write aliased PRODUCT control");
    control_before = diag_control_side_effects;
    axi_write(32'h0000_380c, 32'h1, 0, 0, 0);
    repeat (2) @(negedge clk);
    if (product_write_count != product_before + 1 || product_control != 1 ||
        diag_control_side_effects != control_before)
      $fatal(1, "PRODUCT write aliased diagnostic control");
    expect_read(32'h0000_380c, 32'h0000_0001, 0, 1);
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    if (product_control != 1)
      $fatal(1, "diagnostic CLEAR changed PRODUCT stored enable");
    $display("PASS T24 DIAGNOSTIC_PRODUCT_ADDRESS_ISOLATION");

    // T25: bounded progress plus the complete command/session sequence.
    reset_system();
    start_aw = aw_handshakes;
    start_w = w_handshakes;
    start_b = b_handshakes;
    start_ar = ar_handshakes;
    start_r = r_handshakes;
    start_diag_writes = diag_write_accepts;
    start_diag_reads = diag_read_accepts;
    start_diag_responses = diag_read_responses;
    start_control_effects = diag_control_side_effects;
    start_host_effects = diag_host_side_effects;

    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    axi_write(32'h0000_3c0c, 32'h2, 1, 0, 1);
    wait_prepared();
    axi_write(32'h0000_3c0c, 32'h4, 0, 1, 0);
    for (session = 1; session <= 16; session = session + 1) begin
      wait_capture_session(session);
      expect_read(32'h0000_3d20, 32'h0000_0001, 0,
                  $urandom_range(0, 2));
      axi_read(32'h0000_3d24, 0, $urandom_range(0, 2), value);
      if (value[15:0] != session)
        $fatal(1, "snapshot session mismatch expected=%0d got=%0d",
               session, value[15:0]);
      axi_write(32'h0000_3c34, {session[15:0], 12'b0, 4'b1001},
                $urandom_range(0, 2), $urandom_range(0, 2),
                $urandom_range(0, 2));
    end
    wait_done_restored();
    axi_write(32'h0000_3c0c, 32'h10, 0, 0, 1);
    expect_read(32'h0000_3c6c, 32'h0000_0003, 0, 2);
    axi_write(32'h0000_3c0c, 32'h1, 0, 0, 0);
    expect_read(32'h0000_3c18, 32'h0000_0000, 0, 0);

    repeat (3) @(negedge clk);
    if (aw_handshakes - start_aw != w_handshakes - start_w ||
        aw_handshakes - start_aw != b_handshakes - start_b)
      $fatal(1, "AXI write/B response count mismatch");
    if (ar_handshakes - start_ar != r_handshakes - start_r)
      $fatal(1, "AXI read/R response count mismatch");
    if (diag_read_accepts - start_diag_reads !=
        diag_read_responses - start_diag_responses)
      $fatal(1, "diagnostic read/response count mismatch");
    if (diag_write_accepts - start_diag_writes !=
        (diag_control_side_effects - start_control_effects) +
        (diag_host_side_effects - start_host_effects))
      $fatal(1, "diagnostic write/side-effect count mismatch");
    if ((diag_write_accepts - start_diag_writes) +
        (diag_read_accepts - start_diag_reads) !=
        (diag_control_side_effects - start_control_effects) +
        (diag_host_side_effects - start_host_effects) +
        (diag_read_responses - start_diag_responses))
      $fatal(1, "accepted request conservation mismatch");
    if (bank0[8'h78] != 8'h88 || bank0[8'h79] != 8'h88 ||
        bank1[8'hc2] != 8'ha0 || selected_bank != 8'h00)
      $fatal(1, "complete command sequence failed PRODUCT restore");
    $display("PASS T25 BOUNDED_PROGRESS_PROPERTIES");
    $display("PASS R3_NEW_MMIO_AXI_LITE_SIMULATION_GATE 6/6");
    $finish;
  end

  initial begin
    #10000000;
    $fatal(1, "R3 AXI integration global timeout");
  end
endmodule
