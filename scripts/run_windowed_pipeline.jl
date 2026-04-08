# #!/usr/bin/env julia

# using TFMisfitGOF
# using Printf

# function window_name(t1::Real, t2::Real)
#     return @sprintf("T%06.1f_T%06.1f", float(t1), float(t2)) |>
#            x -> replace(x, "." => "p")
# end

# function clear_old_frames(frames_dir::AbstractString)
#     if isdir(frames_dir)
#         for f in readdir(frames_dir)
#             endswith(lowercase(f), ".png") && rm(joinpath(frames_dir, f); force=true)
#         end
#     end
#     mkpath(frames_dir)
# end

# function find_frame_figure(fig_dir::AbstractString; preferred_name::AbstractString)
#     candidate = joinpath(fig_dir, preferred_name)
#     isfile(candidate) || error("Requested frame file not found: $candidate")
#     return candidate
# end

# function run_one_window(;
#     input_csv::AbstractString,
#     runs_dir::AbstractString,
#     local_norm::Bool,
#     usetex::Bool,
#     style::AbstractString,
#     dpi::Int,
#     format::AbstractString,
#     legacy_output::AbstractString,
#     t_start::Real,
#     t_end::Real,
#     frame_index::Int,
#     frames_dir::AbstractString,
#     preferred_frame_name::AbstractString,
#     dt_target::Union{Nothing,Real}=nothing,
#     use_global_time::Bool=true,
#     signals_ylim::Tuple{Float64,Float64}=(-0.55, 1.05),
#     tem_ylim::Tuple{Float64,Float64}=(-0.16, 0.04),
#     tpm_ylim::Tuple{Float64,Float64}=(-0.05, 0.03),
# )
#     name = window_name(t_start, t_end)
#     run_dir = joinpath(runs_dir, name)
#     work_dir = joinpath(run_dir, "work")
#     fig_dir = joinpath(run_dir, "figures")
#     log_dir = joinpath(run_dir, "logs")

#     mkpath(work_dir)
#     mkpath(fig_dir)
#     mkpath(log_dir)
#     mkpath(frames_dir)

#     input_path = joinpath(work_dir, "HF_TF-MISFIT_GOF")

#     println("--------------------------------------------------")
#     println("Running window: [$t_start, $t_end]")
#     println("Run dir       : $run_dir")

#     TFMisfitGOF.run_prepare(
#         input_path,
#         input_csv;
#         local_norm=local_norm,
#         t_start=t_start,
#         t_end=t_end,
#         dt_target=dt_target,
#     )

#     output_file = TFMisfitGOF.run_compute(
#         workdir=work_dir,
#         input_file="HF_TF-MISFIT_GOF",
#         legacy_output=legacy_output,
#     )

#     # Pass plotting controls through environment variables
#     env = copy(ENV)
#     env["TFMISFIT_WINDOW_LABEL"] = @sprintf("Window %.1f–%.1f s", t_start, t_end)
#     env["TFMISFIT_WINDOW_START"] = string(Float64(t_start))
#     env["TFMISFIT_WINDOW_END"] = string(Float64(t_end))
#     env["TFMISFIT_USE_GLOBAL_TIME"] = lowercase(string(use_global_time))

#     env["TFMISFIT_SIGNALS_YMIN"] = string(signals_ylim[1])
#     env["TFMISFIT_SIGNALS_YMAX"] = string(signals_ylim[2])

#     env["TFMISFIT_TEM_YMIN"] = string(tem_ylim[1])
#     env["TFMISFIT_TEM_YMAX"] = string(tem_ylim[2])

#     env["TFMISFIT_TPM_YMIN"] = string(tpm_ylim[1])
#     env["TFMISFIT_TPM_YMAX"] = string(tpm_ylim[2])

#     withenv(env...) do
#         TFMisfitGOF.run_plot(
#             work_dir,
#             fig_dir;
#             local_norm=local_norm,
#             usetex=usetex,
#             style=style,
#             dpi=dpi,
#             format=format,
#         )
#     end

#     frame_source = find_frame_figure(fig_dir; preferred_name=preferred_frame_name)
#     frame_dest = joinpath(frames_dir, @sprintf("frame_%04d.png", frame_index))
#     cp(frame_source, frame_dest; force=true)

#     println("Finished window: [$t_start, $t_end]")
#     println("Output file    : $output_file")
#     println("Figures dir    : $fig_dir")
#     println("Frame source   : $frame_source")
#     println("Frame saved as : $frame_dest")
# end

