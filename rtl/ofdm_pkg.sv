package ofdm_pkg;
    localparam int N = 64;
    localparam int CP_LEN = 16;
    localparam int FRAME_LEN = N + CP_LEN;
    localparam int PILOT_SPACING = 8;
    localparam int PILOTS_PER_FRAME = N / PILOT_SPACING;
    localparam int DATA_PER_FRAME = N - PILOTS_PER_FRAME;
    localparam int FFT_STAGES = 6;

    localparam int QW = 24;
    localparam int QFRAC = 16;
    localparam longint signed Q_MAX_L = (64'sd1 <<< (QW - 1)) - 64'sd1;
    localparam longint signed Q_MIN_L = -(64'sd1 <<< (QW - 1));

    typedef logic signed [QW-1:0] q_t;

    typedef struct packed {
        q_t re;
        q_t im;
    } cplx_t;

    localparam q_t Q_ZERO = 24'sd0;
    localparam q_t Q_ONE = 24'sd65536;
    localparam q_t Q_NEG_ONE = -24'sd65536;
    localparam q_t Q_EPS = 24'sd64;

    localparam logic [1:0] MOD_QPSK = 2'd0;
    localparam logic [1:0] MOD_QAM16 = 2'd1;
    localparam logic [1:0] MOD_QAM64 = 2'd2;

    localparam logic EQ_MMSE = 1'b0;
    localparam logic EQ_ZF = 1'b1;

    function automatic q_t q_sat(input longint signed value);
        if (value > Q_MAX_L) begin
            q_sat = q_t'(Q_MAX_L);
        end else if (value < Q_MIN_L) begin
            q_sat = q_t'(Q_MIN_L);
        end else begin
            q_sat = q_t'(value);
        end
    endfunction

    function automatic q_t q_add(input q_t a, input q_t b);
        longint signed aa;
        longint signed bb;
        begin
            aa = a;
            bb = b;
            q_add = q_sat(aa + bb);
        end
    endfunction

    function automatic q_t q_sub(input q_t a, input q_t b);
        longint signed aa;
        longint signed bb;
        begin
            aa = a;
            bb = b;
            q_sub = q_sat(aa - bb);
        end
    endfunction

    function automatic q_t q_neg(input q_t a);
        longint signed aa;
        begin
            aa = a;
            q_neg = q_sat(-aa);
        end
    endfunction

    function automatic q_t q_mul(input q_t a, input q_t b);
        longint signed aa;
        longint signed bb;
        longint signed prod;
        begin
            aa = a;
            bb = b;
            prod = aa * bb;
            q_mul = q_sat(prod >>> QFRAC);
        end
    endfunction

    function automatic q_t q_div_small(input q_t a, input int unsigned d);
        longint signed aa;
        begin
            aa = a;
            q_div_small = (d == 0) ? Q_ZERO : q_sat(aa / longint'(d));
        end
    endfunction

    function automatic q_t q_mul_small(input q_t a, input int signed m);
        longint signed aa;
        begin
            aa = a;
            q_mul_small = q_sat(aa * longint'(m));
        end
    endfunction

    function automatic q_t q_recip(input q_t x);
        longint signed xx;
        longint signed numer;
        begin
            xx = x;
            numer = 64'sd1 <<< (2 * QFRAC);
            if (xx <= 0) begin
                q_recip = q_t'(Q_MAX_L);
            end else begin
                q_recip = q_sat(numer / xx);
            end
        end
    endfunction

    function automatic cplx_t c_make(input q_t re, input q_t im);
        cplx_t z;
        begin
            z.re = re;
            z.im = im;
            c_make = z;
        end
    endfunction

    function automatic cplx_t c_zero();
        c_zero = c_make(Q_ZERO, Q_ZERO);
    endfunction

    function automatic cplx_t c_add(input cplx_t a, input cplx_t b);
        cplx_t z;
        begin
            z.re = q_add(a.re, b.re);
            z.im = q_add(a.im, b.im);
            c_add = z;
        end
    endfunction

    function automatic cplx_t c_sub(input cplx_t a, input cplx_t b);
        cplx_t z;
        begin
            z.re = q_sub(a.re, b.re);
            z.im = q_sub(a.im, b.im);
            c_sub = z;
        end
    endfunction

    function automatic cplx_t c_neg(input cplx_t a);
        cplx_t z;
        begin
            z.re = q_neg(a.re);
            z.im = q_neg(a.im);
            c_neg = z;
        end
    endfunction

    function automatic cplx_t c_conj(input cplx_t a);
        cplx_t z;
        begin
            z.re = a.re;
            z.im = q_neg(a.im);
            c_conj = z;
        end
    endfunction

    function automatic cplx_t c_mul(input cplx_t a, input cplx_t b);
        cplx_t z;
        begin
            z.re = q_sub(q_mul(a.re, b.re), q_mul(a.im, b.im));
            z.im = q_add(q_mul(a.re, b.im), q_mul(a.im, b.re));
            c_mul = z;
        end
    endfunction

    function automatic cplx_t c_scale_q(input cplx_t a, input q_t gain);
        cplx_t z;
        begin
            z.re = q_mul(a.re, gain);
            z.im = q_mul(a.im, gain);
            c_scale_q = z;
        end
    endfunction

    function automatic cplx_t c_shift_right(input cplx_t a, input int unsigned sh);
        cplx_t z;
        begin
            z.re = q_t'(a.re >>> sh);
            z.im = q_t'(a.im >>> sh);
            c_shift_right = z;
        end
    endfunction

    function automatic q_t c_abs2(input cplx_t a);
        c_abs2 = q_add(q_mul(a.re, a.re), q_mul(a.im, a.im));
    endfunction

    function automatic cplx_t pilot_value(input int unsigned pilot_index);
        if ((pilot_index & 1) == 0) begin
            pilot_value = c_make(Q_ONE, Q_ZERO);
        end else begin
            pilot_value = c_make(Q_NEG_ONE, Q_ZERO);
        end
    endfunction
endpackage

