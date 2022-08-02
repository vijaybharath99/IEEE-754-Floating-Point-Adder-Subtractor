module floating_alu(out, done, inp1, inp2, opt, clk, start, reset);
    input[31:0] inp1, inp2;
    input start, clk, reset;
    input[2:0] opt;
    output reg[31:0] out;
    output reg done;
    reg[7:0] exp1, exp2;
    reg[22:0] mant1, mant2;
    reg sgn1, sgn2, busy;
    reg[2:0] state, ast, sst;
    reg ovrf, exb1, exb2, exb;
    parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010;
    parameter hold = 3'b000, add = 3'b001, sub = 3'b010, div = 3'b011, mul = 3'b100;
    
    always @(posedge clk or posedge reset)
    begin
        if(reset)
            state <= s0;
        else
            case(state)
                s0 : begin
                    out <= 0; done <= 0; ast <= 0; ovrf = 0; sst <= 0; 
                    if(start) state <= s1;
                    end
                s1 : case(opt)
                    hold : begin
                            state <= s1; 
                            mant1 <= inp1[22:0]; mant2 <= inp2[22:0]; exp1 <= inp1[30:23]; exp2 <= inp2[30:23]; sgn1 <= inp1[31]; sgn2 <= inp2[31]; 
                            exb1 <= inp1[30:23]? 1: 0;
                            exb2 <= inp2[30:23]? 1: 0;
                            exb <= 0;
                           end
                    add : case(ast)     //Floating point addition
                            2'b00 : if(exp1 < exp2)
                                    begin
                                        {exb1,mant1} <= {1'b0,exb1,mant1[22:1]};
                                        exp1 <= exp1 + 1;
                                        ast <= 2'b00;
                                    end
                                    else if(exp1 > exp2)
                                    begin
                                        {exb2,mant2} <= {1'b0,exb2,mant2[22:1]};
                                        exp2 <= exp2 + 1;
                                        ast <= 2'b00;
                                    end
                                    else
                                        case({sgn1, sgn2})
                                            2'b00, 2'b11 : begin
                                                        out[31] <= sgn1;
                                                        out[30:23] <= exp1;
                                                        {ovrf,exb,out[22:0]} <= {{exb1,mant1} + {exb2,mant2}};
                                                        ast <= 2'b01;
                                                    end
                                            2'b01, 2'b10 : begin
                                                        out[30:23] <= exp1;
                                                        {exb,out[22:0]} <= ({exb1,mant1} > {exb2,mant2})? ({exb1,mant1} - {exb2,mant2}): ({exb2,mant2} - {exb1,mant1});
                                                        out[31] <= ({exb1,mant1} > {exb2,mant2})? sgn1: sgn2;
                                                        ast <= 2'b01;
                                                        end
                                        endcase
                            2'b01 : begin       //Output normalization
                                    $display("%b, %b", exb, ovrf);
                                    if(ovrf == 1 && exb == 1)
                                        begin
                                            out[22:0] <= {1'b1, out[22:1]};
                                            out[30:23] <= out[30:23] + 1;
                                            ovrf = 0;
                                            ast <= 2'b01;
                                            state <= s1;
                                        end
                                        else if(exb == 1 && ovrf == 0)
                                        begin
                                            ast <= 2'b10;
                                            state <= s2;
                                        end
                                        else if(exb == 0 && ovrf == 0 && ~(sgn1 ^ sgn2))
                                        begin
                                            out[22:0] <= out[22:0] >> 1;
                                            out[30:23] <= out[30:23] + 1;
                                            ast <= 2'b10;
                                            state <= s2;
                                        end
                                        else if(exb == 0 && ovrf == 0 && (sgn1 ^ sgn2))
                                        begin
                                            $display("hello");
                                            out[22:0] <= out[22:0] << 1;
                                            out[30:23] <= out[30:23] - 1;
                                            ast <= 2'b10;
                                            state <= s2;
                                        end
                                        else if((out[22:0] == 0) | (~out[22:0] == 0))
                                        begin
                                            out <= 0;
                                            ast <= 2'b10;
                                            state <= s2;
                                        end
                                    end
                             2'b10 : ast <= 2'b10;
                          endcase
                    sub : case(sst)     //Floating point subtraction
                            2'b00 : begin sgn2 <= ~sgn2; sst <= 2'b01; end
                            2'b01 : if(exp1 < exp2)
                                    begin
                                        {exb1,mant1} <= {1'b0,exb1,mant1[22:1]};
                                        exp1 <= exp1 + 1;
                                        sst <= 2'b01;
                                    end
                                    else if(exp1 > exp2)
                                    begin
                                        {exb2,mant2} <= {1'b0,exb2,mant2[22:1]};
                                        exp2 <= exp2 + 1;
                                        sst <= 2'b01;
                                    end
                                    else
                                        case({sgn1, sgn2})
                                            2'b00, 2'b11 : begin
                                                        out[31] <= sgn1;
                                                        out[30:23] <= exp1;
                                                        {ovrf,exb,out[22:0]} <= {{exb1,mant1} + {exb2,mant2}};
                                                        sst <= 2'b10;
                                                    end
                                            2'b01, 2'b10 : begin
                                                        out[30:23] <= exp1;
                                                        {exb,out[22:0]} <= ({exb1,mant1} > {exb2,mant2})? ({exb1,mant1} - {exb2,mant2}): ({exb2,mant2} - {exb1,mant1});
                                                        out[31] <= ({exb1,mant1} > {exb2,mant2})? sgn1: sgn2;
                                                        sst <= 2'b10;
                                                        end
                                        endcase
                            2'b10 : begin       //Output normalization
                                    $display("%b, %b", exb, ovrf);
                                    if(ovrf == 1 && exb == 1)
                                        begin
                                            out[22:0] <= {1'b1, out[22:1]};
                                            out[30:23] <= out[30:23] + 1;
                                            ovrf = 0;
                                            sst <= 2'b10;
                                            state <= s1;
                                        end
                                        else if(exb == 1 && ovrf == 0)
                                        begin
                                            sst <= 2'b11;
                                            state <= s2;
                                        end
                                        else if(exb == 0 && ovrf == 0 && ~(sgn1 ^ sgn2))
                                        begin
                                            out[22:0] <= out[22:0] >> 1;
                                            out[30:23] <= out[30:23] + 1;
                                            sst <= 2'b11;
                                            state <= s2;
                                        end
                                        else if(exb == 0 && ovrf == 0 && (sgn1 ^ sgn2))
                                        begin
                                            out[22:0] <= out[22:0] << 1;
                                            out[30:23] <= out[30:23] - 1;
                                            sst <= 2'b11;
                                            state <= s2;
                                        end
                                        else if((out[22:0] == 0) | (~out[22:0] == 0))
                                        begin
                                            out <= 0;
                                            sst <= 2'b10;
                                            state <= s2;
                                        end
                                    end
                             2'b11 : sst <= 2'b11;
                          endcase        
                    default : state <= s0;
                     endcase
                s2 : begin
                        done <= 1; state <= s2;
                     end
            endcase
    end
endmodule            

