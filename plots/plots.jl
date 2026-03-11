using Pkg
Pkg.activate("plots")
Pkg.instantiate()
using CairoMakie, Parameters, JLD2
include("../src/utilities.jl")
include_all("../plots/plotters")
##