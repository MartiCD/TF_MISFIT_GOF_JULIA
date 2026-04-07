module TFMisfitGOF

export compute_from_inputfile,
        run_legacy_script,
        validate_example_run,
        main 

include("legacy.jl")
include("api.jl")
include("cli.jl")

end