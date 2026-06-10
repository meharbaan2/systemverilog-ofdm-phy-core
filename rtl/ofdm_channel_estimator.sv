module ofdm_channel_estimator (
    input  ofdm_pkg::cplx_t rx_frame [ofdm_pkg::N],
    output ofdm_pkg::cplx_t h_est [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    cplx_t hp [PILOTS_PER_FRAME];

    int p;
    int k;
    int left_p;
    int right_p;
    int r;
    cplx_t left_scaled;
    cplx_t right_scaled;

    function automatic cplx_t scale_by_int_div8(input cplx_t x, input int unsigned gain);
        cplx_t z;
        begin
            z.re = q_t'(q_mul_small(x.re, int'(gain)) >>> 3);
            z.im = q_t'(q_mul_small(x.im, int'(gain)) >>> 3);
            scale_by_int_div8 = z;
        end
    endfunction

    always_comb begin
        for (p = 0; p < PILOTS_PER_FRAME; p++) begin
            if ((p & 1) == 0) begin
                hp[p] = rx_frame[p * PILOT_SPACING];
            end else begin
                hp[p] = c_neg(rx_frame[p * PILOT_SPACING]);
            end
        end

        for (k = 0; k < N; k++) begin
            left_p = k / PILOT_SPACING;
            r = k % PILOT_SPACING;
            if (left_p >= (PILOTS_PER_FRAME - 1)) begin
                h_est[k] = hp[PILOTS_PER_FRAME - 1];
            end else begin
                right_p = left_p + 1;
                left_scaled = scale_by_int_div8(hp[left_p], PILOT_SPACING - r);
                right_scaled = scale_by_int_div8(hp[right_p], r);
                h_est[k] = c_add(left_scaled, right_scaled);
            end
        end
    end
endmodule

