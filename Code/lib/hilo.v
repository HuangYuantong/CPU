`include "lib/defines.vh"
module hilo_reg(
    input wire clk,
    input wire rst,
    // write
    input wire hi_we,
    input wire lo_we,
    input wire [31:0]hi_i,
    input wire [31:0]lo_i,
    // read
    input wire hi_re,
    input wire lo_re,
    output wire [31:0] hi_o,
    output wire [31:0] lo_o
);

    reg [31:0] hi, lo;
    always @ (posedge clk) begin
        if (rst) begin
            hi <= 32'b0;
        end
        else if (hi_we) begin
            hi <= hi_i;
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            lo <= 32'b0;
        end
        else if (lo_we) begin
            lo <= lo_i;
        end
    end

    assign hi_o = hi_re ? hi : 32'b0;
    assign lo_o = lo_re ? lo : 32'b0;

endmodule