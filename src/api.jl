using Dates

"""
    main_legacy(input_file::AbstractString="HF_TF-MISFIT_GOF"; legacy_output::AbstractString="summary")

Programmatic legacy entrypoint used by the compatibility shim and internal API.
"""
function main_legacy(input_file::AbstractString="HF_TF-MISFIT_GOF";
                     legacy_output::AbstractString="summary")
    return run_from_inputfile(input_file; legacy_output=legacy_output)
end

# function run_prepare(
#     input_path::AbstractString,
#     input_csv_path::AbstractString;
#     local_norm::Bool=false,
#     t_start::Union{Nothing,Real}=nothing,
#     t_end::Union{Nothing,Real}=nothing,
#     dt_target::Union{Nothing,Real}=nothing,
#     base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")),
# )
#     script = joinpath(base_dir, "scripts", "build_tf_misfit_signals.py")
#     isfile(script) || error("Preprocess script not found: $script")
#     isfile(input_csv_path) || error("Input CSV not found: $input_csv_path")

#     mkpath(dirname(input_path))

#     cmd = `python3 $script $input_path $input_csv_path $(lowercase(string(local_norm)))`

#     if t_start !== nothing
#         cmd = `$cmd --t-start $(string(Float64(t_start)))`
#     end
#     if t_end !== nothing
#         cmd = `$cmd --t-end $(string(Float64(t_end)))`
#     end
#     if dt_target !== nothing
#         cmd = `$cmd --dt-target $(string(Float64(dt_target)))`
#     end

#     run(cmd)

#     isfile(input_path) || error("Expected generated input file not found: $input_path")
#     return input_path
# end

function run_prepare(
    input_path::AbstractString,
    input_csv_path::AbstractString;
    local_norm::Bool=false,
    t_start::Union{Nothing,Real}=nothing,
    t_end::Union{Nothing,Real}=nothing,
    dt_target::Union{Nothing,Real}=nothing,
    reference_source::AbstractString="analytic",
    signal1_col::Int=1,
    signal2_col::Int=2,
    base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")),
)
    script = joinpath(base_dir, "scripts", "build_tf_misfit_signals.py")
    isfile(script) || error("Preprocess script not found: $script")
    isfile(input_csv_path) || error("Input CSV not found: $input_csv_path")

    reference_source in ("analytic", "csv") ||
        error("Invalid reference_source: $reference_source")

    signal1_col >= 0 || error("signal1_col must be >= 0")
    signal2_col >= 0 || error("signal2_col must be >= 0")

    mkpath(dirname(input_path))

    cmd = `python3 $script $input_path $input_csv_path $(lowercase(string(local_norm))) --reference-source $reference_source --signal1-col $signal1_col`

    if reference_source == "csv"
        cmd = `$cmd --signal2-col $signal2_col`
    end
    if t_start !== nothing
        cmd = `$cmd --t-start $(string(Float64(t_start)))`
    end
    if t_end !== nothing
        cmd = `$cmd --t-end $(string(Float64(t_end)))`
    end
    if dt_target !== nothing
        cmd = `$cmd --dt-target $(string(Float64(dt_target)))`
    end

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

# function run_plot(workdir::AbstractString, figdir::AbstractString;
#                   local_norm::Bool=false,
#                   usetex::Bool=false,
#                   format::AbstractString="png",
#                   dpi::Int=300,
#                   style::AbstractString="portable",
#                   base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
#     script = joinpath(base_dir, "scripts", "Plot.py")
#     isfile(script) || error("Plot script not found: $script")

#     format in ("png", "pdf", "both") || error("Invalid format: $format")
#     style in ("portable", "publication") || error("Invalid style: $style")

#     mkpath(figdir)

#     cmd = `python3 $script $workdir $figdir $(lowercase(string(local_norm))) --usetex $(lowercase(string(usetex))) --style $style --dpi $dpi --format $format`
#     run(cmd)

#     return figdir
# end

abstract type AbstractPlotBackend end
struct LegacyPlot   <: AbstractPlotBackend end
struct WindowedPlot <: AbstractPlotBackend end

plot_script(::LegacyPlot,   base_dir) = joinpath(base_dir, "scripts", "Plot.py")
plot_script(::WindowedPlot, base_dir) = joinpath(base_dir, "scripts", "plot_windowed.py")

