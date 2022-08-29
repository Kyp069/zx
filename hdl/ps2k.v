//-------------------------------------------------------------------------------------------------
module ps2k
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	inout  wire[1:0] ps2,
	output reg       strb,
	output reg       make,
	output reg [7:0] code
);
//-------------------------------------------------------------------------------------------------

reg      ps2c;
reg      ps2n;
reg      ps2d;
reg[7:0] ps2f;

always @(posedge clock) begin
	ps2n <= 1'b0;
	ps2d <= ps2[1];
	ps2f <= { ps2[0], ps2f[7:1] };

	if(ps2f == 8'hFF) ps2c <= 1'b1;
	else if(ps2f == 8'h00) begin
		ps2c <= 1'b0;
		if(ps2c) ps2n <= 1'b1;
	end
end

//-------------------------------------------------------------------------------------------------

reg parity;

reg[8:0] data;
reg[3:0] count;

always @(posedge clock) begin
	strb <= 1'b0;
	if(ps2n) begin
		if(count == 4'd0) begin
			parity <= 1'b0;
			if(!ps2d) count <= count+1'd1;
		end
		else if(count < 4'd10) begin
			data <= { ps2d, data[8:1] };
			count <= count+1'd1;
			parity <= parity ^ ps2d;
		end
		else if(ps2d) begin
			count <= 1'd0;
			if(parity) begin
				strb <= 1'b1;
				code <= data[7:0];
			end
		end
		else count <= 1'd0;
	end
end

//-------------------------------------------------------------------------------------------------

always @(posedge clock) if(strb) make <= code == 8'hF0;

//-------------------------------------------------------------------------------------------------

assign ps2 = 2'bZ;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
