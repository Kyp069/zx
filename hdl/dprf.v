//-------------------------------------------------------------------------------------------------
module dprf
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0,
	parameter FN = ""
)
(
	input  wire                      clock,
	input  wire                      we1,
	input  wire[$clog2(KB*1024)-1:0] a1,
	input  wire[                7:0] d1,
	output reg [                7:0] q1,
	input  wire[$clog2(KB*1024)-1:0] a2,
	output reg [                7:0] q2
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[(KB*1024)-1:0];
initial if(FN != "") $readmemh(FN, mem);

always @(posedge clock) if(we1) begin mem[a1] <= d1; q1 <= d1; end else q1 <= mem[a1];
always @(posedge clock) q2 <= mem[a2];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
