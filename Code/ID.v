`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,   //stall

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus, 

    //data correlation
    input wire [`EX_TO_MEM_WD-1:0] ex_to_id_forwarding,  //ex-->id

    input wire [`MEM_TO_WB_WD-1:0] mem_to_id_forwarding,  //mem-->id

    input wire [`WB_TO_RF_WD-1:0] wb_to_id_forwarding,  //wb-->id

    input wire stall_en
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

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
    
    assign stallreq = ((stall_en) & ((rs == ex_forwarding_waddr) | (rt == ex_forwarding_waddr))) ? `Stop: `NoStop;
    assign inst = id_stop ? inst : inst_sram_rdata;

    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

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

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
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
<<<<<<< Updated upstream
         inst_bgez, inst_bgtz, inst_blez , inst_bltz, inst_bgezal, inst_bltzal, inst_jalr;


    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;
=======
         // point 37~43, branch
         inst_bgez, inst_bgtz, inst_blez , inst_bltz, inst_bgezal, inst_bltzal, inst_jalr,
         // point 44~58, div and move
         inst_div , inst_divu , inst_mult, inst_multu,
         inst_mflo, inst_mfhi , inst_mthi, inst_mtlo ,
         inst_lb,   inst_lbu  , inst_lh  , inst_lhu  ,
         inst_sb,   inst_sh;

>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
    assign inst_jalr    = op_d[6'b00_0000] & func_d[6'b00_1001];
