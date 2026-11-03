module delta_sigma_dac (
    input  wire                 clk,        // 50 MHz system clock
    input  wire                 reset_n,    // Active-low reset
    input  wire signed [11:0]   data_in,    // 12-bit audio sample from FIR filter
    output reg                  dac_out     // 1-bit high-speed toggling pin to GPIO
);

    // Convert signed 12-bit (-2048..+2047) to unsigned 12-bit (0..4095)
    wire [11:0] unsigned_data = data_in + 12'd2048;

    // 13-bit accumulator to track quantization error
    reg [12:0] sigma_latch;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sigma_latch <= 13'd0;
            dac_out     <= 1'b0;
        end else begin
            sigma_latch <= sigma_latch[11:0] + unsigned_data;
            dac_out     <= sigma_latch[12]; // MSB carries the pulse-density stream
        end
    end

endmodule