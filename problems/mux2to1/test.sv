`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13
module reference_module (
	input a,
	input b,
	input sel,
	output out
);

	assign out = sel ? b : a;
	
endmodule


module stimulus_gen (
	input clk,
	output logic a,b,sel,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable	
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	



	initial begin
		{a, b, sel} <= 3'b000;
		@(negedge clk) wavedrom_start("<b>Sel</b> chooses between <b>a</b> and <b>b</b>");
			@(posedge clk) {a, b, sel} <= 3'b000;
			@(posedge clk) {a, b, sel} <= 3'b100;
			@(posedge clk) {a, b, sel} <= 3'b110;
			@(posedge clk) {a, b, sel} <= 3'b111;
			@(posedge clk) {a, b, sel} <= 3'b011;
			@(posedge clk) {a, b, sel} <= 3'b001;
			@(posedge clk) {a, b, sel} <= 3'b100;
			@(posedge clk) {a, b, sel} <= 3'b101;
			@(posedge clk) {a, b, sel} <= 3'b110;
			@(posedge clk) {a, b, sel} <= 3'b111;
		@(negedge clk) wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			{a,b,sel} <= $random;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic a;
	logic b;
	logic sel;
	logic out_ref;
	logic out_dut;


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	


	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,sel,out_ref,out_dut );
	end


	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b,
		.sel );
	reference_module good1 (
		.a,
		.b,
		.sel,
		.out(out_ref) );
		
	top_module top_module1 (
		.a,
		.b,
		.sel,
		.out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; end

	end
endmodule
