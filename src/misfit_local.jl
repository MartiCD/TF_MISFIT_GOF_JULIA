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