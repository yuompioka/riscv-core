
module CYBERcobra(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] sw_i,
    output logic [31:0] out_o
);

logic [31:0] program_counter;

// ALU WIRES
logic alu_flag;
logic [31:0] alu_result;
logic [31:0] alu_op1;
logic [31:0] alu_op2;
// ALU WIRES END

// Register file WIRES
logic [31:0] WD;
// Register file WIRES END

logic [31:0] instr_mem_out;
logic [31:0] to_pg_adder;
logic [31:0] to_pg_ff;

assign to_pg_adder = ((instr_mem_out[30] & alu_flag) | instr_mem_out[31]) ? {{22{instr_mem_out[12]}}, {instr_mem_out[12:5], 2'b00}} : 32'd4;

adder_32 ADDER(
    .carry_i(1'b0),
    .a_i(program_counter),
    .b_i(to_pg_adder),
    .res_o(to_pg_ff),
    .carry_o()
);

always_ff @(posedge clk_i) begin
    if(rst_i) program_counter = 32'b0;
    else program_counter = to_pg_ff;
end

always_comb begin
    case(instr_mem_out[29:28])
        2'b00: WD = {{9{instr_mem_out[27]}}, instr_mem_out[27:5]};
        2'b01: WD = alu_result;
        2'b10: WD = {{16{sw_i[15]}}, sw_i};
        2'b11: WD = 32'b0;
    endcase
end

instr_mem INSTRUCT_MEM(
    .addr_i(program_counter),
    .read_data_o(instr_mem_out)
);

rf_riscv REGISTER_FILE(
    .clk_i(clk_i),
    .write_enable_i(~(instr_mem_out[30] | instr_mem_out[31])),
    
    .write_addr_i(instr_mem_out[4:0]),
    .read_addr1_i(instr_mem_out[22:18]),
    .read_addr2_i(instr_mem_out[17:13]),
    
    .write_data_i(WD),
    .read_data1_o(alu_op1),
    .read_data2_o(alu_op2)
);

alu_riscv ALU(
    .a_i(alu_op1),
    .b_i(alu_op2),
    .alu_op_i(instr_mem_out[27:23]),
    .flag_o(alu_flag),
    .result_o(alu_result)
);

assign out_o = alu_op1;

endmodule
