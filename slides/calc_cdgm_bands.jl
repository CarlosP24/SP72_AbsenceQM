# Illustrative calculation for the talk introduction (slide on CdGM analogs), not a
# result of the paper: bands vs k_z and end LDOS of a hollow-core full-shell wire inside
# the first lobe (n = 1), static self-energy Σ = Γ_S τ_x. At Φ = nΦ0 the hollow-core
# analogs are degenerate at the gap edge (degeneracy point, PRB 107, 155423), so the
# ladder is shown away from it; Φ = 0 (n = 0) is kept for reference. It reuses the
# thesis builder PT_Thesis/PT3_CdGM/src/builders/hollow_bands.jl (wire `hollow_b`,
# the San-Jose et al. PRB 107, 155423 (2023) Fig. 4(b) wire) unchanged.
#
# Run in the PT3_CdGM environment (FullShell 1.4.0), from this repo's root:
#   julia --project=<PhD>/PT_Thesis/PT3_CdGM slides/calc_cdgm_bands.jl
# Output: slides/data/cdgm_bands.jld2 (plain arrays only; seconds)

const PT3 = joinpath(homedir(), "Library/CloudStorage/Nextcloud-saco.csic.es-CARLOSPAYAHERRERO",
    "PhD/PT_Thesis/PT3_CdGM")
include(joinpath(PT3, "src/builders/hollow_bands.jl"))
using JLD2

function bands_data(Φ; ks = range(-0.04, 0.04, 801), emax = 2.2)
    b = hollow_bands(Φ; ks)
    Δ0 = real(BANDS_WIRE.Δ0)
    ωs = collect(range(-emax, emax, 1201) .* Δ0)
    ρ = hollow_end_ldos(Φ, ωs)
    secs = b.sectors
    return Dict(
        "Φ" => Φ, "n" => b.n, "ΓS" => b.ΓS, "Δ0" => Δ0, "ks" => collect(b.ks),
        "mL" => [Float64(s.mL) for s in secs],
        "analog" => [s.anticrossing for s in secs],
        "sc" => cat([s.sc for s in secs]...; dims = 3),        # k × 2 × sector (meV)
        "e" => reduce(hcat, [s.e for s in secs]),             # k × sector, normal electron
        "h" => reduce(hcat, [s.h for s in secs]),             # k × sector, normal hole
        "vh_k" => [Float64[p[1] for p in s.vh] for s in secs],
        "vh_E" => [Float64[p[2] for p in s.vh] for s in secs],
        "ωs" => ωs,
        "ldos" => reduce(hcat, [ρ[s.mL] for s in secs]),      # ω × sector (arb.)
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    out = Dict("Phi0" => bands_data(0.0), "Phi1" => bands_data(1.0),
        "Phi060" => bands_data(0.6), "Phi075" => bands_data(0.75),
        "wire" => Dict(string(k) => string(v) for (k, v) in pairs(BANDS_WIRE)),
        "note" => "Illustrative (talk intro): hollow-core bands and end LDOS, static Σ = Γ_S τ_x, " *
                  "wire hollow_b of PT3_CdGM (PRB 107, 155423 Fig. 4(b)).")
    path = joinpath(@__DIR__, "data", "cdgm_bands.jld2")
    mkpath(dirname(path))
    save(path, out)
    @info "Saved $path"
end
