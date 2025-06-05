`timescale 1ns/1ns
`include "defines.v"

module alu_design#(
    parameter w = `DATA_WIDTH
)(
    input clk, rst, ce, mode, Cin,
    input [w-1:0] opa, opb,
    input [1:0] inp_valid,
    input [3:0] cmd,
    output reg [2*w-1:0] result,
    output reg oflow, Cout, G, L, E, Err
);

    localparam n = $clog2(w);

    reg [w-1:0] opa_r, opb_r;
    wire signed [w-1:0] opa_s = $signed(opa_r); // typecasted to signed
    wire signed [w-1:0] opb_s = $signed(opb_r);
    reg [3:0] cmd_r;
    reg mode_r;
    reg [1:0] inp_valid_r;
    reg [n-1:0] rot_amt;

    wire signed [w-1:0] MAX_VAL = {1'b0, {(w-1){1'b1}}};     // addition 127
    wire signed [w-1:0] MIN_VAL = {1'b1, {(w-1){1'b0}}};     // subtraction -128

    // Intermediate result register
    reg [w-1:0] temp_r; // only for rotate
    reg signed [w:0] res_s; // only for signed
    reg signed [w:0] temp_signed;
    reg [2*w-1:0] temp_result;
    reg temp_Cout, temp_oflow, temp_G, temp_L, temp_E, temp_Err;

    // Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            opa_r <= 0;
            opb_r <= 0;
            cmd_r <= 0;
            mode_r <= 0;
            inp_valid_r <= 0;
        end else if (ce) begin
            opa_r <= opa;
            opb_r <= opb;
            cmd_r <= cmd;
            mode_r <= mode;
            inp_valid_r <= inp_valid;
        end else
            Err <= temp_Err;
    end

    // Combinational logic stage
    always @(*) begin
        res_s = 0;
        temp_r = 0;
        temp_result = 0;
        temp_Cout = 0;
        temp_oflow = 0;
        temp_G = 0;
        temp_L = 0;
        temp_E = 0;
        temp_Err = 0;
        rot_amt = opb_r[n-1:0];

        case (inp_valid_r)
            2'b00: temp_Err = 1;

            2'b01: begin // Only A is valid
                if (mode_r) begin // Arithmetic
                    case (cmd_r)
                        `INC_A: begin
                            temp_result = opa_r + 1;
                            temp_Err = (opa_r == {w{1'b1}});
                        end
                        `DEC_A: begin
                            temp_result = opa_r - 1;
                            temp_Err = (opa_r == {w{1'b0}});
                        end
                        default: temp_Err = 1;
                    endcase
                end else begin // Logical
                    case (cmd_r)
                        `NOT_A: temp_result = {{(w){1'b0}},~opa};
                        `SHR1_A: temp_result = {{(w){1'b0}},opa_r >> 1};
                        `SHL1_A: temp_result = {{(w){1'b0}},opa_r << 1};
                        default: temp_Err = 1;
                    endcase
                end
            end

            2'b10: begin // Only B is valid
                if (mode_r) begin
                    case (cmd_r)
                        `INC_B: begin
                            temp_result = opb_r + 1;
                            temp_Err = (opb_r == {w{1'b1}});
                        end
                        `DEC_B: begin
                            temp_result = opb_r - 1;
                            temp_Err = (opb_r == {w{1'b0}});
                        end
                        default: temp_Err = 1;
                    endcase
                end else begin
                    case (cmd_r)
                        `NOT_B: temp_result = {{(w){1'b0}},~opb};
                        `SHR1_B: temp_result = {{(w){1'b0}},opb_r >> 1};
                        `SHL1_B: temp_result = {{(w){1'b0}},opb_r << 1};
                        default: temp_Err = 1;
                    endcase
                end
            end

            2'b11: begin // Both inputs valid
                if (mode_r) begin // Arithmetic
                    case (cmd_r)
                        `ADD: begin
                            temp_result = opa_r + opb_r;
                            temp_Cout = temp_result[w];
                        end
                        `SUB: begin
                            temp_oflow = (opa_r < opb_r);
                            temp_result = opa_r - opb_r;
                        end
                        `ADD_CIN: begin
                            temp_result = opa_r + opb_r + Cin;
                            temp_Cout = temp_result[w];
                        end
                        `SUB_CIN: begin
                            temp_result = opa_r - opb_r - Cin;
                            temp_oflow = (opa_r < opb_r + Cin);
                        end
                        `INC_A: begin
                            temp_result = opa_r + 1;
                            temp_Err = (opa_r == {w{1'b1}});
                        end
                        `DEC_A: begin
                            temp_result = opa_r - 1;
                            temp_Err = (opa_r == {w{1'b0}});
                        end
                        `INC_B: begin
                            temp_result = opb_r + 1;
                            temp_Err = (opb_r == {w{1'b1}});
                        end
                        `DEC_B: begin
                            temp_result = opb_r - 1;
                            temp_Err = (opb_r == {w{1'b0}});
                        end
                        `CMP: begin
                            temp_E = (opa_r == opb_r);
                            temp_G = (opa_r > opb_r);
                            temp_L = (opa_r < opb_r);
                        end
                        `MULT: temp_result = (opa_r + 1) * (opb_r + 1);
                        `SH1_MULT: temp_result = {{w{1'b0}},(opa_r << 1)} * opb_r;
                        `S_ADD: begin
                            res_s = opa_s + opb_s;
                            temp_oflow = (~opa_s[w-1] & ~opb_s[w-1] & res_s[w-1]) |(opa_s[w-1] & opb_s[w-1] & ~res_s[w-1]);
                            temp_Cout = res_s[w];
                            temp_G = (opa_s > opb_s);
                            temp_L = (opa_s < opb_s);
                            temp_E = (opa_s == opb_s);
                            if (temp_oflow) begin
                                if (opa_s[w-1] == 0)
                                    temp_signed = {{1'b0}, MAX_VAL}; // Positive overflow → clamp to MAX
                                else
                                    temp_signed = {{1'b0}, MIN_VAL}; // Negative overflow → clamp to MIN
                            end else begin
                                temp_signed = res_s;
                            end
                        end
                        `S_SUB: begin
                            res_s = opa_s - opb_s;
                            temp_oflow = (opa_s[w-1] != opb_s[w-1]) && (res_s[w-1] != opa_s[w-1]);
                            temp_Cout = res_s[w];
                            temp_G = (opa_s > opb_s);
                            temp_L = (opa_s < opb_s);
                            temp_E = (opa_s == opb_s);
                            if (temp_oflow) begin
                                if (opa_s[w-1] == 0 && opb_s[w-1] == 1)
                                    temp_signed = {{w{1'b0}}, MAX_VAL}; // Positive overflow
                                else
                                    temp_signed = {{w{1'b0}}, MIN_VAL}; // Negative overflow
                            end else begin
                                temp_signed = {{w{res_s[w-1]}}, res_s}; // Sign extend
                            end
                        end
                        default: temp_Err = 1;
                    endcase
                end else begin // Logical
                    case (cmd_r)
                        `AND: temp_result = {{w{1'b0}}, opa_r & opb_r};
                        `NAND: temp_result = {{w{1'b0}}, ~(opa_r & opb_r)};
                        `OR: temp_result = {{w{1'b0}}, opa_r | opb_r};
                        `NOR: temp_result = {{w{1'b0}}, ~(opa_r | opb_r)};
                        `XOR: temp_result = {{w{1'b0}}, opa ^ opb};
                        `XNOR: temp_result = {{w{1'b0}}, ~(opa ^ opb)};
                        `NOT_A: temp_result = {{w{1'b0}}, ~opa};
                        `NOT_B: temp_result = {{w{1'b0}}, ~opb};
                        `SHR1_A: temp_result = {{w{1'b0}}, opa_r >> 1};
                        `SHR1_B: temp_result = {{w{1'b0}}, opb_r >> 1};
                        `SHL1_A: temp_result = {{w{1'b0}}, opa_r << 1};
                        `SHL1_B: temp_result = {{w{1'b0}}, opb_r << 1};
                        `ROL_A_B: begin
                            temp_Err = |opb_r[w-1:n];
                            temp_r = (rot_amt == 0) ? opa_r : (opa_r << rot_amt) | (opa_r >> (w - rot_amt));
                            temp_result = {{w{1'b0}}, temp_r};
                        end
                        `ROR_A_B: begin
                            temp_Err = |opb_r[w-1:n];
                            temp_r = (rot_amt == 0) ? opa_r : (opa_r >> rot_amt) | (opa_r << (w - rot_amt));
                            temp_result = {{w{1'b0}}, temp_r};
                        end
                        default: temp_Err = 1;
                    endcase
                end
            end
            default: temp_Err = 1;
        endcase
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 0;
            Cout <= 0;
            oflow <= 0;
            G <= 0;
            L <= 0;
            E <= 0;
            Err <= 0;
        end else if (ce) begin
            if ((cmd_r == `MULT || cmd_r == `SH1_MULT) && mode_r) begin
                $display("MULT part executed");
                result <= temp_result;
            end else if ((cmd_r == `S_ADD || cmd_r == `S_SUB) && mode_r) begin
                $display("Signed result = %d", $signed(temp_signed));
                result <= {{w{temp_signed[w]}}, temp_signed[w-1:0]};
            end else begin
                $display("Else part executed");
                result <= temp_result;
            end
            Cout <= temp_Cout;
            oflow <= temp_oflow;
            G <= temp_G;
            L <= temp_L;
            E <= temp_E;
            Err <= temp_Err;
        end else
            Err <= temp_Err; // error doesn't depend on CE
    end

endmodule
