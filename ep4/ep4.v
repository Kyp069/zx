`default_nettype none
//-------------------------------------------------------------------------------------------------
module ep4
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	output wire[ 1:0] dsg,

	inout  wire[ 1:0] ps2k,
	inout  wire[ 1:0] ps2m,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso,

	output wire[ 1:0] led
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

wire ear = 1'b0;

wire[14:0] left;
wire[14:0] right;

wire[7:0] joy = 8'h00;

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
	.midi   (       ),
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

wire[15:0] lmix = { 1'd0,  left };
wire[15:0] rmix = { 1'd0, right };

dsg #(15) dsg1(clock, reset, lmix, dsg[1]);
dsg #(15) dsg0(clock, reset, rmix, dsg[0]);

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

ram #(512) Ram
(
	clock,
	init ? memWr : iniW,
	init ? memA1 : iniA,
	init ? memD1 : iniD,
	memQ1
);

//-------------------------------------------------------------------------------------------------

assign led = { 1'b0, sdvCs };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
