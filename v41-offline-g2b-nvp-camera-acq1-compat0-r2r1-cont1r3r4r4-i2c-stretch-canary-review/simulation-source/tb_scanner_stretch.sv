`timescale 1ns/1ps

// Task-owned pin-level digital slave. Frozen scanner and fixed master are DUTs.
// Electrical NVP behaviour is deliberately outside this model.
module tb_scanner_stretch;
  import g2b_nvp_camera_scan1_manifest_pkg::*;
  logic clk=0, reset=1;
  always #8 clk=~clk; // 62.5 MHz, actual production master parameters below.
  logic cmd_valid, cmd_ready, cmd_write, cmd_accepted, busy, done, success, timeout;
  logic [7:0] cmd_reg, cmd_wdata, read_data;
  logic [3:0] cause;
  logic [31:0] txn_sequence;
  logic scl_release, sda_release, bus_idle;
  tri1 scl_pin, sda_pin;
  logic slave_low=0;
  logic slave_scl_low=0;
  assign scl_pin=scl_release ? 1'bz : 1'b0;
  assign scl_pin=slave_scl_low ? 1'b0 : 1'bz;
  assign sda_pin=sda_release ? 1'bz : 1'b0;
  assign sda_pin=slave_low ? 1'b0 : 1'bz;
  logic mmio_req_valid=0, mmio_req_ready, mmio_req_write=0;
  logic [16:0] mmio_req_addr=0;
  logic [31:0] mmio_req_wdata=0;
  logic [3:0] mmio_req_be=4'hf;
  logic mmio_rsp_valid, mmio_rsp_ready=1;
  logic [31:0] mmio_rsp_rdata;
  logic owns_bus, scanner_busy, scanner_done, lockout;
  integer testcase=0, phase_mode=0, command_count=0;
  bit current_target=0, target_select=0, target_verify=0;
  bit command_write=0;
  logic [7:0] command_reg=0, command_wdata=0;
  logic [7:0] slave_bank=0, received=0, register_byte=0, send_byte=0;
  integer phase=0, bit_count=0, starts=0, target_nack_count=0;
  bit active=0, ack_this=0;
  bit stretch_applied=0;
  integer stretch_cycles=0;
  integer target_timeout_count=0;

  nvp_i2c_fixed_master #(
    .CLK_HZ(62_500_000), .I2C_HZ(25_000)
  ) fixed_master (
    .clk(clk), .rst(reset), .raw_scl_i(scl_pin), .raw_sda_i(sda_pin),
    .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_write(cmd_write),
    .cmd_reg(cmd_reg), .cmd_wdata(cmd_wdata), .cmd_accepted(cmd_accepted),
    .busy(busy), .done(done), .success(success), .timeout(timeout),
    .error_cause(cause), .read_data(read_data),
    .transaction_sequence(txn_sequence), .scl_release(scl_release),
    .sda_release(sda_release), .bus_idle(bus_idle));

  g2b_nvp_camera_scan1 scanner (
    .clk(clk), .reset(reset), .autoinit_done(1'b1), .autoinit_busy(1'b0),
    .autoinit_error(1'b0), .nvp_reset_released(1'b1),
    .i2c_cmd_valid(cmd_valid), .i2c_cmd_ready(cmd_ready),
    .i2c_cmd_write(cmd_write), .i2c_cmd_reg(cmd_reg),
    .i2c_cmd_wdata(cmd_wdata), .i2c_cmd_accepted(cmd_accepted),
    .i2c_busy(busy), .i2c_done(done), .i2c_success(success),
    .i2c_timeout(timeout), .i2c_error_cause(cause),
    .i2c_transaction_sequence(txn_sequence), .i2c_read_data(read_data),
    .i2c_bus_idle(bus_idle), .mmio_req_valid(mmio_req_valid),
    .mmio_req_ready(mmio_req_ready), .mmio_req_write(mmio_req_write),
    .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
    .mmio_req_be(mmio_req_be), .mmio_rsp_valid(mmio_rsp_valid),
    .mmio_rsp_ready(mmio_rsp_ready), .mmio_rsp_rdata(mmio_rsp_rdata),
    .scanner_i2c_owns_bus(owns_bus), .scanner_busy(scanner_busy),
    .scanner_done(scanner_done), .bank_context_lockout(lockout));

  // A command is targeted by the scanner's legal output at acceptance. The
  // slave's phase counter below independently decodes wire bytes/ACK slots.
  always @(posedge clk) begin
    if(reset) begin
      command_count<=0; current_target<=0; target_select<=0;
      target_verify<=0; command_write<=0; command_reg<=0;
      command_wdata<=0;
    end else if(cmd_valid && cmd_ready) begin
      if(cmd_write && cmd_reg!=8'hff) $fatal(1,"PIN_UNAUTHORIZED_WRITE");
      command_count<=command_count+1;
      command_write<=cmd_write; command_reg<=cmd_reg;
      command_wdata<=cmd_wdata;
      target_select<=cmd_write && cmd_reg==8'hff && cmd_wdata==8'h05 &&
                     scanner.group_index==5;
      target_verify<=!cmd_write && cmd_reg==8'hff &&
                     scanner.group_index==5 && scanner.state==5;
      current_target<=(phase_mode==4) ?
          (!cmd_write && cmd_reg==8'hff && scanner.group_index==5 && scanner.state==5) :
          (cmd_write && cmd_reg==8'hff && cmd_wdata==8'h05 && scanner.group_index==5);
      if((cmd_write && cmd_reg==8'hff && cmd_wdata==8'h05 && scanner.group_index==5) ||
         (!cmd_write && cmd_reg==8'hff && scanner.group_index==5 && scanner.state==5))
        $display("PIN_TARGET_ACCEPT t=%0t seq=%0d group=%0d index=%0d write=%0d reg=%02h data=%02h bank=%02h",$time,txn_sequence+1,scanner.group_index,scanner.entry_index,cmd_write,cmd_reg,cmd_wdata,slave_bank);
    end
  end

  // START and repeated START are observed on the resolved open-drain pins.
  always @(negedge sda_pin) begin
    if(!reset && scl_pin===1'b1) begin
      if(!active) begin phase=0; starts=1; end
      else begin phase=3; starts=starts+1; end
      active=1; bit_count=0; received=0; slave_low=0;
      if(current_target) $display("PIN_START t=%0t ordinal=%0d repeated=%0d",$time,starts,starts>1);
    end
  end
  always @(posedge sda_pin) begin
    if(!reset && scl_pin===1'b1 && active) begin
      if(current_target) $display("PIN_STOP t=%0t bank=%02h",$time,slave_bank);
      active=0; phase=0; bit_count=0; slave_low=0;
    end
  end

  // For transmitted bytes: eight SCL rises decode the byte. The following
  // ninth rise is the ACK slot. The slave pulls SDA LOW only when ACKing.
  // For read data: it drives each LOW bit before its corresponding SCL rise.
  always @(negedge scl_pin) begin
    if(!reset && active) begin
      if(current_target && target_select && phase==2 && bit_count==8 &&
         !stretch_applied && (phase_mode==5 || phase_mode==6)) begin
        slave_scl_low=1;
        stretch_applied=1;
        $display("SCANNER_STRETCH_BEGIN t=%0t cycles=%0d",$time,stretch_cycles);
      end
      if(phase>=0 && phase<=3 && bit_count==8) begin
        ack_this=1;
        if(current_target &&
           ((phase_mode==1 && phase==2 && target_select) ||
            (phase_mode==2 && phase==0 && target_select) ||
            (phase_mode==3 && phase==1 && target_select) ||
            (phase_mode==4 && phase==3 && target_verify))) begin
          ack_this=0; target_nack_count=target_nack_count+1;
        end
        slave_low=ack_this;
        if(current_target)
          $display("PIN_ACK_SLOT_LOW t=%0t phase=%0d decoded=%02h ack=%0d scl=%b sda=%b",$time,phase,received,ack_this,scl_pin,sda_pin);
      end else if(phase==4 && bit_count<8) begin
        slave_low=!send_byte[7-bit_count];
      end else slave_low=0;
    end
  end
  always @(posedge scl_release) begin
    if(!reset && stretch_applied && slave_scl_low) begin
      #(stretch_cycles*16+8);
      slave_scl_low=0;
      if(phase_mode==6) slave_low=0;
      $display("SCANNER_STRETCH_RELEASE t=%0t",$time);
    end
  end
  always @(posedge scl_pin) begin
    if(!reset && active) begin
      if(phase>=0 && phase<=3) begin
        if(bit_count<8) begin
          received={received[6:0],sda_pin};
          bit_count=bit_count+1;
          if(bit_count==8) begin
            if((phase==0 && received!=8'h60) ||
               (phase==1 && received!=command_reg) ||
               (phase==2 && received!=command_wdata) ||
               (phase==3 && received!=8'h61))
              $fatal(1,"PIN_DECODE_MISMATCH phase=%0d byte=%02h command=%02h/%02h",phase,received,command_reg,command_wdata);
            if(current_target)
              $display("PIN_BYTE t=%0t phase=%0d value=%02h",$time,phase,received);
          end
        end else begin
          if(current_target)
            $display("PIN_ACK_SAMPLE t=%0t phase=%0d value=%b",$time,phase,sda_pin);
          if(phase==1) register_byte=received;
          if(phase==2 && ack_this && command_write && register_byte==8'hff)
            slave_bank=received;
          if(phase==3 && ack_this)
            send_byte=(register_byte==8'hff) ? slave_bank :
                      (slave_bank ^ register_byte ^ 8'h5a);
          if(phase==0) phase=1;
          else if(phase==1) phase=command_write ? 2 : 9;
          else if(phase==2) phase=9;
          else phase=4;
          bit_count=0; received=0;
        end
      end else if(phase==4) begin
        bit_count=bit_count+1;
        if(bit_count==8) phase=5;
      end else if(phase==5) begin
        if(current_target) $display("PIN_MASTER_NACK t=%0t value=%b",$time,sda_pin);
        phase=9;
      end
    end
  end

  always @(posedge clk) if(!reset && done &&
      (target_select || target_verify || current_target)) begin
    $display("MASTER_COMPLETION t=%0t seq=%0d success=%0d timeout=%0d raw=%0d bank=%02h",$time,txn_sequence,success,timeout,cause,slave_bank);
    if (target_select && phase_mode==6 && timeout && cause==4'h5)
      target_timeout_count <= target_timeout_count + 1;
  end

  task automatic start_scan;
    @(negedge clk); mmio_req_addr=17'h1200c; mmio_req_wdata=1;
    mmio_req_write=1; mmio_req_valid=1;
    @(negedge clk); mmio_req_valid=0; mmio_req_write=0;
  endtask
  integer guard;
  logic [3:0] expected_code;
  initial begin
    if($test$plusargs("PIN_STRETCH_CLEAN")) begin testcase=14; phase_mode=5; stretch_cycles=256; end
    if($test$plusargs("PIN_STRETCH_TIMEOUT")) begin testcase=14; phase_mode=6; stretch_cycles=2500; end
    if($test$plusargs("PIN_DATA")) begin testcase=15; phase_mode=1; end
    if($test$plusargs("PIN_WADDR")) begin testcase=16; phase_mode=2; end
    if($test$plusargs("PIN_REGADDR")) begin testcase=16; phase_mode=3; end
    if($test$plusargs("PIN_RADDR")) begin testcase=16; phase_mode=4; end
    if(testcase==0) $fatal(1,"PIN_CASE_REQUIRED");
    repeat(8) @(negedge clk); reset=0;
    repeat(8) @(negedge clk);
    if(fixed_master.CLK_HZ!=62_500_000 || fixed_master.I2C_HZ!=25_000 ||
       fixed_master.SCL_TIMEOUT_CYCLES!=1250 ||
       fixed_master.BUS_IDLE_TIMEOUT_CYCLES!=62500)
      $fatal(1,"REAL_MASTER_PARAMETER_MISMATCH");
    $display("REAL_MASTER_PARAMETERS clk=62500000 i2c=25000 divider=%0d scl_timeout=%0d bus_idle_timeout=%0d",fixed_master.DIVIDER,fixed_master.SCL_TIMEOUT_CYCLES,fixed_master.BUS_IDLE_TIMEOUT_CYCLES);
    start_scan(); guard=0;
    while(scanner.state!=((phase_mode==5)?10:12) && guard<20_000_000) begin
      @(negedge clk); guard++;
    end
    if(guard>=20_000_000) $fatal(1,"REAL_MASTER_CASE_CYCLE_LIMIT");
    repeat(5) @(negedge clk);
    if (phase_mode==5) begin
      if (!stretch_applied || target_nack_count!=0 ||
          scanner.snapshot_generation!=1 || scanner.valid_entry_count!=82 ||
          scanner.scan_transaction_count!=105 || !scanner.restore_verified ||
          scanner.first_error_index!=32'hFFFF_FFFF || slave_bank!=0)
        $fatal(1,"SCANNER_CLEAN_STRETCH_CONTRACT gen=%0d valid=%0d tx=%0d restore=%0d bank=%02h",scanner.snapshot_generation,scanner.valid_entry_count,scanner.scan_transaction_count,scanner.restore_verified,slave_bank);
      $display("SCANNER_STRETCH_CLEAN_PASS gen=%0d valid=%0d tx=%0d",scanner.snapshot_generation,scanner.valid_entry_count,scanner.scan_transaction_count);
      $finish;
    end
    if (phase_mode==6) begin
      if (!stretch_applied || target_timeout_count!=1 || target_nack_count!=0 ||
          scanner.first_error_detail!={8'h0,8'h05,8'hff,4'h0,4'h4} ||
          scanner.snapshot_generation!=0 || scanner.valid_entry_count!=37 ||
          !scanner.restore_verified || slave_bank!=0)
        $fatal(1,"SCANNER_TIMEOUT_STRETCH_CONTRACT timeout=%0d detail=%08h gen=%0d valid=%0d restore=%0d bank=%02h",target_timeout_count,scanner.first_error_detail,scanner.snapshot_generation,scanner.valid_entry_count,scanner.restore_verified,slave_bank);
      $display("SCANNER_STRETCH_TIMEOUT_PASS detail=%08h gen=%0d valid=%0d",scanner.first_error_detail,scanner.snapshot_generation,scanner.valid_entry_count);
      $finish;
    end
    expected_code=(phase_mode==1)?4'ha:(phase_mode==2)?4'h1:
                  (phase_mode==3)?4'h2:4'h3;
    if(scanner.first_error_detail!={8'h0,8'h05,8'hff,4'h0,expected_code} ||
       scanner.valid_entry_count!=37 || scanner.failed_entry_count!=0 ||
       scanner.retried_entry_count!=0 || scanner.first_error_index!=36 ||
       scanner.scan_transaction_count!=((phase_mode==4)?52:51) ||
       scanner.snapshot_generation!=0 || !scanner.restore_verified ||
       scanner.entry_bank!=0 || scanner.exit_bank!=0 || slave_bank!=0 ||
       target_nack_count!=1)
      $fatal(1,"PIN_SIGNATURE_MISMATCH phase=%0d detail=%08h valid=%0d index=%0d tx=%0d gen=%0d restore=%0d bank=%02h nack=%0d",phase_mode,scanner.first_error_detail,scanner.valid_entry_count,scanner.first_error_index,scanner.scan_transaction_count,scanner.snapshot_generation,scanner.restore_verified,slave_bank,target_nack_count);
    $display("PIN_OBS phase=%0d status=%08h gen=%0d valid=%0d failed=%0d retried=%0d index=%0d detail=%08h flags=%08h commands=%0d entry=%02h exit=%02h",phase_mode,scanner.status_word(),scanner.snapshot_generation,scanner.valid_entry_count,scanner.failed_entry_count,scanner.retried_entry_count,scanner.first_error_index,scanner.first_error_detail,scanner.scan_flags,scanner.scan_transaction_count,scanner.entry_bank,scanner.exit_bank);
    $display("TEST_EXECUTION_PASS T%02d phase=%0d",testcase,phase_mode);
    $finish;
  end
  initial begin #1_000_000_000; $fatal(1,"PIN_ABSOLUTE_SIM_TIME_BACKSTOP"); end
endmodule
