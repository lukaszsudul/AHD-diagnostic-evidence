`timescale 1ns/1ps

// Observer only. All state is configuration-initialized and intentionally has
// no reset or enable input. Sampled transition counts cannot see transitions
// occurring while axi_aclk itself is absent.
module v41_axi_clock_lifecycle_monitor (
  input logic axi_aclk,
  input logic nvp_init_done,
  input logic user_lnk_up,
  input logic axi_aresetn,
  output logic [47:0] freerun_count,
  output logic [47:0] cnt_at_init_done,
  output logic [47:0] cnt_at_first_user_lnk_up,
  output logic [47:0] cnt_at_first_axi_aresetn_high,
  output logic [47:0] cnt_at_first_axi_aresetn_low_after_high,
  output logic [31:0] user_lnk_up_transition_count,
  output logic [31:0] axi_aresetn_transition_count,
  output logic [4:0] event_flags
);
  (* DONT_TOUCH = "TRUE", KEEP = "TRUE" *) logic [47:0] counter = 48'b0;
  logic init_done_seen = 1'b0, link_seen = 1'b0, reset_high_seen = 1'b0;
  logic reset_low_after_high_seen = 1'b0, init_before_link = 1'b0;
  logic link_previous = 1'b0, reset_previous = 1'b0;
  logic [47:0] init_count = 48'b0, link_count = 48'b0;
  logic [47:0] reset_high_count = 48'b0, reset_low_count = 48'b0;
  logic [31:0] link_transitions = 32'b0, reset_transitions = 32'b0;

  always_ff @(posedge axi_aclk) begin
    counter <= counter + 48'd1;
    if (!init_done_seen && nvp_init_done) begin
      init_count <= counter;
      init_done_seen <= 1'b1;
      if (!link_seen) init_before_link <= 1'b1;
    end
    if (!link_seen && user_lnk_up) begin link_count <= counter; link_seen <= 1'b1; end
    if (!reset_high_seen && axi_aresetn) begin reset_high_count <= counter; reset_high_seen <= 1'b1; end
    if (reset_high_seen && !reset_low_after_high_seen && !axi_aresetn) begin
      reset_low_count <= counter; reset_low_after_high_seen <= 1'b1;
    end
    if (user_lnk_up != link_previous && link_transitions != 32'hffffffff)
      link_transitions <= link_transitions + 1'b1;
    if (axi_aresetn != reset_previous && reset_transitions != 32'hffffffff)
      reset_transitions <= reset_transitions + 1'b1;
    link_previous <= user_lnk_up;
    reset_previous <= axi_aresetn;
  end

  assign freerun_count = counter;
  assign cnt_at_init_done = init_count;
  assign cnt_at_first_user_lnk_up = link_count;
  assign cnt_at_first_axi_aresetn_high = reset_high_count;
  assign cnt_at_first_axi_aresetn_low_after_high = reset_low_count;
  assign user_lnk_up_transition_count = link_transitions;
  assign axi_aresetn_transition_count = reset_transitions;
  assign event_flags = {init_before_link, reset_low_after_high_seen,
                        reset_high_seen, link_seen, init_done_seen};
endmodule

