# Illustrative calculation for the talk introduction (not a result of the paper):
# end LDOS vs Zeeman field of the paper's partial-shell wire (base_partial) with an
# abrupt end, χ = 1 nm. It is the textbook expectation (zero-bias peak only after the
# bulk gap closes at V_Z^c) that slide 3 contrasts with the smooth case of
# data/LDOSvB/base_partial.jld2 (χ = 200 nm, published). Same model, grid and
# broadening as that file; only χ changes.
#
# Run from the repo root:  julia --project=. slides/calc_sharp_ldos.jl
# Output: slides/data/LDOSvB_partial_sharp.jld2 (~1 min, one process)

cd(joinpath(@__DIR__, ".."))
using Quantica, FullShell, Parameters, JLD2, LinearAlgebra
using SpecialFunctions, FunctionZeros

include(joinpath(pwd(), "src/utilities.jl"))
include_all("builders")
include(joinpath(pwd(), "src/operators/greens.jl"))
include(joinpath(pwd(), "src/models/models.jl"))

function sharp_ldos_vB(; χ = 1, name = "base_partial")
    @load "data/LDOSvB/$(name).jld2" res          # published smooth case: grid and wire
    pw = res.system.params_wire
    @unpack Brng, ωrng = res.system.calc_params
    g, L = greens_softwire(pw, χ)
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)
    # NaN above the Pauli limit (B > Bc, Δ(B) undefined), as calc_LDOS_vB does
    LDOS = [try sum(ρ(ω; ω, B)) catch; NaN end for B in Brng, ω in ωrng]
    return (; Brng = collect(Brng), ωrng = collect(ωrng), LDOS, χ, L,
        note = "Illustrative (talk intro): end LDOS vs B of $(name) with χ = $(χ) nm; " *
               "same wire, grid and broadening as data/LDOSvB/$(name).jld2.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    t = @elapsed out = sharp_ldos_vB()
    mkpath("slides/data")
    jldsave("slides/data/LDOSvB_partial_sharp.jld2"; out...)
    @info "Saved slides/data/LDOSvB_partial_sharp.jld2" size(out.LDOS) t
end
