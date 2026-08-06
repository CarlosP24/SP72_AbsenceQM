using Pkg
Pkg.activate("plots")
Pkg.instantiate()
using CairoMakie, Parameters, JLD2
using Quantica, FullShell
using FunctionZeros

include("../src/utilities.jl")
include_all("../plots/plotters")

include_all("builders")
include("../src/models/models.jl")
##

## Figure 1
include("figure_wyG.jl")
fig = figure_wyG()
save("plots/figures/Fig1.pdf", fig)
fig

## Figure 2
include("figure_wyS.jl")
fig = figure_wyS()
save("plots/figures/Fig2.pdf", fig)
fig

## Figure 3
include("figure_wyS.jl")
fig = figure_wyS("_weak")
save("plots/figures/Fig3.pdf", fig)
fig

## Figure 4
include("figure_skin.jl")
fig = figure_skin()
save("plots/figures/Fig4.pdf", fig)
fig

## Figure S1
include("figure_conductance.jl")
fig = figure_conductance("_Zs")
save("plots/figures/SFig_Conductance.pdf", fig)
fig

## Figure S2 
include("figure_temperature.jl")
fig = figure_temperature()
save("plots/figures/SFig_Temperature.pdf", fig)
fig

