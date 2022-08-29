//-------------------------------------------------------------------------------------------------
module dcm1
//-------------------------------------------------------------------------------------------------
(
	input  wire clock50,
	output wire clock56,
	output wire locked
);
//-------------------------------------------------------------------------------------------------

wire b1, c1;

DCM_SP #
(
	.CLKIN_PERIOD          (20.000),
	.CLKFX_DIVIDE          (22    ),
	.CLKFX_MULTIPLY        (25    )
)
Dcm1
(
	.RST                   (1'b0),
	.DSSEN                 (1'b0),
	.PSCLK                 (1'b0),
	.PSEN                  (1'b0),
	.PSINCDEC              (1'b0),
	.CLKIN                 (clock50),
	.CLKFB                 (b1),
	.CLK0                  (c1),
	.CLK90                 (),
	.CLK180                (),
	.CLK270                (),
	.CLK2X                 (),
	.CLK2X180              (),
	.CLKFX                 (clock56), // 56.7504 MHz output
	.CLKFX180              (),
	.CLKDV                 (),
	.PSDONE                (),
	.STATUS                (),
	.LOCKED                (locked)
);

BUFG BufgB1(.I(c1), .O(b1));

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
