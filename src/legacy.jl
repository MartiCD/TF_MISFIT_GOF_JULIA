# Wrapper around the current monolithic API to provide a legacy interface for older codebases.
# Day 1 goal: package the existing code, not rewrite the math

const LEGACY_SCRIPT = joinpath(@__DIR__, "tf_misfit_port.jl")

"""
    run_legacy_script(input_file::AbstractString; workdir::AbstractString=pwd())

Execute the existing Julia script in 'src/tf_misfit_port.jl' inside 'workdir' passing 'input_file' exactly as the current pipeline does.
"""
function run_legacy_script(input_file::AbstractString; workdir::AbstractString=pwd())
    cmd = `$(Base.julia_cmd()) --project=$(dirname(@__DIR__)) $LEGACY_SCRIPT $input_file`
    return cd(workdir) do 
        run(cmd)
    end
end