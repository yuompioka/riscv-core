module riscv_core(
    input logic clk_i,
    input logic rst_i,
    
    input logic stall_i,
    input logic [31:0] instr_i,
    input logic [31:0] mem_rd_i,
    input logic irq_req_i,
    
    output logic [31:0] instr_addr_o,
    output logic [31:0] mem_addr_o,
    output logic [2:0] mem_size_o,
    output logic mem_req_o,
    output logic mem_we_o,
    output logic [31:0] mem_wd_o,
    output logic irq_ret_o
);

logic [31:0] wb_data;

// ---- Decoder wires ----
logic [1:0] a_sel_dec_out;
logic [2:0] b_sel_dec_out;
logic [4:0] alu_op_dec_out;
logic gpr_we_dec_out;
logic [1:0] wb_sel_dec_out;
logic branch_dec_out;
logic jal_dec_out;
logic jalr_dec_out;
// ---- * ----

logic [31:0] mepc_o, mtvec_o;

// ---- Register File wires ----
logic [31:0] RD1_rf;
logic [31:0] RD2_rf;
logic to_rf_WE;
// ---- * ----
logic csr_we_dec_out, illegal_instr_dec_out, mret_dec_out, mem_we_dec_out, mem_req_dec_out;
logic [2:0] csr_op_dec_out;

decoder_riscv decoder_inst( //all pins OK
    .fetched_instr_i(instr_i),
    .a_sel_o(a_sel_dec_out),
    .b_sel_o(b_sel_dec_out),
    .alu_op_o(alu_op_dec_out),
    .csr_op_o(csr_op_dec_out),
    .csr_we_o(csr_we_dec_out),
    
    .mem_req_o(mem_req_dec_out),
    .mem_we_o(mem_we_dec_out),
    .mem_size_o(mem_size_o),
    
    .gpr_we_o(gpr_we_dec_out),
    .wb_sel_o(wb_sel_dec_out),
    .illegal_instr_o(illegal_instr_dec_out),
    .branch_o(branch_dec_out),
    .jal_o(jal_dec_out),
    .jalr_o(jalr_dec_out),
    .mret_o(mret_dec_out)
);

rf_riscv rf_inst( //all pins OK
    .clk_i(clk_i),
    .write_enable_i(to_rf_WE),
    
    .write_addr_i(instr_i[11:7]),
    .read_addr1_i(instr_i[19:15]),
    .read_addr2_i(instr_i[24:20]),
    .write_data_i(wb_data),
    
    .read_data1_o(RD1_rf),
    .read_data2_o(RD2_rf)
);

logic [31:0] imm_I;
assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
//assign imm_I = {20'b0, instr_i[31:20]};

