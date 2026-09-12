`timescale 1ns/1ps

// v41 integrated G2B top. The complete preserved NVP/video/capture application
// remains behind XDMA's AXI-Lite Master. G2B adds one private channel-0 C2H
// path at the accepted post-frontend byte-stream tap; the tool-mandated H2C
// channel has no consumer and remains permanently backpressured.
module ahd_capture_top_xdma #(
  parameter integer SLOT_COUNT = 2,
  parameter logic [31:0] BLOCK_OR_FW_ID = 32'hA40A0C07,
  parameter logic [31:0] GIT_SHA_W0 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W1 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W2 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W3 = 32'h00000000,
  parameter logic [31:0] GIT_SHA_W4 = 32'h00000000,
  parameter logic [31:0] BUILD_FLAGS = 32'h00000000,
  parameter integer ENABLE_MAREK_INIT_TABLE = 1,
  // 0 = PRODUCT, 1 = RESEARCH_DIAGNOSTIC.  This parameter selects only
  // observability islands; all R1i/NVP/video/G2B functional logic is common.
  parameter integer ENABLE_RTRACK_DIAGNOSTICS = 0,
  // Separate legacy NVP four-channel diagnostic profile.  PRODUCT and the
  // qualified R-track profile leave it absent.
  parameter integer ENABLE_NVP_VIDEO_DIAGNOSTIC = 0,
  // SCAN1-R1 is an independently selected, read-only ONESHOT profile.  The
  // default remains zero so PRODUCT elaboration is unchanged.
  parameter integer ENABLE_NVP_CAMERA_SCAN1 = 0,
  // Separately governed fixed-action executor.  It is legal only as an
  // extension of the SCAN1 profile; the PRODUCT default remains zero.
  parameter integer ENABLE_NVP_ACQ1_EXECUTOR = 0
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
  wire sys_rst_n_c;
  wire axi_aclk;
  wire axi_aresetn;
  wire user_lnk_up;
  wire autonomous_clk = axi_aclk;

  IBUF PCIE_PERST_IBUF (.I(sys_rst_n), .O(sys_rst_n_c));
  IBUFDS_GTE2 PCIE_REFCLK_IBUF (
    .I(sys_clk_p), .IB(sys_clk_n), .CEB(1'b0),
    .O(pcie_refclk), .ODIV2()
  );

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
  logic nvp_init_scl_release;
  logic nvp_init_sda_release;
  logic probe_scl_release;
  logic probe_sda_release;
  logic diag_scl_release;
  logic diag_sda_release;
  wire nvp_scl_oen = nvp_init_scl_release & probe_scl_release &
                      diag_scl_release;
  wire nvp_sda_oen = nvp_init_sda_release & probe_sda_release &
                      diag_sda_release;
  logic nvp_init_busy;
  logic nvp_init_done;
  logic nvp_init_error;
  logic [735:0] nvp_init_detail;
  logic [255:0] r1f_phase_counters;
  logic [127:0] r1f_transaction_counters;
  logic [15:0] r1f_transaction_serial_next;
  logic r1f_transaction_serial_overflow;
  logic r1f_failed_txn_record_valid;
  logic [191:0] r1f_failed_txn_record;
  logic [31:0] r1f_bank_invariant_check_count;
  logic [31:0] r1f_bank_invariant_error_count;
  logic [31:0] r1f_first_bank_invariant_error;
  logic [1023:0] r1i_poc_telemetry;

  logic diag_i2c_cmd_valid;
  logic diag_i2c_cmd_ready;
  logic diag_i2c_cmd_write;
  logic [7:0] diag_i2c_cmd_reg;
  logic [7:0] diag_i2c_cmd_wdata;
  logic diag_i2c_cmd_accepted;
  logic diag_i2c_busy;
  logic diag_i2c_done;
  logic diag_i2c_success;
  logic diag_i2c_timeout;
  logic [3:0] diag_i2c_error_cause;
  logic [7:0] diag_i2c_read_data;
  logic [31:0] diag_i2c_transaction_sequence;
  logic diag_i2c_bus_idle;

  initial begin
    if ((ENABLE_NVP_VIDEO_DIAGNOSTIC != 0) &&
        ((ENABLE_NVP_CAMERA_SCAN1 != 0) ||
         (ENABLE_NVP_ACQ1_EXECUTOR != 0)))
      $error("NVP diagnostic profiles must be mutually exclusive");
    if ((ENABLE_NVP_ACQ1_EXECUTOR != 0) &&
        (ENABLE_NVP_CAMERA_SCAN1 == 0))
      $error("ACQ1 executor requires the qualified SCAN1 profile");
    // Historical SCAN1-R1 exclusion assertion retained for inherited source
    // audit identity: ACQ1 executor is not implemented or authorized in SCAN1-R1
  end

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
    .CLK_HZ(NVP_AUTOINIT_CLK_HZ), .I2C_HZ(25000),
    .ENABLE_MAREK_INIT_TABLE(ENABLE_MAREK_INIT_TABLE)
  ) NVP_AUTOINIT (
    .clk(autonomous_clk), .rst(nvp_por_reset),
    .scl_i(nvp_scl_i), .sda_i(nvp_sda_i),
    .scl_oen(nvp_init_scl_release), .sda_oen(nvp_init_sda_release),
    .nvp_rst(nvp_rst), .nvp_en_vdd1x(nvp_en_vdd1x),
    .nvp_en_vdd3x(nvp_en_vdd3x), .init_busy(nvp_init_busy),
    .init_done(nvp_init_done), .init_error(nvp_init_error),
    .diag_detail(nvp_init_detail),
    .r1f_phase_counters(r1f_phase_counters),
    .r1f_transaction_counters(r1f_transaction_counters),
    .r1f_transaction_serial_next(r1f_transaction_serial_next),
    .r1f_transaction_serial_overflow(r1f_transaction_serial_overflow),
    .r1f_failed_txn_record_valid(r1f_failed_txn_record_valid),
    .r1f_failed_txn_record(r1f_failed_txn_record),
    .r1f_bank_invariant_check_count(r1f_bank_invariant_check_count),
    .r1f_bank_invariant_error_count(r1f_bank_invariant_error_count),
    .r1f_first_bank_invariant_error(r1f_first_bank_invariant_error),
    .r1i_poc_telemetry(r1i_poc_telemetry)
  );

  logic [47:0] lifecycle_freerun_count;
  logic [47:0] cnt_at_init_done;
  logic [47:0] cnt_at_first_user_lnk_up;
  logic [47:0] cnt_at_first_axi_aresetn_high;
  logic [47:0] cnt_at_first_axi_aresetn_low_after_high;
  logic [31:0] user_lnk_up_transition_count;
  logic [31:0] axi_aresetn_transition_count;
  logic [4:0] lifecycle_event_flags;

  generate
    if (ENABLE_RTRACK_DIAGNOSTICS != 0) begin : GEN_RTRACK_LIFECYCLE
      v41_axi_clock_lifecycle_monitor LIFECYCLE_MONITOR (
        .axi_aclk(axi_aclk), .nvp_init_done(nvp_init_done),
        .user_lnk_up(user_lnk_up), .axi_aresetn(axi_aresetn),
        .freerun_count(lifecycle_freerun_count),
        .cnt_at_init_done(cnt_at_init_done),
        .cnt_at_first_user_lnk_up(cnt_at_first_user_lnk_up),
        .cnt_at_first_axi_aresetn_high(cnt_at_first_axi_aresetn_high),
        .cnt_at_first_axi_aresetn_low_after_high(
          cnt_at_first_axi_aresetn_low_after_high),
        .user_lnk_up_transition_count(user_lnk_up_transition_count),
        .axi_aresetn_transition_count(axi_aresetn_transition_count),
        .event_flags(lifecycle_event_flags)
      );
    end else begin : GEN_PRODUCT_NO_LIFECYCLE
      assign lifecycle_freerun_count = 48'b0;
      assign cnt_at_init_done = 48'b0;
      assign cnt_at_first_user_lnk_up = 48'b0;
      assign cnt_at_first_axi_aresetn_high = 48'b0;
      assign cnt_at_first_axi_aresetn_low_after_high = 48'b0;
      assign user_lnk_up_transition_count = 32'b0;
      assign axi_aresetn_transition_count = 32'b0;
      assign lifecycle_event_flags = 5'b0;
    end
  endgenerate

  wire [31:0] probe_count;
  wire [31:0] probe_ack_count;
  wire [31:0] probe_nack_count;
  wire [31:0] probe_timeout_count;
  logic [31:0] probe_status;
  wire [31:0] probe_first_nack_index;
  wire [31:0] probe_last_nack_index;
  wire [31:0] probe_max_consecutive_nacks;
  logic [47:0] probe_start_freerun;
  logic [47:0] probe_done_freerun;
  logic tri_probe_active, tri_probe_done, tri_probe_aborted;
  logic tri_probe_terminal;
  logic [7:0] tri_probe_abort_code;
  logic [7:0] tri_probe_restore_failure_code;
  logic [31:0] tri_probe_native_status;
  logic tri_legacy_init_done_seen, tri_legacy_guard_complete;
  logic tri_legacy_bus_idle_qualified, tri_legacy_scl_timeout;
  logic tri_legacy_bus_idle_timeout;
  logic [7:0] tri_entry_bank;
  logic tri_entry_bank_valid;
  logic tri_safe_bank_select_write_ok, tri_safe_bank_verify_ok;
  logic [7:0] tri_safe_bank_readback;
  logic tri_safe_bank_readback_valid;
  logic [7:0] tri_safe_target_pre_value, tri_safe_target_post_value;
  logic tri_safe_target_pre_valid, tri_safe_target_post_valid;
  logic tri_safe_target_pre_ok, tri_safe_target_post_ok;
  logic tri_original_bank_restored, tri_original_bank_restore_verified;
  logic [7:0] tri_restored_bank_readback;
  logic tri_restored_bank_readback_valid;
  logic tri_final_bus_idle;

  logic [31:0] tri_waddr_transaction_attempts;
  logic [31:0] tri_waddr_target_opportunities;
  logic [31:0] tri_waddr_target_acks, tri_waddr_target_nacks;
  logic [31:0] tri_waddr_timeouts;
  logic [15:0] tri_waddr_first_nack_index, tri_waddr_last_nack_index;
  logic [31:0] tri_waddr_max_consecutive_nacks;
  logic [31:0] tri_waddr_adjacent_nack_pairs, tri_waddr_run_count;

  logic [31:0] tri_regaddr_transaction_attempts;
  logic [31:0] tri_regaddr_prereq_waddr_opportunities;
  logic [31:0] tri_regaddr_prereq_waddr_acks;
  logic [31:0] tri_regaddr_prereq_waddr_nacks;
  logic [31:0] tri_regaddr_target_opportunities;
  logic [31:0] tri_regaddr_target_acks, tri_regaddr_target_nacks;
  logic [31:0] tri_regaddr_timeouts;
  logic [15:0] tri_regaddr_first_nack_index, tri_regaddr_last_nack_index;
  logic [31:0] tri_regaddr_max_consecutive_nacks;
  logic [31:0] tri_regaddr_adjacent_nack_pairs, tri_regaddr_run_count;

  logic [31:0] tri_data_transaction_attempts;
  logic [31:0] tri_data_prereq_waddr_opportunities;
  logic [31:0] tri_data_prereq_waddr_acks;
  logic [31:0] tri_data_prereq_waddr_nacks;
  logic [31:0] tri_data_prereq_regaddr_opportunities;
  logic [31:0] tri_data_prereq_regaddr_acks;
  logic [31:0] tri_data_prereq_regaddr_nacks;
  logic [31:0] tri_data_target_opportunities;
  logic [31:0] tri_data_target_acks, tri_data_target_nacks;
  logic [31:0] tri_data_timeouts;
  logic [15:0] tri_data_first_nack_index, tri_data_last_nack_index;
  logic [31:0] tri_data_max_consecutive_nacks;
  logic [31:0] tri_data_adjacent_nack_pairs, tri_data_run_count;

  logic [31:0] tri_probe_timeout_count_total;
  logic [15:0] tri_waddr_index_stored_count;
  logic [15:0] tri_regaddr_index_stored_count;
  logic [15:0] tri_data_index_stored_count;
  logic tri_waddr_index_overflow, tri_regaddr_index_overflow;
  logic tri_data_index_overflow;
  logic tri_index_read_req;
  logic [1:0] tri_index_read_phase;
  logic [8:0] tri_index_read_address;
  logic tri_index_read_valid;
  logic [15:0] tri_index_read_data;
  logic [1:0] tri_block_read_phase;
  logic [3:0] tri_block_read_index;
  logic [31:0] tri_block_read_nack_count;
  logic [31:0] tri_round_robin_scheduler_rounds;
  logic [1:0] tri_current_scheduler_phase;
  logic [2:0] tri_attempt_limit_status;

  generate
    if (ENABLE_RTRACK_DIAGNOSTICS != 0) begin : GEN_RTRACK_TRI_PHASE_PROBE
      nvp_i2c_tri_phase_probe #(
        .CLK_HZ(NVP_AUTOINIT_CLK_HZ), .PROBE_I2C_HZ(25000),
        .TARGET_OPPORTUNITIES_PER_PHASE(10000), .BLOCK_COUNT_PER_PHASE(10),
        .NACK_INDEX_CAPACITY_PER_PHASE(512),
        .MAX_TRANSACTION_ATTEMPTS_PER_PHASE(12000),
        .POST_INIT_GUARD_CYCLES(62500)
      ) POST_INIT_TRI_PHASE_PROBE (
    .clk(autonomous_clk), .rst(nvp_por_reset),
    .init_done(nvp_init_done), .init_busy(nvp_init_busy), .nvp_rst(nvp_rst),
    .init_scl_release(nvp_init_scl_release),
    .init_sda_release(nvp_init_sda_release),
    .raw_scl_i(nvp_scl_i), .raw_sda_i(nvp_sda_i),
    .freerun_count(lifecycle_freerun_count),
    .probe_scl_release(probe_scl_release),
    .probe_sda_release(probe_sda_release),
    .probe_active(tri_probe_active), .probe_done(tri_probe_done),
    .probe_aborted(tri_probe_aborted), .probe_terminal(tri_probe_terminal),
    .probe_abort_code(tri_probe_abort_code),
    .probe_restore_failure_code(tri_probe_restore_failure_code),
    .probe_status(tri_probe_native_status),
    .legacy_init_done_seen(tri_legacy_init_done_seen),
    .legacy_guard_complete(tri_legacy_guard_complete),
    .legacy_bus_idle_qualified(tri_legacy_bus_idle_qualified),
    .legacy_scl_timeout(tri_legacy_scl_timeout),
    .legacy_bus_idle_timeout(tri_legacy_bus_idle_timeout),
    .probe_start_freerun(probe_start_freerun),
    .probe_done_freerun(probe_done_freerun),
    .entry_bank(tri_entry_bank), .entry_bank_valid(tri_entry_bank_valid),
    .safe_bank_select_write_ok(tri_safe_bank_select_write_ok),
    .safe_bank_verify_ok(tri_safe_bank_verify_ok),
    .safe_bank_readback(tri_safe_bank_readback),
    .safe_bank_readback_valid(tri_safe_bank_readback_valid),
    .safe_target_pre_value(tri_safe_target_pre_value),
    .safe_target_pre_valid(tri_safe_target_pre_valid),
    .safe_target_pre_ok(tri_safe_target_pre_ok),
    .safe_target_post_value(tri_safe_target_post_value),
    .safe_target_post_valid(tri_safe_target_post_valid),
    .safe_target_post_ok(tri_safe_target_post_ok),
    .original_bank_restored(tri_original_bank_restored),
    .original_bank_restore_verified(tri_original_bank_restore_verified),
    .restored_bank_readback(tri_restored_bank_readback),
    .restored_bank_readback_valid(tri_restored_bank_readback_valid),
    .final_bus_idle(tri_final_bus_idle),
    .waddr_transaction_attempts(tri_waddr_transaction_attempts),
    .waddr_target_opportunities(tri_waddr_target_opportunities),
    .waddr_target_acks(tri_waddr_target_acks),
    .waddr_target_nacks(tri_waddr_target_nacks),
    .waddr_timeouts(tri_waddr_timeouts),
    .waddr_first_nack_index(tri_waddr_first_nack_index),
    .waddr_last_nack_index(tri_waddr_last_nack_index),
    .waddr_max_consecutive_nacks(tri_waddr_max_consecutive_nacks),
    .waddr_adjacent_nack_pairs(tri_waddr_adjacent_nack_pairs),
    .waddr_run_count(tri_waddr_run_count),
    .regaddr_transaction_attempts(tri_regaddr_transaction_attempts),
    .regaddr_prereq_waddr_opportunities(
      tri_regaddr_prereq_waddr_opportunities),
    .regaddr_prereq_waddr_acks(tri_regaddr_prereq_waddr_acks),
    .regaddr_prereq_waddr_nacks(tri_regaddr_prereq_waddr_nacks),
    .regaddr_target_opportunities(tri_regaddr_target_opportunities),
    .regaddr_target_acks(tri_regaddr_target_acks),
    .regaddr_target_nacks(tri_regaddr_target_nacks),
    .regaddr_timeouts(tri_regaddr_timeouts),
    .regaddr_first_nack_index(tri_regaddr_first_nack_index),
    .regaddr_last_nack_index(tri_regaddr_last_nack_index),
    .regaddr_max_consecutive_nacks(tri_regaddr_max_consecutive_nacks),
    .regaddr_adjacent_nack_pairs(tri_regaddr_adjacent_nack_pairs),
    .regaddr_run_count(tri_regaddr_run_count),
    .data_transaction_attempts(tri_data_transaction_attempts),
    .data_prereq_waddr_opportunities(tri_data_prereq_waddr_opportunities),
    .data_prereq_waddr_acks(tri_data_prereq_waddr_acks),
    .data_prereq_waddr_nacks(tri_data_prereq_waddr_nacks),
    .data_prereq_regaddr_opportunities(tri_data_prereq_regaddr_opportunities),
    .data_prereq_regaddr_acks(tri_data_prereq_regaddr_acks),
    .data_prereq_regaddr_nacks(tri_data_prereq_regaddr_nacks),
    .data_target_opportunities(tri_data_target_opportunities),
    .data_target_acks(tri_data_target_acks),
    .data_target_nacks(tri_data_target_nacks),
    .data_timeouts(tri_data_timeouts),
    .data_first_nack_index(tri_data_first_nack_index),
    .data_last_nack_index(tri_data_last_nack_index),
    .data_max_consecutive_nacks(tri_data_max_consecutive_nacks),
    .data_adjacent_nack_pairs(tri_data_adjacent_nack_pairs),
    .data_run_count(tri_data_run_count),
    .probe_timeout_count_total(tri_probe_timeout_count_total),
    .waddr_nack_index_stored_count(tri_waddr_index_stored_count),
    .regaddr_nack_index_stored_count(tri_regaddr_index_stored_count),
    .data_nack_index_stored_count(tri_data_index_stored_count),
    .waddr_nack_index_overflow(tri_waddr_index_overflow),
    .regaddr_nack_index_overflow(tri_regaddr_index_overflow),
    .data_nack_index_overflow(tri_data_index_overflow),
    .index_read_req(tri_index_read_req),
    .index_read_phase(tri_index_read_phase),
    .index_read_address(tri_index_read_address),
    .index_read_valid(tri_index_read_valid),
    .index_read_data(tri_index_read_data),
    .block_read_phase(tri_block_read_phase),
    .block_read_index(tri_block_read_index),
    .block_read_nack_count(tri_block_read_nack_count),
    .round_robin_scheduler_rounds(tri_round_robin_scheduler_rounds),
    .current_scheduler_phase(tri_current_scheduler_phase),
        .attempt_limit_status(tri_attempt_limit_status)
      );
    end else begin : GEN_PRODUCT_NO_TRI_PHASE_PROBE
      // The removed research master contributes only released open-drain
      // drivers.  The qualified R1i initializer remains the sole bus driver.
      assign probe_scl_release = 1'b1;
      assign probe_sda_release = 1'b1;
    end
  endgenerate

  generate
    if (ENABLE_NVP_VIDEO_DIAGNOSTIC != 0 ||
        ENABLE_NVP_CAMERA_SCAN1 != 0) begin : GEN_NVP_DIAGNOSTIC_I2C
      nvp_i2c_fixed_master #(
        .CLK_HZ(NVP_AUTOINIT_CLK_HZ), .I2C_HZ(25000)
      ) NVP_DIAGNOSTIC_I2C_MASTER (
        .clk(autonomous_clk), .rst(nvp_por_reset || !axi_aresetn),
        .raw_scl_i(nvp_scl_i), .raw_sda_i(nvp_sda_i),
        .cmd_valid(diag_i2c_cmd_valid), .cmd_ready(diag_i2c_cmd_ready),
        .cmd_write(diag_i2c_cmd_write), .cmd_reg(diag_i2c_cmd_reg),
        .cmd_wdata(diag_i2c_cmd_wdata),
        .cmd_accepted(diag_i2c_cmd_accepted), .busy(diag_i2c_busy),
        .done(diag_i2c_done), .success(diag_i2c_success),
        .timeout(diag_i2c_timeout), .error_cause(diag_i2c_error_cause),
        .read_data(diag_i2c_read_data),
        .transaction_sequence(diag_i2c_transaction_sequence),
        .scl_release(diag_scl_release), .sda_release(diag_sda_release),
        .bus_idle(diag_i2c_bus_idle)
      );
    end else begin : GEN_NO_NVP_DIAGNOSTIC_I2C
      assign diag_scl_release = 1'b1;
      assign diag_sda_release = 1'b1;
      assign diag_i2c_cmd_ready = 1'b0;
      assign diag_i2c_cmd_accepted = 1'b0;
      assign diag_i2c_busy = 1'b0;
      assign diag_i2c_done = 1'b0;
      assign diag_i2c_success = 1'b0;
      assign diag_i2c_timeout = 1'b0;
      assign diag_i2c_error_cause = 4'b0;
      assign diag_i2c_read_data = 8'b0;
      assign diag_i2c_transaction_sequence = 32'b0;
      assign diag_i2c_bus_idle = nvp_scl_i && nvp_sda_i;
    end
  endgenerate

  // Preserve the R1e page offsets as a compatibility projection.  WADDR
  // target counters and zero-based NACK indices project into the legacy
  // fields.  Timestamps and terminal status cover the complete tri-phase
  // lifecycle; the timeout counter covers low-level setup/probe/restore I2C
  // transactions, while a high-level final-idle failure is an abort code.
  // Scientific R1f interpretation uses the versioned R1f page.
  assign probe_count = tri_waddr_target_opportunities;
  assign probe_ack_count = tri_waddr_target_acks;
  assign probe_nack_count = tri_waddr_target_nacks;
  assign probe_timeout_count = tri_probe_timeout_count_total;
  assign probe_first_nack_index = tri_waddr_target_nacks == 0 ?
                                  32'hffff_ffff :
                                  {16'b0, tri_waddr_first_nack_index};
  assign probe_last_nack_index = tri_waddr_target_nacks == 0 ?
                                 32'hffff_ffff :
                                 {16'b0, tri_waddr_last_nack_index};
  assign probe_max_consecutive_nacks = tri_waddr_max_consecutive_nacks;
  always_comb begin
    probe_status = 32'b0;
    // R1e DONE is terminal-on-success-or-abort; R1f keeps the separate
    // success-only tri_probe_done in its versioned page.
    probe_status[0] = tri_probe_terminal;
    probe_status[1] = tri_probe_aborted;
    probe_status[2] = tri_probe_active;
    probe_status[3] = tri_legacy_guard_complete;
    probe_status[4] = tri_legacy_bus_idle_qualified;
    probe_status[5] = tri_legacy_init_done_seen;
    probe_status[6] = tri_legacy_scl_timeout;
    probe_status[7] = tri_legacy_bus_idle_timeout;
    probe_status[8] = 1'b1;
    probe_status[9] = probe_scl_release && probe_sda_release;
  end

  logic [5:0] r1f_record_read_index;
  logic [2:0] r1f_record_read_word;
  logic [5:0] r1f_record_decode_index;
  logic [2:0] r1f_record_decode_word;
  logic r1f_record_read_select;
  logic r1f_record_read_enable;
  logic r1f_record_read_valid;
  logic [31:0] r1f_record_read_data;
  logic [31:0] r1f_failed_txn_total_count;
  logic [6:0] r1f_failed_txn_stored_count;
  logic r1f_failed_txn_overflow;
  logic [15:0] r1f_first_failed_txn_index;
  logic r1f_first_failed_txn_index_valid;
  logic [15:0] r1f_last_failed_txn_index;
  logic r1f_last_failed_txn_index_valid;
  logic r1f_failed_txn_total_count_saturated;
  logic r1f_failed_txn_input_protocol_error;

  generate
    if (ENABLE_RTRACK_DIAGNOSTICS != 0) begin : GEN_RTRACK_FAILED_HISTORY
      v41_r1f_failed_txn_logger R1F_FAILED_TXN_LOGGER (
        .clk(autonomous_clk), .reset(nvp_por_reset),
        .r1f_failed_txn_valid(r1f_failed_txn_record_valid),
        .r1f_failed_txn_record(r1f_failed_txn_record),
        .record_read_enable(r1f_record_read_enable),
        .record_read_index(r1f_record_read_index),
        .record_read_word(r1f_record_read_word),
        .record_read_valid(r1f_record_read_valid),
        .record_read_data(r1f_record_read_data),
        .total_count(r1f_failed_txn_total_count),
        .stored_count(r1f_failed_txn_stored_count),
        .overflow(r1f_failed_txn_overflow),
        .first_failed_txn_index(r1f_first_failed_txn_index),
        .first_failed_txn_index_valid(r1f_first_failed_txn_index_valid),
        .last_failed_txn_index(r1f_last_failed_txn_index),
        .last_failed_txn_index_valid(r1f_last_failed_txn_index_valid),
        .total_count_saturated(r1f_failed_txn_total_count_saturated),
        .input_protocol_error(r1f_failed_txn_input_protocol_error)
      );
    end else begin : GEN_PRODUCT_NO_FAILED_HISTORY
      assign r1f_record_read_valid = 1'b0;
      assign r1f_record_read_data = 32'b0;
      assign r1f_failed_txn_total_count = 32'b0;
      assign r1f_failed_txn_stored_count = 7'b0;
      assign r1f_failed_txn_overflow = 1'b0;
      assign r1f_first_failed_txn_index = 16'b0;
      assign r1f_first_failed_txn_index_valid = 1'b0;
      assign r1f_last_failed_txn_index = 16'b0;
      assign r1f_last_failed_txn_index_valid = 1'b0;
      assign r1f_failed_txn_total_count_saturated = 1'b0;
      assign r1f_failed_txn_input_protocol_error = 1'b0;
    end
  endgenerate

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
  wire nvp_frontend_released;
  g0p8c3r1_physical_frontend NVP_PHYSICAL_FRONTEND (
    .vclk1(vclk1), .vdo1_data(vdo1_data),
    .ingress_reset(nvp_reset_frontend_autonomous),
    .nvp_clk(nvp_clk), .nvp_data_byte(nvp_data_byte),
    .frontend_released(nvp_frontend_released)
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
  generate
    if (ENABLE_RTRACK_DIAGNOSTICS != 0) begin : GEN_RTRACK_NVP_SNAPSHOT
      always_ff @(posedge axi_aclk)
        nvp_diag_axi <= {nvp_init_detail, nvp_init_error, nvp_init_done};
    end else begin : GEN_PRODUCT_NVP_SNAPSHOT
      // D0..D5 and compact bank-safety state remain visible.  The rest of the
      // D1 research extension, including its count/capacity header, reads as a
      // self-consistent absent feature.
      always_ff @(posedge axi_aclk)
        nvp_diag_axi <= {520'b0, nvp_init_detail[215:208], 10'b0,
                         nvp_init_detail[197], 5'b0, nvp_init_detail[191:0],
                         nvp_init_error, nvp_init_done};
    end
  endgenerate

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

  wire legacy_host_req_valid;
  wire legacy_host_req_ready;
  wire legacy_host_req_write;
  wire [16:0] legacy_host_req_addr;
  wire [31:0] legacy_host_req_wdata;
  wire [3:0] legacy_host_req_be;
  wire legacy_host_rsp_valid;
  wire legacy_host_rsp_ready;
  wire [31:0] legacy_host_rsp_rdata;

  wire product_legacy_req_valid;
  wire product_legacy_req_ready;
  wire product_legacy_req_write;
  wire [16:0] product_legacy_req_addr;
  wire [31:0] product_legacy_req_wdata;
  wire [3:0] product_legacy_req_be;
  wire product_legacy_rsp_valid;
  wire product_legacy_rsp_ready;
  wire [31:0] product_legacy_rsp_rdata;

  wire nvp_diag_req_valid;
  wire nvp_diag_req_ready;
  wire nvp_diag_rsp_valid;
  wire nvp_diag_rsp_ready;
  wire [31:0] nvp_diag_rsp_rdata;
  wire legacy_nvp_diag_select = ENABLE_NVP_VIDEO_DIAGNOSTIC != 0 &&
                                legacy_host_req_addr >= 17'h03c00 &&
                                legacy_host_req_addr <= 17'h03fff;
  wire scan1_nvp_diag_select = ENABLE_NVP_CAMERA_SCAN1 != 0 &&
                               legacy_host_req_addr >= 17'h12000 &&
                               legacy_host_req_addr <= 17'h123ff;
  wire acq1_nvp_diag_select = ENABLE_NVP_ACQ1_EXECUTOR != 0 &&
                              legacy_host_req_addr >= 17'h12400 &&
                              legacy_host_req_addr <= 17'h127ff;
  wire nvp_diag_select = legacy_nvp_diag_select || scan1_nvp_diag_select ||
                         acq1_nvp_diag_select;

  wire diag_transport_stored_enable;
  wire diag_transport_c2h_active;
  wire diag_transport_ring_empty;
  wire diag_transport_ring_full;
  wire diag_i2c_owns_bus;
  wire diag_capture_ready;
  wire [15:0] diag_current_session_id;
  wire [2:0] diag_current_round;
  wire [2:0] diag_current_channel;
  wire diag_product_baseline_restored;
  wire scan1_bank_context_lockout;
  wire scan1_busy;
  wire scan1_done;
  wire acq1_executor_busy;
  wire acq1_executor_done;

  wire g2b_req_valid;
  wire g2b_req_ready;
  wire g2b_req_write;
  wire [16:0] g2b_req_addr;
  wire [31:0] g2b_req_wdata;
  wire [3:0] g2b_req_be;
  wire g2b_rsp_valid;
  wire g2b_rsp_ready;
  wire [31:0] g2b_rsp_rdata;

  wire [63:0] g2b_c2h_tdata;
  wire [7:0] g2b_c2h_tkeep;
  wire g2b_c2h_tlast;
  wire g2b_c2h_tvalid;
  wire g2b_c2h_tready;

  wire app_req_valid;
  wire app_req_ready;
  wire app_req_write;
  wire [16:0] app_req_addr;
  wire [31:0] app_req_wdata;
  wire [3:0] app_req_be;
  wire app_rsp_valid;
  wire app_rsp_ready;
  wire [31:0] app_rsp_rdata;
  logic [31:0] measurement_read_data;
  logic [31:0] r1f_read_data;
  logic [31:0] r1i_scalar_read_data;
  logic r1h_req_valid;
  logic r1h_req_ready;
  logic [13:0] r1h_req_offset;
  logic r1h_rsp_valid;
  logic r1h_rsp_ready;
  logic [31:0] r1h_rsp_data;
  logic [6:0] r1f_probe_detail_read_word;
  logic r1f_probe_detail_read_select;
  logic [31:0] r1f_probe_detail_read_data;
  logic [1:0] r1f_probe_index_read_phase;
  logic [7:0] r1f_probe_index_read_word;
  logic r1f_probe_index_read_select;
  logic [31:0] r1f_tri_phase_probe_status;
  logic [31:0] r1f_probe_setup_restore_status;

  logic [31:0] r1f_detail_attempts [0:2];
  logic [31:0] r1f_detail_prereq_waddr_opportunities [0:2];
  logic [31:0] r1f_detail_prereq_waddr_acks [0:2];
  logic [31:0] r1f_detail_prereq_waddr_nacks [0:2];
  logic [31:0] r1f_detail_prereq_regaddr_opportunities [0:2];
  logic [31:0] r1f_detail_prereq_regaddr_acks [0:2];
  logic [31:0] r1f_detail_prereq_regaddr_nacks [0:2];
  logic [31:0] r1f_detail_target_opportunities [0:2];
  logic [31:0] r1f_detail_target_acks [0:2];
  logic [31:0] r1f_detail_target_nacks [0:2];
  logic [31:0] r1f_detail_timeouts [0:2];
  logic [31:0] r1f_detail_first_nack_index [0:2];
  logic [31:0] r1f_detail_last_nack_index [0:2];
  logic [31:0] r1f_detail_max_consecutive_nacks [0:2];
  logic [31:0] r1f_detail_adjacent_nack_pairs [0:2];
  logic [31:0] r1f_detail_run_count [0:2];
  logic [31:0] r1f_detail_index_stored_count [0:2];
  logic r1f_detail_index_overflow [0:2];

  function automatic [31:0] r1f_phase_probe_status_word(
    input [31:0] target_opportunities,
    input [31:0] target_nacks,
    input [31:0] attempts,
    input        index_overflow
  );
    begin
      r1f_phase_probe_status_word = 32'b0;
      r1f_phase_probe_status_word[0] = 1'b1;
      r1f_phase_probe_status_word[1] =
          target_opportunities == 32'd10000;
      r1f_phase_probe_status_word[2] =
          target_opportunities == 32'd10000;
      r1f_phase_probe_status_word[3] = target_nacks != 0;
      r1f_phase_probe_status_word[4] = target_nacks != 0;
      r1f_phase_probe_status_word[5] = index_overflow;
      r1f_phase_probe_status_word[6] = 1'b0;
      r1f_phase_probe_status_word[7] = attempts >= 32'd12000 &&
                                             target_opportunities < 32'd10000;
    end
  endfunction

  assign r1f_detail_attempts[0] = tri_waddr_transaction_attempts;
  assign r1f_detail_attempts[1] = tri_regaddr_transaction_attempts;
  assign r1f_detail_attempts[2] = tri_data_transaction_attempts;
  assign r1f_detail_prereq_waddr_opportunities[0] = 32'b0;
  assign r1f_detail_prereq_waddr_opportunities[1] =
      tri_regaddr_prereq_waddr_opportunities;
  assign r1f_detail_prereq_waddr_opportunities[2] =
      tri_data_prereq_waddr_opportunities;
  assign r1f_detail_prereq_waddr_acks[0] = 32'b0;
  assign r1f_detail_prereq_waddr_acks[1] = tri_regaddr_prereq_waddr_acks;
  assign r1f_detail_prereq_waddr_acks[2] = tri_data_prereq_waddr_acks;
  assign r1f_detail_prereq_waddr_nacks[0] = 32'b0;
  assign r1f_detail_prereq_waddr_nacks[1] = tri_regaddr_prereq_waddr_nacks;
  assign r1f_detail_prereq_waddr_nacks[2] = tri_data_prereq_waddr_nacks;
  assign r1f_detail_prereq_regaddr_opportunities[0] = 32'b0;
  assign r1f_detail_prereq_regaddr_opportunities[1] = 32'b0;
  assign r1f_detail_prereq_regaddr_opportunities[2] =
      tri_data_prereq_regaddr_opportunities;
  assign r1f_detail_prereq_regaddr_acks[0] = 32'b0;
  assign r1f_detail_prereq_regaddr_acks[1] = 32'b0;
  assign r1f_detail_prereq_regaddr_acks[2] = tri_data_prereq_regaddr_acks;
  assign r1f_detail_prereq_regaddr_nacks[0] = 32'b0;
  assign r1f_detail_prereq_regaddr_nacks[1] = 32'b0;
  assign r1f_detail_prereq_regaddr_nacks[2] = tri_data_prereq_regaddr_nacks;
  assign r1f_detail_target_opportunities[0] = tri_waddr_target_opportunities;
  assign r1f_detail_target_opportunities[1] = tri_regaddr_target_opportunities;
  assign r1f_detail_target_opportunities[2] = tri_data_target_opportunities;
  assign r1f_detail_target_acks[0] = tri_waddr_target_acks;
  assign r1f_detail_target_acks[1] = tri_regaddr_target_acks;
  assign r1f_detail_target_acks[2] = tri_data_target_acks;
  assign r1f_detail_target_nacks[0] = tri_waddr_target_nacks;
  assign r1f_detail_target_nacks[1] = tri_regaddr_target_nacks;
  assign r1f_detail_target_nacks[2] = tri_data_target_nacks;
  assign r1f_detail_timeouts[0] = tri_waddr_timeouts;
  assign r1f_detail_timeouts[1] = tri_regaddr_timeouts;
  assign r1f_detail_timeouts[2] = tri_data_timeouts;
  assign r1f_detail_first_nack_index[0] = tri_waddr_target_nacks == 0 ?
      32'b0 : {16'b0, tri_waddr_first_nack_index};
  assign r1f_detail_first_nack_index[1] = tri_regaddr_target_nacks == 0 ?
      32'b0 : {16'b0, tri_regaddr_first_nack_index};
  assign r1f_detail_first_nack_index[2] = tri_data_target_nacks == 0 ?
      32'b0 : {16'b0, tri_data_first_nack_index};
  assign r1f_detail_last_nack_index[0] = tri_waddr_target_nacks == 0 ?
      32'b0 : {16'b0, tri_waddr_last_nack_index};
  assign r1f_detail_last_nack_index[1] = tri_regaddr_target_nacks == 0 ?
      32'b0 : {16'b0, tri_regaddr_last_nack_index};
  assign r1f_detail_last_nack_index[2] = tri_data_target_nacks == 0 ?
      32'b0 : {16'b0, tri_data_last_nack_index};
  assign r1f_detail_max_consecutive_nacks[0] =
      tri_waddr_max_consecutive_nacks;
  assign r1f_detail_max_consecutive_nacks[1] =
      tri_regaddr_max_consecutive_nacks;
  assign r1f_detail_max_consecutive_nacks[2] =
      tri_data_max_consecutive_nacks;
  assign r1f_detail_adjacent_nack_pairs[0] = tri_waddr_adjacent_nack_pairs;
  assign r1f_detail_adjacent_nack_pairs[1] = tri_regaddr_adjacent_nack_pairs;
  assign r1f_detail_adjacent_nack_pairs[2] = tri_data_adjacent_nack_pairs;
  assign r1f_detail_run_count[0] = tri_waddr_run_count;
  assign r1f_detail_run_count[1] = tri_regaddr_run_count;
  assign r1f_detail_run_count[2] = tri_data_run_count;
  assign r1f_detail_index_stored_count[0] =
      {16'b0, tri_waddr_index_stored_count};
  assign r1f_detail_index_stored_count[1] =
      {16'b0, tri_regaddr_index_stored_count};
  assign r1f_detail_index_stored_count[2] =
      {16'b0, tri_data_index_stored_count};
  assign r1f_detail_index_overflow[0] = tri_waddr_index_overflow;
  assign r1f_detail_index_overflow[1] = tri_regaddr_index_overflow;
  assign r1f_detail_index_overflow[2] = tri_data_index_overflow;

  wire r1f_all_probe_targets_complete =
      tri_waddr_target_opportunities == 32'd10000 &&
      tri_regaddr_target_opportunities == 32'd10000 &&
      tri_data_target_opportunities == 32'd10000;
  wire r1f_any_probe_index_overflow = tri_waddr_index_overflow ||
                                       tri_regaddr_index_overflow ||
                                       tri_data_index_overflow;
  wire r1f_phase_counter_saturation =
      r1f_phase_counters[31:0] == 32'hffff_ffff ||
      r1f_phase_counters[63:32] == 32'hffff_ffff ||
      r1f_phase_counters[95:64] == 32'hffff_ffff ||
      r1f_phase_counters[127:96] == 32'hffff_ffff ||
      r1f_phase_counters[159:128] == 32'hffff_ffff ||
      r1f_phase_counters[191:160] == 32'hffff_ffff ||
      r1f_phase_counters[223:192] == 32'hffff_ffff ||
      r1f_phase_counters[255:224] == 32'hffff_ffff ||
      r1f_transaction_counters[31:0] == 32'hffff_ffff ||
      r1f_transaction_counters[63:32] == 32'hffff_ffff ||
      r1f_transaction_counters[95:64] == 32'hffff_ffff ||
      r1f_transaction_counters[127:96] == 32'hffff_ffff;

  always_comb begin
    r1f_tri_phase_probe_status = 32'b0;
    r1f_tri_phase_probe_status[0] = tri_legacy_guard_complete ||
                                           tri_probe_active ||
                                           tri_probe_terminal ||
                                           tri_entry_bank_valid;
    r1f_tri_phase_probe_status[1] = tri_probe_done;
    r1f_tri_phase_probe_status[2] = tri_probe_aborted;
    r1f_tri_phase_probe_status[3] = r1f_all_probe_targets_complete;
    r1f_tri_phase_probe_status[4] = tri_safe_bank_select_write_ok &&
                                           tri_safe_bank_verify_ok &&
                                           tri_safe_target_pre_ok;
    r1f_tri_phase_probe_status[5] = tri_safe_target_pre_valid &&
                                           tri_safe_target_post_valid &&
                                           tri_safe_target_pre_value ==
                                           tri_safe_target_post_value;
    r1f_tri_phase_probe_status[6] = tri_original_bank_restore_verified;
    r1f_tri_phase_probe_status[7] = probe_scl_release && probe_sda_release;
    r1f_tri_phase_probe_status[8] = 1'b1;
    r1f_tri_phase_probe_status[9] = !r1f_any_probe_index_overflow;

    r1f_probe_setup_restore_status = 32'b0;
    r1f_probe_setup_restore_status[0] = r1f_tri_phase_probe_status[0];
    r1f_probe_setup_restore_status[1] = tri_entry_bank_valid;
    r1f_probe_setup_restore_status[2] = tri_legacy_bus_idle_qualified;
    r1f_probe_setup_restore_status[3] = tri_safe_bank_select_write_ok;
    r1f_probe_setup_restore_status[4] = tri_safe_bank_verify_ok;
    r1f_probe_setup_restore_status[5] = tri_safe_target_pre_ok;
    r1f_probe_setup_restore_status[6] = tri_safe_target_post_ok;
    r1f_probe_setup_restore_status[7] =
        r1f_tri_phase_probe_status[5];
    r1f_probe_setup_restore_status[8] = tri_original_bank_restored;
    r1f_probe_setup_restore_status[9] =
        tri_original_bank_restore_verified;
    r1f_probe_setup_restore_status[10] = probe_scl_release &&
                                               probe_sda_release;
    r1f_probe_setup_restore_status[11] = tri_probe_aborted &&
        tri_probe_abort_code >= 8'h01 && tri_probe_abort_code <= 8'h04;
    r1f_probe_setup_restore_status[12] = tri_probe_aborted &&
        (tri_probe_abort_code >= 8'h07 ||
         tri_probe_restore_failure_code != 8'h00);
  end

  assign tri_block_read_phase = r1f_probe_detail_read_word[6:5];
  assign tri_block_read_index = r1f_probe_detail_read_word[4:0] - 5'd19;
  always_comb begin
    integer phase_number;
    logic [4:0] phase_word;
    phase_number = r1f_probe_detail_read_word[6:5];
    phase_word = r1f_probe_detail_read_word[4:0];
    r1f_probe_detail_read_data = 32'b0;
    if (phase_number < 3) begin
      if (phase_word >= 5'd19 && phase_word <= 5'd28) begin
        r1f_probe_detail_read_data = tri_block_read_nack_count;
      end else begin
        case (phase_word)
          5'd0: r1f_probe_detail_read_data = r1f_phase_probe_status_word(
              r1f_detail_target_opportunities[phase_number],
              r1f_detail_target_nacks[phase_number],
              r1f_detail_attempts[phase_number],
              r1f_detail_index_overflow[phase_number]);
          5'd1: r1f_probe_detail_read_data = r1f_detail_attempts[phase_number];
          5'd2: r1f_probe_detail_read_data =
              r1f_detail_prereq_waddr_opportunities[phase_number];
          5'd3: r1f_probe_detail_read_data =
              r1f_detail_prereq_waddr_acks[phase_number];
          5'd4: r1f_probe_detail_read_data =
              r1f_detail_prereq_waddr_nacks[phase_number];
          5'd5: r1f_probe_detail_read_data =
              r1f_detail_prereq_regaddr_opportunities[phase_number];
          5'd6: r1f_probe_detail_read_data =
              r1f_detail_prereq_regaddr_acks[phase_number];
          5'd7: r1f_probe_detail_read_data =
              r1f_detail_prereq_regaddr_nacks[phase_number];
          5'd8: r1f_probe_detail_read_data =
              r1f_detail_target_opportunities[phase_number];
          5'd9: r1f_probe_detail_read_data =
              r1f_detail_target_acks[phase_number];
          5'd10: r1f_probe_detail_read_data =
              r1f_detail_target_nacks[phase_number];
          5'd11: r1f_probe_detail_read_data = r1f_detail_timeouts[phase_number];
          5'd12: r1f_probe_detail_read_data =
              r1f_detail_first_nack_index[phase_number];
          5'd13: r1f_probe_detail_read_data =
              r1f_detail_last_nack_index[phase_number];
          5'd14: r1f_probe_detail_read_data =
              r1f_detail_max_consecutive_nacks[phase_number];
          5'd15: r1f_probe_detail_read_data =
              r1f_detail_adjacent_nack_pairs[phase_number];
          5'd16: r1f_probe_detail_read_data =
              r1f_detail_run_count[phase_number];
          5'd17: r1f_probe_detail_read_data =
              r1f_detail_index_stored_count[phase_number];
          5'd18: r1f_probe_detail_read_data =
              {31'b0, r1f_detail_index_overflow[phase_number]};
          default: r1f_probe_detail_read_data = 32'b0;
        endcase
      end
    end else begin
      case (phase_word)
        5'd0: r1f_probe_detail_read_data = r1f_tri_phase_probe_status;
        5'd1: r1f_probe_detail_read_data = tri_round_robin_scheduler_rounds;
        5'd2: r1f_probe_detail_read_data = tri_waddr_transaction_attempts +
            tri_regaddr_transaction_attempts + tri_data_transaction_attempts;
        5'd3: r1f_probe_detail_read_data = tri_probe_timeout_count_total;
        5'd4: r1f_probe_detail_read_data = tri_probe_aborted &&
            tri_probe_abort_code <= 8'h04 ? {24'b0, tri_probe_abort_code} : 32'b0;
        5'd5: r1f_probe_detail_read_data = tri_probe_aborted &&
            tri_probe_restore_failure_code != 8'h00 ?
            {24'b0, tri_probe_restore_failure_code} :
            (tri_probe_abort_code >= 8'h07 ?
             {24'b0, tri_probe_abort_code} : 32'b0);
        5'd6: r1f_probe_detail_read_data =
            {23'b0, tri_entry_bank_valid, tri_entry_bank};
        5'd7: r1f_probe_detail_read_data =
            {22'b0, tri_safe_bank_verify_ok,
             tri_safe_bank_readback_valid, tri_safe_bank_readback};
        5'd8: r1f_probe_detail_read_data =
            {22'b0, tri_safe_target_pre_ok, tri_safe_target_pre_valid,
             tri_safe_target_pre_value};
        5'd9: r1f_probe_detail_read_data =
            {21'b0, tri_safe_target_post_ok,
             r1f_tri_phase_probe_status[5], tri_safe_target_post_valid,
             tri_safe_target_post_value};
        5'd10: r1f_probe_detail_read_data =
            {22'b0, tri_original_bank_restore_verified,
             tri_restored_bank_readback_valid, tri_restored_bank_readback};
        5'd11: r1f_probe_detail_read_data =
            {27'b0, tri_legacy_bus_idle_qualified, nvp_sda_i, nvp_scl_i,
             nvp_init_sda_release, nvp_init_scl_release};
        5'd12: r1f_probe_detail_read_data =
            {29'b0, nvp_init_scl_release && nvp_init_sda_release,
             probe_sda_release, probe_scl_release};
        5'd13: r1f_probe_detail_read_data =
            {30'b0, tri_current_scheduler_phase};
        5'd14: r1f_probe_detail_read_data =
            {29'b0, tri_attempt_limit_status};
        5'd15: r1f_probe_detail_read_data = 32'b0;
        default: r1f_probe_detail_read_data = 32'b0;
      endcase
    end
  end

  generate
    if (ENABLE_RTRACK_DIAGNOSTICS != 0) begin : GEN_RTRACK_MMIO
  v41_r1f_measurement_regs #(
    .SAFE_PROBE_BANK(8'h00), .SAFE_PROBE_REGISTER(8'h85),
    .SAFE_PROBE_DATA(8'h00), .SAFE_PROBE_TARGET_PROVEN(1'b1)
  ) R1F_MEASUREMENT_REGS (
    .offset(r1h_req_offset),
    .autoinit_waddr_opportunities(r1f_phase_counters[31:0]),
    .autoinit_waddr_nacks(r1f_phase_counters[63:32]),
    .autoinit_regaddr_opportunities(r1f_phase_counters[95:64]),
    .autoinit_regaddr_nacks(r1f_phase_counters[127:96]),
    .autoinit_data_opportunities(r1f_phase_counters[159:128]),
    .autoinit_data_nacks(r1f_phase_counters[191:160]),
    .autoinit_raddr_opportunities(r1f_phase_counters[223:192]),
    .autoinit_raddr_nacks(r1f_phase_counters[255:224]),
    .autoinit_transaction_starts(r1f_transaction_counters[31:0]),
    .autoinit_transaction_completions(r1f_transaction_counters[63:32]),
    .autoinit_failed_transactions(r1f_transaction_counters[95:64]),
    .autoinit_timeout_transactions(r1f_transaction_counters[127:96]),
    .phase_counters_final(nvp_init_done),
    .phase_counter_saturation(r1f_phase_counter_saturation),
    .legacy_aggregate_nack_count({16'b0, nvp_init_detail[143:128]}),
    .legacy_first8_reconciliation_supported(1'b1),
    .failed_txn_total_count(r1f_failed_txn_total_count),
    .failed_txn_stored_count(r1f_failed_txn_stored_count),
    .failed_txn_overflow(r1f_failed_txn_overflow),
    .first_failed_txn_index(r1f_first_failed_txn_index),
    .first_failed_txn_index_valid(r1f_first_failed_txn_index_valid),
    .last_failed_txn_index(r1f_last_failed_txn_index),
    .last_failed_txn_index_valid(r1f_last_failed_txn_index_valid),
    .next_transaction_serial(r1f_transaction_serial_next),
    .transaction_serial_overflow(r1f_transaction_serial_overflow),
    .failed_txn_total_count_saturated(r1f_failed_txn_total_count_saturated),
    .failed_txn_input_protocol_error(r1f_failed_txn_input_protocol_error),
    .bank_invariant_check_count(r1f_bank_invariant_check_count),
    .bank_invariant_error_count(r1f_bank_invariant_error_count),
    .first_bank_invariant_error(r1f_first_bank_invariant_error),
    .final_physical_bank(nvp_init_detail[215:208]),
    .final_physical_bank_valid(nvp_init_detail[197]),
    .tri_phase_probe_status(r1f_tri_phase_probe_status),
    .probe_timeout_count_total(tri_probe_timeout_count_total),
    .probe_setup_restore_status(r1f_probe_setup_restore_status),
    .safe_target_pre_readback(tri_safe_target_pre_value),
    .safe_target_pre_readback_valid(tri_safe_target_pre_valid),
    .safe_target_post_readback(tri_safe_target_post_value),
    .safe_target_post_readback_valid(tri_safe_target_post_valid),
    .original_bank_readback(tri_entry_bank),
    .original_bank_readback_valid(tri_entry_bank_valid),
    .restored_bank_readback(tri_restored_bank_readback),
    .restored_bank_readback_valid(tri_restored_bank_readback_valid),
    .restored_bank_verified(tri_original_bank_restore_verified),
    .probe_start_freerun(probe_start_freerun),
    .probe_done_freerun(probe_done_freerun),
    .probe_detail_read_word(r1f_probe_detail_read_word),
    .probe_detail_read_select(r1f_probe_detail_read_select),
    .probe_detail_read_data(r1f_probe_detail_read_data),
    .record_read_index(r1f_record_decode_index),
    .record_read_word(r1f_record_decode_word),
    .record_read_select(r1f_record_read_select),
    .probe_index_read_phase(r1f_probe_index_read_phase),
    .probe_index_read_word(r1f_probe_index_read_word),
    .probe_index_read_select(r1f_probe_index_read_select),
    .read_data(r1f_read_data)
  );

  // Only the new, unused 0x3600..0x367f page is overlaid. All old scalar,
  // failed-record and probe-index decode/BRAM latency remain unchanged.
  v41_r1i_poc_scalar_mux R1I_POC_SCALAR_MUX (
    .offset(r1h_req_offset), .telemetry(r1i_poc_telemetry),
    .legacy_scalar_read_data(r1f_read_data),
    .scalar_read_data(r1i_scalar_read_data)
  );

  // The complete R1f/R1h page plus R1i uses one registered, one-outstanding read
  // service.  Scalar values are captured at request acceptance; record words
  // use one BRAM read and packed index words use two ordered BRAM reads.
  v41_r1h_mmio_read_service R1H_MMIO_READ_SERVICE (
    .clk(axi_aclk), .reset((~axi_aresetn) || nvp_por_reset),
    .req_valid(r1h_req_valid), .req_ready(r1h_req_ready),
    .req_offset(r1h_req_offset),
    .rsp_valid(r1h_rsp_valid), .rsp_ready(r1h_rsp_ready),
    .rsp_data(r1h_rsp_data),
    .scalar_read_data(r1i_scalar_read_data),
    .record_select(r1f_record_read_select),
    .record_index(r1f_record_decode_index),
    .record_word(r1f_record_decode_word),
    .probe_index_select(r1f_probe_index_read_select),
    .probe_index_phase(r1f_probe_index_read_phase),
    .probe_index_word(r1f_probe_index_read_word),
    .record_read_enable(r1f_record_read_enable),
    .record_read_index(r1f_record_read_index),
    .record_read_word(r1f_record_read_word),
    .record_read_valid(r1f_record_read_valid),
    .record_read_data(r1f_record_read_data),
    .index_read_enable(tri_index_read_req),
    .index_read_phase(tri_index_read_phase),
    .index_read_address(tri_index_read_address),
    .index_read_valid(tri_index_read_valid),
    .index_read_data(tri_index_read_data),
    .waddr_index_stored_count(tri_waddr_index_stored_count),
    .regaddr_index_stored_count(tri_regaddr_index_stored_count),
    .data_index_stored_count(tri_data_index_stored_count)
  );

  v41_r1e_measurement_regs R1E_MEASUREMENT_REGS (
    .offset(host_req_addr[7:0]),
    .freerun_count(lifecycle_freerun_count),
    .cnt_at_init_done(cnt_at_init_done),
    .cnt_at_first_user_lnk_up(cnt_at_first_user_lnk_up),
    .cnt_at_first_axi_aresetn_high(cnt_at_first_axi_aresetn_high),
    .cnt_at_first_axi_aresetn_low_after_high(
      cnt_at_first_axi_aresetn_low_after_high),
    .user_lnk_up_transition_count(user_lnk_up_transition_count),
    .axi_aresetn_transition_count(axi_aresetn_transition_count),
    .event_flags(lifecycle_event_flags),
    .probe_count(probe_count), .probe_ack_count(probe_ack_count),
    .probe_nack_count(probe_nack_count),
    .probe_timeout_count(probe_timeout_count), .probe_status(probe_status),
    .probe_first_nack_index(probe_first_nack_index),
    .probe_last_nack_index(probe_last_nack_index),
    .probe_max_consecutive_nacks(probe_max_consecutive_nacks),
    .probe_start_freerun(probe_start_freerun),
    .probe_done_freerun(probe_done_freerun), .read_data(measurement_read_data)
  );
    end else begin : GEN_PRODUCT_MMIO
      v41_g2b_product_r1e_compatibility R1E_COMPATIBILITY (
        .offset(host_req_addr[7:0]), .read_data(measurement_read_data)
      );

      // Preserve this small boundary so the post-synthesis profile receipt can
      // prove that PRODUCT elaborated its deterministic compatibility service.
      // The attribute is local to this observability-only responder.
      (* keep_hierarchy = "yes" *)
      v41_g2b_product_profile_read_service PRODUCT_R1I_READ_SERVICE (
        .clk(axi_aclk), .reset((~axi_aresetn) || nvp_por_reset),
        .req_valid(r1h_req_valid), .req_ready(r1h_req_ready),
        .req_offset(r1h_req_offset),
        .rsp_valid(r1h_rsp_valid), .rsp_ready(r1h_rsp_ready),
        .rsp_data(r1h_rsp_data), .r1i_telemetry(r1i_poc_telemetry),
        .r1f_phase_counters(r1f_phase_counters),
        .r1f_transaction_counters(r1f_transaction_counters),
        .phase_counters_final(nvp_init_done),
        .phase_counter_saturation(r1f_phase_counter_saturation),
        .legacy_aggregate_nack_count(nvp_init_detail[143:128]),
        .next_transaction_serial(r1f_transaction_serial_next),
        .transaction_serial_overflow(r1f_transaction_serial_overflow),
        .bank_invariant_check_count(r1f_bank_invariant_check_count),
        .bank_invariant_error_count(r1f_bank_invariant_error_count),
        .first_bank_invariant_error(r1f_first_bank_invariant_error),
        .final_physical_bank(nvp_init_detail[215:208]),
        .final_physical_bank_valid(nvp_init_detail[197])
      );
    end
  endgenerate

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

  v41_g2b_mmio_router G2B_MMIO_ROUTER (
    .host_req_valid(host_req_valid), .host_req_ready(host_req_ready),
    .host_req_write(host_req_write), .host_req_addr(host_req_addr),
    .host_req_wdata(host_req_wdata), .host_req_be(host_req_be),
    .host_rsp_valid(host_rsp_valid), .host_rsp_ready(host_rsp_ready),
    .host_rsp_rdata(host_rsp_rdata),
    .legacy_req_valid(legacy_host_req_valid),
    .legacy_req_ready(legacy_host_req_ready),
    .legacy_req_write(legacy_host_req_write),
    .legacy_req_addr(legacy_host_req_addr),
    .legacy_req_wdata(legacy_host_req_wdata),
    .legacy_req_be(legacy_host_req_be),
    .legacy_rsp_valid(legacy_host_rsp_valid),
    .legacy_rsp_ready(legacy_host_rsp_ready),
    .legacy_rsp_rdata(legacy_host_rsp_rdata),
    .g2b_req_valid(g2b_req_valid), .g2b_req_ready(g2b_req_ready),
    .g2b_req_write(g2b_req_write), .g2b_req_addr(g2b_req_addr),
    .g2b_req_wdata(g2b_req_wdata), .g2b_req_be(g2b_req_be),
    .g2b_rsp_valid(g2b_rsp_valid), .g2b_rsp_ready(g2b_rsp_ready),
    .g2b_rsp_rdata(g2b_rsp_rdata)
  );

  // Both diagnostic ranges remain on the legacy side of the frozen G2B
  // router.  Exactly one may be intercepted by a compile-time profile; with
  // both profile parameters at zero every address follows the PRODUCT path.
  assign product_legacy_req_valid = legacy_host_req_valid && !nvp_diag_select;
  assign product_legacy_req_write = legacy_host_req_write;
  assign product_legacy_req_addr = legacy_host_req_addr;
  assign product_legacy_req_wdata = legacy_host_req_wdata;
  assign product_legacy_req_be = legacy_host_req_be;
  assign nvp_diag_req_valid = legacy_host_req_valid && nvp_diag_select;
  assign legacy_host_req_ready = nvp_diag_select ? nvp_diag_req_ready :
                                                   product_legacy_req_ready;
  assign legacy_host_rsp_valid = nvp_diag_rsp_valid || product_legacy_rsp_valid;
  assign legacy_host_rsp_rdata = nvp_diag_rsp_valid ? nvp_diag_rsp_rdata :
                                                    product_legacy_rsp_rdata;
  assign nvp_diag_rsp_ready = legacy_host_rsp_ready;
  assign product_legacy_rsp_ready = legacy_host_rsp_ready;

  generate
    if (ENABLE_NVP_VIDEO_DIAGNOSTIC != 0) begin : GEN_NVP_VIDEO_DIAG_CORE
      g2b_nvp_video_diag NVP_VIDEO_DIAG_CORE (
        .clk(axi_aclk), .reset(~axi_aresetn),
        .autoinit_done(nvp_init_done), .autoinit_busy(nvp_init_busy),
        .autoinit_error(nvp_init_error), .nvp_reset_released(nvp_rst),
        .transport_stream_enabled(diag_transport_stored_enable),
        .transport_c2h_active(diag_transport_c2h_active),
        .transport_ring_empty(diag_transport_ring_empty),
        .transport_ring_full(diag_transport_ring_full),
        .i2c_cmd_valid(diag_i2c_cmd_valid),
        .i2c_cmd_ready(diag_i2c_cmd_ready),
        .i2c_cmd_write(diag_i2c_cmd_write),
        .i2c_cmd_reg(diag_i2c_cmd_reg),
        .i2c_cmd_wdata(diag_i2c_cmd_wdata),
        .i2c_cmd_accepted(diag_i2c_cmd_accepted),
        .i2c_busy(diag_i2c_busy), .i2c_done(diag_i2c_done),
        .i2c_success(diag_i2c_success), .i2c_timeout(diag_i2c_timeout),
        .i2c_read_data(diag_i2c_read_data),
        .i2c_bus_idle(diag_i2c_bus_idle),
        .mmio_req_valid(nvp_diag_req_valid),
        .mmio_req_ready(nvp_diag_req_ready),
        .mmio_req_write(legacy_host_req_write),
        .mmio_req_addr(legacy_host_req_addr),
        .mmio_req_wdata(legacy_host_req_wdata),
        .mmio_req_be(legacy_host_req_be),
        .mmio_rsp_valid(nvp_diag_rsp_valid),
        .mmio_rsp_ready(nvp_diag_rsp_ready),
        .mmio_rsp_rdata(nvp_diag_rsp_rdata),
        .diagnostic_i2c_owns_bus(diag_i2c_owns_bus),
        .capture_ready(diag_capture_ready),
        .current_session_id(diag_current_session_id),
        .current_round(diag_current_round),
        .current_channel(diag_current_channel),
        .product_baseline_restored(diag_product_baseline_restored)
      );
      assign scan1_bank_context_lockout = 1'b0;
      assign scan1_busy = 1'b0;
      assign scan1_done = 1'b0;
      assign acq1_executor_busy = 1'b0;
      assign acq1_executor_done = 1'b0;
    end else if (ENABLE_NVP_CAMERA_SCAN1 != 0 &&
                 ENABLE_NVP_ACQ1_EXECUTOR != 0) begin : GEN_NVP_CAMERA_ACQ1_COMPAT0_R2_CORE
      g2b_nvp_camera_scan1_acq1_compat0_r2 NVP_CAMERA_ACQ1_COMPAT0_R2_CORE (
        .clk(axi_aclk), .reset(~axi_aresetn),
        .autoinit_done(nvp_init_done), .autoinit_busy(nvp_init_busy),
        .autoinit_error(nvp_init_error), .nvp_reset_released(nvp_rst),
        .i2c_cmd_valid(diag_i2c_cmd_valid),
        .i2c_cmd_ready(diag_i2c_cmd_ready),
        .i2c_cmd_write(diag_i2c_cmd_write),
        .i2c_cmd_reg(diag_i2c_cmd_reg),
        .i2c_cmd_wdata(diag_i2c_cmd_wdata),
        .i2c_cmd_accepted(diag_i2c_cmd_accepted),
        .i2c_busy(diag_i2c_busy), .i2c_done(diag_i2c_done),
        .i2c_success(diag_i2c_success), .i2c_timeout(diag_i2c_timeout),
        .i2c_error_cause(diag_i2c_error_cause),
        .i2c_read_data(diag_i2c_read_data),
        .i2c_bus_idle(diag_i2c_bus_idle),
        .mmio_req_valid(nvp_diag_req_valid),
        .mmio_req_ready(nvp_diag_req_ready),
        .mmio_req_write(legacy_host_req_write),
        .mmio_req_addr(legacy_host_req_addr),
        .mmio_req_wdata(legacy_host_req_wdata),
        .mmio_req_be(legacy_host_req_be),
        .mmio_rsp_valid(nvp_diag_rsp_valid),
        .mmio_rsp_ready(nvp_diag_rsp_ready),
        .mmio_rsp_rdata(nvp_diag_rsp_rdata),
        .diagnostic_i2c_owns_bus(diag_i2c_owns_bus),
        .scanner_busy(scan1_busy), .scanner_done(scan1_done),
        .executor_busy(acq1_executor_busy),
        .executor_done(acq1_executor_done),
        .bank_context_lockout(scan1_bank_context_lockout)
      );
      assign diag_capture_ready = 1'b0;
      assign diag_current_session_id = 16'b0;
      assign diag_current_round = 3'b0;
      assign diag_current_channel = 3'b0;
      assign diag_product_baseline_restored = 1'b1;
    end else if (ENABLE_NVP_CAMERA_SCAN1 != 0) begin : GEN_NVP_CAMERA_SCAN1_CORE
      g2b_nvp_camera_scan1 NVP_CAMERA_SCAN1_CORE (
        .clk(axi_aclk), .reset(~axi_aresetn),
        .autoinit_done(nvp_init_done), .autoinit_busy(nvp_init_busy),
        .autoinit_error(nvp_init_error), .nvp_reset_released(nvp_rst),
        .i2c_cmd_valid(diag_i2c_cmd_valid),
        .i2c_cmd_ready(diag_i2c_cmd_ready),
        .i2c_cmd_write(diag_i2c_cmd_write),
        .i2c_cmd_reg(diag_i2c_cmd_reg),
        .i2c_cmd_wdata(diag_i2c_cmd_wdata),
        .i2c_cmd_accepted(diag_i2c_cmd_accepted),
        .i2c_busy(diag_i2c_busy), .i2c_done(diag_i2c_done),
        .i2c_success(diag_i2c_success), .i2c_timeout(diag_i2c_timeout),
        .i2c_error_cause(diag_i2c_error_cause),
        .i2c_read_data(diag_i2c_read_data),
        .i2c_bus_idle(diag_i2c_bus_idle),
        .mmio_req_valid(nvp_diag_req_valid),
        .mmio_req_ready(nvp_diag_req_ready),
        .mmio_req_write(legacy_host_req_write),
        .mmio_req_addr(legacy_host_req_addr),
        .mmio_req_wdata(legacy_host_req_wdata),
        .mmio_req_be(legacy_host_req_be),
        .mmio_rsp_valid(nvp_diag_rsp_valid),
        .mmio_rsp_ready(nvp_diag_rsp_ready),
        .mmio_rsp_rdata(nvp_diag_rsp_rdata),
        .scanner_i2c_owns_bus(diag_i2c_owns_bus),
        .scanner_busy(scan1_busy), .scanner_done(scan1_done),
        .bank_context_lockout(scan1_bank_context_lockout)
      );
      assign diag_capture_ready = 1'b0;
      assign diag_current_session_id = 16'b0;
      assign diag_current_round = 3'b0;
      assign diag_current_channel = 3'b0;
      assign diag_product_baseline_restored = 1'b1;
      assign acq1_executor_busy = 1'b0;
      assign acq1_executor_done = 1'b0;
    end else begin : GEN_NO_NVP_VIDEO_DIAG_CORE
      assign nvp_diag_req_ready = 1'b0;
      assign nvp_diag_rsp_valid = 1'b0;
      assign nvp_diag_rsp_rdata = 32'b0;
      assign diag_i2c_cmd_valid = 1'b0;
      assign diag_i2c_cmd_write = 1'b0;
      assign diag_i2c_cmd_reg = 8'b0;
      assign diag_i2c_cmd_wdata = 8'b0;
      assign diag_i2c_owns_bus = 1'b0;
      assign diag_capture_ready = 1'b0;
      assign diag_current_session_id = 16'b0;
      assign diag_current_round = 3'b0;
      assign diag_current_channel = 3'b0;
      assign diag_product_baseline_restored = 1'b1;
      assign scan1_bank_context_lockout = 1'b0;
      assign scan1_busy = 1'b0;
      assign scan1_done = 1'b0;
      assign acq1_executor_busy = 1'b0;
      assign acq1_executor_done = 1'b0;
    end
  endgenerate

  v41_control_status_regs #(
    .BLOCK_ID(BLOCK_OR_FW_ID),
    .GIT_SHA_W0(GIT_SHA_W0), .GIT_SHA_W1(GIT_SHA_W1),
    .GIT_SHA_W2(GIT_SHA_W2), .GIT_SHA_W3(GIT_SHA_W3),
    .GIT_SHA_W4(GIT_SHA_W4), .BUILD_FLAGS(BUILD_FLAGS)
  ) CONTROL_STATUS_REGS (
    .clk(axi_aclk), .reset(~axi_aresetn),
    .host_req_valid(product_legacy_req_valid),
    .host_req_ready(product_legacy_req_ready),
    .host_req_write(product_legacy_req_write),
    .host_req_addr(product_legacy_req_addr),
    .host_req_wdata(product_legacy_req_wdata),
    .host_req_be(product_legacy_req_be),
    .host_rsp_valid(product_legacy_rsp_valid),
    .host_rsp_ready(product_legacy_rsp_ready),
    .host_rsp_rdata(product_legacy_rsp_rdata),
    .app_req_valid(app_req_valid), .app_req_ready(app_req_ready),
    .app_req_write(app_req_write), .app_req_addr(app_req_addr),
    .app_req_wdata(app_req_wdata), .app_req_be(app_req_be),
    .app_rsp_valid(app_rsp_valid), .app_rsp_ready(app_rsp_ready),
    .app_rsp_rdata(app_rsp_rdata),
    .measurement_read_data(measurement_read_data),
    .r1h_req_valid(r1h_req_valid), .r1h_req_ready(r1h_req_ready),
    .r1h_req_offset(r1h_req_offset),
    .r1h_rsp_valid(r1h_rsp_valid), .r1h_rsp_ready(r1h_rsp_ready),
    .r1h_rsp_data(r1h_rsp_data),
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

  v41_g2b_onech_c2h G2B_ONECH_C2H (
    // NVP initialization/readiness is not a source-sequence reset under the
    // frozen ABI.  No distinct product source-reset cause exists at this top;
    // the core's explicit source-reset interface is qualified in simulation.
    .source_clk(nvp_clk), .source_reset(1'b0),
    .source_ready(nvp_enable && nvp_frontend_released),
    .source_byte(nvp_data_byte),
    .axi_clk(axi_aclk), .axi_aresetn(axi_aresetn),
    .standalone_transport_reset(1'b0),
    .mmio_req_valid(g2b_req_valid), .mmio_req_ready(g2b_req_ready),
    .mmio_req_write(g2b_req_write), .mmio_req_addr(g2b_req_addr),
    .mmio_req_wdata(g2b_req_wdata), .mmio_req_be(g2b_req_be),
    .mmio_rsp_valid(g2b_rsp_valid), .mmio_rsp_ready(g2b_rsp_ready),
    .mmio_rsp_rdata(g2b_rsp_rdata),
    .m_axis_c2h_tdata(g2b_c2h_tdata),
    .m_axis_c2h_tkeep(g2b_c2h_tkeep),
    .m_axis_c2h_tlast(g2b_c2h_tlast),
    .m_axis_c2h_tvalid(g2b_c2h_tvalid),
    .m_axis_c2h_tready(g2b_c2h_tready),
    .diag_stored_enable(diag_transport_stored_enable),
    .diag_c2h_active(diag_transport_c2h_active),
    .diag_ring_empty(diag_transport_ring_empty),
    .diag_ring_full(diag_transport_ring_full)
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
    .s_axis_c2h_tdata_0(g2b_c2h_tdata),
    .s_axis_c2h_tlast_0(g2b_c2h_tlast),
    .s_axis_c2h_tvalid_0(g2b_c2h_tvalid),
    .s_axis_c2h_tready_0(g2b_c2h_tready),
    .s_axis_c2h_tkeep_0(g2b_c2h_tkeep),
    .m_axis_h2c_tdata_0(h2c_tdata), .m_axis_h2c_tlast_0(h2c_tlast),
    .m_axis_h2c_tvalid_0(h2c_tvalid), .m_axis_h2c_tready_0(1'b0),
    .m_axis_h2c_tkeep_0(h2c_tkeep)
  );

  // Make deliberate stage-boundary tie-offs explicit for structural audits.
  wire [119:0] unused_stage1_signals = {
    nvp_mpp, nvp_init_busy, bar_target_reset, user_lnk_up, usr_irq_ack,
    msi_enable, msi_vector_width, cfg_mgmt_read_data,
    cfg_mgmt_read_write_done, g2b_c2h_tready, h2c_tdata, h2c_tlast,
    h2c_tvalid, h2c_tkeep
  };
endmodule
