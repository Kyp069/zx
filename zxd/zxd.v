`default_nettype none
//-------------------------------------------------------------------------------------------------
module zxd
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       tape,
	input  wire[ 2:0] i2sIn,

	output wire[ 1:0] dsg,
	output wire[ 2:0] i2sOut,

	output wire       midi,

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
	output wire[20:0] sramA,

//	output wire[ 1:0] led // green
	output wire[ 1:1] led // black
);
//-------------------------------------------------------------------------------------------------

wire ci;
IBUFG IBufg(.I(clock50), .O(ci));

wire clock0, locked0;
dcm0 dcm0(ci, clock0, locked0);

wire clock1, locked1;
dcm1 dcm1(ci, clock1, locked1);

wire clock;
wire model;
wire power = locked0 & locked1;
BUFGMUX_1 BufgMux(.I0(clock0), .I1(clock1), .O(clock), .S(model));

//-------------------------------------------------------------------------------------------------

wire[7:0] joy1;
wire[7:0] joy2;

joystick Joystick
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

wire mapper;
wire sdcard;

wire reset;
wire nmi;

reg[17:0] palette[0:15];
initial $readmemb("../hdl/palette18.bin", palette);

wire[ 1:0] cepix = { cep2x, cep1x };
wire[ 1:0] iblank = { vblank, hblank };
wire[ 1:0] isync = { vsync, hsync };
wire[17:0] irgb = model ? { r,r,{4{r&i}}, g,g,{4{g&i}}, b,b,{4{b&i}} } : palette[{ i, r, g, b }];
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

//controller controller
demistify controller
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

wire[15:0] lmix = { 1'b0, (lmidi[15:1]^15'h4000)+ left };
wire[15:0] rmix = { 1'b0, (rmidi[15:1]^15'h4000)+right };

dsg #(15) dsg1(clock, reset, lmix, dsg[1]);
dsg #(15) dsg0(clock, reset, rmix, dsg[0]);
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

assign sramUb = 1'b0;
assign sramLb = 1'b1;
assign sramOe = init ? !memRd :  1'b1;
assign sramWe = init ? !memWr : !iniW;
assign sramDQ = sramWe ? 8'bZ : init ? memD1 : iniD;
assign sramA  = { 2'b00, init ? memA1 : iniA };

//-------------------------------------------------------------------------------------------------

//assign led = { init, ~sdvCs }; // green
assign led = ~sdvCs; // black

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
