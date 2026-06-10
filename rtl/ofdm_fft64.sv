module ofdm_fft64 (
    input  logic inverse,
    input  ofdm_pkg::cplx_t in_frame [ofdm_pkg::N],
    output ofdm_pkg::cplx_t out_frame [ofdm_pkg::N]
);
    import ofdm_pkg::*;

    cplx_t work [N];
    cplx_t next_work [N];
    cplx_t tw;
    cplx_t t;
    cplx_t u;

    int i;
    int st;
    int m;
    int half_m;
    int step;
    int group_base;
    int j;
    int idx_a;
    int idx_b;

    function automatic int unsigned bit_reverse6(input int unsigned value);
        int unsigned r;
        int unsigned b;
        begin
            r = 0;
            for (b = 0; b < FFT_STAGES; b++) begin
                r = (r << 1) | ((value >> b) & 1);
            end
            bit_reverse6 = r;
        end
    endfunction

    function automatic cplx_t twiddle64_pos(input int unsigned index);
        cplx_t z;
        begin
            unique case (index[5:0])
                6'd0: begin z.re = 24'sd65536; z.im = 24'sd0; end
                6'd1: begin z.re = 24'sd65220; z.im = 24'sd6424; end
                6'd2: begin z.re = 24'sd64277; z.im = 24'sd12785; end
                6'd3: begin z.re = 24'sd62714; z.im = 24'sd19024; end
                6'd4: begin z.re = 24'sd60547; z.im = 24'sd25080; end
                6'd5: begin z.re = 24'sd57798; z.im = 24'sd30893; end
                6'd6: begin z.re = 24'sd54491; z.im = 24'sd36410; end
                6'd7: begin z.re = 24'sd50660; z.im = 24'sd41576; end
                6'd8: begin z.re = 24'sd46341; z.im = 24'sd46341; end
                6'd9: begin z.re = 24'sd41576; z.im = 24'sd50660; end
                6'd10: begin z.re = 24'sd36410; z.im = 24'sd54491; end
                6'd11: begin z.re = 24'sd30893; z.im = 24'sd57798; end
                6'd12: begin z.re = 24'sd25080; z.im = 24'sd60547; end
                6'd13: begin z.re = 24'sd19024; z.im = 24'sd62714; end
                6'd14: begin z.re = 24'sd12785; z.im = 24'sd64277; end
                6'd15: begin z.re = 24'sd6424; z.im = 24'sd65220; end
                6'd16: begin z.re = 24'sd0; z.im = 24'sd65536; end
                6'd17: begin z.re = -24'sd6424; z.im = 24'sd65220; end
                6'd18: begin z.re = -24'sd12785; z.im = 24'sd64277; end
                6'd19: begin z.re = -24'sd19024; z.im = 24'sd62714; end
                6'd20: begin z.re = -24'sd25080; z.im = 24'sd60547; end
                6'd21: begin z.re = -24'sd30893; z.im = 24'sd57798; end
                6'd22: begin z.re = -24'sd36410; z.im = 24'sd54491; end
                6'd23: begin z.re = -24'sd41576; z.im = 24'sd50660; end
                6'd24: begin z.re = -24'sd46341; z.im = 24'sd46341; end
                6'd25: begin z.re = -24'sd50660; z.im = 24'sd41576; end
                6'd26: begin z.re = -24'sd54491; z.im = 24'sd36410; end
                6'd27: begin z.re = -24'sd57798; z.im = 24'sd30893; end
                6'd28: begin z.re = -24'sd60547; z.im = 24'sd25080; end
                6'd29: begin z.re = -24'sd62714; z.im = 24'sd19024; end
                6'd30: begin z.re = -24'sd64277; z.im = 24'sd12785; end
                6'd31: begin z.re = -24'sd65220; z.im = 24'sd6424; end
                6'd32: begin z.re = -24'sd65536; z.im = 24'sd0; end
                default: begin z.re = 24'sd0; z.im = 24'sd0; end
            endcase
            twiddle64_pos = z;
        end
    endfunction

    function automatic cplx_t twiddle64(input int unsigned index, input logic inv);
        cplx_t z;
        begin
            z = twiddle64_pos(index & 6'h3f);
            if (!inv) begin
                z.im = q_neg(z.im);
            end
            twiddle64 = z;
        end
    endfunction

    always_comb begin
        for (i = 0; i < N; i++) begin
            work[i] = in_frame[bit_reverse6(i)];
            next_work[i] = c_zero();
        end

        for (st = 1; st <= FFT_STAGES; st++) begin
            m = 1 << st;
            half_m = m >> 1;
            step = N / m;

            for (group_base = 0; group_base < N; group_base += m) begin
                for (j = 0; j < half_m; j++) begin
                    idx_a = group_base + j;
                    idx_b = idx_a + half_m;
                    tw = twiddle64(j * step, inverse);
                    t = c_mul(work[idx_b], tw);
                    u = work[idx_a];
                    next_work[idx_a] = c_add(u, t);
                    next_work[idx_b] = c_sub(u, t);
                end
            end

            for (i = 0; i < N; i++) begin
                work[i] = next_work[i];
            end
        end

        for (i = 0; i < N; i++) begin
            out_frame[i] = c_shift_right(work[i], 3);
        end
    end
endmodule

