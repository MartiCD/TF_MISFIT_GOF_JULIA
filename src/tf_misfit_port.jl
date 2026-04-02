# =====================================================================
# Time-Frequency Misfit Analysis (Julia port of Fortran code)
# =====================================================================

# This program computes time-frequency misfits between two signals using
# continuous wavelet transforms (CWT) based on the Morlet wavelet.

# Overview
# --------
# Given two input signals S1 and S2 (possibly multi-component), the code:

# 1. Transforms each signal to the frequency domain using a custom FFT
#    (ported from the original Fortran routine FCOOLR).

# 2. Computes their Continuous Wavelet Transform (CWT) using a
#    frequency-domain Morlet wavelet.

# 3. Builds a time-frequency representation (TFR) of both signals.

# 4. Computes misfit measures between S1 and S2:

#    - TFEM: Time-Frequency Envelope Misfit
#    - TFPM: Time-Frequency Phase Misfit
#    - TEM / TPM: Time-dependent misfits (averaged over frequency)
#    - FEM / FPM: Frequency-dependent misfits (averaged over time)
#    - EM / PM: Global scalar misfits

# 5. Optionally applies:
#    - Global normalization (tf_misfits_glob)
#    - Local normalization (tf_misfits_loc)

# 6. Outputs multiple diagnostic files containing:
#    - Time-frequency misfit maps
#    - Marginal misfits (time / frequency)
#    - Wavelet power spectra (|CWT|^2)
#    - Goodness-of-fit metrics


# More info
# ---------
# For more details we encourage the user to read:

# 1. Kristekova M., J. Kristek, P. Moczo, and S.M. Day, 2006.
#    Misfit criteria for quantitative comparison of seismograms.
#    Bull. Seism. Soc. Am. 96, 1836-1850,
#    doi: 10.1785/0120060012.

# 2. Kristekova M., Kristek J., Moczo P., 2009.
#    Time-frequency misfit and goodness-of-fit criteria
#    for quantitative comparison of time signals.
#    Geophys. J. Int. 178, 813-825,
#    doi: 10.1111/j.1365-246X.2009.04177.x.

# =====================================================================

