module ofdm_pilot_insert (
    input  ofdm_pkg::cplx_t data_in [ofdm_pkg::DATA_PER_FRAME],
    output ofdm_pkg::cplx_t frame_out [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    int k;
    int data_idx;

    always_comb begin
        for (k = 0; k < N; k++) begin
            if ((k % PILOT_SPACING) == 0) begin
                frame_out[k] = pilot_value(k / PILOT_SPACING);
            end else begin
                data_idx = k - (k / PILOT_SPACING) - 1;
                frame_out[k] = data_in[data_idx];
            end
        end
    end
endmodule

