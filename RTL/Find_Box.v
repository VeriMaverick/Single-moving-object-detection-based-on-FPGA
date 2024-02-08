//Last update: 2024/02/06 22:14

module Find_Box #(
    parameter	[10:0]	IMG_Width = 11'd640,	//640*480
    parameter	[10:0]	IMG_High  = 11'd480
)(
    //global clock
    input			clk,  				//cmos video pixel clock
    input			rst_n,				//global reset
    //Image data prepred to be processd
    input			per_frame_vsync,	// 准备图像数据场有效信号
    input			per_frame_href,		// 准备图像数据行有效信号
    input			per_frame_clken,	// 准备图像数据输出/捕获使能时钟
    input			per_img_Y,			// 准备图像数据输入 灰度值
    input          	cmos_frame_clken,	// CMOS 时钟使能信号               
    input			cmos_frame_vsync,	// CMOS 帧有效信号
    input          	cmos_frame_href,	// CMOS 行有效信号    
    input	[15:0]	cmos_frame_data,    // CMOS 数据输入
    
    //Image data has been processd
    output			post_frame_vsync,	//Processed Image data vsync valid signal
    output			post_frame_href,	//Processed Image data href vaild  signal
    output			post_frame_clken,	//Processed Image data output/capture enable clock
    output	[15:0]  post_img_Y			//Processed Image brightness output
);

reg [9:0] edg_up	;		// = 160;
reg [9:0] edg_down	;		// = 240;
reg	[9:0] edg_left	;		// = 160;
reg	[9:0] edg_right ;		// = 240;
reg [9:0] edg_up_d1     ;
reg	[9:0] edg_down_d1   ;
reg	[9:0] edg_left_d1   ;
reg	[9:0] edg_right_d1  ;
reg per_frame_href_r    	;	// 准备图像数据行有效信号
reg per_frame_vsync_r   	;	// 准备图像数据场有效信号
reg per_frame_clken_r		;	// 准备图像数据输出/捕获使能时钟
reg per_img_data_r			;	// 准备图像数据输入
reg [9:0]	h_cnt			;	// 水平计数
reg [9:0]	v_cnt			;	// 垂直计数
reg [15:0]	post_cmos_data	;	// 处理后的CMOS数据
reg cmos_frame_clken_r;	               
reg cmos_frame_vsync_r;	
reg cmos_frame_href_r;

wire valid_en = 1'b1;		// 有效使能信号
wire href_falling;			// 行有效下降沿
wire vsync_rising;			// 场有效上升沿
wire vsync_falling;			// 场有效下降沿

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
           per_frame_href_r	<= 1'd0;
           per_frame_vsync_r	<= 1'd0;
        per_frame_clken_r 	<= 1'b0;
           per_img_data_r 		<= 1'd0;
       end else begin
           per_frame_href_r	<= per_frame_href; 
           per_frame_vsync_r	<= per_frame_vsync; 
           per_img_data_r 		<= per_img_Y;
        per_frame_clken_r 	<= per_frame_clken;
     end
end 
 
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cmos_frame_href_r  <= 1'd0;
        cmos_frame_vsync_r <= 1'd0;
        cmos_frame_clken_r <= 1'b0;
    end else begin
        cmos_frame_href_r  <= cmos_frame_href;
        cmos_frame_vsync_r <= cmos_frame_vsync;
        cmos_frame_clken_r <= cmos_frame_clken;
    end 
end

// href counter
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        h_cnt <=10'd0;
    end else if(per_frame_href)begin
        if(per_frame_clken) begin
            h_cnt <=h_cnt+1'b1;
        end else begin
            h_cnt <=h_cnt;
        end 
    end else begin
        h_cnt <=10'd0;
    end 
end

// vsync counter
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        v_cnt <=10'd0;
    end else if(per_frame_vsync)begin 
        if(href_falling) begin
            v_cnt <=v_cnt+1'b1;
        end else begin
            v_cnt <=v_cnt;
        end 
    end else begin
        v_cnt <=10'd0;
    end
end
 

// 
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        edg_up    <=  10'd479;
        edg_down  <=  10'd0;
        edg_left  <=  10'd639;
        edg_right <=  10'd0;
    end else if(vsync_rising) begin
        edg_up    <=  10'd479;
        edg_down  <=  10'd0;
        edg_left  <=  10'd639;
        edg_right <=  10'd0;
    end else if(per_frame_clken & per_frame_href) begin
        if(per_img_Y == 1'b1) begin
            if(edg_up > v_cnt) begin
                edg_up  <=v_cnt ;
            end else begin
                edg_up  <=edg_up ;	
            end

            if(edg_down < v_cnt) begin
                edg_down  <=v_cnt ;
            end else begin
                edg_down  <= edg_down ;	
            end
             
            if(edg_left > h_cnt) begin
                edg_left  <= h_cnt ;
            end else begin
                edg_left  <= edg_left ;	
            end

            if(edg_right < h_cnt) begin
                edg_right  <=h_cnt ;
            end else begin
                edg_right  <=edg_right ;
            end			 
        end else begin
            edg_up    <=  edg_up;
            edg_down  <=  edg_down;
            edg_left  <=  edg_left;
            edg_right <=  edg_right;
        end
    end
end 
 
always@(posedge clk or negedge rst_n)
begin 
   if(!rst_n) begin
      edg_up_d1    <=  10'd160;
      edg_down_d1  <=  10'd240;
      edg_left_d1  <=  10'd160;
      edg_right_d1 <=  10'd240;
     end
     else if(vsync_falling) begin
       edg_up_d1    <=  edg_up   ;
      edg_down_d1  <=  edg_down ;
      edg_left_d1  <=  edg_left ;
      edg_right_d1 <=  edg_right;
    end
end 
 
always@(posedge  clk or negedge rst_n) begin
    if(~rst_n) begin
        post_cmos_data <= 16'd0; 
    end else if(cmos_frame_vsync) begin 
        if(~(cmos_frame_href & cmos_frame_clken)) begin
            post_cmos_data <= 16'd0;
        end else if(valid_en &&
          ((((( h_cnt >=edg_left_d1)&&(h_cnt <=edg_left_d1+2))||(( h_cnt >=edg_right_d1))&&(h_cnt <=edg_right_d1+2)))&&(v_cnt >=edg_up_d1 && v_cnt <= edg_down_d1))
         ||(((( v_cnt >=edg_up_d1)&&(v_cnt <=edg_up_d1+2))||(( v_cnt >=edg_down_d1)&&(v_cnt <=edg_down_d1+2)))&&(h_cnt >= edg_left_d1 && h_cnt <= edg_right_d1))) begin
            post_cmos_data <={5'b11111,6'd0,5'd0};
        end else if(h_cnt >= 318 && h_cnt <= 320 && v_cnt >= 238 && v_cnt <= 240) begin
            // Set the pixel color to red at the center of the screen
            post_cmos_data <= {5'b11111,6'd0,5'd0};
        end else begin
            post_cmos_data <= cmos_frame_data;
        end 
        
    end else begin
        post_cmos_data <= post_cmos_data;
    end       
end

assign     vsync_rising    =(~per_frame_vsync_r) & per_frame_vsync ?1'b1:1'b0;
assign     vsync_falling   = per_frame_vsync_r & (~per_frame_vsync)? 1'b1:1'b0;
assign     href_falling    = per_frame_href_r & (~per_frame_href)?1'b1:1'b0;

assign post_frame_vsync  = cmos_frame_vsync_r;
assign post_frame_href   = cmos_frame_href_r;
assign post_frame_clken  = cmos_frame_clken_r;

assign post_img_Y =post_cmos_data;

endmodule