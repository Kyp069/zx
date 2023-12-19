//-------------------------------------------------------------------------------------------------
//  ROM
//  Copyright (C) 2022 Kyp069 <kyp069@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//-------------------------------------------------------------------------------------------------
module romzx
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 128
)
(
	input  wire                      clock,
	input  wire[$clog2(KB*1024)-1:0] a,
	output reg [                7:0] q
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[(KB*1024)-1:0] /* synthesis ram_init_file = "../hdl/rom/zx.mif" */;
//initial $readmemh("../rom/zx.hex", mem);

always @(posedge clock) q <= mem[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------