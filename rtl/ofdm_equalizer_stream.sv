module ofdm_equalizer_stream (
    input  logic clk,
    input  logic rst_n,
    input  logic eq_mode,
    input  ofdm_pkg::q_t noise_var,
    input  logic in_valid,
    output logic in_ready,
    input  ofdm_pkg::q_t in_rx_i,
    input  ofdm_pkg::q_t in_rx_q,
    input  ofdm_pkg::q_t in_h_i,
    input  ofdm_pkg::q_t in_h_q,
    output logic out_valid,
    input  logic out_ready,
    output ofdm_pkg::q_t out_data_i,
    output ofdm_pkg::q_t out_data_q
);
    import ofdm_pkg::*;

    cplx_t rx;
    cplx_t h;
    cplx_t numerator_now;
    cplx_t numerator_r;
    q_t h_power;
    q_t denom;
    q_t inv_denom;
    logic recip_valid;
    logic recip_ready;

    assign rx = c_make(in_rx_i, in_rx_q);
    assign h = c_make(in_h_i, in_h_q);
    assign h_power = c_abs2(h);
    assign denom = (eq_mode == EQ_ZF)
        ? ((h_power < Q_EPS) ? Q_EPS : h_power)
        : q_add(h_power, noise_var);
    assign numerator_now = c_mul(rx, c_conj(h));
    assign in_ready = recip_ready;

    ofdm_recip_nr_pipe u_recip (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid && in_ready),
        .in_ready(recip_ready),
        .in_x(denom),
        .out_valid(recip_valid),
        .out_ready(out_ready),
        .out_y(inv_denom)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            numerator_r <= c_zero();
        end else if (in_valid && in_ready) begin
            numerator_r <= numerator_now;
        end
    end

    assign out_valid = recip_valid;
    assign out_data_i = q_mul(numerator_r.re, inv_denom);
    assign out_data_q = q_mul(numerator_r.im, inv_denom);
endmodule

