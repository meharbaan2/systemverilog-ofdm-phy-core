module ofdm_tx_frame (
    input  ofdm_pkg::cplx_t data_symbols [ofdm_pkg::DATA_PER_FRAME],
    output ofdm_pkg::cplx_t tx_time_cp [ofdm_pkg::FRAME_LEN]
);
    import ofdm_pkg::*;

    cplx_t freq_frame [N];
    cplx_t time_frame [N];
    cplx_t time_cp_internal [FRAME_LEN];
    int cp_i;

    genvar k;
    generate
        for (k = 0; k < N; k++) begin : gen_pilot_map
            if ((k % PILOT_SPACING) == 0) begin : gen_pilot
                assign freq_frame[k] = pilot_value(k / PILOT_SPACING);
            end else begin
                assign freq_frame[k] = data_symbols[k - (k / PILOT_SPACING) - 1];
            end
        end
    endgenerate

    ofdm_fft64 u_ifft (
        .inverse(1'b1),
        .in_frame(freq_frame),
        .out_frame(time_frame)
    );

    ofdm_cp_insert u_cp_insert (
        .time_in(time_frame),
        .time_cp_out(time_cp_internal)
    );

    always_comb begin
        for (cp_i = 0; cp_i < FRAME_LEN; cp_i++) begin
            tx_time_cp[cp_i] = time_cp_internal[cp_i];
        end
    end
endmodule
