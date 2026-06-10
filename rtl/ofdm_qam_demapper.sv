module ofdm_qam_demapper (
    input  logic [1:0] scheme,
    input  ofdm_pkg::cplx_t symbol,
    output logic [5:0] bits,
    output logic [2:0] bit_count
);
    import ofdm_pkg::*;

    function automatic logic [1:0] qam16_index(input q_t x);
        if (x < -24'sd41448) begin
            qam16_index = 2'd0;
        end else if (x < 24'sd0) begin
            qam16_index = 2'd1;
        end else if (x < 24'sd41448) begin
            qam16_index = 2'd2;
        end else begin
            qam16_index = 2'd3;
        end
    endfunction

    function automatic logic [2:0] qam64_index(input q_t x);
        if (x < -24'sd60636) begin
            qam64_index = 3'd0;
        end else if (x < -24'sd40424) begin
            qam64_index = 3'd1;
        end else if (x < -24'sd20212) begin
            qam64_index = 3'd2;
        end else if (x < 24'sd0) begin
            qam64_index = 3'd3;
        end else if (x < 24'sd20212) begin
            qam64_index = 3'd4;
        end else if (x < 24'sd40424) begin
            qam64_index = 3'd5;
        end else if (x < 24'sd60636) begin
            qam64_index = 3'd6;
        end else begin
            qam64_index = 3'd7;
        end
    endfunction

    logic [1:0] re16;
    logic [1:0] im16;
    logic [2:0] re64;
    logic [2:0] im64;

    always_comb begin
        bits = 6'd0;
        bit_count = 3'd0;
        re16 = qam16_index(symbol.re);
        im16 = qam16_index(symbol.im);
        re64 = qam64_index(symbol.re);
        im64 = qam64_index(symbol.im);

        unique case (scheme)
            MOD_QPSK: begin
                bits = {symbol.re > 0, symbol.im > 0, 4'b0000};
                bit_count = 3'd2;
            end
            MOD_QAM16: begin
                bits = {re16, im16, 2'b00};
                bit_count = 3'd4;
            end
            MOD_QAM64: begin
                bits = {re64, im64};
                bit_count = 3'd6;
            end
            default: begin
                bits = 6'd0;
                bit_count = 3'd0;
            end
        endcase
    end
endmodule

