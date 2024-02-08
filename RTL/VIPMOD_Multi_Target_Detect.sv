module VIPMOD_Multi_Target_Detect #(
    parameter [9:0] IMG_HDISP = 10'd640,
    parameter [9:0] IMG_VDISP = 10'd480 
)(
    input                   clk                     ,
    input                   rst_n                   ,
    input                   per_frame_vsync         ,
    input                   per_frame_hsync         ,
    input                   per_frame_clken         ,
    input                   per_img_bit             ,
    output  logic   [40:0]  target_pos_out [15:0]   ,   // {flag,ymax[39:30],xmax[29:20],ymin[19:10],xmin[9:0]}
    input           [9:0]   min_dist                ,   // 目标间阈值
    input                   disp_sel
);

logic per_frame_vsync_r;
logic per_frame_href_r;
logic per_frame_clken_r;
logic per_img_bit_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        per_frame_vsync_r   <= 1'b0;
        per_frame_href_r    <= 1'b0;
        per_frame_clken_r   <= 1'b0;
        per_img_bit_r       <= 1'b0;
    end else begin
        per_frame_vsync_r   <= per_frame_vsync;
        per_frame_href_r    <= per_frame_hsync;
        per_frame_clken_r   <= per_frame_clken;
        per_img_bit_r       <= per_img_bit;
    end
end 

logic vsync_pos_flag;   // 场同步上升沿
logic vsync_neg_flag;   // 场同步下降沿

assign vsync_pos_flag = (~per_frame_vsync_r) & per_frame_vsync;
assign vsync_neg_flag = per_frame_vsync_r & (~per_frame_vsync);

