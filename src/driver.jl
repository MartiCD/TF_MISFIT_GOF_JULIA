using DelimitedFiles
using HDF5

function run_from_inputfile(input_file::AbstractString="HF_TF-MISFIT_GOF";
                            legacy_output::AbstractString="summary")
    legacy_output in ("h5", "summary", "full") || error("Invalid legacy_output: $legacy_output")

    write_summary_dat = legacy_output in ("summary", "full")
    write_full_dat = legacy_output == "full"

    params = read_fortran_namelist_input(input_file)

    s1_name = strip_quotes(params["S1_NAME"])
    s2_name = strip_quotes(params["S2_NAME"])

    nc = parse(Int, get(params, "NC", "1"))
    mt = parse(Int, params["MT"])
    dt = parse(Float64, params["DT"])
    nf_tf = parse(Int, get(params, "NF_TF", "100"))
    fmin = parse(Float64, params["FMIN"])
    fmax = parse(Float64, params["FMAX"])
    is_local_norm = parse_fortran_logical(get(params, "LOCAL_NORM", ".FALSE."))
    is_s2_reference = parse_fortran_logical(get(params, "IS_S2_REFERENCE", ".TRUE."))

    s1_raw = readdlm(s1_name)
    s2_raw = readdlm(s2_name)

    size(s1_raw) == size(s2_raw) || error("Signal files have different shapes: $(size(s1_raw)) vs $(size(s2_raw))")
    size(s1_raw, 1) == mt || error("MT mismatch: namelist MT=$mt but signal has $(size(s1_raw, 1)) rows")

    # Expect: first column = time, remaining columns = components
    size(s1_raw, 2) >= 2 || error("Expected at least 2 columns in signal files (time + signal)")

    t = Float64.(s1_raw[:, 1])
    if length(t) >= 2
        dt_data = t[2] - t[1]
        abs(dt_data - dt) < max(1e-12, 1e-8 * abs(dt)) || @warn "DT in namelist ($dt) differs from data ($dt_data); using namelist DT"
    end

    data_nc = size(s1_raw, 2) - 1
    data_nc == nc || error("NC mismatch: namelist NC=$nc but signal files contain $data_nc component columns")

    s1 = permutedims(Float64.(Matrix(s1_raw[:, 2:end])))
    s2 = permutedims(Float64.(Matrix(s2_raw[:, 2:end])))

    results = if is_local_norm
        tf_misfits_loc(s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference)
    else
        tf_misfits_glob(s1, s2, nc, dt, mt, fmin, fmax, nf_tf, is_s2_reference)
    end

    tfem, tfpm, tem, tpm, fem, fpm, em, pm, cwt1, cwt2 = results

    # Canonical output: always write HDF5
    h5open("results.h5", "w") do h5
        h5["S1"] = s1
        h5["S2"] = s2
        h5["TFEM"] = tfem
        h5["TFPM"] = tfpm
        h5["TEM"] = tem
        h5["TPM"] = tpm
        h5["FEM"] = fem
        h5["FPM"] = fpm
        h5["EM"] = em
        h5["PM"] = pm
        h5["CWT1"] = cwt1
        h5["CWT2"] = cwt2
        h5["dt"] = dt
        h5["fmin"] = fmin
        h5["fmax"] = fmax
        h5["nf_tf"] = nf_tf
        h5["mt"] = mt
        h5["nc"] = nc
        h5["local_norm"] = Int(is_local_norm)
        h5["s2_reference"] = Int(is_s2_reference)
    end

    # Compatibility summary output
    if write_summary_dat
        open("MISFIT-GOF.DAT", "w") do io
            for j in 1:nc
                println(io, em[j], " ", pm[j])
            end
        end
    end

    # Full legacy ASCII outputs
    if write_full_dat
        for j in 1:nc
            write_2d_slices("TFEM$(j).DAT", tfem[j, :, :], mt, nf_tf)
            write_2d_slices("TFPM$(j).DAT", tfpm[j, :, :], mt, nf_tf)
            write_1d("TEM$(j).DAT", tem[j, :])
            write_1d("TPM$(j).DAT", tpm[j, :])
            write_1d("FEM$(j).DAT", fem[j, :])
            write_1d("FPM$(j).DAT", fpm[j, :])
            write_2d_slices("CWT1$(j).DAT", cwt1[j, :, :], mt, nf_tf)
            write_2d_slices("CWT2$(j).DAT", cwt2[j, :, :], mt, nf_tf)
        end
    end

    if legacy_output == "h5"
        return joinpath(pwd(), "results.h5")
    else
        return joinpath(pwd(), "MISFIT-GOF.DAT")
    end
end