`timescale 1ns/1ns
`include "alu_design.v"
`include "defines.v"
`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 98

module tb_alu #(parameter w = `DATA_WIDTH) ();

    localparam FEATURE_ID_WIDTH    = w;
    localparam RESERVED_WIDTH      = 2;
    localparam RST_WIDTH           = 1;
    localparam CE_WIDTH            = 1;
    localparam IP_V_WIDTH          = 2;
    localparam MODE_WIDTH          = 1;
    localparam CMD_WIDTH           = 4;
    localparam OPA_WIDTH           = w;
    localparam OPB_WIDTH           = w;
    localparam CIN_WIDTH           = 1;
    localparam EXPECTED_RES_WIDTH  = 2 * w;
    localparam COUT_WIDTH          = 1;
    localparam EGL_WIDTH           = 3;
    localparam OV_WIDTH            = 1;
    localparam ERR_WIDTH           = 1;

    localparam TOTAL_WIDTH = 5 * w + 18;

    localparam FEATURE_ID_MSB    = TOTAL_WIDTH - 1;
    localparam FEATURE_ID_LSB    = FEATURE_ID_MSB - FEATURE_ID_WIDTH + 1;

    localparam RESERVED_MSB      = FEATURE_ID_LSB - 1;
    localparam RESERVED_LSB      = RESERVED_MSB - RESERVED_WIDTH + 1;

    localparam RST_MSB           = RESERVED_LSB - 1;
    localparam RST_LSB           = RST_MSB - RST_WIDTH + 1;

    localparam CE_MSB            = RST_LSB - 1;
    localparam CE_LSB            = CE_MSB - CE_WIDTH + 1;

    localparam IP_V_MSB          = CE_LSB - 1;
    localparam IP_V_LSB          = IP_V_MSB - IP_V_WIDTH + 1;

    localparam MODE_MSB          = IP_V_LSB - 1;
    localparam MODE_LSB          = MODE_MSB - MODE_WIDTH + 1;

    localparam CMD_MSB           = MODE_LSB - 1;
    localparam CMD_LSB           = CMD_MSB - CMD_WIDTH + 1;

    localparam OPA_MSB           = CMD_LSB - 1;
    localparam OPA_LSB           = OPA_MSB - OPA_WIDTH + 1;

    localparam OPB_MSB           = OPA_LSB - 1;
    localparam OPB_LSB           = OPB_MSB - OPB_WIDTH + 1;

    localparam CIN_MSB           = OPB_LSB - 1;
    localparam CIN_LSB           = CIN_MSB - CIN_WIDTH + 1;

    localparam EXPECTED_RES_MSB  = CIN_LSB - 1;
    localparam EXPECTED_RES_LSB  = EXPECTED_RES_MSB - EXPECTED_RES_WIDTH + 1;

    localparam COUT_MSB          = EXPECTED_RES_LSB - 1;
    localparam COUT_LSB          = COUT_MSB - COUT_WIDTH + 1;

    localparam EGL_MSB           = COUT_LSB - 1;
    localparam EGL_LSB           = EGL_MSB - EGL_WIDTH + 1;

    localparam OV_MSB            = EGL_LSB - 1;
    localparam OV_LSB            = OV_MSB - OV_WIDTH + 1;

    localparam ERR_MSB           = OV_LSB - 1;
    localparam ERR_LSB           = ERR_MSB - ERR_WIDTH + 1;

    localparam RES_START   = TOTAL_WIDTH;
    localparam RES_END     = RES_START + 2*w - 1;

    localparam COUT_BIT    = RES_END + 1;

    localparam EGL_START   = COUT_BIT + 1;
    localparam EGL_END     = EGL_START + 2;

    localparam OFLOW_BIT   = EGL_END + 1;
    localparam ERR_BIT     = OFLOW_BIT + 1;

    // Registers and memories
    reg [TOTAL_WIDTH-1:0] curr_test_case = 0;
    reg [TOTAL_WIDTH-1:0] stimulus_mem [0:`no_of_testcase-1];
    reg [2*w + TOTAL_WIDTH + 5:0]  response_packet;

    //Decl for giving the Stimulus
    integer i, j;
    reg CLK, REST, CE;
    event fetch_stimulus;

    reg [w-1:0] OPA, OPB;
    reg [3:0] CMD;
    reg [1:0] IP_V;
    reg MODE, CIN;
    reg [w-1:0] Feature_ID;
    reg [1:0] Reserved_bits;
    reg [2:0] Comparison_EGL;
    reg [2*w-1:0] Expected_RES;
    reg err, cout, ov;

    reg [1:0] res1;

    // DUT output wires
    wire [2*w-1:0] RES;
    wire ERR, OFLOW, COUT;
    wire [2:0] EGL;

    wire [2*w + 5:0] expected_data;
    reg  [2*w + 5:0] exact_data;

    // Instantiate DUT
    alu_design inst_dut (
        .clk(CLK),
        .rst(REST),
        .ce(CE),
        .mode(MODE),
        .Cin(CIN),
        .opa(OPA),
        .opb(OPB),
        .inp_valid(IP_V),
        .cmd(CMD),
        .result(RES),
        .Cout(COUT),
        .oflow(OFLOW),
        .G(EGL[1]),
        .E(EGL[2]),
        .L(EGL[0]),
        .Err(ERR)
    );

    // Read stimulus task
    task read_stimulus();
    begin
        #10 $readmemb("stimulus.txt", stimulus_mem);
    end
    endtask

    // Stimulus fetcher
    integer stim_mem_ptr = 0, stim_stimulus_mem_ptr = 0;
    always @(fetch_stimulus) begin
        curr_test_case = stimulus_mem[stim_mem_ptr];
        //$display("Stimulus_mem = %b\n", curr_test_case);
        stim_mem_ptr = stim_mem_ptr + 1;
        //$display ("packet data = %b\n",curr_test_case);
    end

    // Clock generator
    initial begin
        CLK = 0;
        forever #60 CLK = ~CLK;
    end

    // DRIVER TASK
    task driver();
    begin
        ->fetch_stimulus;
        @(posedge CLK);

        Feature_ID    = curr_test_case[FEATURE_ID_MSB:FEATURE_ID_LSB];
        res1          = curr_test_case[RESERVED_MSB:RESERVED_LSB];
        REST          = curr_test_case[RST_MSB:RST_LSB];
        CE            = curr_test_case[CE_MSB:CE_LSB];
        IP_V          = curr_test_case[IP_V_MSB:IP_V_LSB];
        MODE          = curr_test_case[MODE_MSB:MODE_LSB];
        CMD           = curr_test_case[CMD_MSB:CMD_LSB];
        OPA           = curr_test_case[OPA_MSB:OPA_LSB];
        OPB           = curr_test_case[OPB_MSB:OPB_LSB];
        CIN           = curr_test_case[CIN_MSB:CIN_LSB];
        Expected_RES = curr_test_case[EXPECTED_RES_MSB:EXPECTED_RES_LSB];
        cout          = curr_test_case[COUT_MSB:COUT_LSB];
        Comparison_EGL = curr_test_case[EGL_MSB:EGL_LSB];
        ov            = curr_test_case[OV_MSB:OV_LSB];
        err           = curr_test_case[ERR_MSB:ERR_LSB];

        $display("Driver Results \n At time %0t | Feature_ID=%b Reserved=%b OPA=%b OPB=%b in_valid=%b CMD=%b CIN=%b CE=%b MODE=%b RST=%b\n Expected_RES=%b cout=%b EGL=%b ov=%b err=%b\n",$time, Feature_ID, res1, OPA, OPB,IP_V, CMD, CIN, CE, MODE,REST, Expected_RES, cout, Comparison_EGL, ov, err);
    end
    endtask

    // DUT reset task
    task dut_reset();
    begin
        CE = 1;
        REST = 1;
        #20 REST = 0;
    end
    endtask

    // Global initialization
    task global_init();
    begin
        curr_test_case = 0;
        response_packet = 0;
        stim_mem_ptr = 0;
        stim_stimulus_mem_ptr = 0;
    end
    endtask

    // Monitor task: capture DUT outputs
    task monitor();
    begin
        repeat(2) @(posedge CLK);
        #5;
        response_packet[TOTAL_WIDTH-1:0] = curr_test_case;
        response_packet[RES_END:RES_START] = RES;
        response_packet[COUT_BIT] = COUT;
        response_packet[EGL_END:EGL_START] = EGL;
        response_packet[OFLOW_BIT] = OFLOW;
        response_packet[ERR_BIT] = ERR;
        //$display("%b",response_packet);
        $display("Monitor results \n: time %0t | RES=%b COUT=%b EGL=%b OFLOW=%b ERR=%b\n",$time, RES, COUT, EGL, OFLOW, ERR);
        exact_data = {RES, COUT, EGL, OFLOW, ERR};
    end
    endtask

    // Expected data assignment
    assign expected_data = {Expected_RES, cout, Comparison_EGL, ov, err};

    // Scoreboard task: check DUT output vs expected
    localparam PACKET_WIDTH = 1 + FEATURE_ID_WIDTH + (2*w+6) + (2*w+6) + 1 + 1;
    reg [PACKET_WIDTH-1:0] scb_stimulus_mem [0:`no_of_testcase-1];

    task score_board();
    reg [2*w+5:0] expected_res_data;
    reg [2*w+5:0] response_data;
    reg [FEATURE_ID_WIDTH-1:0] feature_id;
    begin
        #5;
        feature_id = Feature_ID;
        expected_res_data = expected_data;
        response_data = exact_data;

        $display("Scoreboard results: \n Expected=%b, Response=%b\n", expected_res_data, response_data);
        if(expected_data === exact_data)
                scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0, feature_id, expected_res_data, response_data, 1'b0, `PASS};
        else
                scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0, feature_id, expected_res_data, response_data, 1'b0, `FAIL};
                //$display("scoreboard mem: %b\n",scb_stimulus_mem[stim_stimulus_mem_ptr]);
                stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
        end
    endtask

    //Generating the report `no_of_testcase-1
    task gen_report;
        integer file_id, pointer;
        reg [PACKET_WIDTH-1:0] status;
        reg [w-1:0]c_p,c_f;
        localparam FEATURE_ID_MSB_IN_REPORT = PACKET_WIDTH - 2;
        localparam FEATURE_ID_LSB_IN_REPORT = FEATURE_ID_MSB_IN_REPORT - FEATURE_ID_WIDTH + 1;
    begin
        file_id = $fopen("results.txt", "w");
        c_p = 0;
        c_f = 0;
        for (pointer = 0; pointer < `no_of_testcase; pointer = pointer + 1) begin
            status = scb_stimulus_mem[pointer];
            //$display("\n status:%b",status);
            if (status[0]) begin
                c_p = c_p + 1;
                $fdisplay(file_id, "Feature ID %d : PASS", status[FEATURE_ID_MSB_IN_REPORT:FEATURE_ID_LSB_IN_REPORT]);
            end else begin
                c_f = c_f + 1;
                $fdisplay(file_id, "Feature ID %d : FAIL", status[FEATURE_ID_MSB_IN_REPORT:FEATURE_ID_LSB_IN_REPORT]);
            end
        end
        $display("------------STATUS------------\n");
        $display("Passed: %d\n",c_p);
        $display("Failed: %d\n",c_f);
        $fclose(file_id);
    end
    endtask

    // Main testbench initial block
    initial begin
        global_init();
        read_stimulus();
        dut_reset();

        for (i = 0; i < `no_of_testcase; i = i + 1) begin
            driver();
            monitor();
            score_board();
            $display("--------------------------------Test case %d completed!--------------------------------",i);
        end
        gen_report();
        $finish;
    end

endmodule
