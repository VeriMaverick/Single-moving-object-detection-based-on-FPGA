module Video_Image_Process_Moving_Object_Detection #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset
	//Image data prepred to be processd
	input          	cmos_frame_clken,	               
	input          	cmos_frame_vsync,	
	input          	cmos_frame_href,	
	input	[15:0]	cmos_frame_data, 

	//Image data has been processd
	output			post_frame_vsync,	//Processed Image data vsync valid signal
	output			post_frame_href,	//Processed Image data href vaild  signal
	output         	post_frame_clken,
	output	[15:0]	post_img_data,		//Processed Image Gray output
	input	[15:0]	sys_data_out1,//sdram
	output         	gs_clken ,
	output	[15:0] 	gray_sft ,
	output         	sdr_rd 
);

wire        gs_vsync ;
wire        gs_href  ;


wire        post0_frame_vsync ;	
wire        post0_frame_href  ;	
wire        post0_frame_clken ;	
wire [7:0]  post0_data_Y   ;		

wire			post1_frame_vsync;	//Processed Image data vsync valid signal
wire			post1_frame_href;	//Processed Image data href vaild  signal
wire			post1_frame_clken;	//Processed Image data output/capture enable clock
wire	[7:0]	post1_data_diff;		//Processed Image Bit flag outout(1: Value, 0:inValid)
		
wire			post2_frame_vsync;	//Processed Image data vsync valid signal
wire			post2_frame_href;	//Processed Image data href vaild  signal
wire			post2_frame_clken;	//Processed Image data output/capture enable clock
wire			post2_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)

wire			post3_frame_vsync;	//Processed Image data vsync valid signal
wire			post3_frame_href;	//Processed Image data href vaild  signal
wire			post3_frame_clken;	//Processed Image data output/capture enable clock
wire			post3_img_Bit;		//Pro

RGB565_to_YCbCr	RGB565_to_YCbCr(
	.clk   				( clk						),
	.rst_n 				( rst_n						),
	.img_red			( cmos_frame_data[15:11]	),
	.img_green			( cmos_frame_data[10:5]		),
	.img_blue			( cmos_frame_data[4:0]		),
	.pre_frame_hsync 	( cmos_frame_href			),
	.pre_frame_vsync 	( cmos_frame_vsync			),
	.pre_frame_de		( cmos_frame_clken			),
	.img_y				( post0_data_Y				),
	.img_cb				( 							),
	.img_cr				( 							),
	.post_frame_hsync	(post0_frame_href 			),
	.post_frame_vsync	(post0_frame_vsync			),                                                                                                  
	.post_frame_de		(post0_frame_clken			)   
);
//step2
Gray_Shift    Gray_Shift( 
	.clk    	( clk  ) , 
	.rst_n 		( rst_n ) , 
	.clken  	( post0_frame_clken) , 
	.ivsync 	( post0_frame_vsync ) , 
	.ihsync 	( post0_frame_href ) , 
	.graya  	( post0_data_Y ) ,  //next frame 
	.grayb  	( sys_data_out1) ,  //before frame
	.ovsync 	( gs_vsync),
	.ohsync 	( gs_href) ,
	.oclken 	( gs_clken),	
	.ogray  	( gray_sft ), 	
	.sdr_rd 	( sdr_rd   ) 
) ;		
//step3					
//--------------------------------------------------	
Diff_Frame #(
	.THRESHOLD			(8'd20)
) Diff_Frame (
	.clk              (clk) ,	// input  clk
	.rst_n            (rst_n) ,	// input  rst_n
	//.data_en(data_en),
	.per_frame_vsync  (gs_vsync),
	.per_frame_href   (gs_href),
	.per_frame_clken  (gs_clken),
	.data_cur         (gray_sft[7:0]) ,		// 当前帧
	.data_next        (gray_sft[15:8]) ,	// input [7:0] data2
	//Image data has been processd
	.post_frame_vsync	(post1_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href	(post1_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken	(post1_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit		(post1_data_diff)			//Processed Image Bit flag outout(1: Value, 0:inValid)

);



VIPMOD_Bit_Erosion_Detector
#(
	.IMG_HDISP	(10'd640),	//640*480
	.IMG_VDISP	(10'd480)
)
VIPMOD_Bit_Erosion_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post1_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href		(post1_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post1_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post1_data_diff[7]),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post2_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post2_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post2_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post2_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);

//step4
//--------------------------------------
//Bit Image Process with Dilation after Erosion Detector.

VIPMOD_Bit_Dilation_Detector
#(
	.IMG_HDISP	(10'd640),	//640*480
	.IMG_VDISP	(10'd480)
)
VIPMOD_Bit_Dilation_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post2_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href		(post2_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post2_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post2_img_Bit),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post3_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post3_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post3_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post3_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);

//--------------------------------------------------------------------
Find_Box	
#(
	.IMG_Width	(11'd640),	//640*480
	.IMG_High	(11'd480)
)
Find_Box
(
	//global clock
	.clk					(clk),  			//cmos video pixel clock
	.rst_n					(rst_n),			//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post3_frame_vsync),		//Prepared Image data vsync valid signal
	.per_frame_href		(post3_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post3_frame_clken),		//Prepared Image data output/capture enable clock
	.per_img_Y		      (post3_img_Bit),			//Prepared Image brightness input

	.cmos_frame_clken		(cmos_frame_clken), 	//Prepared Image data vsync valid signal
	.cmos_frame_vsync		(cmos_frame_vsync), 		//Prepared Image data href vaild  signal
	.cmos_frame_href		(cmos_frame_href ), 	//Prepared Image data output/capture enable clock
	.cmos_frame_data     (cmos_frame_data),			//Prepared Image brightness input

	//Image data has been processd
	.post_frame_vsync		(post_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Y    	   (post_img_data)			//Processed Image brightness output
);
	

endmodule
