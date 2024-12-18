module count_8(
    input clk,
    input rst_n,
    output reg Q0,
    output reg Q1,
    output reg Q2
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Q0 <= 1'b0;
        Q1 <= 1'b0;
        Q2 <= 1'b0;
    end else begin
        {Q2, Q1, Q0} <= {Q2, Q1, Q0} + 1'b1;
    end
end

endmodule