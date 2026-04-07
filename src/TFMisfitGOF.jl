module TFMisfitGOF

export compute_from_inputfile,
       run_legacy_script,
       validate_example_run,
       run_prepare,
       run_compute,
       run_plot,
       run_pipeline,
       create_run_dirs,
       main

include("legacy.jl")
include("api.jl")
include("cli.jl")

end