# function build_gif(frames_dir::AbstractString, out_gif::AbstractString; fps::Int=1)
#     ffmpeg = Sys.which("ffmpeg")
#     ffmpeg === nothing && error("ffmpeg not found in PATH")
#     run(`$(ffmpeg) -y -framerate $fps -i $(joinpath(frames_dir, "frame_%04d.png")) $out_gif`)
# end

# function build_mp4(frames_dir::AbstractString, out_mp4::AbstractString; fps::Int=1)
#     ffmpeg = Sys.which("ffmpeg")
#     ffmpeg === nothing && error("ffmpeg not found in PATH")
#     run(`$(ffmpeg) -y -framerate $fps -i $(joinpath(frames_dir, "frame_%04d.png")) -pix_fmt yuv420p $out_mp4`)
# end

# function main()
#     input_csv = "data/probe_ricker_wavelet_long_time.csv"
#     runs_dir = "runs_windowed"
#     frames_dir = joinpath(runs_dir, "animation_frames")

#     local_norm = false
#     usetex = false
#     style = "portable"
#     dpi = 300
#     format = "png"
#     legacy_output = "h5"
#     dt_target = nothing

#     preferred_frame_name = "signals_time_marginals.png"

#     windows = [
#         (1.0, 10.0),
#         (100.0, 110.0),
#         (200.0, 210.0),
#         (300.0, 310.0),
#         (400.0, 410.0),
#         (500.0, 510.0),
#         (600.0, 610.0),
#         (700.0, 710.0),
#         (800.0, 810.0),
#         (900.0, 910.0),
#         (1000.0, 1010.0),
#         (2000.0, 2010.0),
#         (3000.0, 3010.0),
#         (4000.0, 4010.0),
#         (5000.0, 5010.0),
#         (6000.0, 6010.0),
#         (7000.0, 7010.0),
#         (8000.0, 8010.0),
#         (9000.0, 9010.0),
#         (9989.0, 9999.0),
#     ]

#     clear_old_frames(frames_dir)

#     for (i, (t_start, t_end)) in enumerate(windows)
#         run_one_window(
#             input_csv=input_csv,
#             runs_dir=runs_dir,
#             local_norm=local_norm,
#             usetex=usetex,
#             style=style,
#             dpi=dpi,
#             format=format,
#             legacy_output=legacy_output,
#             t_start=t_start,
#             t_end=t_end,
#             frame_index=i,
#             frames_dir=frames_dir,
#             preferred_frame_name=preferred_frame_name,
#             dt_target=dt_target,
#             use_global_time=true,
#             signals_ylim=(-0.55, 1.05),
#             tem_ylim=(-0.16, 0.04),
#             tpm_ylim=(-0.05, 0.03),
#         )
#     end

#     build_gif(frames_dir, joinpath(runs_dir, "signals_time_marginals.gif"); fps=1)
#     # build_mp4(frames_dir, joinpath(runs_dir, "signals_time_marginals.mp4"); fps=1)

#     println("--------------------------------------------------")
#     println("Animation frames : $frames_dir")
#     println("GIF created      : $(joinpath(runs_dir, "signals_time_marginals.gif"))")
#     println("MP4 created      : $(joinpath(runs_dir, "signals_time_marginals.mp4"))")
# end

# main()

#!/usr/bin/env julia

using TFMisfitGOF
using Printf

function window_name(t1::Real, t2::Real)
    return @sprintf("T%06.1f_T%06.1f", float(t1), float(t2)) |>
           x -> replace(x, "." => "p")
end

function clear_old_frames(frames_dir::AbstractString)
    if isdir(frames_dir)
        for f in readdir(frames_dir)
            endswith(lowercase(f), ".png") && rm(joinpath(frames_dir, f); force=true)
        end
    end
    mkpath(frames_dir)
end

function copy_named_frame(
    fig_dir::AbstractString,
    frames_dir::AbstractString,
    frame_index::Int,
    figure_name::AbstractString,
)
    src = joinpath(fig_dir, figure_name)
    isfile(src) || error("Expected frame figure not found: $src")
    dst = joinpath(frames_dir, @sprintf("frame_%04d.png", frame_index))
    cp(src, dst; force=true)
    return dst
end

function build_gif(frames_dir::AbstractString, out_gif::AbstractString; fps::Int=1)
    ffmpeg = Sys.which("ffmpeg")
    ffmpeg === nothing && error("ffmpeg not found in PATH")

    cmd = `$(ffmpeg) -y -framerate $fps -i $(joinpath(frames_dir, "frame_%04d.png")) $out_gif`
    run(cmd)
end

