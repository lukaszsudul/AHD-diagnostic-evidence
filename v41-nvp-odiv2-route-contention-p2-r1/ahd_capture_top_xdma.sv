`timescale 1ns/1ps

// v41 integrated Phase-1 top.  The complete preserved NVP/video/capture
// application is present behind XDMA's AXI-Lite Master.  C2H remains idle
// until its record adapter is introduced by the staged data-plane phase; the
// tool-mandated H2C channel has no consumer and is permanently backpressured.
module ahd_capture_top_xdma #(
  parameter integer SLOT_COUNT = 2,
  parameter logic [31:0] BLOCK_OR_FW_ID = 32'hA40A0C07,
  parameter logic [31:0] GIT_SHA_W0 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W1 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W2 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W3 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W4 = 32'h00000000,
  parameter logic [31:0] BUILD_FLAGS = 32'h00000000,
  parameter integer ENABLE_MAREK_INIT_TABLE = 1
) (
  output wire  [0:0] pci_exp_txp,
  output wire  [0:0] pci_exp_txn,
  input  logic [0:0] pci_exp_rxp,
  input  logic [0:0] pci_exp_rxn,
  input  logic       sys_clk_p,
  input  logic       sys_clk_n,
  input  logic       sys_rst_n,
  input  logic       vclk1,
  input  logic [7:0] vdo1_data,
  output wire        nvp_rst,
  inout  wire        nvp_scl,
  inout  wire        nvp_sda,
  output wire        nvp_en_vdd1x,
  output wire        nvp_en_vdd3x,
  input  logic [3:0] nvp_mpp
);
  wire pcie_refclk;
  wire refclk_odiv2;
  wire nvp_aclk_probe;
  wire sys_rst_n_c;
  wire axi_aclk;
  wire axi_aresetn;
  wire user_lnk_up;
  wire autonomous_clk = axi_aclk;

  IBUF PCIE_PERST_IBUF (.I(sys_rst_n), .O(sys_rst_n_c));
  IBUFDS_GTE2 PCIE_REFCLK_IBUF (
    .I(sys_clk_p), .IB(sys_clk_n), .CEB(1'b0),
    .O(pcie_refclk), .ODIV2(refclk_odiv2)
  );

  BUFG NVP_ACLK_BUFG (.I(refclk_odiv2), .O(nvp_aclk_probe));
  (* DONT_TOUCH = "TRUE", SHREG_EXTRACT = "NO" *) logic [7:0] nvp_aclk_probe_counter = '0;
  always_ff @(posedge nvp_aclk_probe)
    nvp_aclk_probe_counter <= nvp_aclk_probe_counter + 1'b1;

  // Reuse XDMA's free-running 62.5 MHz application clock, exactly as the
  // accepted v40 design reused the PCIe support user clock.  Do not consume
  // IBUFDS_GTE2.ODIV2 with another BUFG: the earlier G0P8C3R1 matched A/B
  // experiment proved that topology blocks the dedicated O -> CPLLPD-BUFG
  // route.  NVP reset remains independent of link-up and axi_aresetn.  The
  // 320-cycle POR preserves the accepted nominal 5.12 us duration.
  localparam integer NVP_AUTOINIT_CLK_HZ = 62500000;
  localparam integer NVP_POR_CYCLES = 320;
  logic [9:0] nvp_por_count = '0;
  logic nvp_por_reset = 1'b1;
  logic nvp_scl_i;
  logic nvp_sda_i;
  logic nvp_scl_oen;
  logic nvp_sda_oen;
  logic nvp_init_busy;
  logic nvp_init_done;
  logic nvp_init_error;
  logic [735:0] nvp_init_detail;

  always_ff @(posedge autonomous_clk) begin
    if (nvp_por_reset) begin
      if (nvp_por_count == NVP_POR_CYCLES-1)
        nvp_por_reset <= 1'b0;
      else
        nvp_por_count <= nvp_por_count + 1'b1;
    end
  end

  IOBUF NVP_SCL_IOBUF (
    .I(1'b0), .T(nvp_scl_oen), .O(nvp_scl_i), .IO(nvp_scl)
  );
  IOBUF NVP_SDA_IOBUF (
    .I(1'b0), .T(nvp_sda_oen), .O(nvp_sda_i), .IO(nvp_sda)
  );

  v40a_nvp_autoinit #(
    .CLK_HZ(NVP_AUTOINIT_CLK_HZ), .I2C_HZ(50000),
    .ENABLE_MAREK_INIT_TABLE(ENABLE_MAREK_INIT_TABLE)
  ) NVP_AUTOINIT (
    .clk(autonomous_clk), .rst(nvp_por_reset),
    .scl_i(nvp_scl_i), .sda_i(nvp_sda_i),
    .scl_oen(nvp_scl_oen), .sda_oen(nvp_sda_oen),
    .nvp_rst(nvp_rst), .nvp_en_vdd1x(nvp_en_vdd1x),
    .nvp_en_vdd3x(nvp_en_vdd3x), .init_busy(nvp_init_busy),
    .init_done(nvp_init_done), .init_error(nvp_init_error),
    .diag_detail(nvp_init_detail)
  );

  // Keep one source flop per asynchronous-reset synchronizer.  If these three
  // logically identical registers are merged, one launch flop fans out into
  // multiple independent reset synchronizers and report_cdc correctly raises
  // CDC-11.  Keeping the sources distinct preserves the intended one-to-one
  // assertion-async/release-sync topology.
  (* DONT_TOUCH = "TRUE" *) logic nvp_reset_frontend_autonomous = 1'b1;
  (* DONT_TOUCH = "TRUE" *) logic nvp_reset_ready_autonomous = 1'b1;
  (* DONT_TOUCH = "TRUE" *) logic nvp_reset_app_autonomous = 1'b1;
  always_ff @(posedge autonomous_clk) begin
    nvp_reset_frontend_autonomous <= ~nvp_init_done | nvp_init_error;
    nvp_reset_ready_autonomous <= ~nvp_init_done | nvp_init_error;
    nvp_reset_app_autonomous <= ~nvp_init_done | nvp_init_error;
  end

  wire nvp_clk;
  wire [7:0] nvp_data_byte;
  g0p8c3r1_physical_frontend NVP_PHYSICAL_FRONTEND (
    .vclk1(vclk1), .vdo1_data(vdo1_data),
    .ingress_reset(nvp_reset_frontend_autonomous),
    .nvp_clk(nvp_clk), .nvp_data_byte(nvp_data_byte)
  );

  (* ASYNC_REG = "TRUE" *) logic [1:0] nvp_ready_sync = '0;
  wire nvp_enable = nvp_ready_sync[1];
  always_ff @(posedge nvp_clk or posedge nvp_reset_ready_autonomous) begin
    if (nvp_reset_ready_autonomous)
      nvp_ready_sync <= '0;
    else
      nvp_ready_sync <= {nvp_ready_sync[0], 1'b1};
  end

  logic [31:0] vclk_edge_count_nvp = '0;
  (* DONT_TOUCH = "TRUE" *) logic [31:0] vclk_edge_gray_nvp = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] vclk_edge_gray_sync1_user = '0;
  (* ASYNC_REG = "TRUE" *) logic [31:0] vclk_edge_gray_sync2_user = '0;
  logic [31:0] vclk_edge_count_user;
  integer gray_bit;
  always_comb begin
    vclk_edge_count_user[31] = vclk_edge_gray_sync2_user[31];
    for (gray_bit = 30; gray_bit >= 0; gray_bit = gray_bit - 1)
      vclk_edge_count_user[gray_bit] = vclk_edge_count_user[gray_bit+1] ^
                                       vclk_edge_gray_sync2_user[gray_bit];
  end
  always_ff @(posedge nvp_clk) begin
    vclk_edge_count_nvp <= vclk_edge_count_nvp + 1'b1;
    vclk_edge_gray_nvp <= vclk_edge_count_nvp ^ (vclk_edge_count_nvp >> 1);
  end
  always_ff @(posedge axi_aclk) begin
    vclk_edge_gray_sync1_user <= vclk_edge_gray_nvp;
    vclk_edge_gray_sync2_user <= vclk_edge_gray_sync1_user;
  end

  // Autonomous initialization and AXI-Lite now share axi_aclk.  Keep one
  // explicit register stage for a stable telemetry snapshot; a CDC primitive
  // here would be both redundant and misleading.
  logic [737:0] nvp_diag_axi = '0;
  always_ff @(posedge axi_aclk)
    nvp_diag_axi <= {nvp_init_detail, nvp_init_error, nvp_init_done};

  wire [31:0] m_axil_awaddr;
  wire [2:0]  m_axil_awprot;
  wire        m_axil_awvalid;
  wire        m_axil_awready;
  wire [31:0] m_axil_wdata;
  wire [3:0]  m_axil_wstrb;
  wire        m_axil_wvalid;
  wire        m_axil_wready;
  wire [1:0]  m_axil_bresp;
  wire        m_axil_bvalid;
  wire        m_axil_bready;
  wire [31:0] m_axil_araddr;
  wire [2:0]  m_axil_arprot;
  wire        m_axil_arvalid;
  wire        m_axil_arready;
  wire [31:0] m_axil_rdata;
  wire [1:0]  m_axil_rresp;
  wire        m_axil_rvalid;
  wire        m_axil_rready;

  wire host_req_valid;
  wire host_req_ready;
  wire host_req_write;
  wire [16:0] host_req_addr;
  wire [31:0] host_req_wdata;
  wire [3:0] host_req_be;
  wire host_rsp_valid;
  wire host_rsp_ready;
  wire [31:0] host_rsp_rdata;

  wire app_req_valid;
  wire app_req_ready;
  wire app_req_write;
  wire [16:0] app_req_addr;
  wire [31:0] app_req_wdata;
  wire [3:0] app_req_be;
  wire app_rsp_valid;
  wire app_rsp_ready;
  wire [31:0] app_rsp_rdata;

  wire telemetry_capture_request_busy;
  wire telemetry_capture_busy;
  wire telemetry_capture_armed;
  wire telemetry_capture_done;
  wire telemetry_capture_aborted;
  wire [31:0] telemetry_capture_generation;
  wire [31:0] telemetry_captured_line_count;
  wire [31:0] telemetry_first_source_line;
  wire [31:0] telemetry_frame_sequence;
  wire [31:0] telemetry_bad_marker_count;
  wire [31:0] telemetry_bad_length_count;
  wire [31:0] telemetry_capture_overflow_count;
  wire [31:0] telemetry_malformed_count;
  wire [31:0] telemetry_capture_dropped_count;
  wire [31:0] telemetry_arm_rejected_count;
  wire [31:0] telemetry_mailbox_rejected_count;
  wire [31:0] telemetry_active_sav_count;
  wire [31:0] telemetry_record_commit_count;

  v41_axi_lite_host_bridge AXI_LITE_HOST_BRIDGE (
    .clk(axi_aclk), .reset(~axi_aresetn),
    .s_axi_awaddr(m_axil_awaddr), .s_axi_awprot(m_axil_awprot),
    .s_axi_awvalid(m_axil_awvalid), .s_axi_awready(m_axil_awready),
    .s_axi_wdata(m_axil_wdata), .s_axi_wstrb(m_axil_wstrb),
    .s_axi_wvalid(m_axil_wvalid), .s_axi_wready(m_axil_wready),
    .s_axi_bresp(m_axil_bresp), .s_axi_bvalid(m_axil_bvalid),
    .s_axi_bready(m_axil_bready),
    .s_axi_araddr(m_axil_araddr), .s_axi_arprot(m_axil_arprot),
    .s_axi_arvalid(m_axil_arvalid), .s_axi_arready(m_axil_arready),
    .s_axi_rdata(m_axil_rdata), .s_axi_rresp(m_axil_rresp),
    .s_axi_rvalid(m_axil_rvalid), .s_axi_rready(m_axil_rready),
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata)
  );

  v41_control_status_regs #(
    .BLOCK_ID(BLOCK_OR_FW_ID),
    .GIT_SHA_W0(GIT_SHA_W0), .GIT_SHA_W1(GIT_SHA_W1),
    .GIT_SHA_W2(GIT_SHA_W2), .GIT_SHA_W3(GIT_SHA_W3),
    .GIT_SHA_W4(GIT_SHA_W4), .BUILD_FLAGS(BUILD_FLAGS)
  ) CONTROL_STATUS_REGS (
    .clk(axi_aclk), .reset(~axi_aresetn),
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata),
    .app_req_valid(app_req_valid), .app_req_ready(app_req_ready),
    .app_req_write(app_req_write), .app_req_addr(app_req_addr),
    .app_req_wdata(app_req_wdata), .app_req_be(app_req_be),
    .app_rsp_valid(app_rsp_valid), .app_rsp_ready(app_rsp_ready),
    .app_rsp_rdata(app_rsp_rdata),
    .capture_request_busy(telemetry_capture_request_busy),
    .capture_busy(telemetry_capture_busy),
    .capture_armed(telemetry_capture_armed),
    .capture_done(telemetry_capture_done),
    .capture_aborted(telemetry_capture_aborted),
    .capture_generation(telemetry_capture_generation),
    .captured_line_count(telemetry_captured_line_count),
    .first_source_line(telemetry_first_source_line),
    .frame_sequence(telemetry_frame_sequence),
    .bad_marker_count(telemetry_bad_marker_count),
    .bad_length_count(telemetry_bad_length_count),
    .capture_overflow_count(telemetry_capture_overflow_count),
    .malformed_count(telemetry_malformed_count),
    .capture_dropped_count(telemetry_capture_dropped_count),
    .arm_rejected_count(telemetry_arm_rejected_count),
    .mailbox_rejected_count(telemetry_mailbox_rejected_count),
    .vclk_edge_count(vclk_edge_count_user),
    .active_sav_count(telemetry_active_sav_count),
    .record_commit_count(telemetry_record_commit_count),
    .nvp_init_busy(nvp_init_busy), .nvp_init_done(nvp_diag_axi[0]),
    .nvp_init_error(nvp_diag_axi[1]), .nvp_reset_released(nvp_rst),
    .nvp_vdd1x_active(nvp_en_vdd1x), .nvp_vdd3x_active(nvp_en_vdd3x),
    .nvp_scl_sample(nvp_scl_i), .nvp_sda_sample(nvp_sda_i),
    .nvp_detail(nvp_diag_axi[193:2]),
    .dma_status(32'b0), .records_streamed(32'b0),
    .dropped_records(32'b0), .c2h_stall_cycles(64'b0),
    .last_streamed_capture_sequence(32'b0),
    .stream_protocol_errors(32'b0), .user_irq_count(32'b0),
    .h2c_attempt_count(32'b0)
  );

  wire bar_target_reset;
  g0p8c2_capture_subsystem #(
    .SLOT_COUNT(SLOT_COUNT), .BLOCK_OR_FW_ID(BLOCK_OR_FW_ID)
  ) CAPTURE_SUBSYSTEM (
    .nvp_clk(nvp_clk), .nvp_reset(nvp_reset_app_autonomous),
    .enable_vdo(nvp_enable), .data_byte(nvp_data_byte),
    .diag_last_memwr_addr('0), .diag_last_memwr_raw_data('0),
    .diag_last_memwr_logical_data('0),
    .diag_vclk_edge_count(vclk_edge_count_user),
    .diag_nvp_autoinit_done(nvp_diag_axi[0]),
    .diag_nvp_autoinit_error(nvp_diag_axi[1]),
    .diag_nvp_autoinit_detail(nvp_diag_axi[737:2]),
    .pcie_user_clk(axi_aclk), .pcie_user_reset(~axi_aresetn),
    .host_req_valid(app_req_valid), .host_req_ready(app_req_ready),
    .host_req_write(app_req_write), .host_req_addr(app_req_addr),
    .host_req_wdata(app_req_wdata), .host_req_be(app_req_be),
    .host_rsp_valid(app_rsp_valid), .host_rsp_ready(app_rsp_ready),
    .host_rsp_rdata(app_rsp_rdata), .debug_free_mask(),
    .debug_capture_busy(), .debug_write_slot(), .debug_write_address(),
    .debug_write_enable(), .debug_commit(),
    .bar_target_reset(bar_target_reset),
    .telemetry_capture_request_busy(telemetry_capture_request_busy),
    .telemetry_capture_busy(telemetry_capture_busy),
    .telemetry_capture_armed(telemetry_capture_armed),
    .telemetry_capture_done(telemetry_capture_done),
    .telemetry_capture_aborted(telemetry_capture_aborted),
    .telemetry_capture_generation(telemetry_capture_generation),
    .telemetry_captured_line_count(telemetry_captured_line_count),
    .telemetry_first_source_line(telemetry_first_source_line),
    .telemetry_frame_sequence(telemetry_frame_sequence),
    .telemetry_bad_marker_count(telemetry_bad_marker_count),
    .telemetry_bad_length_count(telemetry_bad_length_count),
    .telemetry_capture_overflow_count(telemetry_capture_overflow_count),
    .telemetry_malformed_count(telemetry_malformed_count),
    .telemetry_capture_dropped_count(telemetry_capture_dropped_count),
    .telemetry_arm_rejected_count(telemetry_arm_rejected_count),
    .telemetry_mailbox_rejected_count(telemetry_mailbox_rejected_count),
    .telemetry_active_sav_count(telemetry_active_sav_count),
    .telemetry_record_commit_count(telemetry_record_commit_count)
  );

  wire [31:0] cfg_mgmt_read_data;
  wire cfg_mgmt_read_write_done;
  wire [0:0] usr_irq_ack;
  wire msi_enable;
  wire [2:0] msi_vector_width;
  wire [63:0] h2c_tdata;
  wire h2c_tlast;
  wire h2c_tvalid;
  wire [7:0] h2c_tkeep;
  wire c2h_tready;

  xdma_v41_m1 XDMA (
    .sys_clk(pcie_refclk), .sys_rst_n(sys_rst_n_c),
    .user_lnk_up(user_lnk_up),
    .pci_exp_txp(pci_exp_txp), .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp), .pci_exp_rxn(pci_exp_rxn),
    .axi_aclk(axi_aclk), .axi_aresetn(axi_aresetn),
    .usr_irq_req(1'b0), .usr_irq_ack(usr_irq_ack),
    .msi_enable(msi_enable), .msi_vector_width(msi_vector_width),
    .m_axil_awaddr(m_axil_awaddr), .m_axil_awprot(m_axil_awprot),
    .m_axil_awvalid(m_axil_awvalid), .m_axil_awready(m_axil_awready),
    .m_axil_wdata(m_axil_wdata), .m_axil_wstrb(m_axil_wstrb),
    .m_axil_wvalid(m_axil_wvalid), .m_axil_wready(m_axil_wready),
    .m_axil_bvalid(m_axil_bvalid), .m_axil_bresp(m_axil_bresp),
    .m_axil_bready(m_axil_bready),
    .m_axil_araddr(m_axil_araddr), .m_axil_arprot(m_axil_arprot),
    .m_axil_arvalid(m_axil_arvalid), .m_axil_arready(m_axil_arready),
    .m_axil_rdata(m_axil_rdata), .m_axil_rresp(m_axil_rresp),
    .m_axil_rvalid(m_axil_rvalid), .m_axil_rready(m_axil_rready),
    .cfg_mgmt_addr(19'b0), .cfg_mgmt_write(1'b0),
    .cfg_mgmt_write_data(32'b0), .cfg_mgmt_byte_enable(4'b0),
    .cfg_mgmt_read(1'b0), .cfg_mgmt_read_data(cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
    .cfg_mgmt_type1_cfg_reg_access(1'b0),
    .s_axis_c2h_tdata_0(64'b0), .s_axis_c2h_tlast_0(1'b0),
    .s_axis_c2h_tvalid_0(1'b0), .s_axis_c2h_tready_0(c2h_tready),
    .s_axis_c2h_tkeep_0(8'b0),
    .m_axis_h2c_tdata_0(h2c_tdata), .m_axis_h2c_tlast_0(h2c_tlast),
    .m_axis_h2c_tvalid_0(h2c_tvalid), .m_axis_h2c_tready_0(1'b0),
    .m_axis_h2c_tkeep_0(h2c_tkeep)
  );

  // Make deliberate stage-boundary tie-offs explicit for structural audits.
  wire [119:0] unused_stage1_signals = {
    nvp_mpp, nvp_init_busy, bar_target_reset, user_lnk_up, usr_irq_ack,
    msi_enable, msi_vector_width, cfg_mgmt_read_data,
    cfg_mgmt_read_write_done, c2h_tready, h2c_tdata, h2c_tlast,
    h2c_tvalid, h2c_tkeep
  };
endmodule
