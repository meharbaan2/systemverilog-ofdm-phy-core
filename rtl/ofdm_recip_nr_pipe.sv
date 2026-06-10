module ofdm_recip_nr_pipe (
    input  logic clk,
    input  logic rst_n,
    input  logic in_valid,
    output logic in_ready,
    input  ofdm_pkg::q_t in_x,
    output logic out_valid,
    input  logic out_ready,
    output ofdm_pkg::q_t out_y
);
    import ofdm_pkg::*;

    assign in_ready = !out_valid || out_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_y <= Q_ZERO;
        end else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) begin
                out_y <= q_recip_approx(in_x);
            end
        end
    end
endmodule

