//-------------------------------------------------------------------------------------------------
module demistify
//-------------------------------------------------------------------------------------------------
#
(
	parameter RGBW          = 18,
	parameter OSD_PIXEL_MSB = 5
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

wire spiCk = sdcCk;
wire spiSs2, spiSs3, spiSs4, spiSsIo, spiMosi, spiMiso;

wire kbiCk = ps2k[0]; wire kboCk; assign ps2k[0] = kboCk ? 1'bZ : kboCk;
wire kbiDQ = ps2k[1]; wire kboDQ; assign ps2k[1] = kboDQ ? 1'bZ : kboDQ;

wire msiCk = ps2m[0]; wire msoCk; assign ps2m[0] = msoCk ? 1'bZ : msoCk;
wire msiDQ = ps2m[1]; wire msoDQ; assign ps2m[1] = msoDQ ? 1'bZ : msoDQ;

substitute_mcu #(.sysclk_frequency(560)) controller
(
	.clk          (clock  ),
	.reset_in     (power  ),
	.reset_out    (       ),
	.spi_cs       (sdcCs  ),
	.spi_clk      (sdcCk  ),
	.spi_mosi     (sdcMosi),
	.spi_miso     (sdcMiso),
	.spi_req      (       ),
	.spi_ack      (1'b1   ),
	.spi_ss2      (spiSs2 ),
	.spi_ss3      (spiSs3 ),
	.spi_ss4      (spiSs4 ),
	.spi_srtc     (       ),
	.conf_data0   (spiSsIo),
	.spi_toguest  (spiMosi),
	.spi_fromguest(spiMiso),
	.ps2k_clk_in  (kbiCk  ),
	.ps2k_dat_in  (kbiDQ  ),
	.ps2k_clk_out (kboCk  ),
	.ps2k_dat_out (kboDQ  ),
	.ps2m_clk_in  (msiCk  ),
	.ps2m_dat_in  (msiDQ  ),
	.ps2m_clk_out (msoCk  ),
	.ps2m_dat_out (msoDQ  ),
	.joy1         (8'hFF  ),
	.joy2         (8'hFF  ),
	.joy3         (8'hFF  ),
	.joy4         (8'hFF  ),
	.buttons      (8'hFF  ),
	.rxd          (1'b0   ),
	.txd          (       ),
	.intercept    (       ),
	.c64_keys     (64'hFFFFFFFF)
);

//-------------------------------------------------------------------------------------------------

localparam CONF_STR =
{
	"ZX;;",
	"F,ROM,Load ROM;",
	"S0,VHD,Mount VHD;",
	"O45,DivMMC,On,SPI,Off;",
	"O3,Model,48K,128K;",
	"T2,NMI;",
	"T1,Reset;",
//	"T9,Reset FPGA;", // 99/113
	"V,V1.0;"
};

wire[63:0] status;

wire keyStrobe;
wire keyPressed;
wire[7:0] keyCode;

wire[8:0] mouse_x;
wire[8:0] mouse_y;
wire[7:0] mouse_f;

wire       usdRd     ;
wire       usdWr     ;
wire       usdAck    ;
wire       usdAckConf;
wire[31:0] usdLba    ;
wire       usdConf   ;
wire       usdSdHc   ;
wire[ 8:0] usdA      ;
wire[ 7:0] usdD      ;
wire[ 7:0] usdQ      ;
wire       usdStrbQ  ;
wire[63:0] usdSize   ;
wire       usdMntd   ;

wire rgb;

user_io #(.STRLEN(99), .SD_IMAGES(1)) user_io
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
	.scandoubler_disable(rgb),

	.rtc           (),

	.sd_rd         (usdRd     ),
	.sd_wr         (usdWr     ),
	.sd_ack        (usdAck    ),
	.sd_ack_conf   (usdAckConf),
	.sd_lba        (usdLba    ),
	.sd_conf       (usdConf   ),
	.sd_sdhc       (usdSdHc   ),
	.sd_dout       (usdQ      ),
	.sd_dout_strobe(usdStrbQ  ),
	.sd_din        (usdD      ),
	.sd_din_strobe (          ),
	.sd_buff_addr  (usdA      ),

	.img_size      (usdSize),
	.img_mounted   (usdMntd),

	.ps2_kbd_clk   (),
	.ps2_kbd_data  (),
	.ps2_kbd_clk_i (1'b0),
	.ps2_kbd_data_i(1'b0),
	.ps2_mouse_clk (),
	.ps2_mouse_data(),
	.ps2_mouse_clk_i(1'b0),
	.ps2_mouse_data_i(1'b0),

	.key_code      (keyCode),
	.key_strobe    (keyStrobe),
	.key_pressed   (keyPressed),
	.key_extended  (),

	.mouse_x       (mouse_x),
	.mouse_y       (mouse_y),
	.mouse_z       (),
	.mouse_idx     (),
	.mouse_flags   (mouse_f),
	.mouse_strobe  (),

	.serial_data   (8'd0),
	.serial_strobe (1'd0)
);

assign boot = F11 && (ctrl || alt || bspc) && !status[9];

//-------------------------------------------------------------------------------------------------

assign model = status[3];
assign mapper = status[5:4] == 0;
assign sdcard = status[5:4] == 0 || status[5:4] == 1;

//-------------------------------------------------------------------------------------------------

reg modeld, modelp;
always @(posedge clock) begin modeld <= model; modelp <= modeld != model; end

assign reset = power && init && F9 && (ctrl || alt || del) && btn[0] && !status[1] && !modelp;
assign nmi = F5 && btn[1] && !status[2];

//-------------------------------------------------------------------------------------------------

wire[OSD_PIXEL_MSB:0] osdRi = irgb[3*(OSD_PIXEL_MSB+1)-1:2*(OSD_PIXEL_MSB+1)];
wire[OSD_PIXEL_MSB:0] osdGi = irgb[2*(OSD_PIXEL_MSB+1)-1:OSD_PIXEL_MSB+1];
wire[OSD_PIXEL_MSB:0] osdBi = irgb[OSD_PIXEL_MSB: 0];

wire[OSD_PIXEL_MSB:0] osdRo;
wire[OSD_PIXEL_MSB:0] osdGo;
wire[OSD_PIXEL_MSB:0] osdBo;

osd #(.OSD_AUTO_CE(1'b0)) osd
(
	.clk_sys(clock  ),
	.ce     (cepix[0]),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.VSync  (isync[1]),
	.HSync  (isync[0]),
	.R_in   (osdRi  ),
	.G_in   (osdGi  ),
	.B_in   (osdBi  ),
	.R_out  (osdRo  ),
	.G_out  (osdGo  ),
	.B_out  (osdBo  )
);

wire[RGBW-1:0] sdbirgb = { osdRo, osdGo, osdBo };

wire[ 1:0] sdbosync;
wire[RGBW-1:0] sdborgb;

scandoubler #(.RGBW(RGBW)) Scandoubler
(
	.clock  (clock   ),
	.enable (!rgb    ),
	.ice    (cepix[0]),
	.iblank (iblank  ),
	.isync  (isync   ),
	.irgb   (sdbirgb ),
	.oce    (cepix[1]),
	.oblank (oblank  ),
	.osync  (osync   ),
	.orgb   (orgb    )
);

//-------------------------------------------------------------------------------------------------

assign strb = keyStrobe;
assign make = !keyPressed;
assign code = keyCode;

reg F5 = 1'b1, F9 = 1'b1, F11 = 1'b1;
reg alt = 1'b1, del = 1'b1, ctrl = 1'b1, bspc = 1'b1;

always @(posedge clock) if(strb)
	case(code)
		8'h01: F9 <= make;
		8'h03: F5 <= make;
		8'h78: F11 <= make;
		8'h11: alt <= make;
		8'h71: del <= make;
		8'h14: ctrl <= make;
		8'h66: bspc <= make;
	endcase

//-------------------------------------------------------------------------------------------------

assign xaxis = mouse_x[7:0];
assign yaxis = mouse_y[7:0];
assign mbtns = { mouse_f[3], mouse_f[0], mouse_f[1] };

//-------------------------------------------------------------------------------------------------

sd_card sd_card
(
	.clk_sys     (clock     ),
	.sd_rd       (usdRd     ),
	.sd_wr       (usdWr     ),
	.sd_ack      (usdAck    ),
	.sd_ack_conf (usdAckConf),
	.sd_lba      (usdLba    ),
	.sd_conf     (usdConf   ),
	.sd_sdhc     (usdSdHc   ),
	.img_size    (usdSize   ),
	.img_mounted (usdMntd   ),
	.sd_busy     (          ),
	.sd_buff_addr(usdA      ),
	.sd_buff_din (usdD      ),
	.sd_buff_dout(usdQ      ),
	.sd_buff_wr  (usdStrbQ  ),
	.allow_sdhc  (1'b1      ),
	.sd_cs       (sdvCs     ),
	.sd_sck      (sdvCk     ),
	.sd_sdi      (sdvMosi   ),
	.sd_sdo      (sdvMiso   )
);

//-------------------------------------------------------------------------------------------------

wire ioctlDl;
wire ioctlWr;
wire[24:0] ioctlA;
wire[ 7:0] ioctlD;

data_io data_io
(
	.clk_sys       (clock   ),
	.clkref_n      (1'b0    ),
	.SPI_SCK       (spiCk   ),
	.SPI_SS2       (spiSs2  ),
	.SPI_SS4       (spiSs4  ),
	.SPI_DI        (spiMosi ),
	.SPI_DO        (spiMiso ),
	.ioctl_download(ioctlDl ),
	.ioctl_upload  (        ),
	.ioctl_index   (        ),
	.ioctl_wr      (ioctlWr ),
	.ioctl_addr    (ioctlA  ),
	.ioctl_din     (8'h00   ),
	.ioctl_dout    (ioctlD  ),
	.ioctl_fileext (        ),
	.ioctl_filesize(        )
);

assign init = !ioctlDl;
assign iniW = ioctlWr;
assign iniA = ioctlA[18:0];
assign iniD = ioctlD;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
