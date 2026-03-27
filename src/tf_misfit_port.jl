"""
=====================================================================
Time-Frequency Misfit Analysis (Julia port of Fortran code)
=====================================================================

This program computes time-frequency misfits between two signals using
continuous wavelet transforms (CWT) based on the Morlet wavelet.

Overview
--------
Given two input signals S1 and S2 (possibly multi-component), the code:

1. Transforms each signal to the frequency domain using a custom FFT
   (ported from the original Fortran routine FCOOLR).

2. Computes their Continuous Wavelet Transform (CWT) using a
   frequency-domain Morlet wavelet.

3. Builds a time-frequency representation (TFR) of both signals.

4. Computes misfit measures between S1 and S2:

   - TFEM: Time-Frequency Envelope Misfit
   - TFPM: Time-Frequency Phase Misfit
   - TEM / TPM: Time-dependent misfits (averaged over frequency)
   - FEM / FPM: Frequency-dependent misfits (averaged over time)
   - EM / PM: Global scalar misfits

5. Optionally applies:
   - Global normalization (tf_misfits_glob)
   - Local normalization (tf_misfits_loc)

6. Outputs multiple diagnostic files containing:
   - Time-frequency misfit maps
   - Marginal misfits (time / frequency)
   - Wavelet power spectra (|CWT|^2)
   - Goodness-of-fit metrics


More info
---------
For more details we encourage the user to read:

1. Kristekova M., J. Kristek, P. Moczo, and S.M. Day, 2006.
   Misfit criteria for quantitative comparison of seismograms.
   Bull. Seism. Soc. Am. 96, 1836-1850,
   doi: 10.1785/0120060012.

2. Kristekova M., Kristek J., Moczo P., 2009.
   Time-frequency misfit and goodness-of-fit criteria
   for quantitative comparison of time signals.
   Geophys. J. Int. 178, 813-825,
   doi: 10.1111/j.1365-246X.2009.04177.x.

=====================================================================
"""

# ============================================================
# GLOBAL (ported from Fortran MODULE GLOBAL)
# ============================================================
const KN = 16
const NF = 2 ^ KN
const PI = pi
const W0 = 6.0


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


# ============================================================
# TF_MISFITS_GLOB
# ============================================================
function tf_misfits_glob(s1, s2, nc::Int, dt::Float64, mt::Int, fmin::Float64, fmax::Float64, nf_tf::Int, is_s2_reference::Bool)
    de = zeros(Float64, nc, mt, nf_tf)
    dp = zeros(Float64, nc, mt, nf_tf)
    det = zeros(Float64, nc, max(mt, nf_tf))
    dpt = zeros(Float64, nc, max(mt, nf_tf))
    d_ef = zeros(Float64, nc, max(mt, nf_tf))
    dpf = zeros(Float64, nc, max(mt, nf_tf))

    ss1 = zeros(ComplexF64, nc, NF)
    ss2 = zeros(ComplexF64, nc, NF)
    wv1 = zeros(ComplexF64, nc, mt, nf_tf)
    wv2 = zeros(ComplexF64, nc, mt, nf_tf)
    wv_ref = zeros(ComplexF64, nc, mt, nf_tf)

    df = 1.0 / (dt * float(NF))
    ff = exp(log(fmax / fmin) / float(nf_tf - 1))

    for j in 1:nc
        for i in 1:mt
            ss1[j, i] = ComplexF64(s1[j, i], 0.0)
            ss2[j, i] = ComplexF64(s2[j, i], 0.0)
        end

        ss1[j, :] .= fcoolr_complex(KN, vec(ss1[j, :]), -1.0)
        ss2[j, :] .= fcoolr_complex(KN, vec(ss2[j, :]), -1.0)

        ss1[j, :] .*= dt
        ss2[j, :] .*= dt

        wv1[j, :, :] .= cwt(vec(ss1[j, :]), mt, nf_tf, df, ff, fmin)
        wv2[j, :, :] .= cwt(vec(ss2[j, :]), mt, nf_tf, df, ff, fmin)

        if (!is_s2_reference) && (maximum(abs.(wv1[j, :, :])) < maximum(abs.(wv2[j, :, :])))
            wv_ref[j, :, :] .= wv1[j, :, :]
        else
            wv_ref[j, :, :] .= wv2[j, :, :]
        end
    end

    cwt1 = abs.(wv1).^2
    cwt2 = abs.(wv2).^2

    maxtf = maximum(abs.(wv_ref))
    de .= abs.(wv1) .- abs.(wv2)

    for i in 1:mt, l in 1:nf_tf, j in 1:nc
        if (abs(wv1[j, i, l]) == 0.0) || (abs(wv2[j, i, l]) == 0.0)
            dp[j, i, l] = 0.0
        else
            ratio = wv1[j, i, l] / wv2[j, i, l]
            dp[j, i, l] = atan(imag(ratio), real(ratio)) / PI
        end
        dp[j, i, l] = abs(wv_ref[j, i, l]) * dp[j, i, l]
    end

    tfem = de / maxtf
    tfpm = dp / maxtf

    for i in 1:mt
        det[:, i] .= sum(de[:, i, :], dims=2)[:, 1] ./ float(nf_tf)
        dpt[:, i] .= sum(dp[:, i, :], dims=2)[:, 1] ./ float(nf_tf)
    end

    for l in 1:nf_tf
        d_ef[:, l] .= sum(de[:, :, l], dims=2)[:, 1] ./ float(mt)
        dpf[:, l] .= sum(dp[:, :, l], dims=2)[:, 1] ./ float(mt)
    end

    maxdenom = 0.0
    for i in 1:mt, j in 1:nc
        denoms = sum(abs.(wv_ref[j, i, :])) / float(nf_tf)
        maxdenom = max(maxdenom, denoms)
    end

    tem = zeros(Float64, nc, mt)
    tpm = zeros(Float64, nc, mt)
    for i in 1:mt
        tem[:, i] .= det[:, i] ./ maxdenom
        tpm[:, i] .= dpt[:, i] ./ maxdenom
    end

    maxdenom = 0.0
    for l in 1:nf_tf, j in 1:nc
        denoms = sum(abs.(wv_ref[j, :, l])) / float(mt)
        maxdenom = max(maxdenom, denoms)
    end

    fem = zeros(Float64, nc, nf_tf)
    fpm = zeros(Float64, nc, nf_tf)
    for l in 1:nf_tf
        fem[:, l] .= d_ef[:, l] ./ maxdenom
        fpm[:, l] .= dpf[:, l] ./ maxdenom
    end

    maxdenom = 0.0
    for j in 1:nc
        denoms = sum(abs.(wv_ref[j, :, :]).^2)
        maxdenom = max(maxdenom, denoms)
    end

    em = zeros(Float64, nc)
    pm = zeros(Float64, nc)
    for j in 1:nc
        nomse = sum(abs.(de[j, :, :]).^2)
        nomsp = sum(abs.(dp[j, :, :]).^2)
        em[j] = sqrt(nomse / maxdenom)
        pm[j] = sqrt(nomsp / maxdenom)
    end

    return tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2
