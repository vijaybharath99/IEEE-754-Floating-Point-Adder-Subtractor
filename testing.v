module test_float();
    wire[31:0] out;
    wire done;
    reg[31:0] inp1, inp2;
    reg[2:0] opt;
    reg clk, reset, start;
    floating_alu dut(out, done, inp1, inp2, opt, clk, start, reset);
    initial begin
        clk = 0; start = 0; opt = 0; reset = 1; #3 start = 1; reset = 0;
        #10 inp1 = 32'b01000000000010000000111010111111; inp2 = 32'b01000000101011011001100110011010;
        #10 opt = 1;
        #400 $finish;
        end
        
        always #5 clk = ~clk;
        
        initial $monitor("out = %b, %b", out, dut.state);
endmodule
        
        