# CPU
 这里是”计算机系统-实现CPU“实验，的repository

**编码格式为：GB 2312，换行符为：CRLF**

## 更新日志
### 11.27：完成EX、MEM段返回至ID段的连线
1. 在EX, MEM分别output wire [37:0] ex/mem_to_id_forwarding。含有：rf_we, rf_waddr, ex_result
2. 在ID中用input wire [37:0] ex/mem_to_id_forwarding接收，并拆为wire ex/mem_forwarding_we, ex/mem_forwarding_waddr, ex/mem_forwarding_wdata
3. 在mycpu_core.v中加入相关连接
4. 在ID中，进行是否发生forwarding的判断：
    * ex/mem_forwarding_we为1，且(&)ex/mem_forwarding_waddr要写入的目标寄存器和当前ID段指令的rs寄存器为同一个(==)，表示前面指令已将源寄存器修改（rdata1发生数据相关）
    * 则将rdata11赋值为相应的ex/mem_forwarding_wdata
    * 若是和rt寄存器为同一个（rdata2发生数据相关），则将rdata22赋值为相应的ex/mem_forwarding_wdata（例如subu指令，rt就是第二个源寄存器）
    * 否则 rdata11=rdata1，rdata22=rdata2

### 12.4：~~完成WB段返回至ID段的连线，~~添加多条指令和流水线暂停：
~~1. 在WB段，ID段和mycou_core.v添加数据相关：wb_to_id_forwarding；~~
2. 添加指令：
    * wire inst_beq, inst_subu, inst_addu
    * wire inst_jal, inst_jr,   inst_sll;
    * wire inst_or , inst_lw ,  inst_xor;  
    * wire inst_sltu,inst_bne;
3. 添加流水线在ID段的周期暂停(lw指令后)：stallreg_id_stop;

### 12.5：通过point8
1. 添加指令：
    * wire inst_sw;  
2.添加id_stop(id段暂停作为判断)用来顺势延长指令执行周期

### 12.6：通过point9~36
* 添加了指令inst_slti、inst_sltiu，通过point9~12
* 添加了指令inst_j、inst_add，通过point13~15
* 添加了指令inst_addi、inst_sub、inst_and、inst_andi、inst_nor、inst_xori、inst_sllv、inst_sra、inst_srav、inst_srl、inst_srlv,inst_bgez，通过point16~36

### 12.8：通过point37-43
* 添加了指令inst_bgtz, inst_blez , inst_bltz, inst_bgezal, inst_bltzal, inst_jalr;通过了point37-43
* 添加了指令inst_slti, inst_sltiu，通过point9~12
* 添加了指令inst_j, inst_add，通过point13~15
* 添加了指令inst_addi, inst_sub, inst_and, inst_andi, inst_nor, inst_xori, inst_sllv, inst_sra, inst_srav, inst_srl, inst_srlv,inst_bgez，通过point16~36

