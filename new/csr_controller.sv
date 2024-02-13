module csr_controller(
    input logic clk_i,
    input logic rst_i,
    input logic trap_i,
    
    input logic [2:0] opcode_i,
    
    input logic [11:0] addr_i,
    input logic [31:0] pc_i,
    input logic [31:0] mcause_i,
    input logic [31:0] rs1_data_i,
    input logic [31:0] imm_data_i,
    input logic write_enable_i,
    
    output logic [31:0] read_data_o,
    output logic [31:0] mie_o,
    output logic [31:0] mepc_o,
    output logic [31:0] mtvec_o
);

import csr_pkg::*;

logic [31:0] mux0_out;
//logic MIE_ADDR_en, MTVEC_ADDR_en, MSCRATCH_ADDR_en, MEPC_ADDR_en, MCAUSE_ADDR_en;

logic [31:0] MIE_reg, MTVEC_reg, MSCRATCH_reg, MEPC_reg, MCAUSE_reg; 

assign mie_o = MIE_reg;
assign mtvec_o = MTVEC_reg;
assign mepc_o = MEPC_reg;

logic [4:0] addr_bus;

always_comb begin
    case(opcode_i)
        CSR_RW: mux0_out <= rs1_data_i;
        CSR_RS: mux0_out <= read_data_o | rs1_data_i;
        CSR_RC: mux0_out <= read_data_o & ~rs1_data_i;
        CSR_RWI: mux0_out <= imm_data_i;
        CSR_RSI: mux0_out <= read_data_o | imm_data_i;
        CSR_RCI: mux0_out <= read_data_o & ~imm_data_i;
    endcase
    case(addr_i)
        MIE_ADDR: addr_bus <= {4'b0, write_enable_i};
        MTVEC_ADDR: addr_bus <= {3'b0, write_enable_i, 1'b0};
        MSCRATCH_ADDR: addr_bus <= {2'b0, write_enable_i, 2'b0};
        MEPC_ADDR: addr_bus <= {1'b0, write_enable_i, 3'b0};
        MCAUSE_ADDR: addr_bus <= {write_enable_i, 4'b0};
        default: addr_bus <= 5'b00000;
    endcase
end

always @(posedge clk_i) begin
    if(rst_i) MIE_reg <= 'b0;
    else begin
        if(addr_bus[0]) MIE_reg <= mux0_out;
    end
end

always @(posedge clk_i) begin
    if(rst_i) MTVEC_reg <= 'b0;
    else begin
        if(addr_bus[1]) MTVEC_reg <= mux0_out;
    end
end

always @(posedge clk_i) begin
    if(rst_i) MSCRATCH_reg <= 'b0;
    else begin
        if(addr_bus[2]) MSCRATCH_reg <= mux0_out;
    end
end

always @(posedge clk_i) begin
    if(rst_i) MEPC_reg <= 'b0;
    else begin
        if(addr_bus[3] | trap_i) begin
            case(trap_i)
                1'b0: MEPC_reg <= mux0_out;
                1'b1: MEPC_reg <= pc_i;
            endcase
        end
    end
end

always @(posedge clk_i) begin
    if(rst_i) MCAUSE_reg <= 'b0;
    else begin
        if(addr_bus[4] | trap_i) begin
            case(trap_i)
                1'b0: MCAUSE_reg <= mux0_out;
                1'b1: MCAUSE_reg <= mcause_i;
            endcase
        end
    end
end

always_comb begin
    case(addr_i)
        MIE_ADDR: read_data_o <= MIE_reg;
        MTVEC_ADDR: read_data_o <= MTVEC_reg;
        MSCRATCH_ADDR: read_data_o <= MSCRATCH_reg;
        MEPC_ADDR: read_data_o <= MEPC_reg;
        MCAUSE_ADDR: read_data_o <= MCAUSE_reg;
        default: read_data_o <= 'b0;
    endcase
end

endmodule