function build_mp4(frames_dir::AbstractString, out_mp4::AbstractString; fps::Int=1)
    ffmpeg = Sys.which("ffmpeg")
    ffmpeg === nothing && error("ffmpeg not found in PATH")

    input_pattern = joinpath(frames_dir, "frame_%04d.png")
    vf_filter = "pad=ceil(iw/2)*2:ceil(ih/2)*2"

    cmd = `$(ffmpeg) -y -framerate $fps -i $input_pattern -vf $vf_filter -c:v libx264 -pix_fmt yuv420p -movflags +faststart $out_mp4`
    run(cmd)
end

function build_animation_pair(frames_dir::AbstractString, out_stem::AbstractString; fps::Int=1)
    build_gif(frames_dir, out_stem * ".gif"; fps=fps)
    # build_mp4(frames_dir, out_stem * ".mp4"; fps=fps)
end

function run_one_window(;
    input_csv::AbstractString,
    runs_dir::AbstractString,
    local_norm::Bool,
    usetex::Bool,
    style::AbstractString,
    dpi::Int,
    format::AbstractString,
    legacy_output::AbstractString,
    t_start::Real,
    t_end::Real,
    frame_index::Int,
    stm_frames_dir::AbstractString,
    fm_frames_dir::AbstractString,
    tfm_frames_dir::AbstractString,
    dt_target::Union{Nothing,Real}=nothing,
    use_global_time::Bool=true,
    signals_ylim::Tuple{Float64,Float64}=(-0.55, 1.05),
    tem_ylim::Tuple{Float64,Float64}=(-0.15, 0.03),
    tpm_ylim::Tuple{Float64,Float64}=(-0.045, 0.025),
    fem_ylim::Union{Nothing,Tuple{Float64,Float64}}=nothing,
    fpm_ylim::Union{Nothing,Tuple{Float64,Float64}}=nothing,
    tfem_vmin::Union{Nothing,Float64}=nothing,
    tfem_vmax::Union{Nothing,Float64}=nothing,
    tfpm_vmin::Union{Nothing,Float64}=nothing,
    tfpm_vmax::Union{Nothing,Float64}=nothing,
)
    name = window_name(t_start, t_end)
    run_dir = joinpath(runs_dir, name)
    work_dir = joinpath(run_dir, "work")
    fig_dir = joinpath(run_dir, "figures")
    log_dir = joinpath(run_dir, "logs")

    mkpath(work_dir)
    mkpath(fig_dir)
    mkpath(log_dir)
    mkpath(stm_frames_dir)
    mkpath(fm_frames_dir)
    mkpath(tfm_frames_dir)

    input_path = joinpath(work_dir, "HF_TF-MISFIT_GOF")

    println("--------------------------------------------------")
    println("Running window: [$t_start, $t_end]")
    println("Run dir       : $run_dir")

    TFMisfitGOF.run_prepare(
        input_path,
        input_csv;
        local_norm=local_norm,
        t_start=t_start,
        t_end=t_end,
        dt_target=dt_target,
    )

    output_file = TFMisfitGOF.run_compute(
        workdir=work_dir,
        input_file="HF_TF-MISFIT_GOF",
        legacy_output=legacy_output,
    )

    env = copy(ENV)

    env["TFMISFIT_WINDOW_LABEL"] = @sprintf("Window %.1f–%.1f s", t_start, t_end)
    env["TFMISFIT_WINDOW_START"] = string(Float64(t_start))
    env["TFMISFIT_WINDOW_END"] = string(Float64(t_end))
    env["TFMISFIT_USE_GLOBAL_TIME"] = lowercase(string(use_global_time))

    env["TFMISFIT_SIGNALS_YMIN"] = string(signals_ylim[1])
    env["TFMISFIT_SIGNALS_YMAX"] = string(signals_ylim[2])

    env["TFMISFIT_TEM_YMIN"] = string(tem_ylim[1])
    env["TFMISFIT_TEM_YMAX"] = string(tem_ylim[2])

    env["TFMISFIT_TPM_YMIN"] = string(tpm_ylim[1])
    env["TFMISFIT_TPM_YMAX"] = string(tpm_ylim[2])

    if fem_ylim !== nothing
        env["TFMISFIT_FEM_YMIN"] = string(fem_ylim[1])
        env["TFMISFIT_FEM_YMAX"] = string(fem_ylim[2])
    end
    if fpm_ylim !== nothing
        env["TFMISFIT_FPM_YMIN"] = string(fpm_ylim[1])
        env["TFMISFIT_FPM_YMAX"] = string(fpm_ylim[2])
    end

    if tfem_vmin !== nothing
        env["TFMISFIT_TFEM_VMIN"] = string(tfem_vmin)
    end
    if tfem_vmax !== nothing
        env["TFMISFIT_TFEM_VMAX"] = string(tfem_vmax)
    end
    if tfpm_vmin !== nothing
        env["TFMISFIT_TFPM_VMIN"] = string(tfpm_vmin)
    end
    if tfpm_vmax !== nothing
        env["TFMISFIT_TFPM_VMAX"] = string(tfpm_vmax)
    end

    withenv(env...) do
        TFMisfitGOF.run_plot(
            work_dir,
            fig_dir;
            local_norm=local_norm,
            usetex=usetex,
            style=style,
            dpi=dpi,
            format=format,
        )
    end

    stm_frame = copy_named_frame(fig_dir, stm_frames_dir, frame_index, "signals_time_marginals.png")
    fm_frame  = copy_named_frame(fig_dir, fm_frames_dir,  frame_index, "frequency_marginals.png")
    tfm_frame = copy_named_frame(fig_dir, tfm_frames_dir, frame_index, "tf_maps.png")

    println("Finished window : [$t_start, $t_end]")
    println("Output file     : $output_file")
    println("Signal frame    : $stm_frame")
    println("Freq frame      : $fm_frame")
    println("TF-map frame    : $tfm_frame")