### 12.7：通过point37~43
1. BxxZ类四条指令，添加了指令inst_bgez, inst_bgtz , inst_blez, inst_bltz，通过point37~40
    * 对于rs符号位：0 then rs>=0, 1 then rs<0，所以：
        + ge: >=，判断条件为：rs_ge_z=(~selected_rdata1[31])， 即 >=0
        + gt: > ，判断条件为：rs_gt_z=(~selected_rdata1[31]) & ~(selected_rdata1 == 32'b0)，即 >=0 && !=0
        + le: <=, 判断条件为：rs_le_z=(selected_rdata1[31] | (selected_rdata1 == 32'b0))，即 <0 || =0
        + lt: < , 判断条件为：rs_lt_z=(selected_rdata1[31])，即 <0
    * 其跳转位置都为 (pc_plus_4 + target_offset)
        + 在跳转指令部分：target_offset={{14{inst[15]}}, inst[15:0], 2'b0}，即“立即数 offset左移2位并进行有符号扩展的值，加上该分支指令对应的延迟槽指令的PC”
2. BxxZAL类二条指令，添加了inst_bgezal, inst_bltzal，通过point41~42
    * 除满足上述1中条件外，格外添加操作“将该分支对应延迟槽指令之后的指令的 PC 值保存至31号寄存器中”，所以：
    * 在ID的EX准备阶段：将PC->reg1、32'b8->reg2分别接通，并将ALU功能选为“op_add”
    * 在ID的MEM准备阶段：选择信号“sel_rf_dst[2]”，将结果存入No.31号寄存器
3. 添加inst_jalr指令，通过point43

### 12.9：添加了HI、LO寄存器，及其forwarding
1. hilo寄存器位于regfile中，有各自的hi_we、lo_we写使能信号
2. 通过拓展ID_TO_EX_WD、EX_TO_MEM_WD、MEM_TO_WB_WD、WB_TO_RF_WD（都增加64+2位），完成hilo写使能信号及值在流水线中传递
3. 解决了hilo的RAW数据冲突。对于forwarding：
    + 因为hilo在hi_we、lo_we为1时即为需要写操作无需外加地址判断，所以同步拓宽的ex_to_id_forwarding、mem_to_id_forwarding同样是增加64+2位
    + 在ID段通过以下代码进行forwarding数据前传:
    
            assign selected_hi_rdata = forwarding_ex_hi_we ? forwarding_ex_hi_result
                                : forwarding_mem_hi_we ? forwarding_mem_hi_result
                                : wb_hi_we ? wb_hi_wdata
                                : hi_rdata;
    + 因此selected_hi/lo_rdata为ID段向后传递的数据

4. 添加了move移动指令的实现机制：
    1. 在ID中添加4位信号move_sourse。0~3位依次表示源操作数为rs、rt、hi、lo
    2. ID_TO_EX_WD再次加4，传递至EX，如果move_sourse不为0，则用相应值更新EX段的hi_result、lo_result或ex_result。
    3. **加入了一条移动inst_mlfo指令，PC对了但没加除法指令所以数据不对**
    
5. 添加了乘法和除法指令的实现机制：
    + 类似move移动指令的实现机制，同样在ID中添加2位信号op_mul_and_div。0~1位依次表示操作为乘法、除法。
    + ID_TO_EX_WD再次加2，传递至EX，如果op_mul_and_div不为0，则用相应操作后的div_result或mul_result相应分段更新EX段的hi_result和lo_result。

### 12.11：添加了乘法、除法器接入、移动指令，通过point 44~58
1. 添加了 inst_mult, inst_multu, inst_div , inst_divu 乘法、无符号乘法、除法、无符号除法，指令共4条
    * 将op_mul_and_div拓宽至4位，0~3依次表示操作为：inst_mult, inst_multu, inst_div , inst_divu
    * 乘法：
        * 符号标志：mul_signed = op_mul_and_div[0]（inst_mult指令）
        * 操作数分别为：rf_rdata1、rf_rdata2
        * 添加暂停信号：stallreq_for_mul
    * 除法：
        * 通过以下代码将现有除法器接入：

                wire inst_div, inst_divu;
                assign inst_div  = op_mul_and_div[2];
                assign inst_divu = op_mul_and_div[3];

2. 乘法除法的暂停实现
    * 将EX向CTRL的暂停信号设为：

            assign stallreq_for_ex = stallreq_for_mul | stallreq_for_div
    * 添加寄存器cnt, next_cnt实现乘法暂停
        * 每个时钟周期将cnt <= next_cnt
        * 如果(inst_mult | inst_multu) & ~cnt，则stallreq_for_mul和next_cnt都为1
        * 如果(inst_mult | inst_multu) & cnt ，则stallreq_for_mul和next_cnt都为0
        * 否则，stallreq_for_mul和next_cnt都为0

3. 添加了inst_mfhi, inst_mthi , inst_mtlo移动指令共3条
    * 如上文“move移动指令的实现机制”所记，在ID段设置以下参数即可实现跳转：
        * 设置move_sourse以指定数据源
        * 设置rf_we、hi_we、lo_we以指定目的地

### 12.12: 添加了lb,lbu,lh,lhu,sb,sh指令，通过point 59-64
1. 添加了访存指令：inst_lb,inst_lbu,inst_lh,inst_lhu
    * 在id段添加op_mem[4:0]用来存储五个l指令的信号，传递到mem段
    * 在mem段中通过op_mem中对应指令的信号和ex_result的低位信号(最低两位)来判断mem_result取值；
    * ex_result的低位信号(最低两位)来表示具体取data_sram_rdata的具体位数的字节，剩余位数进行符号扩展补充
2. 添加了访存指令：inst_sb,inst_sh
    * 在id段添加op_ex[2:0]用来存储三个s指令的信号，传递到ex段
    * 在ex段利用op_ex中对应指令的信号和alu_result的低位信号(最低两位)来判断data_sram_wen取值
    * 在ex段利用op_ex中对应指令的信号来判断data_sram_wdata所取的rf_rdata2(rt)的字节位，对于空缺位数用所取字节位进行填充，防止l指令运行时取错
