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

@testset "CLI validate smoke test with legacy-output modes" begin
    repo_root = normpath(joinpath(@__DIR__, ".."))
    src_global = joinpath(repo_root, "examples", "global")
    src_local  = joinpath(repo_root, "examples", "local")

    tmp = mktempdir()
    ex_global = joinpath(tmp, "global")
    ex_local  = joinpath(tmp, "local")

    cp(src_global, ex_global; force=true)
    cp(src_local, ex_local; force=true)

    @testset "summary mode" begin
        @test_nowarn main_cli([
            "validate",
            "--example-dir", ex_global,
            "--legacy-output", "summary",
        ])
        @test isfile(joinpath(ex_global, "MISFIT-GOF.DAT"))
        @test isfile(joinpath(ex_global, "results.h5"))
    end

    @testset "h5 mode" begin
        @test_nowarn main_cli([
            "validate",
            "--example-dir", ex_local,
            "--legacy-output", "h5",
        ])
        @test isfile(joinpath(ex_local, "results.h5"))
    end
end