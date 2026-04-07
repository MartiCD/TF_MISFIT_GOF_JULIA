using Test

const LEGACY_OUTPUT_FILES = [
    "MISFIT-GOF.DAT",
]

"""
    compute_from_inputfile(input_file::AbstractString; workdir::AbstractString=pwd())

Run the current legacy implementation using `input_file` inside `workdir`.
Returns the path to the summary output file.
"""
function compute_from_inputfile(input_file::AbstractString; workdir::AbstractString=pwd())
    run_legacy_script(input_file; workdir=workdir)

    summary_file = joinpath(workdir, "MISFIT-GOF.DAT")
    isfile(summary_file) || error("Expected output not found: $summary_file")
    return summary_file
end

"""
    validate_example_run(example_dir::AbstractString)

Run an example directory and check that the expected summary file exists.
"""
function validate_example_run(example_dir::AbstractString)
    input_file = "HF_TF-MISFIT_GOF"
    summary_file = compute_from_inputfile(input_file; workdir=example_dir)
    @test isfile(summary_file)
    return summary_file
end