end

function main()
    input_csv = "data/probe_ricker_wavelet_long_time.csv"
    runs_dir = "runs_windowed"

    stm_frames_dir = joinpath(runs_dir, "animation_frames_signals_time_marginals")
    fm_frames_dir  = joinpath(runs_dir, "animation_frames_frequency_marginals")
    tfm_frames_dir = joinpath(runs_dir, "animation_frames_tf_maps")

    local_norm = false
    usetex = true
    style = "portable"
    dpi = 300
    format = "png"
    legacy_output = "h5"
    dt_target = nothing

    windows = [
        (1.0, 10.0),
        (100.0, 110.0),
        (200.0, 210.0),
        (300.0, 310.0),
        (400.0, 410.0),
        (500.0, 510.0),
        (600.0, 610.0),
        (700.0, 710.0),
        (800.0, 810.0),
        (900.0, 910.0),
        (1000.0, 1010.0),
        (2000.0, 2010.0),
        (3000.0, 3010.0),
        (4000.0, 4010.0),
        (5000.0, 5010.0),
        (6000.0, 6010.0),
        (7000.0, 7010.0),
        (8000.0, 8010.0),
        (9000.0, 9010.0),
        (9989.0, 9999.0),
    ]

    clear_old_frames(stm_frames_dir)
    clear_old_frames(fm_frames_dir)
    clear_old_frames(tfm_frames_dir)

    for (i, (t_start, t_end)) in enumerate(windows)
        run_one_window(
            input_csv=input_csv,
            runs_dir=runs_dir,
            local_norm=local_norm,
            usetex=usetex,
            style=style,
            dpi=dpi,
            format=format,
            legacy_output=legacy_output,
            t_start=t_start,
            t_end=t_end,
            frame_index=i,
            stm_frames_dir=stm_frames_dir,
            fm_frames_dir=fm_frames_dir,
            tfm_frames_dir=tfm_frames_dir,
            dt_target=dt_target,
            use_global_time=true,
            signals_ylim=(-0.55, 1.05),
            tem_ylim=(-1.0, 1.0),
            tpm_ylim=(-1.0, 1.0),
            fem_ylim=(-1.0, 1.0),
            fpm_ylim=(-1.0, 1.0),
            tfem_vmin=-1.,
            tfem_vmax=1.,
            tfpm_vmin=-1.,
            tfpm_vmax=1.,
        )
    end

    build_animation_pair(stm_frames_dir, joinpath(runs_dir, "signal_time_marginals"); fps=1)
    build_animation_pair(fm_frames_dir,  joinpath(runs_dir, "frequency_marginals"); fps=1)
    build_animation_pair(tfm_frames_dir, joinpath(runs_dir, "tf_maps"); fps=1)

    println("--------------------------------------------------")
    println("Created:")
    println("  ", joinpath(runs_dir, "signal_time_marginals.gif"))
    println("  ", joinpath(runs_dir, "signal_time_marginals.mp4"))
    println("  ", joinpath(runs_dir, "frequency_marginals.gif"))
    println("  ", joinpath(runs_dir, "frequency_marginals.mp4"))
    println("  ", joinpath(runs_dir, "tf_maps.gif"))
    println("  ", joinpath(runs_dir, "tf_maps.mp4"))
end

main()