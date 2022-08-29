//-------------------------------------------------------------------------------------------------
//  Full dual port ram
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
module dprfaw
//-------------------------------------------------------------------------------------------------
#
(
	parameter AW = 0
)
(
	input  wire       clock1,
	input  wire       we1,
	input  wire[AW:0] a1,
	input  wire[ 7:0] d1,
	output reg [ 7:0] q1,
	input  wire       clock2,
	input  wire       we2,
	input  wire[AW:0] a2,
	input  wire[ 7:0] d2,
	output reg [ 7:0] q2
);
//-------------------------------------------------------------------------------------------------

reg[7:0] mem[(2**AW)-1:0];

always @(posedge clock1) if(we1) begin mem[a1] <= d1; q1 <= d1; end else q1 <= mem[a1];
always @(posedge clock2) if(we2) begin mem[a2] <= d2; q2 <= d2; end else q2 <= mem[a2];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
