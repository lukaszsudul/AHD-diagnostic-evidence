`timescale 1ns/1ps

// Task-owned logical master. DUT scanner and manifest are unmodified.
module tb_bank5_mock;
  import g2b_nvp_camera_scan1_manifest_pkg::*;
  logic clk=0, reset=1;
  always #8 clk=~clk;
  logic autoinit_done=1, autoinit_busy=0, autoinit_error=0, nvp_reset_released=1;
  logic cmd_valid, cmd_ready, cmd_write, cmd_accepted, busy, done, success, timeout;
  logic [7:0] cmd_reg, cmd_wdata, read_data;
  logic [3:0] cause;
  logic [31:0] txn_sequence;
  logic bus_idle;
  logic mmio_req_valid=0, mmio_req_ready, mmio_req_write=0;
  logic [16:0] mmio_req_addr=0;
  logic [31:0] mmio_req_wdata=0;
  logic [3:0] mmio_req_be=4'hf;
  logic mmio_rsp_valid, mmio_rsp_ready=1;
  logic [31:0] mmio_rsp_rdata;
  logic owns_bus, scanner_busy, scanner_done, lockout;
  integer testcase=0, mode=0, raw_override=0, timeout_override=0;
  integer latency=0, accepted_total=0, fault_count=0;
  bit fault_armed=0, fault_used=0;
  logic [7:0] bank=0;
  logic latched_write;
  logic [7:0] latched_reg, latched_wdata;
  integer latched_state, latched_entry;
  bit latched_retry;
  assign cmd_ready=!busy;
  assign bus_idle=!busy;

  g2b_nvp_camera_scan1 dut(
    .clk(clk), .reset(reset), .autoinit_done(autoinit_done),
    .autoinit_busy(autoinit_busy), .autoinit_error(autoinit_error),
    .nvp_reset_released(nvp_reset_released),
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

  always_ff @(posedge clk) begin
    if (reset) begin
      cmd_accepted<=0; busy<=0; done<=0; success<=0; timeout<=0;
      cause<=0; txn_sequence<=0; read_data<=0; bank<=0; latency<=0;
      accepted_total<=0; fault_count<=0; fault_used<=0;
      latched_write<=0; latched_reg<=0; latched_wdata<=0;
      latched_state<=0; latched_entry<=0; latched_retry<=0;
    end else begin
      cmd_accepted<=0; done<=0;
      if (!busy && cmd_valid && cmd_ready) begin
        if (cmd_write && cmd_reg!=8'hff) $fatal(1,"UNAUTHORIZED_MOCK_WRITE");
        cmd_accepted<=1; busy<=1; txn_sequence<=txn_sequence+1;
        accepted_total<=accepted_total+1; latency<=20;
        latched_write<=cmd_write; latched_reg<=cmd_reg;
        latched_wdata<=cmd_wdata; latched_state<=dut.state;
        latched_entry<=dut.entry_index; latched_retry<=dut.retry_used;
        if (cmd_write && cmd_reg==8'hff && cmd_wdata==8'h05)
          $display("BANK5_SELECT_ACCEPT seq=%0d prior_bank=%02h entry=%0d group=%0d gen=%0d",txn_sequence+1,bank,dut.entry_index,dut.group_index,dut.snapshot_generation);
      end else if (busy && latency>0) latency<=latency-1;
      else if (busy) begin
        busy<=0; done<=1; success<=1; timeout<=0; cause<=0;
        if (latched_write) bank<=latched_wdata;
        else if (latched_reg==8'hff) read_data<=bank;
        else read_data<=bank ^ latched_reg ^ 8'h5a;
        if (fault_armed && !fault_used && latched_state==4 &&
            latched_write && latched_reg==8'hff && latched_wdata==8'h05 &&
            (mode==1 || mode==2 || mode==3 || mode==4 || mode==7 ||
             mode==8 || mode==11 || mode==12 || mode==13)) begin
          success<=0; fault_used<=1; fault_count<=fault_count+1;
          if (mode!=2) bank<=bank; // no ACK does not itself prove bank acceptance
          case(mode)
            1,2,11: cause<=4;
            3: cause<=1;
            4: cause<=2;
            7: begin cause<=5; timeout<=1; end
            8: begin cause<=6; timeout<=1; end
            12,13: begin cause<=raw_override[3:0]; timeout<=timeout_override[0]; end
            default: $fatal(1,"MOCK_MODE_UNREACHABLE");
          endcase
          $display("SELECT_FAULT mode=%0d raw=%0d timeout=%0d bank_after=%02h seq=%0d",mode,
                   mode==12 || mode==13 ? raw_override : (mode==3 ? 1 : (mode==4 ? 2 : (mode==7 ? 5 : (mode==8 ? 6 : 4)))),
                   mode==7 || mode==8 || ((mode==12 || mode==13) && timeout_override),
                   mode==2 ? 8'h05 : bank,txn_sequence);
        end else if (fault_armed && !fault_used && latched_state==5 &&
                     (mode==5 || mode==6) && bank==8'h05) begin
          fault_used<=1; fault_count<=fault_count+1;
          if (mode==5) begin success<=0; cause<=3; end
          else read_data<=8'h04;
          $display("VERIFY_FAULT mode=%0d seq=%0d",mode,txn_sequence);
        end else if (fault_armed && latched_state==6 && latched_entry==4 &&
                     (mode==9 || mode==10) && (!latched_retry || mode==10)) begin
          success<=0; cause<=2; fault_used<=1; fault_count<=fault_count+1;
          $display("ENTRY_REGADDR_NACK retry=%0d seq=%0d",latched_retry,txn_sequence);
        end else if (fault_armed && mode==11 && latched_state==7) begin
          success<=0; cause<=1; bank<=bank;
          fault_count<=fault_count+1;
          $display("RESTORE_FAULT seq=%0d",txn_sequence);
        end
      end
    end
  end

  task automatic apply_reset;
    reset=1; repeat(5) @(negedge clk); reset=0; repeat(4) @(negedge clk);
  endtask
  task automatic mmio_command(input logic [31:0] value);
    @(negedge clk); mmio_req_addr=17'h1200c; mmio_req_wdata=value;
    mmio_req_write=1; mmio_req_valid=1;
    @(negedge clk); mmio_req_valid=0; mmio_req_write=0;
  endtask
  task automatic mmio_read(input logic [16:0] addr, output logic [31:0] value);
    integer guard;
    @(negedge clk); mmio_req_addr=addr; mmio_req_write=0; mmio_req_valid=1;
    guard=0; while(!mmio_req_ready && guard<200) begin @(negedge clk); guard++; end
    if(!mmio_req_ready) $fatal(1,"MMIO_READY_TIMEOUT");
    @(negedge clk); mmio_req_valid=0;
    guard=0; while(!mmio_rsp_valid && guard<200) begin @(negedge clk); guard++; end
    if(!mmio_rsp_valid) $fatal(1,"MMIO_RESPONSE_TIMEOUT");
    value=mmio_rsp_rdata; @(negedge clk);
  endtask
  task automatic start_and_wait(input bit expect_error);
    integer guard;
    mmio_command(1);
    guard=0;
    while(!scanner_done && dut.state!=12 && guard<40000) begin
      @(negedge clk); guard++;
    end
    if(guard>=40000) $fatal(1,"SCANNER_CASE_CYCLE_LIMIT mode=%0d",mode);
    repeat(3) @(negedge clk);
    if(expect_error && dut.state!=12) $fatal(1,"EXPECTED_ERROR_NOT_SEEN mode=%0d state=%0d",mode,dut.state);
    if(!expect_error && !scanner_done) $fatal(1,"EXPECTED_PUBLICATION_NOT_SEEN mode=%0d state=%0d",mode,dut.state);
  endtask
  task automatic ack_to_idle;
    integer guard;
    mmio_command(2); guard=0;
    while(dut.state!=0 && guard<100) begin @(negedge clk); guard++; end
    if(dut.state!=0) $fatal(1,"ACK_DID_NOT_IDLE");
    repeat(2) @(negedge clk);
  endtask
  task automatic check_clean(input integer expected_generation);
    integer guard;
    guard=0;
    while(!dut.telemetry_complete && guard<100) begin @(negedge clk); guard++; end
    if(!dut.telemetry_complete || dut.valid_entry_count!=82 ||
       dut.scan_transaction_count!=105 || dut.snapshot_generation!=expected_generation ||
       dut.failed_entry_count!=0 || dut.retried_entry_count!=0 ||
       !dut.restore_verified || bank!=0 || dut.telemetry_committed_groups!=10 ||
       dut.telemetry_committed_entries!=82 || dut.scan_flags!=32'h00690005)
      $fatal(1,"CLEAN_SCAN_MISMATCH gen=%0d valid=%0d tx=%0d flags=%08h",dut.snapshot_generation,dut.valid_entry_count,dut.scan_transaction_count,dut.scan_flags);
    $display("CLEAN gen=%0d entries=%0d groups=%0d commands=%0d",dut.snapshot_generation,dut.valid_entry_count,dut.telemetry_committed_groups,dut.scan_transaction_count);
  endtask
  task automatic print_failure;
    logic [31:0] st,gen,valid,failed,retried,idx,detail,flags,entry,exitb;
    mmio_read(17'h12010,st); mmio_read(17'h12014,gen);
    mmio_read(17'h1201c,valid); mmio_read(17'h12020,failed);
    mmio_read(17'h12024,retried); mmio_read(17'h12028,idx);
    mmio_read(17'h1202c,detail); mmio_read(17'h1203c,flags);
    mmio_read(17'h12030,entry); mmio_read(17'h12034,exitb);
    $display("OBS status=%08h gen=%0d valid=%0d failed=%0d retried=%0d index=%0d detail=%08h flags=%08h commands=%0d entry=%08h exit=%08h bank=%02h lockout=%0d",st,gen,valid,failed,retried,idx,detail,flags,flags[31:16],entry,exitb,bank,lockout);
  endtask
  task automatic expect_select(input logic [3:0] expected_error,
                               input integer expected_tx,
                               input bit expected_restore);
    if(dut.valid_entry_count!=37 || dut.failed_entry_count!=0 ||
       dut.retried_entry_count!=0 || dut.first_error_index!=36 ||
       dut.first_error_detail!={8'h0,8'h05,8'hff,4'h0,expected_error} ||
       dut.scan_transaction_count!=expected_tx ||
       dut.restore_verified!=expected_restore ||
       dut.snapshot_generation!=0)
      $fatal(1,"SELECT_SIGNATURE_MISMATCH detail=%08h idx=%0d tx=%0d restored=%0d gen=%0d",dut.first_error_detail,dut.first_error_index,dut.scan_transaction_count,dut.restore_verified,dut.snapshot_generation);
  endtask
  integer g,i,j,first;
  logic [31:0] v;
  logic [3:0] expected_map;
  initial begin
    if($test$plusargs("CASE_1")) testcase=1;
    if($test$plusargs("CASE_2")) testcase=2;
    if($test$plusargs("CASE_3")) testcase=3;
    if($test$plusargs("CASE_4")) testcase=4;
    if($test$plusargs("CASE_5")) testcase=5;
    if($test$plusargs("CASE_6")) testcase=6;
    if($test$plusargs("CASE_7")) testcase=7;
    if($test$plusargs("CASE_8")) testcase=8;
    if($test$plusargs("CASE_9")) testcase=9;
    if($test$plusargs("CASE_10")) testcase=10;
    if($test$plusargs("CASE_11")) testcase=11;
    if($test$plusargs("CASE_12")) testcase=12;
    if($test$plusargs("CASE_13")) testcase=13;
    if($test$plusargs("CASE_14")) testcase=14;
    if(testcase==0) $fatal(1,"CASE_PLUSARG_REQUIRED");
    if(SCAN1_ENTRY_COUNT!=82 || SCAN1_GROUP_COUNT!=10) $fatal(1,"MANIFEST_COUNTS");
    first=0;
    for(g=0;g<10;g++) begin
      if(scan1_group_start(g)!=first) $fatal(1,"GROUP_START g=%0d",g);
      first+=scan1_group_count(g);
    end
    if(first!=82 || scan1_group_start(5)!=37 || scan1_group_start(6)!=48)
      $fatal(1,"MANIFEST_SCHEDULE");
    $display("MANIFEST_SCHEDULE_PASS starts=0,1,4,11,27,37,48,59,70,81 counts=1,3,7,16,10,11,11,11,11,1");
    apply_reset();
    case(testcase)
      1: begin
        start_and_wait(0); check_clean(1); ack_to_idle();
        if(dut.status_word()!=32'h11) $fatal(1,"CLEAN_ACK_STATUS");
      end
      2: begin
        for(i=1;i<=26;i++) begin
          start_and_wait(0); check_clean(i); ack_to_idle();
        end
        mode=1; fault_armed=1;
        start_and_wait(1); print_failure();
        if(dut.status_word()!=32'h00000c18 || dut.snapshot_generation!=26 ||
           dut.valid_entry_count!=37 || dut.failed_entry_count!=0 ||
           dut.retried_entry_count!=0 || dut.first_error_index!=36 ||
           dut.first_error_detail!=32'h0005ff0a ||
           dut.scan_flags!=32'h00330004 || dut.scan_transaction_count!=51 ||
           dut.entry_bank_valid!=1 || dut.entry_bank!=0 ||
           dut.restore_verified!=1 || dut.exit_bank!=0 || bank!=0 || !fault_used)
          $fatal(1,"HISTORICAL_SIGNATURE_MISMATCH");
        $display("HISTORICAL_SIGNATURE_MATCH generation=26 prior_complete=26 failed_attempt_unpublished=1");
        ack_to_idle();
        if(dut.status_word()!=32'h11 || dut.snapshot_generation!=26 ||
           accepted_total!=26*105+51) $fatal(1,"ACK_OR_COMMAND_COUNT");
        $display("ACK_CLEAR_MATCH status=%08h commands_total=%0d",dut.status_word(),accepted_total);
      end
      3: begin
        for(j=1;j<=2;j++) begin
          apply_reset(); mode=j; fault_armed=1;
          start_and_wait(1); expect_select(4'ha,51,1); print_failure();
          if(bank!=0) $fatal(1,"RESTORE_BANK_DISPOSITION_%0d",j);
          $display("BANK_DISPOSITION_PASS accepted_despite_nack=%0d",j==2);
        end
      end
      4,5,6,7,8,9: begin
        mode=(testcase==4)?3:(testcase==5)?4:(testcase==6)?5:
             (testcase==7)?6:(testcase==8)?7:8;
        fault_armed=1; start_and_wait(1); print_failure();
        if(testcase==4) expect_select(1,51,1);
        if(testcase==5) expect_select(2,51,1);
        if(testcase==6 && (dut.first_error_detail!=32'h0005ff03 ||
                           dut.scan_transaction_count!=52 || dut.first_error_index!=36))
          $fatal(1,"VERIFY_RADDR_DISTINCTION");
        if(testcase==7 && (dut.first_error_detail!=32'h0005ff06 ||
                           dut.scan_transaction_count!=52)) $fatal(1,"VERIFY_MISMATCH_DISTINCTION");
        if(testcase==8) expect_select(4,51,1);
        if(testcase==9) expect_select(5,51,1);
      end
      10: begin
        for(j=0;j<32;j++) begin
          apply_reset(); mode=12; raw_override=j%16;
          timeout_override=j/16; fault_armed=1;
          start_and_wait(1);
          expected_map=timeout_override ? (raw_override==6 ? 5 : 4) :
                       ((raw_override>=1 && raw_override<=3) ? raw_override : 10);
          if(dut.first_error_detail!={8'h0,8'h05,8'hff,4'h0,expected_map})
            $fatal(1,"MAPPING_CASE raw=%0d timeout=%0d observed=%08h",raw_override,timeout_override,dut.first_error_detail);
          $display("MAP raw=%0d timeout=%0d scanner=%0d classification=SYNTHETIC_INTERFACE_EXCEPT_REACHABLE_COMBINATIONS",raw_override,timeout_override,expected_map);
        end
      end
      11: begin
        mode=13; raw_override=0; timeout_override=0; fault_armed=1;
        start_and_wait(1); expect_select(10,51,1); print_failure();
        $display("INTERFACE_WITNESS_FAIL_SUCCESS_ZERO_CAUSE_ZERO maps=0xA synthetic=1");
      end
      12: begin
        mode=9; fault_armed=1; start_and_wait(0);
        first=0;
        while(!dut.telemetry_complete && first<100) begin @(negedge clk); first++; end
        if(!dut.telemetry_complete || dut.valid_entry_count!=82 ||
           dut.snapshot_generation!=1 || !dut.restore_verified ||
           dut.retried_entry_count!=1 || dut.scan_transaction_count!=106 ||
           dut.telemetry_event_count!=1 || dut.scan_flags!=32'h006a0005)
          $fatal(1,"RETRY_SUCCESS_RECEIPT");
        $display("RETRY_SUCCESS_ENTRY4 event_count=%0d tx=%0d",dut.telemetry_event_count,dut.scan_transaction_count);
      end
      13: begin
        mode=10; fault_armed=1; start_and_wait(1); print_failure();
        if(dut.valid_entry_count!=4 || dut.failed_entry_count!=1 ||
           dut.retried_entry_count!=1 || dut.snapshot_generation!=0 ||
           dut.first_error_detail[3:0]!=2 || dut.scan_transaction_count!=15 ||
           !dut.restore_verified) $fatal(1,"RETRY_FAILURE_RECEIPT");
        $display("RETRY_FAILURE_PASS");
        apply_reset(); mode=11; fault_armed=1;
        start_and_wait(1); print_failure();
        if(!lockout || dut.restore_verified || dut.snapshot_generation!=0 ||
           dut.first_error_detail!=32'h0005ff0a || dut.scan_transaction_count!=50)
          $fatal(1,"RESTORE_FAILURE_LOCKOUT_RECEIPT");
        $display("RESTORE_FAILURE_LOCKOUT_PASS");
      end
      14: begin
        mode=1; fault_armed=1; start_and_wait(1); first=accepted_total;
        ack_to_idle();
        if(dut.status_word()!=32'h11 || dut.snapshot_generation!=0 ||
           accepted_total!=first) $fatal(1,"ACK_CLEAR_EXTRA_ACTION");
        $display("ACK_CLEAR_NO_EXTRA_COMMAND_PASS accepted_before=%0d after=%0d",first,accepted_total);
      end
      default: $fatal(1,"UNSUPPORTED_CASE=%0d",testcase);
    endcase
    $display("TEST_EXECUTION_PASS T%02d",testcase);
    $finish;
  end
  initial begin #200_000_000; $fatal(1,"HOST_PROCESS_BACKSTOP_SIM_TIME"); end
endmodule
