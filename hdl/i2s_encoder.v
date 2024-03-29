//-------------------------------------------------------------------------------------------------
module i2s_encoder
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	output wire[ 2:0] i2s,
	input  wire[15:0] l,
	input  wire[15:0] r
);
//-------------------------------------------------------------------------------------------------

reg[8:0] ce;
always @(negedge clock) ce <= ce+1'd1;

wire ce4 = &ce[3:0];
wire ce5 = &ce[4:0];
wire ce9a = ce[8] & ce[7] & ce[6] &  ce[5] & ce[4] & ce[3] & ce[2] & ce[1] & ce[0];
wire ce9b = ce[8] & ce[7] & ce[6] & ~ce[5] & ce[4] & ce[3] & ce[2] & ce[1] & ce[0];

reg ck;
always @(posedge clock) if(ce4) ck <= ~ck;

reg lr;
always @(posedge clock) if(ce9b) lr <= ~lr;

reg q;
reg[14:0] sr;
always @(posedge clock) if(ce9a) { q, sr } <= lr ? r : l; else if(ce5) { q, sr } <= { sr, 1'b0 };

assign i2s = { q, lr, ck };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
