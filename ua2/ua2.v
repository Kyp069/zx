`default_nettype none
//-------------------------------------------------------------------------------------------------
module ua2
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire       rgbCk,
	output wire       rgbEn,
	output wire[ 1:0] sync,
	output wire[23:0] rgb,

	input  wire       tape,
	input  wire[ 2:0] i2sIn,
	output wire[ 2:0] i2sOut,

	output wire       midi,

	inout  wire[ 1:0] ps2k,
	inout  wire[ 1:0] ps2m,

	input  wire[ 5:0] joy1,
	input  wire[ 5:0] joy2,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,

	output wire       sramWe,
	inout  wire[ 7:0] sramDQ,
	output wire[20:0] sramA,

	output wire[ 1:0] led,
	output wire       stm
);
//-------------------------------------------------------------------------------------------------

wire clock0, locked0;
pll0 pll0(clock50, clock0, locked0);

wire clock1, locked1;
pll1 pll1(clock50, clock1, locked1);

wire clock = model ? clock1 : clock0;
wire power = locked0 & locked1;

//-------------------------------------------------------------------------------------------------

wire model;
wire mapper;
wire sdcard;

wire reset;
wire nmi;

reg[23:0] palette[0:15];
initial $readmemh("../hdl/palette24.hex", palette);

wire[ 1:0] cepix = { cep2x, cep1x };
wire[ 1:0] iblank = { vblank, hblank };
wire[ 1:0] isync = { vsync, hsync };
wire[23:0] irgb = model ? { r,r,{6{r&i}}, g,g,{6{g&i}}, b,b,{6{b&i}} } : palette[{ i, r, g, b }];
wire[ 1:0] blank;

wire strb;
wire make;
wire[7:0] code;

wire[7:0] xaxis;
wire[7:0] yaxis;
wire[2:0] mbtns;

wire sdvCs;
wire sdvCk;
wire sdvMosi;
wire sdvMiso;

wire init;
wire iniW;
wire[18:0] iniA;
wire[ 7:0] iniD;

//controller #(.RGBW(24)) controller
demistify #(.RGBW(24), .OSD_PIXEL_MSB(7)) controller
(
	.clock  (clock  ),
	.power  (power  ),
	.boot   (       ),
	.model  (model  ),
	.mapper (mapper ),
	.sdcard (sdcard ),
	.reset  (reset  ),
	.nmi    (nmi    ),
	.cepix  (cepix  ),
	.iblank (iblank ),
	.isync  (isync  ),
	.irgb   (irgb   ),
	.oblank (blank  ),
	.osync  (sync   ),
	.orgb   (rgb    ),
	.ps2k   (ps2k   ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.ps2m   (ps2m   ),
	.xaxis  (       ),
	.yaxis  (       ),
	.mbtns  (       ),
	.btn    (2'b11  ),
	.sdcCs  (sdcCs  ),
	.sdcCk  (sdcCk  ),
	.sdcMosi(sdcMosi),
	.sdcMiso(sdcMiso),
	.sdvCs  (sdvCs  ),
	.sdvCk  (sdvCk  ),
	.sdvMosi(sdvMosi),
	.sdvMiso(sdvMiso),
	.init   (init   ),
	.iniW   (iniW   ),
	.iniA   (iniA   ),
	.iniD   (iniD   )
);

//-------------------------------------------------------------------------------------------------

wire hblank;
wire vblank;
wire hsync;
wire vsync;

wire r;
wire g;
wire b;
wire i;

wire ear = ~tape;

wire[14:0] left;
wire[14:0] right;

wire[7:0] joy = { 2'b00, ~(joy1 | joy2) };

wire cep1x;
wire cep2x;

wire memRf;
wire memRd;
wire memWr;
wire[18:0] memA1;
wire[ 7:0] memD1;
wire[ 7:0] memQ1;
wire[13:0] memA2;
wire[ 7:0] memQ2;

zx Zx
(
	.model  (model  ),
	.mapper (mapper ),
	.sdcard (sdcard ),
	.clock  (clock  ),
	.power  (power  ),
	.reset  (reset  ),
	.nmi    (nmi    ),
	.hblank (hblank ),
	.vblank (vblank ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.i      (i      ),
	.ear    (ear    ),
	.midi   (midi   ),
	.left   (left   ),
	.right  (right  ),
	.col    (5'h1F  ),
	.row    (       ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.xaxis  (8'd0   ),
	.yaxis  (8'd0   ),
	.mbtns  (3'd0   ),
	.joy    (joy    ),
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso),
	.cecpu  (       ),
	.cep1x  (cep1x  ),
	.cep2x  (cep2x  ),
	.memRf  (       ),
	.memRd  (memRd  ),
	.memWr  (memWr  ),
	.memA1  (memA1  ),
	.memD1  (memD1  ),
	.memQ1  (memQ1  ),
	.memA2  (memA2  ),
	.memQ2  (memQ2  )
);

//-------------------------------------------------------------------------------------------------

wire[15:0] lmidi, rmidi;
i2s_decoder Midi(clock, i2sIn, lmidi, rmidi);

wire[15:0] lmix = { 1'b0, lmidi[15:1] }^16'h4000+{ 1'd0,  left };
wire[15:0] rmix = { 1'b0, rmidi[15:1] }^16'h4000+{ 1'd0, right };
i2s_encoder I2S(clock, i2sOut, lmix, rmix);

//-------------------------------------------------------------------------------------------------

dprs #(16) Dpr
(
	clock,
	memWr && memA1[18:17] == 2'b01 && (memA1[16:14] == 5 || memA1[16:14] == 7) && !memA1[13],
	{ memA1[15], memA1[12:0] },
	memD1,
	memA2,
	memQ2
);

assign memQ1 = sramDQ;

assign sramWe = init ? !memWr : !iniW;
assign sramDQ = sramWe ? 8'bZ : init ? memD1 : iniD;
assign sramA  = { 2'b00, init ? memA1 : iniA };

//-------------------------------------------------------------------------------------------------

assign rgbCk = cep2x;
assign rgbEn = ~|blank;

assign led = { init, ~sdvCs };
assign stm = 1'b0;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
