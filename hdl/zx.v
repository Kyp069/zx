//-------------------------------------------------------------------------------------------------
module zx
//-------------------------------------------------------------------------------------------------
(
	input  wire       model,  // 0 = 48K, 1 = 128K
	input  wire       mapper, // 0 = off, 1 = on
	input  wire       sdcard, // 0 = off, 1 = on

	input  wire       clock,  // clock 56 MHz
	input  wire       power,
	input  wire       reset,
	input  wire       nmi,

	output wire       hblank,  // video
	output wire       vblank,
	output wire       hsync,
	output wire       vsync,
	output wire       r,
	output wire       g,
	output wire       b,
	output wire       i,

	input  wire       ear,    // audio
	output wire       midi,
	output wire[14:0] left,
	output wire[14:0] right,

	input  wire[ 4:0] col,    // membrane
	output wire[ 7:0] row,

	input  wire       strb,   // keyboard
	input  wire       make,
	input  wire[ 7:0] code,

	input  wire[ 7:0] xaxis,  // mouse
	input  wire[ 7:0] yaxis,
	input  wire[ 2:0] mbtns,

	input  wire[ 7:0] joy,    // joystic

	output wire       cs,     // uSD
	output wire       ck,
	output wire       mosi,
	input  wire       miso,

	output wire       cecpu,  // clock enables
	output wire       cep1x,
	output wire       cep2x,

	output wire       memRf,  // memory
	output wire       memRd,
	output wire       memWr,
	output wire[18:0] memA1,
	output wire[ 7:0] memD1,
	input  wire[ 7:0] memQ1,
	output wire[13:0] memA2,
	input  wire[ 7:0] memQ2
);
//-------------------------------------------------------------------------------------------------

wire addr00 = !a[15] && !a[14];
wire addr01 = !a[15] &&  a[14];
wire addr10 =  a[15] && !a[14];
wire addr11 =  a[15] &&  a[14];

wire ioFE   = !(!iorq && !a[0]);                    // ula
wire ioDF   = !(!iorq && !a[5]);                    // kempston
wire ioEB   = !(!iorq && a[7:0] == 8'hEB);          // usd
wire ioFFFD = !(!iorq && addr11 && !a[1]);          // psg
wire io7FFD = !(!iorq && !a[15] && !a[1] && model); // 128K mapping

//wire ioFFDF = !(!iorq &&  a[10] && a[9] &&  a[8] && !a[5]); // y-axis  65503 FFDF xxxxx111 xx0xxxxx
//wire ioFBDF = !(!iorq && !a[10] && a[9] &&  a[8] && !a[5]); // x-axis  64479 FBDF xxxxx011 xx0xxxxx
//wire ioFADF = !(!iorq &&           a[9] && !a[8] && !a[5]); // buttons 64223 FADF xxxxxx10 xx0xxxxx

//-------------------------------------------------------------------------------------------------

reg ne14M;
reg ne7M0, pe7M0;
reg ne3M5, pe3M5;

reg[3:0] ce = 1;
always @(negedge clock) if(power) begin
	ce <= ce+1'd1;
	ne14M <= ~ce[0] & ~ce[1];
	ne7M0 <= ~ce[0] & ~ce[1] & ~ce[2];
	pe7M0 <= ~ce[0] & ~ce[1] &  ce[2];
	ne3M5 <= ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];
	pe3M5 <= ~ce[0] & ~ce[1] & ~ce[2] &  ce[3];
end

//-------------------------------------------------------------------------------------------------

reg mreqt23iorqtw3;
always @(posedge clock) if(pc3M5) mreqt23iorqtw3 <= mreq & ioFE;

reg clk35;
always @(posedge clock) if(ne7M0) clk35 <= !(clk35 && contend);

wire memC = addr01 || (model && addr11 && ramPage[0]);
wire contend = !(clk35 && vduC && mreqt23iorqtw3 && (memC || !ioFE));

wire pc3M5 = pe3M5 & contend;
wire nc3M5 = ne3M5 & contend;

//-------------------------------------------------------------------------------------------------

