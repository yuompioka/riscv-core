
module adder_32(
    input logic carry_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    output logic [31:0] res_o,
    output logic carry_o
);

wire addo_0, addo_1, addo_2, addo_3, addo_4, addo_5, addo_6, addo_7;

adder_4 adder0 (carry_i, a_i[3:0], b_i[3:0], res_o[3:0], addo_0);
adder_4 adder1 (addo_0, a_i[7:4], b_i[7:4], res_o[7:4], addo_1);
adder_4 adder2 (addo_1, a_i[11:8], b_i[11:8], res_o[11:8], addo_2);
adder_4 adder3 (addo_2, a_i[15:12], b_i[15:12], res_o[15:12], addo_3);

adder_4 adder4 (addo_3, a_i[19:16], b_i[19:16], res_o[19:16], addo_4);
adder_4 adder5 (addo_4, a_i[23:20], b_i[23:20], res_o[23:20], addo_5);
adder_4 adder6 (addo_5, a_i[27:24], b_i[27:24], res_o[27:24], addo_6);
adder_4 adder7 (addo_6, a_i[31:28], b_i[31:28], res_o[31:28], addo_7);

assign carry_o = addo_7;

endmodule
