`timescale 1ns/1ps
module tb_axi_clock_measurement_regs;
 logic [5:0] off; wire [31:0] data;
 v41_axi_clock_measurement_regs dut(.offset(off),.freerun_count(48'h123456789abc),
  .cnt_at_init_done(48'h223456789abc),.cnt_at_first_user_lnk_up(48'h323456789abc),
  .cnt_at_first_axi_aresetn_high(48'h423456789abc),
  .cnt_at_first_axi_aresetn_low_after_high(48'h523456789abc),
  .user_lnk_up_transition_count(32'h11),.axi_aresetn_transition_count(32'h22),
  .event_flags(5'h1f),.read_data(data));
 task check(input[5:0] a,input[31:0] e); begin off=a;#1;if(data!==e)$fatal(1,"off %x got %x",a,data);end endtask
 initial begin check(0,32'h314b4c43);check(6'h0c,32'h56789abc);check(6'h10,32'h1234);
  check(6'h34,32'h11);check(6'h38,32'h22);check(6'h3c,32'h1f);$display("PASS regs");$finish;end
endmodule
