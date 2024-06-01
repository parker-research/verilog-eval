This is a Moore state machine with two states, one input, and one output. Implement this state machine in Verilog. The reset state is B and reset is active-high synchronous.

// B (out=1) --in=0--> A
// B (out=1) --in=1--> B
// A (out=0) --in=0--> B
// A (out=0) --in=1--> A
