	
	initial
		q = 1'hx;
		
	always @(posedge clk)
		q <= d;
	
endmodule
