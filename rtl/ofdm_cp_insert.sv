module ofdm_cp_insert (
    input  ofdm_pkg::cplx_t time_in [ofdm_pkg::N],
    output ofdm_pkg::cplx_t time_cp_out [ofdm_pkg::FRAME_LEN]
);
    import ofdm_pkg::*;

    int i;

    always_comb begin
        for (i = 0; i < CP_LEN; i++) begin
            time_cp_out[i] = time_in[N - CP_LEN + i];
        end
        for (i = 0; i < N; i++) begin
            time_cp_out[CP_LEN + i] = time_in[i];
        end
    end
endmodule

