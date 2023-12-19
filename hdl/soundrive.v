//-------------------------------------------------------------------------------------------------
module soundrive
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      ce,

	input  wire      reset,
	input  wire      iorq,
	input  wire      wr,
	input  wire[7:0] d,
	input  wire[7:0] a,

	output reg [7:0] l1,
	output reg [7:0] l2,
	output reg [7:0] r1,
	output reg [7:0] r2
);
//-------------------------------------------------------------------------------------------------

always @(posedge clock, negedge reset)
	if(!reset) l1 <= 1'd0;
	else if(ce) if(!iorq && !wr && a == 8'h0F) l1 <= d;

always @(posedge clock, negedge reset)
	if(!reset) l2 <= 1'd0;
	else if(ce) if(!iorq && !wr && a == 8'h1F) l2 <= d;

always @(posedge clock, negedge reset)
	if(!reset) r1 <= 1'd0;
	else if(ce) if(!iorq && !wr && a == 8'h4F) r1 <= d;

always @(posedge clock, negedge reset)
	if(!reset) r2 <= 1'd0;
	else if(ce) if(!iorq && !wr && a == 8'h5F) r2 <= d;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
