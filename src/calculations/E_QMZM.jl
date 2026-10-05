function eigs_near(h, σ; nev = 4, kw...)
    ε, ψ = spectrum(h(; kw...), solver = ES.ShiftInvert(ES.ArnoldiMethod(nev = nev), σ))
    return real.(ε), ψ
end

# Lowest subgap pole of the closed wire, E = λ(H(ω = E)), solved by secant iteration.
# The SC self-energy depends on ω, so eigenvalues of H(ω = 0) overestimate the pole.
function lowest_pole(h, kw; tol = 1e-10, maxit = 40)
    ε, _ = eigs_near(h, 0.0; ω = 0.0, kw...)
    λ0 = minimum(filter(>(0), ε))
    function λ(ω)
        ε, ψ = eigs_near(h, ω; ω, kw...)
        i = argmin(abs.(ε .- ω))
        return ε[i], ψ[:, i]
    end
    ω0, f0 = 0.0, λ0
    ω1 = λ0 / 2
    ε1, ψ1 = λ(ω1)
    f1 = ε1 - ω1
    for _ in 1:maxit
        (abs(f1) < tol * max(1, abs(ω1)) || abs(ω1) < 1e-14) && break
        ω2 = max(ω1 - f1 * (ω1 - ω0) / (f1 - f0), 0.0)
        ω0, f0 = ω1, f1
        ω1 = ω2
        ε1, ψ1 = λ(ω1)
        f1 = ε1 - ω1
    end
    return ω1, λ0, ψ1
end

# Energy of the lowest (quasi-)Majorana state vs χ in a closed wire of length max(pref χ, Lmin)
function calc_E_chi(name::String; pref = 12, Lmin = 15000)
    system = systems[name]
    @unpack χrng, Φs, Bs, outdir = system.calc_params

    # Output path
    path = "$(outdir)/E_QMZM/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params_wire = build(system.params_wire)
    xs = params_wire isa Params ? Φs : Bs

    Es = pfunction(
        (χ, x) -> try
            L = max(pref * χ, Lmin)
            h, L = build_barrier(hSC, params_wire, χ; pref = L / χ)
            kw = params_wire isa Params ? (; Φ = x, Z = 0) : (; B = x)
            E, λ0, ψ = lowest_pole(h, kw)
            zs = [r[1] for r in sites(lattice(h))]
            ρ = vec(sum(abs2.(reshape(ψ, 4, :)), dims = 1))
            ρ ./= sum(ρ)
            (E, λ0, sum(zs .* ρ) / χ, sum(ρ[zs .< L / 2]))
        catch e
            @warn "Error calculating E at (χ=$χ, x=$x): $e"
            (NaN, NaN, NaN, NaN)
        end,
        [χrng, xs];
    )

    # E: self-consistent pole; E0: eigenvalue of H(ω = 0); zc: ⟨z⟩/χ; wL: weight in left half
    E = Dict(
        key => (
            E = first.(Es[:, i]),
            E0 = getindex.(Es[:, i], 2),
            zc = getindex.(Es[:, i], 3),
            wL = last.(Es[:, i]),
        ) for (i, key) in enumerate(["Majo", "QMajo"])
    )

    return (; system, E, pref, Lmin, path)
end
