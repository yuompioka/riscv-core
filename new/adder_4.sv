
module adder_4(
    input logic carry_i,
    input logic [3:0] a_i,
    input logic [3:0] b_i,
    output logic [3:0] res_o,
    output logic carry_o
);

wire addo_0, addo_1, addo_2, addo_3;

one_bit_adder adder0 (carry_i, a_i[0], b_i[0], res_o[0], addo_0);
one_bit_adder adder1 (addo_0, a_i[1], b_i[1], res_o[1], addo_1);
one_bit_adder adder2 (addo_1, a_i[2], b_i[2], res_o[2], addo_2);
one_bit_adder adder3 (addo_2, a_i[3], b_i[3], res_o[3], addo_3);

assign carry_o = addo_3;

endmodule
