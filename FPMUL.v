module FPMUL(opA_i, opB_i, MUL_o);
	input [15:0] opA_i, opB_i;
	output [15:0] MUL_o;
	wire [10:0] manA={1'b1, opA_i[9:0]};
	wire [10:0] manB={1'b1, opB_i[9:0]};
	reg [5:0] exp_sum;
	reg [21:0] man_mul;

	always @ (*)begin
		if((opA_i[14:10]==5'b11111) | (opB_i[14:10]==5'b11111)) begin	//입력에 overflow가 있는 경우
			man_mul=0;
			exp_sum=6'b011111;
		end
		if((opA_i[14:10]==5'b0) | (opB_i[14:10]==5'b0)) begin	//입력에 0 있는 경우
			man_mul=0;
			exp_sum=0;
		end
		if(opA_i[14:10]+opB_i[14:10]>15) begin
			if (exp_sum>30) begin		//overflow
				exp_sum=6'b011111;
				man_mul=0;
			end
			else begin			//normal
				man_mul=manA*manB;
				exp_sum=opA_i[14:10]+opB_i[14:10]-15;
			end
		end
		else if ((opA_i[14:10]+opB_i[14:10])<15) begin	//underflow
			exp_sum=0;
			man_mul=0;
		end
		else begin
			man_mul=manA*manB;
			if (!man_mul[21]) begin
				man_mul=0;
				exp_sum=0;
			end
		end
		if (man_mul[21]) begin		//normalizing
			man_mul=man_mul>>1;
			exp_sum=exp_sum+1;
			end
			if (exp_sum==0) man_mul=0;
		end
	end
	assign MUL_o={opA_i[15]^opB_i[15], exp_sum[4:0], man_mul[19:10]};
	
endmodule