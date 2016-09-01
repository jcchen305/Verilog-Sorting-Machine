`timescale 1ns / 1ps

module sort_tb;

reg Reset, Clk;
reg bubbleStart, selectionStart, insertionStart, Ack;

reg [4:0] width;
reg [30*7 - 1:0] Ain;
wire [30*7 - 1:0] bubbleOut, insertionOut, selectionOut;
wire Done;
reg [6:0] Array [0:29];
integer i, output_file;

bubble_sort uut1(
	.width(width),
	.Clk(Clk),
	.Reset(Reset),
	.Start(bubbleStart),
	.Ack(Ack),
	.Ain(Ain),
	.Aout(bubbleOut),
	.Done(Done),
	.q_Ini(b_Ini),
	.q_Incr(b_Incr),
	.q_Comp(b_Comp),
	.q_Done(b_Done)
);

selection_sort uut2(
	.width(width),
	.Clk(Clk),
	.Reset(Reset),
	.Start(selectionStart),
	.Ack(Ack),
	.Ain(Ain),
	.Aout(selectionOut),
	.Done(Done),
	.q_Ini(s_Ini),
	.q_Incr(s_Incr),
	.q_Comp(s_Comp),
	.q_Done(s_Done)
);

insertion_sort uut3(
	.width(width),
	.Clk(Clk),
	.Reset(Reset),
	.Start(insertionStart),
	.Ack(Ack),
	.Ain(Ain),
	.Aout(insertionOut),
	.Done(Done),
	.q_Ini(i_Ini),
	.q_Incr(i_Incr),
	.q_Comp(i_Comp),
	.q_Done(i_Done)
);

initial
	begin: CLOCK_GENERATOR
		Clk = 0;
		forever
			begin
				#5 Clk = ~Clk;
			end
	end
	
initial begin
	output_file = $fopen ("results.txt", "w");
end

initial begin
	Clk = 0;
	Reset = 0;
	bubbleStart = 0;
	selectionStart = 0;
	insertionStart = 0;
	Ack = 0;
	width = 30;

	@ (posedge Clk)
	@ (posedge Clk)
	# 1;
	Reset = 1;
	@ (posedge Clk);
	# 1;
	Reset = 0;	
	
	$fdisplay(output_file, "Bubble Sort Initial Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = (i*17)%113;
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]);
	for (i = 1; i <= 30; i = i + 1)
		Ain[(i-1)*7 +: 7] = Array[i-1];
		
	@ (posedge Clk)
	@ (posedge Clk)
	# 1;
	bubbleStart = 1;
	@ (posedge Clk);
	bubbleStart = 0;
	
	wait (b_Done)
	# 1;
	$fdisplay(output_file, "Bubble Sort Completed Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = bubbleOut[(i-1)*7 +: 7];	
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]);
	Ack = 1;
	@ (posedge Clk);
	Ack = 0;
	
	$fdisplay(output_file, "Selection Sort Initial Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = (i*19)%113;
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]); 
	for (i = 1; i <= 30; i = i + 1)
		Ain[(i-1)*7 +: 7] = Array[i-1];
		
	@ (posedge Clk)
	@ (posedge Clk)
	# 1;
	selectionStart = 1;
	@ (posedge Clk);
	selectionStart = 0;
	
	wait (s_Done)
	# 1;
	$fdisplay(output_file, "Selection Sort Completed Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = selectionOut[(i-1)*7 +: 7];	
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]);
	Ack = 1;
	@ (posedge Clk);
	Ack = 0;
	
	$fdisplay(output_file, "Insertion Sort Initial Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = (i*89)%113;
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]);
	for (i = 1; i <= 30; i = i + 1)
		Ain[(i-1)*7 +: 7] = Array[i-1];
		
	@ (posedge Clk)
	@ (posedge Clk)
	# 1;
	insertionStart = 1;
	@ (posedge Clk);
	insertionStart = 0;
	
	wait (i_Done)
	# 1;
	$fdisplay(output_file, "Insertion Sort Completed Array:");
	for (i = 1; i <= 30; i = i + 1)
		Array[i-1] = insertionOut[(i-1)*7 +: 7];	
	for (i = 1; i <= 30; i = i + 1)
		$fdisplay (output_file, "%d : %d", i, Array[i-1]);
	Ack = 1;
	@ (posedge Clk);
	Ack = 0;
	
end
	

endmodule