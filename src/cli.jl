function _parse_bool(x::AbstractString)
    y = lowercase(strip(x))
    y in ("true", "t", "1", "yes") && return true
    y in ("false", "f", "0", "no") && return false
    error("Invalid boolean value: $x")
end

function _parse_kv_args(args)
    opts = Dict{String,String}()
    i = 1
    while i <= length(args)
        key = args[i]
        startswith(key, "--") || error("Expected option starting with --, got: $key")
        i == length(args) && error("Missing value for option $key")
        opts[key] = args[i + 1]
        i += 2
    end
    return opts
end

function _required_opt(opts::Dict{String,String}, key::String)
    haskey(opts, key) || error("Missing $key")
    return opts[key]
end

function print_usage()
    println("""
Usage:
  tfmisfit prepare --input-csv <path> --workdir <dir>
                   [--local-norm <true|false>]
                   [--t-start <float>] [--t-end <float>] [--dt-target <float>]
                   [--reference-source <analytic|csv>]
                   [--signal1-col <int>] [--signal2-col <int>]

  tfmisfit run --workdir <dir>
               [--input-file <name>]
               [--legacy-output <h5|summary|full>]

  tfmisfit plot --workdir <dir> --figdir <dir>
                [--local-norm <true|false>]
                [--usetex <true|false>]
                [--style <portable|publication>]
                [--dpi <int>]
                [--format <png|pdf|both>]
                [--plot-backend <legacy|windowed>]

  tfmisfit pipeline [--input-csv <path>]
                    [--local-norm <true|false>]
                    [--runs-dir <dir>]
                    [--usetex <true|false>]
                    [--style <portable|publication>]
                    [--dpi <int>]
                    [--format <png|pdf|both>]
                    [--legacy-output <h5|summary|full>]
                    [--t-start <float>] [--t-end <float>] [--dt-target <float>]

  tfmisfit validate --example-dir <dir>
                    [--legacy-output <h5|summary|full>]

Notes:
  - prepare defaults to --reference-source analytic
  - use --reference-source csv for demo/tutorial CSVs with:
      column 0 = time, column 1 = signal1, column 2 = signal2
  - plot defaults should ideally target the windowed/HDF5 plotter on this branch
""")
end

function main_cli(args=ARGS)
    isempty(args) && return print_usage()

    cmd = args[1]
    opts = _parse_kv_args(args[2:end])

    if cmd == "prepare"
        input_csv = _required_opt(opts, "--input-csv")
        workdir = _required_opt(opts, "--workdir")
        local_norm = _parse_bool(get(opts, "--local-norm", "false"))
        t_start = haskey(opts, "--t-start") ? parse(Float64, opts["--t-start"]) : nothing
        t_end = haskey(opts, "--t-end") ? parse(Float64, opts["--t-end"]) : nothing
        dt_target = haskey(opts, "--dt-target") ? parse(Float64, opts["--dt-target"]) : nothing
        reference_source = get(opts, "--reference-source", "analytic")
        signal1_col = parse(Int, get(opts, "--signal1-col", "1"))
        signal2_col = parse(Int, get(opts, "--signal2-col", "2"))

        input_path = joinpath(workdir, "HF_TF-MISFIT_GOF")
        run_prepare(
            input_path,
            input_csv;
            local_norm=local_norm,
            t_start=t_start,
            t_end=t_end,
            dt_target=dt_target,
            reference_source=reference_source,
            signal1_col=signal1_col,
            signal2_col=signal2_col,
        )
        println("Prepared input: ", abspath(input_path))
        return

    elseif cmd == "run"
        workdir = _required_opt(opts, "--workdir")
        input_file = get(opts, "--input-file", "HF_TF-MISFIT_GOF")
        legacy_output = get(opts, "--legacy-output", "summary")

        output_file = run_compute(workdir=workdir,
                                  input_file=input_file,
                                  legacy_output=legacy_output)
        println("Finished. Output: ", abspath(output_file))
        return

    elseif cmd == "plot"
        workdir = _required_opt(opts, "--workdir")
        figdir = _required_opt(opts, "--figdir")
        local_norm = _parse_bool(get(opts, "--local-norm", "false"))
        usetex = _parse_bool(get(opts, "--usetex", "false"))
        style = get(opts, "--style", "portable")
        dpi = parse(Int, get(opts, "--dpi", "300"))
        format = get(opts, "--format", "png")
        plot_backend_name = get(opts, "--plot-backend", "windowed")

        backend =
            plot_backend_name == "legacy" ? LegacyPlot() :
            plot_backend_name == "windowed" ? WindowedPlot() :
            error("Invalid --plot-backend: $plot_backend_name")

        run_plot(backend, workdir, figdir;
                local_norm=local_norm,
                usetex=usetex,
                style=style,
                dpi=dpi,
                format=format)
        println("Plots written to: ", abspath(figdir))
        return

    elseif cmd == "pipeline"
        input_csv = get(opts, "--input-csv", joinpath("data", "probe_ricker_wavelet.csv"))
        local_norm = _parse_bool(get(opts, "--local-norm", "false"))
        runs_dir = get(opts, "--runs-dir", joinpath(normpath(joinpath(@__DIR__, "..")), "runs"))
        usetex = _parse_bool(get(opts, "--usetex", "false"))
        style = get(opts, "--style", "portable")
        dpi = parse(Int, get(opts, "--dpi", "300"))
        format = get(opts, "--format", "png")
        legacy_output = get(opts, "--legacy-output", "summary")

        t_start = haskey(opts, "--t-start") ? parse(Float64, opts["--t-start"]) : nothing
        t_end = haskey(opts, "--t-end") ? parse(Float64, opts["--t-end"]) : nothing
        dt_target = haskey(opts, "--dt-target") ? parse(Float64, opts["--dt-target"]) : nothing

        result = run_pipeline(
            input_csv=input_csv,
            local_norm=local_norm,
            runs_dir=runs_dir,
            usetex=usetex,
            style=style,
            dpi=dpi,
            format=format,
            legacy_output=legacy_output,
            t_start=t_start,
            t_end=t_end,
            dt_target=dt_target,
        )

        println("Run folder: ", abspath(result.run_dir))
        println("Output file: ", abspath(result.output_file))
        return

    elseif cmd == "validate"
        example_dir = _required_opt(opts, "--example-dir")
        legacy_output = get(opts, "--legacy-output", "summary")

        output_file = validate_example_run(example_dir; legacy_output=legacy_output)
        println("Validation passed for: ", abspath(example_dir))
        println("Output file: ", abspath(output_file))
        return

    else
        return print_usage()
    end
end