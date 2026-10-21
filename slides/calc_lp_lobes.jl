# Illustrative calculation for the talk introduction (Little–Parks slide), not a result of
# the paper: pairing amplitude Δ(Φ) and spectral gap Ω(Φ) of the paper's shell (base_fs:
# R = 70 nm, d = 10 nm, ξ_d = 70 nm, Δ0 = 0.23 meV), from the same Abrikosov–Gor'kov pair
# breaking Λ(Φ, n) the model uses (FullShell.pairbreaking, ΔD, Ω), with fluxoid n = round(Φ/Φ0).
#
# Run from the repo root:  julia --project=. slides/calc_lp_lobes.jl
# Output: slides/data/lp_lobes.jld2 (seconds)

cd(joinpath(@__DIR__, ".."))
using FullShell, JLD2

pw = (R = 70, d = 10, ξd = 70, Δ0 = 0.23)      # base_fs, src/models/fullshells.jl
Φs = collect(range(-0.6, 2.6, length = 1601))
Λs = [pairbreaking(Φ, round(Int, Φ), pw.Δ0, pw.ξd, pw.R, pw.d) for Φ in Φs]
Δs = [ΔD(Λ, pw.Δ0) for Λ in Λs]
Ωs = [max(Ω(Λ, pw.Δ0), 0.0) for Λ in Λs]
jldsave("slides/data/lp_lobes.jld2"; Φs, Δs, Ωs, Δ0 = pw.Δ0, params = pw,
    note = "Illustrative (talk intro): Little–Parks lobes of the base_fs shell, Usadel pair breaking.")
@info "Saved slides/data/lp_lobes.jld2" extrema(Ωs ./ pw.Δ0) Ωs[argmin(abs.(Φs .- 0.5))] / pw.Δ0
