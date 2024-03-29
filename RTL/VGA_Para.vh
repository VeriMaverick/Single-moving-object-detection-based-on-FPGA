

`timescale 1ns/1ns

//-----------------------------------------------------------------------
//Define the color parameter RGB--8|8|8
//define colors RGB--8|8|8
`define RED		24'hFF0000   /*11111111,00000000,00000000	*/
`define GREEN	24'h00FF00   /*00000000,11111111,00000000	*/
`define BLUE  	24'h0000FF   /*00000000,00000000,11111111	*/
`define WHITE 	24'hFFFFFF   /*11111111,11111111,11111111	*/
`define BLACK 	24'h000000   /*00000000,00000000,00000000	*/
`define YELLOW	24'hFFFF00   /*11111111,11111111,00000000	*/
`define CYAN  	24'hFF00FF   /*11111111,00000000,11111111	*/
`define ROYAL 	24'h00FFFF   /*00000000,11111111,11111111	*/ 

//---------------------------------
`define	SYNC_POLARITY 1'b0

//------------------------------------
//vga parameter define

`define	VGA_640_480_60FPS_25MHz
//`define	VGA_800_600_60FPS_40MHz
//`define	VGA_1280_720_60FPS_74_25MHz
//`define	VGA_1920_1080_60FPS_148_5MHz

//---------------------------------
//	640 * 480
`ifdef	VGA_640_480_60FPS_25MHz
`define	H_FRONT	12'd16
`define	H_SYNC 	12'd96  
`define	H_BACK 	12'd48  
`define	H_DISP	12'd640 
`define	H_TOTAL	12'd800 	
 				
`define	V_FRONT	12'd10  
`define	V_SYNC 	12'd2   
`define	V_BACK 	12'd33 
`define	V_DISP 	12'd480   
`define	V_TOTAL	12'd525
`endif

//---------------------------------
//	800 * 600
`ifdef VGA_800_600_60FPS_40MHz 
`define	H_FRONT	12'd40
`define	H_SYNC 	12'd128  
`define	H_BACK 	12'd88  
`define	H_DISP 	12'd800
`define	H_TOTAL	12'd1056 
				
`define	V_FRONT	12'd1 
`define	V_SYNC 	12'd4   
`define	V_BACK 	12'd23  
`define	V_DISP 	12'd600  
`define	V_TOTAL	12'd628
`endif


//---------------------------------
//	1280 * 720
`ifdef	VGA_1280_720_60FPS_74_25MHz
`define	H_FRONT	12'd110
`define	H_SYNC 	12'd40
`define	H_BACK 	12'd220
`define	H_DISP	12'd1280
`define	H_TOTAL	12'd1650
 				
`define	V_FRONT	12'd5
`define	V_SYNC 	12'd5   
`define	V_BACK 	12'd20 
`define	V_DISP 	12'd720   
`define	V_TOTAL	12'd750
`endif



//---------------------------------
//	1920 * 1080
`ifdef	VGA_1920_1080_60FPS_148_5MHz
`define	H_FRONT	12'd88
`define	H_SYNC 	12'd44
`define	H_BACK 	12'd148
`define	H_DISP	12'd1920
`define	H_TOTAL	12'd2200
 					
`define	V_FRONT	12'd4
`define	V_SYNC 	12'd5   
`define	V_BACK 	12'd36
`define	V_DISP 	12'd1080 
`define	V_TOTAL	12'd1125
`endif
