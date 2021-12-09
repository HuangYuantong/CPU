`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,   // stall

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus, 

    //data correlation
    input wire [`EX_TO_MEM_WD-1:0] ex_to_id_forwarding,     //ex-->id
    input wire [`MEM_TO_WB_WD-1:0] mem_to_id_forwarding,    //mem-->id

    input wire stall_en    // stall signal from EX
    
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    reg id_stop;

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            id_stop <= 1'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            id_stop <= 1'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
            id_stop <= 1'b0;
        end
        else if(stall[2] == `Stop) begin
            id_stop <= 1'b1;
        end
    end
    
    assign stallreq = ((stall_en) & ((rs == forwarding_ex_rf_waddr) | (rt == forwarding_ex_rf_waddr)))
                     ? `Stop : `NoStop;
    assign inst = id_stop ? inst : inst_sram_rdata;

    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;

// Write and Read all the Registers (both normal and hilo)
//////////////////////////////////////////////////
    // 
    // Write from Last Cycle
    // 
    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    // hilo_reg write
    wire wb_hi_we;
    wire wb_lo_we;
    wire [31:0]wb_hi_wdata;
    wire [31:0]wb_lo_wdata;

    assign {
        // hilo_reg's
        wb_hi_we,
        wb_lo_we,
        wb_hi_wdata,
        wb_lo_wdata,

        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    // 
    // Read and Decide-if-write from This Cycle
    // 
    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    // helo_reg write enable signal of this cycle
    wire hi_we, lo_we;
    wire [31:0] hi_rdata;
    wire [31:0] lo_rdata;

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs     ),
        .rdata1 (rdata1 ),
        .raddr2 (rt     ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we   ),
        .waddr  (wb_rf_waddr),
        .wdata  (wb_rf_wdata),
        // hilo_reg's part
        .rst    (rst        ),
        // write
        .hi_we  (wb_hi_we   ),
        .lo_we  (wb_lo_we   ),
        .hi_i   (wb_hi_wdata),
        .lo_i   (wb_lo_wdata),
        // read
        .hi_o   (hi_rdata   ),
        .lo_o   (lo_rdata   )
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

