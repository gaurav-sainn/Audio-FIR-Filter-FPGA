module fir_filter_16tap (
    input  wire                  clk,            // 50 MHz system clock
    input  wire                  reset_n,        // Active-low asynchronous reset
    input  wire signed [11:0]    data_in,        // 12-bit audio sample input
    input  wire                  data_valid_in,  // Pulse HIGH for 1 cycle when data_in arrives
    output reg  signed [11:0]    data_out,       // 12-bit filtered audio output
    output reg                   data_valid_out  // Pulses HIGH when data_out is valid
);

    // Filter Coefficients generated in Q15 format
    wire signed [15:0] coeff [0:15];
    assign coeff[ 0] = 16'sd27;
    assign coeff[ 1] = 16'sd131;
    assign coeff[ 2] = 16'sd450;
    assign coeff[ 3] = 16'sd1111;
    assign coeff[ 4] = 16'sd2111;
    assign coeff[ 5] = 16'sd3280;
    assign coeff[ 6] = 16'sd4327;
    assign coeff[ 7] = 16'sd4947;
    assign coeff[ 8] = 16'sd4947;
    assign coeff[ 9] = 16'sd4327;
    assign coeff[10] = 16'sd3280;
    assign coeff[11] = 16'sd2111;
    assign coeff[12] = 16'sd1111;
    assign coeff[13] = 16'sd450;
    assign coeff[14] = 16'sd131;
    assign coeff[15] = 16'sd27;

    // Shift register array to store the past 16 samples
    reg signed [11:0] shift_reg [0:15];
    reg signed [31:0] acc;
    integer i;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                shift_reg[i] <= 12'sd0;
            end
            data_out       <= 12'sd0;
            data_valid_out <= 1'b0;
            acc            <= 32'sd0;
        end else if (data_valid_in) begin
            // 1. Shift existing samples downward (from highest index to 1)
            for (i = 15; i > 0; i = i - 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
            shift_reg[0] <= data_in;

            // 2. Multiply and Accumulate using the incoming sample and current history
            acc = data_in * coeff[0];
            for (i = 1; i < 16; i = i + 1) begin
                acc = acc + (shift_reg[i-1] * coeff[i]);
            end

            // 3. Remove Q15 scaling: bits [26:15] extract the signed 12-bit output
            data_out       <= acc[26:15];
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule