module ofdm_rx_frame (
    input  logic eq_mode,
    input  ofdm_pkg::q_t noise_var,
    input  ofdm_pkg::cplx_t rx_time_cp [ofdm_pkg::FRAME_LEN],
    output ofdm_pkg::cplx_t data_symbols [ofdm_pkg::DATA_PER_FRAME],
    output ofdm_pkg::cplx_t h_est [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    cplx_t rx_time [N];
    cplx_t rx_freq [N];
    cplx_t eq_freq [N];
    cplx_t unused_pilots [PILOTS_PER_FRAME];

    ofdm_cp_remove u_cp_remove (
        .time_cp_in(rx_time_cp),
        .time_out(rx_time)
    );

    ofdm_fft64 u_fft (
        .inverse(1'b0),
        .in_frame(rx_time),
        .out_frame(rx_freq)
    );

    ofdm_channel_estimator u_channel_estimator (
        .rx_frame(rx_freq),
        .h_est(h_est)
    );

    ofdm_equalizer u_equalizer (
        .eq_mode(eq_mode),
        .noise_var(noise_var),
        .rx_frame(rx_freq),
        .h_est(h_est),
        .eq_frame(eq_freq)
    );

    ofdm_pilot_extract u_pilot_extract (
        .frame_in(eq_freq),
        .data_out(data_symbols),
        .pilots_out(unused_pilots)
    );
endmodule