function run_plot(backend::AbstractPlotBackend,
                  workdir::AbstractString,
                  figdir::AbstractString;
                  local_norm::Bool=false,
                  usetex::Bool=false,
                  python::AbstractString = get(ENV, "PYTHON", "python3"),
                  format::AbstractString="png",
                  dpi::Int=300,
                  style::AbstractString="portable",
                  base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")))
    script = plot_script(backend, base_dir)
    isfile(script) || error("Plot script not found: $script")

    format in ("png", "pdf", "both") || error("Invalid format: $format")
    style in ("portable", "publication") || error("Invalid style: $style")

    mkpath(figdir)

    cmd = `$(python) $script $workdir $figdir $(lowercase(string(local_norm))) --usetex $(lowercase(string(usetex))) --style $style --dpi $dpi --format $format`
    run(cmd)

    return figdir
end

function run_plot(workdir::AbstractString,
                  figdir::AbstractString;
                  kwargs...)
    run_plot(LegacyPlot(), workdir, figdir; kwargs...)
end

run_plot_legacy(workdir::AbstractString, figdir::AbstractString; kwargs...) = run_plot(LegacyPlot(), workdir, figdir; kwargs...)
run_plot_windowed(workdir::AbstractString, figdir::AbstractString; kwargs...) = run_plot(WindowedPlot(), workdir, figdir; kwargs...)

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

function run_pipeline(;
    input_csv::AbstractString=joinpath("data", "probe_ricker_wavelet.csv"),
    local_norm::Bool=false,
    usetex::Bool=false,
    format::AbstractString="png",
    dpi::Int=300,
    style::AbstractString="portable",
    legacy_output::AbstractString="summary",
    t_start::Union{Nothing,Real}=nothing,
    t_end::Union{Nothing,Real}=nothing,
    dt_target::Union{Nothing,Real}=nothing,
    base_dir::AbstractString=normpath(joinpath(@__DIR__, "..")),
    runs_dir::AbstractString=joinpath(base_dir, "runs"),
)
    dirs = create_run_dirs(runs_dir=runs_dir)
    input_csv_path = isabspath(input_csv) ? input_csv : joinpath(base_dir, input_csv)
    input_path = joinpath(dirs.work_dir, "HF_TF-MISFIT_GOF")

    run_prepare(
        input_path,
        input_csv_path;
        local_norm=local_norm,
        t_start=t_start,
        t_end=t_end,
        dt_target=dt_target,
        base_dir=base_dir,
    )

    output_file = run_compute(
        workdir=dirs.work_dir,
        input_file="HF_TF-MISFIT_GOF",
        legacy_output=legacy_output,
    )

    run_plot(
        dirs.work_dir,
        dirs.fig_dir;
        local_norm=local_norm,
        usetex=usetex,
        format=format,
        dpi=dpi,
        style=style,
        base_dir=base_dir,
    )

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

"""
    run_tf_metric_demo(case_name; kwargs...) -> demo_dir

Run a pedagogical demo showing how TFEM and TFPM respond to controlled
perturbations of a Ricker wavelet.

Supported cases:
- "amplitude" : test signal is amplitude-scaled relative to reference
- "shift"     : test signal is time-advanced relative to reference
- "mixed"     : both amplitude scaling and time shift

The workflow is:
1. generate synthetic signals
2. write a CSV file
3. call `run_prepare`
4. call `run_compute`
5. call `run_plot`

Returns the demo case directory.
"""
function run_tf_metric_demo(case_name::AbstractString;
                            outdir::AbstractString,
                            f0::Real=5.0,
                            dt::Real=0.001,
                            tmin::Real=-1.0,
                            tmax::Real=1.0,
                            t0::Real=0.0,
                            amp_scale::Real=1.01,
                            shift_fraction_of_period::Real=0.01,
                            local_norm::Bool=false,
                            usetex::Bool=false,
                            format::AbstractString="png",
                            dpi::Int=300,
                            style::AbstractString="portable",
                            dt_target::Union{Nothing,Real}=nothing,
                            legacy_output::AbstractString="h5",
                            plot_backend::AbstractPlotBackend=WindowedPlot())

    case_key = lowercase(strip(case_name))
    case_key in ("amplitude", "shift", "mixed") ||
        error("Unknown demo case: $case_name")

    format in ("png", "pdf", "both") || error("Invalid format: $format")
    style in ("portable", "publication") || error("Invalid style: $style")
    legacy_output in ("h5", "summary", "full") || error("Invalid legacy_output: $legacy_output")

    t = collect(tmin:dt:tmax)
    length(t) >= 2 || error("Time vector must contain at least two samples")

    s_ref, s_test =
        case_key == "amplitude" ? make_amplitude_demo(
            t; f0=f0, amp_scale=amp_scale, t0=t0
        ) :
        case_key == "shift" ? make_shift_demo(
            t; f0=f0, shift_fraction_of_period=shift_fraction_of_period, t0=t0
        ) :
        make_mixed_demo(
            t; f0=f0, amp_scale=amp_scale,
            shift_fraction_of_period=shift_fraction_of_period, t0=t0
        )

    demo_dir = joinpath(outdir, case_key)
    workdir  = joinpath(demo_dir, "work")
    figdir   = joinpath(demo_dir, "figures")
    mkpath(workdir)
    mkpath(figdir)

    csv_path = joinpath(demo_dir, "demo_signals.csv")

    # signal1 = perturbed/test
    # signal2 = reference
    write_demo_csv(csv_path, t, s_test, s_ref)

    input_file_path = joinpath(workdir, "HF_TF-MISFIT_GOF")

    input_file = isnothing(dt_target) ?
        run_prepare(
            input_file_path,
            csv_path;
            local_norm=local_norm,
            reference_source="csv",
            signal1_col=1,
            signal2_col=2,
        ) :
        run_prepare(
            input_file_path,
            csv_path;
            local_norm=local_norm,
            dt_target=dt_target,
            reference_source="csv",
            signal1_col=1,
            signal2_col=2,
        )

    run_compute(; input_file=input_file, workdir=workdir, legacy_output=legacy_output)

    run_plot(plot_backend, workdir, figdir;
             local_norm=local_norm,
             usetex=usetex,
             format=format,
             dpi=dpi,
             style=style)

    return demo_dir
end