using HDF5

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
    df = 1.0 / (dt * float(NF))
    ff = exp(log(fmax / fmin) / float(nf_tf - 1))

    # Sortides finals
    tfem = zeros(Float64, nc, mt, nf_tf)
    tfpm = zeros(Float64, nc, mt, nf_tf)
    tem  = zeros(Float64, nc, mt)
    tpm  = zeros(Float64, nc, mt)
    fem  = zeros(Float64, nc, nf_tf)
    fpm  = zeros(Float64, nc, nf_tf)
    em   = zeros(Float64, nc)
    pm   = zeros(Float64, nc)
    cwt1 = zeros(Float64, nc, mt, nf_tf)
    cwt2 = zeros(Float64, nc, mt, nf_tf)

    # Acumuladors intermedis necessaris per a la normalització global
    det_all = zeros(Float64, nc, mt)
    dpt_all = zeros(Float64, nc, mt)
    def_all = zeros(Float64, nc, nf_tf)
    dpf_all = zeros(Float64, nc, nf_tf)

    denom_t_all = zeros(Float64, nc, mt)
    denom_f_all = zeros(Float64, nc, nf_tf)
    denom_e_all = zeros(Float64, nc)

    nomse_all = zeros(Float64, nc)
    nomsp_all = zeros(Float64, nc)

    # Buffers reutilitzables FFT
    ss1 = zeros(ComplexF64, NF)
    ss2 = zeros(ComplexF64, NF)

    # Per trobar el màxim global del senyal de referència
    maxtf = 0.0

    println("Computing FFTs and CWTs"); flush(stdout)

    @views for j in 1:nc
        fill!(ss1, 0.0 + 0.0im)
        fill!(ss2, 0.0 + 0.0im)

        @inbounds for i in 1:mt
            ss1[i] = ComplexF64(s1[j, i], 0.0)
            ss2[i] = ComplexF64(s2[j, i], 0.0)
        end

        ss1 .= fcoolr_complex(KN, ss1, -1.0)
        ss2 .= fcoolr_complex(KN, ss2, -1.0)

        @. ss1 = ss1 * dt
        @. ss2 = ss2 * dt

        # CWT del component actual
        wv1j = cwt(ss1, mt, nf_tf, df, ff, fmin)   # mt x nf_tf
        wv2j = cwt(ss2, mt, nf_tf, df, ff, fmin)   # mt x nf_tf

        println("Finished CWT for component ", j); flush(stdout)

        # Guardar cwt1/cwt2 i decidir referència
        local_max1 = 0.0
        local_max2 = 0.0

        @inbounds for l in 1:nf_tf, i in 1:mt
            a1 = abs(wv1j[i, l])
            a2 = abs(wv2j[i, l])

            cwt1[j, i, l] = a1 * a1
            cwt2[j, i, l] = a2 * a2

            if a1 > local_max1
                local_max1 = a1
            end
            if a2 > local_max2
                local_max2 = a2
            end
        end

        use_wv1_ref = (!is_s2_reference) && (local_max1 < local_max2)

        local_ref_max = use_wv1_ref ? local_max1 : local_max2
        if local_ref_max > maxtf
            maxtf = local_ref_max
        end

        # Acumuladors locals per component
        det_j = zeros(Float64, mt)
        dpt_j = zeros(Float64, mt)
        den_t_j = zeros(Float64, mt)

        def_j = zeros(Float64, nf_tf)
        dpf_j = zeros(Float64, nf_tf)
        den_f_j = zeros(Float64, nf_tf)

        nomse = 0.0
        nomsp = 0.0
        den_e = 0.0

        # Bucle principal
        @inbounds for l in 1:nf_tf
            for i in 1:mt
                z1 = wv1j[i, l]
                z2 = wv2j[i, l]

                a1 = abs(z1)
                a2 = abs(z2)

                aref = use_wv1_ref ? a1 : a2

                de_ijl = a1 - a2

                dp0 = if (a1 == 0.0) || (a2 == 0.0)
                    0.0
                else
                    ratio = z1 / z2
                    atan(imag(ratio), real(ratio)) / PI
                end

                dp_ijl = aref * dp0

                # tfem/tfpm es normalitzen després amb maxtf global
                tfem[j, i, l] = de_ijl
                tfpm[j, i, l] = dp_ijl

                # acumuladors temporals
                det_j[i] += de_ijl
                dpt_j[i] += dp_ijl
                den_t_j[i] += aref

                # acumuladors freqüencials
                def_j[l] += de_ijl
                dpf_j[l] += dp_ijl
                den_f_j[l] += aref

                # acumuladors globals energia
                nomse += de_ijl * de_ijl
                nomsp += dp_ijl * dp_ijl
                den_e += aref * aref
            end
        end

        inv_nf = 1.0 / float(nf_tf)
        inv_mt = 1.0 / float(mt)

        @inbounds for i in 1:mt
            det_all[j, i] = det_j[i] * inv_nf
            dpt_all[j, i] = dpt_j[i] * inv_nf
            denom_t_all[j, i] = den_t_j[i] * inv_nf
        end

        @inbounds for l in 1:nf_tf
            def_all[j, l] = def_j[l] * inv_mt
            dpf_all[j, l] = dpf_j[l] * inv_mt
            denom_f_all[j, l] = den_f_j[l] * inv_mt
        end

        nomse_all[j] = nomse
        nomsp_all[j] = nomsp
        denom_e_all[j] = den_e
    end

    # Normalització global TF
    if maxtf == 0.0
        fill!(tfem, 0.0)
        fill!(tfpm, 0.0)
    else
        @. tfem = tfem / maxtf
        @. tfpm = tfpm / maxtf
    end

    println("Computing marginal misfits (TEM/FEM)"); flush(stdout)

    # Màxim denominador global en temps
    maxdenom_t = 0.0
    @inbounds for j in 1:nc, i in 1:mt
        d = denom_t_all[j, i]
        if d > maxdenom_t
            maxdenom_t = d
        end
    end

    if maxdenom_t == 0.0
        fill!(tem, 0.0)
        fill!(tpm, 0.0)
    else
        @inbounds for j in 1:nc, i in 1:mt
            tem[j, i] = det_all[j, i] / maxdenom_t
            tpm[j, i] = dpt_all[j, i] / maxdenom_t
        end
    end

    # Màxim denominador global en freqüència
    maxdenom_f = 0.0
    @inbounds for j in 1:nc, l in 1:nf_tf
        d = denom_f_all[j, l]
        if d > maxdenom_f
            maxdenom_f = d
        end
    end

    if maxdenom_f == 0.0
        fill!(fem, 0.0)
        fill!(fpm, 0.0)
    else
        @inbounds for j in 1:nc, l in 1:nf_tf
            fem[j, l] = def_all[j, l] / maxdenom_f
            fpm[j, l] = dpf_all[j, l] / maxdenom_f
        end
    end

    # Màxim denominador global energètic
    println("Before maxdenom over wv_ref"); flush(stdout)

    maxdenom_e = 0.0
    @inbounds for j in 1:nc
        d = denom_e_all[j]
        if d > maxdenom_e
            maxdenom_e = d
        end
    end

    println("Before nomse/nomsp over de/dp"); flush(stdout)

    if maxdenom_e == 0.0
        fill!(em, 0.0)
        fill!(pm, 0.0)
    else
        @inbounds for j in 1:nc
            em[j] = sqrt(nomse_all[j] / maxdenom_e)
            pm[j] = sqrt(nomsp_all[j] / maxdenom_e)
        end
    end

    return tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2
