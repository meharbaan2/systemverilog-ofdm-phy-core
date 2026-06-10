module ofdm_cp_remove (
    input  ofdm_pkg::cplx_t time_cp_in [ofdm_pkg::FRAME_LEN],
    output ofdm_pkg::cplx_t time_out [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    int i;

    always_comb begin
        for (i = 0; i < N; i++) begin
            time_out[i] = time_cp_in[CP_LEN + i];
        end
    end
endmodule

