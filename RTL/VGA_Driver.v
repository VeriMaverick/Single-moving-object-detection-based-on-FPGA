module VGA_Driver(  	
	//global clock
	input			clk,			//system clock
	input			rst_n,     		//sync reset
	
	//lcd interface
	output			lcd_dclk,   	//lcd pixel clock
	output			lcd_blank,		//lcd blank
	output			lcd_sync,		//lcd sync
	output			lcd_hs,	    	//lcd horizontal sync
	output			lcd_vs,	    	//lcd vertical sync
	output			lcd_en,			//lcd display enable
	output	[15:0]	lcd_rgb,		//lcd display data

	//user interface
	output			lcd_request,	//lcd data request
	output	[11:0]	lcd_xpos,		//lcd horizontal coordinate
	output	[11:0]	lcd_ypos,		//lcd vertical coordinate
	input	[15:0]	lcd_data		//lcd data
);	 
`include "VGA_Para.vh" 

/*******************************************
		SYNC--BACK--DISP--FRONT
*******************************************/
//------------------------------------------
//h_sync counter & generator
reg [11:0] hcnt; 
always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
		hcnt <= 12'd0;
	else
		begin
        if(hcnt < `H_TOTAL - 1'b1)		//line over			
            hcnt <= hcnt + 1'b1;
        else
            hcnt <= 12'd0;
		end
end 
assign	lcd_hs = (hcnt <= `H_SYNC - 1'b1) ? 1'b0 : 1'b1;

//------------------------------------------
//v_sync counter & generator
reg [11:0] vcnt;
always@(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		vcnt <= 12'b0;
	else if(hcnt == `H_TOTAL - 1'b1)		//line over
		begin
		if(vcnt < `V_TOTAL - 1'b1)		//frame over
			vcnt <= vcnt + 1'b1;
		else
			vcnt <= 12'd0;
		end
end
assign	lcd_vs = (vcnt <= `V_SYNC - 1'b1) ? 1'b0 : 1'b1;

//------------------------------------------
//LCELL	LCELL(.in(clk),.out(lcd_dclk));
assign	lcd_dclk = ~clk;
assign	lcd_blank = lcd_hs & lcd_vs;		
assign	lcd_sync = 1'b0;

reg   lcd_vs_r;
wire  pre_lcd_request;


always @(posedge clk or negedge rst_n)
if(!rst_n)begin 
lcd_vs_r <=0;
end 
else lcd_vs_r <=lcd_vs;

wire rising =(~lcd_vs_r & lcd_vs) ? 1'b1 :1'b0;
		
reg [3:0] cnt_fps;
wire  rd_en =(cnt_fps==8)?1'b1 :1'b0;

always @(posedge clk or negedge rst_n)
if(!rst_n)begin 
cnt_fps <=0;
end 
else if((rising)&(cnt_fps<8))
cnt_fps <=cnt_fps+1;
else 
cnt_fps <=cnt_fps;

assign lcd_request =  pre_lcd_request & rd_en ;

//-----------------------------------------
assign	lcd_en		=	(hcnt >= `H_SYNC + `H_BACK  && hcnt < `H_SYNC + `H_BACK + `H_DISP) &&
						(vcnt >= `V_SYNC + `V_BACK  && vcnt < `V_SYNC + `V_BACK + `V_DISP) 
						? 1'b1 : 1'b0;
assign	lcd_rgb 	= 	lcd_en ? lcd_data : 16'h000000;	//ffffff;



//------------------------------------------
//ahead x clock
localparam	H_AHEAD = 	12'd1;


assign	pre_lcd_request	=	(hcnt >= `H_SYNC + `H_BACK - H_AHEAD && hcnt < `H_SYNC + `H_BACK + `H_DISP - H_AHEAD) &&
						(vcnt >= `V_SYNC + `V_BACK && vcnt < `V_SYNC + `V_BACK + `V_DISP) 
						? 1'b1 : 1'b0;
//lcd xpos & ypos
assign	lcd_xpos	= 	lcd_request ? (hcnt - (`H_SYNC + `H_BACK - H_AHEAD)) : 11'd0;
assign	lcd_ypos	= 	lcd_request ? (vcnt - (`V_SYNC + `V_BACK)) : 12'd0;



endmodule
