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