module decoder_riscv(
    input logic [31:0] fetched_instr_i,
    output logic [1:0] a_sel_o,
    output logic [2:0] b_sel_o,
    output logic [4:0] alu_op_o,
    output logic [2:0] csr_op_o,
    output logic csr_we_o,
    output logic mem_req_o,
    output logic mem_we_o,
    output logic [2:0] mem_size_o,
    output logic gpr_we_o,
    output logic [1:0] wb_sel_o,
    output logic illegal_instr_o,
    output logic branch_o,
    output logic jal_o,
    output logic jalr_o,
    output logic mret_o
);

import riscv_pkg::*;

logic [4:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = fetched_instr_i[6:2];
assign funct3 = fetched_instr_i[14:12];
assign funct7 = fetched_instr_i[31:25];

always_comb begin
    jal_o <= 1'b0;
    jalr_o <= 1'b0;
    mret_o <= 1'b0;
    branch_o <= 1'b0;
    csr_op_o <= CSR_RW;
    mem_size_o <= LDST_B;
    a_sel_o <= OP_A_RS1; b_sel_o <= OP_B_RS2; wb_sel_o <= WB_EX_RESULT; alu_op_o <= ALU_ADD;
    illegal_instr_o = 1'b0;
    mem_we_o <= 1'b0; gpr_we_o = 1'b0; csr_we_o <= 1'b0; mem_req_o <= 1'b0;

    if(fetched_instr_i[1:0] != 2'b11 || (opcode == SYSTEM_OPCODE && funct3 == 3'h0 && (funct7 == 7'h0 || funct7 == 7'h1))) begin
        illegal_instr_o = 1'b1;
    end
    else begin
        //TODO add default output values, do not touch values dependant on illegal state
        case(opcode)
            OP_OPCODE: begin
                a_sel_o <= OP_A_RS1; b_sel_o <= OP_B_RS2; gpr_we_o = 1'b1; wb_sel_o <= WB_EX_RESULT;
                case(funct7)
                    7'h00: case(funct3)
                        3'h0: alu_op_o <= ALU_ADD;
                        3'h4: alu_op_o <= ALU_XOR;
                        3'h6: alu_op_o <= ALU_OR;
                        3'h7: alu_op_o <= ALU_AND;
                        3'h1: alu_op_o <= ALU_SLL;
                        3'h5: alu_op_o <= ALU_SRL;
                        3'h2: alu_op_o <= ALU_SLTS;
                        3'h3: alu_op_o <= ALU_SLTU;
                        default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                    endcase
                    7'h20: case(funct3)
                        3'h0: alu_op_o <= ALU_SUB;
                        3'h5: alu_op_o <= ALU_SRA;
                        default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                    endcase
                    default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                endcase
            end //OP_OPCODE
            OP_IMM_OPCODE: begin
                gpr_we_o = 1'b1;
                a_sel_o <= OP_A_RS1; b_sel_o <= OP_B_IMM_I; wb_sel_o <= WB_EX_RESULT;
                case(funct3)
                    3'h0: alu_op_o <= ALU_ADD;
                    3'h4: alu_op_o <= ALU_XOR;
                    3'h6: alu_op_o <= ALU_OR;
                    3'h7: alu_op_o <= ALU_AND;
                    3'h2: alu_op_o <= ALU_SLTS;
                    3'h3: alu_op_o <= ALU_SLTU;
                    3'h5: case(funct7)
                            'h0: alu_op_o <= ALU_SRL;
                            'h20: alu_op_o <= ALU_SRA;
                            default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                          endcase
                    3'h1: case(funct7)
                            'h0: alu_op_o <= ALU_SLL;
                            default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                          endcase
                    default: begin illegal_instr_o <= 1'b1; gpr_we_o = 1'b0; end
                endcase
            end
            LOAD_OPCODE: begin
                mem_req_o <= 1'b1; gpr_we_o = 1'b1; wb_sel_o <= WB_LSU_DATA;
                b_sel_o <= OP_B_IMM_I; alu_op_o <= ALU_ADD;
                case(funct3)
                    3'h0: mem_size_o <= LDST_B;
                    3'h1: mem_size_o <= LDST_H;
                    3'h2: mem_size_o <= LDST_W;
                    3'h4: mem_size_o <= LDST_BU;
                    3'h5: mem_size_o <= LDST_HU;
                    default: begin illegal_instr_o <= 1'b1; mem_req_o <= 1'b0; gpr_we_o = 1'b0; end
                endcase
            end
            STORE_OPCODE: begin
                mem_req_o <= 1'b1; mem_we_o <= 1'b1; wb_sel_o <= WB_EX_RESULT; b_sel_o <= OP_B_IMM_S;
                case(funct3)
                    3'h0: mem_size_o <= LDST_B;
                    3'h1: mem_size_o <= LDST_H;
                    3'h2: mem_size_o <= LDST_W;
                    default: begin illegal_instr_o <= 1'b1; mem_req_o <= 1'b0; mem_we_o <= 1'b0; end
                endcase
            end
            BRANCH_OPCODE: begin
                branch_o <= 1'b1; a_sel_o <= OP_A_RS1; b_sel_o <= OP_B_RS2;
                case(funct3)
                    3'h0: alu_op_o <= ALU_EQ;//beq
                    3'h1: alu_op_o <= ALU_NE;//bne
                    3'h4: alu_op_o <= ALU_LTS;//blt
                    3'h5: alu_op_o <= ALU_GES;//bge
                    3'h6: alu_op_o <= ALU_LTU;//bltu
                    3'h7: alu_op_o <= ALU_GEU;//bgeu
                    default: begin illegal_instr_o <= 1'b1; branch_o <= 1'b0; end
                endcase
            end
            JAL_OPCODE: begin
                jal_o <= 1'b1; a_sel_o <= OP_A_CURR_PC; b_sel_o <= OP_B_INCR; gpr_we_o = 1'b1; wb_sel_o <= WB_EX_RESULT; alu_op_o <= ALU_ADD;
            end
            JALR_OPCODE: begin
                jalr_o <= 1'b1; a_sel_o <= OP_A_CURR_PC; b_sel_o <= OP_B_INCR; gpr_we_o = 1'b1; wb_sel_o <= WB_EX_RESULT; alu_op_o <= ALU_ADD;
                if(funct3 != 3'b000) begin
                    begin illegal_instr_o <= 1'b1; gpr_we_o <= 1'b0; jalr_o <= 1'b0; end
                end
            end
            LUI_OPCODE: begin
                a_sel_o <= OP_A_ZERO; b_sel_o <= OP_B_IMM_U; gpr_we_o = 1'b1; wb_sel_o <= WB_EX_RESULT; alu_op_o <= ALU_ADD;
            end
            AUIPC_OPCODE: begin
                a_sel_o <= OP_A_CURR_PC; b_sel_o <= OP_B_IMM_U; gpr_we_o = 1'b1; wb_sel_o <= WB_EX_RESULT; alu_op_o <= ALU_ADD;
            end
            MISC_MEM_OPCODE: begin
                if(funct3 == 3'h0) begin
                //NOP (do nothing)
                end else illegal_instr_o = 1'b1;
            end
            SYSTEM_OPCODE: begin
                csr_we_o <= 1'b1; gpr_we_o <= 1'b1; wb_sel_o <= WB_CSR_DATA;
                case(funct3)
                    'h0: case(funct7)
                            'h0: begin illegal_instr_o <= 1'b1; csr_we_o <= 1'b0; gpr_we_o <= 1'b0; end
                            'h1: begin illegal_instr_o <= 1'b1; csr_we_o <= 1'b0; gpr_we_o <= 1'b0; end
                            'h18: begin mret_o <= 1'b1; csr_we_o <= 1'b0; gpr_we_o <= 1'b0; end
                            default: begin illegal_instr_o <= 1'b1; csr_we_o <= 1'b0; gpr_we_o <= 1'b0; mret_o <= 1'b0; end
                        endcase
                    CSR_RW: csr_op_o <= CSR_RW;
                    CSR_RS: csr_op_o <= CSR_RS;
                    CSR_RC: csr_op_o <= CSR_RC;
                    CSR_RWI: csr_op_o <= CSR_RWI;
                    CSR_RSI: csr_op_o <= CSR_RSI;
                    CSR_RCI: csr_op_o <= CSR_RCI;
                    default: begin illegal_instr_o <= 1'b1; csr_we_o <= 1'b0; gpr_we_o <= 1'b0; end
                endcase
            end
            default: begin illegal_instr_o <= 1'b1; mem_we_o <= 1'b0; gpr_we_o <= 1'b0; csr_we_o <= 1'b0; mem_req_o <= 1'b0;
                           branch_o <= 1'b0; end //unknown code
        endcase
    end
end

endmodule
