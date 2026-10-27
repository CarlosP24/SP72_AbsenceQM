# Illustrative calculation for the web talk (slide 7), not a result of the paper: the
# quasi-MZM pair of base_partial at V_Z^(2) = 1.8 meV along the χ sweep of
# calc_partial_sweeps.jl, keeping the signed amplitudes (slides/calc_qmzm_amp.jl, same routine
# as src/calculations/wfs.jl). Per χ, up to z = zmax: the largest spinor component of each
# Majorana (signed, real after the rotation), both densities, the coupling density
# c(z) = Ψ_L(z)ᵀ(HΨ_R)(z) (its sum is the splitting), and the spatial overlap Σ√(ρ_L ρ_R) of
# the normalised densities, which stays large while the splitting collapses.
#
# Run from the repo root:  julia --project=. slides/quarto/julia/calc_qmzm_amp_sweep.jl
# Output: slides/data/wfs_partial_ampsweep.jld2 (a few minutes)

include(joinpath(@__DIR__, "..", "..", "calc_qmzm_amp.jl"))      # cd's to the repo root; qmzm_amp

function amp_sweep_point(χ; zmax = 1600)
    r = qmzm_amp(χ)
    ρL, ρR = vec(sum(abs2, r.ΨL, dims = 1)), vec(sum(abs2, r.ΨR, dims = 1))
    ρL ./= sum(ρL); ρR ./= sum(ρR)
    big(Ψ) = Ψ[argmax(vec(sum(abs2, Ψ, dims = 2))), :]
    keep = r.z .<= zmax
    return (; χ, z = r.z[keep], ψL = big(r.ΨL)[keep], ψR = big(r.ΨR)[keep], ρL = ρL[keep], ρR = ρR[keep],
        c = r.c[keep], creal = r.creal[keep], E = sum(r.c), Ereal = sum(r.creal), ε = r.ε,
        overlap = sum(sqrt.(ρL .* ρR)), ks = r.ks, kL = r.kL ./ sum(r.kL), kR = r.kR ./ sum(r.kR),
        koverlap = sum(sqrt.(r.kL ./ sum(r.kL) .* r.kR ./ sum(r.kR))))
end

if abspath(PROGRAM_FILE) == @__FILE__
    χs = round.(Int, exp10.(range(log10(20), log10(400), length = 25)))   # as calc_partial_sweeps.jl
    t = @elapsed res = [amp_sweep_point(χ) for χ in χs]
    path = "slides/data/wfs_partial_ampsweep.jld2"
    jldsave(path; χs, res, B = 1.8,
        note = "Illustrative (web talk, slide 7): quasi-MZM pair of base_partial at V_Z = 1.8 meV vs χ (nm), " *
               "signed largest spinor component, normalised densities, coupling density Ψ_Lᵀ(HΨ_R) " *
               "(c: imaginary part, creal: real part) and overlap Σ√(ρ_L ρ_R); slides/calc_qmzm_amp.jl.")
    @info "Saved $path in $(round(t, digits = 1)) s"
    for r in res
        @info "χ = $(r.χ) nm" overlap = round(r.overlap, sigdigits = 3) koverlap = round(r.koverlap, sigdigits = 3) Ereal = r.Ereal
    end
end
