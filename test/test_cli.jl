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

    @test_throws Exception TFMisfitGOF.main(["prepare"])
    @test_throws Exception TFMisfitGOF.main(["plot", "--workdir", "x"])
end

@testset "plot API validation" begin
    @test_throws Exception run_plot("a", "b"; format="jpg")
    @test_throws Exception run_plot("a", "b"; style="fancy")
end