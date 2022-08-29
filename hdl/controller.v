//-------------------------------------------------------------------------------------------------
module controller
//-------------------------------------------------------------------------------------------------
#
(
	parameter RGBW = 18
)
(
	input  wire       clock,
	input  wire       power,

	output wire       model,
	output wire       mapper,
	output wire       sdcard,

	output wire       reset,
	output wire       boot,
	output wire       nmi,

	input  wire[ 1:0] cepix,
	input  wire[ 1:0] isync,
	input  wire[RGBW-1:0] irgb,

	output wire[ 1:0] osync,
	output wire[RGBW-1:0] orgb,

	inout  wire[ 1:0] ps2k,
	output wire       strb,
	output wire       make,
	output wire[ 7:0] code,

	inout  wire[ 1:0] ps2m,
	output wire[ 7:0] xaxis,
	output wire[ 7:0] yaxis,
	output wire[ 2:0] mbtns,

	input  wire[ 1:0] btn,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,

	input  wire       sdvCs,
	input  wire       sdvCk,
	input  wire       sdvMosi,
	output wire       sdvMiso,

	output wire       init,
	output wire       iniW,
	output wire[18:0] iniA,
	output wire[ 7:0] iniD
);
//-------------------------------------------------------------------------------------------------

reg vga = 1'b0;

scandoubler #(.RGBW(RGBW)) Scandoubler
(
	.clock  (clock   ),
	.enable (vga     ),
	.ice    (cepix[0]),
	.isync  (isync   ),
	.irgb   (irgb    ),
	.oce    (cepix[1]),
	.osync  (osync   ),
	.orgb   (orgb    )
);
/*
assign osync = { 1'b1, ~^isync };
assign orgb = irgb;
*/
//-------------------------------------------------------------------------------------------------

ps2k keyboard(clock, ps2k, strb, make, code);

reg F1 = 1'b1;
reg F2 = 1'b1;
reg F4 = 1'b1;
reg F5 = 1'b1;
reg F9 = 1'b1;
always @(posedge clock) if(strb)
	case(code)
		8'h03: F5 <= make;
		8'h01: F9 <= make;
		8'h05: if(!make) F1 <= ~F1;
		8'h06: if(!make) F2 <= ~F2;
		8'h0C: if(!make) F4 <= ~F4;
		8'h7E: if(!make) vga <= ~vga;
	endcase

reg F1d = 1'b1, F1p = 1'b1;
always @(posedge clock) if(strb) begin F1d <= F1; F1p <= F1 == F1d; end

assign model = F1;
assign mapper = F4;
assign sdcard = F2;

assign reset = power & init && btn[0] & F9 & F1p;
assign boot = 1'b1;
assign nmi = F5 && btn[1];

//-------------------------------------------------------------------------------------------------

//ps2m mouse(clock, reset, ps2m, xaxis, yaxis, mbtns);

assign xaxis = 1'd0;
assign yaxis = 1'd0;
assign mbtns = 1'd0;

//-------------------------------------------------------------------------------------------------

assign sdcCs = sdvCs;
assign sdcCk = sdvCk;
assign sdcMosi = sdvMosi;
assign sdvMiso = sdcMiso;

//-------------------------------------------------------------------------------------------------

reg[20:0] cc = 0;
always @(posedge clock) if(power) if(!init) cc <= cc+1'd1;

wire[13:0] rom0A = iniA[13:0];
wire[ 7:0] rom0Q;
rom #(16, "48.hex") rom0(clock, rom0A, rom0Q);

wire[14:0] rom1A = iniA[14:0];
wire[ 7:0] rom1Q;
rom #(32, "+2.hex") rom(clock, rom1A, rom1Q);

wire[12:0] rom2A = iniA[12:0];
wire[ 7:0] rom2Q;
rom #(8, "esxdos.hex") esx(clock, rom2A, rom2Q);

assign init = cc[20];
assign iniW = cc[0];
assign iniA = cc[19:1];
assign iniD
	= iniA[18:15] == 4'h0 ? rom0Q
	: iniA[18:15] == 4'h1 ? rom1Q
	: iniA[18:15] == 4'h2 ? rom2Q
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
