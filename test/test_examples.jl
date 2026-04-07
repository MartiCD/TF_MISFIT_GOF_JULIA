using Test
using TFMisfitGOF

@testset "example runs" begin
    repo_root = normpath(joinpath(@__DIR__, ".."))

    # Adjust these if the example subdirectories evolve.
    candidate_examples = [
        joinpath(repo_root, "examples", "global"),
        joinpath(repo_root, "examples", "local"),
    ]

    found_any = false

    for ex in candidate_examples
        if isdir(ex)
            found_any = true
            @testset basename(ex) begin
                summary = validate_example_run(ex)
                @test isfile(summary)
                @test filesize(summary) > 0
            end
        end
    end

    @test found_any
end