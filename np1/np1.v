`default_nettype none
//-------------------------------------------------------------------------------------------------
module np1
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire[ 1:0] ps2k,

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

	output wire       stm,
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

wire spiCk, spiSs2, spiSs3, spiSs4, spiSsIo, spiMosi, spiMiso;

substitute_mcu #(.sysclk_frequency(560)) controller
(
	.clk          (clock  ),
	.reset_in     (power  ),
	.reset_out    (       ),
	.spi_cs       (       ),
	.spi_clk      (spiCk  ),
	.spi_mosi     (       ),
	.spi_miso     (1'b1   ),
	.spi_req      (       ),
	.spi_ack      (1'b1   ),
	.spi_ss2      (spiSs2 ),
	.spi_ss3      (spiSs3 ),
	.spi_ss4      (spiSs4 ),
	.spi_srtc     (       ),
	.conf_data0   (spiSsIo),
	.spi_toguest  (spiMosi),
	.spi_fromguest(spiMiso),
	.ps2k_clk_in  (ps2k[0]),
	.ps2k_dat_in  (ps2k[1]),
	.ps2k_clk_out (       ),
	.ps2k_dat_out (       ),
	.ps2m_clk_in  (1'b1   ),
	.ps2m_dat_in  (1'b1   ),
	.ps2m_clk_out (       ),
	.ps2m_dat_out (       ),
	.joy1         (8'hFF  ),
	.joy2         (8'hFF  ),
	.joy3         (8'hFF  ),
	.joy4         (8'hFF  ),
	.buttons      ({32{1'b1}}),
	.rxd          (1'b0   ),
	.txd          (       ),
	.intercept    (       ),
	.c64_keys     ({64{1'b1}})
);

//-------------------------------------------------------------------------------------------------

localparam CONF_STR =
{
	"ZX;;",
	"O6,Mem,SRAM,SDRAM;",
	"O45,DivMMC,On,SPI only,Off;",
	"O3,Model,48K,128K;",
	"T2,NMI;",
	"T1,Reset;",
	"V,V1.0;"
};

wire[63:0] status;

wire ps2kDQ;
wire ps2kCk;

user_io #(.STRLEN(90), .SD_IMAGES(0)) user_io
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

	.joystick_0    (),
	.joystick_1    (),
	.joystick_2    (),
	.joystick_3    (),
	.joystick_4    (),
	.joystick_analog_0(),
	.joystick_analog_1(),

	.status        (status),
	.buttons       (),
	.switches      (),
	.ypbpr         (),
	.no_csync      (),
	.core_mod      (),
	.scandoubler_disable(),

	.rtc           (),

	.sd_rd         (),
	.sd_wr         (),
	.sd_ack        (),
	.sd_ack_conf   (),
	.sd_lba        (),
	.sd_conf       (),
	.sd_sdhc       (),
	.sd_dout       (),
	.sd_dout_strobe(),
	.sd_din        (),
	.sd_din_strobe (),
	.sd_buff_addr  (),

	.img_size      (),
	.img_mounted   (),

	.ps2_kbd_clk   (ps2kCk),
	.ps2_kbd_data  (ps2kDQ),
	.ps2_kbd_clk_i (1'b0),
	.ps2_kbd_data_i(1'b0),
	.ps2_mouse_clk (),
	.ps2_mouse_data(),
	.ps2_mouse_clk_i(1'b0),
	.ps2_mouse_data_i(1'b0),

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

osd #(.OSD_AUTO_CE(1'b1)) osd
(
	.clk_sys(clock  ),
	.ce     (       ),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.HSync  (hsync  ),
	.VSync  (vsync  ),
	.R_in   (hblank || vblank ? 6'd0 : { r,{4{r&i}},r }),
	.G_in   (hblank || vblank ? 6'd0 : { g,{4{g&i}},g }),
	.B_in   (hblank || vblank ? 6'd0 : { b,{4{b&i}},b }),
	.R_out  (rgb[17:12]),
	.G_out  (rgb[11: 6]),
	.B_out  (rgb[ 5: 0])
);

assign sync = { 1'b1, ~(hsync^vsync) };

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
wire mapper = status[5:4] == 2'b00;
wire sdcard = status[5:4] == 2'b00 || status[5:4] == 2'b01;

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
	.early  (1'b0   ),
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
	.ear    (1'b0   ),
	.midi   (       ),
	.left   (       ),
	.right  (       ),
	.col    (5'h1F  ),
	.row    (       ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.xaxis  (8'd0   ),
	.yaxis  (8'd0   ),
	.mbtns  (3'd0   ),
	.joy    (8'hFF  ),
	.cs     (sdcCs  ),
	.ck     (sdcCk  ),
	.mosi   (sdcMosi),
	.miso   (sdcMiso),
	.cecpu  (       ),
	.cep1x  (       ),
	.cep2x  (       ),
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

assign sramUb = 1'b0;
assign sramLb = 1'b1;
assign sramOe = !memR1;
assign sramWe = !memW1;
assign sramDQ = sramWe ? 8'bZ : memD1;
assign sramA  = { 2'b00, memA1 };

wire ready;
wire sdrRf = rfsh;
wire sdrRd = memR1;
wire sdrWr = memW1;

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

assign memQ1 = memA1[18:17] == 2'b00 ? romQ : status[6] ? sdrQ[7:0] : sramDQ;

assign dramCk = clock;
assign dramCe = 1'b1;

//-------------------------------------------------------------------------------------------------

assign led = reset;
assign stm = 1'b0;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
