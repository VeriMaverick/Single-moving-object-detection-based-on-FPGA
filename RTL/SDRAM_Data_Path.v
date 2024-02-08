module SDRAM_Data_Path #(
        parameter DATA_WIDTH = 16
)(
        CLK,
        RESET_N,
        DATAIN,
        DM,
        DQOUT,
        DQM
        );


`include        "SDRAM_Params.vh"

input                           CLK;                    // System Clock
input                           RESET_N;                // System Reset
input   [DATA_WIDTH-1:0]            DATAIN;                 // Data input from the host
input   [DATA_WIDTH/8-1:0]          DM;                     // byte data masks
output  [DATA_WIDTH-1:0]            DQOUT;
output  [DATA_WIDTH/8-1:0]          DQM;                    // SDRAM data mask ouputs
reg     [DATA_WIDTH/8-1:0]          DQM;
            


// Allign the input and output data to the SDRAM control path
always @(posedge CLK or negedge RESET_N)
begin
        if (RESET_N == 0) 
		DQM		<= DATA_WIDTH/8-1'hF;
        else
 		DQM		<=	DM;                 
end

assign DQOUT = DATAIN;

endmodule

