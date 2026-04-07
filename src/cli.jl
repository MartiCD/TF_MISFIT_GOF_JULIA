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

    
    println("Wrote compact outputs:")
    println("  - results.h5")
    flush(stdout)
end


if abspath(PROGRAM_FILE) == @__FILE__
    input_file = isempty(ARGS) ? "HF_TF-MISFIT_GOF" : ARGS[1]
    main(input_file)
end