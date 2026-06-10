`timescale 1ns/1ps

module ofdm_scoreboard_tb;
    import ofdm_pkg::*;

    localparam int QAM_CASES = 144;
    localparam int RECIP_CASES = 10;

    int failures;
    int i;
    int fd;
    int rc;
    int scheme_i;
    int bits_i;
    int exp_re;
    int exp_im;
    int x_i;
    int recip_i;
    int got_recip;
    logic [1:0] scheme;
    logic [5:0] bits;
    cplx_t mapped;
    cplx_t data [DATA_PER_FRAME];
    cplx_t tx_cp [FRAME_LEN];
    cplx_t exp_tx_cp [FRAME_LEN];
    cplx_t awgn_cp [FRAME_LEN];
    cplx_t rayleigh_cp [FRAME_LEN];
    cplx_t awgn_data [DATA_PER_FRAME];
    cplx_t rayleigh_data [DATA_PER_FRAME];
    cplx_t awgn_h [N];
    cplx_t rayleigh_h [N];

    ofdm_qam_mapper u_mapper (
        .scheme(scheme),
        .bits(bits),
        .symbol(mapped)
    );

    ofdm_tx_frame u_tx (
        .data_symbols(data),
        .tx_time_cp(tx_cp)
    );

    ofdm_rx_frame u_awgn_rx (
        .eq_mode(EQ_MMSE),
        .noise_var(Q_ZERO),
        .rx_time_cp(awgn_cp),
        .data_symbols(awgn_data),
        .h_est(awgn_h)
    );

    ofdm_rx_frame u_rayleigh_rx (
        .eq_mode(EQ_MMSE),
        .noise_var(24'sd64),
        .rx_time_cp(rayleigh_cp),
        .data_symbols(rayleigh_data),
        .h_est(rayleigh_h)
    );

    task automatic expect_near(input string name, input q_t got, input q_t exp, input int tol);
        longint signed d;
        begin
            d = longint'(got) - longint'(exp);
            if (d < 0) d = -d;
            if (d > tol) begin
                $display("[FAIL] %s expected %0d got %0d tol %0d", name, exp, got, tol);
                failures++;
            end
        end
    endtask

    task automatic read_complex_file(input string path, output cplx_t values [FRAME_LEN]);
        int local_fd;
        int local_rc;
        int re_i;
        int im_i;
        begin
            local_fd = $fopen(path, "r");
            if (local_fd == 0) begin
                $display("[FAIL] could not open %s", path);
                failures++;
            end else begin
                for (int n = 0; n < FRAME_LEN; n++) begin
                    local_rc = $fscanf(local_fd, "%d %d\n", re_i, im_i);
                    values[n] = c_make(q_t'(re_i), q_t'(im_i));
                    if (local_rc != 2) begin
                        $display("[FAIL] malformed complex vector %s line %0d", path, n);
                        failures++;
                    end
                end
                $fclose(local_fd);
            end
        end
    endtask

    initial begin
        failures = 0;

        fd = $fopen("vectors/scoreboard_qam_cases.txt", "r");
        if (fd == 0) begin
            $display("[FAIL] missing vectors/scoreboard_qam_cases.txt");
            failures++;
        end else begin
            for (i = 0; i < QAM_CASES; i++) begin
                rc = $fscanf(fd, "%d %d %d %d\n", scheme_i, bits_i, exp_re, exp_im);
                scheme = scheme_i[1:0];
                bits = bits_i[5:0];
                #1;
                if (rc != 4) begin
                    $display("[FAIL] malformed qam case %0d", i);
                    failures++;
                end
                expect_near("scoreboard qam re", mapped.re, q_t'(exp_re), 64);
                expect_near("scoreboard qam im", mapped.im, q_t'(exp_im), 64);
            end
            $fclose(fd);
        end

        fd = $fopen("vectors/scoreboard_data_q16.txt", "r");
        if (fd == 0) begin
            $display("[FAIL] missing vectors/scoreboard_data_q16.txt");
            failures++;
        end else begin
            for (i = 0; i < DATA_PER_FRAME; i++) begin
                rc = $fscanf(fd, "%d %d\n", exp_re, exp_im);
                data[i] = c_make(q_t'(exp_re), q_t'(exp_im));
                if (rc != 2) failures++;
            end
            $fclose(fd);
        end

        read_complex_file("vectors/scoreboard_tx_cp_q16.txt", exp_tx_cp);
        read_complex_file("vectors/scoreboard_awgn_cp_q16.txt", awgn_cp);
        read_complex_file("vectors/scoreboard_rayleigh_cp_q16.txt", rayleigh_cp);
        #1;

        for (i = 0; i < FRAME_LEN; i++) begin
            expect_near("python ofdm tx cp re", tx_cp[i].re, exp_tx_cp[i].re, 160);
            expect_near("python ofdm tx cp im", tx_cp[i].im, exp_tx_cp[i].im, 160);
        end

        for (i = 0; i < DATA_PER_FRAME; i++) begin
            expect_near("awgn high snr re", awgn_data[i].re, data[i].re, 1024);
            expect_near("awgn high snr im", awgn_data[i].im, data[i].im, 1024);
        end

        for (i = 0; i < DATA_PER_FRAME; i++) begin
            if (rayleigh_data[i].re > 24'sd4000000 || rayleigh_data[i].re < -24'sd4000000 ||
                rayleigh_data[i].im > 24'sd4000000 || rayleigh_data[i].im < -24'sd4000000) begin
                $display("[FAIL] rayleigh smoke output out of bounds at %0d", i);
                failures++;
            end
        end

        fd = $fopen("vectors/scoreboard_recip_cases.txt", "r");
        if (fd == 0) begin
            $display("[FAIL] missing vectors/scoreboard_recip_cases.txt");
            failures++;
        end else begin
            for (i = 0; i < RECIP_CASES; i++) begin
                rc = $fscanf(fd, "%d %d\n", x_i, recip_i);
                got_recip = q_recip_approx(q_t'(x_i));
                if (rc != 2) failures++;
                expect_near("reciprocal approx", q_t'(got_recip), q_t'(recip_i), 4096);
            end
            $fclose(fd);
        end

        if (failures == 0) begin
            $display("[ OK ] OFDM Python scoreboard regression passed");
        end else begin
            $display("[FAIL] %0d OFDM scoreboard issue(s)", failures);
            $fatal(1, "OFDM scoreboard regression failed");
        end
        $finish;
    end
endmodule
