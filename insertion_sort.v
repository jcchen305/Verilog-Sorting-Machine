module insertion_sort(width, Reset, Clk, Start, Ack, Ain, Aout, Done, q_Ini, q_Incr, q_Comp, q_Done);

input [4:0] width;
input Reset, Clk;
input Start, Ack;
input [30*7 - 1:0] Ain;

output [30*7 - 1:0] Aout;
output Done;
output q_Ini, q_Incr, q_Comp, q_Done;

wire q_Ini, q_Incr, q_Comp, q_Done;
wire [30*7 - 1:0] Aout;
reg [6:0] A [0:29];
reg [3:0] state;
reg[4:0] K,J, Index;
reg Done;
genvar l;
integer i;

localparam
	INI = 4'b0001,
	INCR = 4'b0010,
	COMP = 4'b0100,
	DONE = 4'b1000,
	UNKN = 4'bXXXX;
	
generate
for (l = 1; l <= 30; l = l + 1)
	assign Aout[l*7-1:(l-1)*7] = A[l-1];
endgenerate	

assign {q_Done, q_Comp, q_Incr, q_Ini} = state;
	
always @ (posedge Clk, posedge Reset)
begin
	if (Reset)
	begin
		state <= INI;
		K <= 5'bXXXXX;
		J <= 5'bXXXXX;
	end
	else
	begin
		case (state) 
		
			INI:
			begin
				if (Start && width >= 2)
					state <= INCR;
				else if (Start && width < 2)
					state <= DONE;
			
				for (i = 1; i <= 30; i = i + 1)
					A[i-1] <= Ain[(i-1)*7 +: 7];
				K <= 5'b00000;
				J <= 5'b00000;
				Done <= 0;
			end
			
			INCR:
			begin
				state <= COMP;
				
				J <= K + 1;
				Index <= K;
			end
			
			COMP:
			begin
				if (J == width && K != width - 2)
					state <= INCR;
				else if (J == width && K == width - 2)
					state <= DONE;
					
				J <= J + 1;
				if (A[J] < A[Index])
					Index <= J;
				if (J == width)
				begin
					A[Index] <= A[K];
					A[K] <= A[Index];
					K <= K + 1;
				end
			end
			
			DONE:
			begin 
				if (Ack) 
					state <= INI;
					
				Done <= 1;
			end
				
			default:
				state <= UNKN;
		endcase
	end
end

endmodule