`timescale 1ns/1ps
module clock_forward (
    input  wire osc27_d13,
    input  wire gate_enable_t12,
    output wire nvp_clk_a14
);
    wire osc27_ibuf;
    wire osc27_gated;
    wire nvp_clk_oddr;

    IBUF #(.IOSTANDARD("LVCMOS33")) u_ibuf (
        .I(osc27_d13),
        .O(osc27_ibuf)
    );

    (* DONT_TOUCH = "TRUE" *)
    BUFGCE #(.CE_TYPE("SYNC")) u_bufgce (
        .I(osc27_ibuf),
        .CE(gate_enable_t12),
        .O(osc27_gated)
    );

    (* DONT_TOUCH = "TRUE" *)
    ODDR #(
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) u_oddr (
        .Q(nvp_clk_oddr),
        .C(osc27_gated),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    OBUF #(
        .IOSTANDARD("LVCMOS33"),
        .DRIVE(8),
        .SLEW("SLOW")
    ) u_obuf (
        .I(nvp_clk_oddr),
        .O(nvp_clk_a14)
    );
endmodule
