`timescale 1ns/1ps

// Pin-level, open-drain slave: receive bytes from physical SCL edges, drive
// ACKs/data as a slave, and recognize master START/STOP transitions. Internal
// telemetry is an independent scoreboard, never the source of ACK timing.
module r1i_wire_test #(parameter integer REF_MODE=0, SELECT_MODE=-1);
  localparam integer CLK_HZ=1000000, I2C_HZ=25000, TICK=21;
  logic clk=0, rst=1, start=0;
  always #500 clk=~clk;
  wire scl_oen,sda_oen,busy,done,any_error;
  logic slave_sda=1,slave_scl=1;
  wire scl_i=scl_oen & slave_scl, sda_i=sda_oen & slave_sda;
  wire [127:0] values,afe_values;
  wire [63:0] output_values;
  wire [15:0] read_errors,aux_errors,afe_errors,nack_count,timeout_count,serial_next;
  wire [7:0] write_errors,original_ff,restored_ff,meta_bank,phys_bank;
  wire phys_bank_valid,first_valid,record_valid;
  wire [7:0] phase_dbg,step_dbg,last_reg,last_wdata,last_rdata,i2c_state,first_code;
  wire [2:0] last_op;
  wire [255:0] phase_counts;
  wire [127:0] txn_counts;
  wire [191:0] failed_record;
  wire [31:0] bank_errors;
  wire [1023:0] poc;
  r1i_master_test_adapter #(.REF_MODE(REF_MODE),.CLK_HZ(CLK_HZ),.I2C_HZ(I2C_HZ)) dut(.*);

  function automatic int unsigned p(input integer w);
    p=poc[32*w +: 32];
  endfunction
  typedef enum {RX_BITS,RX_ACK,TX_BITS,TX_NACK,WAIT_STOP} slave_state_t;
  slave_state_t bstate=RX_BITS;
  integer mode=0,cycle=0,starts=0,stops=0,byte_count=0,read_bits=0;
  integer bits=0,byte_role=0,ack_phase=0,read_bit=7,late_count=0;
  integer target_serial=-1,target_attempt=0,attempt_failures=0;
  integer nack_injections=0,record_count=0,nack_tail_rises=0;
  integer target_records=0,first_record_serial=-1,read_changes_high=0;
  integer timeout_hold_cycles=0,stop_cycle=0,expected_backoff=0;
  integer trace_fd=0,txn_wire_bytes=0,allack_cycles=0,only_mode=SELECT_MODE;
  integer previous_i2c_state=0,busfree_cycle=0,retry_timer_checks=0;
  integer physical_high_cycles=0;
  logic [255:0] previous_phase_counts=0;
  logic active=0,repeat_start=0,previous_scl=1,previous_master_sda=1;
  logic ack_bad=0,nack_seen=0,ack_has_risen=0,late_pending=0;
  logic current_target=0,timeout_injected=0,first_error_prev=0;
  integer first_error_edges=0,stable_guard_errors=0;
  logic [7:0] rx_byte=0,wire_reg=0,wire_wdata=0,model_bank=8'h07;
  logic [7:0] read_value=0,txn_bytes[0:3];
  logic [31:0] target_signature=0;
  logic [15:0] target_slot=0;

  function automatic int failures_for_mode(input int m);
    if(m==7) return 3;
    if(m==8 || m==15 || m==16) return 4;
    return 1;
  endfunction
  function automatic bit choose_target(input int m);
    if(m==4 || m==12 || m==15) return last_op==3'b101;
    if(m==13 || m==14 || m==16) return last_op==3'b110;
    return 1;
  endfunction
  function automatic bit inject_nack(input int phase);
    if(!current_target || target_attempt>failures_for_mode(mode)) return 0;
    case(mode)
      2,6,7,8: return phase==0;
      3: return phase==1;
      4,12,15: return phase==2;
      5,13,16: return phase==3;
      default: return 0;
    endcase
  endfunction
  function automatic int backoff(input int failed_attempt);
    case(failed_attempt) 1:return 100; 2:return 500; default:return 2000; endcase
  endfunction

  always @(negedge clk) begin : wire_bfm
    bit sc,begin_evt,end_evt,rise_evt,fall_evt;
    logic [7:0] completed;
    cycle=cycle+1;
    if(rst) begin
      slave_sda=1; slave_scl=1; bstate=RX_BITS; active=0;
      previous_scl=1; previous_master_sda=1; bits=0; byte_role=0;
      starts=0; stops=0; byte_count=0; read_bits=0; model_bank=8'h07;
      rx_byte=0; wire_reg=0; wire_wdata=0; read_value=0;
      target_serial=-1; target_attempt=0; current_target=0;
      nack_injections=0; record_count=0; target_records=0;
      first_record_serial=-1; timeout_injected=0; timeout_hold_cycles=0;
      late_pending=0; late_count=0; read_changes_high=0;
      nack_seen=0; ack_has_risen=0; first_error_prev=0;
      first_error_edges=0; stop_cycle=0; expected_backoff=0;
      txn_wire_bytes=0; stable_guard_errors=0;
      previous_i2c_state=0; busfree_cycle=0; retry_timer_checks=0;
      physical_high_cycles=0; previous_phase_counts=0;
    end else begin
      if(mode==9 && timeout_injected && slave_scl==0) begin
        timeout_hold_cycles=timeout_hold_cycles+1;
        // Let the actual RTL timeout, not a synthetic timer, cause release.
        if(p(28)>0) slave_scl=1;
      end
      sc=scl_oen & slave_scl;
      if(REF_MODE==0) begin
        for(integer ph=0;ph<4;ph=ph+1)
          if(phase_counts[64*ph +: 32]!=previous_phase_counts[64*ph +: 32] &&
             (!previous_scl || physical_high_cycles<TICK))
            $fatal(1,"ACK decision lacked prior physically-high full dwell phase%0d cycles%0d",ph,physical_high_cycles);
      end
      previous_phase_counts=phase_counts;
      if(sc) physical_high_cycles=physical_high_cycles+1;
      else physical_high_cycles=0;
      begin_evt=previous_master_sda && !sda_oen && sc && previous_scl;
      end_evt=!previous_master_sda && sda_oen && sc;
      rise_evt=!previous_scl && sc;
      fall_evt=previous_scl && !sc;
      if(end_evt && active && !slave_sda)
        $fatal(1,"intended master STOP did not raise physical SDA: slave still owns ACK/data; mode%0d state%0d",mode,i2c_state);
      if(REF_MODE==0 && end_evt && active && physical_high_cycles<TICK)
        $fatal(1,"STOP SDA release before qualified physical SCL high dwell");
      if(begin_evt) begin
        repeat_start=active;
        if(!active) begin
          starts=starts+1; txn_wire_bytes=0; nack_seen=0; nack_tail_rises=0;
          if(target_serial<0 && mode>1 && choose_target(mode)) target_serial=serial_next;
          current_target=serial_next==target_serial;
          if(current_target) begin
            target_attempt=target_attempt+1;
            if(target_attempt==1) begin
              target_signature={phase_dbg,last_op,5'b0,last_reg,last_wdata};
              target_slot={8'b0,step_dbg};
            end else begin
              if({phase_dbg,last_op,5'b0,last_reg,last_wdata}!==target_signature ||
                 {8'b0,step_dbg}!==target_slot)
                $fatal(1,"retry changed logical transaction bytes/phase/slot");
              if(expected_backoff>0 && cycle-stop_cycle<expected_backoff+TICK)
                $fatal(1,"retry began before completed STOP/bus-free plus fixed backoff");
            end
          end
          if(phase_dbg==1 && last_op==3'b010 &&
             (!phys_bank_valid || phys_bank!==meta_bank))
            $fatal(1,"target write before exact verified bank");
        end
        active=1; bstate=RX_BITS; bits=0; rx_byte=0;
        byte_role=repeat_start ? 3:0; slave_sda=1;
      end else if(end_evt && active) begin
        stops=stops+1;
        if(nack_seen && nack_tail_rises>1)
          $fatal(1,"first-NACK abort emitted later byte/data clocks: %0d",nack_tail_rises);
        if(!nack_seen && txn_wire_bytes==3 && txn_bytes[0]==8'h60 &&
           txn_bytes[1]==8'hff && byte_role==2)
          model_bank=wire_wdata;
        if(current_target && (nack_seen || (mode==9 && target_attempt==1))) begin
          stop_cycle=cycle; expected_backoff=backoff(target_attempt);
        end
        if(trace_fd!=0 && mode==0) begin
          if(txn_wire_bytes==3 && byte_role==3)
            $fdisplay(trace_fd,"TX %0d %02x %02x %02x R%02x",stops,
              txn_bytes[0],txn_bytes[1],txn_bytes[2],read_value);
          else
            $fdisplay(trace_fd,"TX %0d %02x %02x %02x W",stops,
              txn_bytes[0],txn_bytes[1],txn_bytes[2]);
        end
        active=0; slave_sda=1; late_pending=0; bstate=RX_BITS; bits=0;
      end else if(active) begin
        if(rise_evt) begin
          case(bstate)
            RX_BITS: begin
              rx_byte={rx_byte[6:0],sda_i}; bits=bits+1;
              if(bits==8) begin
                completed=rx_byte;
                if(txn_wire_bytes>=4) $fatal(1,"unexpected extra transaction byte");
                txn_bytes[txn_wire_bytes]=completed;
                txn_wire_bytes=txn_wire_bytes+1; byte_count=byte_count+1;
                case(byte_role)
                  0: begin
                    if(completed!==8'h60) $fatal(1,"wrong write address %02x",completed);
                    ack_phase=0;
                  end
                  1: begin
                    if(completed!==last_reg) $fatal(1,"wire register differs from requested byte");
                    wire_reg=completed; ack_phase=1;
                  end
                  2: begin
                    if(completed!==last_wdata) $fatal(1,"wire data differs from requested byte");
                    wire_wdata=completed; ack_phase=2;
                  end
                  3: begin
                    if(completed!==8'h61) $fatal(1,"wrong repeated read address");
                    ack_phase=3;
                  end
                endcase
              end
            end
            RX_ACK: begin
              ack_has_risen=1;
              if(ack_bad) begin
                nack_seen=1; nack_tail_rises=0; nack_injections=nack_injections+1;
              end else if(mode==1) begin
                late_pending=1; late_count=2;
              end
            end
            TX_BITS: begin
              read_bits=read_bits+1;
              if(mode==10 || mode==1) begin late_pending=1; late_count=2; end
            end
            TX_NACK: if(sda_oen!==1'b1) $fatal(1,"master did not NACK last read byte");
            WAIT_STOP: if(nack_seen) nack_tail_rises=nack_tail_rises+1;
          endcase
        end
        if(fall_evt) begin
          case(bstate)
            RX_BITS: if(bits==8) begin
              bstate=RX_ACK; ack_bad=inject_nack(ack_phase); ack_has_risen=0;
              slave_sda=(ack_bad || mode==1) ? 1:0;
              // C1 adapter: keep the end-of-LOW filtered observation at NACK,
              // then qualify ACK before the first filtered-SCL-HIGH edge.
              if(mode==1) begin late_pending=1; late_count=17; end
              if((mode==9 || mode==17) && current_target && target_attempt==1 && ack_phase==0 &&
                 !timeout_injected) begin
                slave_scl=0; timeout_injected=1;
              end
            end
            RX_ACK: if(ack_has_risen) begin
              late_pending=0; slave_sda=1;
              if(ack_bad) bstate=WAIT_STOP;
              else if(byte_role==3) begin
                read_value=(wire_reg==8'hff) ? model_bank:8'ha6;
                if(mode==14 && current_target && target_attempt==1) read_value=~model_bank;
                read_bit=7; bstate=TX_BITS;
                slave_sda=(mode==10 || mode==1) ? ~read_value[7]:read_value[7];
              end else if(byte_role==2) bstate=WAIT_STOP;
              else begin bstate=RX_BITS; bits=0; rx_byte=0; byte_role=byte_role+1; end
            end
            TX_BITS: begin
              late_pending=0;
              if(read_bit==0) begin bstate=TX_NACK; slave_sda=1; end
              else begin
                read_bit=read_bit-1;
                slave_sda=(mode==10 || mode==1) ? ~read_value[read_bit]:read_value[read_bit];
              end
            end
            TX_NACK: begin bstate=WAIT_STOP; slave_sda=1; end
            default: begin end
          endcase
        end
        if(late_pending && !rise_evt) begin
          if(late_count>0) late_count=late_count-1;
          else begin
            if(!sc && !(mode==1 && bstate==RX_ACK)) $fatal(1,"late slave stimulus was not during physical SCL high");
            if(bstate==RX_ACK) slave_sda=(mode==1 && sc) ? 1:0;
            else if(bstate==TX_BITS) begin
              slave_sda=read_value[read_bit]; read_changes_high=read_changes_high+1;
            end
            late_pending=0;
          end
        end
      end
      if(first_valid && !first_error_prev) first_error_edges=first_error_edges+1;
      first_error_prev=first_valid;
      // BUS_FREE36 -> STORE_RESULT30 is the completed filtered bus-free proof.
      // RETRY_START38 begins only after the exact fixed base-clock backoff.
      if(previous_i2c_state==36 && i2c_state==30) busfree_cycle=cycle;
      if(i2c_state==38 && previous_i2c_state!=38) begin
        if(cycle-busfree_cycle!=backoff(target_attempt))
          $fatal(1,"fixed backoff mismatch from completed bus-free: observed%0d expected%0d",
            cycle-busfree_cycle,backoff(target_attempt));
        retry_timer_checks=retry_timer_checks+1;
      end
      previous_i2c_state=i2c_state;
      if(record_valid) begin
        record_count=record_count+1;
        if(failed_record[55:52]!=0) begin
          if(failed_record[58:56]!==3'd1)
            $fatal(1,"failed attempt must contain exactly first qualified NACK");
          case(failed_record[55:52])
            4'h1: if(failed_record[51:48]!==4'h1) $fatal(1,"WADDR abort reached later phase");
            4'h2: if(failed_record[51:48]!==4'h3) $fatal(1,"REG abort reached later phase");
            4'h4: if(failed_record[51:48]!==4'h7) $fatal(1,"DATA abort bitmap invalid");
            4'h8: if(failed_record[51:48]!==4'hb || failed_record[90])
              $fatal(1,"RADDR abort read data or bitmap invalid");
            default: $fatal(1,"multiple NACK phases in an aborted attempt");
          endcase
        end
        if(first_record_serial<0) first_record_serial=failed_record[15:0];
        if(mode!=14 && mode!=17 && failed_record[15:0]!=first_record_serial)
          $fatal(1,"retry changed logical transaction index");
        target_records=target_records+1;
      end
      previous_scl=sc; previous_master_sda=sda_oen;
    end
  end

  task automatic begin_run(input integer m);
    @(posedge clk); #50; rst=1; start=0; mode=m;
    repeat(12) @(posedge clk);
    #50; rst=0;
    repeat(12) @(posedge clk);
    #50; start=1;
    repeat(3) @(posedge clk);
    #50; start=0;
  endtask
  task automatic await_done;
    integer c;
    c=0;
    while(!done && c<2000000) begin @(posedge clk); c=c+1; end
    if(!done) $fatal(1,"mode%0d bounded completion timeout state%0d",mode,i2c_state);
    repeat(4) @(posedge clk);
    if(bank_errors!=0) $fatal(1,"mode%0d bank invariant errors %0d",mode,bank_errors);
    if(mode!=17 && (txn_counts[31:0]!=starts || txn_counts[63:32]!=starts || stops!=starts))
      $fatal(1,"mode%0d wire start/stop and physical attempt counters differ %0d/%0d/%0d/%0d",
        mode,starts,stops,txn_counts[31:0],txn_counts[63:32]);
    if(nack_count!=nack_injections ||
       phase_counts[63:32]+phase_counts[127:96]+phase_counts[191:160]+
       phase_counts[255:224]!=nack_count)
      $fatal(1,"mode%0d raw/phase NACK counters disagree with physical injection",mode);
    if(REF_MODE==0 && (p(0)!=32'h52314950 || p(1)!=1 || p(2)!=32'h3f))
      $fatal(1,"POC identity changed");
    if(REF_MODE==0 && p(19)!=nack_count) $fatal(1,"raw qualified count hidden");
  endtask
  task automatic expect_recovery(input integer n,input integer success_word);
    if(any_error || first_valid || p(20)!=1 || p(21)!=n || p(22)!=0 || p(23)!=0 ||
       p(success_word)!=1 || p(19)!=n || record_count!=n)
      $fatal(1,"mode%0d bad recovery err%0d first%0d recovered%0d/%0d terminal%0d/%0d raw%0d records%0d",
        mode,any_error,first_valid,p(20),p(21),p(22),p(23),p(19),record_count);
  endtask

  initial begin
    if(only_mode>=0) begin
      begin_run(only_mode); await_done();
      $display("SINGLE_MODE_RESULT mode%0d error%0d raw%0d recovered%0d terminal%0d/%0d earlyfalse%0d original%02x restored%02x timeouts%0d readchanges%0d records%0d",
        mode,any_error,p(19),p(20),p(22),p(23),p(6)+p(10)+p(14)+p(18),original_ff,restored_ff,p(28),read_changes_high,record_count);
      $finish;
    end
    trace_fd=$fopen(REF_MODE ? "r1h_reference_allack.trace":"r1i_candidate_allack.trace","w");
    if(trace_fd==0) $fatal(1,"trace open failed");
    begin_run(0); await_done(); allack_cycles=cycle;
    if(any_error || first_valid || nack_count || timeout_count || original_ff!=7 || restored_ff!=7)
      $fatal(1,"allACK functional behavior failed");
    if(REF_MODE==0 && (p(4)+p(8)+p(12)+p(16)!=0 || p(6)+p(10)+p(14)+p(18)!=0))
      $fatal(1,"normal ACK stimulus falsely counted legacy-early NACK");
    $fdisplay(trace_fd,"FINAL %032x %016x %032x %04x %04x %04x %02x %02x %02x %02x %01x",
      values,output_values,afe_values,read_errors,aux_errors,afe_errors,write_errors,
      original_ff,restored_ff,phys_bank,phys_bank_valid);
    $fclose(trace_fd); trace_fd=0;
    $display("PASS ALL_ACK_WIRE_SEQUENCE_AND_OUTPUT_CAPTURE REF=%0d cycles=%0d tx=%0d bytes=%0d",
      REF_MODE,allack_cycles,starts,byte_count);
    if(REF_MODE==1) $finish;
    $display("PASS CASE1_C1_FIRST_FILTERED_HIGH_STIMULUS_ADAPTER");
    begin_run(1); await_done();
    for(integer ph=0;ph<4;ph=ph+1)
      if(p(3+4*ph)!=p(4+4*ph) || p(4+4*ph)!=p(6+4*ph) || p(5+4*ph)!=0)
        $fatal(1,"late ACK causal per-phase counter mismatch phase%0d",ph);
    if(any_error || p(19)!=0 || p(20)!=0 || p(6)+p(10)+p(14)+p(18)==0 ||
       read_changes_high==0 || original_ff!=7 || restored_ff!=7)
      $fatal(1,"late ACK/read data qualification failed err%0d raw%0d recovered%0d false%0d reads%0d original%02x restored%02x",
        any_error,p(19),p(20),p(6)+p(10)+p(14)+p(18),read_changes_high,original_ff,restored_ff);
    $display("PASS CASE1_LATE_ACK_QUALIFIED_NO_RETRY false=%0d",p(6)+p(10)+p(14)+p(18));
    begin_run(2); await_done(); expect_recovery(1,24);
    $display("PASS CASE2_WADDR_FIRST_ABORT_CASE6_RETRY1_RECOVERY");
    begin_run(3); await_done(); expect_recovery(1,24);
    $display("PASS CASE3_REGADDR_FIRST_ABORT");
    begin_run(4); await_done(); expect_recovery(1,24);
    $display("PASS CASE4_DATA_FIRST_ABORT");
    begin_run(5); await_done(); expect_recovery(1,24);
    $display("PASS CASE5_RADDR_FIRST_ABORT_NO_READ_DATA");
    begin_run(7); await_done(); expect_recovery(3,26);
    $display("PASS CASE7_RETRY3_FINAL_ALLOWED_ATTEMPT_RECOVERY");
    begin_run(8); await_done();
    if(!any_error || !first_valid || p(22)!=1 || p(23)!=1 || p(19)!=4 ||
       p(20)!=0 || record_count!=4 || first_error_edges!=1 || target_attempt!=4)
      $fatal(1,"four-attempt exhaustion/terminal-error behavior failed");
    $display("PASS CASE8_EXACT_FOUR_ATTEMPTS_ONE_TERMINAL_ERROR");
    begin_run(9); await_done();
    if(!timeout_injected || timeout_hold_cycles<20 || p(28)!=1 || p(20)!=1 ||
       p(22)!=0 || p(23)!=0 || any_error || record_count!=1)
      $fatal(1,"bounded physical SCL timeout recovery failed timeout=%0d recovered=%0d records=%0d",
        p(28),p(20),record_count);
    $display("PASS CASE9_PHYSICAL_SCL_LOW_BOUNDED_TIMEOUT_STOP_RETRY");
    begin_run(10); await_done();
    if(any_error || original_ff!=7 || restored_ff!=7 ||
       values!=={16{8'ha6}} || output_values!=={8{8'ha6}} || read_changes_high<8)
      $fatal(1,"qualified-high read byte reconstruction failed");
    $display("PASS CASE10_READ_DATA_CHANGES_ONLY_PHYSICAL_SCL_HIGH");
    begin_run(12); await_done(); expect_recovery(1,24);
    $display("PASS CASE12_BANK_SELECTOR_FAILURE_RECOVERY_NO_UNVERIFIED_TARGET");
    begin_run(13); await_done(); expect_recovery(1,24);
    $display("PASS CASE12_BANK_VERIFY_NACK_RECOVERY_NO_UNVERIFIED_TARGET");
    begin_run(14); await_done();
    if(target_records<1 || bank_errors!=0)
      $fatal(1,"bank-verify mismatch not visible or cache unsafe");
    $display("PASS CASE12_BANK_VERIFY_MISMATCH_CACHE_INVALIDATION");
    begin_run(15); await_done();
    if(!any_error || p(22)!=1 || p(23)!=1 || p(19)!=4 || target_attempt!=4)
      $fatal(1,"selector exhaustion not bounded");
    $display("PASS CASE12_BANK_SELECTOR_EXHAUSTION_NO_UNVERIFIED_TARGET");
    begin_run(16); await_done();
    if(!any_error || p(22)!=1 || p(23)!=1 || p(19)!=4 || target_attempt!=4)
      $fatal(1,"verify exhaustion not bounded");
    $display("PASS CASE12_BANK_VERIFY_EXHAUSTION_NO_UNVERIFIED_TARGET");
    begin_run(17); await_done();
    if(!timeout_injected || !any_error || p(22)==0 || p(23)!=0 ||
       starts!=1 || stops!=0 || retry_timer_checks!=0 || scl_oen!==1'b1 || sda_oen!==1'b1)
      $fatal(1,"persistent SCL-low did not terminate safely without retry/newphysicalSTART");
    $display("PASS CASE9_PERSISTENT_SCL_LOW_BOUNDED_SAFE_TERMINAL_NO_RETRY");
    $display("PASS R1I_FOCUSED_WIRE_SEMANTIC_SUITE");
    $finish;
  end
endmodule

module tb_r1i_qualified_ack_readiness;
  r1i_wire_test #(.REF_MODE(0)) testbench();
endmodule
module tb_r1h_allack_reference;
  r1i_wire_test #(.REF_MODE(1)) testbench();
endmodule
module tb_r1i_timeout_recovery;
  r1i_wire_test #(.REF_MODE(0),.SELECT_MODE(9)) testbench();
endmodule
