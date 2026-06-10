`timescale 1ns/1ps

module ofdm_stream_tb;
    import ofdm_pkg::*;

    logic clk;
    logic rst_n;

    logic tx_in_valid;
    logic tx_in_ready;
    q_t tx_in_i;
    q_t tx_in_q;
    logic tx_out_valid;
    logic tx_out_ready;
    q_t tx_out_i;
    q_t tx_out_q;

    logic rx_in_valid;
    logic rx_in_ready;
    q_t rx_in_i;
    q_t rx_in_q;
    logic rx_out_valid;
    logic rx_out_ready;
    q_t rx_out_i;
    q_t rx_out_q;

    cplx_t data [DATA_PER_FRAME];
    cplx_t tx_expected [FRAME_LEN];
    cplx_t tx_captured [FRAME_LEN];
    cplx_t rx_captured [DATA_PER_FRAME];

    int failures;
    int cycle;

    ofdm_tx_frame u_ref_tx (
        .data_symbols(data),
        .tx_time_cp(tx_expected)
    );

    ofdm_tx_stream u_tx_stream (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(tx_in_valid),
        .in_ready(tx_in_ready),
        .in_data_i(tx_in_i),
        .in_data_q(tx_in_q),
        .out_valid(tx_out_valid),
        .out_ready(tx_out_ready),
        .out_data_i(tx_out_i),
        .out_data_q(tx_out_q)
    );

    ofdm_rx_stream u_rx_stream (
        .clk(clk),
        .rst_n(rst_n),
        .eq_mode(EQ_MMSE),
        .noise_var(Q_ZERO),
        .in_valid(rx_in_valid),
        .in_ready(rx_in_ready),
        .in_data_i(rx_in_i),
        .in_data_q(rx_in_q),
        .out_valid(rx_out_valid),
        .out_ready(rx_out_ready),
        .out_data_i(rx_out_i),
        .out_data_q(rx_out_q)
    );

    always #5 clk = !clk;

    task automatic tick;
        begin
            @(posedge clk);
            cycle++;
        end
    endtask

    task automatic expect_near(input string name, input q_t got, input q_t exp, input int tol);
        longint signed d;
        begin
            d = longint'(got) - longint'(exp);
            if (d < 0) d = -d;
            if (d > tol) begin
                $display("[FAIL] %s expected %0d got %0d", name, exp, got);
                failures++;
            end
        end
    endtask

    task automatic load_data_pattern(input int frame_id);
        begin
            for (int i = 0; i < DATA_PER_FRAME; i++) begin
                if (frame_id == 0) begin
                    data[i] = (i & 1) ? c_make(24'sd46341, -24'sd46341)
                                      : c_make(-24'sd46341, 24'sd46341);
                end else begin
                    unique case (i % 4)
                        0: data[i] = c_make(24'sd46341, 24'sd46341);
                        1: data[i] = c_make(24'sd46341, -24'sd46341);
                        2: data[i] = c_make(-24'sd46341, -24'sd46341);
                        default: data[i] = c_make(-24'sd46341, 24'sd46341);
                    endcase
                end
            end
        end
    endtask

    task automatic run_tx_stream(input int frame_id);
        int sent;
        int recv;
        int guard;
        logic take_in;
        logic take_out;
        q_t cap_i;
        q_t cap_q;
        begin
            sent = 0;
            recv = 0;
            guard = 0;

            while ((sent < DATA_PER_FRAME || recv < FRAME_LEN) && guard < 2000) begin
                @(negedge clk);
                tx_in_valid = (sent < DATA_PER_FRAME) && ((guard % 5) != 3);
                if (sent < DATA_PER_FRAME) begin
                    tx_in_i = data[sent].re;
                    tx_in_q = data[sent].im;
                end else begin
                    tx_in_i = Q_ZERO;
                    tx_in_q = Q_ZERO;
                end
                tx_out_ready = ((guard % 7) != 2);

                #1;
                take_in = tx_in_valid && tx_in_ready;
                take_out = tx_out_valid && tx_out_ready;
                cap_i = tx_out_i;
                cap_q = tx_out_q;

                @(posedge clk);
                #1;
                if (take_in) sent++;
                if (take_out) begin
                    tx_captured[recv] = c_make(cap_i, cap_q);
                    recv++;
                end
                guard++;
            end

            tx_in_valid = 1'b0;
            tx_out_ready = 1'b0;
            if (sent != DATA_PER_FRAME || recv != FRAME_LEN) begin
                $display("[FAIL] tx stream timeout frame=%0d sent=%0d recv=%0d state=%0d in_count=%0d out_count=%0d",
                    frame_id, sent, recv, u_tx_stream.state, u_tx_stream.in_count, u_tx_stream.out_count);
                failures++;
            end
        end
    endtask

    task automatic run_rx_stream(input int frame_id);
        int sent;
        int recv;
        int guard;
        logic take_in;
        logic take_out;
        q_t cap_i;
        q_t cap_q;
        begin
            sent = 0;
            recv = 0;
            guard = 0;

            while ((sent < FRAME_LEN || recv < DATA_PER_FRAME) && guard < 3000) begin
                @(negedge clk);
                rx_in_valid = (sent < FRAME_LEN) && ((guard % 6) != 1);
                if (sent < FRAME_LEN) begin
                    rx_in_i = tx_expected[sent].re;
                    rx_in_q = tx_expected[sent].im;
                end else begin
                    rx_in_i = Q_ZERO;
                    rx_in_q = Q_ZERO;
                end
                rx_out_ready = ((guard % 4) != 1);

                #1;
                take_in = rx_in_valid && rx_in_ready;
                take_out = rx_out_valid && rx_out_ready;
                cap_i = rx_out_i;
                cap_q = rx_out_q;

                @(posedge clk);
                #1;
                if (take_in) sent++;
                if (take_out) begin
                    rx_captured[recv] = c_make(cap_i, cap_q);
                    recv++;
                end
                guard++;
            end

            rx_in_valid = 1'b0;
            rx_out_ready = 1'b0;
            if (sent != FRAME_LEN || recv != DATA_PER_FRAME) begin
                $display("[FAIL] rx stream timeout frame=%0d sent=%0d recv=%0d state=%0d in_count=%0d out_count=%0d",
                    frame_id, sent, recv, u_rx_stream.state, u_rx_stream.in_count, u_rx_stream.out_count);
                failures++;
            end
        end
    endtask

    task automatic run_stream_frame(input int frame_id);
        begin
            load_data_pattern(frame_id);
            #1;

            run_tx_stream(frame_id);
            for (int i = 0; i < FRAME_LEN; i++) begin
                expect_near("tx stream re", tx_captured[i].re, tx_expected[i].re, 2);
                expect_near("tx stream im", tx_captured[i].im, tx_expected[i].im, 2);
            end

            run_rx_stream(frame_id);
            for (int i = 0; i < DATA_PER_FRAME; i++) begin
                expect_near("rx stream re", rx_captured[i].re, data[i].re, 512);
                expect_near("rx stream im", rx_captured[i].im, data[i].im, 512);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        tx_in_valid = 1'b0;
        tx_in_i = Q_ZERO;
        tx_in_q = Q_ZERO;
        tx_out_ready = 1'b0;
        rx_in_valid = 1'b0;
        rx_in_i = Q_ZERO;
        rx_in_q = Q_ZERO;
        rx_out_ready = 1'b0;
        failures = 0;
        cycle = 0;

        repeat (4) tick();
        @(negedge clk);
        rst_n = 1'b1;
        repeat (2) tick();

        @(negedge clk);
        #1;
        if (!tx_in_ready || !rx_in_ready) begin
            $display("[FAIL] stream wrappers not ready after reset tx_ready=%0b rx_ready=%0b",
                tx_in_ready, rx_in_ready);
            failures++;
        end

        run_stream_frame(0);
        run_stream_frame(1);

        if (failures == 0) begin
            $display("[ OK ] OFDM streaming valid/ready regression passed");
        end else begin
            $display("[FAIL] %0d OFDM streaming issue(s)", failures);
            $fatal(1, "OFDM streaming regression failed");
        end
        $finish;
    end
endmodule
