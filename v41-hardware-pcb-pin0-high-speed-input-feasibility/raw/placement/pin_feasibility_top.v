module pin_feasibility_top (
    input  wire       vclk1,
    input  wire [7:0] vdo1,
    input  wire       vclk2,
    input  wire [7:0] vdo2,
    input  wire       ref27,
    input  wire       nvp_irq,
    output wire       nvp_rst,
    inout  wire       nvp_sda,
    inout  wire       nvp_scl
);
  wire vclk1_ibuf, vclk1_io, vclk1_div;
  wire vclk2_ibuf, vclk2_io, vclk2_div;
  wire ref27_ibuf, ref27_global;
  wire [7:0] vdo1_ibuf, vdo2_ibuf;
  wire [7:0] vdo1_rise, vdo1_fall, vdo2_rise, vdo2_fall;
  wire sda_in, scl_in;
  reg div1_q = 1'b0;
  reg div2_q = 1'b0;
  reg ref_q  = 1'b0;

  (* DONT_TOUCH = "TRUE" *) IBUF u_vclk1_ibuf (.I(vclk1), .O(vclk1_ibuf));
  (* DONT_TOUCH = "TRUE" *) BUFIO u_vclk1_bufio (.I(vclk1_ibuf), .O(vclk1_io));
  (* DONT_TOUCH = "TRUE" *) BUFR #(.BUFR_DIVIDE("BYPASS"), .SIM_DEVICE("7SERIES"))
    u_vclk1_bufr (.I(vclk1_ibuf), .CE(1'b1), .CLR(1'b0), .O(vclk1_div));

  (* DONT_TOUCH = "TRUE" *) IBUF u_vclk2_ibuf (.I(vclk2), .O(vclk2_ibuf));
  (* DONT_TOUCH = "TRUE" *) BUFIO u_vclk2_bufio (.I(vclk2_ibuf), .O(vclk2_io));
  (* DONT_TOUCH = "TRUE" *) BUFR #(.BUFR_DIVIDE("BYPASS"), .SIM_DEVICE("7SERIES"))
    u_vclk2_bufr (.I(vclk2_ibuf), .CE(1'b1), .CLR(1'b0), .O(vclk2_div));

  (* DONT_TOUCH = "TRUE" *) IBUF u_ref27_ibuf (.I(ref27), .O(ref27_ibuf));
  (* DONT_TOUCH = "TRUE" *) BUFG u_ref27_bufg (.I(ref27_ibuf), .O(ref27_global));

  genvar bit_index;
  generate
    for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin : g_input_bits
      (* DONT_TOUCH = "TRUE" *) IBUF u_vdo1_ibuf (.I(vdo1[bit_index]), .O(vdo1_ibuf[bit_index]));
      (* DONT_TOUCH = "TRUE" *) IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b0), .INIT_Q2(1'b0),
        .SRTYPE("SYNC")
      ) u_vdo1_iddr (
        .D(vdo1_ibuf[bit_index]), .C(vclk1_io),
        .CE(1'b1), .R(1'b0), .S(1'b0),
        .Q1(vdo1_rise[bit_index]), .Q2(vdo1_fall[bit_index])
      );

      (* DONT_TOUCH = "TRUE" *) IBUF u_vdo2_ibuf (.I(vdo2[bit_index]), .O(vdo2_ibuf[bit_index]));
      (* DONT_TOUCH = "TRUE" *) IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b0), .INIT_Q2(1'b0),
        .SRTYPE("SYNC")
      ) u_vdo2_iddr (
        .D(vdo2_ibuf[bit_index]), .C(vclk2_io),
        .CE(1'b1), .R(1'b0), .S(1'b0),
        .Q1(vdo2_rise[bit_index]), .Q2(vdo2_fall[bit_index])
      );
    end
  endgenerate

  always @(posedge vclk1_div) div1_q <= ~div1_q;
  always @(posedge vclk2_div) div2_q <= ~div2_q;
  always @(posedge ref27_global) ref_q <= ~ref_q;

  (* DONT_TOUCH = "TRUE" *) IOBUF u_sda_iobuf
    (.I(1'b0), .T(~nvp_irq), .O(sda_in), .IO(nvp_sda));
  (* DONT_TOUCH = "TRUE" *) IOBUF u_scl_iobuf
    (.I(1'b0), .T(~nvp_irq), .O(scl_in), .IO(nvp_scl));

  assign nvp_rst = ^{vdo1_rise, vdo1_fall, vdo2_rise, vdo2_fall,
                     div1_q, div2_q, ref_q, sda_in, scl_in};
endmodule
