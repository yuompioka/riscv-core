module riscv_lsu(
    input logic clk_i,
    input logic rst_i,
    
    input logic core_req_i,
    input logic core_we_i,
    input logic [2:0] core_size_i,
    input logic [31:0] core_addr_i,
    input logic [31:0] core_wd_i,
    output logic [31:0] core_rd_o,
    output logic core_stall_o,
    
    output logic mem_req_o,
    output logic mem_we_o,
    output logic [3:0] mem_be_o,
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wd_o,
    input logic [31:0] mem_rd_i,
    input logic mem_ready_i
);

localparam LDST_B = 3'd0;
localparam LDST_H = 3'd1;
localparam LDST_W = 3'd2;
localparam LDST_BU = 3'd4;
localparam LDST_HU = 3'd5;

logic stall;
logic [1:0] byte_offset;
assign byte_offset = core_addr_i[1:0];
logic half_offset;
assign half_offset = core_addr_i[1];

assign core_stall_o = ~(stall & mem_ready_i) & core_req_i;
assign mem_req_o = core_req_i;
assign mem_we_o = core_we_i;
assign mem_addr_o = core_addr_i;

logic [31:0] mux_wire_0, mux_wire_1, mux_wire_2, mux_wire_3;

always_ff @(posedge clk_i) begin
    if(rst_i) stall <= 1'b0;
    else stall <= core_stall_o;
end

always_comb begin
    case(byte_offset)
        2'b00: mux_wire_0 <= {{24{mem_rd_i[7]}}, mem_rd_i[7:0]};
        2'b01: mux_wire_0 <= {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
        2'b10: mux_wire_0 <= {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
        2'b11: mux_wire_0 <= {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
        default: mux_wire_0 <= 'b0;
    endcase
    case(byte_offset)
        2'b00: mux_wire_1 <= {{24{1'b0}}, mem_rd_i[7:0]};
        2'b01: mux_wire_1 <= {{24{1'b0}}, mem_rd_i[15:8]};
        2'b10: mux_wire_1 <= {{24{1'b0}}, mem_rd_i[23:16]};
        2'b11: mux_wire_1 <= {{24{1'b0}}, mem_rd_i[31:24]};
        default: mux_wire_1 <= 'b0;
    endcase
    case(half_offset)
        1'b0: mux_wire_2 <= {{16{mem_rd_i[15]}}, mem_rd_i[15:0]};
        1'b1: mux_wire_2 <= {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};
    endcase
    case(half_offset)
        1'b0: mux_wire_3 <= {{16{1'b0}}, mem_rd_i[15:0]};
        1'b1: mux_wire_3 <= {{16{1'b0}}, mem_rd_i[31:16]};
    endcase
end

always_comb begin
    case(core_size_i)
        LDST_W: mem_be_o <= 4'b1111;
        LDST_H: case(half_offset)
            1'b0: mem_be_o <= 4'b0011;
            1'b1: mem_be_o <= 4'b1100;
            default: mem_be_o <= 4'b0000;
        endcase
        LDST_B: mem_be_o <= 4'b0001 << byte_offset;
        default: mem_be_o <= 4'b0000;
    endcase
    case(core_size_i)
        LDST_H: mem_wd_o <= {{2{core_wd_i[15:0]}}};
        LDST_W: mem_wd_o <= core_wd_i;
        LDST_B: mem_wd_o <= {{4{core_wd_i[7:0]}}};
        default: mem_wd_o <= 'b0;
    endcase
    case(core_size_i)
        LDST_W: core_rd_o <= mem_rd_i;
        LDST_B: core_rd_o <= mux_wire_0;
        LDST_BU: core_rd_o <= mux_wire_1;
        LDST_H: core_rd_o <= mux_wire_2;
        LDST_HU: core_rd_o <= mux_wire_3;
        default: core_rd_o <= 'b0;
    endcase
end

endmodule
