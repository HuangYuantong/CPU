`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,  //read from memory

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    // forwarding
    output wire [`MEM_TO_WB_WD-1:0] mem_to_id_forwarding
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
<<<<<<< HEAD
    
    // helo_reg write
    wire hi_we, lo_we;
    wire [31:0] hi_result, lo_result;

    assign {
=======
<<<<<<< Updated upstream

    assign {
=======
    
    // helo_reg write
    wire hi_we, lo_we;
    wire [31:0] hi_result, lo_result;
    //lw,lb,lbu,lh,lhu
    wire [4:0] op_mem;

    assign {
        op_mem,         //142:146
>>>>>>> Xsword-yzs
        // hilo_reg's
        hi_we,          // 141
        lo_we,          // 140
        hi_result,      // 108:139
        lo_result,      // 76:107

<<<<<<< HEAD
=======
>>>>>>> Stashed changes
>>>>>>> Xsword-yzs
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;
 


    assign mem_result = op_mem[0]?data_sram_rdata                                                              //inst_lw
                       :(op_mem[1]&(ex_result[1:0]==2'b00))? {{24{data_sram_rdata[7]}},data_sram_rdata[7:0]}    //inst_lb
                       :(op_mem[1]&(ex_result[1:0]==2'b01))? {{24{data_sram_rdata[15]}},data_sram_rdata[15:8]}  
                       :(op_mem[1]&(ex_result[1:0]==2'b10))? {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}
                       :(op_mem[1]&(ex_result[1:0]==2'b11))? {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]}
                       :(op_mem[2]&(ex_result[1:0]==2'b00))? {{24{1'b0}},data_sram_rdata[7:0]}    //inst_lbu
                       :(op_mem[2]&(ex_result[1:0]==2'b01))? {{24{1'b0}},data_sram_rdata[15:8]}
                       :(op_mem[2]&(ex_result[1:0]==2'b10))? {{24{1'b0}},data_sram_rdata[23:16]}
                       :(op_mem[2]&(ex_result[1:0]==2'b11))? {{24{1'b0}},data_sram_rdata[31:24]}
                       :(op_mem[3]&(ex_result[1:0]==2'b00))? {{16{data_sram_rdata[15]}},data_sram_rdata[15:0]}    //inst_lh
                       :(op_mem[3]&(ex_result[1:0]==2'b10))? {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}
                       :(op_mem[4]&(ex_result[1:0]==2'b00))? {{16{1'b0}},data_sram_rdata[15:0]}    //inst_lhu
                       :(op_mem[4]&(ex_result[1:0]==2'b10))? {{16{1'b0}},data_sram_rdata[31:16]}
                       : 32'b0;
    
<<<<<<< HEAD
    assign rf_wdata = sel_rf_res ? mem_result
                        : ex_result;
=======
<<<<<<< Updated upstream
    assign rf_wdata = sel_rf_res ? mem_result : ex_result;
=======
    assign rf_wdata = sel_rf_res ? mem_result            //data from memory
                        : ex_result;                     //data from alu or hilo
>>>>>>> Stashed changes
>>>>>>> Xsword-yzs

    assign mem_to_wb_bus = {
        // hilo_reg's
        hi_we,          // 135
        lo_we,          // 134
        hi_result,      // 102:133
        lo_result,      // 70:101

        mem_pc,         // 69:38
        rf_we,          // 37
        rf_waddr,       // 36:32
        rf_wdata        // 31:0
    };

    assign mem_to_id_forwarding = {
        // hilo_reg's
        hi_we,          // 135
        lo_we,          // 134
        hi_result,      // 102:133
        lo_result,      // 70:101

        mem_pc,         // 69:38
        rf_we,          // 37
        rf_waddr,       // 36:32
        rf_wdata        // 31:0
    };


endmodule