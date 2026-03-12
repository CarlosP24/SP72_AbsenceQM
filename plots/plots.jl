using Pkg
Pkg.activate("plots")
Pkg.instantiate()
using CairoMakie, Parameters, JLD2
using Quantica, FullShell
include("../src/utilities.jl")
include_all("../plots/plotters")

include_all("builders")
include("../src/models/models.jl")
##