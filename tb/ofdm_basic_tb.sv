`timescale 1ns/1ps

module ofdm_basic_tb;
    import ofdm_pkg::*;

    logic [1:0] scheme;
    logic [5:0] bits_in;
    logic [5:0] bits_out;
    logic [2:0] bit_count;
    cplx_t mapped_symbol;

    cplx_t pilot_data [DATA_PER_FRAME];
    cplx_t pilot_frame [N];
    cplx_t pilot_data_out [DATA_PER_FRAME];
    cplx_t pilot_values_out [PILOTS_PER_FRAME];

    cplx_t cp_time [N];
    cplx_t cp_with_prefix [FRAME_LEN];
    cplx_t cp_removed [N];

    cplx_t fft_in [N];
    cplx_t fft_time [N];
    cplx_t fft_roundtrip [N];

    cplx_t tx_data [DATA_PER_FRAME];
    cplx_t tx_time_cp [FRAME_LEN];
    cplx_t rx_data [DATA_PER_FRAME];
    cplx_t rx_h [N];

    int i;
    int failures;
    longint signed diff_re;
    longint signed diff_im;

    ofdm_qam_mapper u_mapper (
        .scheme(scheme),
        .bits(bits_in),
        .symbol(mapped_symbol)
    );

    ofdm_qam_demapper u_demapper (
        .scheme(scheme),
        .symbol(mapped_symbol),
        .bits(bits_out),
        .bit_count(bit_count)
    );

    ofdm_pilot_insert u_pilot_insert (
        .data_in(pilot_data),
        .frame_out(pilot_frame)
    );

    ofdm_pilot_extract u_pilot_extract (
        .frame_in(pilot_frame),
        .data_out(pilot_data_out),
        .pilots_out(pilot_values_out)
    );

    ofdm_cp_insert u_cp_insert (
        .time_in(cp_time),
        .time_cp_out(cp_with_prefix)
    );

    ofdm_cp_remove u_cp_remove (
        .time_cp_in(cp_with_prefix),
        .time_out(cp_removed)
    );

    ofdm_fft64 u_ifft (
        .inverse(1'b1),
        .in_frame(fft_in),
        .out_frame(fft_time)
    );

    ofdm_fft64 u_fft (
        .inverse(1'b0),
        .in_frame(fft_time),
        .out_frame(fft_roundtrip)
    );

    ofdm_tx_frame u_tx (
        .data_symbols(tx_data),
        .tx_time_cp(tx_time_cp)
    );

    ofdm_rx_frame u_rx (
        .eq_mode(EQ_MMSE),
        .noise_var(Q_ZERO),
        .rx_time_cp(tx_time_cp),
        .data_symbols(rx_data),
        .h_est(rx_h)
    );

    task automatic expect_equal_q(input string name, input q_t a, input q_t b, input int tolerance);
        longint signed d;
        begin
            d = longint'(a) - longint'(b);
            if (d < 0) begin
                d = -d;
            end
            if (d > tolerance) begin
                $display("[FAIL] %s expected %0d got %0d", name, b, a);
                failures++;
            end
        end
    endtask

    initial begin
        failures = 0;

        scheme = MOD_QPSK;
        bits_in = 6'b100000;
        #1;
        if (bits_out[5:4] != bits_in[5:4] || bit_count != 3'd2) begin
            $display("[FAIL] QPSK mapper/demapper");
            failures++;
        end

        scheme = MOD_QAM16;
        bits_in = 6'b100100;
        #1;
        if (bits_out[5:2] != bits_in[5:2] || bit_count != 3'd4) begin
            $display("[FAIL] 16-QAM mapper/demapper");
            failures++;
        end

        scheme = MOD_QAM64;
        bits_in = 6'b101011;
        #1;
        if (bits_out != bits_in || bit_count != 3'd6) begin
            $display("[FAIL] 64-QAM mapper/demapper");
            failures++;
        end

        for (i = 0; i < DATA_PER_FRAME; i++) begin
            pilot_data[i] = c_make(q_t'(i * 1024), q_t'(-(i * 512)));
        end
        #1;
        if (pilot_frame[0].re != Q_ONE || pilot_frame[8].re != Q_NEG_ONE) begin
            $display("[FAIL] pilot polarity");
            failures++;
        end
        for (i = 0; i < DATA_PER_FRAME; i++) begin
            expect_equal_q("pilot extract re", pilot_data_out[i].re, pilot_data[i].re, 0);
            expect_equal_q("pilot extract im", pilot_data_out[i].im, pilot_data[i].im, 0);
        end

        for (i = 0; i < N; i++) begin
            cp_time[i] = c_make(q_t'(i * 256), q_t'(-(i * 128)));
        end
        #1;
        for (i = 0; i < N; i++) begin
            expect_equal_q("cp remove re", cp_removed[i].re, cp_time[i].re, 0);
            expect_equal_q("cp remove im", cp_removed[i].im, cp_time[i].im, 0);
        end

        for (i = 0; i < N; i++) begin
            fft_in[i] = c_zero();
        end
        fft_in[3] = c_make(24'sd65536, -24'sd32768);
        #1;
        for (i = 0; i < N; i++) begin
            expect_equal_q("fft roundtrip re", fft_roundtrip[i].re, fft_in[i].re, 96);
            expect_equal_q("fft roundtrip im", fft_roundtrip[i].im, fft_in[i].im, 96);
        end

        for (i = 0; i < DATA_PER_FRAME; i++) begin
            tx_data[i] = (i & 1) ? c_make(24'sd46341, -24'sd46341)
                                : c_make(-24'sd46341, 24'sd46341);
        end
        #1;
        for (i = 0; i < DATA_PER_FRAME; i++) begin
            expect_equal_q("e2e ideal re", rx_data[i].re, tx_data[i].re, 512);
            expect_equal_q("e2e ideal im", rx_data[i].im, tx_data[i].im, 512);
        end

        if (failures == 0) begin
            $display("[ OK ] OFDM basic RTL sanity tests passed");
        end else begin
            $display("[FAIL] %0d OFDM basic RTL sanity issue(s)", failures);
            $fatal(1, "OFDM basic regression failed");
        end
        $finish;
    end
endmodule
