# Illustrative calculation for the talk introduction (slide 5, partial shell), not a result
# of the paper: quasi-MZM pair of the paper's partial-shell wire (base_partial, V_Z^(2) =
# 1.8 meV) for sharper ends than the published χ = 200 nm, where the inner component
# still oscillates and the pair hybridizes. Same routine as src/calculations/wfs.jl
# (closed wire of length 100χ, two eigenstates closest to zero rotated into the most
# localized real pair); only χ changes.
#
# Run from the repo root:  julia --project=. slides/calc_qmzm_wfs.jl
# Output: slides/data/wfs_partial_chis.jld2 (seconds)

cd(joinpath(@__DIR__, ".."))
using Quantica, FullShell, Parameters, JLD2, LinearAlgebra
using SpecialFunctions, FunctionZeros, ArnoldiMethod, LinearMaps

include(joinpath(pwd(), "src/utilities.jl"))
include_all("builders")
include(joinpath(pwd(), "src/operators/greens.jl"))
include(joinpath(pwd(), "src/models/models.jl"))
include(joinpath(pwd(), "src/calculations/wfs.jl"))      # rotate_majorana_pair, longitudinal_density

function qmzm_wfs(χ; name = "base_partial", B = 1.8)
    pw = systems[name].params_wire
    _, hSC, pw = build(pw)
    h, L = build_barrier(hSC, pw, χ; pref = 100)
    ε, Ψ = spectrum(h(; ω = 0.0 + 1e-3im, B), solver = ES.ShiftInvert(ES.ArnoldiMethod(nev = 2), 0.0))
    ΨL, ΨR = rotate_majorana_pair(Ψ[:, 1], Ψ[:, 2], 1)
    return (; χ, L, ε = collect(ε), ΨL = longitudinal_density(ΨL, 1), ΨR = longitudinal_density(ΨR, 1))
end

if abspath(PROGRAM_FILE) == @__FILE__
    χs = [20, 30, 40, 50, 60, 80, 100]
    res = [qmzm_wfs(χ) for χ in χs]
    path = "slides/data/wfs_partial_chis.jld2"
    jldsave(path; χs, a0 = 5, B = 1.8,
        ΨL = [r.ΨL for r in res], ΨR = [r.ΨR for r in res], ε = [r.ε for r in res],
        note = "Illustrative (talk intro, slide 5): quasi-MZM pair of base_partial at V_Z = 1.8 meV " *
               "for several χ (nm); same routine as src/calculations/wfs.jl. Eigenvalues are those " *
               "of H(ω = 0), not the renormalized energies.")
    @info "Saved $path" χs [abs(r.ε[1]) for r in res]
end
