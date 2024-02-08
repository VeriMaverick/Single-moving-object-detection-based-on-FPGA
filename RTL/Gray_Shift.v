module Gray_Shift( 
    input               clk     , 
    input               rst_n   , 
    input               clken   , 
    input               ivsync  , 
    input               ihsync  , 
    input       [7:0]   graya   ,   // next frame
    input       [7:0]   grayb   ,   // before frame
    output              sdr_rd  ,   //延时一帧的使能信号
    output      [15:0]  ogray   ,   //延时一帧的灰度信号
    output  reg         ovsync  ,
    output  reg         ohsync  ,
    output              oclken             
) ; 
 
always@(posedge clk or negedge rst_n) begin 
    if ( !rst_n) 
        ovsync <= 1'b0; 
    else 
        ovsync <=  ivsync; 
end 
 
always@(posedge clk or negedge rst_n) begin 
    if ( !rst_n) 
        ohsync <= 1'b0; 
    else 
        ohsync <= ihsync; 
end 


reg clken_d0; 
always@(posedge clk or negedge rst_n) begin 
    if ( !rst_n) 
        clken_d0 <= 1'b0; 
    else 
        clken_d0 <= clken; 
end 

reg rd_en; 
always@(posedge clk or negedge rst_n) begin 
    if ( !rst_n) 
        rd_en <= 1'b0; 
    else if(~ivsync & ovsync) 
        rd_en <= 1'b1; 
end 
 
assign sdr_rd = rd_en & clken; 
reg [ 7:0] graya_d0; 
always@(posedge clk or negedge rst_n) begin 
    if ( !rst_n) 
        graya_d0 <= 1'b0; 
    else 
        graya_d0 <= graya; 
end 

assign oclken = clken_d0  ;
assign ogray  = {graya_d0, grayb} ;

endmodule 		  