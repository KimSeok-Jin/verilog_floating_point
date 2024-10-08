module FPADD(opA_i, opB_i, ADD_o);

	input [15:0] opA_i, opB_i;
	output [15:0] ADD_o;
	
	wire [10:0] manA={1'b1, opA_i[9:0]};
	wire [10:0] manB={1'b1, opB_i[9:0]};
	reg [11:0] man;		//for LZDetect
	
	wire [4:0]expA=opA_i[14:10];
	wire [4:0]expB=opB_i[14:10];	
	reg [5:0] exp_o;
	reg [11:0] man_o;
	reg [9:0] man_f;
	reg sign;
	
	wire valid;
	wire [3:0] count;
	
	LZC_10 u10(man[9:0], valid, count);
	
	always @(*) begin
		if ((opA_i[14:10]==5'b11111)|(opB_i[14:10]==5'b11111)) begin	//입력에 overflow가 있는 경우
			sign=0;
			exp_o=6'b011111;
			man_o=0;
		end
		else if ((opA_i[14:10]==5'b00000)|(opB_i[14:10]==5'b00000)) begin	//입력에 0이 있는 경우
			if ((opA_i[14:10]==5'b00000)) begin
				sign=opB_i[15];
				exp_o={1'b0,opB_i[14:10]};
				man_o={1'b0,1'b1,opB_i[9:0]};
			end
			else if((opB_i[14:10]==5'b00000))begin
				sign=opA_i[15];
				exp_o={1'b0,opA_i[14:10]};
				man_o={1'b0,1'b1,opA_i[9:0]};
			end
		end
		else if(opA_i[14:10]==opB_i[14:10]) begin		//지수가 같을 때
			exp_o={1'b0, opA_i[14:10]};	
			if (opA_i[15]==opB_i[15]) begin		//부호가 같음
				sign=opA_i[15];
				man_o=manA+manB;
				man=manA+manB;
			end
			else begin		//부호가 다름
				if (manA>manB) begin	//절대값이 A가 더 클 때
					sign=opA_i[15];
					man_o=manA-manB;
					man=manA-manB;
				end
				else if (manA<manB) begin	//절대값이 B가 더 클 때
					sign=opB_i[15];
					man_o=manB-manA;	
					man=manB-manA;
				end
				else begin		//지수와 소수가 둘 다 같음
					sign=0;
					man_o=0;
					exp_o=0;
					man=manA-manB;
				end	
			end
		end
		else begin		//두 지수가 다를 때
			if (opA_i[15]==opB_i[15]) begin	//부호가 같을 때
				sign=opA_i[15];
				if (opA_i[14:10]>opB_i[14:10]) begin	//A>B
					exp_o={1'b0, opA_i[14:10]};
					man_o=manA+(manB>>(opA_i[14:10]-opB_i[14:10]));
					man=manA+(manB>>(opA_i[14:10]-opB_i[14:10]));
				end
				else begin								//B>A
					exp_o={1'b0, opB_i[14:10]};
					man_o=manB+(manA>>(opB_i[14:10]-opA_i[14:10]));
					man=manB+(manA>>(opB_i[14:10]-opA_i[14:10]));
				end
			end
			else begin						//부호가 다름
				if (opA_i[14:10]>opB_i[14:10]) begin	//A>B
					sign=opA_i[15];
					exp_o={1'b0, opA_i[14:10]};
					man_o=manA-(manB>>(opA_i[14:10]-opB_i[14:10]));
					man=manA-(manB>>(opA_i[14:10]-opB_i[14:10]));
				end
				else begin								//B>A
					sign=opB_i[15];
					exp_o={1'b0, opB_i[14:10]};
					man_o=manB-(manA>>(opB_i[14:10]-opA_i[14:10]));
					man=manB-(manA>>(opB_i[14:10]-opA_i[14:10]));
				end
			end
		end
		if (man_o[11]) begin			//normalizing1
			man_o=man_o>>1;
			exp_o=exp_o+1;
		end
		if (opA_i[15]==opB_i[15]) begin
			if (exp_o>=6'b011111) begin		//overflow
				exp_o=6'b011111;
				man_o=0;
			end
		
			if (exp_o<6'b000001) begin		//underflow
				exp_o=0;
				man_o=0;
			end
		end
		if ((man_o<12'b010000000000)&&(exp_o<6'b011111)) begin	//normalizing2
			if(valid) begin
				if(exp_o[4:0]>(count+1)) begin
					man_o=man_o<<(count+1);
					exp_o=exp_o-(count+1);
				end
				else begin
					man_o=0;
					exp_o=0;				
				end
			end
			else begin
				man_o=0;		
				exp_o=0;	
			end
		end
	end
	assign ADD_o={sign, exp_o[4:0], man_o[9:0]};
	
endmodule

module LZD_2 (

	input [1:0] IN,
	output VALID,
	output POSITION);
	
	assign VALID = IN[1] | IN[0];
	assign POSITION = ~IN[1];
	
endmodule
	
module LZD_4 (

	input [3:0] IN,
	output VALID,
	output [1:0] POSITION);
	
	wire V_Upper, V_Lower, P_Upper, P_Lower;
	
	LZD_2 u32 (IN[3:2], V_Upper, P_Upper);
	LZD_2 u10 (IN[1:0], V_Lower, P_Lower);
	
	assign VALID = V_Upper | V_Lower;
	assign POSITION[1] = ~V_Upper;
	assign POSITION[0] = V_Upper ? P_Upper : P_Lower;
	
endmodule

module LZD_8 (

	input [7:0] IN,
	output VALID,
	output [2:0] POSITION);
	
	wire V_Upper, V_Lower;
	wire [1:0] P_Upper, P_Lower;
	
	LZD_4 u74 (IN[7:4], V_Upper, P_Upper);
	LZD_4 u30 (IN[3:0], V_Lower, P_Lower);
	
	assign VALID = V_Upper | V_Lower;
	assign POSITION[2] = ~V_Upper;
	assign POSITION[1] = V_Upper ? P_Upper[1] : P_Lower[1];
	assign POSITION[0] = V_Upper ? P_Upper[0] : P_Lower[0];
	
endmodule

	
module LZC_10(

	input [9:0] IN_i,
	output VALID_o,
	output [3:0] COUNT_o);
	
	wire V_Upper, V_Lower;
	wire [2:0] P_Upper;
	wire P_Lower;
	
	LZD_8 u92 (IN_i[9:2], V_Upper, P_Upper);
	LZD_2 u10 (IN_i[1:0],V_Lower, P_Lower);
	
	assign VALID_o=V_Upper | V_Lower;
	
	assign COUNT_o[3]=~V_Upper;
	assign COUNT_o[2]=V_Upper ? P_Upper[2] : P_Lower;
	assign COUNT_o[1]=V_Upper ? P_Upper[1] : P_Lower;
	assign COUNT_o[0]=V_Upper ? P_Upper[0] : P_Lower;

endmodule