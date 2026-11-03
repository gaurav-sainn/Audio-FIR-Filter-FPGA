module fir_filter_avalon_slave (
    input  wire        clk,
    input  wire        reset_n,

    // Avalon-MM Slave Bus (Connected to HPS)
    input  wire [1:0]  avs_address,
    input  wire        avs_read,
    input  wire        avs_write,
    input  wire [31:0] avs_writedata,
    output reg  [31:0] avs_readdata,

    // Conduit to physical LEDs
    output wire [7:0]  leds
);

    // Control Register: 
    // Bit 0 = Soft Reset (1 = in reset)
    // Bit 1 = Filter Bypass (1 = bypass active)
    reg [31:0] reg_ctrl;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_ctrl <= 32'd0;
        end else if (avs_write && (avs_address == 2'b00)) begin
            reg_ctrl <= avs_writedata;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            avs_readdata <= 32'd0;
        end else if (avs_read) begin
            case (avs_address)
                2'b00:   avs_readdata <= reg_ctrl;
                default: avs_readdata <= 32'hDEADBEEF;
            endcase
        end
    end

    wire soft_reset_n = ~reg_ctrl[0] & reset_n;
    wire bypass       =  reg_ctrl[1];

    // Internal 48 kHz Strobe Generator
    reg [10:0] sample_timer;
    reg        sample_valid;

    always @(posedge clk or negedge soft_reset_n) begin
        if (!soft_reset_n) begin
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

    // Internal Signal Generator (500 Hz Tone + 12.5 kHz Noise)
    reg [6:0] tone_cnt;
    reg [1:0] noise_cnt;

    always @(posedge clk or negedge soft_reset_n) begin
        if (!soft_reset_n) begin
            tone_cnt  <= 7'd0;
            noise_cnt <= 2'd0;
        end else if (sample_valid) begin
            tone_cnt  <= tone_cnt + 1'b1;
            noise_cnt <= noise_cnt + 1'b1;
        end
    end

    wire signed [11:0] low_freq_tone   = (tone_cnt[6])  ? 12'sd600 : -12'sd600;
    wire signed [11:0] high_freq_noise = (noise_cnt[1]) ? 12'sd400 : -12'sd400;
    wire signed [11:0] noisy_sample    = low_freq_tone + high_freq_noise;

    // FIR Filter Instance
    wire signed [11:0] filtered_sample;
    wire               filtered_valid;

    fir_filter_16tap u_fir (
        .clk            (clk),
        .reset_n        (soft_reset_n),
        .data_in        (noisy_sample),
        .data_valid_in  (sample_valid),
        .data_out       (filtered_sample),
        .data_valid_out (filtered_valid)
    );

    wire signed [11:0] display_sample = (bypass) ? noisy_sample : filtered_sample;
    wire [11:0] abs_val = (display_sample < 0) ? -display_sample : display_sample;
    assign leds = abs_val[10:3];

endmodule