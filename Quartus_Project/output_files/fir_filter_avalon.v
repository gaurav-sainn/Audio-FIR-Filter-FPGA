// ============================================================================
// fir_filter_avalon.v - Avalon Memory-Mapped Interface for 16-Tap FIR Audio Filter
// Target: Intel Cyclone V SoC (DE10-Nano)
// ============================================================================
`timescale 1 ps / 1 ps

module fir_filter_avalon (
    input  wire        clk,
    input  wire        reset_n,

    // Avalon-MM Slave Interface (LWH2F Bridge at 0xFF200000)
    input  wire [1:0]  avs_address,     // 0x00 (word 0) = Control, 0x04 (word 1) = Status
    input  wire        avs_read,
    output reg  [31:0] avs_readdata,
    input  wire        avs_write,
    input  wire [31:0] avs_writedata,

    // Conduit interface directly routed to board user LEDs
    output wire [7:0]  leds
);

    // -------------------------------------------------------------
    // Register Map:
    // Reg 0 (Offset 0x00): Control Register
    //   Bit 0: Soft Core Reset (Active High pulse)
    //   Bit 1: Bypass Mode (1 = Bypass Filter / Noise ON, 0 = Filter ACTIVE)
    // Reg 1 (Offset 0x04): Status Register
    //   Bits [7:0]: Live Rectified Signal Amplitude
    // -------------------------------------------------------------
    reg [31:0] reg_control;

    // Synchronous Avalon-MM Writes
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_control <= 32'd0;
        end else if (avs_write) begin
            if (avs_address == 2'b00) begin
                reg_control <= avs_writedata;
            end
        end
    end

    // Real-Time Rectified Signal Amplitude
    wire [7:0] amplitude_metric;

    // Asynchronous / Combinational Avalon-MM Reads (0-wait / 0-latency bus compliance)
    always @(*) begin
        case (avs_address)
            2'b00:   avs_readdata = reg_control;
            2'b01:   avs_readdata = {24'd0, amplitude_metric};
            default: avs_readdata = 32'd0;
        endcase
    end

    // -------------------------------------------------------------
    // Core Reset & Bypass Mode Routing
    // -------------------------------------------------------------
    wire core_reset_n = reset_n & ~reg_control[0];
    wire bypass_mode  = reg_control[1];

    // -------------------------------------------------------------
    // 48 kHz Sampling Strobe (50 MHz / 1042 = 47.98 kHz)
    // -------------------------------------------------------------
    reg [10:0] sample_timer;
    reg        sample_valid;

    always @(posedge clk or negedge core_reset_n) begin
        if (!core_reset_n) begin
            sample_timer <= 11'd0;
            sample_valid <= 1'b0;
        end else if (sample_timer >= 11'd1041) begin
            sample_timer <= 11'd0;
            sample_valid <= 1'b1;
        end else begin
            sample_timer <= sample_timer + 1'b1;
            sample_valid <= 1'b0;
        end
    end

    // -------------------------------------------------------------
    // Synthetic Audio: 500 Hz Base Tone + 12.5 kHz Noise
    // -------------------------------------------------------------
    reg [6:0] tone_cnt;
    reg [1:0] noise_cnt;

    always @(posedge clk or negedge core_reset_n) begin
        if (!core_reset_n) begin
            tone_cnt  <= 7'd0;
            noise_cnt <= 2'd0;
        end else if (sample_valid) begin
            tone_cnt  <= tone_cnt + 1'b1;
            noise_cnt <= noise_cnt + 1'b1;
        end
    end

    wire signed [11:0] low_freq_tone  = (tone_cnt[6]) ? 12'sd600 : -12'sd600;
    wire signed [11:0] high_freq_noise = (noise_cnt[1]) ? 12'sd400 : -12'sd400;
    wire signed [11:0] noisy_sample    = low_freq_tone + high_freq_noise;

    // -------------------------------------------------------------
    // 16-Tap Pipelined FIR Low-Pass Filter Core
    // -------------------------------------------------------------
    wire signed [11:0] filtered_sample;
    wire               filtered_valid;

    fir_filter_16tap u_fir_core (
        .clk            (clk),
        .reset_n        (core_reset_n),
        .data_in        (noisy_sample),
        .data_valid_in  (sample_valid),
        .data_out       (filtered_sample),
        .data_valid_out (filtered_valid)
    );

    // -------------------------------------------------------------
    // Display Output & Live Amplitude Calculation
    // -------------------------------------------------------------
    wire signed [11:0] display_sample = (bypass_mode) ? noisy_sample : filtered_sample;
    wire [11:0] abs_val = (display_sample < 0) ? -display_sample : display_sample;

    assign amplitude_metric = abs_val[10:3];
    assign leds             = amplitude_metric;

endmodule
