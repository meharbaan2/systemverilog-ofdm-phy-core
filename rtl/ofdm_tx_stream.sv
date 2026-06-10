module ofdm_tx_stream (
    input  logic clk,
    input  logic rst_n,
    input  logic in_valid,
    output logic in_ready,
    input  ofdm_pkg::q_t in_data_i,
    input  ofdm_pkg::q_t in_data_q,
    output logic out_valid,
    input  logic out_ready,
    output ofdm_pkg::q_t out_data_i,
    output ofdm_pkg::q_t out_data_q
);
    import ofdm_pkg::*;

    typedef enum logic [0:0] { S_LOAD, S_EMIT } state_t;
    state_t state = S_LOAD;
    logic [6:0] in_count = 7'd0;
    logic [6:0] out_count = 7'd0;
    cplx_t data_buffer [DATA_PER_FRAME];
    cplx_t tx_time_cp [FRAME_LEN];

    ofdm_tx_frame u_tx_frame (
        .data_symbols(data_buffer),
        .tx_time_cp(tx_time_cp)
    );

    assign in_ready = (state == S_LOAD);
    assign out_valid = (state == S_EMIT);
    assign out_data_i = tx_time_cp[out_count].re;
    assign out_data_q = tx_time_cp[out_count].im;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_LOAD;
            in_count <= 7'd0;
            out_count <= 7'd0;
            for (int i = 0; i < DATA_PER_FRAME; i++) begin
                data_buffer[i] <= c_zero();
            end
        end else begin
            unique case (state)
                S_LOAD: begin
                    out_count <= 7'd0;
                    if (in_valid && in_ready) begin
                        data_buffer[in_count] <= c_make(in_data_i, in_data_q);
                        if (in_count == DATA_PER_FRAME - 1) begin
                            in_count <= 7'd0;
                            state <= S_EMIT;
                        end else begin
                            in_count <= in_count + 7'd1;
                        end
                    end
                end
                S_EMIT: begin
                    if (out_valid && out_ready) begin
                        if (out_count == FRAME_LEN - 1) begin
                            out_count <= 7'd0;
                            state <= S_LOAD;
                        end else begin
                            out_count <= out_count + 7'd1;
                        end
                    end
                end
                default: begin
                    state <= S_LOAD;
                    in_count <= 7'd0;
                    out_count <= 7'd0;
                end
            endcase
        end
    end
endmodule
