//-------------------------------------------------------------------------------------------------
module usd
//-------------------------------------------------------------------------------------------------
(
	input  wire      sdcard, // 0 = off, 1 = on

	input  wire      clock,
	input  wire      ce,
	input  wire      cep,
	input  wire      cen,

	input  wire      reset,
	input  wire      iorq,
	input  wire      wr,
	input  wire      rd,
	input  wire[7:0] d,
	output wire[7:0] q,
	input  wire[7:0] a,

	output reg       cs,
	output wire      ck,
	output wire      mosi,
	input  wire      miso
);
//-------------------------------------------------------------------------------------------------

always @(posedge clock, negedge reset)
	if(!reset) cs <= 1'b1;
	else if(ce) if(!iorq && !wr && a == 8'hE7 && sdcard) cs <= d[0];

//-------------------------------------------------------------------------------------------------

reg iod, iop;
wire ioEB = !iorq && a == 8'hEB && (!rd || !wr);
always @(posedge clock) if(cep) begin iod <= ioEB; iop <= ioEB && !iod; end

//-------------------------------------------------------------------------------------------------

wire[7:0] spiD = !wr ? d : 8'hFF;

spi Spi
(
	.clock  (clock  ),
	.ce     (cen    ),
	.io     (iop    ),
	.d      (spiD   ),
	.q      (q      ),
	.ck     (ck     ),
	.mosi   (mosi   ),
	.miso   (miso   )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
