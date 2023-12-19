`default_nettype none
//-------------------------------------------------------------------------------------------------
module psd
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       ear,
	output wire[ 2:0] i2s,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,
	output wire       dramWe,
	output wire       dramRas,
	output wire       dramCas,
	output wire[ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output wire[ 1:0] dramBA,
	output wire[12:0] dramA,

	input  wire       spiCk,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiSsIo,
	input  wire       spiMosi,
	output wire       spiMiso,

	output wire       led
);
//-------------------------------------------------------------------------------------------------

wire clock0, locked0;
pll0 pll0(clock50, clock0, locked0);

wire clock1, locked1;
pll1 pll1(clock50, clock1, locked1);

wire clock = model ? clock1 : clock0;
wire power = locked0 & locked1;

//-------------------------------------------------------------------------------------------------

localparam CONF_STR =
{
	"ZX;;",
	"S0,VHD,Mount SD;",
	"O67,DivMMC,On,SPI only,Off;",
	"O5,kempston mouse,Off,On;",
	"O4,Int timing,late,early;",
	"O3,Model,48K,128K;",
	"T2,NMI;",
	"T1,Reset;",
	"V,V1.0;"
};


wire vga;
wire ps2kDQ;
wire ps2kCk;

wire[31:0] joystick_0;
wire[31:0] joystick_1;

wire[63:0] status;

wire       sdRd;
wire       sdWr;
wire       sdAck;
wire[31:0] sdLba;
wire       sdBusy;
wire       sdConf;
wire       sdSdhc;
wire       sdAckCf;
wire[ 8:0] sdBuffA;
wire[ 7:0] sdBuffD;
wire[ 7:0] sdBuffQ;
wire       sdBuffW;
wire       imgMntd;
wire[63:0] imgSize;

user_io #(.STRLEN(138), .SD_IMAGES(1)) user_io
(
	.conf_str      (CONF_STR),
	.conf_addr     (        ),
	.conf_chr      (8'd0    ),

	.clk_sys       (clock   ),
	.clk_sd        (clock   ),

	.SPI_CLK       (spiCk   ),
	.SPI_SS_IO     (spiSsIo ),
	.SPI_MOSI      (spiMosi ),
	.SPI_MISO      (spiMiso ),

	.ps2_kbd_clk   (ps2kCk),
	.ps2_kbd_data  (ps2kDQ),
	.ps2_kbd_clk_i (1'b0),
	.ps2_kbd_data_i(1'b0),
	.ps2_mouse_clk (),
	.ps2_mouse_data(),
	.ps2_mouse_clk_i(1'b0),
	.ps2_mouse_data_i(1'b0),

	.joystick_0    (joystick_0),
	.joystick_1    (joystick_1),
	.joystick_2    (),
	.joystick_3    (),
	.joystick_4    (),
	.joystick_analog_0(),
	.joystick_analog_1(),

	.ypbpr         (),
	.status        (status),
	.buttons       (),
	.switches      (),
	.no_csync      (),
	.core_mod      (),
	.scandoubler_disable(vga),

	.sd_rd         (sdRd   ),
	.sd_wr         (sdWr   ),
	.sd_ack        (sdAck  ),
	.sd_lba        (sdLba  ),
	.sd_conf       (sdConf ),
	.sd_sdhc       (sdSdhc ),
	.sd_ack_conf   (sdAckCf),
	.sd_buff_addr  (sdBuffA),
	.sd_din        (sdBuffD),
	.sd_dout       (sdBuffQ),
	.sd_dout_strobe(sdBuffW),
	.sd_din_strobe (),
	.img_size      (imgSize),
	.img_mounted   (imgMntd),

	.rtc           (),

	.key_code      (),
	.key_strobe    (),
	.key_pressed   (),
	.key_extended  (),

	.mouse_x       (),
	.mouse_y       (),
	.mouse_z       (),
	.mouse_idx     (),
	.mouse_flags   (),
	.mouse_strobe  (),

	.serial_data   (8'd0),
	.serial_strobe (1'd0)
);

wire sdvCs;
wire sdvCk;
wire sdvMosi;
wire sdvMiso;

sd_card sd_card
(
	.clk_sys     (clock  ),
	.sd_rd       (sdRd   ),
	.sd_wr       (sdWr   ),
	.sd_ack      (sdAck  ),
	.sd_lba      (sdLba  ),
	.sd_conf     (sdConf ),
	.sd_sdhc     (sdSdhc ),
	.sd_ack_conf (sdAckCf),
	.sd_buff_addr(sdBuffA),
	.sd_buff_din (sdBuffD),
	.sd_buff_dout(sdBuffQ),
	.sd_buff_wr  (sdBuffW),
	.img_size    (imgSize),
	.img_mounted (imgMntd),
	.allow_sdhc  (1'b1   ),
	.sd_busy     (sdBusy ),
	.sd_cs       (sdvCs  ),
	.sd_sck      (sdvCk  ),
	.sd_sdi      (sdvMosi),
	.sd_sdo      (sdvMiso)
);

wire[5:0] ro, go, bo;

osd #(.OSD_AUTO_CE(1'b0)) osd
(
	.clk_sys(clock  ),
	.ce     (cep1x  ),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.HSync  (hsync  ),
	.VSync  (vsync  ),
	.R_in   (hblank || vblank ? 6'd0 : { r,{4{r&i}},r }),
	.G_in   (hblank || vblank ? 6'd0 : { g,{4{g&i}},g }),
	.B_in   (hblank || vblank ? 6'd0 : { b,{4{b&i}},b }),
	.R_out  (ro     ),
	.G_out  (go     ),
	.B_out  (bo     )
);

scandoubler scandoubler
(
	.clock   (clock  ),
	.enable  (~vga   ),
	.ice     (cep1x  ),
	.iblank  ({ vblank, hblank }),
	.isync   ({  vsync,  hsync }),
	.irgb    ({ ro, go, bo }),
	.oce     (cep2x  ),
	.oblank  (       ),
	.osync   (sync   ),
	.orgb    (rgb    )
);

//-------------------------------------------------------------------------------------------------

wire      strb;
wire      make;
wire[7:0] code;
ps2k PS2K(clock, { ps2kDQ, ps2kCk }, strb, make, code);

reg F5 = 1'b1, F9 = 1'b1;
reg alt = 1'b1, del = 1'b1, ctrl = 1'b1;

always @(posedge clock) if(strb)
	case(code)
		8'h03: F5 <= make;
		8'h01: F9 <= make;
		8'h11: alt <= make;
		8'h71: del <= make;
		8'h14: ctrl <= make;
	endcase

//-------------------------------------------------------------------------------------------------

wire model  = status[3];
wire early  = status[4];
wire mouse  = status[5];
wire mapper = status[7:6] == 2'b00;
wire sdcard = status[7:6] == 2'b00 || status[7:6] == 2'b01;

wire reset = power && ready && F9 && !status[1];
wire nmi = F5 && !status[2];

wire hblank;
wire vblank;
wire hsync;
wire vsync;

wire r;
wire g;
wire b;
wire i;

wire[14:0] left;
wire[14:0] right;

wire       cep1x;
wire       cep2x;

wire       rfsh;
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
	.mouse  (1'b0   ),
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
	.xaxis  (8'd0   ),
	.yaxis  (8'd0   ),
	.mbtns  (3'd0   ),
	.joy    (8'hFF  ),
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso),
	.cecpu  (       ),
	.cep1x  (cep1x  ),
	.cep2x  (cep2x  ),
	.rfsh   (rfsh   ),
	.memR1  (memR1  ),
	.memW1  (memW1  ),
	.memA1  (memA1  ),
	.memD1  (memD1  ),
	.memQ1  (memQ1  ),
	.memA2  (memA2  ),
	.memQ2  (memQ2  )
);

//-------------------------------------------------------------------------------------------------

i2s_encoder i2so(clock, i2s, { 1'b0,  left }, { 1'b0, right });

//-------------------------------------------------------------------------------------------------

wire[7:0] romQ;
romzx rom(clock, memA1[16:0], romQ);

dprs #(16) dpr
(
	clock,
	memW1 && memA1[18:17] == 2'b01 && (memA1[16:14] == 5 || memA1[16:14] == 7) && !memA1[13],
	{ memA1[15], memA1[12:0] },
	memD1,
	memA2,
	memQ2
);

wire ready;
wire sdrRf = rfsh;
wire sdrRd = memR1 && memA1[18:17] != 2'b00;
wire sdrWr = memW1 && memA1[18:17] != 2'b00;

wire[23:0] sdrA = { 5'd0, memA1 };
wire[15:0] sdrD = { 8'hFF, memD1 };
wire[15:0] sdrQ;

sdram ram
(
	.clock  (clock  ),
	.reset  (power  ),
	.ready  (ready  ),
	.rfsh   (sdrRf  ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (dramCs ),
	.dramRas(dramRas),
	.dramCas(dramCas),
	.dramWe (dramWe ),
	.dramDQM(dramDQM),
	.dramDQ (dramDQ ),
	.dramBA (dramBA ),
	.dramA  (dramA  )
);

assign memQ1 = memA1[18:17] == 2'b00 ? romQ : sdrQ[7:0];

assign dramCk = clock;
assign dramCe = 1'b1;

//-------------------------------------------------------------------------------------------------

assign led = ~sdBusy;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
