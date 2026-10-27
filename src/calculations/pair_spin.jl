# Talk check (not a paper result): what decouples the two halves of the quasi-MZM pair? For the
# closed wire of calc_E_chi (length max(pref χ, Lmin)) at the quasi-MZM field Φs[2] / Bs[2],
# the two states closest to zero of H(ω = 0) are rotated into the most localised real pair
# (rotate_majorana_pair, as calc_wfs). Per Majorana: the density along z, the electron spin
# along the field (σz on the electron components, total and along z), and the momentum
# content |Ψ(k)|² (all components, and electron ↑/↓ separately); per χ, the spatial overlap
# Σ√(ρ1 ρ2) of the normalised densities and |E0|. Opposite spins with a large overlap point to
# the spin-channel decoupling of Kells et al. (2012) and Vuik et al. (2019) rather than
# separation.
function calc_pair_spin(name::String; pref = 12, Lmin = 15000, ks = range(0, 0.2, length = 801))
    system = systems[name]
    @unpack χs, Φs, Bs, outdir = system.calc_params
    path = "$(outdir)/pair_spin/$(name).jld2"
    mkpath(dirname(path))

    _, hSC, params_wire = build(system.params_wire)
    kw = params_wire isa Params ? (; Φ = Φs[2], Z = 0) : (; B = Bs[2])

    res = pfunction(
        (χ,) -> try
            L = max(pref * χ, Lmin)
            h, L = build_barrier(hSC, params_wire, χ; pref = L / χ)
            ε, Ψ = eigs_near(h, 0.0; nev = 2, ω = 0.0, kw...)
            zsite = [r[1] for r in sites(lattice(h))]
            srad = count(==(zsite[1]), zsite)
            γ1, γ2 = rotate_majorana_pair(Ψ[:, 1], Ψ[:, 2], srad)
            z = zsite[1:srad:end]
            measure(γ) = begin
                ψ = reshape(real.(γ), 4, srad, :)
                ρ = vec(sum(abs2, ψ, dims = (1, 2))); ρ ./= sum(ρ)
                up, dn = vec(sum(abs2, ψ[1, :, :], dims = 1)), vec(sum(abs2, ψ[2, :, :], dims = 1))
                ph = [exp(-im * k * zz) for k in ks, zz in z]           # nk × nz
                F(o) = vec(sum(abs2, ph * transpose(ψ[o, :, :]), dims = 2))   # Σ_rad |Σ_z ψ e^{-ikz}|²
                Fo = [F(o) for o in 1:4]
                (; ρ, sz = up .- dn, s = (sum(up) - sum(dn)) / (sum(up) + sum(dn)),
                    Fk = sum(Fo) ./ maximum(sum(Fo)), Fup = Fo[1] ./ maximum(sum(Fo)), Fdn = Fo[2] ./ maximum(sum(Fo)))
            end
            m1, m2 = measure(γ1), measure(γ2)
            (; χ, L, z, E0 = minimum(abs, ε), overlap = sum(sqrt.(m1.ρ .* m2.ρ)), m1, m2)
        catch e
            @warn "Error at χ=$χ: $e"
            (; χ, L = NaN, z = Float64[], E0 = NaN, overlap = NaN, m1 = nothing, m2 = nothing)
        end,
        [χs];
    )
    return (; system, res = vec(res), ks = collect(ks), pref, Lmin, path)
end
