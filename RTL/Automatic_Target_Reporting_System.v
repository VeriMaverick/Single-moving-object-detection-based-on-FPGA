// Project name : Automatic_Target_Reporting_System
// Auther ：Wang Mingjie
// Date ：2024/02/07
// Version ：V1.1

module Automatic_Target_Reporting_System
(
    input			clk			,	// 50MHz
    input			rst_n       ,	// Reset,低电平有效
    // Camera OV5640
    input           cam_pclk    ,   // cmos 数据像素时钟
    output          cam_xclk    ,	// cmos 系统时钟
    input           cam_vsync   ,	// cmos 场同步信号
    input           cam_href    ,	// cmos 行同步信号
    input	[7:0]	cam_data	,	// cmos 数据  
    output			cam_rst_n	,	// cmos 复位信号，低电平有效
    output			cam_pwdn	,	// cmos 电源休眠模式选择信号
    output			cam_scl		,	// cmos SCCB_SCL线
    inout			cam_sda   	,	// cmos SCCB_SDA线
    // VGA	640*480		
    output			vga_hs		,	// VGA 行同步信号
    output			vga_vs		,	// VGA 场同步信号
    output	[4:0]	vga_red		,	// VGA 红色信号
    output	[5:0]	vga_green	,	// VGA 绿色信号
    output	[4:0]	vga_blue	,	// VGA 蓝色信号
    // SDRAM 
    output	[12:0]	sdram_addr	,	// SDRAM 地址
    inout	[15:0]	sdram_data	,	// SDRAM 数据
    output			sdram_we_n	,	// SDRAM 写使能信号
    output			sdram_cke	,	// SDRAM 时钟使能信号
    output			sdram_cs_n	,	// SDRAM 芯片选择信号
    output			sdram_ras_n	,	// SDRAM 行地址选择信号
    output			sdram_cas_n	,	// SDRAM 列地址选择信号
    output	[1:0]	sdram_ba	,	// SDRAM bank选择信号
    output	[1:0]	sdram_dqm	,	// SDRAM 数据掩码
    output			sdram_clk	 	// SDRAM 时钟
);

wire	[15:0]	vout_data;        //vga output data
//system global clock control
wire	sys_rst_n;		//global reset
wire	clk_ref;		//sdram ctrl clock
wire	clk_refout;		//sdram clock output
wire	clk_vga;		//vga clock
wire	clk_48M;		//48MHz SignalTap II Clock

//cmos video image capture
wire        lcd_request ;
wire [15:0]  gray_sft; 
wire         sdr_rd; 
wire         gs_clken ;
wire         post_frame_vsync;
wire         post_frame_href;
wire [15:0]  post_img_data;
wire         post_frame_clken;
//Sdram_Control_4Port module 	
//sdram write port1
wire			sdr_wr1_clk;	//Change with input signal
wire	[7:0]	sdr_wr1_wrdata;
wire			sdr_wr1_wrreq;
//sdram read  port1
wire			sdr_rd1_clk;
wire	[7:0]	sys_data_out1;
wire			sys_rd1;
wire         	RD1_EMPTY;
//sdram write port2
wire			sdr_wr2_clk;	//Change with input signal
wire	[15:0]	sdr_wr2_wrdata;
wire			sdr_wr2_wrreq;
//sdram read  port2
wire			sdr_rd2_clk;
wire	[15:0]	sys_data_out2;
wire			sys_rd2;
wire			RD2_EMPTY;
wire			sdram_init_done;		//sdram init done


// PLL
System_Ctrl_PLL System_Ctrl_PLL
(
    .clk		(clk),			//global clock
    .rst_n		(rst_n),		//external reset
    
    .sys_rst_n	(sys_rst_n),	//global reset
    .clk_c0		(clk_ref),		//100MHz 
    .clk_c1		(clk_refout),	//100MHz clock phase shift -135 deg
    .clk_c2		(clk_vga),		//25MHz
    .clk_c3		(cam_xclk),		//24MHz
    .clk_c4		(clk_48M)		//48MHz SignalTap II Clock
);

// Camera OV5640
localparam  SLAVE_ADDR = 7'h3c         ;  //OV5640的器件地址7'h3c
localparam  BIT_CTRL   = 1'b1          ;  //OV5640的字节地址为16位  0:8位 1:16位
localparam  CLK_FREQ   = 26'd25_000_000;  //i2c_dri模块的驱动时钟频率 25MHz
localparam  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
localparam  CMOS_H_PIXEL = 24'd640     ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
localparam  CMOS_V_PIXEL = 24'd480     ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小
wire                  i2c_exec        ;  //I2C触发执行信号
wire   [23:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟
//不对摄像头硬件复位,固定高电平
assign  cam_rst_n = 1'b1;
//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn = 1'b0;
 //I2C配置模块
IIC_OV5640_RGB565_Config #(
     .CMOS_H_PIXEL  (CMOS_H_PIXEL),
     .CMOS_V_PIXEL  (CMOS_V_PIXEL)
) IIC_OV5640_RGB565_Config(
    .clk           (i2c_dri_clk),
    .rst_n         (rst_n),
    .i2c_done      (i2c_done),
    .i2c_exec      (i2c_exec),
    .i2c_data      (i2c_data),
    .init_done     (cam_init_done)
);    