=======
    assign inst_jalr    = op_d[6'b00_0000] & rt_d[5'b0_0000] & func_d[6'b00_1001];
    // point 44~58, div and move
    assign inst_div     = op_d[6'b00_0000] & func_d[6'b01_1010];
    assign inst_divu    = op_d[6'b00_0000] & func_d[6'b01_1011];
    assign inst_mult    = op_d[6'b00_0000] & func_d[6'b01_1000];
    assign inst_multu   = op_d[6'b00_0000] & func_d[6'b01_1001];
    assign inst_mflo    = op_d[6'b00_0000] & func_d[6'b01_0010];
    assign inst_mfhi    = op_d[6'b00_0000] & func_d[6'b01_0000];
    assign inst_mthi    = op_d[6'b00_0000] & func_d[6'b01_0001];
    assign inst_mtlo    = op_d[6'b00_0000] & func_d[6'b01_0011];
    //point 59~  , l and s
    assign inst_lb      = op_d[6'b10_0000];
    assign inst_lbu     = op_d[6'b10_0100];
    assign inst_lh      = op_d[6'b10_0001];
    assign inst_lhu     = op_d[6'b10_0101];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];
>>>>>>> Stashed changes

//////////////////////////////////////////////////


// EX preparation
//////////////////////////////////////////////////
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_subu | inst_addu | inst_or  |
                             inst_lw  | inst_xor   | inst_sltu | inst_sw   | inst_slt |
                             inst_slti| inst_sltiu | inst_add  | inst_addi | inst_sub |
                             inst_and | inst_andi  | inst_nor  | inst_xori | inst_sllv|
<<<<<<< Updated upstream
                             inst_srav| inst_srlv;
=======
                             inst_srav| inst_srlv  | inst_div  | inst_divu | inst_mult|
                             inst_multu| inst_mthi | inst_mtlo | inst_lb   | inst_lbu |
                             inst_lh  | inst_lhu   | inst_sb   | inst_sh;
>>>>>>> Stashed changes

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_bgezal| inst_bltzal| inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;

    // rt to reg2
    assign sel_alu_src2[0] = inst_subu | inst_addu | inst_sll | inst_or   | inst_xor |
                              inst_sltu| inst_slt  | inst_add | inst_sub  | inst_and |
                              inst_nor | inst_sllv | inst_sra | inst_srav | inst_srl |
                              inst_srlv;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lw | inst_sw | inst_slti |
                             inst_sltiu| inst_addi | inst_lb | inst_lbu| inst_lh   |
                             inst_lhu | inst_sb    | inst_sh;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_bgezal| inst_bltzal| inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;

    // ALU operation
    assign op_add  = inst_addiu | inst_addu | inst_jal   | inst_lw    | inst_sw   |
                     inst_add   | inst_addi | inst_bgezal| inst_bltzal| inst_jalr |
                     inst_lb    | inst_lbu  | inst_lh    | inst_lhu   | inst_sb   |
                     inst_sh;
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


<<<<<<< Updated upstream
// MEM preparation
//////////////////////////////////////////////////
    // load and store enable
    assign data_ram_en = inst_lw | inst_sw;   

    // write enable
    assign data_ram_wen =  inst_sw? 4'b1111
=======
// Mul, Div and Move operation
//////////////////////////////////////////////////
    // Mul and Div
    wire [3:0] op_mul_and_div;
    // mult signal
    assign op_mul_and_div[0] = inst_mult ;
    // multu signal
    assign op_mul_and_div[1] = inst_multu;
    // div signal
    assign op_mul_and_div[2] = inst_div  ;
    // divu signal
    assign op_mul_and_div[3] = inst_divu ;

    // Move
    wire [3:0] move_sourse;
    // rs to move sourse
    assign move_sourse[0] = inst_mthi | inst_mtlo;
    // rd to move sourse
    assign move_sourse[1] = 1'b0;
    // hi to move sourse
    assign move_sourse[2] = inst_mfhi;
    // lo to move sourse
    assign move_sourse[3] = inst_mflo;
//////////////////////////////////////////////////

//lw,lb,lbu,lh,lhu
/////////////////////////////////////////////////
wire [4:0] op_mem;
assign op_mem[0]=inst_lw;
assign op_mem[1]=inst_lb;
assign op_mem[2]=inst_lbu;
assign op_mem[3]=inst_lh;
assign op_mem[4]=inst_lhu;
////////////////////////////////////////////////
//sw,sb,sh
///////////////////////////////////////////////
wire [2:0] op_ex;
assign op_ex[0]=inst_sw;
assign op_ex[1]=inst_sb;
assign op_ex[2]=inst_sh;
//////////////////////////////////////////////
// MEM preparation
//////////////////////////////////////////////////
    // RAM load and store enable
    assign data_ram_en = inst_lw | inst_sw | inst_lb | inst_lbu| inst_lh | inst_lhu | inst_sb | inst_sh;   

    // RAM write enable
    assign data_ram_wen =  ( inst_sw | inst_sb | inst_sh )? 4'b1111
>>>>>>> Stashed changes
                         : 4'b0000; 

    // regfile store enable
    assign rf_we = inst_ori    | inst_lui  | inst_addiu | inst_subu | inst_addu |
                     inst_jal  | inst_sll  | inst_or    | inst_lw   | inst_xor  |
                     inst_sltu | inst_slt  | inst_slti  | inst_sltiu| inst_add  |
                     inst_addi | inst_sub  | inst_and   | inst_andi |inst_nor   |
                     inst_xori |inst_sllv  | inst_sra   | inst_srav | inst_srl  |
<<<<<<< Updated upstream
                     inst_srlv |inst_bgezal| inst_bltzal| inst_jalr;
=======
                     inst_srlv |inst_bgezal| inst_bltzal| inst_jalr | inst_mflo |
                     inst_mfhi | inst_lb   | inst_lbu   | inst_lh   | inst_lhu;
>>>>>>> Stashed changes

    // store in [rd]
    assign sel_rf_dst[0] = inst_subu   | inst_addu | inst_sll | inst_or   | inst_xor |
                             inst_sltu | inst_slt  | inst_add | inst_sub  | inst_and |
                             inst_nor  | inst_sllv | inst_sra | inst_srav | inst_srl |
                             inst_srlv  ;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori     | inst_lui  | inst_addiu | inst_lw  | inst_slti |
                             inst_sltiu | inst_addi | inst_andi  | inst_xori| inst_lb   |
                             inst_lbu   | inst_lh   | inst_lhu;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bgezal | inst_bltzal | inst_jalr;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
<<<<<<< Updated upstream
    assign sel_rf_res = inst_lw ;
 //////////////////////////////////////////////////   

    

    //data correlation start
    // we just use six of these variables, maybe after we will use the others
    //ex_to_id_forwarding
    wire [31:0] ex_forwarding_ex_pc;
    wire ex_forwarding_data_ram_en;
    wire [3:0] ex_forwarding_data_ram_wen;
    wire ex_forwarding_sel_rf_res;
    wire ex_forwarding_we;             //main use
    wire [4:0] ex_forwarding_waddr;    //main use
    wire [31:0] ex_forwarding_result;     //main use
    //mem_to_id_forwarding
    wire [31:0] mem_forwarding_mem_pc;
    wire mem_forwarding_we;                //main use
    wire [4:0] mem_forwarding_waddr;   //main use
    wire [31:0] mem_forwarding_wdata;  //main use
=======
    assign sel_rf_res = inst_lw | inst_lb | inst_lbu | inst_lh | inst_lhu;

    // store in hi
    assign hi_we = inst_div | inst_divu | inst_mult | inst_multu | inst_mthi;

    // store in lo
    assign lo_we = inst_div | inst_divu | inst_mult | inst_multu | inst_mtlo;
//////////////////////////////////////////////////

    

// forwarding
//////////////////////////////////////////////////
    wire [4:0] forwarding_op_mem;
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
>>>>>>> Stashed changes

    
    wire [31:0] selected_rdata1, selected_rdata2;

    assign {
<<<<<<< Updated upstream
        ex_forwarding_ex_pc,          // 75:44
        ex_forwarding_data_ram_en,    // 43
        ex_forwarding_data_ram_wen,   // 42:39
        ex_forwarding_sel_rf_res,     // 38
        ex_forwarding_we,          // 37
        ex_forwarding_waddr,       // 36:32
        ex_forwarding_result       // 31:0
=======
        forwarding_op_mem,
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
>>>>>>> Stashed changes
    } = ex_to_id_forwarding;

    assign {
        mem_forwarding_mem_pc,    //41:38
        mem_forwarding_we,     //37
        mem_forwarding_waddr,  //36:32
        mem_forwarding_wdata   //31:0
    } = mem_to_id_forwarding;


    assign selected_rdata1 = (ex_forwarding_we & (ex_forwarding_waddr == rs)) ? ex_forwarding_result
                            :(mem_forwarding_we & (mem_forwarding_waddr == rs)) ? mem_forwarding_wdata
                            :(wb_rf_we & (wb_rf_waddr == rs)) ? wb_rf_wdata
                            :rdata1;

    assign selected_rdata2 = (ex_forwarding_we & (ex_forwarding_waddr == rt)) ? ex_forwarding_result
                            :(mem_forwarding_we & (mem_forwarding_waddr == rt)) ? mem_forwarding_wdata
                            :(wb_rf_we & (wb_rf_waddr == rt)) ? wb_rf_wdata
                            :rdata2;
    
    //data correlation end

    assign id_to_ex_bus = {
<<<<<<< Updated upstream
=======
        op_ex,          // 238:240
        op_mem,         // 233:237
        op_mul_and_div, // 229:232
        move_sourse,    // 225:228
        // hilo_reg's
        hi_we,          // 224
        lo_we,          // 223
        selected_hi_rdata,// 191:222
        selected_lo_rdata,// 159:190

>>>>>>> Stashed changes
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
        selected_rdata1,         // 63:32
        selected_rdata2          // 31:0
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