// operation declare
//////////////////////////////////////////////////
    wire inst_ori , inst_lui , inst_addiu, inst_beq , inst_subu,
         inst_addu, inst_jal , inst_jr   , inst_sll , inst_or  ,
         inst_lw  , inst_xor , inst_sltu , inst_bne , inst_sw  ,
         inst_slt , inst_slti, inst_sltiu, inst_j   , inst_add ,
         inst_addi, inst_sub , inst_and  , inst_andi, inst_nor ,
         inst_xori, inst_sllv, inst_sra  , inst_srav, inst_srl , inst_srlv ,
         inst_bgez, inst_bgtz, inst_blez , inst_bltz, inst_bgezal, inst_bltzal, inst_jalr,  // point 37~43
         inst_div , inst_mlfo;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011];
    assign inst_addu    = op_d[6'b00_0000] & func_d[6'b10_0001];
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jr      = op_d[6'b00_0000] & func_d[6'b00_1000];
    assign inst_sll     = op_d[6'b00_0000] & func_d[6'b00_0000];
    assign inst_or      = op_d[6'b00_0000] & func_d[6'b10_0101];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_xor     = op_d[6'b00_0000] & func_d[6'b10_0110];
    assign inst_sltu    = op_d[6'b00_0000] & func_d[6'b10_1011];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_sw      = op_d[6'b10_1011];
    assign inst_slt     = op_d[6'b00_0000] & func_d[6'b10_1010];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    assign inst_j       = op_d[6'b00_0010];
    assign inst_add     = op_d[6'b00_0000] & func_d[6'b10_0000];
    assign inst_addi    = op_d[6'b00_1000];
    assign inst_sub     = op_d[6'b00_0000] & func_d[6'b10_0010];
    assign inst_and     = op_d[6'b00_0000] & func_d[6'b10_0100];
    assign inst_andi    = op_d[6'b00_1100];
    assign inst_nor     = op_d[6'b00_0000] & func_d[6'b10_0111];
    assign inst_xori    = op_d[6'b00_1110];
    assign inst_sllv    = op_d[6'b00_0000] & func_d[6'b00_0100];
    assign inst_sra     = op_d[6'b00_0000] & func_d[6'b00_0011];
    assign inst_srav    = op_d[6'b00_0000] & func_d[6'b00_0111];
    assign inst_srl     = op_d[6'b00_0000] & func_d[6'b00_0010];
    assign inst_srlv    = op_d[6'b00_0000] & func_d[6'b00_0110];
    // point 37~43, branch
    assign inst_bgez    = op_d[6'b00_0001] & rt_d[5'b0_0001];
    assign inst_bgtz    = op_d[6'b00_0111] & rt_d[5'b0_0000];
    assign inst_blez    = op_d[6'b00_0110] & rt_d[5'b0_0000];
    assign inst_bltz    = op_d[6'b00_0001] & rt_d[5'b0_0000];
    assign inst_bgezal  = op_d[6'b00_0001] & rt_d[5'b10_001];
    assign inst_bltzal  = op_d[6'b00_0001] & rt_d[5'b10_000];
    assign inst_jalr    = op_d[6'b00_0000] & rt_d[5'b0_0000] & func_d[6'b00_1001];
    // point 44~, div and move
    assign inst_div     = op_d[6'b00_0000] & func_d[6'b01_1010];
    assign inst_mlfo    = op_d[6'b00_0000] & func_d[6'b01_0010];

//////////////////////////////////////////////////

// EX preparation
//////////////////////////////////////////////////
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_subu | inst_addu | inst_or  |
                             inst_lw  | inst_xor   | inst_sltu | inst_sw   | inst_slt |
                             inst_slti| inst_sltiu | inst_add  | inst_addi | inst_sub |
                             inst_and | inst_andi  | inst_nor  | inst_xori | inst_sllv|
                             inst_srav| inst_srlv  | inst_div;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_bgezal| inst_bltzal| inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;

    // rt to reg2
    assign sel_alu_src2[0] = inst_subu | inst_addu | inst_sll | inst_or   | inst_xor |
                              inst_sltu| inst_slt  | inst_add | inst_sub  | inst_and |
                              inst_nor | inst_sllv | inst_sra | inst_srav | inst_srl |
                              inst_srlv| inst_div;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lw | inst_sw | inst_slti |
                             inst_sltiu| inst_addi;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_bgezal| inst_bltzal| inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;

    // ALU operation
    wire op_add, op_sub, op_slt, op_sltu,
        op_and, op_nor, op_or, op_xor,
        op_sll, op_srl, op_sra, op_lui;

    assign op_add  = inst_addiu | inst_addu | inst_jal   | inst_lw    | inst_sw   |
                     inst_add   | inst_addi | inst_bgezal| inst_bltzal| inst_jalr;
    assign op_sub  = inst_subu  | inst_sub;
    assign op_slt  = inst_slt   | inst_slti;
    assign op_sltu = inst_sltu  | inst_sltiu;
    assign op_and  = inst_and   | inst_andi;
    assign op_nor  = inst_nor;
    assign op_or   = inst_ori  | inst_or;
    assign op_xor  = inst_xor  | inst_xori;
    assign op_sll  = inst_sll  | inst_sllv;
    assign op_srl  = inst_srl  | inst_srlv;
    assign op_sra  = inst_sra  | inst_srav;
    assign op_lui  = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};
//////////////////////////////////////////////////


// Mul, Div and Move operation
//////////////////////////////////////////////////
    // Mul and Div
    wire [1:0] op_mul_and_div;
    // mul signal
    assign op_mul_and_div[0] = 1'b0;
    // div signal
    assign op_mul_and_div[1] = inst_div;
    
    // Move
    wire [3:0] move_sourse;
    // rs to move sourse
    assign move_sourse[0] = 1'b0;
    // rd to move sourse
    assign move_sourse[1] = 1'b0;
    // hi to move sourse
    assign move_sourse[2] = 1'b0;
    // lo to move sourse
    assign move_sourse[3] = inst_mlfo;
//////////////////////////////////////////////////


// MEM preparation
//////////////////////////////////////////////////
    // RAM load and store enable
    assign data_ram_en = inst_lw | inst_sw;   

    // RAM write enable
    assign data_ram_wen =  inst_sw? 4'b1111
                         : 4'b0000; 

    // regfile store enable
    assign rf_we = inst_ori    | inst_lui  | inst_addiu | inst_subu | inst_addu |
                     inst_jal  | inst_sll  | inst_or    | inst_lw   | inst_xor  |
                     inst_sltu | inst_slt  | inst_slti  | inst_sltiu| inst_add  |
                     inst_addi | inst_sub  | inst_and   | inst_andi |inst_nor   |
                     inst_xori |inst_sllv  | inst_sra   | inst_srav | inst_srl  |
                     inst_srlv |inst_bgezal| inst_bltzal| inst_jalr | inst_mlfo ;

    // store in [rd]
    assign sel_rf_dst[0] = inst_subu   | inst_addu | inst_sll | inst_or   | inst_xor |
                             inst_sltu | inst_slt  | inst_add | inst_sub  | inst_and |
                             inst_nor  | inst_sllv | inst_sra | inst_srav | inst_srl |
                             inst_srlv | inst_jalr | inst_mlfo;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori     | inst_lui  | inst_addiu | inst_lw  | inst_slti |
                             inst_sltiu | inst_addi | inst_andi  | inst_xori;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bgezal | inst_bltzal;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw ;

    // store in hi
    assign hi_we = inst_div;

    // store in lo
    assign lo_we = inst_div;
//////////////////////////////////////////////////

    

// forwarding
//////////////////////////////////////////////////
    wire forwarding_ex_hi_we;
    wire forwarding_ex_lo_we;
    wire [31:0] forwarding_ex_hi_result;
    wire [31:0] forwarding_ex_lo_result;
    wire [31:0] forwarding_ex_pc;
    wire forwarding_data_ram_en;
    wire [3:0] forwarding_data_ram_wen;
    wire forwarding_sel_rf_res;
    wire forwarding_ex_rf_we;             // EX needs to write
    wire [4:0] forwarding_ex_rf_waddr;    // EX's writing address
    wire [31:0] forwarding_ex_result;     // EX's writing value

    wire forwarding_mem_hi_we;
    wire forwarding_mem_lo_we;
    wire [31:0] forwarding_mem_hi_result;
    wire [31:0] forwarding_mem_lo_result;
    wire [31:0] forwarding_mem_pc;
    wire forwarding_mem_rf_we;            // MEM needs to write
    wire [4:0] forwarding_mem_rf_waddr;   // MEM's writing address
    wire [31:0] forwarding_mem_rf_wdata;  // MEM's writing value

    
    wire [31:0] selected_rdata1, selected_rdata2;
    wire [31:0] selected_hi_rdata, selected_lo_rdata;

    assign {
        forwarding_ex_hi_we,
        forwarding_ex_lo_we,
        forwarding_ex_hi_result,
        forwarding_ex_lo_result,
        forwarding_ex_pc,           // 75:44
        forwarding_data_ram_en,     // 43
        forwarding_data_ram_wen,    // 42:39
        forwarding_sel_rf_res,      // 38
        forwarding_ex_rf_we,        // 37
        forwarding_ex_rf_waddr,     // 36:32
        forwarding_ex_result        // 31:0
    } = ex_to_id_forwarding;

    assign {
        forwarding_mem_hi_we,
        forwarding_mem_lo_we,
        forwarding_mem_hi_result,
        forwarding_mem_lo_result,
        forwarding_mem_pc,          //41:38
        forwarding_mem_rf_we,       //37
        forwarding_mem_rf_waddr,    //36:32
        forwarding_mem_rf_wdata     //31:0
    } = mem_to_id_forwarding;


    assign selected_rdata1 = (forwarding_ex_rf_we & (forwarding_ex_rf_waddr == rs)) ? forwarding_ex_result
                            : (forwarding_mem_rf_we & (forwarding_mem_rf_waddr == rs)) ? forwarding_mem_rf_wdata
                            : (wb_rf_we & (wb_rf_waddr == rs)) ? wb_rf_wdata
                            : rdata1;

    assign selected_rdata2 = (forwarding_ex_rf_we & (forwarding_ex_rf_waddr == rt)) ? forwarding_ex_result
                            : (forwarding_mem_rf_we & (forwarding_mem_rf_waddr == rt)) ? forwarding_mem_rf_wdata
                            : (wb_rf_we & (wb_rf_waddr == rt)) ? wb_rf_wdata
                            : rdata2;
    
    assign selected_hi_rdata = forwarding_ex_hi_we ? forwarding_ex_hi_result
                            : forwarding_mem_hi_we ? forwarding_mem_hi_result
                            : wb_hi_we ? wb_hi_wdata
                            : hi_rdata;

    assign selected_lo_rdata = forwarding_ex_lo_we ? forwarding_ex_lo_result
                            : forwarding_mem_lo_we ? forwarding_mem_lo_result
                            : wb_lo_we ? wb_lo_wdata
                            : lo_rdata;

//////////////////////////////////////////////////

    assign id_to_ex_bus = {
        op_mul_and_div, // 229:230
        move_sourse,    // 225:228
        // hilo_reg's
        hi_we,          // 224
        lo_we,          // 223
        selected_hi_rdata,// 191:222
        selected_lo_rdata,// 159:190

        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        selected_rdata1,// 63:32
        selected_rdata2 // 31:0
    };


// jump and branch
//////////////////////////////////////////////////
    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;

    wire [31:0] pc_plus_4;
    wire [31:0] target_offset;
    assign pc_plus_4 = id_pc + 32'h4;
    assign target_offset = {{14{inst[15]}}, inst[15:0], 2'b0};
    
    assign rs_eq_rt  = (selected_rdata1 == selected_rdata2);    // rs=rt: 1 then yes, 0 then no
    assign rs_ge_z   = (~selected_rdata1[31]);  // rs>=0: (0 then >=0, 1 then <0)
    assign rs_gt_z   = (~selected_rdata1[31]) & ~(selected_rdata1 == 32'b0);    // rs>0: rs >=0 && rs!=0
    assign rs_le_z   = (selected_rdata1[31] | (selected_rdata1 == 32'b0));  // rs<=0: 1 then <0 || rs==0
    assign rs_lt_z   = (selected_rdata1[31]);   // rs<0: 1 then <0


    assign br_e = (inst_beq & rs_eq_rt)    | inst_jal   | inst_jr   | (inst_bne & (~rs_eq_rt)) | inst_j |
                    (inst_bgez & rs_ge_z)  | (inst_bgtz & rs_gt_z)  | (inst_blez & rs_le_z) | (inst_bltz & rs_lt_z) |
                    (inst_bgezal & rs_ge_z)| (inst_bltzal & rs_lt_z)| inst_jalr;

    assign br_addr =  inst_beq  ?  pc_plus_4 + target_offset
                    : inst_jal  ?  {pc_plus_4[31:28], inst[25:0], 2'b0}
                    : inst_jr   ?  selected_rdata1
                    : inst_bne  ?  pc_plus_4 + target_offset
                    : inst_j    ?  {pc_plus_4[31:28], inst[25:0], 2'b0}
                    : inst_bgez ?  pc_plus_4 + target_offset 
                    : inst_bgtz ?  pc_plus_4 + target_offset
                    : inst_blez ?  pc_plus_4 + target_offset 
                    : inst_bltz ?  pc_plus_4 + target_offset
                    : inst_bgezal? pc_plus_4 + target_offset 
                    : inst_bltzal? pc_plus_4 + target_offset
                    : inst_jalr ?  selected_rdata1
                    : 32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
//////////////////////////////////////////////////   

endmodule