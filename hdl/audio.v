//-------------------------------------------------------------------------------------------------
module audio
//-------------------------------------------------------------------------------------------------
(
	input  wire       mic,
	input  wire       ear,
	input  wire       speaker,
	input  wire[11:0] a1,
	input  wire[11:0] b1,
	input  wire[11:0] c1,
	input  wire[11:0] a2,
	input  wire[11:0] b2,
	input  wire[11:0] c2,
	input  wire[ 7:0] spdQ,
	input  wire[ 7:0] sbxQ,
	input  wire[ 7:0] sdvL1,
	input  wire[ 7:0] sdvR1,
	input  wire[ 7:0] sdvL2,
	input  wire[ 7:0] sdvR2,
	input  wire[ 7:0] saaL,
	input  wire[ 7:0] saaR,
	output wire[14:0] left,
	output wire[14:0] right
);
//-------------------------------------------------------------------------------------------------

reg[7:0] ula;
always @(*) case({ speaker, ear, mic })
	0: ula <= 8'h00;
	1: ula <= 8'h24;
	2: ula <= 8'h40;
	3: ula <= 8'h64;
	4: ula <= 8'hB8;
	5: ula <= 8'hC0;
	6: ula <= 8'hF8;
	7: ula <= 8'hFF;
endcase

//-------------------------------------------------------------------------------------------------

wire[15:0] lmix = { 3'd0, a1, 1'd0 }+{ 3'd0, a2, 1'd0 }+{ 4'd0, b1 }+{ 4'd0, b2}+{ 3'd0, spdQ, 5'd0}+{ 3'd0, sbxQ, 5'd0}+{ 3'd0, sdvL1, 5'd0}+{ 3'd0, sdvL2, 5'd0}+{ 6'd0, saaL, 2'd0 }+{ 4'd0, ula, 4'd0};
wire[15:0] rmix = { 3'd0, c1, 1'd0 }+{ 3'd0, c2, 1'd0 }+{ 4'd0, b1 }+{ 4'd0, b2}+{ 3'd0, spdQ, 5'd0}+{ 3'd0, sbxQ, 5'd0}+{ 3'd0, sdvR1, 5'd0}+{ 3'd0, sdvR2, 5'd0}+{ 6'd0, saaR, 2'd0 }+{ 4'd0, ula, 4'd0};

assign  left = lmix[15:1];
assign right = rmix[15:1];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
