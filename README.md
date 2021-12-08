# CPU
 这里是”计算机系统-实现CPU“实验，的repository

**编码格式为：GB 2312，换行符为：CRLF**

## 更新日志
### 11.27：完成EX、MEM段返回至ID段的连线
1. 在EX、MEM分别output wire [37:0] ex/mem_to_id_forwarding。含有：rf_we、rf_waddr、ex_result
2. 在ID中用input wire [37:0] ex/mem_to_id_forwarding接收，并拆为wire ex/mem_forwarding_we、ex/mem_forwarding_waddr、ex/mem_forwarding_wdata
3. 在mycpu_core.v中加入相关连接
4. 在ID中，进行是否发生forwarding的判断：
    * ex/mem_forwarding_we为1，且(&)ex/mem_forwarding_waddr要写入的目标寄存器和当前ID段指令的rs寄存器为同一个(==)，表示前面指令已将源寄存器修改（rdata1发生数据相关）
    * 则将rdata11赋值为相应的ex/mem_forwarding_wdata
    * 若是和rt寄存器为同一个（rdata2发生数据相关），则将rdata22赋值为相应的ex/mem_forwarding_wdata（例如subu指令，rt就是第二个源寄存器）
    * 否则 rdata11=rdata1，rdata22=rdata2
### 12.4：完成WB段返回至ID段的连线，添加多条指令和流水线暂停：
1. 在WB段，ID段和mycou_core.v添加数据相关：wb_to_id_forwarding；
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
### 12.7：通过point37~43
* 添加了指令inst_bgtz, inst_blez , inst_bltz, inst_bgezal, inst_bltzal, inst_jalr;通过point37~43
