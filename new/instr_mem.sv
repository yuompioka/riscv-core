
module instr_mem(
    input  logic [31:0] addr_i,
    output logic [31:0] read_data_o
);

logic [31:0] MEM [0:1023];

initial $readmemh("irq_program.txt", MEM);

assign read_data_o = (addr_i > 4095) ? 32'b0 : MEM[addr_i >> 2];

endmodule
