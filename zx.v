//-------------------------------------------------------------------------------------------------
module zx
//-------------------------------------------------------------------------------------------------
(
	input  wire       model,
	input  wire       divmmc,

	input  wire       clock,
	input  wire       ne7M0,
	input  wire       pe7M0,
	input  wire       ne3M5,
	input  wire       pe3M5,

	input  wire       reset,
	output wire       rfsh,
	input  wire       nmi,

	output wire[13:0] a1,
	input  wire[ 7:0] q1,

	output wire[18:0] a2,
	output wire[ 7:0] d2,
	input  wire[ 7:0] q2,
	output wire       r2,
	output wire       w2,

	output wire       hsync,
	output wire       vsync,
	output wire       r,
	output wire       g,
	output wire       b,
	output wire       i,

	input  wire       ear,
	output wire       midi,
	output wire[14:0] left,
	output wire[14:0] right,

	input  wire[ 4:0] col,
	output wire[ 7:0] row,

	input  wire[ 7:0] joy1,
	input  wire[ 7:0] joy2,

	input  wire[ 2:0] mbtns,
	input  wire[ 7:0] xaxis,
	input  wire[ 7:0] yaxis,

	output wire       sdcCs,
	output wire       sdcCk,
	output wire       sdcMosi,
	input  wire       sdcMiso
);
//--- io ------------------------------------------------------------------------------------------

	wire iorq;
	wire mreq;
	wire irq;
	wire m1;
	wire rd;
	wire wr;

	wire[15:0] a;
	wire[ 7:0] q;

	wire iorq7FFD = !iorq && !a[15] && !a[1] && model;
	wire iorqFFFD = !iorq && a[15] && a[14] && !a[1];
	wire iorqFADF = !iorq && a[ 9:8] == 2'b10  && !a[5]; // kempston mouse buttons
	wire iorqFBDF = !iorq && a[10:8] == 3'b011 && !a[5]; // kempston mouse x axis
	wire iorqFFDF = !iorq && a[10:8] == 3'b111 && !a[5]; // kempston mouse y axis
	wire iorq1F = !iorq && !a[7] && !a[6] && !a[5];      // kempston joystick 1
	wire iorq37 = !iorq && !a[7] && !a[6] && !a[3];      // kempston joystick 2
	wire iorqEB = !iorq && a[7:0] == 8'hEB;
	wire iorqFE = !iorq && !a[0];

	reg[5:0] data7FFD;
	always @(posedge clock, negedge reset)
		if(!reset) data7FFD <= 1'd0; else if(pe3M5) if(iorq7FFD && !wr) data7FFD <= { data7FFD[5]|q[5], q[4:0] };

	reg[4:0] dataFE;
	always @(posedge clock)
		if(pe7M0) if(iorqFE && !wr) dataFE <= q[4:0];

//--- video ---------------------------------------------------------------------------------------

	wire[ 2:0] border = dataFE[2:0];
	wire[12:0] va;
	wire       vc;
	wire       fb;

	vdu vdu
	(
		.model  (model  ),
		.clock  (clock  ),
		.ce     (ne7M0  ),
		.border (border ),
		.irq    (irq    ),
		.va     (va     ),
		.vd     (q1     ),
		.vc     (vc     ),
		.fb     (fb     ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.r      (r      ),
		.g      (g      ),
		.b      (b      ),
		.i      (i      )
	);

	assign a1 = { data7FFD[3], va[12:7], !rfsh && !a[15] && a[14] ? a[6:0] : va[6:0] };

//--- turbosound ----------------------------------------------------------------------------------

	wire[ 7:0] tbsQ;
	wire[14:0] tbsL;
	wire[14:0] tbsR;

	turbosound turbosound(clock, pe3M5, reset, iorq, wr, rd, { a[15:14], a[1] }, q, tbsQ, tbsL, tbsR, midi);

//--- contention ----------------------------------------------------------------------------------

	wire nc3M5 = ne3M5 && !contend;
	wire pc3M5 = pe3M5 && !contend;

	reg mreqt23iorqtw3;
	always @(posedge clock) if(pc3M5) mreqt23iorqtw3 <= mreq && !iorqFE;

	reg clk35;
	always @(posedge clock) if(ne7M0) clk35 <= !(clk35 && !contend);

	wire contend = clk35 && vc && mreqt23iorqtw3 && ((!a[15] && a[14]) || iorqFE);

//--- divmmc --------------------------------------------------------------------------------------

	wire      mapped;
	wire      ramcs;
	wire[3:0] page;

	mapper mapper
	(
		.enable (divmmc ),
		.clock  (clock  ),
		.ce     (pc3M5  ),
		.mapped (mapped ),
		.ramcs  (ramcs  ),
		.page   (page   ),
		.reset  (reset  ),
		.iorq   (iorq   ),
		.mreq   (mreq   ),
		.m1     (m1     ),
		.wr     (wr     ),
		.a      (a      ),
		.d      (q      )
	);

	wire[7:0] sdcQ;

	sdc sdc
	(
		.enable (divmmc ),
		.clock  (clock  ),
		.ce     (pe3M5  ),
		.cen    (ne7M0  ),
		.cep    (pe7M0  ),
		.reset  (reset  ),
		.iorq   (iorq   ),
		.rd     (rd     ),
		.wr     (wr     ),
		.a      (a[7:0] ),
		.d      (q      ),
		.q      (sdcQ   ),
		.cs     (sdcCs  ),
		.ck     (sdcCk  ),
		.mosi   (sdcMosi),
		.miso   (sdcMiso)
	);

//--- memory --------------------------------------------------------------------------------------

	wire[2:0] romPage = mapped ? 3'd4 : { 1'b0, model, data7FFD[4] };
	wire[2:0] ramPage = a[15] ? (a[14] ? data7FFD[2:0] : 3'd2) : 3'd5;

	assign a2 = a[15:14] ? { 2'd2, ramPage, a[13:0] } : mapped && ramcs ? { 2'd1, page, a[12:0] } : { 2'd0, romPage, a[13:0] };
	assign d2 = q;
	assign r2 = !mreq && !rd;
	assign w2 = !mreq && !wr && (a[15:14] || (mapped && a[13]));

//--- cpu -----------------------------------------------------------------------------------------

	wire[ 7:0] d
		= !mreq ? q2
		: iorqFFFD ? tbsQ
		: iorqFADF ? { 5'h1F, mbtns }
		: iorqFBDF ? xaxis
		: iorqFFDF ? yaxis
		: iorq1F ? joy1
		: iorq37 ? joy2
		: iorqEB ? sdcQ
		: iorqFE ? { 1'b1, ear|dataFE[4], 1'b1, col }
		: !iorq && fb ? q1
		: 8'hFF;

	cpu cpu
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

	wire[11:0] sound = dataFE[4:3] == 3 ? 12'd4095 : dataFE[4:3] == 2 ? 12'd3874 : dataFE[4:3] == 1 ? 12'd775 : 12'd0;

	assign left  = { 3'd0, sound }+tbsL;
	assign right = { 3'd0, sound }+tbsR;

	assign row = a[15:8];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
