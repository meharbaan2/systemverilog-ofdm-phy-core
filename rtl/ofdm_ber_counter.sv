module ofdm_ber_counter (
    input  logic clk,
    input  logic rst_n,
    input  logic clear,
    input  logic valid,
    input  logic ref_bit,
    input  logic rx_bit,
    output logic [31:0] bit_count,
    output logic [31:0] error_count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 32'd0;
            error_count <= 32'd0;
        end else if (clear) begin
            bit_count <= 32'd0;
            error_count <= 32'd0;
        end else if (valid) begin
            bit_count <= bit_count + 32'd1;
            if (ref_bit != rx_bit) begin
                error_count <= error_count + 32'd1;
            end
        end
    end
endmodule

