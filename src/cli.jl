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

function print_usage()
    println("""
Usage:
  tfmisfit prepare  --input-csv <csv> --workdir <dir> [--local-norm <true|false>]
  tfmisfit run      --workdir <dir> [--input-file <name>]
  tfmisfit plot     --workdir <dir> --figdir <dir> [--local-norm <true|false>] [--usetex <true|false>] [--style <portable|publication>] [--dpi <int>] [--format <png|pdf|both>]
  tfmisfit pipeline [--input-csv <csv>] [--local-norm <true|false>] [--runs-dir <dir>] [--usetex <true|false>] [--style <portable|publication>] [--dpi <int>] [--format <png|pdf|both>]
  tfmisfit validate --example-dir <dir>
""")
end

function main(args=ARGS)
    isempty(args) && return print_usage()

    cmd = args[1]
    opts = _parse_kv_args(args[2:end])

    if cmd == "prepare"
        input_csv = get(opts, "--input-csv", error("Missing --input-csv"))
        workdir = get(opts, "--workdir", error("Missing --workdir"))
        local_norm = _parse_bool(get(opts, "--local-norm", "false"))

        input_path = joinpath(workdir, "HF_TF-MISFIT_GOF")
        run_prepare(input_path, input_csv; local_norm=local_norm)

        println("Prepared input: ", abspath(input_path))
        return

    elseif cmd == "run"
        workdir = get(opts, "--workdir", error("Missing --workdir"))
        input_file = get(opts, "--input-file", "HF_TF-MISFIT_GOF")

        summary = run_compute(workdir=workdir, input_file=input_file)
        println("Finished. Summary: ", abspath(summary))
        return

    elseif cmd == "plot"
        workdir = get(opts, "--workdir", error("Missing --workdir"))
        figdir = get(opts, "--figdir", error("Missing --figdir"))
        local_norm = _parse_bool(get(opts, "--local-norm", "false"))
        usetex = _parse_bool(get(opts, "--usetex", "false"))
        style = get(opts, "--style", "portable")
        dpi = parse(Int, get(opts, "--dpi", "300"))
        format = get(opts, "--format", "png")

        run_plot(workdir, figdir;
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

        result = run_pipeline(input_csv=input_csv,
                              local_norm=local_norm,
                              runs_dir=runs_dir,
                              usetex=usetex,
                              style=style,
                              dpi=dpi,
                              format=format)

        println("Run folder: ", abspath(result.run_dir))
        println("Summary file: ", abspath(result.summary_file))
        return

    elseif cmd == "validate"
        example_dir = get(opts, "--example-dir", error("Missing --example-dir"))
        summary = validate_example_run(example_dir)
        println("Validation passed for: ", abspath(example_dir))
        println("Summary file: ", abspath(summary))
        return

    else
        return print_usage()
    end
end