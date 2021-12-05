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

### 12.6：通过point9~12
* 添加了指令SLTI、SLTIU