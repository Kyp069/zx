//-------------------------------------------------------------------------------------------------
module rom
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0,
	parameter FN = ""
)
(
	input  wire                      clock,
	input  wire[$clog2(KB*1024)-1:0] a,
	output reg [                7:0] q
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[0:(KB*1024)-1];
initial if(FN != "") $readmemh(FN, mem);

always @(posedge clock) q <= mem[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
