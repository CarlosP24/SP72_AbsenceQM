# Illustrative calculation for the talk introduction (slide 5), not a result of the paper:
# the quasi-MZM pair of base_partial at V_Z^(2) = 1.8 meV for χ = 200 nm (the published case)
# and χ = 50 nm, keeping the signed Majorana amplitudes (calc_qmzm_wfs.jl keeps densities).
# Same routine as src/calculations/wfs.jl. Saved per Majorana: the 4 spinor components on
# the chain (rotated to real), their wavelength content |Ψ(k)|² (sum over components), and
# the coupling density c(z) = Im[Ψ_L(z)ᵀ (H Ψ_R)(z)], whose integral is the splitting.
#
# Run from the repo root:  julia --project=. slides/calc_qmzm_amp.jl
# Output: slides/data/wfs_partial_amp.jld2 (seconds)

cd(joinpath(@__DIR__, ".."))
using Quantica, FullShell, Parameters, JLD2, LinearAlgebra
using SpecialFunctions, FunctionZeros, ArnoldiMethod, LinearMaps

include(joinpath(pwd(), "src/utilities.jl"))
include_all("builders")
include(joinpath(pwd(), "src/operators/greens.jl"))
include(joinpath(pwd(), "src/models/models.jl"))
include(joinpath(pwd(), "src/calculations/wfs.jl"))      # rotate_majorana_pair

function qmzm_amp(χ; name = "base_partial", B = 1.8, ks = range(0, 0.2, length = 801))
    pw = systems[name].params_wire
    _, hSC, pw = build(pw)
    h, L = build_barrier(hSC, pw, χ; pref = 100)
    H = h(; ω = 0.0 + 1e-3im, B)
    ε, Ψ = spectrum(H, solver = ES.ShiftInvert(ES.ArnoldiMethod(nev = 2), 0.0))
    ΨL, ΨR = rotate_majorana_pair(Ψ[:, 1], Ψ[:, 2], 1)
    M = H[()]                                               # flat sparse matrix of the closed wire
    a0 = pw.a0
    z = collect(0:length(ΨL) ÷ 4 - 1) .* a0
    comps(ψ) = real.(reshape(ψ, 4, :))                       # 4 × N, real after the rotation
    spec(ψ) = [sum(abs2, reshape(ψ, 4, :) * exp.(-im .* k .* z)) for k in ks] .* a0^2
    HR = M * ΨR
    c = vec(sum(reshape(conj.(ΨL) .* HR, 4, :), dims = 1))
    return (; χ, z, ε = collect(ε), ΨL = comps(ΨL), ΨR = comps(ΨR), kL = spec(ΨL), kR = spec(ΨR),
        ks = collect(ks), c = imag.(c), creal = real.(c))
end

if abspath(PROGRAM_FILE) == @__FILE__
    res = Dict(string(χ) => qmzm_amp(χ) for χ in (200, 50))
    jldsave("slides/data/wfs_partial_amp.jld2"; res,
        note = "Illustrative (talk intro, slide 5): signed quasi-MZM amplitudes of base_partial at " *
               "V_Z = 1.8 meV, χ = 200 and 50 nm; |Ψ(k)|²; coupling density Im[Ψ_L H Ψ_R].")
    for (k, r) in res
        @info "χ = $k nm" sum(r.c) sum(r.creal) abs.(r.ε)
    end
end
