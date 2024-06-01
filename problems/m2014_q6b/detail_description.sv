Consider the state machine shown below:

// A (0) --0--> B
// A (0) --1--> A
// B (0) --0--> C
// B (0) --1--> D
// C (0) --0--> E
// C (0) --1--> D
// D (0) --0--> F
// D (0) --1--> A
// E (1) --0--> E
// E (1) --1--> D
// F (1) --0--> C
// F (1) --1--> D

// Assume that you want to Implement the FSM using three flip-flops and state codes y[3:1] = 000, 001, ..., 101 for states A, B, ..., F, respectively. Implement just the next-state logic for y[2] in Verilog. The output Y2 is y[2].
