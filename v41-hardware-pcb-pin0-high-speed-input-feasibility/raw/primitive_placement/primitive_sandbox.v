module primitive_sandbox (
    input  wire       ch1_vclk,
    input  wire [7:0] ch1_vdo,
    input  wire       ch2_vclk,
    input  wire [7:0] ch2_vdo,
    input  wire       idelay_refclk_200,
    output wire [3:0] capture_summary
);
    wire ch1_clk_ibuf;
    wire ch2_clk_ibuf;
    wire ch1_clk_io;
    wire ch2_clk_io;
    wire ch1_clk_div;
    wire ch2_clk_div;
    wire refclk_ibuf;
    wire refclk_g;

    wire [7:0] ch1_data_ibuf;
    wire [7:0] ch2_data_ibuf;
    wire [7:0] ch1_data_delayed;
    wire [7:0] ch2_data_delayed;
    wire [7:0] ch1_q1;
    wire [7:0] ch1_q2;
    wire [7:0] ch2_q1;
    wire [7:0] ch2_q2;
    wire       ch1_div_sample;
    wire       ch2_div_sample;

    IBUF u_ch1_clk_ibuf (.I(ch1_vclk), .O(ch1_clk_ibuf));
    IBUF u_ch2_clk_ibuf (.I(ch2_vclk), .O(ch2_clk_ibuf));
    BUFIO u_ch1_bufio (.I(ch1_clk_ibuf), .O(ch1_clk_io));
    BUFIO u_ch2_bufio (.I(ch2_clk_ibuf), .O(ch2_clk_io));
    BUFR #(.BUFR_DIVIDE("2"), .SIM_DEVICE("7SERIES"))
        u_ch1_bufr (.I(ch1_clk_ibuf), .CE(1'b1), .CLR(1'b0), .O(ch1_clk_div));
    BUFR #(.BUFR_DIVIDE("2"), .SIM_DEVICE("7SERIES"))
        u_ch2_bufr (.I(ch2_clk_ibuf), .CE(1'b1), .CLR(1'b0), .O(ch2_clk_div));

    IBUF u_refclk_ibuf (.I(idelay_refclk_200), .O(refclk_ibuf));
    BUFG u_refclk_bufg (.I(refclk_ibuf), .O(refclk_g));

    (* IODELAY_GROUP = "CH1_IODELAY_GRP" *)
    IDELAYCTRL u_ch1_idelayctrl (.REFCLK(refclk_g), .RST(1'b0), .RDY());
    (* IODELAY_GROUP = "CH2_IODELAY_GRP" *)
    IDELAYCTRL u_ch2_idelayctrl (.REFCLK(refclk_g), .RST(1'b0), .RDY());

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : g_ch1
            IBUF u_data_ibuf (.I(ch1_vdo[i]), .O(ch1_data_ibuf[i]));
            (* IODELAY_GROUP = "CH1_IODELAY_GRP" *)
            IDELAYE2 #(
                .CINVCTRL_SEL("FALSE"),
                .DELAY_SRC("IDATAIN"),
                .HIGH_PERFORMANCE_MODE("FALSE"),
                .IDELAY_TYPE("FIXED"),
                .IDELAY_VALUE(0),
                .PIPE_SEL("FALSE"),
                .REFCLK_FREQUENCY(200.0),
                .SIGNAL_PATTERN("DATA")
            ) u_idelay (
                .DATAOUT(ch1_data_delayed[i]), .CNTVALUEOUT(),
                .C(refclk_g), .CE(1'b0), .CINVCTRL(1'b0),
                .CNTVALUEIN(5'b00000), .DATAIN(1'b0),
                .IDATAIN(ch1_data_ibuf[i]), .INC(1'b0), .LD(1'b0),
                .LDPIPEEN(1'b0), .REGRST(1'b0)
            );
            IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b0),
                   .INIT_Q2(1'b0), .SRTYPE("SYNC"))
            u_iddr (
                .Q1(ch1_q1[i]), .Q2(ch1_q2[i]), .C(ch1_clk_io),
                .CE(1'b1), .D(ch1_data_delayed[i]),
                .R(1'b0), .S(1'b0)
            );
        end
        for (i = 0; i < 8; i = i + 1) begin : g_ch2
            IBUF u_data_ibuf (.I(ch2_vdo[i]), .O(ch2_data_ibuf[i]));
            (* IODELAY_GROUP = "CH2_IODELAY_GRP" *)
            IDELAYE2 #(
                .CINVCTRL_SEL("FALSE"),
                .DELAY_SRC("IDATAIN"),
                .HIGH_PERFORMANCE_MODE("FALSE"),
                .IDELAY_TYPE("FIXED"),
                .IDELAY_VALUE(0),
                .PIPE_SEL("FALSE"),
                .REFCLK_FREQUENCY(200.0),
                .SIGNAL_PATTERN("DATA")
            ) u_idelay (
                .DATAOUT(ch2_data_delayed[i]), .CNTVALUEOUT(),
                .C(refclk_g), .CE(1'b0), .CINVCTRL(1'b0),
                .CNTVALUEIN(5'b00000), .DATAIN(1'b0),
                .IDATAIN(ch2_data_ibuf[i]), .INC(1'b0), .LD(1'b0),
                .LDPIPEEN(1'b0), .REGRST(1'b0)
            );
            IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b0),
                   .INIT_Q2(1'b0), .SRTYPE("SYNC"))
            u_iddr (
                .Q1(ch2_q1[i]), .Q2(ch2_q2[i]), .C(ch2_clk_io),
                .CE(1'b1), .D(ch2_data_delayed[i]),
                .R(1'b0), .S(1'b0)
            );
        end
    endgenerate

    FDRE u_ch1_div_ff (.C(ch1_clk_div), .CE(1'b1), .D(^ch1_q1), .R(1'b0), .Q(ch1_div_sample));
    FDRE u_ch2_div_ff (.C(ch2_clk_div), .CE(1'b1), .D(^ch2_q1), .R(1'b0), .Q(ch2_div_sample));
    assign capture_summary[0] = ^ch1_q1 ^ ^ch1_q2;
    assign capture_summary[1] = ^ch2_q1 ^ ^ch2_q2;
    assign capture_summary[2] = ch1_div_sample;
    assign capture_summary[3] = ch2_div_sample;
endmodule
