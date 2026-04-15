using Test
using TFMisfitGOF

@testset "demo signal generators" begin
    t = collect(-1.0:0.001:1.0)

    @testset "ricker_wavelet" begin
        w = ricker_wavelet(t, 5.0; t0=0.0)
        @test length(w) == length(t)
        @test all(isfinite, w)
        @test maximum(abs.(w)) > 0
    end

    @testset "amplitude demo" begin
        s_ref, s_test = make_amplitude_demo(t; f0=5.0, amp_scale=1.01)
        @test length(s_ref) == length(t)
        @test length(s_test) == length(t)
        @test all(isfinite, s_ref)
        @test all(isfinite, s_test)
        @test maximum(abs.(s_test)) > maximum(abs.(s_ref))
    end

    @testset "shift demo" begin
        s_ref, s_test = make_shift_demo(t; f0=5.0, shift_fraction_of_period=0.01)
        @test length(s_ref) == length(t)
        @test length(s_test) == length(t)
        @test s_ref != s_test
        @test isapprox(sum(abs, s_ref), sum(abs, s_test); rtol=1e-2)
    end

    @testset "mixed demo" begin
        s_ref, s_test = make_mixed_demo(
            t; f0=5.0, amp_scale=1.01, shift_fraction_of_period=0.01
        )
        @test length(s_ref) == length(t)
        @test length(s_test) == length(t)
        @test s_ref != s_test
    end
end

@testset "write_demo_csv" begin
    t = collect(-1.0:0.5:1.0)
    s1 = copy(t)
    s2 = 2 .* t
    tmp = mktempdir()
    path = joinpath(tmp, "demo.csv")

    out = write_demo_csv(path, t, s1, s2)
    @test out == path
    @test isfile(path)

    lines = readlines(path)
    @test lines[1] == "time,signal1,signal2"
    @test length(lines) == length(t) + 1
end