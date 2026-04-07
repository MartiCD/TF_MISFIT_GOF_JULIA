function print_usage()
    println("""
Usage:
  julia --project -e 'using TFMisfitGOF; TFMisfitGOF.main()' run <workdir> [input_file]
  julia --project -e 'using TFMisfitGOF; TFMisfitGOF.main()' validate <example_dir>

Commands:
  run       Run the legacy TF misfit code inside <workdir>
  validate  Run one example and verify summary output exists
""")
end

function main(args=ARGS)
    isempty(args) && return print_usage()

    cmd = args[1]

    if cmd == "run"
        length(args) < 2 && return print_usage()
        workdir = args[2]
        input_file = length(args) >= 3 ? args[3] : "HF_TF-MISFIT_GOF"
        compute_from_inputfile(input_file; workdir=workdir)
        println("Finished. Outputs written to: ", abspath(workdir))
        return

    elseif cmd == "validate"
        length(args) < 2 && return print_usage()
        example_dir = args[2]
        validate_example_run(example_dir)
        println("Validation passed for: ", abspath(example_dir))
        return
    else
        return print_usage()
    end
end