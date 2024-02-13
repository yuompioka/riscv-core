module interrupt_controller(
    input logic clk_i,
    input logic rst_i,
    input logic exception_i,
    input logic irq_req_i,
    input logic mie_i,
    input logic mret_i,
    
    output logic irq_ret_o,
    output logic [31:0] irq_cause_o,
    output logic irq_o
);

logic exc_h, irq_h;

logic ex_or_exch;
assign ex_or_exch = exception_i | exc_h;

assign irq_o = (irq_req_i & mie_i) & ~(irq_h | ex_or_exch);
assign irq_cause_o = 32'h1000_0010;
assign irq_ret_o = mret_i & ~ex_or_exch;

always @(posedge clk_i) begin
    if(rst_i) exc_h <= 1'b0;
    else exc_h <= ex_or_exch & ~mret_i;
end

always @(posedge clk_i) begin
    if(rst_i) irq_h <= 1'b0;
    else irq_h <= (irq_o | irq_h) & ~irq_ret_o;
end

endmodule
