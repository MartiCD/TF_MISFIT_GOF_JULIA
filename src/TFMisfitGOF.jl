module TFMisfitGOF

export KN, NF, W0,
       morlet, cwt,
       fcoolr!, fcoolr_complex,
       tf_misfits_glob, tf_misfits_loc,
       strip_quotes, parse_fortran_logical, read_fortran_namelist_input,
       write_1d, write_2d_slices,
       run_legacy_script,
       compute_from_inputfile,
       validate_example_run,
       run_prepare,
       run_compute,
       run_plot,
       run_pipeline,
       create_run_dirs,
       main_cli,
       main_legacy,
       main

include("constants.jl")
include("fft_legacy.jl")
include("cwt.jl")
include("misfit_global.jl")
include("misfit_local.jl")
include("input_parsing.jl")
include("io_legacy.jl")
include("legacy.jl")
include("driver.jl")
include("api.jl")
include("cli.jl")

# For demonstration purposes
# we include the code to generate synthetic signals that can be used to test the TF-MISFIT-GOF implementation. 
# This is not part of the core library functionality, but it is useful for users who want to understand 
# how the misfit and GOF metrics behave with known signals.
include("demo_signals.jl")

export ricker_wavelet
export make_amplitude_demo, make_shift_demo, make_mixed_demo
export write_demo_csv
export run_tf_metric_demo

# Keep `main` as the CLI entrypoint for backward compatibility with PR3 docs.
const main = main_cli

end