end


# ============================================================
# TF_MISFITS_LOC
# ============================================================
function tf_misfits_loc(s1, s2, nc::Int, dt::Float64, mt::Int, fmin::Float64, fmax::Float64, nf_tf::Int, is_s2_reference::Bool)
    de = zeros(Float64, nc, mt, nf_tf)
    dp = zeros(Float64, nc, mt, nf_tf)
    det = zeros(Float64, nc, max(mt, nf_tf))
    dpt = zeros(Float64, nc, max(mt, nf_tf))
    d_ef = zeros(Float64, nc, max(mt, nf_tf))
    dpf = zeros(Float64, nc, max(mt, nf_tf))

    ss1 = zeros(ComplexF64, nc, NF)
    ss2 = zeros(ComplexF64, nc, NF)
    wv1 = zeros(ComplexF64, nc, mt, nf_tf)
    wv2 = zeros(ComplexF64, nc, mt, nf_tf)
    wv_ref = zeros(ComplexF64, nc, mt, nf_tf)

    df = 1.0 / (dt * float(NF))
    ff = exp(log(fmax / fmin) / float(nf_tf - 1))

    for j in 1:nc
        for i in 1:mt
            ss1[j, i] = ComplexF64(s1[j, i], 0.0)
            ss2[j, i] = ComplexF64(s2[j, i], 0.0)
        end

        ss1[j, :] .= fcoolr_complex(KN, vec(ss1[j, :]), -1.0)
        ss2[j, :] .= fcoolr_complex(KN, vec(ss2[j, :]), -1.0)

        ss1[j, :] .*= dt
        ss2[j, :] .*= dt

        wv1[j, :, :] .= cwt(vec(ss1[j, :]), mt, nf_tf, df, ff, fmin)
        wv2[j, :, :] .= cwt(vec(ss2[j, :]), mt, nf_tf, df, ff, fmin)

        if (!is_s2_reference) && (maximum(abs.(wv1[j, :, :])) < maximum(abs.(wv2[j, :, :])))
            wv_ref[j, :, :] .= wv1[j, :, :]
        else
            wv_ref[j, :, :] .= wv2[j, :, :]
        end
    end

    cwt1 = abs.(wv1).^2
    cwt2 = abs.(wv2).^2
    de .= abs.(wv1) .- abs.(wv2)

    for j in 1:nc, i in 1:mt, l in 1:nf_tf
        if (abs(wv1[j, i, l]) == 0.0) || (abs(wv2[j, i, l]) == 0.0)
            dp[j, i, l] = 0.0
        else
            ratio = wv1[j, i, l] / wv2[j, i, l]
            dp[j, i, l] = atan(imag(ratio), real(ratio)) / PI
        end
        dp[j, i, l] = abs(wv_ref[j, i, l]) * dp[j, i, l]
    end

    mv = maximum(abs.(wv_ref))
    tfem = zeros(Float64, nc, mt, nf_tf)
    for j in 1:nc, i in 1:mt, l in 1:nf_tf
        if abs(wv_ref[j, i, l]) < 0.000 * mv
            tfem[j, i, l] = -2.0
        else
            tfem[j, i, l] = de[j, i, l] / abs(wv_ref[j, i, l])
        end
    end

    tfpm = dp ./ abs.(wv_ref)

    for i in 1:mt
        det[:, i] .= sum(de[:, i, :], dims=2)[:, 1] ./ float(nf_tf)
        dpt[:, i] .= sum(dp[:, i, :], dims=2)[:, 1] ./ float(nf_tf)
    end

    for l in 1:nf_tf
        d_ef[:, l] .= sum(de[:, :, l], dims=2)[:, 1] ./ float(mt)
        dpf[:, l] .= sum(dp[:, :, l], dims=2)[:, 1] ./ float(mt)
    end

    tem = zeros(Float64, nc, mt)
    tpm = zeros(Float64, nc, mt)
    for i in 1:mt, j in 1:nc
        denoms = sum(abs.(wv_ref[j, i, :])) / float(nf_tf)
        tem[j, i] = det[j, i] / denoms
        tpm[j, i] = dpt[j, i] / denoms
    end

    fem = zeros(Float64, nc, nf_tf)
    fpm = zeros(Float64, nc, nf_tf)
    for l in 1:nf_tf, j in 1:nc
        denoms = sum(abs.(wv_ref[j, :, l])) / float(mt)
        fem[j, l] = d_ef[j, l] / denoms
        fpm[j, l] = dpf[j, l] / denoms
    end

    em = zeros(Float64, nc)
    pm = zeros(Float64, nc)
    for j in 1:nc
        nomse = sum(abs.(de[j, :, :]).^2)
        nomsp = sum(abs.(dp[j, :, :]).^2)
        denoms = sum(abs.(wv_ref[j, :, :]).^2)
        em[j] = sqrt(nomse / denoms)
        pm[j] = sqrt(nomsp / denoms)
    end

    return tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2
