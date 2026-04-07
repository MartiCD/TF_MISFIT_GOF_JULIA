using Test
using TFMisfitGOF

@testset "TFMisfitGOF" begin
    include("test_examples.jl")
    include("test_cli.jl")
end