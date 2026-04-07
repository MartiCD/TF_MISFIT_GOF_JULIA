using Dates

"""
    main_legacy(input_file::AbstractString="HF_TF-MISFIT_GOF"; legacy_output::AbstractString="summary")

Programmatic legacy entrypoint used by the compatibility shim and internal API.
"""
function main_legacy(input_file::AbstractString="HF_TF-MISFIT_GOF";
                     legacy_output::AbstractString="summary")
    return run_from_inputfile(input_file; legacy_output=legacy_output)
end

function run_prepare(input_path::AbstractString, input_csv_path::AbstractString;
                     local_norm::Bool=false,
                     base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
    script = joinpath(base_dir, "scripts", "build_tf_misfit_signals.py")
    isfile(script) || error("Preprocess script not found: $script")
    isfile(input_csv_path) || error("Input CSV not found: $input_csv_path")

    mkpath(dirname(input_path))

    cmd = `python3 $script $input_path $input_csv_path $(lowercase(string(local_norm)))`
    run(cmd)

    isfile(input_path) || error("Expected generated input file not found: $input_path")
    return input_path
end

function run_compute(; workdir::AbstractString,
                     input_file::AbstractString="HF_TF-MISFIT_GOF",
                     legacy_output::AbstractString="summary")
    output_file = compute_from_inputfile(input_file; workdir=workdir, legacy_output=legacy_output)
    return output_file
end

function run_plot(workdir::AbstractString, figdir::AbstractString;
                  local_norm::Bool=false,
                  usetex::Bool=false,
                  format::AbstractString="png",
                  dpi::Int=300,
                  style::AbstractString="portable",
                  base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
    script = joinpath(base_dir, "scripts", "Plot.py")
    isfile(script) || error("Plot script not found: $script")

    format in ("png", "pdf", "both") || error("Invalid format: $format")
    style in ("portable", "publication") || error("Invalid style: $style")

    mkpath(figdir)

    cmd = `python3 $script $workdir $figdir $(lowercase(string(local_norm))) --usetex $(lowercase(string(usetex))) --style $style --dpi $dpi --format $format`
    run(cmd)

    return figdir
end

function create_run_dirs(; runs_dir::AbstractString,
                         date_str::AbstractString=string(Dates.today()))
    mkpath(runs_dir)

    i = 1
    run_name = ""
    run_dir = ""

    while true
        run_name = string(date_str, "_", lpad(i, 3, '0'))
        run_dir = joinpath(runs_dir, run_name)
        !isdir(run_dir) && break
        i += 1
    end

    work_dir = joinpath(run_dir, "work")
    fig_dir  = joinpath(run_dir, "figures")
    log_dir  = joinpath(run_dir, "logs")

    mkpath(work_dir)
    mkpath(fig_dir)
    mkpath(log_dir)

    return (run_name=run_name, run_dir=run_dir, work_dir=work_dir, fig_dir=fig_dir, log_dir=log_dir)
end

function run_pipeline(; input_csv::AbstractString=joinpath("data", "probe_ricker_wavelet.csv"),
                      local_norm::Bool=false,
                      usetex::Bool=false,
                      format::AbstractString="png",
                      dpi::Int=300,
                      style::AbstractString="portable",
                      legacy_output::AbstractString="summary",
                      base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")),
                      runs_dir::AbstractString=joinpath(base_dir, "runs"))
    dirs = create_run_dirs(runs_dir=runs_dir)

    input_csv_path = isabspath(input_csv) ? input_csv : joinpath(base_dir, input_csv)
    input_path = joinpath(dirs.work_dir, "HF_TF-MISFIT_GOF")

    run_prepare(input_path, input_csv_path; local_norm=local_norm, base_dir=base_dir)
    output_file = run_compute(workdir=dirs.work_dir,
                              input_file="HF_TF-MISFIT_GOF",
                              legacy_output=legacy_output)

    run_plot(dirs.work_dir, dirs.fig_dir;
             local_norm=local_norm,
             usetex=usetex,
             format=format,
             dpi=dpi,
             style=style,
             base_dir=base_dir)

    return (; dirs..., output_file=output_file)
end

function compute_from_inputfile(input_file::AbstractString;
                                workdir::AbstractString=pwd(),
                                legacy_output::AbstractString="summary")
    abs_workdir = abspath(workdir)

    return cd(abs_workdir) do
        main_legacy(input_file; legacy_output=legacy_output)

        expected_file = legacy_output == "h5" ? "results.h5" : "MISFIT-GOF.DAT"
        isfile(expected_file) || error("Expected output not found: $(abspath(expected_file))")
        abspath(expected_file)
    end
end

function validate_example_run(example_dir::AbstractString;
                              legacy_output::AbstractString="summary")
    input_file = "HF_TF-MISFIT_GOF"
    output_file = compute_from_inputfile(input_file;
                                         workdir=example_dir,
                                         legacy_output=legacy_output)
    return output_file
end