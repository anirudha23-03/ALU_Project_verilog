`timescale 1ns/1ns
`include "defines.v"

module test_vector_alu;

    integer file;
    parameter w = `DATA_WIDTH;
    parameter TOTAL_w = 5*w + 17;

    reg [w-1:0] feature_id;
    reg [1:0] reserved_bits;
    reg clk,rst, ce, mode, cin;
    reg [1:0] ip_v;
    reg [3:0] cmd;
    reg [w-1:0] opa, opb;

    reg [2*w-1:0] full_res;
    reg [2*w-1:0] expected_res;
    reg expected_cout;
    reg [2:0]expected_egl;
    reg expected_overflow;
    reg expected_error;
    //reg [TOTAL_w:0] test_vector;

task calculate_expected_results;
    input rst, ce, mode, cin;
    input [1:0] ip_v;
    input [3:0] cmd;
    input [w-1:0] opa, opb;

    output reg [2*w-1:0] expected_res;
    output reg expected_cout;
    output reg [2:0]expected_egl;
    output reg expected_overflow;
    output reg expected_error;

    // Local variables
    integer rot_amt;
    reg signed [w:0] s_temp;
    reg signed [w-1:0] opa_s, opb_s;
    reg signed [w:0] s_res;
    reg signed [w-1:0] MAX_VAL, MIN_VAL;

    begin
        // Defaults
        expected_res = 0;
        expected_cout = 0;
        expected_egl = 3'b0;
        expected_overflow = 0;
        expected_error = 0;
        if(rst)begin
                 expected_res = 0;                                                                                                                    expected_cout = 0;                                                                                                                   expected_egl = 3'b0;                                                                                                                 expected_overflow = 0;                                                                                                               expected_error = 0;
        end else if (ce)begin
        opa_s = $signed(opa);
        opb_s = $signed(opb);
        rot_amt = opb[$clog2(w)-1:0]; // Only lower bits for rotation

        MAX_VAL = {1'b0, {(w-1){1'b1}}}; // e.g., 127 for w=8
        MIN_VAL = {1'b1, {(w-1){1'b0}}}; // e.g., -128 for w=8

        case (ip_v)
            2'b00: expected_error = 1;

            2'b01: begin
                if (mode) begin
                    case (cmd)
                        `INC_A: begin
                            expected_res = opa + 1;
                            expected_error = (opa == {w{1'b1}});
                        end
                        `DEC_A: begin
                            expected_res = opa - 1;
                            expected_error = (opa == {w{1'b0}});
                        end
                        default: expected_error = 1;
                    endcase
                end else begin
                    case (cmd)
                        `NOT_A: expected_res = {{w{1'b0}}, ~opa};
                        `SHR1_A: expected_res = {{w{1'b0}}, opa >> 1};
                        `SHL1_A: expected_res = {{w{1'b0}}, opa << 1};
                        default: expected_error = 1;
                    endcase
                end
            end

            2'b10: begin
                if (mode) begin
                    case (cmd)
                        `INC_B: begin
                            expected_res = opb + 1;
                            expected_error = (opb == {w{1'b1}});
                        end
                        `DEC_B: begin
                            expected_res = opb - 1;
                            expected_error = (opb == {w{1'b0}});
                        end
                        default: expected_error = 1;
                    endcase
                end else begin
                    case (cmd)
                        `NOT_B: expected_res = {{w{1'b0}}, ~opb};
                        `SHR1_B: expected_res = {{w{1'b0}}, opb >> 1};
                        `SHL1_B: expected_res = {{w{1'b0}}, opb << 1};
                        default: expected_error = 1;
                    endcase
                end
            end

            2'b11: begin
                if (mode) begin
                    case (cmd)
                        `ADD: begin
                            expected_res = opa + opb;
                            expected_cout = expected_res[w];
                        end
                        `SUB: begin
                            expected_res = opa - opb;
                            expected_overflow = (opa < opb);
                        end
                        `ADD_CIN: begin
                            expected_res = opa + opb + cin;
                            expected_cout = expected_res[w];
                        end
                        `SUB_CIN: begin
                            expected_res = opa - opb - cin;
                            expected_overflow = (opa < (opb + cin));
                        end
                        `INC_A: begin
                            expected_res = opa + 1;
                            expected_error = (opa == {w{1'b1}});
                        end
                        `DEC_A: begin
                            expected_res = opa - 1;
                            expected_error = (opa == {w{1'b0}});
                        end
                        `INC_B: begin
                            expected_res = opb + 1;
                            expected_error = (opb == {w{1'b1}});
                        end
                        `DEC_B: begin
                            expected_res = opb - 1;
                            expected_error = (opb == {w{1'b0}});
                        end
                        `CMP: begin
                            if (opa == opb) expected_egl = 3'b100;
                            else if(opa > opb)expected_egl = 3'b010;
                            else expected_egl = 3'b001;
                        end
                        `MULT: expected_res = (opa + 1) * (opb + 1);
                        `SH1_MULT: expected_res = {{w{1'b0}},(opa << 1)} * opb;
                        `S_ADD: begin
                            s_res = opa_s + opb_s;
                            expected_cout = s_res[w];
                            if (opa_s == opb_s) expected_egl = 3'b100;
                            else if(opa_s > opb_s)expected_egl = 3'b010;
                            else expected_egl = 3'b001;
                            expected_overflow = (~opa_s[w-1] & ~opb_s[w-1] & s_res[w-1]) |(opa_s[w-1] &  opb_s[w-1] & ~s_res[w-1]);
                            if (expected_overflow) begin
                                if (opa_s[w-1] == 0) // positive overflow
                                        expected_res = {{w{1'b0}}, MAX_VAL};
                                else                 // negative overflow
                                        expected_res = {{w{1'b0}}, MIN_VAL};
                            end else begin
                                        expected_res = {{1{s_res[w-1]}}, s_res[w-1:0]};
                            end
                        end
                        `S_SUB: begin
                            s_res = opa_s - opb_s;
                            expected_cout = s_res[w];
                            if (opa_s == opb_s) expected_egl = 3'b100;
                            else if(opa_s > opb_s)expected_egl = 3'b010;
                            else expected_egl = 3'b001;
                            expected_overflow = (~opa_s[w-1] &  opb_s[w-1] & s_res[w-1]) | (opa_s[w-1] & ~opb_s[w-1] & ~s_res[w-1]);
                            if (expected_overflow) begin
                                if (opa_s[w-1] == 0)  // positive operand - negative = positive overflow
                                        expected_res = {{w{1'b0}}, MAX_VAL};
                                else                  // negative operand - positive = negative overflow
                                        expected_res = {{w{1'b0}}, MIN_VAL};
                            end else begin
                                        expected_res = {{1{s_res[w-1]}}, s_res[w-1:0]};
                            end
                        end
                        default: expected_error = 1;
                    endcase
                end else begin
                    case (cmd)
                        `AND: expected_res = {{w{1'b0}}, opa & opb};
                        `NAND: expected_res = {{w{1'b0}}, ~(opa & opb)};
                        `OR: expected_res = {{w{1'b0}}, opa | opb};
                        `NOR: expected_res = {{w{1'b0}}, ~(opa | opb)};
                        `XOR: expected_res = {{w{1'b0}}, opa ^ opb};
                        `XNOR: expected_res = {{w{1'b0}}, ~(opa ^ opb)};
                        `NOT_A: expected_res = {{w{1'b0}}, ~opa};
                        `NOT_B: expected_res = {{w{1'b0}}, ~opb};
                        `SHR1_A: expected_res = {{w{1'b0}}, opa >> 1};
                        `SHR1_B: expected_res = {{w{1'b0}}, opb >> 1};
                        `SHL1_A: expected_res = {{w{1'b0}}, opa << 1};
                        `SHL1_B: expected_res = {{w{1'b0}}, opb << 1};
                        `ROL_A_B: begin
                            expected_error = |opb[w-1:$clog2(w)];
                            expected_res = {{w{1'b0}}, (rot_amt == 0) ? opa :
                                            (opa << rot_amt) | (opa >> (w - rot_amt))};
                        end
                        `ROR_A_B: begin
                            expected_error = |opb[w-1:$clog2(w)];
                            expected_res = {{w{1'b0}}, (rot_amt == 0) ? opa :
                                            (opa >> rot_amt) | (opa << (w - rot_amt))};
                        end
                        default: expected_error = 1;
                    endcase
                end
            end

            default: expected_error = 1;
        endcase
        end else
                expected_error = 1;
    end
endtask


    task create_test_vector;
        input [w-1:0] fid;
        input rst_in, ce_in;
        input [1:0] inp_valid;
        input mode_in;
        input [3:0] command;
        input [w-1:0] op_a, op_b;
        input c_in;

        reg cout_tmp, oflow_tmp, err_tmp;
        reg [2:0]egl_tmp;
        reg [2*w-1:0] res_tmp;

        begin
            feature_id = fid;
            rst = rst_in;
            ce = ce_in;
            ip_v = inp_valid;
            mode = mode_in;
            cmd = command;
            opa = op_a;
            opb = op_b;
            cin = c_in;
            reserved_bits = 2'b00;
            calculate_expected_results(rst_in,ce_in,mode_in,c_in,inp_valid,command,op_a, op_b,res_tmp, cout_tmp,egl_tmp,oflow_tmp, err_tmp);
            expected_cout = cout_tmp;
            expected_overflow = oflow_tmp;
            expected_error = err_tmp;
            expected_egl = egl_tmp;
            expected_res = res_tmp;

            //test_vector = {feature_id,reserved_bits,rst,ce,ip_v,mode,cmd,opa,opb,cin,expected_res,expected_cout,expected_egl,expected_overflow,expected_error};
        $fdisplay(file,"%b_%b_%b_%b_%b_%b_%b_%b_%b_%b_%b_%b_%b_%b_%b",feature_id,reserved_bits,rst,ce,ip_v,mode,cmd,opa,opb,cin,expected_res,expected_cout,expected_egl,expected_overflow,expected_error);
        $display("\nfid: %d, cmd: %b, expected RES: %b, expected COUT: %b, expected EGL:%b, OFLOW: %b, ERR: %b",feature_id, cmd, expected_res, expected_cout,expected_egl, expected_overflow, expected_error);
        end
    endtask

    task create_corner_test_vector(input [w-1:0] fid);
    begin
        case (fid)
            46:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b0, 4'b0000, 8'b00000010, 8'b11110001, 1'b0);//only a operand valid
            47:  create_test_vector(fid, 1'b0, 1'b1, 2'b00, 1'b0, 4'b0001, 8'b00000001, 8'b00000001, 1'b0);//both invalid
            48:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b0, 4'b0010, 8'b00000100, 8'b00000010, 1'b0);//only b operand valid
            49:  create_test_vector(fid, 1'b1, 1'b1, 2'b11, 1'b0, 4'b0011, 8'b11111111, 8'b11111111, 1'b0);//rst = 1
            50:  create_test_vector(fid, 1'b0, 1'b0, 2'b11, 1'b0, 4'b0100, 8'b10101010, 8'b11001100, 1'b0);//ce = 0
            51:  create_test_vector(fid, 1'b0, 1'b0, 2'b11, 1'b0, 4'b0101, 8'b11110000, 8'b00001111, 1'b0);//ce = 0
            52:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b0, 4'b0110, 8'b10101010, 8'b00000000, 1'b0);//only one operand valid
            53:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b0, 4'b0111, 8'b00001111, 8'b00000001, 1'b0);
            54:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b0, 4'b1000, 8'b10000000, 8'b00000001, 1'b0);
            55:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b0, 4'b1001, 8'b11111111, 8'b00000000, 1'b0);
            56:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b0, 4'b1010, 8'b11111111, 8'b00000000, 1'b0);
            57:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b0, 4'b1011, 8'b11111111, 8'b00101010, 1'b0);
            58:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b0, 4'b1100, 8'b00001001, 8'b00011111, 1'b0); //rola_b error case
            59:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b0, 4'b1101, 8'b10001110, 8'b00000111, 1'b0); //rora_b
            60:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0000, 8'b11111111, 8'b00000001, 1'b0); //add carry
            61:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0001, 8'b00101100, 8'b11111111, 1'b0); //sub overflow
            62:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0010, 8'b11111111, 8'b11111111, 1'b1); //add cin
            63:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0011, 8'b00000001, 8'b11111110, 1'b1); //sub cin
            64:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0100, 8'b11111111, 8'b00000001, 1'b0); //inc A
            65:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0101, 8'b00000000, 8'b11111111, 1'b0); //dnc A
            66:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0110, 8'b11111111, 8'b11111111, 1'b0); //inc B
            67:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b0111, 8'b11111111, 8'b00000000, 1'b0); //dec B
            68:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1000, 8'b11111111, 8'b00000001, 1'b0); //compare g
            69:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1000, 8'b11111111, 8'b11111111, 1'b0); //compare e
            70:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1000, 8'b00000001, 8'b11000001, 1'b0); //compare l
            71:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1001, 8'b11111111, 8'b11111111, 1'b0); //+1 mult
            72:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1001, 8'b11111100, 8'b11111001, 1'b0); //+1 mult
            73:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1010, 8'b11111111, 8'b11111111, 1'b0); //shl 1 A
            74:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b11111111, 8'b00000001, 1'b0); //signed add
            75:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1100, 8'b00000000, 8'b10000000, 1'b0); //signed sub
            76:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b1, 4'b0100, 8'b11111111, 8'b10000000, 1'b0);//INC A
            77:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b1, 4'b0101, 8'b00000000, 8'b10000000, 1'b0);//dec A
            78:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b1, 4'b0110, 8'b00000000, 8'b11111111, 1'b0);//inc B
            79:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b1, 4'b0111, 8'b00000110, 8'b00000000, 1'b0);//dec B
            80:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1111, 8'b00000000, 8'b10000000, 1'b0);
            81:  create_test_vector(fid, 1'b0, 1'b1, 2'b10, 1'b1, 4'b1111, 8'b00000000, 8'b10000000, 1'b0);
            82:  create_test_vector(fid, 1'b0, 1'b1, 2'b01, 1'b1, 4'b1111, 8'b00000000, 8'b10000000, 1'b0);
            83:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b0, 4'b1111, 8'b00000000, 8'b10000000, 1'b0);//mode 0 error
            84:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b10000000, 8'b11111111, 1'b0);//-128 + (-1)
            85:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1100, 8'b01111111, 8'b11111111, 1'b0);
            86:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b01111111, 8'b10000101, 1'b0);//127 + 5
            87:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1111, 8'b11111011, 8'b00000011, 1'b0); //-5 -3
            88:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1100, 8'b00001111, 8'b11110111, 1'b0);
            90:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b0, 4'b1100, 8'b10101010, 8'b00000000, 1'b0);//rol
            91:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b0, 4'b1101, 8'b10101010, 8'b00000101, 1'b0);//ror
            92:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b01010000, 8'b01010000, 1'b0);//pos oflow
            93:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b00000100, 8'b00000101, 1'b0);//avoid oflow
            94:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b01111111, 8'b00000001, 1'b0);
            95:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b10000000, 8'b10000000, 1'b0);
            96:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b00000110, 8'b00000001, 1'b0);
            97:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'b1011, 8'b11111100, 8'b00000100, 1'b0);
            98:  create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, 4'd1011, 8'b01000000, 8'b00000001, 1'b0);
            default: ;
        endcase
    end
    endtask

    reg [w-1:0] fid;
    integer d;


    initial begin
    file = $fopen("stimulus.txt", "w");
    fid = 0;
    d = 2**w;

    while (fid < 99) begin
        if (fid < 20) begin // 20 test cases for logical
            for (cmd = 0; cmd <= 4'b1101 && fid < 20; cmd = cmd + 1) begin
                create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b0, cmd, (($random % d + d)%d), (($random % d + d)%d), 1'b0);//rst,ce,ip,mod,cmd,opa,opb,cin
                fid = fid + 1;
            end
        end else if (fid < 40) begin // 20 test cases for arithmetic
            for (cmd = 0; cmd <= 4'b1100 && fid < 40; cmd = cmd + 1) begin
                create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, cmd, $random % d, $random % d, 1'b0);
                fid = fid + 1;
            end
        end else if (fid < 46) begin // 6 test cases for carry-in
            for (cmd = 4'b0010; cmd <= 4'b0011 && fid < 46; cmd = cmd + 1) begin
                create_test_vector(fid, 1'b0, 1'b1, 2'b11, 1'b1, cmd, $random % d, $random % d, 1'b1);
                fid = fid + 1;
            end
        end else begin // 34 corner test cases
            while (fid<99)begin
                create_corner_test_vector(fid);
                fid = fid + 1;
            end
        end
    end

    $display("Generation complete! Total vectors: %0d", fid );
    $fclose(file);
    $finish;
    end
endmodule
