module Diff_Frame #(
    parameter  THRESHOLD = 8'd20
)(
    //globol clock
    input           clk,
    input           rst_n,
    //synced signal
    input   [7:0]   data_cur ,      //当前帧
    input   [7:0]   data_next,      //下一帧

    //Image data prepred to be processd
    input				per_frame_vsync,	//Prepared Image data vsync valid signal
    input				per_frame_href,		//Prepared Image data href vaild  signal
    input				per_frame_clken,	//Prepared Image data output/capture enable clock
    input				per_img_Bit,		//Prepared Image Bit flag outout(1: Value, 0:inValid)
    
    //Image data has been processd
    output			post_frame_vsync,	//Processed Image data vsync valid signal
    output			post_frame_href,	//Processed Image data href vaild  signal
    output			post_frame_clken,	//Processed Image data output/capture enable clock
    output   [7:0] post_img_Bit		//Processed Image Bit flag outout(1: Value, 0:inValid)
); 

reg  [7:0] data_diff;
wire [7:0] data;
assign data = (data_next>data_cur)?((data_next-data_cur > THRESHOLD)? 8'd255 :8'd0):((data_next==data_cur)? 8'd0: ((data_cur-data_next > THRESHOLD)? 8'd255 :8'd0));

always@(posedge clk or negedge rst_n)
if(!rst_n) 
   data_diff<= 8'd0;		
else begin 
   data_diff<= data;
end 

reg per_frame_vsync_r;
reg per_frame_href_r ;
reg per_frame_clken_r;

always@(posedge clk or negedge rst_n)
if(!rst_n) begin
  per_frame_vsync_r <= 1'b0;
  per_frame_href_r  <= 1'b0; 
  per_frame_clken_r <= 1'b0;
 end 
else begin
  per_frame_vsync_r <= per_frame_vsync;
  per_frame_href_r  <= per_frame_href ; 
  per_frame_clken_r <= per_frame_clken;
end  


assign post_frame_vsync	= per_frame_vsync_r ;
assign post_frame_href	= per_frame_href_r  ;
assign post_frame_clken	= per_frame_clken_r ;
assign post_img_Bit     = data_diff         ;
        
endmodule

