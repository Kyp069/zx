//-------------------------------------------------------------------------------------------------
module soundbox
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      ce,

	input  wire      reset,
	input  wire      iorq,
	input  wire      wr,
	input  wire[7:0] d,
	input  wire[7:0] a,

	output reg [7:0] q
);
//-------------------------------------------------------------------------------------------------

always @(posedge clock, negedge reset)
	if(!reset) q <= 1'd0;
	else if(ce) if(!iorq && !wr && a == 8'hFB) q <= d;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
