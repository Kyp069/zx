//-------------------------------------------------------------------------------------------------
module ram
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0,
	parameter FN = ""
)
(
	input  wire                      clock,
	input  wire                      we,
	input  wire[$clog2(KB*1024)-1:0] a,
	input  wire[                7:0] d,
	output reg [                7:0] q
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[(KB*1024)-1:0];
initial if(FN != "") $readmemh(FN, mem);

always @(posedge clock) if(we) begin mem[a] <= d; q <= d; end else q <= mem[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------