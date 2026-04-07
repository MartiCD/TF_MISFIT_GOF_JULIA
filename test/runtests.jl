using Test
using TFMisfitGOF

@testset "TFMisfitGOF" begin
    @test KN == 16
    @test NF == 2^KN
    @test W0 == 6.0

    @test morlet(1.0, 0.0) == 0.0 + 0.0im
    @test isfinite(real(morlet(1.0, 1.0)))

    z = ComplexF64[1 + 0im, 0 + 0im, 0 + 0im, 0 + 0im]
    out = fcoolr_complex(2, z, -1.0)
    @test length(out) == 4

    include("test_examples.jl")
    include("test_cli.jl")
end