# Illustrative calculation for the talk introduction (slide 5, partial shell), not a result
# of the paper: DOS vs Zeeman field where μ(z) varies, as in data/DOS/base_partial.jld2
# (paper Fig. 1c, χ = 200 nm), for a sharper end, χ = 50 nm. There the quasi-MZM pair
# overlaps and splits instead of pinning to zero energy before V_Z^c. Same routine as
# calc_DOS_B in src/calculations/DOS.jl (NDOS sites over the length L = log(100)χ where
# μ(z) varies), same wire, grid and broadening; only χ changes.
#
# Run from the repo root:  julia --project=. slides/calc_qmzm_dos.jl
# Output: slides/data/DOSvB_partial_chi50.jld2 (a few minutes, one process)

cd(joinpath(@__DIR__, ".."))
using Quantica, FullShell, Parameters, JLD2, LinearAlgebra
using SpecialFunctions, FunctionZeros

include(joinpath(pwd(), "src/utilities.jl"))
include_all("builders")
include(joinpath(pwd(), "src/operators/greens.jl"))
include(joinpath(pwd(), "src/models/models.jl"))

function dos_vB(; χ = 50, name = "base_partial")
    @load "data/DOS/$(name).jld2" res             # published χ = 200 nm case: grid and wire
    pw = res.system.params_wire
    @unpack Brng, ωrng, NDOS = res.system.calc_params
    g, L = greens_softwire(pw, χ)
    N = round(Int, L / pw.a0)
    step = max(1, round(Int, N / NDOS))
    positions = Set(x * pw.a0 for x in 0:step:N)
    ρ = ldos(g[region = r -> r[1] in positions]; kernel = I)
    # NaN above the Pauli limit (B > Bc, Δ(B) undefined), as calc_DOS_B does
    DOS = [try sum(ρ(ω; ω, B)) catch; NaN end for B in Brng, ω in ωrng]
    return (; Brng = collect(Brng), ωrng = collect(ωrng), DOS, χ, L,
        note = "Illustrative (talk intro): DOS vs B where μ(z) varies, $(name) with χ = $(χ) nm; " *
               "same routine, wire, grid and broadening as data/DOS/$(name).jld2.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    t = @elapsed out = dos_vB()
    mkpath("slides/data")
    jldsave("slides/data/DOSvB_partial_chi50.jld2"; out...)
    @info "Saved slides/data/DOSvB_partial_chi50.jld2" size(out.DOS) t
end
