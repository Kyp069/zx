//-------------------------------------------------------------------------------------------------
module mist
//-------------------------------------------------------------------------------------------------
#
(
	RGBW = 6
)
(
	input  wire       clock,
	input  wire       ne14M,
	input  wire       ne7M0,

	input  wire       spiCk,
	input  wire       spiSs1,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiMosi,
	inout  wire       spiMiso,

	input  wire       hsync,
	input  wire       vsync,
	input  wire       r,
	input  wire       g,
	input  wire       b,
	input  wire       i,

	input  wire[ 7:0] midiQ,
	input  wire       midiS,

	output wire[63:0] status,

	output wire[ 1:0] sync,
	output wire[RGBW*3-1:0] rgb,

	output wire       ps2kCk,
	output wire       ps2kD,

	output wire[ 7:0] joy1,
	output wire[ 7:0] joy2,

	output reg [ 2:0] mbtns,
	output reg [ 7:0] xaxis,
	output reg [ 7:0] yaxis,

	output wire       romIo,
	output wire       tzxIo,
	output wire[31:0] dioSz,
	output wire[26:0] dioA,
	output wire[ 7:0] dioD,
	output wire       dioW,

	input  wire       sdcCs,
	input  wire       sdcCk,
	input  wire       sdcMosi,
	output wire       sdcMiso
);
//--- confStr -------------------------------------------------------------------------------------

	localparam confStr =
	{
		"ZX;;",
		"O4,DivMMC,On,Off;",
		"S0U,VHD,Mount SD;",
		"-;",
		"O5,Tape sound,On,Off;",
		"F1,TZX,Load TZX;",
		"-;",
		"F0,ROM,Load ROM;",
		"O3,Model,48K,128K;",
		"-;",
		"T1,Reset;",
		"T2,NMI;",
		"V,V2.0,2026.01.23;",
	};

