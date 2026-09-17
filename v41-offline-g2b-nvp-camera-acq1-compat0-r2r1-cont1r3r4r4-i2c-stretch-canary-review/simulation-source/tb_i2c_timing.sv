`timescale 1ns/1ps

// Task-owned resolved open-drain bus model. The compiled master is the exact
// frozen Git blob; neither its outputs nor private state are forced.
module tb_i2c_timing;
  logic clk = 0, rst = 1;
  always #8 clk = ~clk;

  logic cmd_valid = 0, cmd_ready, cmd_write = 1, cmd_accepted;
  logic [7:0] cmd_reg = 8'hff, cmd_wdata = 8'h05;
  logic busy, done, success, timeout, bus_idle;
  logic [3:0] error_cause;
  logic [7:0] read_data;
  logic [31:0] transaction_sequence;
  logic scl_release, sda_release;
  tri1 scl_bus, sda_bus;
  logic slave_scl_low = 0, slave_sda_low = 0;
  logic raw_scl = 1, raw_sda = 1;
  assign scl_bus = scl_release ? 1'bz : 1'b0;
  assign scl_bus = slave_scl_low ? 1'b0 : 1'bz;
  assign sda_bus = sda_release ? 1'bz : 1'b0;
  assign sda_bus = slave_sda_low ? 1'b0 : 1'bz;

  integer case_id = 0, op_read = 0, stretch_phase = -1, stretch_bit = -1;
  integer extra_cycles = 0, edge_phase_ns = 0;
  integer scl_input_delay_ns = 0, sda_input_delay_ns = 0;
  integer ack_mode = 0, ack_lead_ns = 2000, early_release_ns = 0;
  integer expected_reg = 255, expected_data = 5;
  integer ack_target_phase = -1;
  integer starts = 0, stops = 0, decoded_bytes = 0, decoded_bits = 0;
  integer phase = 0, bit_count = 0;
  logic [7:0] received = 0, register_byte = 0, send_byte = 8'ha5;
  bit active = 0, ack_this = 0, target_window = 0;
  bit target_ack = 0, target_low_pending = 0;
  bit target_saw_bus_high = 0, ack_high_violation = 0;
  integer max_scl_wait = 0, max_idle_wait = 0;
  time target_low_t = 0, target_master_release_t = 0;
  time target_slave_release_t = 0, target_bus_high_t = 0;
  time target_bus_fall_t = 0, ack_assert_t = 0, ack_release_t = 0;
  time target_sample_t = 0, target_raw_scl_t = 0, target_sync_scl_t = 0;
  time target_filtered_scl_t = 0, target_raw_sda_t = 0;
  time target_sync_sda_t = 0, target_filtered_sda_t = 0;
  time last_raw_scl_t = 0, last_sync_scl_t = 0, last_filtered_scl_t = 0;
  time last_raw_sda_t = 0, last_sync_sda_t = 0, last_filtered_sda_t = 0;
  integer sampled_sda = -1, sampled_raw_sda = -1, sampled_bus_sda = -1;
  integer case_file, fields_read;
  integer pin_file;

  nvp_i2c_fixed_master #(.CLK_HZ(62_500_000), .I2C_HZ(25_000)) dut (
    .clk(clk), .rst(rst), .raw_scl_i(raw_scl), .raw_sda_i(raw_sda),
    .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_write(cmd_write),
    .cmd_reg(cmd_reg), .cmd_wdata(cmd_wdata), .cmd_accepted(cmd_accepted),
    .busy(busy), .done(done), .success(success), .timeout(timeout),
    .error_cause(error_cause), .read_data(read_data),
    .transaction_sequence(transaction_sequence), .scl_release(scl_release),
    .sda_release(sda_release), .bus_idle(bus_idle));

  // Separate threshold-crossing sensitivity model. A pending rise never
  // raises the receiver input while a participant still pulls the bus LOW.
  always @(posedge scl_bus) begin
    #(scl_input_delay_ns);
    if (scl_bus === 1'b1) raw_scl = 1;
  end
  always @(negedge scl_bus) raw_scl = 0;
  always @(posedge sda_bus) begin
    #(sda_input_delay_ns);
    if (sda_bus === 1'b1) raw_sda = 1;
  end
  always @(negedge sda_bus) raw_sda = 0;

  // Read-only edge timestamps; none of these signals control the slave.
  always @(posedge raw_scl) last_raw_scl_t = $time;
  always @(posedge dut.scl_sync[1]) last_sync_scl_t = $time;
  always @(posedge dut.scl_filtered) last_filtered_scl_t = $time;
  always @(negedge raw_sda) last_raw_sda_t = $time;
  always @(negedge dut.sda_sync[1]) last_sync_sda_t = $time;
  always @(negedge dut.sda_filtered) last_filtered_sda_t = $time;
  // Read-only pin recorder. The external checker reconstructs bytes and ACK
  // windows from these resolved-bus events, independently of slave `phase`.
  always @(posedge scl_bus) if (!rst && pin_file != 0)
    $fdisplay(pin_file, "RISE,%0t,%b", $time, sda_bus);
  always @(negedge scl_bus) if (!rst && pin_file != 0)
    $fdisplay(pin_file, "FALL,%0t,%b", $time, sda_bus);
  always @(negedge sda_bus) if (!rst && scl_bus === 1'b1 && pin_file != 0)
    $fdisplay(pin_file, "START,%0t,0", $time);
  always @(posedge sda_bus) if (!rst && scl_bus === 1'b1 && pin_file != 0)
    $fdisplay(pin_file, "STOP,%0t,1", $time);
  always @(posedge clk) if (!rst) begin
    if (dut.scl_wait_count > max_scl_wait) max_scl_wait = dut.scl_wait_count;
    if (dut.idle_wait_count > max_idle_wait) max_idle_wait = dut.idle_wait_count;
    if (target_window && dut.state_tick && dut.scl_filtered &&
        ((stretch_phase == 2 && dut.state == 6'd13) ||
         (stretch_phase == 0 && dut.state == 6'd7) ||
         (stretch_phase == 1 && dut.state == 6'd11) ||
         (stretch_phase == 3 && dut.state == 6'd15) ||
         (stretch_phase == 4 && dut.state == 6'd23) ||
         (stretch_phase == 5 && dut.state == 6'd9))) begin
      target_sample_t = $time;
      target_raw_scl_t = last_raw_scl_t;
      target_sync_scl_t = last_sync_scl_t;
      target_filtered_scl_t = last_filtered_scl_t;
      target_raw_sda_t = last_raw_sda_t;
      target_sync_sda_t = last_sync_sda_t;
      target_filtered_sda_t = last_filtered_sda_t;
      sampled_sda = dut.sda_filtered;
      sampled_raw_sda = raw_sda;
      sampled_bus_sda = sda_bus;
    end
  end

  // Slave state comes solely from resolved bus START/STOP and byte edges.
  always @(negedge sda_bus) begin
    if (!rst && scl_bus === 1'b1) begin
      if (!active) begin phase = 0; starts = starts + 1; end
      else begin phase = 3; starts = starts + 1; end
      active = 1;
      bit_count = 0;
      received = 0;
      slave_sda_low = 0;
    end
  end
  always @(posedge sda_bus) begin
    if (!rst && scl_bus === 1'b1 && active) begin
      stops = stops + 1;
      active = 0;
      phase = 0;
      bit_count = 0;
      slave_sda_low = 0;
    end
    if (target_ack && target_saw_bus_high && target_bus_fall_t == 0)
      ack_high_violation = 1;
  end

  // The selected low phase may be lengthened. Selection uses only decoded
  // byte/bit position. master scl_release is an external output used solely
  // to measure requested extra-low time after controller release.
  always @(negedge scl_bus) begin
    if (!rst && active) begin
      if (target_window && target_saw_bus_high && target_bus_fall_t == 0)
        target_bus_fall_t = $time;
      target_window = 0;
      target_ack = 0;
      target_low_pending = 0;
      if ((stretch_phase == 2 && phase == 2 && bit_count == stretch_bit) ||
          (stretch_phase == 0 && phase == 0 && bit_count == 8) ||
          (stretch_phase == 1 && phase == 1 && bit_count == 8) ||
          (stretch_phase == 5 && phase == 1 && bit_count == stretch_bit) ||
          (stretch_phase == 3 && phase == 2 && bit_count == 8) ||
          (stretch_phase == 4 && phase == 3 && bit_count == 8)) begin
        target_window = 1;
        target_ack = (bit_count == 8);
        target_low_pending = 1;
        target_low_t = $time;
        slave_scl_low = 1;
      end
      if (phase >= 0 && phase <= 3 && bit_count == 8) begin
        ack_this = !(target_ack && ack_mode == 1);
        if (target_ack && ack_mode == 2 &&
            (extra_cycles * 16 + edge_phase_ns) >= ack_lead_ns)
          slave_sda_low = 0;
        else begin
          slave_sda_low = ack_this;
          if (target_ack && ack_this) ack_assert_t = $time;
        end
      end else if (phase == 4 && bit_count < 8) begin
        slave_sda_low = !send_byte[7-bit_count];
      end else slave_sda_low = 0;
    end
  end

  always @(posedge scl_release) begin
    if (!rst && target_low_pending) begin
      target_master_release_t = $time;
      if (target_ack && ack_mode == 2 && ack_this &&
          (extra_cycles * 16 + edge_phase_ns) >= ack_lead_ns) begin
        #(extra_cycles * 16 + edge_phase_ns - ack_lead_ns);
        slave_sda_low = 1;
        ack_assert_t = $time;
        #(ack_lead_ns);
      end else begin
        #(extra_cycles * 16 + edge_phase_ns);
      end
      slave_scl_low = 0;
      target_slave_release_t = $time;
      target_low_pending = 0;
    end
  end

  always @(posedge scl_bus) begin
    if (!rst && active) begin
      if (target_window && !target_saw_bus_high) begin
        target_bus_high_t = $time;
        target_saw_bus_high = 1;
      end
      if (phase >= 0 && phase <= 3) begin
        if (bit_count < 8) begin
          received = {received[6:0], sda_bus};
          decoded_bits = decoded_bits + 1;
          bit_count = bit_count + 1;
          if (bit_count == 8) begin
            decoded_bytes = decoded_bytes + 1;
            if ((phase == 0 && received != 8'h60) ||
                (phase == 1 && received != expected_reg[7:0]) ||
                (phase == 2 && received != expected_data[7:0]) ||
                (phase == 3 && received != 8'h61))
              $fatal(1, "EMITTED_BYTE_MISMATCH phase=%0d observed=%02h", phase, received);
          end
        end else begin
          if (phase == 1) register_byte = received;
          if (phase == 3) send_byte = 8'ha5;
          if (phase == 0) phase = 1;
          else if (phase == 1) phase = op_read ? 9 : 2;
          else if (phase == 2) phase = 9;
          else phase = 4;
          bit_count = 0;
          received = 0;
        end
      end else if (phase == 4) begin
        bit_count = bit_count + 1;
        if (bit_count == 8) phase = 5;
      end else if (phase == 5) begin
        if (sda_bus !== 1'b1)
          $fatal(1, "MASTER_TERMINAL_NACK_MISSING");
        phase = 9;
      end
      if (target_ack && target_saw_bus_high && ack_mode == 3 &&
          early_release_ns > 0) begin
        fork
          begin
            #(early_release_ns);
            slave_sda_low = 0;
            ack_release_t = $time;
          end
        join_none
      end
    end
  end

  initial begin
    case_file = $fopen("case_input.txt", "r");
    if (case_file == 0) $fatal(1, "CASE_INPUT_UNAVAILABLE");
    fields_read = $fscanf(case_file, "%d %d %d %d %d %d %d %d %d %d %d\n",
      case_id, op_read, stretch_phase, stretch_bit, extra_cycles,
      edge_phase_ns, scl_input_delay_ns, sda_input_delay_ns, ack_mode,
      ack_lead_ns, early_release_ns);
    $fclose(case_file);
    if (fields_read != 11) $fatal(1, "CASE_INPUT_FIELD_COUNT_%0d", fields_read);
    pin_file = $fopen("pin_edges.csv", "w");
    if (pin_file == 0) $fatal(1, "PIN_LOG_UNAVAILABLE");
    if (op_read) begin expected_reg = 8'hf4; expected_data = 0; end
    if (extra_cycles < 0 || extra_cycles > 2500 || edge_phase_ns < 0 ||
        edge_phase_ns > 15 || scl_input_delay_ns < 0 ||
        scl_input_delay_ns > 2000 || sda_input_delay_ns < 0 ||
        sda_input_delay_ns > 2000 || stretch_phase < -1 ||
        stretch_phase > 5 || ack_mode < 0 || ack_mode > 3)
      $fatal(1, "CASE_PARAMETER_OUT_OF_BOUNDS");
    repeat (8) @(negedge clk);
    rst = 0;
    repeat (8) @(negedge clk);
    if (dut.CLK_HZ != 62_500_000 || dut.I2C_HZ != 25_000 ||
        dut.SCL_TIMEOUT_CYCLES != 1250 ||
        dut.BUS_IDLE_TIMEOUT_CYCLES != 62500 || dut.DIVIDER != 1250)
      $fatal(1, "FROZEN_PROFILE_MISMATCH");
    @(negedge clk);
    cmd_write = !op_read;
    cmd_reg = expected_reg[7:0];
    cmd_wdata = expected_data[7:0];
    cmd_valid = 1;
    @(negedge clk);
    cmd_valid = 0;
    wait (done);
    repeat (4) @(negedge clk);
    $display("DEBUG_COMPLETION seq=%0d busy=%0d idle=%0d timeout=%0d success=%0d cause=%0d", transaction_sequence,busy,bus_idle,timeout,success,error_cause);
    if (transaction_sequence != 1 || busy || (!timeout && !bus_idle))
      $fatal(1, "COMMAND_COMPLETION_CONTRACT seq=%0d busy=%0d idle=%0d", transaction_sequence,busy,bus_idle);
    $display("OBS case=%0d read=%0d target=%0d bit=%0d extra=%0d phase_ns=%0d scl_delay=%0d sda_delay=%0d ack_mode=%0d ack_lead=%0d early_release=%0d success=%0d timeout=%0d raw=%0d read_data=%02h starts=%0d stops=%0d bytes=%0d bits=%0d max_scl_wait=%0d max_idle_wait=%0d target_low=%0t master_release=%0t slave_release=%0t bus_high=%0t bus_fall=%0t ack_assert=%0t ack_release=%0t sample=%0t sample_bus_sda=%0d sample_raw_sda=%0d sample_filtered_sda=%0d raw_scl_high=%0t sync_scl_high=%0t filtered_scl_high=%0t raw_sda_low=%0t sync_sda_low=%0t filtered_sda_low=%0t ack_high_violation=%0d",
      case_id,op_read,stretch_phase,stretch_bit,extra_cycles,edge_phase_ns,
      scl_input_delay_ns,sda_input_delay_ns,ack_mode,ack_lead_ns,
      early_release_ns,success,timeout,error_cause,read_data,starts,stops,
      decoded_bytes,decoded_bits,max_scl_wait,max_idle_wait,target_low_t,
      target_master_release_t,target_slave_release_t,target_bus_high_t,
      target_bus_fall_t,ack_assert_t,ack_release_t,target_sample_t,
      sampled_bus_sda,sampled_raw_sda,sampled_sda,target_raw_scl_t,
      target_sync_scl_t,target_filtered_scl_t,target_raw_sda_t,
      target_sync_sda_t,target_filtered_sda_t,ack_high_violation);
    $display("CASE_COMPLETE_%0d", case_id);
    $fclose(pin_file);
    $finish;
  end
  initial begin #30_000_000; $fatal(1, "SIMULATED_30MS_CASE_LIMIT"); end
endmodule