end


# ============================================================
# INPUT / OUTPUT HELPERS
# ============================================================
function strip_quotes(s::String)
    s = strip(s)
    if (startswith(s, "\"") && endswith(s, "\"")) || (startswith(s, "'") && endswith(s, "'"))
        return s[2:end-1]
    end
    return s
end


function parse_fortran_logical(s::String)
    u = uppercase(strip(s))
    return u in (".TRUE.", "TRUE", "T")
end


function read_fortran_namelist_input(filename::String)
    text = read(filename, String)
    text = replace(text, r"!.*" => "")
    text = replace(text, '\n' => ' ')
    text = replace(text, "&INPUT" => "")
    text = replace(text, "/" => "")

    params = Dict{String, String}()
    for part in split(text, ',')
        if occursin("=", part)
            kv = split(part, "=", limit=2)
            params[strip(uppercase(kv[1]))] = strip(kv[2])
        end
    end
    return params
end


function write_1d(filename::String, arr)
    open(filename, "w") do io
        for val in arr
            println(io, val)
        end
    end
end


function write_2d_slices(filename::String, arr, mt::Int, nf_tf::Int)
    open(filename, "w") do io
        for l in 1:nf_tf
            println(io, join((string(arr[i, l]) for i in 1:mt), " "))
        end
    end
end


