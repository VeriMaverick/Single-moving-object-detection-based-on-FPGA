module System_Ctrl_PLL
(
	//globol clock
	input				clk,
	input				rst_n,

	//synced signal
	output 				sys_rst_n,	//system reset
	output 				clk_c0,		//clock output	
	output 				clk_c1,		//clock output
	output 				clk_c2,		//clock output
	output				clk_c3,		//clock output
	output				clk_c4		//clock output
);

//----------------------------------
//component instantiation for system_delay
wire	delay_done;	//system init delay has done
System_Init_Delay #(
	.SYS_DELAY_TOP	(24'd2500000)	//50ms system init delay
) System_Init_Delay (
	//global clock
	.clk		(clk),
	.rst_n		(1'b1),			//It don't depend on rst_n when power up
	//system interface
	.delay_done	(delay_done)
);
wire	pll_rst = ~delay_done;// ? ~locked : 1'b1;	//PLL reset, H valid


//-----------------------------------
//system pll module
wire	locked;
SYS_PLL	SYS_PLL 
(
	.inclk0		(clk),
	.areset		(pll_rst),
	.locked		(locked),
	.c0			(clk_c0),	// 100MHz
	.c1			(clk_c1),	// 100MHz
	.c2			(clk_c2),	// 25MHz
	.c3			(clk_c3),	// 24MHz
	.c4			(clk_c4)	// 48MHz
);

wire	clk_ref = clk_c0;
//----------------------------------------------
//rst_n sync, only controlled by the main clk
reg     rst_nr1, rst_nr2;
always @(posedge clk_ref)
begin
	if(!rst_n)
		begin
		rst_nr1 <= 1'b0;
		rst_nr2 <= 1'b0;
		end
	else
		begin
		rst_nr1 <= 1'b1;
		rst_nr2 <= rst_nr1;
		end
end
assign	sys_rst_n = rst_nr2 & locked;	//active low

endmodule

