module TFMisfitGOF

export KN, NF, W0,
       morlet, cwt,
       fcoolr!, fcoolr_complex,
       tf_misfits_glob, tf_misfits_loc,
       strip_quotes, parse_fortran_logical, read_fortran_namelist_input,
       write_1d, write_2d_slices,
       compute_from_inputfile, main

include("constants.jl")
include("fft_legacy.jl")
include("cwt.jl")
include("misfit_global.jl")
include("misfit_local.jl")
include("input_parsing.jl")
include("io_legacy.jl")
include("api.jl")
include("cli.jl")

end