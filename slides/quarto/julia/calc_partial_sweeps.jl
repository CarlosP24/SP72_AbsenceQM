# Illustrative calculations for the web talk (part I, partial shell), not results of the
# paper. Both reuse the paper's wire (base_partial) and routines unchanged; only χ varies.
#
#  1. Quasi-MZM pair at V_Z^(2) = 1.8 meV for a log-spaced sweep of χ (animation of the
#     pair separating and pinning). Same routine as slides/calc_qmzm_wfs.jl (closed wire of
#     length 100χ, the two states closest to zero rotated into the most localized real pair).
#  2. End LDOS vs V_Z for χ = 50 and 100 nm, between the abrupt end (χ = 1 nm,
#     slides/calc_sharp_ldos.jl) and the published χ = 200 nm (data/LDOSvB/base_partial).
#     Same grid and broadening as the published file.
#
# Run from the repo root (root environment):
#   julia --project=. slides/quarto/julia/calc_partial_sweeps.jl   (a few minutes)
# Output: slides/data/wfs_partial_chisweep.jld2, slides/data/LDOSvB_partial_chi{50,100}.jld2

include(joinpath(@__DIR__, "..", "..", "calc_qmzm_wfs.jl"))     # cd's to the repo root; qmzm_wfs

function ldos_vB(χ; name = "base_partial")
    @load "data/LDOSvB/$(name).jld2" res
    pw = res.system.params_wire
    @unpack Brng, ωrng = res.system.calc_params
    g, L = greens_softwire(pw, χ)
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)
    Bs, ωs = collect(Brng), collect(ωrng)
    LDOS = fill(NaN, length(Bs), length(ωs))
    # NaN above the Pauli limit (B > Bc, Δ(B) undefined), as calc_LDOS_vB does.
    # Sequential: the Green function caches are not thread-safe.
    for i in eachindex(Bs)
        for (j, ω) in enumerate(ωs)
            LDOS[i, j] = try sum(ρ(ω; ω, B = Bs[i])) catch; NaN end
        end
    end
    return (; Brng = Bs, ωrng = ωs, LDOS, χ, L,
        note = "Illustrative (web talk): end LDOS vs B of $(name) with χ = $(χ) nm; " *
               "same wire, grid and broadening as data/LDOSvB/$(name).jld2.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    χs = round.(Int, exp10.(range(log10(20), log10(400), length = 25)))
    t = @elapsed res = [qmzm_wfs(χ) for χ in χs]
    path = "slides/data/wfs_partial_chisweep.jld2"
    jldsave(path; χs, a0 = 5, B = 1.8,
        ΨL = [r.ΨL for r in res], ΨR = [r.ΨR for r in res], ε = [r.ε for r in res],
        note = "Illustrative (web talk): quasi-MZM pair of base_partial at V_Z = 1.8 meV for a " *
               "sweep of χ (nm); routine of slides/calc_qmzm_wfs.jl. Eigenvalues of H(ω = 0).")
    @info "Saved $path" t χs
    for χ in (50, 100)
        t = @elapsed out = ldos_vB(χ)
        p = "slides/data/LDOSvB_partial_chi$(χ).jld2"
        jldsave(p; out...)
        @info "Saved $p" t
    end
end
