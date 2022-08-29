//-------------------------------------------------------------------------------------------------
module mapper
//-------------------------------------------------------------------------------------------------
(
	input  wire       mapper,

	input  wire       clock,
	input  wire       ce,

	input  wire       reset,
	input  wire       mreq,
	input  wire       iorq,
	input  wire       wr,
	input  wire       m1,
	input  wire[15:0] a,
	input  wire[ 7:0] d,

	output wire       map,
	output wire       ram,
	output wire[ 3:0] page
);
//-------------------------------------------------------------------------------------------------

wire ioE3 = !iorq && a[7:0] == 8'hE3;

reg[7:0] portE3;
always @(posedge clock, negedge reset)
	if(!reset) portE3 <= 1'd0;
	else if(ce) if(ioE3 && !wr) portE3 <= { d[7], d[6]|portE3[6], d[5:0] };

wire forcemap = portE3[7];
wire mapram = portE3[6];
wire[3:0] mappage = portE3[3:0];

//-------------------------------------------------------------------------------------------------

wire addr =
	a == 16'h0000 || // reset
	a == 16'h0008 || // rst 8
	a == 16'h0038 || // int
	a == 16'h0066 || // nmi
	a == 16'h04C6 || // load
	a == 16'h0562;   // save

reg automap, m1on;
always @(posedge clock, negedge reset)
	if(!reset) { automap, m1on } <= 1'd0;
	else if(ce) begin
		if(!mreq && !m1 && mapper) begin
			if(addr) m1on <= 1'b1; // activate automapper after this cycle
			else if(a[15:3] == 13'h3FF) m1on <= 1'b0; // deactivate automapper after this cycle
			else if(a[15:8] == 8'h3D) { automap, m1on } <= 2'b11; // activate automapper immediately
		end
		if(m1) automap <= m1on;
	end

//-------------------------------------------------------------------------------------------------

assign map = forcemap || automap;
assign ram = mapram;
assign page = !a[13] && mapram ? 4'd3 : mappage;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