//I2C驱动模块
IIC_Driver #(
    .SLAVE_ADDR  (SLAVE_ADDR),               //参数传递
    .CLK_FREQ    (CLK_FREQ  ),              
    .I2C_FREQ    (I2C_FREQ  )                
) IIC_Driver(
    .clk         (clk_vga   ),//25M
    .rst_n       (rst_n     ),   
    //i2c interface
    .i2c_exec    (i2c_exec  ),   
    .bit_ctrl    (BIT_CTRL  ),   
    .i2c_rh_wl   (1'b0),                     //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr    (i2c_data[23:8]),   
    .i2c_data_w  (i2c_data[7:0]),   
    .i2c_data_r  (),   
    .i2c_done    (i2c_done  ),   
    .scl         (cam_scl   ),   
    .sda         (cam_sda   ),   
    //user interface
    .dri_clk     (i2c_dri_clk)               //I2C操作时钟
);

//CMOS图像数据采集模块
wire            cmos_frame_vsync;	//cmos frame data vsync valid signal
wire            cmos_frame_href;	//cmos frame data href vaild  signal
wire    [15:0]	cmos_frame_data;	//cmos frame data output: {cmos_data[7:0]<<8, cmos_data[7:0]}	
wire			cmos_frame_clken;	//cmos frame data output/capture enable clock

CMOS_Capture_Data CMOS_Capture_Data(
    .rst_n               (rst_n & cam_init_done), //系统初始化完成之后再开始采集数据 
    .cam_pclk            (cam_pclk),
    .cam_vsync           (cam_vsync),
    .cam_href            (cam_href),
    .cam_data            (cam_data),         
    .cmos_frame_vsync    (cmos_frame_vsync),
    .cmos_frame_href     (cmos_frame_href),
    .cmos_frame_valid    (cmos_frame_clken),            //数据有效使能信号
    .cmos_frame_data     (cmos_frame_data)           //有效数据 
);

SDRAM_Control_4Port SDRAM_Control_4Port(
    //	HOST Side
    .REF_CLK		( clk_ref			),      // 100MHz clock
    .OUT_CLK		( clk_refout		),      // 100MHz clock phase shift -135 deg
    .RESET_N		( sys_rst_n		 	),      //复位输入，低电平复位
    //	FIFO Write Side 1
    .WR1_DATA		( sdr_wr1_wrdata 	),		//写入端口1的数据输入端，16bit
    .WR1			( sdr_wr1_wrreq		),		//写入端口1的写使能端，高电平写入
    .WR1_ADDR		( 0					),		//写入端口1的写起始地址
    .WR1_MAX_ADDR	( 640*480			),		//写入端口1的写入最大地址
    .WR1_LENGTH		( 256				),		//一次性写入数据长度
    .WR1_LOAD		( ~sys_rst_n        ),		//写入端口1清零请求，高电平清零写入地址和fifo
    .WR1_CLK		( sdr_wr1_clk     	),		//写入端口1 fifo写入时钟
    .WR1_FULL		(					),		//写入端口1 fifo写满信号
    .WR1_USE		(					),		//写入端口1 fifo已经写入的数据长度
    //	FIFO Write Side 2
    .WR2_DATA		( sdr_wr2_wrdata	),		//写入端口2的数据输入端，16bit
    .WR2			( sdr_wr2_wrreq		),		//写入端口2的写使能端，高电平写入
    .WR2_ADDR		( 640*480			),		//写入端口2的写起始地址
    .WR2_MAX_ADDR	( 640*480*2			),		//写入端口2的写入最大地址
    .WR2_LENGTH		( 256				),		//一次性写入数据长度
    .WR2_LOAD		( ~sys_rst_n		),		//写入端口2清零请求，高电平清零写入地址和fifo
    .WR2_CLK		( sdr_wr2_clk		),		//写入端口2 fifo写入时钟
    .WR2_FULL		( 					),		//写入端口2 fifo写满信号
    .WR2_USE		( 					),		//写入端口2 fifo已经写入的数据长度
    //	FIFO Read Side 1
    .RD1_DATA		( sys_data_out1		),		//读出端口1的数据输出端，16bit
    .RD1			( sys_rd1			),		//读出端口1的读使能端，高电平读出
    .RD1_ADDR		( 0					),		//读出端口1的读起始地址
    .RD1_MAX_ADDR	( 640*480			),		//读出端口1的读出最大地址
    .RD1_LENGTH		( 128				),		//一次性读出数据长度
    .RD1_LOAD		( ~sys_rst_n		),		//读出端口1 清零请求，高电平清零读出地址和fifo
    .RD1_CLK		( sdr_rd1_clk		),		//读出端口1 fifo读取时钟
    .RD1_EMPTY		( RD1_EMPTY			),		//读出端口1 fifo读空信号
    .RD1_USE		(					),		//读出端口1 fifo已经还可以读取的数据长度
    //	FIFO Read Side 2
    .RD2_DATA		( sys_data_out2		),		//读出端口2的数据输出端，16bit
    .RD2			( sys_rd2			),		//读出端口2的读使能端，高电平读出
    .RD2_ADDR		( 640*480			),		//读出端口2的读起始地址
    .RD2_MAX_ADDR	( 640*480*2			),		//读出端口2的读出最大地址
    .RD2_LENGTH		( 128				),		//一次性读出数据长度
    .RD2_LOAD		( ~sys_rst_n		),		//读出端口2清零请求，高电平清零读出地址和fifo
    .RD2_CLK		( sdr_rd2_clk		),		//读出端口2 fifo读取时钟
    .RD2_EMPTY		( RD2_EMPTY			),		//读出端口2 fifo读空信号
    .RD2_USE		( 					),		//读出端口2 fifo已经还可以读取的数据长度
    //	SDRAM Side 
     
    .SA				( sdram_addr		),		//SDRAM 地址线，
    .BA				( sdram_ba			),		//SDRAM bank地址线
    .CS_N			( sdram_cs_n		),		//SDRAM 片选信号
    .CKE			( sdram_cke			),		//SDRAM 时钟使能
    .RAS_N			( sdram_ras_n		),		//SDRAM 行选中信号
    .CAS_N			( sdram_cas_n		),		//SDRAM 列选中信号
    .WE_N			( sdram_we_n		),		//SDRAM 写请求信号
    .DQ				( sdram_data		),		//SDRAM 双向数据总线
    .SDR_CLK        ( sdram_clk			),
    .DQM			( sdram_dqm			),		//SDRAM 数据总线高低字节屏蔽信号
    .Sdram_Init_Done( sdram_init_done	)
);

assign sdr_wr1_clk      = cam_pclk;	
assign sdr_wr1_wrdata   = gray_sft[15:8];
assign sdr_wr1_wrreq    = gs_clken ;//gs_clken ;
//sdram read  port1
assign sdr_rd1_clk	= cam_pclk ;	//Change with vga timing	
assign sys_rd1		= sdr_rd ;
//sdram write port2
assign sdr_wr2_clk		= cam_pclk;	//Change with input signal											
assign sdr_wr2_wrdata	= post_img_data ;// {16{post_img_Bit}};//{data_diff,data_diff}; //sys_data_sim for test
assign sdr_wr2_wrreq	= post_frame_clken;//sys_we_sim for test
//sdram read  port2
assign sdr_rd2_clk	= clk_vga;	//Change with vga timing	
assign sys_rd2		= lcd_request;

Video_Image_Process_Moving_Object_Detection #(
    .IMG_HDISP(10'd640),	//640*480
    .IMG_VDISP(10'd480)
) Video_Image_Process_Moving_Object_Detection(
    //global clock
    .clk				( cam_pclk               ),  			//cmos video pixel clock
    .rst_n				( sys_rst_n              ),			//global reset
    .cmos_frame_clken	( cmos_frame_clken    ), 	//Prepared Image data vsync valid signal
    .cmos_frame_vsync	( cmos_frame_vsync ), 		//Prepared Image data href vaild  signal
    .cmos_frame_href	( cmos_frame_href ), 	//Prepared Image data output/capture enable clock
    .cmos_frame_data	( cmos_frame_data         ),			//Prepared Image brightness input
    //Image data has been processd
    .post_frame_vsync	( post_frame_vsync       ),
    .post_frame_href	( post_frame_href        ),		//Processed Image data href vaild  signal
    .post_frame_clken	( post_frame_clken       ),		//Processed Image data output/capture enable clock
    .post_img_data		( post_img_data          ),			//Processed Image brightness output
    .sys_data_out1		( sys_data_out1          ),
    .gs_clken			( gs_clken               ),
    .gray_sft           ( gray_sft               ),
    .sdr_rd             ( sdr_rd                 )
);


//LCD driver timing
VGA_Driver VGA_Driver
(
    //global clock 
    .clk			( clk_vga       ),		
    .rst_n			( sys_rst_n     ), 
    //lcd interface 
    .lcd_dclk		( lcd_dclk      ),
    .lcd_blank		( lcd_blank     ),//lcd_blank
    .lcd_sync		(               ),		    	
    .lcd_hs			( vga_hs        ),		
    .lcd_vs			( vga_vs        ),
    .lcd_en			( lcd_de        ),		
    .lcd_rgb		( vout_data     ),
    //user interface 
    .lcd_request    ( lcd_request   ),
    .lcd_data		( sys_data_out2 ),	
    .lcd_xpos		(               ),	
    .lcd_ypos		(               )
);

assign vga_red   = vout_data[15:11];
assign vga_green = vout_data[10:5];
assign vga_blue  = vout_data[4:0];

endmodule 