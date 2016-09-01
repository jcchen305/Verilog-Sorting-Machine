`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module Sorter(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, 
	Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0,
	BtnL, BtnU, BtnD, BtnR, BtnC,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	
	input ClkPort;
	input BtnL, BtnU, BtnD, BtnR, BtnC;
	input Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, sortReset, start, ClkPort, board_clk, clk, button_clk;
	wire [1:0]	ssdscan_clk;
	
	wire [3:0] Xin, Yin;
	wire [6:0] nextVal;
	
	reg	[26:0] DIV_CLK;
	
	reg [3:0] SSD;
	wire [3:0] SSD3, SSD2, SSD1, SSD0;
	reg [7:0] SSD_CATHODES;
	
	//2-D array
	wire [6:0] A[0:29];
	reg arraySet, Ack;
	reg [4:0] index;
	reg bubbleStart, selectionStart, insertionStart;
	reg [30*7 - 1:0] Ain;
	reg temp;
	wire [30*7 - 1:0] bubbleOut, selectionOut, insertionOut;
	integer i;
	genvar j;	
	
	BUF BUF1 (board_clk, ClkPort); 	

	// A is the array to be displayed. It is constantly drive by Ain.
	generate
	for (j = 1; j <= 30; j = j + 1)
		assign A[j-1] = Ain[j*7 - 1 : (j-1)*7];
	endgenerate

	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0; 
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY; 

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;

	//wire R = CounterY>=(position-10) && CounterY<=(position+10) && CounterX[8:5]==7;
	wire R = CounterY >= ( 450 - (A[(CounterX) /21] * 3)) && CounterY <= 450 && CounterX <= 630 && (CounterX % 21 == 0 || CounterX % 21 == 1 || CounterX % 21 == 2 || CounterX % 21 == 3);   
	wire G = 0;
	//wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	wire B = R;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	// Keep LD7, LD6, and LD5 off
	assign {LD7, LD6, LD5} = {1'b0};
	// LD0 shows if array is set
	assign LD0 = arraySet;
	// LD1, LD2, LD3, and LD4 shows which state it's in
	assign LD1 = b_Ini && s_Ini && i_Ini;
	assign LD2 = b_Incr || s_Incr || i_Incr;
	assign LD3 = b_Comp || s_Comp || i_Comp;
	assign LD4 = b_Done || s_Done || i_Done;
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	assign Xin = {Sw7, Sw6, Sw5};
	assign Yin = {Sw4, Sw3, Sw2, Sw1};
	assign sortReset = Sw0;
	assign nextVal = {Xin, Yin};
	
	assign SSD3 = index[4];
	assign SSD2 = {index[3],index[2],index[1],index[0]};
	assign SSD1 = {1'b0, Xin};
	assign SSD0 = Yin;
	
	assign ssdscan_clk = DIV_CLK[19:18];

	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11

	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD0;
				  2'b01: SSD = SSD1;
				  2'b10: SSD = SSD2;
				  2'b11: SSD = SSD3;
		endcase 
	end
	
	always @ (SSD)
	begin: HEX_TO_SSD
		case (SSD)
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end
	
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////	
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  Everything else starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	// Add value PB
	ee201_debouncer #(.N_dc(25)) debouncer1
		(.CLK(board_clk), .RESET(sortReset), .PB(BtnU), .DPB( ), .SCEN(addValue), .MCEN( ), .CCEN( ));
	
	// Lock the array PB
	ee201_debouncer #(.N_dc(25)) debouncer2
		(.CLK(board_clk), .RESET(sortReset), .PB(BtnD), .DPB( ), .SCEN(lockArray), .MCEN( ), .CCEN( ));

	// Bubble Sort PB
	ee201_debouncer #(.N_dc(25)) debouncer3
		(.CLK(board_clk), .RESET(sortReset), .PB(BtnL), .DPB( ), .SCEN(bubbleInit), .MCEN( ), .CCEN( ));

	// Selection Sort PB
	ee201_debouncer #(.N_dc(25)) debouncer4
		(.CLK(board_clk), .RESET(sortReset), .PB(BtnC), .DPB( ), .SCEN(selectionInit), .MCEN( ), .CCEN( ));

	// Insertion Sort PB
	ee201_debouncer #(.N_dc(25)) debouncer5
		(.CLK(board_clk), .RESET(sortReset), .PB(BtnR), .DPB( ), .SCEN(insertionInit), .MCEN( ), .CCEN( ));

	// Bubble Sort module
	bubble_sort (.width(index), .Clk(DIV_CLK[21]), .Reset(sortReset), .Start(bubbleStart), .Ain(Ain), .Ack(Ack), .Aout(bubbleOut), .Done(), .q_Ini(b_Ini), .q_Incr(b_Incr), .q_Comp(b_Comp), .q_Done(b_Done));
	
	// Selection Sort module
	selection_sort(.width(index), .Clk(DIV_CLK[21]), .Reset(sortReset), .Start(selectionStart), .Ain(Ain), .Ack(Ack), .Aout(selectionOut), .Done(), .q_Ini(s_Ini), .q_Incr(s_Incr), .q_Comp(s_Comp), .q_Done(s_Done));

	// Insertion Sort PB
	insertion_sort(.width(index), .Clk(DIV_CLK[21]), .Reset(sortReset), .Start(insertionStart), .Ain(Ain), .Ack(Ack), .Aout(insertionOut), .Done(), .q_Ini(i_Ini), .q_Incr(i_Incr), .q_Comp(i_Comp), .q_Done(i_Done));

	always @ (posedge board_clk) 
	begin
		if (sortReset)
		begin
			index <= 0;
			Ain <= 210'b0;
			arraySet <= 0;
			bubbleStart <= 0;
			selectionStart <= 0;
			insertionStart <= 0;
		end
		else
		begin
			if (addValue && !arraySet) 
			begin
				// Insert value into array 
				Ain[index*7 +: 7] <= nextVal;
				// Increment index
				index <= index + 1;
				// If index at the end, hold it there
				if (index == 30)
					index <= 30;
			end
			
			// Toggle arraySet
			else if (lockArray) 
			begin
				arraySet <= ~arraySet;
			end
			
			else if (bubbleInit && arraySet)
			begin
				bubbleStart <= 1;
				arraySet <= 0;
				Ack <= 0;
			end
			
			else if (selectionInit && arraySet)
			begin
				selectionStart <= 1;
				arraySet <= 0;
				Ack <= 0;
			end
			
			else if (insertionInit && arraySet)
			begin
				insertionStart <= 1;
				arraySet <= 0;
				Ack <= 0;
			end
			
			// Update Ain whenever reached the comp state
			else if (b_Comp)
			begin
				Ain <= bubbleOut;
			end
			
			else if (s_Comp)
			begin
				Ain <= selectionOut;
			end
			
			else if (i_Comp)
			begin
				Ain <= insertionOut;
			end
			
			// If done, update Ain and acknowledge
			else if (b_Done || s_Done || i_Done)
			begin
				if (b_Done)
					Ain <= bubbleOut;
				else if (s_Done)
					Ain <= selectionOut;
				else if (i_Done)
					Ain <= insertionOut;
				bubbleStart <= 0;
				selectionStart <= 0;
				insertionStart <= 0;
				Ack <= 1;
				index <= 0;
			end
		end
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  Everything else ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////

endmodule