end


# ============================================================
# TF_MISFITS_LOC
# ============================================================
function tf_misfits_loc(s1, s2, nc::Int, dt::Float64, mt::Int, fmin::Float64, fmax::Float64, nf_tf::Int, is_s2_reference::Bool)
    # IMPORTANT:
    # Assumim que NF i KN són globals constants o, idealment, passats com arguments.
    # Si són globals no constants, això pot penalitzar el rendiment.
    # Recomanació: const NF = ... ; const KN = ...

    df = 1.0 / (dt * float(NF))
    ff = exp(log(fmax / fmin) / float(nf_tf - 1))

    # Sortides finals
    tfem = zeros(Float64, nc, mt, nf_tf)
    tfpm = zeros(Float64, nc, mt, nf_tf)
    tem  = zeros(Float64, nc, mt)
    tpm  = zeros(Float64, nc, mt)
    fem  = zeros(Float64, nc, nf_tf)
    fpm  = zeros(Float64, nc, nf_tf)
    em   = zeros(Float64, nc)
    pm   = zeros(Float64, nc)
    cwt1 = zeros(Float64, nc, mt, nf_tf)
    cwt2 = zeros(Float64, nc, mt, nf_tf)

    # Buffers reutilitzables per FFT
    ss1 = zeros(ComplexF64, NF)
    ss2 = zeros(ComplexF64, NF)

    println("Computing FFTs and CWTs"); flush(stdout)

    @views for j in 1:nc
        # Reomplim buffers
        fill!(ss1, 0.0 + 0.0im)
        fill!(ss2, 0.0 + 0.0im)

        @inbounds for i in 1:mt
            ss1[i] = ComplexF64(s1[j, i], 0.0)
            ss2[i] = ComplexF64(s2[j, i], 0.0)
        end

        ss1 .= fcoolr_complex(KN, ss1, -1.0)
        ss2 .= fcoolr_complex(KN, ss2, -1.0)

        @. ss1 = ss1 * dt
        @. ss2 = ss2 * dt

        # CWT només per al component actual
        wv1j = cwt(ss1, mt, nf_tf, df, ff, fmin)   # mt x nf_tf
        wv2j = cwt(ss2, mt, nf_tf, df, ff, fmin)   # mt x nf_tf

        println("Finished CWT for component ", j); flush(stdout)

        # Guardem cwt1 i cwt2
        local_max1 = 0.0
        local_max2 = 0.0
        @inbounds for l in 1:nf_tf, i in 1:mt
            a1 = abs(wv1j[i, l])
            a2 = abs(wv2j[i, l])
            cwt1[j, i, l] = a1 * a1
            cwt2[j, i, l] = a2 * a2
            if a1 > local_max1
                local_max1 = a1
            end
            if a2 > local_max2
                local_max2 = a2
            end
        end

        use_wv1_ref = (!is_s2_reference) && (local_max1 < local_max2)
        ref_max = use_wv1_ref ? local_max1 : local_max2
        threshold = 0.000 * ref_max

        # Acumuladors locals per component
        nomse = 0.0
        nomsp = 0.0
        den_total = 0.0

        # acumuladors per temps i freqüència
        det_j = zeros(Float64, mt)
        dpt_j = zeros(Float64, mt)
        den_t = zeros(Float64, mt)

        def_j = zeros(Float64, nf_tf)
        dpf_j = zeros(Float64, nf_tf)
        den_f = zeros(Float64, nf_tf)

        # Bucle principal: calculem tot en una sola passada
        @inbounds for l in 1:nf_tf
            for i in 1:mt
                z1 = wv1j[i, l]
                z2 = wv2j[i, l]

                a1 = abs(z1)
                a2 = abs(z2)

                zref = use_wv1_ref ? z1 : z2
                aref = use_wv1_ref ? a1 : a2

                de_ijl = a1 - a2

                dp0 = if (a1 == 0.0) || (a2 == 0.0)
                    0.0
                else
                    ratio = z1 / z2
                    atan(imag(ratio), real(ratio)) / PI
                end

                dp_ijl = aref * dp0

                # tfem
                if aref < threshold
                    tfem[j, i, l] = -2.0
                else
                    tfem[j, i, l] = de_ijl / aref
                end

                # tfpm
                tfpm[j, i, l] = aref == 0.0 ? 0.0 : dp_ijl / aref

                # acumuladors per tem/tpm
                det_j[i] += de_ijl
                dpt_j[i] += dp_ijl
                den_t[i] += aref

                # acumuladors per fem/fpm
                def_j[l] += de_ijl
                dpf_j[l] += dp_ijl
                den_f[l] += aref

                # acumuladors globals per em/pm
                nomse += de_ijl * de_ijl
                nomsp += dp_ijl * dp_ijl
                den_total += aref * aref
            end
        end

        # Mitjanes i normalitzacions finals per component
        inv_nf = 1.0 / float(nf_tf)
        inv_mt = 1.0 / float(mt)

        @inbounds for i in 1:mt
            det_j[i] *= inv_nf
            dpt_j[i] *= inv_nf
            deni = den_t[i] * inv_nf

            tem[j, i] = deni == 0.0 ? 0.0 : det_j[i] / deni
            tpm[j, i] = deni == 0.0 ? 0.0 : dpt_j[i] / deni
        end

        @inbounds for l in 1:nf_tf
            def_j[l] *= inv_mt
            dpf_j[l] *= inv_mt
            denl = den_f[l] * inv_mt

            fem[j, l] = denl == 0.0 ? 0.0 : def_j[l] / denl
            fpm[j, l] = denl == 0.0 ? 0.0 : dpf_j[l] / denl
        end

        if den_total == 0.0
            em[j] = 0.0
            pm[j] = 0.0
        else
            em[j] = sqrt(nomse / den_total)
            pm[j] = sqrt(nomsp / den_total)
        end
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

