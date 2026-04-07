using Test
using TFMisfitGOF

@testset "constants" begin
    @test KN == 16
    @test NF == 2^KN
    @test W0 == 6.0
end

@testset "morlet" begin
    @test morlet(1.0, 0.0) == 0.0 + 0.0im
    @test isfinite(real(morlet(1.0, 1.0)))
end

@testset "fft legacy shape" begin
    z = ComplexF64[1+0im, 0+0im, 0+0im, 0+0im]
    out = fcoolr_complex(2, z, -1.0)
    @test length(out) == 4
end

@testset "example runs" begin
    repo_root = normpath(joinpath(@__DIR__, ".."))

    candidate_examples = [
        joinpath(repo_root, "examples", "global"),
        joinpath(repo_root, "examples", "local"),
    ]

    found_any = false

    for ex in candidate_examples
        if isdir(ex)
            found_any = true
            name = basename(ex)

            @testset "$name" begin
                summary = validate_example_run(ex)
                @test isfile(summary)
                @test filesize(summary) > 0
            end
        end
    end

    @test found_any
end