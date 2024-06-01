`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13
module reference_module (
	input [3:0] in,
	output reg [1:0] pos
);

	always @(*) begin
		case (in)
			4'h0: pos = 2'h0;
			4'h1: pos = 2'h0;
			4'h2: pos = 2'h1;
			4'h3: pos = 2'h0;
			4'h4: pos = 2'h2;
			4'h5: pos = 2'h0;
			4'h6: pos = 2'h1;
			4'h7: pos = 2'h0;
			4'h8: pos = 2'h3;
			4'h9: pos = 2'h0;
			4'ha: pos = 2'h1;
			4'hb: pos = 2'h0;
			4'hc: pos = 2'h2;
			4'hd: pos = 2'h0;
			4'he: pos = 2'h1;
			4'hf: pos = 2'h0;
			default: pos = 2'b0;
		endcase
	end
	
endmodule


module stimulus_gen (
	input clk,
	output logic [3:0] in, 
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
		@(negedge clk) wavedrom_start("Priority encoder");
			@(posedge clk) in <= 4'h1;
			repeat(4) @(posedge clk) in <= in << 1;
			in <= 0;
			repeat(16) @(posedge clk) in <= in + 1;
		@(negedge clk) wavedrom_stop();

		repeat(50) @(posedge clk, negedge clk) begin
			in <= $urandom;
		end
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_pos;
		int errortime_pos;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [3:0] in;
	logic [1:0] pos_ref;
	logic [1:0] pos_dut;


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	


	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,pos_ref,pos_dut );
	end


	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	reference_module good1 (
		.in,
		.pos(pos_ref) );
		
	top_module top_module1 (
		.in,
		.pos(pos_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_pos) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "pos", stats1.errors_pos, stats1.errortime_pos);
		else $display("Hint: Output '%s' has no mismatches.", "pos");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { pos_ref } === ( { pos_ref } ^ { pos_dut } ^ { pos_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (pos_ref !== ( pos_ref ^ pos_dut ^ pos_ref ))
		begin if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
			stats1.errors_pos = stats1.errors_pos+1'b1; end

	end
endmodule