# ============================================================
# MAIN
# ============================================================
function main(input_file::String="HF_TF-MISFIT_GOF")
    A = 10.0
    K = 1.0

    fmin = -999999.0
    fmax = -999999.0
    is_s2_reference = false
    local_norm = false
    nc = 1

    params = read_fortran_namelist_input(input_file)

    mt = parse(Int, params["MT"])
    dt = parse(Float64, params["DT"])
    s1_name = strip_quotes(params["S1_NAME"])
    s2_name = strip_quotes(params["S2_NAME"])

    if haskey(params, "NC")
        nc = parse(Int, params["NC"])
    end
    if haskey(params, "FMIN")
        fmin = parse(Float64, params["FMIN"])
    end
    if haskey(params, "FMAX")
        fmax = parse(Float64, params["FMAX"])
    end
    if haskey(params, "IS_S2_REFERENCE")
        is_s2_reference = parse_fortran_logical(params["IS_S2_REFERENCE"])
    end
    if haskey(params, "LOCAL_NORM")
        local_norm = parse_fortran_logical(params["LOCAL_NORM"])
    end

    if fmin == -999999.0
        fmin = 1.0 / float(mt) / dt
    end
    if fmax == -999999.0
        fmax = 1.0 / 2.0 / dt
    end

    ff = 1.0 + 1.0 / sqrt(2.0) / W0 / 30.0
    nf_tf = 1 + Int(floor(log(fmax / fmin) / log(ff)))

    s1 = zeros(Float64, nc, mt)
    s2 = zeros(Float64, nc, mt)

    open(s1_name, "r") do f1
        open(s2_name, "r") do f2
            open("S1.DAT", "w") do out1
                open("S2.DAT", "w") do out2
                    for i in 1:mt
                        row1 = parse.(Float64, split(readline(f1)))
                        row2 = parse.(Float64, split(readline(f2)))

                        vals1 = row1[2:min(1 + nc, end)]
                        vals2 = row2[2:min(1 + nc, end)]
                        if length(vals1) != nc || length(vals2) != nc
                            error("Row $i in input files does not contain NC=$nc values.")
                        end

                        for j in 1:nc
                            s1[j, i] = vals1[j]
                            s2[j, i] = vals2[j]
                        end

                        println(out1, string(dt * (i - 1), " ", join((string(s1[j, i]) for j in 1:nc), " ")))
                        println(out2, string(dt * (i - 1), " ", join((string(s2[j, i]) for j in 1:nc), " ")))
                    end
                end
            end
        end
    end

    if local_norm
        tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2 = tf_misfits_loc(
            s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference
        )
    else
        tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2 = tf_misfits_glob(
            s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference
        )
    end

    open("MISFIT-GOF.DAT", "w") do io
        println(io, "$fmin $fmax")
        println(io, "$nf_tf $mt")
        println(io, "$dt $nc")
        println(io, max(maximum(abs.(s1)), maximum(abs.(s2))))
        for j in 1:nc
            println(io, "$(em[j]) $(pm[j])")
        end
        for j in 1:nc
            println(io, "$(A * exp(-abs(em[j])^K)) $(A * (1.0 - abs(pm[j])^K))")
        end
        println(io, "$(maximum(abs.(tfem))) $(maximum(abs.(tfpm)))")
        println(io, "$(maximum(abs.(fem))) $(maximum(abs.(fpm)))")
        println(io, "$(maximum(abs.(tem))) $(maximum(abs.(tpm)))")
        println(io, "$(maximum(abs.(cwt1))) $(maximum(abs.(cwt2)))")
    end

    for j in 1:nc
        char = string(j)
        write_2d_slices("TFEM" * char * ".DAT", tfem[j, :, :], mt, nf_tf)
        write_2d_slices("TFPM" * char * ".DAT", tfpm[j, :, :], mt, nf_tf)
        write_1d("TEM" * char * ".DAT", tem[j, :])
        write_1d("TPM" * char * ".DAT", tpm[j, :])
        write_1d("FEM" * char * ".DAT", fem[j, :])
        write_1d("FPM" * char * ".DAT", fpm[j, :])
        write_2d_slices("TFRS1_" * char * ".DAT", cwt1[j, :, :], mt, nf_tf)
        write_2d_slices("TFRS2_" * char * ".DAT", cwt2[j, :, :], mt, nf_tf)
    end

    for j in 1:nc
        char = string(j)
        write_2d_slices("TFEG" * char * ".DAT", A .* exp.(-abs.(tfem[j, :, :]).^K), mt, nf_tf)
        write_2d_slices("TFPG" * char * ".DAT", A .* (1.0 .- abs.(tfpm[j, :, :]).^K), mt, nf_tf)
        write_1d("TEG" * char * ".DAT", A .* exp.(-abs.(tem[j, :]).^K))
        write_1d("TPG" * char * ".DAT", A .* (1.0 .- abs.(tpm[j, :]).^K))
        write_1d("FEG" * char * ".DAT", A .* exp.(-abs.(fem[j, :]).^K))
        write_1d("FPG" * char * ".DAT", A .* (1.0 .- abs.(fpm[j, :]).^K))
    end
end


if abspath(PROGRAM_FILE) == @__FILE__
    input_file = length(ARGS) >= 1 ? ARGS[1] : "HF_TF-MISFIT_GOF"
    main(input_file)
end