//--- user io--------------------------------------------------------------------------------------

	wire[31:0] joystick_1;
	wire[31:0] joystick_2;

	wire[ 8:0] mouse_x;
	wire[ 8:0] mouse_y;
	wire[ 7:0] mouse_flags;
	wire       mouse_strobe;

	wire       sdRd;
	wire       sdWr;
	wire       sdAck;
	wire[31:0] sdLba;
	wire       sdBusy;
	wire       sdConf;
	wire       sdSdhc;
	wire       sdAckCf;
	wire[16:0] sdBuffA;
	wire[ 7:0] sdBuffD;
	wire[ 7:0] sdBuffQ;
	wire       sdBuffW;
	wire       imgMntd;
	wire[63:0] imgSize;

	wire novga;

	user_io #(.STRLEN(149), .SD_IMAGES(1), .SERIAL_CHANNEL(1), .FEATURES(32'h2000)) user_io
	(
		.conf_str        (confStr),
		.conf_addr       (       ),
		.conf_chr        (8'd0   ),
		.clk_sys         (clock  ),
		.clk_sd          (clock  ),
		.SPI_CLK         (spiCk  ),
		.SPI_SS_IO       (spiSs1 ),
		.SPI_MOSI        (spiMosi),
		.SPI_MISO        (spiMiso),
		.ps2_kbd_clk     (ps2kCk ),
		.ps2_kbd_data    (ps2kD  ),
		.ps2_kbd_clk_i   (1'b0),
		.ps2_kbd_data_i  (1'b0),
		.ps2_mouse_clk   (),
		.ps2_mouse_data  (),
		.ps2_mouse_clk_i (1'b0),
		.ps2_mouse_data_i(1'b0),
		.sd_rd           (sdRd   ),
		.sd_wr           (sdWr   ),
		.sd_ack          (sdAck  ),
		.sd_ack_conf     (sdAckCf),
		.sd_ack_x        (),
		.sd_lba          (sdLba  ),
		.sd_cnt          (8'd0   ),
		.sd_conf         (sdConf ),
		.sd_sdhc         (sdSdhc ),
		.sd_buff_addr    (sdBuffA),
		.sd_din          (sdBuffD),
		.sd_din_strobe   (),
		.sd_dout         (sdBuffQ),
		.sd_dout_strobe  (sdBuffW),
		.img_mounted     (imgMntd),
		.img_size        (imgSize),
		.rtc             (),
		.ypbpr           (),
		.leds            (8'd0),
		.status          (status),
		.buttons         (),
		.switches        (),
		.no_csync        (),
		.core_mod        (),
		.key_pressed     (),
		.key_extended    (),
		.key_code        (),
		.key_strobe      (),
		.kbd_out_data    (8'd0),
		.kbd_out_strobe  (1'b0),
		.mouse_x         (mouse_x),
		.mouse_y         (mouse_y),
		.mouse_z         (),
		.mouse_flags     (mouse_flags),
		.mouse_strobe    (mouse_strobe),
		.mouse_idx       (),
		.joystick_0      (),
		.joystick_1      (joystick_1),
		.joystick_2      (joystick_2),
		.joystick_3      (),
		.joystick_4      (),
		.i2c_start       (),
		.i2c_read        (),
		.i2c_addr        (),
		.i2c_subaddr     (),
		.i2c_dout        (),
		.i2c_din         (8'hFF),
		.i2c_ack         (1'b0 ),
		.i2c_end         (1'b0 ),
		.serial_data     (midiQ),
		.serial_strobe   (midiS),
		.joystick_analog_0(),
		.joystick_analog_1(),
		.scandoubler_disable(novga)
	);

//--- data io--------------------------------------------------------------------------------------

	wire      dioEn;
	wire[7:0] dioIx;

	data_io	data_io
	(
		.clk_sys       (clock  ),
		.SPI_SCK       (spiCk  ),
		.SPI_SS2       (spiSs2 ),
		.SPI_SS4       (       ),
		.SPI_DI        (spiMosi),
		.SPI_DO        (spiMiso),
		.clkref_n      (1'b0   ),
		.ioctl_filesize(dioSz  ),
		.ioctl_download(dioEn  ),
		.ioctl_index   (dioIx  ),
		.ioctl_addr    (dioA   ),
		.ioctl_din     (8'd0   ),
		.ioctl_dout    (dioD   ),
		.ioctl_wr      (dioW   ),
		.ioctl_upload  (),
		.ioctl_fileext (),
		.QCSn          (1'b1),
		.QSCK          (1'b1),
		.QDAT          (4'hF),
		.hdd_clk       (1'b0),
		.hdd_cmd_req   (1'b0),
		.hdd_cdda_req  (1'b0),
		.hdd_dat_req   (1'b0),
		.hdd_cdda_wr   (),
		.hdd_status_wr (),
		.hdd_addr      (),
		.hdd_wr        (),
		.hdd_data_out  (),
		.hdd_data_in   (16'd0),
		.hdd_data_rd   (),
		.hdd_data_wr   (),
		.hdd0_ena      (),
		.hdd1_ena      ()
	);

//---sd card --------------------------------------------------------------------------------------

	sd_card sd_card
	(
		.clk_sys     (clock  ),
		.sd_rd       (sdRd   ),
		.sd_wr       (sdWr   ),
		.sd_ack      (sdAck  ),
		.sd_lba      (sdLba  ),
		.sd_busy     (sdBusy ),
		.sd_conf     (sdConf ),
		.sd_sdhc     (sdSdhc ),
		.sd_ack_conf (sdAckCf),
		.sd_buff_addr(sdBuffA[8:0]),
		.sd_buff_din (sdBuffD),
		.sd_buff_dout(sdBuffQ),
		.sd_buff_wr  (sdBuffW),
		.img_mounted (imgMntd),
		.img_size    (imgSize),
		.allow_sdhc  (1'b1   ),
		.sd_cs       (sdcCs  ),
		.sd_sck      (sdcCk  ),
		.sd_sdi      (sdcMosi),
		.sd_sdo      (sdcMiso)
	);

//--- osd -----------------------------------------------------------------------------------------

	wire[RGBW*3-1:0] rgbosd;

	osd #(.OSD_AUTO_CE(0), .BIG_OSD(1'b1), .OUT_COLOR_DEPTH(RGBW)) osd
	(
		.clk_sys(clock  ),
		.ce     (ne7M0  ),
		.SPI_SCK(spiCk  ),
		.SPI_SS3(spiSs3 ),
		.SPI_DI (spiMosi),
		.rotate (2'd0   ),
		.HBlank (1'b0   ),
		.VBlank (1'b0   ),
		.HSync  (hsync  ),
		.VSync  (vsync  ),
		.R_in   ({RGBW/2{r,r&i}}),
		.G_in   ({RGBW/2{g,g&i}}),
		.B_in   ({RGBW/2{b,b&i}}),
		.R_out  (rgbosd[RGBW*3-1:RGBW*2]),
		.G_out  (rgbosd[RGBW*2-1:RGBW*1]),
		.B_out  (rgbosd[RGBW*1-1:RGBW*0]),
		.osd_enable()
	);

//---scandoubler ----------------------------------------------------------------------------------

	scandoubler #(.RGBW(RGBW*3)) scandoubler
	(
		.clock   (clock  ),
		.novga   (novga  ),
		.ice     (ne7M0  ),
		.isync   ({ vsync, hsync }),
		.irgb    (rgbosd ),
		.oce     (ne14M  ),
		.osync   (sync   ),
		.orgb    (rgb    )
	);

	// assign sync = { 1'b1, ~(hsync^vsync) };

//-------------------------------------------------------------------------------------------------

	assign romIo = dioEn && dioIx[5:0] == 0;
	assign tzxIo = dioEn && dioIx[5:0] == 1;

	assign joy1 = joystick_1[7:0];
	assign joy2 = joystick_2[7:0];

	reg mouse_strobe_p;
	always @(posedge clock) begin
		mouse_strobe_p <= mouse_strobe;
		if(mouse_strobe != mouse_strobe_p) begin
			mbtns <= ~{ mouse_flags[2], mouse_flags[0], mouse_flags[1] };
			xaxis <= xaxis+{ mouse_flags[4], mouse_x[7:1] };
			yaxis <= yaxis+{ mouse_flags[5], mouse_y[7:1] };
		end
	end

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
