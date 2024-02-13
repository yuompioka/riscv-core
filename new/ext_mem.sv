module ext_mem(
    input  logic        clk_i,
    input  logic        mem_req_i,
    input  logic        write_enable_i,
    input  logic [ 3:0] byte_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,
    output logic ready_o
);

logic [31:0] MEM [0:4095];

always_ff @(posedge clk_i) begin
    ready_o <= 1'b0;
    if(mem_req_i == 0 || write_enable_i == 1) begin
        read_data_o <= 32'hfa11_1eaf;
        if(mem_req_i == 1) begin
            ready_o <= 1'b1;
            case(byte_enable_i)
                4'b0001: MEM[addr_i >> 2][7:0] <= write_data_i[7:0];
                4'b0010: MEM[addr_i >> 2][15:8] <= write_data_i[15:8];
                4'b0100: MEM[addr_i >> 2][23:16] <= write_data_i[23:16];
                4'b1000: MEM[addr_i >> 2][31:24] <= write_data_i[31:24];
                4'b0011: MEM[addr_i >> 2][15:0] <= write_data_i[15:0];
                4'b1100: MEM[addr_i >> 2][31:16] <= write_data_i[31:16];
                default: MEM[addr_i >> 2] <= write_data_i;
            endcase
        end
    end
    else begin
        if(mem_req_i == 1 && addr_i <= 4096*4-1) begin
            read_data_o <= MEM[addr_i >> 2];
            ready_o <= 1'b1;
        end
        else read_data_o <= 32'hdead_beef;
    end
end

endmodule