reg irq = 1'b1;
always @(posedge clock) if(pc3M5) irq <= vduI;

wire iorq, mreq, rfsh, m1, rd, wr;

wire[15:0] a;
wire[ 7:0] d;
wire[ 7:0] q;

cpu Cpu
(
	.clock  (clock  ),
	.ne     (nc3M5  ),
	.pe     (pc3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.rfsh   (rfsh   ),
	.irq    (irq    ),
	.nmi    (nmi    ),
	.m1     (m1     ),
	.rd     (rd     ),
	.wr     (wr     ),
	.a      (a      ),
	.d      (d      ),
	.q      (q      )
);

//-------------------------------------------------------------------------------------------------

reg[4:0] portFE;
always @(posedge clock) if(pe7M0) if(!ioFE && !wr) portFE <= q[4:0];

wire mic = portFE[3];
wire speaker = portFE[4];
wire[2:0] border = portFE[2:0];

//-------------------------------------------------------------------------------------------------

wire io7FFDwr = !(!io7FFD && !wr);

reg io7FFDwrd;
reg[5:0] port7FFD, port7FFDd;
always @(posedge clock, negedge reset)
	if(!reset) begin
		port7FFD <= 1'd0;
		port7FFDd <= 1'd0;
		io7FFDwrd <= 1'b1;
	end
	else if(nc3M5) begin
		io7FFDwrd <= io7FFDwr;
		port7FFDd <= q[5:0];
		if(model && io7FFDwr && !io7FFDwrd && !port7FFD[5]) port7FFD <= port7FFDd;
	end

wire      vmmPage = port7FFD[3];
wire[2:0] romPage = { 1'b0, model, port7FFD[4] };
wire[2:0] ramPage = addr01 ? 3'd5 : addr10 ? 3'd2 : model ? port7FFD[2:0] : { a[15:14], 1'b0 };

//-------------------------------------------------------------------------------------------------

wire map, mapRam;
wire[3:0] mapPage;

mapper Mapper
(
	.mapper (mapper ),
	.clock  (clock  ),
	.reset  (reset  ),
	.ce     (pc3M5  ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.m1     (m1     ),
	.wr     (wr     ),
	.a      (a      ),
	.d      (q      ),
	.map    (map    ),
	.ram    (mapRam ),
	.page   (mapPage)
);

wire sysrom = addr00 && !map;
wire sysram = a[15] || a[14];
wire esxrom = addr00 && map && !a[13] && !mapRam;
wire esxram = addr00 && map && (a[13] || mapRam);

assign memRf = !rfsh;
assign memRd = !mreq && !rd;
assign memWr = !mreq && !wr && (a[15] || a[14] || (map && a[13]));
assign memD1 = q;

assign memA1
	= sysrom ? { 2'b00, romPage, a[13:0] }
	: esxrom ? { 2'b00, 4'b1000, a[12:0] }
	: sysram ? { 2'b01, ramPage, a[13:0] }
	: esxram ? { 2'b10, mapPage, a[12:0] }
	: 8'hFF;
assign memA2 = { vmmPage, vduA[12:7], !rfsh && addr01 ? a[6:0] : vduA[6:0] };

//-------------------------------------------------------------------------------------------------

wire       vduI;
wire       vduC;
wire[12:0] vduA;
wire[ 7:0] vduD = memQ2;
wire[ 7:0] vduQ;

video Video
(
	.model  (model  ),
	.clock  (clock  ),
	.ce     (ne7M0  ),
	.border (border ),
	.irq    (vduI   ),
	.cn     (vduC   ),
	.a      (vduA   ),
	.d      (vduD   ),
	.q      (vduQ   ),
	.hblank (hblank ),
	.vblank (vblank ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.i      (i      )
);

//-------------------------------------------------------------------------------------------------

wire[ 2:0] psgA = { a[15:14], a[1] };
wire[ 7:0] psgD = q;
wire[ 7:0] psgQ;

wire[11:0] a1, b1, c1;
wire[11:0] a2, b2, c2;

turbosound Turbosound
(
	.clock  (clock  ),
	.ce     (pe3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.a      (psgA   ),
	.d      (psgD   ),
	.q      (psgQ   ),
	.a1     (a1     ),
	.b1     (b1     ),
	.c1     (c1     ),
	.a2     (a2     ),
	.b2     (b2     ),
	.c2     (c2     ),
	.midi   (midi   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] spdA = a[7:0];
wire[7:0] spdQ;

specdrum Specdrum
(
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (spdA   ),
	.d      (q      ),
	.q      (spdQ   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] sbxA = a[7:0];
wire[7:0] sbxQ;

soundbox SoundBox
(
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (sbxA   ),
	.d      (q      ),
	.q      (sbxQ   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] sdvA = a[7:0];
wire[7:0] sdvL1, sdvL2, sdvR1, sdvR2;

soundrive SounDrive
(
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.a      (sdvA   ),
	.d      (q      ),
	.l1     (sdvL1  ),
	.l2     (sdvL2  ),
	.r1     (sdvR1  ),
	.r2     (sdvR2  )
);

//-------------------------------------------------------------------------------------------------

wire saaCs = !(!iorq && !wr && a[7:0] == 8'hFF);
wire saaA0 = a[8];

wire[7:0] saaD = q;

wire[7:0] saaL;
wire[7:0] saaR;

reg[3:0] ce8;
wire ce8M0 = !ce8;
always @(negedge clock) if(ce8 == 6) ce8 <= 1'd0; else ce8 <= ce8+1'd1;

saa1099 SAA
(
	.clk_sys(clock  ),
	.ce     (ce8M0  ),
	.rst_n  (reset  ),
	.cs_n   (saaCs  ),
	.wr_n   (saaCs  ),
	.a0     (saaA0  ),
	.din    (saaD   ),
	.out_l  (saaL   ),
	.out_r  (saaR   )
);

//-------------------------------------------------------------------------------------------------

audio Audio
(
	.ear    (ear    ),
	.mic    (mic    ),
	.speaker(speaker),
	.a1     (a1     ),
	.b1     (b1     ),
	.c1     (c1     ),
	.a2     (a2     ),
	.b2     (b2     ),
	.c2     (c2     ),
	.spdQ   (spdQ   ),
	.sbxQ   (sbxQ   ),
	.sdvL1  (sdvL1  ),
	.sdvL2  (sdvL2  ),
	.sdvR1  (sdvR1  ),
	.sdvR2  (sdvR2  ),
	.saaL   (saaL   ),
	.saaR   (saaR   ),
	.left   (left   ),
	.right  (right  )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] keyA = a[15:8];
wire[4:0] keyQ;

keyboard Keyboard
(
	.clock  (clock  ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.a      (keyA   ),
	.q      (keyQ   )
);

assign row = a[15:8];
wire[4:0] mbrQ = { &(row|{8{col[4]}}), &(row|{8{col[3]}}), &(row|{8{col[2]}}), &(row|{8{col[1]}}), &(row|{8{col[0]}}) };

//-------------------------------------------------------------------------------------------------

wire[7:0] usdQ;
wire[7:0] usdA = a[7:0];

usd uSD
(
	.sdcard (sdcard ),
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.cep    (pe7M0  ),
	.cen    (ne7M0  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.q      (usdQ   ),
	.a      (usdA   ),
	.cs     (cs     ),
	.ck     (ck     ),
	.mosi   (mosi   ),
	.miso   (miso   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] qDF
	= a[ 9:8] ==  2'b10 ? { vduQ[7:3], mbtns }
	: a[10:8] == 3'b011 ? xaxis
	: a[10:8] == 3'b111 ? yaxis
	: joy;

assign d
	= !mreq   ? memQ1
	: !ioDF   ? qDF
	: !ioEB   ? usdQ
	: !ioFE   ? { 1'b1, ear|speaker, 1'b1, keyQ & mbrQ }
	: !ioFFFD ? psgQ
	: vduQ;

//-------------------------------------------------------------------------------------------------

assign cecpu = pc3M5;
assign cep1x = ne7M0;
assign cep2x = ne14M;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
