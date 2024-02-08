// Address Space Parameters
   
`define ROWSIZE		12  
`define COLSTART	0
`define COLSIZE		8
`define BANKSIZE	2
`define ROWSTART    `COLSIZE 
`define BANKSTART   `COLSIZE+`ROWSIZE
// Address and Data Bus Sizes

`define  ASIZE      `ROWSIZE+`COLSIZE+`BANKSIZE     // total address width of the SDRAM
`define  DSIZE      16                              // Width of data bus to SDRAMS

`define	INIT_PER    24000 
`define	REF_PER     1024 
`define	SC_CL       3 
`define	SC_RCD      3 
`define	SC_RRD      7 
`define	SC_PM       1 
`define	SC_BL       1 


//	SDRAM Parameter
`define	SDR_BL		3'b111	
`define	SDR_BT		1'b0	
`define	SDR_CL		3'b11