# function write_hdf5(
#     filename::String,
#     tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2,
#     dt, fmin, fmax
# )
#     println("Writing HDF5 file: $filename"); flush(stdout)

#     h5open(filename, "w") do f
#         # Metadata
#         f["dt"] = dt
#         f["fmin"] = fmin
#         f["fmax"] = fmax

#         # Scalars per component
#         f["EM"] = em
#         f["PM"] = pm

#         # Time-frequency
#         f["TFEM"] = Float32.(tfem)
#         f["TFPM"] = Float32.(tfpm)

#         # Marginals
#         f["TEM"] = Float32.(tem)
#         f["TPM"] = Float32.(tpm)
#         f["FEM"] = Float32.(fem)
#         f["FPM"] = Float32.(fpm)

#         # Wavelet power
#         f["CWT1"] = Float32.(cwt1)
#         f["CWT2"] = Float32.(cwt2)
#     end

#     println("HDF5 write complete."); flush(stdout)
# end
function write_hdf5(
    filename::String,
    s1, s2,
    tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2,
    dt, fmin, fmax
)
    println("Writing HDF5 file with compression: $filename"); flush(stdout)

    s132   = Float32.(s1)
    s232   = Float32.(s2)
    tfem32 = Float32.(tfem)
    tfpm32 = Float32.(tfpm)
    tem32  = Float32.(tem)
    tpm32  = Float32.(tpm)
    fem32  = Float32.(fem)
    fpm32  = Float32.(fpm)
    em32   = Float32.(em)
    pm32   = Float32.(pm)
    cwt132 = Float32.(cwt1)
    cwt232 = Float32.(cwt2)

    h5open(filename, "w") do f
        f["dt"] = dt
        f["fmin"] = fmin
        f["fmax"] = fmax

        f["EM"] = em32
        f["PM"] = pm32

        # Signals: (nc, mt)
        chunk_sig = (size(s132, 1), min(size(s132, 2), 1024))
        f["S1", chunk=chunk_sig, shuffle=true, compress=4] = s132
        f["S2", chunk=chunk_sig, shuffle=true, compress=4] = s232

        # 3D arrays: (nc, mt, nf)
        nc, mt, nf = size(tfem32)
        chunk3 = (nc, min(mt, 256), min(nf, 32))

        f["TFEM", chunk=chunk3, shuffle=true, compress=4] = tfem32
        f["TFPM", chunk=chunk3, shuffle=true, compress=4] = tfpm32
        f["CWT1", chunk=chunk3, shuffle=true, compress=4] = cwt132
        f["CWT2", chunk=chunk3, shuffle=true, compress=4] = cwt232

        # Time marginals: (nc, mt)
        chunk2_t = (size(tem32, 1), min(size(tem32, 2), 1024))
        f["TEM", chunk=chunk2_t, shuffle=true, compress=4] = tem32
        f["TPM", chunk=chunk2_t, shuffle=true, compress=4] = tpm32

        # Frequency marginals: (nc, nf)
        chunk2_f = (size(fem32, 1), min(size(fem32, 2), 256))
        f["FEM", chunk=chunk2_f, shuffle=true, compress=4] = fem32
        f["FPM", chunk=chunk2_f, shuffle=true, compress=4] = fpm32
    end

    println("HDF5 compressed write complete."); flush(stdout)
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

    println("mt = ", mt)
    println("nc = ", nc)
    println("nf_tf = ", nf_tf)
    println("NF = ", NF)

    n = nc * mt * nf_tf
    println("3D Float64 array ~ ", round(n * 8 / 1024^2, digits=2), " MB")
    println("3D ComplexF64 array ~ ", round(n * 16 / 1024^2, digits=2), " MB")
    flush(stdout)

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
        println("Using LOCAL normalization"); flush(stdout)
        tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2 = tf_misfits_loc(
            s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference
        )
    else
        println("Using GLOBAL normalization"); flush(stdout)
        tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2 = tf_misfits_glob(
            s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference
        )
    end
    println("Finished TF misfit computation"); flush(stdout)

    # ------------------------------------------------------------
    # HDF5 OUTPUT
    # ------------------------------------------------------------
    write_hdf5(
        "results.h5",
        s1, s2,
        tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2,
        dt, fmin, fmax
    )

    # open("MISFIT-GOF.DAT", "w") do io
    #     println(io, "$fmin $fmax")
    #     println(io, "$nf_tf $mt")
    #     println(io, "$dt $nc")
    #     println(io, max(maximum(abs.(s1)), maximum(abs.(s2))))
    #     for j in 1:nc
    #         println(io, "$(em[j]) $(pm[j])")
    #     end
    #     for j in 1:nc
    #         println(io, "$(A * exp(-abs(em[j])^K)) $(A * (1.0 - abs(pm[j])^K))")
    #     end
    #     println(io, "$(maximum(abs.(tfem))) $(maximum(abs.(tfpm)))")
    #     println(io, "$(maximum(abs.(fem))) $(maximum(abs.(fpm)))")
    #     println(io, "$(maximum(abs.(tem))) $(maximum(abs.(tpm)))")
    #     println(io, "$(maximum(abs.(cwt1))) $(maximum(abs.(cwt2)))")
    # end

    # for j in 1:nc
    #     char = string(j)
    #     write_2d_slices("TFEM" * char * ".DAT", tfem[j, :, :], mt, nf_tf)
    #     write_2d_slices("TFPM" * char * ".DAT", tfpm[j, :, :], mt, nf_tf)
    #     write_1d("TEM" * char * ".DAT", tem[j, :])
    #     write_1d("TPM" * char * ".DAT", tpm[j, :])
    #     write_1d("FEM" * char * ".DAT", fem[j, :])
    #     write_1d("FPM" * char * ".DAT", fpm[j, :])
    #     write_2d_slices("TFRS1_" * char * ".DAT", cwt1[j, :, :], mt, nf_tf)
    #     write_2d_slices("TFRS2_" * char * ".DAT", cwt2[j, :, :], mt, nf_tf)
    # end

    # for j in 1:nc
    #     char = string(j)
    #     write_2d_slices("TFEG" * char * ".DAT", A .* exp.(-abs.(tfem[j, :, :]).^K), mt, nf_tf)
    #     write_2d_slices("TFPG" * char * ".DAT", A .* (1.0 .- abs.(tfpm[j, :, :]).^K), mt, nf_tf)
    #     write_1d("TEG" * char * ".DAT", A .* exp.(-abs.(tem[j, :]).^K))
    #     write_1d("TPG" * char * ".DAT", A .* (1.0 .- abs.(tpm[j, :]).^K))
    #     write_1d("FEG" * char * ".DAT", A .* exp.(-abs.(fem[j, :]).^K))
    #     write_1d("FPG" * char * ".DAT", A .* (1.0 .- abs.(fpm[j, :]).^K))
    # end
    
    println("Wrote compact outputs:")
    println("  - results.h5")
    println("  - S1.DAT")
    println("  - S2.DAT")
    flush(stdout)
end


if abspath(PROGRAM_FILE) == @__FILE__
    input_file = length(ARGS) >= 1 ? ARGS[1] : "HF_TF-MISFIT_GOF"
    main(input_file)
end
