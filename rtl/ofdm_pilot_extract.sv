module ofdm_pilot_extract (
    input  ofdm_pkg::cplx_t frame_in [ofdm_pkg::N],
    output ofdm_pkg::cplx_t data_out [ofdm_pkg::DATA_PER_FRAME],
    output ofdm_pkg::cplx_t pilots_out [ofdm_pkg::PILOTS_PER_FRAME]
);
    import ofdm_pkg::*;

    int k;
    int data_idx;

    always_comb begin
        for (k = 0; k < PILOTS_PER_FRAME; k++) begin
            pilots_out[k] = frame_in[k * PILOT_SPACING];
        end

        for (k = 0; k < N; k++) begin
            if ((k % PILOT_SPACING) != 0) begin
                data_idx = k - (k / PILOT_SPACING) - 1;
                data_out[data_idx] = frame_in[k];
            end
        end
    end
endmodule

