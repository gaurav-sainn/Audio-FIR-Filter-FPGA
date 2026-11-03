`timescale 1ns / 1ps

module tb_fir_filter;

    reg                 clk;
    reg                 reset_n;
    reg  signed [11:0]  data_in;
    reg                 data_valid_in;
    wire signed [11:0]  data_out;
    wire                data_valid_out;

    // Connect to the FIR filter
    fir_filter_16tap uut (
        .clk            (clk),
        .reset_n        (reset_n),
        .data_in        (data_in),
        .data_valid_in  (data_valid_in),
        .data_out       (data_out),
        .data_valid_out (data_valid_out)
    );

    // 50 MHz clock generation (20 ns total period: 10ns LOW, 10ns HIGH)
    always #10 clk = ~clk;

    integer k;

    initial begin
        clk           = 0;
        reset_n       = 0;
        data_in       = 12'sd0;
        data_valid_in = 0;

        // Apply reset for 100 ns
        #100;
        reset_n = 1;
        #100;

        // Test Phase 1: Low-Frequency Audio / DC Pass-Through
        // Send a constant signal of +1000 for 25 samples
        $display("Starting Test 1: Low Frequency Pass-Through...");
        for (k = 0; k < 25; k = k + 1) begin
            @(posedge clk);
            data_in       = 12'sd1000;
            data_valid_in = 1'b1;
            @(posedge clk);
            data_valid_in = 1'b0;

            #300; // Simulated audio sampling interval
        end

        // Test Phase 2: High-Frequency Noise / Hiss
        // Rapidly alternate between +1000 and -1000 (Filter should flatten this to near 0)
        $display("Starting Test 2: High Frequency Noise Suppression...");
        for (k = 0; k < 25; k = k + 1) begin
            @(posedge clk);
            data_in       = (k % 2 == 0) ? 12'sd1000 : -12'sd1000;
            data_valid_in = 1'b1;
            @(posedge clk);
            data_valid_in = 1'b0;

            #300;
        end

        #500;
        $display("Simulation Complete!");
        $stop;
    end

endmodule