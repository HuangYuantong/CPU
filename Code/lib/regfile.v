`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,

// hilo_reg's
//////////////////////////////////////////////////
    input wire rst,
    // write
    input wire hi_we,
    input wire lo_we,
    input wire [31:0]hi_i,
    input wire [31:0]lo_i,
    // read
    output wire [31:0] hi_o,
    output wire [31:0] lo_o
//////////////////////////////////////////////////

);
    reg [31:0] reg_array [31:0];
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : reg_array[raddr1];
    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : reg_array[raddr2];

// hilo_reg's
//////////////////////////////////////////////////
    reg [31:0] hi, lo;
    always @ (posedge clk) begin
        // if (rst) begin
        //     hi <= 32'b0;
        // end
        // else 
        if (hi_we) begin
            hi <= hi_i;
        end
    end

    always @ (posedge clk) begin
        // if (rst) begin
        //     lo <= 32'b0;
        // end
        // else 
        if (lo_we) begin
            lo <= lo_i;
        end
    end

    assign hi_o = hi;
    assign lo_o = lo;
//////////////////////////////////////////////////

endmodule