// 对输入的像素进行 行/场 方向计数，得到其纵横坐标
logic [9:0] x_cnt;
logic [9:0] y_cnt;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        x_cnt <= 10'd0;
        y_cnt <= 10'd0;
    end else if(per_frame_vsync) begin
        x_cnt <= 10'd0;
        y_cnt <= 10'd0;
    end else if(per_frame_clken) begin
        if(x_cnt < IMG_HDISP-1'b1) begin
            x_cnt <= x_cnt + 1'b1;
            y_cnt <= y_cnt;
        end else begin
            x_cnt <= 10'd0;
            y_cnt <= y_cnt + 1'b1;
        end
    end else begin
        x_cnt <= x_cnt;
        y_cnt <= y_cnt;
    end
end

// 寄存坐标
logic [9:0] x_cnt_r;
logic [9:0] y_cnt_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        x_cnt_r <= 10'd0;
        y_cnt_r <= 10'd0;
    end else begin
        x_cnt_r <= x_cnt;
        y_cnt_r <= y_cnt;
    end 
end 

logic [40:0] target_pos [15:0];  // 寄存各个目标的边界

logic [15:0] target_flag;   // 目标有效标志位
logic [9:0]  target_left;   // 目标左边界
logic [9:0]  target_right;  // 目标右边界
logic [9:0]  target_top;    // 目标上边界
logic [9:0]  target_bottom; // 目标下边界

logic [9:0]  target_boarder_left    [15:0];     // 目标左边界
logic [9:0]  target_boarder_right   [15:0];     // 目标右边界
logic [9:0]  target_boarder_top     [15:0];     // 目标上边界
logic [9:0]  target_boarder_bottom  [15:0];     // 目标下边界

generate
    genvar i;
    for(i=0; i<16; i=i+1) begin: voluation
        assign target_flag[i] = target_pos[i][40];
        
        assign target_bottom[i] =( target_pos[i][39:30] < IMG_VDISP-1'b1-min_dist ) ? (target_pos[i][39:30] + min_dist) : IMG_VDISP-1'b1;
        assign target_right[i]  =( target_pos[i][29:20] < IMG_HDISP-1'b1-min_dist ) ? (target_pos[i][29:20] + min_dist) : IMG_HDISP-1'b1;
        assign target_top[i]    =( target_pos[i][19:10] > 10'd0         +min_dist ) ? (target_pos[i][19:10] - min_dist) : 10'd0;
        assign target_left[i]   =( target_pos[i][9:0]   > 10'd0         +min_dist ) ? (target_pos[i][9:0]   - min_dist) : 10'd0;

        assign target_boarder_bottom[i] = target_pos[i][39:30];//下边界像素坐标
        assign target_boarder_right[i]  = target_pos[i][29:20];//右边界像素坐标
        assign target_boarder_top[i]    = target_pos[i][19:10];//上边界像素坐标
        assign target_boarder_left[i]   = target_pos[i][9:0];  //左边界像素坐标
    end
endgenerate

// 检测并标记目标 需要两个像素时钟
integer j;

logic [3:0] target_cnt;
logic [15:0] new_target_flag;   // 检测新目标的投票计数

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        // 初始化各个目标的边界 0
        for(j=0; j<16; j=j+1) begin
            target_pos[j] <= {1'b0, 10'd0, 10'd0, 10'd0, 10'd0};
        end
        new_target_flag <= 16'b0;
        target_cnt <= 4'd0;
    end else if(vsync_neg_flag) begin // 在一帧开始进行初始化
        for(j=0; j<16; j=j+1) begin
            target_pos[j] <= {1'b0, 10'd0, 10'd0, 10'd0, 10'd0};
        end
        new_target_flag <= 16'b0;
        target_cnt <= 4'd0;
    // 第一个时钟周期，找出标记为运动目标的像素点，由运动目标列表中的元素进行投票，判断是否为新的运动目标
    end else if(per_frame_clken && per_img_bit) begin
        for(j=0; j<16; j=j+1) begin 
            if(target_flag[j] == 1'b0) begin        // 运动目标列表中的数据元素无效，则该元素投票认定输入的灰度为新的最大值
                new_target_flag[j] <= 1'b1;
            end else begin                          // 运动目标列表中的数据元素有效，则判断当前像素是否落在该元素临域里
                if( (x_cnt < target_left[j]) || (x_cnt > target_right[j]) || (y_cnt < target_top[j]) || (y_cnt > target_bottom[j]) ) begin
                    new_target_flag[j] <= 1'b1;     // 如果坐标距离超出目标临域范围，投票认定为新的目标
                end else begin
                    new_target_flag[j] <= 1'b0;     // 否则不认定为新的目标
                end
            end
        end
    end else begin
        new_target_flag <= 16'b0;                   // 其他时刻，不进行新目标检测   
    end

    // 第二个时钟周期，根据投票结果，将候选数据更新到运动目标列表中
    if(per_frame_clken_r && per_img_bit_r) begin
        if(new_target_flag == 16'hffff) begin       // 全票通过，标志出现新的运动目标
            target_pos[target_cnt] <= {1'b1, y_cnt_r, x_cnt_r, y_cnt_r, x_cnt_r};
            target_cnt <= target_cnt + 1'b1;
        end else if(new_target_flag > 16'd0) begin  // 出现被标记为运动目标的像素点，但是落在运动目标某个元素的临域内
            for(j=0; j<16; j=j+1) begin             // 遍历运动目标列表，扩展其中各元素的临域范围
                if(new_target_flag[j] == 1'b0) begin // 未投票认定为新目标的元素，表示当前像素位于它的临域内
                    target_pos[j][40] <= 1'b1;  
                    if(x_cnt_r < target_pos[j][9:0])    // 若X坐标小于左边界，则将其X坐标扩展为左边界
                        target_pos[j][9:0] <= x_cnt_r;

                    if(x_cnt_r > target_pos[j][29:20])   // 若X坐标大于右边界，则将其X坐标扩展为右边界
                        target_pos[j][29:20] <= x_cnt_r;
                    
                    if(y_cnt_r < target_pos[j][19:10])   // 若Y坐标小于上边界，则将其Y坐标扩展为上边界
                        target_pos[j][19:10] <= y_cnt_r;

                    if(y_cnt_r > target_pos[j][39:30])   // 若Y坐标大于下边界，则将其Y坐标扩展为下边界
                        target_pos[j][39:30] <= y_cnt_r;
                end
            end
        end
    end
end

assign target_pos_out = target_pos;


                    
                 
                

endmodule 