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

	output reg        early = 1'b0,
	output reg        mouse = 1'b0,
	output reg        model = 1'b0,
	output reg        mapper = 1'b1,
	output reg        sdcard = 1'b1,

	output wire       reset,
	output wire       boot,
	output wire       nmi,

	input  wire       vgaE,
	input  wire       vgaD,

	input  wire[     1:0] cepix,

	input  wire[     1:0] iblank,
	input  wire[     1:0] isync,
	input  wire[RGBW-1:0] irgb,
    
	output wire[     1:0] oblank,
	output wire[     1:0] osync,
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

scandoubler #(.RGBW(RGBW)) scandoubler
(
	.clock  (clock   ),
	.enable (vga     ),
	.ice    (cepix[0]),
	.iblank (iblank  ),
	.isync  (isync   ),
	.irgb   (irgb    ),
	.oce    (cepix[1]),
	.oblank (oblank  ),
	.osync  (osync   ),
	.orgb   (orgb    )
);

//-------------------------------------------------------------------------------------------------

initial begin model = 1'b0; early = 1'b0; mouse = 1'b0; mapper = 1'b1; sdcard = 1'b1; end

ps2k keyboard(clock, ps2k, strb, make, code);

reg F5 = 1'b1, F9 = 1'b1, F11 = 1'b1;
reg alt = 1'b1, del = 1'b1, ctrl = 1'b1, bspc = 1'b1;

always @(posedge clock) begin
	if(!vgaE) vga <= vgaD;
	if(strb)
		case(code)
			8'h7E: if(!make) vga <= ~vga;       // scroll lock
			8'h05: if(!make) model <= 1'b0;     // F1
			8'h06: if(!make) model <= 1'b1;     // F2
			8'h0C: if(!make) early <= ~early;   // F4
			8'h0B: if(!make) mapper <= ~mapper; // F6
			8'h83: if(!make) sdcard <= ~sdcard; // F7
			8'h0A: if(!make) mouse <= ~mouse;   // F8
			8'h03: F5 <= make;
			8'h01: F9 <= make;
			8'h78: F11 <= make;
			8'h11: alt <= make;
			8'h71: del <= make;
			8'h14: ctrl <= make;
			8'h66: bspc <= make;
		endcase
end

reg modeld = 1'b1, modelp = 1'b1;
always @(posedge clock) if(strb) begin modeld <= model; modelp <= modeld == model; end

assign reset = power & init && btn[0] & F9 & (ctrl | alt | del) & modelp;
assign boot = F11 & (ctrl | alt | bspc);
assign nmi = F5 & btn[1];

//-------------------------------------------------------------------------------------------------

ps2m mouse(clock, reset, ps2m, xaxis, yaxis, mbtns);

//-------------------------------------------------------------------------------------------------

assign sdcCs = sdvCs;
assign sdcCk = sdvCk;
assign sdcMosi = sdvMosi;
assign sdvMiso = sdcMiso;

//-------------------------------------------------------------------------------------------------

reg[20:0] cc = 0;
always @(posedge clock) if(power && vgaE) if(!init) cc <= cc+1'd1;

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
