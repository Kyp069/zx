`default_nettype none
//-------------------------------------------------------------------------------------------------
module zx3
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[23:0] rgb,

	input  wire       tape,
	output wire       midi,

	input  wire[ 2:0] i2si,
	output wire[ 2:0] i2so,
	output wire[ 1:0] dsg,

	inout  wire[ 1:0] ps2k,
	inout  wire[ 1:0] ps2m,

	output wire       joyCk,
	output wire       joyLd,
	output wire       joyS,
	input  wire       joyD,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,

	output wire       sramUb,
	output wire       sramLb,
	output wire       sramOe,
	output wire       sramWe,
	inout  wire[15:8] sramDQ,
	output wire[19:0] sramA,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,

	output wire[ 1:0] led
);
//-------------------------------------------------------------------------------------------------

wire ci;
IBUF IBuf(.I(clock50), .O(ci));

wire clock0, locked0;
mmcm0 mmcm0(ci, clock0, locked0);

wire clock1, locked1;
mmcm1 mmcm1(ci, clock1, locked1);

wire clock;
wire model;
wire power = locked0 & locked1;
BUFGMUX_1 BufgMux(.I0(clock0), .I1(clock1), .O(clock), .S(model));

//-------------------------------------------------------------------------------------------------

wire[7:0] joy1;
wire[7:0] joy2;

joystick joystick
(
	.clock  (clock  ),
	.joyCk  (joyCk  ),
	.joyLd  (joyLd  ),
	.joyS   (joyS   ),
	.joyD   (joyD   ),
	.joy1   (joy1   ),
	.joy2   (joy2   )
);

//-------------------------------------------------------------------------------------------------

reg tapeini, tapegot;
always @(posedge clock) if(!power) if(!tapegot) { tapeini, tapegot } <= { tape, 1'b1 };

//-------------------------------------------------------------------------------------------------

wire early;
wire mouse;
wire mapper;
wire sdcard;

wire reset;
wire boot;
wire nmi;

reg[23:0] palette[0:15];
initial $readmemh("../hdl/rom/palette24.hex", palette);

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

controller #(.RGBW(24)) controller
//demistify #(.RGBW(24)) controller
(
	.clock  (clock  ),
	.power  (power  ),
	.early  (early  ),
	.mouse  (mouse  ),
	.model  (model  ),
	.mapper (mapper ),
	.sdcard (sdcard ),
	.reset  (reset  ),
	.boot   (boot   ),
	.nmi    (nmi    ),
	.vgaE   (1'b1   ),
	.vgaD   (1'b0   ),
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
	.xaxis  (xaxis  ),
	.yaxis  (yaxis  ),
	.mbtns  (mbtns  ),
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

wire ear = tape ^ tapeini;

wire[14:0] left;
wire[14:0] right;

wire[7:0] joy = joy1 | joy2;

wire cep1x;
wire cep2x;

wire       memR1;
wire       memW1;
wire[18:0] memA1;
wire[ 7:0] memD1;
wire[ 7:0] memQ1;
wire[13:0] memA2;
wire[ 7:0] memQ2;

zx zx
(
	.early  (early  ),
	.mouse  (mouse  ),
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
	.xaxis  (xaxis  ),
	.yaxis  (yaxis  ),
	.mbtns  (mbtns  ),
	.joy    (joy    ),
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso),
	.cecpu  (       ),
	.cep1x  (cep1x  ),
	.cep2x  (cep2x  ),
	.rfsh   (       ),
	.memR1  (memR1  ),
	.memW1  (memW1  ),
	.memA1  (memA1  ),
	.memD1  (memD1  ),
	.memQ1  (memQ1  ),
	.memA2  (memA2  ),
	.memQ2  (memQ2  )
);

//-------------------------------------------------------------------------------------------------

wire[15:0] lmidi, rmidi;
i2s_decoder i2so(clock, i2si, lmidi, rmidi);

wire[15:0] lmix = { 1'b0, (lmidi[15:1]^15'h4000)+ left };
wire[15:0] rmix = { 1'b0, (rmidi[15:1]^15'h4000)+right };

i2s_encoder i2si(clock, i2so, lmix, rmix);
dsg #(15) dsg1(clock, reset, lmix, dsg[1]);
dsg #(15) dsg0(clock, reset, rmix, dsg[0]);

//-------------------------------------------------------------------------------------------------

dprs #(16) dpr
(
	clock,
	memW1 && memA1[18:17] == 2'b01 && (memA1[16:14] == 5 || memA1[16:14] == 7) && !memA1[13],
	{ memA1[15], memA1[12:0] },
	memD1,
	memA2,
	memQ2
);

assign memQ1 = sramDQ;

assign sramUb = 1'b0;
assign sramLb = 1'b1;
assign sramOe = init ? !memR1 :  1'b1;
assign sramWe = init ? !memW1 : !iniW;
assign sramDQ = sramWe ? 8'bZ : init ? memD1 : iniD;
assign sramA  = { 1'b0, init ? memA1 : iniA };

assign dramCk = 1'b0;
assign dramCe = 1'b0;
assign dramCs = 1'b1;

//-------------------------------------------------------------------------------------------------

mboot mboot(clock, ~boot);

//-------------------------------------------------------------------------------------------------

assign led = ~{ init, sdvCs };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
