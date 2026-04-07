function run_prepare(input_path::AbstractString, input_csv_path::AbstractString;
                     local_norm::Bool=false, base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
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
                      input_file::AbstractString="HF_TF-MISFIT_GOF")
    summary_file = compute_from_inputfile(input_file; workdir=workdir)
    return summary_file
end

function run_plot(workdir::AbstractString, figdir::AbstractString;
                  local_norm::Bool=false,
                  base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
    script = joinpath(base_dir, "scripts", "Plot.py")
    isfile(script) || error("Plot script not found: $script")

    mkpath(figdir)

    cmd = `python3 $script $workdir $figdir $(lowercase(string(local_norm)))`
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
                        base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")),
                        runs_dir::AbstractString=joinpath(base_dir, "runs"))
    dirs = create_run_dirs(runs_dir=runs_dir)

    input_csv_path = isabspath(input_csv) ? input_csv : joinpath(base_dir, input_csv)
    input_path = joinpath(dirs.work_dir, "HF_TF-MISFIT_GOF")

    run_prepare(input_path, input_csv_path; local_norm=local_norm, base_dir=base_dir)
    summary = run_compute(workdir=dirs.work_dir, input_file="HF_TF-MISFIT_GOF")
    run_plot(dirs.work_dir, dirs.fig_dir; local_norm=local_norm, base_dir=base_dir)

    return (; dirs..., summary_file=summary)
end