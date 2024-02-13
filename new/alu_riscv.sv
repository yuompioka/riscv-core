module alu_riscv(
    input  logic [31:0]  a_i,
    input  logic [31:0]  b_i,
    input  logic [4:0]   alu_op_i,
    output logic         flag_o,
    output logic [31:0]  result_o
);

import alu_opcodes_pkg::*; // import all operations codes

// assigns for flag
assign F_IS_EQ = a_i == b_i;
assign F_IS_LESS_SIGNED = $signed(a_i) < $signed(b_i);
assign F_IS_LESS = a_i < b_i;

logic [31:0] adder_res;
logic adder_out;

adder_32 ADDER (
    .carry_i(alu_op_i[3]),
    .a_i(a_i),
    .b_i(alu_op_i[3] ? ~b_i : b_i),
    .res_o(adder_res),
    .carry_o(adder_out)
);

always_comb begin
    case(alu_op_i)
        ALU_EQ: flag_o <= F_IS_EQ;
        ALU_NE: flag_o <= ~F_IS_EQ;
        ALU_LTS: flag_o <= F_IS_LESS_SIGNED;
        ALU_LTU: flag_o <= F_IS_LESS;
        ALU_GES: flag_o <= ~F_IS_LESS_SIGNED;
        ALU_GEU: flag_o <= ~F_IS_LESS;
        default: flag_o <= 1'b0;
    endcase
end

always @* begin
    case(alu_op_i)
        ALU_ADD: result_o = adder_res;
        ALU_SUB: result_o = adder_res;
        ALU_SLL: result_o <= a_i << b_i[4:0];
        ALU_SLTS: result_o <= $signed(a_i) < $signed(b_i);
        ALU_SLTU: result_o <= a_i < b_i;
        ALU_XOR: result_o <= a_i ^ b_i;
        ALU_SRL: result_o <= a_i >> b_i[4:0];
        ALU_SRA: result_o <= $signed(a_i) >>> b_i[4:0];
        ALU_OR: result_o <= a_i | b_i;
        ALU_AND: result_o <= a_i & b_i;
        default: result_o <= 32'b0;
    endcase
end

endmodule
