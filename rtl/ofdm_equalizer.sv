module ofdm_equalizer (
    input  logic eq_mode,
    input  ofdm_pkg::q_t noise_var,
    input  ofdm_pkg::cplx_t rx_frame [ofdm_pkg::N],
    input  ofdm_pkg::cplx_t h_est [ofdm_pkg::N],
    output ofdm_pkg::cplx_t eq_frame [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    int k;
    q_t h_power;
    q_t denom;
    q_t inv_denom;
    cplx_t numerator;

    always_comb begin
        for (k = 0; k < N; k++) begin
            h_power = c_abs2(h_est[k]);
            if (eq_mode == EQ_ZF) begin
                denom = (h_power < Q_EPS) ? Q_EPS : h_power;
            end else begin
                denom = q_add(h_power, noise_var);
            end

            inv_denom = q_recip_approx(denom);
            numerator = c_mul(rx_frame[k], c_conj(h_est[k]));
            eq_frame[k] = c_scale_q(numerator, inv_denom);
        end
    end
endmodule
