# ============================================================
# CWT
# ============================================================
function cwt(f_v::Vector{ComplexF64}, mt::Int, nf_tf::Int, dfa::Float64, ff::Float64, fmin::Float64)
    if length(f_v) != NF
        error("f_v must have length NF=$NF, got $(length(f_v))")
    end

    cwt_out = zeros(ComplexF64, mt, nf_tf)
    nf21 = div(NF, 2) + 1
    f = fmin / ff

    for i in 1:nf_tf
        f *= ff
        s = W0 / (2.0 * PI * f)

        fpwv = zeros(ComplexF64, NF)
        for j in 1:nf21
            fpwv[j] = morlet(s, (j - 1) * dfa)
        end

        fwv = f_v .* conj.(fpwv)
        fwv = fcoolr_complex(KN, fwv, 1.0)

        @inbounds for t in 1:mt
            cwt_out[t, i] = fwv[t] * dfa * sqrt(s)
        end
    end

    return cwt_out
end