//-------------------------------------------------------------------------------------------------
module cpu
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ne,
	input  wire       pe,
	input  wire       reset,
	output wire       iorq,
	output wire       mreq,
	output wire       rfsh,
	input  wire       irq,
	input  wire       nmi,
	output wire       m1,
	output wire       rd,
	output wire       wr,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,
	output wire[15:0] a
);
//-------------------------------------------------------------------------------------------------
T80pa Cpu
(
	.CLK    (clock  ),
	.CEN_n  (ne     ),
	.CEN_p  (pe     ),
	.RESET_n(reset  ),
	.BUSRQ_n(1'b1   ),
	.WAIT_n (1'b1   ),
	.BUSAK_n(       ),
	.HALT_n (       ),
	.IORQ_n (iorq   ),
	.MREQ_n (mreq   ),
	.RFSH_n (rfsh   ),
	.INT_n  (irq    ),
	.NMI_n  (nmi    ),
	.M1_n   (m1     ),
	.RD_n   (rd     ),
	.WR_n   (wr     ),
	.A      (a      ),
	.DI     (d      ),
	.DO     (q      ),
	.DIRSet (1'b0   ),
	.OUT0   (1'b0   ),
	.REG    (       ),
	.DIR    (212'd0 )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