logic [31:0] imm_U;
assign imm_U = {instr_i[31:12], 12'h0};

logic [31:0] imm_S;
assign imm_S = {{20{instr_i[31]}} ,instr_i[31:25], instr_i[11:7]};
//assign imm_S = {20'b0 ,instr_i[31:25], instr_i[11:7]};

logic [31:0] imm_B;
assign imm_B = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
//assign imm_B = {19'b0, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};

logic [31:0] imm_J;
assign imm_J = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
//assign imm_J = {11'b0, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

logic [31:0] imm_Z;
assign imm_Z = {27'b0, instr_i[19:15]};

// ---- ALU wires ----
logic [31:0] to_alu_a;
logic [31:0] to_alu_b;
logic flag_alu_out;
logic [31:0] result_alu_out;
// ---- * ----
assign mem_wd_o = RD2_rf;
assign mem_addr_o = result_alu_out;

logic [31:0] PC;
logic [31:0] to_PC0, to_PC1, to_PC2;

logic [31:0] csr_wd, irq_cause_ic_out;

logic [31:0] RD1_plus_imm_I;
assign RD1_plus_imm_I = RD1_rf+$signed(imm_I);

logic flag_AND_branch, to_mux_imm_left;
assign flag_AND_branch = flag_alu_out & branch_dec_out;
assign to_mux_imm_left = flag_AND_branch | jal_dec_out;

logic [31:0] instr_addr_plus;
logic [31:0] mux_imm_left, mux_imm_right, mux_mcause;

adder_32 adder_inst(
    .carry_i(1'b0),
    .a_i(mux_imm_left),
    .b_i(PC),
    .res_o(instr_addr_plus),
    .carry_o()
);

logic irq_from_ic;

logic trap;
assign trap = irq_from_ic | illegal_instr_dec_out;

always_comb begin
    case(a_sel_dec_out)
        'd0: to_alu_a <= RD1_rf;
        'd1: to_alu_a <= PC;
        'd2: to_alu_a <= 'b0;
        default: to_alu_a <= 'b0;
    endcase
    case(b_sel_dec_out)
        'd0: to_alu_b <= RD2_rf;
        'd1: to_alu_b <= imm_I;
        'd2: to_alu_b <= imm_U;
        'd3: to_alu_b <= imm_S;
        'd4: to_alu_b <= 'd4;
        default: to_alu_b <= 'b0;
    endcase
    case(wb_sel_dec_out)
        'h0: wb_data <= result_alu_out;
        'h1: wb_data <= mem_rd_i;
        'h2: wb_data <= csr_wd;
        default: wb_data <= 'b0;
    endcase
    case(jalr_dec_out)
        'b1: to_PC0 <= {RD1_plus_imm_I[31:1], 1'b0};
        'b0: to_PC0 <= instr_addr_plus;
        default: to_PC0 <= 'b0;
    endcase
    case(trap)
        'b1: to_PC1 <= mtvec_o;
        'b0: to_PC1 <= to_PC0;
        default: to_PC1 <= 'b0;
    endcase
    case(mret_dec_out)
        'b1: to_PC2 <= mepc_o;
        'b0: to_PC2 <= to_PC1;
        default: to_PC2 <= 'b0;
    endcase
    case(to_mux_imm_left)
        'b0: mux_imm_left <= 'd4;
        'b1: mux_imm_left <= mux_imm_right;
        default: mux_imm_left <= 'b0;
    endcase
    case(branch_dec_out)
        'b0: mux_imm_right <= imm_J;
        'b1: mux_imm_right <= imm_B;
        default: mux_imm_right <= 'b0;
    endcase
    case(illegal_instr_dec_out)
        1'b0: mux_mcause <= irq_cause_ic_out;
        1'b1: mux_mcause <= 32'h0000_0002;
    endcase
end

alu_riscv alu_inst( //all pins OK
    .a_i(to_alu_a),
    .b_i(to_alu_b),
    .alu_op_i(alu_op_dec_out),
    .flag_o(flag_alu_out),
    .result_o(result_alu_out)
);

logic [31:0] mie_csr_out;

csr_controller csr_controller_inst(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .trap_i(trap),
    
    .opcode_i(csr_op_dec_out),
    
    .addr_i(instr_i[31:20]),
    .pc_i(PC),
    .mcause_i(mux_mcause),
    .rs1_data_i(RD1_rf),
    .imm_data_i(imm_Z),
    .write_enable_i(csr_we_dec_out),
    
    .read_data_o(csr_wd),
    .mie_o(mie_csr_out),
    .mepc_o(mepc_o),
    .mtvec_o(mtvec_o)
);

always_ff @(posedge clk_i) begin
    if(rst_i) PC <= 32'b0;
    else begin
        if(~stall_i | trap) begin
            PC <= to_PC2;
        end
    end
end

interrupt_controller ic_instance(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .exception_i(illegal_instr_dec_out),
    .irq_req_i(irq_req_i),
    .mie_i(mie_csr_out[0]),
    .mret_i(mret_dec_out),
    
    .irq_ret_o(irq_ret_o),
    .irq_cause_o(irq_cause_ic_out),
    .irq_o(irq_from_ic)
);

assign instr_addr_o = PC;
assign mem_we_o = ~trap & mem_we_dec_out;
assign mem_req_o = ~trap & mem_req_dec_out;
assign to_rf_WE = gpr_we_dec_out & ~(stall_i | trap);


endmodule
