module ad7265_spi_master (
    input  wire                 clk,            // 50 MHz system clock
    input  wire                 reset_n,        // Active-low asynchronous reset

    // Physical Hardware Pins connected to AD7265
    output reg                  adc_convst,     // Conversion Start / CS_N
    output reg                  adc_sclk,       // Serial Clock (12.5 MHz)
    input  wire                 adc_sdo,        // Serial Data Out (Channel A)

    // Data connection to the FIR Filter
    output reg  signed [11:0]   sample_out,     // 12-bit signed audio sample
    output reg                  sample_valid    // 1-clock-cycle pulse when sample is ready
);

    // Audio sampling rate generator:
    // 50 MHz / 48 kHz ~= 1042 clock cycles per audio sample
    localparam SAMPLE_INTERVAL = 11'd1041;
    reg [10:0] sample_timer;

    // FSM States
    localparam IDLE    = 1'b0;
    localparam READ_SPI = 1'b1;
    reg state;

    reg [1:0]  sclk_div;      // 50 MHz divided by 4 gives 12.5 MHz SPI clock
    reg [4:0]  bit_index;     // Counter for 12 data bits
    reg [11:0] shift_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sample_timer <= 11'd0;
            state        <= IDLE;
            adc_convst   <= 1'b1;
            adc_sclk     <= 1'b1;
            sclk_div     <= 2'd0;
            bit_index    <= 5'd0;
            shift_reg    <= 12'd0;
            sample_out   <= 12'sd0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0; // Default: strobe pulse lasts only 1 cycle

            case (state)
                IDLE: begin
                    adc_convst <= 1'b1;
                    adc_sclk   <= 1'b1;
                    sclk_div   <= 2'd0;
                    bit_index  <= 5'd0;

                    if (sample_timer >= SAMPLE_INTERVAL) begin
                        sample_timer <= 11'd0;
                        adc_convst   <= 1'b0;   // Drop CONVST to trigger conversion
                        state        <= READ_SPI;
                    end else begin
                        sample_timer <= sample_timer + 1'b1;
                    end
                end

                READ_SPI: begin
                    sclk_div <= sclk_div + 1'b1;

                    // Toggle ADC_SCLK every 2 clock cycles (12.5 MHz)
                    if (sclk_div == 2'd1) begin
                        adc_sclk <= 1'b0; // Falling edge
                    end else if (sclk_div == 2'd3) begin
                        adc_sclk <= 1'b1; // Rising edge: sample input bit

                        shift_reg <= {shift_reg[10:0], adc_sdo};
                        bit_index <= bit_index + 1'b1;

                        if (bit_index == 5'd11) begin
                            // Finished reading 12 bits
                            // Convert ADC unipolar binary (0 to 4095) to signed bipolar (-2048 to +2047)
                            sample_out   <= {~shift_reg[10], shift_reg[9:0], adc_sdo}; 
                            sample_valid <= 1'b1;
                            adc_convst   <= 1'b1;
                            state        <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule