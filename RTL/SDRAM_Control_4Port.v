`include        "SDRAM_Params.vh"
module SDRAM_Control_4Port #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 20
)(
    //	HOST Side
    input                           REF_CLK,	// 系统时钟  100MHz
    input		                    OUT_CLK,	// 输出时钟  100MHz clock phase shift  -135deg
    input		                    RESET_N,	// 复位信号
    //	FIFO Write Side 1   
    input       [DATA_WIDTH-1:0]    WR1_DATA,               //Data input
    input                           WR1,					//Write Request
    input       [ADDR_WIDTH-1:0]    WR1_ADDR,				//Write start address
    input       [ADDR_WIDTH-1:0]    WR1_MAX_ADDR,			//Write max address
    input	    [8:0]               WR1_LENGTH,				//Write length
    input                           WR1_LOAD,				//Write register load & fifo clear
    input                           WR1_CLK,				//Write fifo clock
    output                          WR1_FULL,				//Write fifo full
    output	    [15:0]              WR1_USE,				//Write fifo usedw
    //	FIFO Write Side 2   
    input       [DATA_WIDTH-1:0]    WR2_DATA,               //Data input
    input				            WR2,					//Write Request
    input	    [ADDR_WIDTH-1:0]    WR2_ADDR,				//Write start address
    input	    [ADDR_WIDTH-1:0]    WR2_MAX_ADDR,			//Write max address
    input	    [8:0]               WR2_LENGTH,				//Write length
    input				            WR2_LOAD,				//Write register load & fifo clear
    input				            WR2_CLK,				//Write fifo clock
    output				            WR2_FULL,				//Write fifo full
    output	    [15:0]              WR2_USE,				//Write fifo usedw
    //	FIFO Read Side 1        
    output      [DATA_WIDTH-1:0]    RD1_DATA,               //Data output
    input				            RD1,					//Read Request
    input	    [ADDR_WIDTH-1:0]    RD1_ADDR,				//Read start address
    input	    [ADDR_WIDTH-1:0]    RD1_MAX_ADDR,			//Read max address
    input       [8:0]               RD1_LENGTH,				//Read length
    input				            RD1_LOAD,				//Read register load & fifo clear
    input				            RD1_CLK,				//Read fifo clock
    output				            RD1_EMPTY,				//Read fifo empty
    output	    [15:0]              RD1_USE,				//Read fifo usedw
    //	FIFO Read Side 2        
    output      [DATA_WIDTH-1:0]    RD2_DATA,               //Data output
    input				            RD2,					//Read Request
    input	    [ADDR_WIDTH-1:0]    RD2_ADDR,				//Read start address
    input	    [ADDR_WIDTH-1:0]    RD2_MAX_ADDR,			//Read max address
    input	    [8:0]               RD2_LENGTH,				//Read length
    input				            RD2_LOAD,				//Read register load & fifo clear
    input				            RD2_CLK,				//Read fifo clock
    output				            RD2_EMPTY,				//Read fifo empty
    output	    [15:0]              RD2_USE,				//Read fifo usedw
    //	SDRAM Side
    output  reg [11:0]              SA,                     //SDRAM address output
    output  reg [1:0]               BA,                     //SDRAM bank address
    output  reg [1:0]               CS_N,                   //SDRAM Chip Selects
    output  reg                     CKE,                    //SDRAM clock enable
    output  reg                     RAS_N,                  //SDRAM Row address Strobe
    output  reg                     CAS_N,                  //SDRAM Column address Strobe
    output  reg                     WE_N,                   //SDRAM write enable
    inout       [DATA_WIDTH-1:0]    DQ,                     //SDRAM data bus
    output  reg [DATA_WIDTH/8-1:0]  DQM,                    //SDRAM data mask lines
    output                          SDR_CLK,				//SDRAM clock
    output                          Sdram_Init_Done
    );


wire CLK;
assign SDR_CLK=OUT_CLK;
assign CLK=REF_CLK;

//	Internal Registers/Wires
//	Controller
reg     [ADDR_WIDTH-1:0]    mADDR;					//Internal address
reg     [8:0]               mLENGTH;				//Internal length
reg     [ADDR_WIDTH-1:0]    rWR1_ADDR;				//Register write address				
reg     [ADDR_WIDTH-1:0]    rWR1_MAX_ADDR;			//Register max write address				
reg     [8:0]               rWR1_LENGTH;			//Register write length
reg     [ADDR_WIDTH-1:0]    rWR2_ADDR;				//Register write address				
reg     [ADDR_WIDTH-1:0]    rWR2_MAX_ADDR;			//Register max write address				
reg     [8:0]               rWR2_LENGTH;			//Register write length
reg     [ADDR_WIDTH-1:0]    rRD1_ADDR;				//Register read address
reg     [ADDR_WIDTH-1:0]    rRD1_MAX_ADDR;			//Register max read address
reg     [8:0]               rRD1_LENGTH;			//Register read length
reg     [ADDR_WIDTH-1:0]    rRD2_ADDR;				//Register read address
reg     [ADDR_WIDTH-1:0]    rRD2_MAX_ADDR;			//Register max read address
reg     [8:0]               rRD2_LENGTH;			//Register read length
reg     [1:0]               WR_MASK;				//Write port active mask
reg     [1:0]               RD_MASK;				//Read port active mask
reg			                mWR_DONE;				//Flag write done, 1 pulse SDR_CLK
reg			                mRD_DONE;				//Flag read done, 1 pulse SDR_CLK
reg			                mWR,Pre_WR;				//Internal WR edge capture
reg			                mRD,Pre_RD;				//Internal RD edge capture
reg     [9:0]               ST;						//Controller status
reg     [1:0]               CMD;					//Controller command
reg			                PM_STOP;				//Flag page mode stop
reg			                PM_DONE;				//Flag page mode done
reg			                Read;					//Flag read active
reg			                Write;					//Flag write active
reg     [DATA_WIDTH-1:0]    mDATAOUT;               //Controller Data output
wire    [DATA_WIDTH-1:0]    mDATAIN;                //Controller Data input
wire    [DATA_WIDTH-1:0]    mDATAIN1;                //Controller Data input 1
wire    [DATA_WIDTH-1:0]    mDATAIN2;                //Controller Data input 2
wire                        CMDACK;                 //Controller command acknowledgement
//	DRAM Control
wire    [DATA_WIDTH-1:0]    DQOUT;					//SDRAM data out link
wire  	[DATA_WIDTH/8-1:0]  IDQM;                   //SDRAM data mask lines
wire    [11:0]              ISA;                    //SDRAM address output
wire    [1:0]               IBA;                    //SDRAM bank address
wire    [1:0]               ICS_N;                  //SDRAM Chip Selects
wire                        ICKE;                   //SDRAM clock enable
wire                        IRAS_N;                 //SDRAM Row address Strobe
wire                        ICAS_N;                 //SDRAM Column address Strobe
wire                        IWE_N;                  //SDRAM write enable
//	FIFO Control
reg						    OUT_VALID;				//Output data request to read side fifo
reg						    IN_REQ;					//Input	data request to write side fifo
wire	[15:0]			    write_side_fifo_rusedw1;
wire	[15:0]			    read_side_fifo_wusedw1;
wire	[15:0]			    write_side_fifo_rusedw2;
wire	[15:0]			    read_side_fifo_wusedw2;
//	DRAM Internal Control   
wire    [ADDR_WIDTH-1:0]    saddr;
wire                        load_mode;
wire                        nop;
wire                        reada;
wire                        writea;
wire                        refresh;
wire                        precharge;
wire                        oe;
wire					    ref_ack;
wire					    ref_req;
wire					    init_req;
wire					    cm_ack;
wire					    active;


Control_Interface Control_Interface (
    .CLK                (CLK),
    .RESET_N            (RESET_N),
    .CMD                (CMD),
    .ADDR               (mADDR),
    .REF_ACK            (ref_ack),
    .CM_ACK             (cm_ack),
    .NOP                (nop),
    .READA              (reada),
    .WRITEA             (writea),
    .REFRESH            (refresh),
    .PRECHARGE          (precharge),
    .LOAD_MODE          (load_mode),
    .SADDR              (saddr),
    .REF_REQ            (ref_req),
    .INIT_REQ           (init_req),
    .CMD_ACK            (CMDACK),
    .Sdram_Init_Done    (Sdram_Init_Done)
);

Command Command(
                .CLK(CLK),
                .RESET_N(RESET_N),
                .SADDR(saddr),
                .NOP(nop),
                .READA(reada),
                .WRITEA(writea),
                .REFRESH(refresh),
                .LOAD_MODE(load_mode),
                .PRECHARGE(precharge),
                .REF_REQ(ref_req),
                .INIT_REQ(init_req),
                .REF_ACK(ref_ack),
                .CM_ACK(cm_ack),
                .OE(oe),
                .PM_STOP(PM_STOP),
                .PM_DONE(PM_DONE),
                .SA(ISA),
                .BA(IBA),
                .CS_N(ICS_N),
                .CKE(ICKE),
                .RAS_N(IRAS_N),
                .CAS_N(ICAS_N),
                .WE_N(IWE_N)
                );
                
SDRAM_Data_Path SDRAM_Data_Path(
                .CLK(CLK),
                .RESET_N(RESET_N),
                .DATAIN(mDATAIN),
                .DM(2'b00),
                .DQOUT(DQOUT),
                .DQM(IDQM)
                );

SDRAM_RD_FIFO 	Write_FIFO_0(
                .data(WR1_DATA),
                .wrreq(WR1),
                .wrclk(WR1_CLK),
                .aclr(WR1_LOAD),
                .rdreq(IN_REQ&WR_MASK[0]),
                .rdclk(CLK),
                .q(mDATAIN1),
                .wrfull(WR1_FULL),
                .wrusedw(WR1_USE),
                .rdusedw(write_side_fifo_rusedw1)
                );

SDRAM_WR_FIFO 	Write_FIFO_1(
                .data(WR2_DATA),
                .wrreq(WR2),
                .wrclk(WR2_CLK),
                .aclr(WR2_LOAD),
                .rdreq(IN_REQ&WR_MASK[1]),
                .rdclk(CLK),
                .q(mDATAIN2),
                .wrfull(WR2_FULL),
                .wrusedw(WR2_USE),
                .rdusedw(write_side_fifo_rusedw2)
                );
                
assign	mDATAIN	=	(WR_MASK[0])	?	mDATAIN1	:
                                        mDATAIN2	;

SDRAM_RD_FIFO 	Read_FIFO_0(
                .data(mDATAOUT),
                .wrreq(OUT_VALID&RD_MASK[0]),
                .wrclk(CLK),
                .aclr(RD1_LOAD),
                .rdreq(RD1),
                .rdclk(RD1_CLK),
                .q(RD1_DATA),
                .wrusedw(read_side_fifo_wusedw1),
                .rdempty(RD1_EMPTY),
                .rdusedw(RD1_USE)
                );
                
SDRAM_RD_FIFO 	Read_FIFO_1(
                .data(mDATAOUT),
                .wrreq(OUT_VALID&RD_MASK[1]),
                .wrclk(CLK),
                .aclr(RD2_LOAD),
                .rdreq(RD2),
                .rdclk(RD2_CLK),
                .q(RD2_DATA),
                .wrusedw(read_side_fifo_wusedw2),
                .rdempty(RD2_EMPTY),
                .rdusedw(RD2_USE)
                );

always @(posedge CLK)
begin
    SA      <= (ST==`SC_CL+mLENGTH)			?	12'h200	:	ISA;
    BA      <= IBA;
    CS_N    <= ICS_N;
    CKE     <= ICKE;
    RAS_N   <= (ST==`SC_CL+mLENGTH)			?	1'b0	:	IRAS_N;
    CAS_N   <= (ST==`SC_CL+mLENGTH)			?	1'b1	:	ICAS_N;
    WE_N    <= (ST==`SC_CL+mLENGTH)			?	1'b0	:	IWE_N;
    PM_STOP	<= (ST==`SC_CL+mLENGTH)			?	1'b1	:	1'b0;
    PM_DONE	<= (ST==`SC_CL+`SC_RCD+mLENGTH+2)	?	1'b1	:	1'b0;
    DQM	   <= {(DATA_WIDTH/8){1'b0}}; //( active && (ST>=SC_CL) )	?	(	((ST==SC_CL+mLENGTH) && Write)?	2'b11	:	2'b00	)	:	2'b11	;
    mDATAOUT<= DQ;
end

assign  DQ = oe ? DQOUT : {DATA_WIDTH{1'bz}}; // tri-state control
assign	active	=	Read | Write;

always@(posedge CLK or negedge RESET_N)
begin
    if(RESET_N==0)
    begin
        CMD			<=  0;
        ST			<=  0;
        Pre_RD		<=  0;
        Pre_WR		<=  0;
        Read		<=	0;
        Write		<=	0;
        OUT_VALID	<=	0;
        IN_REQ		<=	0;
        mWR_DONE	<=	0;
        mRD_DONE	<=	0;
    end
    else
    begin
        Pre_RD	<=	mRD;
        Pre_WR	<=	mWR;
        case(ST)
        0:	begin
                if({Pre_RD,mRD}==2'b01)
                begin
                    Read	<=	1;
                    Write	<=	0;
                    CMD		<=	2'b01;
                    ST		<=	1;
                end
                else if({Pre_WR,mWR}==2'b01)
                begin
                    Read	<=	0;
                    Write	<=	1;
                    CMD		<=	2'b10;
                    ST		<=	1;
                end
            end
        1:	begin
                if(CMDACK==1)
                begin
                    CMD<=2'b00;
                    ST<=2;
                end
            end
        default:	
            begin	
                if(ST!=`SC_CL+`SC_RCD+mLENGTH+1)
                ST<=ST+1;
                else
                ST<=0;
            end
        endcase
    
        if(Read)
        begin
            if(ST==`SC_CL+`SC_RCD+1)
            OUT_VALID	<=	1;
            else if(ST==`SC_CL+`SC_RCD+mLENGTH+1)
            begin
                OUT_VALID	<=	0;
                Read		<=	0;
                mRD_DONE	<=	1;
            end
        end
        else
        mRD_DONE	<=	0;
        
        if(Write)
        begin
            if(ST==`SC_CL-1)
            IN_REQ	<=	1;
            else if(ST==`SC_CL+mLENGTH-1)
            IN_REQ	<=	0;
            else if(ST==`SC_CL+`SC_RCD+mLENGTH)
            begin
                Write	<=	0;
                mWR_DONE<=	1;
            end
        end
        else
        mWR_DONE<=	0;

    end
end
//	Internal Address & Length Control
always@(posedge CLK or negedge RESET_N)
begin
    if(!RESET_N)
    begin
        rWR1_ADDR		<=	WR1_ADDR;
        rWR1_MAX_ADDR	<=	WR1_MAX_ADDR;
        rWR2_ADDR		<=	WR2_ADDR;
        rWR2_MAX_ADDR	<=	WR2_MAX_ADDR;
        rRD1_ADDR		<=	RD1_ADDR;
        rRD1_MAX_ADDR	<=	RD1_MAX_ADDR;
        rRD2_ADDR		<=	RD2_ADDR;
        rRD2_MAX_ADDR	<=	RD2_MAX_ADDR;
        rWR1_LENGTH		<=WR1_LENGTH;
        rRD1_LENGTH		<=RD1_LENGTH;
        rWR2_LENGTH		<=WR2_LENGTH;
        rRD2_LENGTH		<=RD2_LENGTH;
    end
    else
    begin
        //	Write Side 1
        if(WR1_LOAD)
        begin
            rWR1_ADDR	<=	WR1_ADDR;
            rWR1_LENGTH	<=	WR1_LENGTH;
        end
        else if(mWR_DONE&WR_MASK[0])
        begin
            if(rWR1_ADDR<rWR1_MAX_ADDR-rWR1_LENGTH)
            rWR1_ADDR	<=	rWR1_ADDR+rWR1_LENGTH;
            else
            rWR1_ADDR	<=	WR1_ADDR;
        end
        //	Write Side 2
        if(WR2_LOAD)
        begin
            rWR2_ADDR	<=	WR2_ADDR;
            rWR2_LENGTH	<=	WR2_LENGTH;
        end
        else if(mWR_DONE&WR_MASK[1])
        begin
            if(rWR2_ADDR<rWR2_MAX_ADDR-rWR2_LENGTH)
            rWR2_ADDR	<=	rWR2_ADDR+rWR2_LENGTH;
            else
            rWR2_ADDR	<=	WR2_ADDR;
        end
        //	Read Side 1
        if(RD1_LOAD)
        begin
            rRD1_ADDR	<=	RD1_ADDR;
            rRD1_LENGTH	<=	RD1_LENGTH;
        end
        else if(mRD_DONE&RD_MASK[0])
        begin
            if(rRD1_ADDR<rRD1_MAX_ADDR-rRD1_LENGTH)
            rRD1_ADDR	<=	rRD1_ADDR+rRD1_LENGTH;
            else
            rRD1_ADDR	<=	RD1_ADDR;
        end
        //	Read Side 2
        if(RD2_LOAD)
        begin
            rRD2_ADDR	<=	RD2_ADDR;
            rRD2_LENGTH	<=	RD2_LENGTH;
        end
        else if(mRD_DONE&RD_MASK[1])
        begin
            if(rRD2_ADDR<rRD2_MAX_ADDR-rRD2_LENGTH)
            rRD2_ADDR	<=	rRD2_ADDR+rRD2_LENGTH;
            else
            rRD2_ADDR	<=	RD2_ADDR;
        end
    end
end
//	Auto Read/Write Control
always@(posedge CLK or negedge RESET_N)
begin
    if(!RESET_N)
    begin
        mWR		<=	0;
        mRD		<=	0;
        mADDR	<=	0;
        mLENGTH	<=	0;
    end
    else
    begin
        if( (mWR==0) && (mRD==0) && (ST==0) &&
            (WR_MASK==0)	&&	(RD_MASK==0) &&
            (WR1_LOAD==0)	&&	(RD1_LOAD==0) &&
            (WR2_LOAD==0)	&&	(RD2_LOAD==0) )
        begin
            //	Read Side 1
            if( (read_side_fifo_wusedw1 < rRD1_LENGTH) )
            begin
                mADDR	<=	rRD1_ADDR;
                mLENGTH	<=	rRD1_LENGTH;
                WR_MASK	<=	2'b00;
                RD_MASK	<=	2'b01;
                mWR		<=	0;
                mRD		<=	1;				
            end
            //	Read Side 2
            else if( (read_side_fifo_wusedw2 < rRD2_LENGTH) )
            begin
                mADDR	<=	rRD2_ADDR;
                mLENGTH	<=	rRD2_LENGTH;
                WR_MASK	<=	2'b00;
                RD_MASK	<=	2'b10;
                mWR		<=	0;
                mRD		<=	1;
            end
            //	Write Side 1
            else if( (write_side_fifo_rusedw1 >= rWR1_LENGTH) && (rWR1_LENGTH!=0) )
            begin
                mADDR	<=	rWR1_ADDR;
                mLENGTH	<=	rWR1_LENGTH;
                WR_MASK	<=	2'b01;
                RD_MASK	<=	2'b00;
                mWR		<=	1;
                mRD		<=	0;
            end
            //	Write Side 2
            else if( (write_side_fifo_rusedw2 >= rWR2_LENGTH) && (rWR2_LENGTH!=0) )
            begin
                mADDR	<=	rWR2_ADDR;
                mLENGTH	<=	rWR2_LENGTH;
                WR_MASK	<=	2'b10;
                RD_MASK	<=	2'b00;
                mWR		<=	1;
                mRD		<=	0;
            end
        end
        if(mWR_DONE)
        begin
            WR_MASK	<=	0;
            mWR		<=	0;
        end
        if(mRD_DONE)
        begin
            RD_MASK	<=	0;
            mRD		<=	0;
        end
    end
end

endmodule
