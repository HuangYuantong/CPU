`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/19 18:46
// Design Name: 
// Module Name: Mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MUL(
	input wire rst,							//复位
	input wire clk,							//时钟
	input wire signed_mul_i,				//是否为有符号乘法运算，1位有符号
	input wire[31:0] opdata1_i,				//乘数
	input wire[31:0] opdata2_i,				//被乘数
	input wire start_i,						//是否开始乘法运算
	input wire annul_i,						//是否取消乘法运算，1位取消
	output reg[63:0] result_o,				//乘法运算结果
	output reg ready_o						//乘法运算是否结束
	
);
	

	reg [5:0] cnt;							//记录乘加法进行了几轮
	reg[64:0] multdend;						//中间计算结果
	reg [1:0] state;						//乘法器处于的状态	
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	wire [63:0] mul_add;            //中间乘数分解得到的加法数
    reg  [31:0] mul_y;                      //乘数，运算时每次右移一位
    reg  [63:0] mul_x;                //加载被乘数，运算时每次左移一位
	assign mul_add = mul_y[0] ? mul_x : {`ZeroWord, `ZeroWord} ;
	
	always @ (posedge clk) begin
		if (rst) begin
			state <= `MulFree;
			result_o <= {`ZeroWord,`ZeroWord};
			ready_o <= `MulResultNotReady;
		end else begin
			case(state)
			
				`MulFree: begin			//乘法器空闲
					if (start_i == `MulStart && annul_i == 1'b0) begin
						if(opdata2_i == `ZeroWord||opdata1_i== `ZeroWord) begin			//如果乘法中有数是0
							state <= `MulByZero;
						end else begin
							state <= `MulOn;					//数不为0
							cnt <= 6'b000000;
							if(signed_mul_i == 1'b1 && opdata1_i[31] == 1'b1) begin			//乘数为负数
								temp_op1 = ~opdata1_i + 1;
							end else begin
								temp_op1 = opdata1_i;
							end
							if (signed_mul_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin			//被乘数为负数
								temp_op2 = ~opdata2_i + 1;
							end else begin
								temp_op2 = opdata2_i;
							end
							multdend <= {`ZeroWord, `ZeroWord};
							mul_x <= {`ZeroWord, temp_op1};
							mul_y <= temp_op2;
						end
					end else begin
						ready_o <= `MulResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
				`MulByZero: begin			//乘法中有数为0
					multdend <= {`ZeroWord, `ZeroWord};
					state <= `MulEnd;
				end
				
				`MulOn: begin				//乘法中数不为0
					if(annul_i == 1'b0) begin			//进行乘法运算
						if(cnt != 6'b100000) begin
							mul_x <= {mul_x[62:0],1'b0};  //被乘数x每次左移一位
                            mul_y <= {1'b0,mul_y[31:1]}; //相当于乘数y右移一位
                            multdend <= multdend + mul_add;//中间结果加上加法数
							cnt <= cnt +1;		//乘加法运算次数
						end	else begin
							if ((signed_mul_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin  //乘法中有一个负数
								multdend <= (~multdend + 1);
							end
							state <= `MulEnd;
							cnt <= 6'b000000;
						end
					end else begin	
						state <= `MulFree;
					end
				end
				
				`MulEnd: begin			//乘法结束
					result_o <= multdend;
					ready_o <= `MulResultReady;
					if (start_i == `MulStop) begin
						state <= `MulFree;
						ready_o <= `MulResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
			endcase
		end
	end


endmodule