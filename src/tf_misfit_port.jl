include("TFMisfitGOF.jl")
using .TFMisfitGOF

input_file = isempty(ARGS) ? "HF_TF-MISFIT_GOF" : ARGS[1]
main_legacy(input_file)