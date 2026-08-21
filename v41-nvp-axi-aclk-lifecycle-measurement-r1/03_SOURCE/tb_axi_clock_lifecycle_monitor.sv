`timescale 1ns/1ps
module tb_axi_clock_lifecycle_monitor;
  logic clk=0, done=0, link=0, arstn=0; always #8 clk=~clk;
  wire [47:0] count,done_count,link_count,hi_count,lo_count;
  wire [31:0] link_changes,reset_changes; wire [4:0] flags;
  v41_axi_clock_lifecycle_monitor dut(.axi_aclk(clk),.nvp_init_done(done),
    .user_lnk_up(link),.axi_aresetn(arstn),.freerun_count(count),
    .cnt_at_init_done(done_count),.cnt_at_first_user_lnk_up(link_count),
    .cnt_at_first_axi_aresetn_high(hi_count),
    .cnt_at_first_axi_aresetn_low_after_high(lo_count),
    .user_lnk_up_transition_count(link_changes),
    .axi_aresetn_transition_count(reset_changes),.event_flags(flags));
  initial begin
    repeat(4) @(posedge clk); done<=1; @(posedge clk); #1;
    if(!flags[0] || done_count!==48'd4) $fatal(1,"init snapshot");
    arstn<=1; repeat(2) @(posedge clk); link<=1; repeat(2) @(posedge clk); arstn<=0;
    repeat(3) @(posedge clk); #1;
    if(count!==48'd12 || hi_count!==48'd5 || link_count!==48'd7 || lo_count!==48'd9) $fatal(1,"event counts");
    if(flags!==5'b11111 || link_changes!==1 || reset_changes!==2) $fatal(1,"flags/transitions");
    $display("PASS lifecycle counter=%0d",count); $finish;
  end
endmodule
