`include "lib/defines.vh"
module EX(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,

    output wire data_sram_en,   // if load or store?
    output wire [3:0] data_sram_wen,  //all 0:load, all 1:store
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,

    //data correlation
    output wire [`EX_TO_MEM_WD-1:0] ex_to_id_forwarding,

    //stall 
    output wire stallreq_for_ex,

    output wire stall_en    //to id
);

    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        // else if (flush) begin
        //     id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        // end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        else if (stall[2]==`NoStop) begin
            id_to_ex_bus_r <= id_to_ex_bus;
        end
    end

    wire [31:0] ex_pc, inst;
    wire [11:0] alu_op;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;
    reg is_in_delayslot;
<<<<<<< Updated upstream

    assign {
=======
    
    //lw,lb,lbu,lh,lhu
    wire [4:0] op_mem;
    //sw,sb,sh
    wire [2:0] op_ex;
    // Mul and Div signal
    wire [3:0] op_mul_and_div;
    // move operation's source
    wire [3:0] move_sourse;
    // helo_reg write enable signal of this cycle
    wire hi_we, lo_we;
    wire [31:0] hi_rdata;
    wire [31:0] lo_rdata;

    assign { 
        op_ex,          // 238:240
        op_mem,         // 223:237
        op_mul_and_div, // 229:232
        move_sourse,    // 215:218
        // hilo_reg's
        hi_we,          // 214
        lo_we,          // 213
        hi_rdata,       // 181:212
        lo_rdata,       // 149:180

>>>>>>> Stashed changes
        ex_pc,          // 148:117
        inst,           // 116:85
        alu_op,         // 84:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,         // 63:32
        rf_rdata2          // 31:0
    } = id_to_ex_bus_r;

    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    assign imm_sign_extend = {{16{inst[15]}},inst[15:0]};
    assign imm_zero_extend = {16'b0, inst[15:0]};
    assign sa_zero_extend = {27'b0,inst[10:6]};

    wire [31:0] alu_src1, alu_src2;
    wire [31:0] alu_result, ex_result;


    assign alu_src1 = sel_alu_src1[1] ? ex_pc :
                      sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend :
                      sel_alu_src2[2] ? 32'd8 :
                      sel_alu_src2[3] ? imm_zero_extend : rf_rdata2;
    
    alu u_alu(
    	.alu_control (alu_op      ),
        .alu_src1    (alu_src1    ),
        .alu_src2    (alu_src2    ),
        .alu_result  (alu_result  )
    );

<<<<<<< Updated upstream
    assign ex_result = alu_result;

    //load and store instructions
    assign stall_en = (inst[31:26]==6'b10_0011)?1'b1:1'b0;   

=======
// Move: if move_sourse!=0 then current is a move operation
// Mul and Div: if op_mul_and_div!=0 then current is a mul or div operation
//////////////////////////////////////////////////
    assign ex_result =    move_sourse[2] ? hi_rdata
                        : move_sourse[3] ? lo_rdata
                        : alu_result;
    
    assign hi_result =    (move_sourse[0] & hi_we) ? rf_rdata1
                        : (move_sourse[1] & hi_we) ? rf_rdata2
                        : (op_mul_and_div[0]|op_mul_and_div[1]) ? mul_result[63:32]    // mul's high 32
                        : (op_mul_and_div[2]|op_mul_and_div[3]) ? div_result[63:32]    // div's remain
                        : hi_rdata;
    
    assign lo_result =    (move_sourse[0] & lo_we) ? rf_rdata1
                        : (move_sourse[1] & lo_we) ? rf_rdata2
                        : (op_mul_and_div[0]|op_mul_and_div[1]) ? mul_result[31:0]    // mul's low 32
                        : (op_mul_and_div[2]|op_mul_and_div[3]) ? div_result[31:0]    // div's quotient
                        : hi_rdata;
//////////////////////////////////////////////////
    

    // load and store instructions
    //assign stall_en = (op_mem[0]|op_mem[1]|op_mem[2]|op_mem[3]|op_mem[4])?1'b1:1'b0;
    assign stall_en = (inst[31:26]==6'b10_0011|inst[31:26]==6'b10_0000|inst[31:26]==6'b10_0100|inst[31:26]==6'b10_0001|inst[31:26]==6'b10_0101)?1'b1:1'b0;   
    //inst[31:26]==6'b10_0011|inst[31:26]==6'b10_0000
>>>>>>> Stashed changes
    assign data_sram_en = data_ram_en;
    assign data_sram_wen =  op_ex[0] ? 4'b1111                                              //inst_sw
                          :(op_ex[1]&&(alu_result[1:0]==2'b00)) ? 4'b0001                   //inst_sb
                          :(op_ex[1]&&(alu_result[1:0]==2'b01)) ? 4'b0010
                          :(op_ex[1]&&(alu_result[1:0]==2'b10)) ? 4'b0100
                          :(op_ex[1]&&(alu_result[1:0]==2'b11)) ? 4'b1000
                          :(op_ex[2]&&(alu_result[1:0]==2'b00)) ? 4'b0011                   //inst_sh
                          :(op_ex[2]&&(alu_result[1:0]==2'b10)) ? 4'b1100
                          :4'b0000;  
    assign data_sram_addr = alu_result;                             //address  for loading
    assign data_sram_wdata = op_ex[0]? rf_rdata2                    //inst_sw
                            :op_ex[1]?{4{rf_rdata2[7:0]}}           //inst_sb
                            :op_ex[2]?{2{rf_rdata2[15:0]}}          //inst_sh
                            :32'b0;

<<<<<<< Updated upstream
    //

    //stall part start
    assign stallreq_for_ex = `NoStop;

    //stall part end
=======
    assign ex_to_mem_bus = {
        op_mem,         //142:146
        // hilo_reg's
        hi_we,          // 141
        lo_we,          // 140
        hi_result,      // 108:139
        lo_result,      // 76:107
>>>>>>> Stashed changes

    assign ex_to_mem_bus = {
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };

    assign ex_to_id_forwarding = {
<<<<<<< Updated upstream
=======
        op_mem,         //142:146
        // hilo_reg's
        hi_we,          // 141
        lo_we,          // 140
        hi_result,      // 108:139
        lo_result,      // 76:107

>>>>>>> Stashed changes
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };

<<<<<<< Updated upstream
    // MUL part
    wire [63:0] mul_result;
    wire mul_signed; // 有符号乘法标�?
=======

// Mul and Div
//////////////////////////////////////////////////
    // MUL part
    wire mul_signed;                        // 1 then mul is negtive
    assign mul_signed = op_mul_and_div[0];

    wire [63:0] mul_result;                 // result
    reg stallreq_for_mul;                   // stallreq_for_mul
>>>>>>> Stashed changes

    mul u_mul(
    	.clk        (clk            ),
        .resetn     (~rst           ),
        .mul_signed (mul_signed     ),
<<<<<<< Updated upstream
        .ina        (      ), // 乘法源操作数1
        .inb        (      ), // 乘法源操作数2
        .result     (mul_result     ) // 乘法结果 64bit
=======
        .ina        (rf_rdata1      ),      // scource 1
        .inb        (rf_rdata2      ),      // scource 2
        .result     (mul_result     )       // mul's result is 64bit
>>>>>>> Stashed changes
    );

    // DIV part
    wire [63:0] div_result;
    wire inst_div, inst_divu;
    wire div_ready_i;
<<<<<<< Updated upstream
    reg stallreq_for_div;
    assign stallreq_for_ex = stallreq_for_div;

=======
    wire [63:0] div_result;                 // result
    reg stallreq_for_div;                   // stallreq_for_mul
>>>>>>> Stashed changes
    reg [31:0] div_opdata1_o;
    reg [31:0] div_opdata2_o;
    reg div_start_o;
    reg signed_div_o;

    div u_div(
    	.rst          (rst          ),
        .clk          (clk          ),
        .signed_div_i (signed_div_o ),
        .opdata1_i    (div_opdata1_o    ),
        .opdata2_i    (div_opdata2_o    ),
        .start_i      (div_start_o      ),
        .annul_i      (1'b0      ),
        .result_o     (div_result     ), // 除法结果 64bit
        .ready_o      (div_ready_i      )
    );

    always @ (*) begin
        if (rst) begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
        end
        else begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
<<<<<<< Updated upstream
            case ({inst_div,inst_divu})
=======
            case ({op_mul_and_div[2], op_mul_and_div[3]})
>>>>>>> Stashed changes
                2'b10:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                2'b01:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                default:begin
                end
            endcase
        end
    end
<<<<<<< Updated upstream

    // mul_result �? div_result 可以直接使用
    
=======
// can directly use "mul_result" and "div_result"

// Stall for Mul and Div
//////////////////////////////////////////////////   
    reg cnt;                 //count for stall mul
    reg next_cnt;
    
    always @ (posedge clk) begin
        if (rst) begin
           cnt <= 1'b0; 
        end
        else begin
           cnt <= next_cnt; 
        end
    end

    always @ (*) begin
        if (rst) begin
            stallreq_for_mul <= 1'b0;
            next_cnt <= 1'b0;
        end
        else if((op_mul_and_div[0]|op_mul_and_div[1])&~cnt) begin
            stallreq_for_mul <= 1'b1;
            next_cnt <= 1'b1;
        end
        else if((op_mul_and_div[0]|op_mul_and_div[1])&cnt) begin
            stallreq_for_mul <= 1'b0;
            next_cnt <= 1'b0;
        end
        else begin
           stallreq_for_mul <= 1'b0;
           next_cnt <= 1'b0; 
        end
    end 

    assign stallreq_for_ex = stallreq_for_div | stallreq_for_mul;
////////////////////////////////////////////////// 
>>>>>>> Stashed changes
    
endmodule