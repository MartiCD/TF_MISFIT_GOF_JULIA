using Test
using TFMisfitGOF

@testset "CLI helpers" begin
    d = mktempdir()

    dirs = create_run_dirs(runs_dir=d, date_str="2026-04-07")
    @test isdir(dirs.work_dir)
    @test isdir(dirs.fig_dir)
    @test isdir(dirs.log_dir)
    @test endswith(dirs.run_name, "_001")

    dirs2 = create_run_dirs(runs_dir=d, date_str="2026-04-07")
    @test endswith(dirs2.run_name, "_002")

    @test_throws Exception main_cli(["prepare"])
    @test_throws Exception main_cli(["plot", "--workdir", "x"])
end

@testset "CLI required option parsing" begin
    opts = TFMisfitGOF._parse_kv_args(["--example-dir", "examples/global"])
    @test opts["--example-dir"] == "examples/global"
end

@testset "CLI validate parsing" begin
    ex = joinpath(normpath(joinpath(@__DIR__, "..")), "examples", "global")
    @test_nowarn main_cli(["validate", "--example-dir", ex])
end