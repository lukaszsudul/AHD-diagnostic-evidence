`timescale 1ns/1ps
module v41_axi_clock_measurement_regs (
  input logic [5:0] offset,
  input logic [47:0] freerun_count, cnt_at_init_done,
  input logic [47:0] cnt_at_first_user_lnk_up,
  input logic [47:0] cnt_at_first_axi_aresetn_high,
  input logic [47:0] cnt_at_first_axi_aresetn_low_after_high,
  input logic [31:0] user_lnk_up_transition_count,
  input logic [31:0] axi_aresetn_transition_count,
  input logic [4:0] event_flags,
  output logic [31:0] read_data
);
  always_comb case (offset)
    6'h00: read_data=32'h314B4C43; // "CLK1"
    6'h04: read_data=32'd1;
    6'h08: read_data={27'b0,event_flags};
    6'h0c: read_data=freerun_count[31:0]; 6'h10: read_data={16'b0,freerun_count[47:32]};
    6'h14: read_data=cnt_at_init_done[31:0]; 6'h18: read_data={16'b0,cnt_at_init_done[47:32]};
    6'h1c: read_data=cnt_at_first_user_lnk_up[31:0]; 6'h20: read_data={16'b0,cnt_at_first_user_lnk_up[47:32]};
    6'h24: read_data=cnt_at_first_axi_aresetn_high[31:0]; 6'h28: read_data={16'b0,cnt_at_first_axi_aresetn_high[47:32]};
    6'h2c: read_data=cnt_at_first_axi_aresetn_low_after_high[31:0]; 6'h30: read_data={16'b0,cnt_at_first_axi_aresetn_low_after_high[47:32]};
    6'h34: read_data=user_lnk_up_transition_count;
    6'h38: read_data=axi_aresetn_transition_count;
    6'h3c: read_data={27'b0,event_flags};
    default: read_data=32'b0;
  endcase
endmodule
