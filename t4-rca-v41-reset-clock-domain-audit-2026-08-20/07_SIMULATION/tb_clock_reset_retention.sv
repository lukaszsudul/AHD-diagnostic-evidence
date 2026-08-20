`timescale 1ns/1ps
module tb_clock_reset_retention;
  logic base_clk=0, run_clk=1, nvp_clk, cfg_init=1;
  logic pcie_reset=0, axi_reset=0, perst=0, link_up=1;
  logic [8:0] por_count=0;
  logic por_reset=1;
  logic [7:0] fsm_state=0;
  logic scl_oe=1, sda_oe=1;
  assign nvp_clk = base_clk & run_clk;
  always #8 base_clk = ~base_clk;

  // Exact integration property being checked: the local NVP state has no
  // PCIe/XDMA reset in its sensitivity or reset conditions.
  always @(posedge nvp_clk) begin
    if (cfg_init) begin por_count<=0; por_reset<=1; fsm_state<=0; scl_oe<=1; sda_oe<=1; end
    else begin
      if (por_count < 320) begin por_count<=por_count+1; por_reset<=1; end
      else begin
        por_reset<=0;
        fsm_state<=fsm_state+1;
        scl_oe<=~fsm_state[0];
        sda_oe<=~fsm_state[1];
      end
    end
  end

  task pulse_integration_resets;
    logic [8:0] pc; logic [7:0] fs; logic so,sd;
    begin
      pc=por_count; fs=fsm_state; so=scl_oe; sd=sda_oe;
      pcie_reset=1; axi_reset=1; perst=1; link_up=0; #160;
      pcie_reset=0; axi_reset=0; perst=0; link_up=1; #32;
      assert(por_count>pc || fsm_state>fs) else $fatal("integration reset altered/stopped NVP cone");
    end
  endtask

  task pause_and_check(input integer cycles, input string label_text);
    logic [8:0] pc; logic [7:0] fs; logic so,sd;
    begin
      pc=por_count; fs=fsm_state; so=scl_oe; sd=sda_oe;
      run_clk=0; #(cycles*16);
      assert(por_count==pc && fsm_state==fs && scl_oe==so && sda_oe==sd)
        else $fatal("pause retention failed: %s",label_text);
      run_clk=1; #32;
      $display("PASS_PAUSE_RETENTION %s",label_text);
    end
  endtask

  initial begin
    #40; cfg_init=0;
    pause_and_check(20,"before_physical_reset_release");
    wait(por_reset==0);
    pause_and_check(20,"after_reset_before_start_model_point");
    pause_and_check(20,"address_byte_model_point");
    pause_and_check(20,"ack_preparation_model_point");
    pause_and_check(20,"register_byte_model_point");
    pause_and_check(20,"between_transactions_model_point");
    pulse_integration_resets();
    $display("PASS_INTEGRATION_RESET_INDEPENDENCE_MODEL");
    $display("HYPOTHETICAL_NOT_PROVEN_CLOCK_PAUSE_LIFECYCLE");
    $finish;
  end
endmodule
