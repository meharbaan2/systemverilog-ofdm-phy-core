module ofdm_qam_mapper (
    input  logic [1:0] scheme,
    input  logic [5:0] bits,
    output ofdm_pkg::cplx_t symbol
);
    import ofdm_pkg::*;

    function automatic q_t qam16_level(input logic [1:0] b);
        case (b)
            2'd0: qam16_level = -24'sd62172;
            2'd1: qam16_level = -24'sd20724;
            2'd2: qam16_level =  24'sd20724;
            default: qam16_level = 24'sd62172;
        endcase
    endfunction

    function automatic q_t qam64_level(input logic [2:0] b);
        case (b)
            3'd0: qam64_level = -24'sd70742;
            3'd1: qam64_level = -24'sd50530;
            3'd2: qam64_level = -24'sd30318;
            3'd3: qam64_level = -24'sd10106;
            3'd4: qam64_level =  24'sd10106;
            3'd5: qam64_level =  24'sd30318;
            3'd6: qam64_level =  24'sd50530;
            default: qam64_level = 24'sd70742;
        endcase
    endfunction

    always_comb begin
        unique case (scheme)
            MOD_QPSK: begin
                symbol.re = bits[5] ? 24'sd46341 : -24'sd46341;
                symbol.im = bits[4] ? 24'sd46341 : -24'sd46341;
            end
            MOD_QAM16: begin
                symbol.re = qam16_level(bits[5:4]);
                symbol.im = qam16_level(bits[3:2]);
            end
            MOD_QAM64: begin
                symbol.re = qam64_level(bits[5:3]);
                symbol.im = qam64_level(bits[2:0]);
            end
            default: begin
                symbol = c_zero();
            end
        endcase
    end
endmodule

