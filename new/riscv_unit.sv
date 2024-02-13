module riscv_unit(
    input logic clk_i,
    input logic rst_i
);

logic stall_i, irq_ret, irq_req;
logic [31:0] mem_rd_i;

logic [31:0] instr_addr_o;
logic [31:0] mem_addr_o;
logic mem_req_o;
logic mem_we_o;
logic [31:0] mem_wd_o;
logic [31:0] mem_size_o;
logic [31:0] read_data_o;

riscv_core core(
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .irq_req_i(irq_req),
    .irq_ret_o(irq_ret),
    
    .stall_i(stall_i),
    .instr_i(read_data_o),
    .mem_rd_i(mem_rd_i),
    
    .instr_addr_o(instr_addr_o),
    .mem_addr_o(mem_addr_o),
    .mem_size_o(mem_size_o), //NC
    .mem_req_o(mem_req_o),
    .mem_we_o(mem_we_o),
    .mem_wd_o(mem_wd_o)
);

logic lsu_req_o;
logic lsu_we_o;
logic [3:0] lsu_be_o;
logic [31:0] lsu_addr_o;
logic [31:0] lsu_wd_o;
logic [31:0] ext_mem_rd_o;
logic ext_mem_ready_o;

riscv_lsu riscv_lsu_inst(
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .core_req_i(mem_req_o),
    .core_we_i(mem_we_o),
    .core_size_i(mem_size_o),
    .core_addr_i(mem_addr_o),
    .core_wd_i(mem_wd_o),
    .core_rd_o(mem_rd_i),
    .core_stall_o(stall_i),
    
    .mem_req_o(lsu_req_o),
    .mem_we_o(lsu_we_o),
    .mem_be_o(lsu_be_o),
    .mem_addr_o(lsu_addr_o),
    .mem_wd_o(lsu_wd_o),
    .mem_rd_i(ext_mem_rd_o),
    .mem_ready_i(ext_mem_ready_o)
);

ext_mem ext_mem_inst(
    .clk_i(clk_i),
    .mem_req_i(lsu_req_o),
    .write_enable_i(lsu_we_o),
    .byte_enable_i(lsu_be_o),
    .addr_i(lsu_addr_o),
    .write_data_i(lsu_wd_o),
    .read_data_o(ext_mem_rd_o),
    .ready_o(ext_mem_ready_o)
);

instr_mem instr_mem_inst(
    .addr_i(instr_addr_o),
    .read_data_o(read_data_o)
);

/*
always_ff @(posedge clk_i) begin
    if(rst_i) stall_i <= 1'b0;
    else stall_i <= mem_req_o & ~stall_i;
end
*/

endmodule
