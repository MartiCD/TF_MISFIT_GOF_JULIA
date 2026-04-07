# ============================================================
# MORLET
# ============================================================
function morlet(s, fa)
    pi14 = 0.7511255444649
    if fa == 0.0
        return ComplexF64(0.0, 0.0)
    else
        val = pi14 * exp(-((s * 2.0 * PI * fa - W0)^2) / 2.0)
        return ComplexF64(val, 0.0)
    end
end


# ============================================================
# FCOOLR (faithful port)
# ============================================================
function fcoolr!(k::Int, d::Vector{Float64}, sn::Float64)
    lx = 2 ^ k
    pi_local = 3.141592654
    pi2 = 2.0 * pi_local

    inu = zeros(Int, 32)
    q1 = float(lx)
    il = lx
    sh = sn * pi2 / q1

    for i in 1:k
        il = div(il, 2)
        inu[i] = il
    end

    nkk = 1

    for la in 1:k
        nck = nkk
        nkk = nkk + nkk
        lck = div(lx, nck)
        l2k = lck + lck
        nw = 0

        for ick in 1:nck
            fnw = float(nw)
            aa = sh * fnw
            w1 = cos(aa)
            w2 = sin(aa)
            ls = l2k * (ick - 1)

            for i in 2:2:lck
                j1 = i + ls
                j = j1 - 1
                jh = j + lck
                jh1 = jh + 1

                q1 = d[jh] * w1 - d[jh1] * w2
                q2 = d[jh] * w2 + d[jh1] * w1

                d[jh] = d[j] - q1
                d[jh1] = d[j1] - q2
                d[j] = d[j] + q1
                d[j1] = d[j1] + q2
            end

            idx = 0
            for i in 2:k
                idx = inu[i]
                il = idx + idx
                if (nw - idx - il * div(nw, il)) < 0
                    break
                end
                nw -= idx
            end
            nw += idx
        end
    end

    nw = 0

    for j in 1:lx
        if (nw - j) >= 0
            jj = nw + nw + 1
            j1 = jj + 1
            jh1 = j + j
            jh = jh1 - 1

            q1 = d[jj]
            d[jj] = d[jh]
            d[jh] = q1

            q1 = d[j1]
            d[j1] = d[jh1]
            d[jh1] = q1
        end

        idx = 0
        for i in 1:k
            idx = inu[i]
            il = idx + idx
            if (nw - idx - il * div(nw, il)) < 0
                break
            end
            nw -= idx
        end
        nw += idx
    end

    return d
end


function fcoolr_complex(k::Int, z::Vector{ComplexF64}, sn::Float64)
    lx = 2 ^ k
    if length(z) != lx
        error("length(z) must be 2^k = $lx, got $(length(z))")
    end

    d = Vector{Float64}(undef, 2 * lx)
    @inbounds for i in 1:lx
        d[2i - 1] = real(z[i])
        d[2i] = imag(z[i])
    end

    fcoolr!(k, d, sn)

    out = Vector{ComplexF64}(undef, lx)
    @inbounds for i in 1:lx
        out[i] = ComplexF64(d[2i - 1], d[2i])
    end
    return out
end