function reshape_orbitals_radial_longitudinal(ψ, srad)
    n = length(ψ)
    block = 4 * srad
    @assert n % block == 0 "length(ψ) must be divisible by 4*srad"
    N = Int(n ÷ block)
    return reshape(ψ, 4, srad, N)
end

function longitudinal_density(ψ, srad)
    ψ3 = reshape_orbitals_radial_longitudinal(ψ, srad)
    # ρ(x) = Σ_orb Σ_rad |ψ_orb,rad(x)|^2
    return vec(sum(abs2.(ψ3), dims = (1, 2)))
end

function rotate_majorana_pair(Ψ1, Ψ2, srad; nθ = 721)
    phase_fix(ψ) = ψ .* exp(-0.5im * angle(sum(ψ .* ψ)))

    # Start from phase-fixed, normalized eigenvectors.
    u0 = phase_fix(Ψ1)
    v0 = phase_fix(Ψ2)
    u0 ./= norm(u0)
    v0 ./= norm(v0)

    # Scan real rotations in the two-state subspace.
    # Strategy: enforce realness and maximize localization.
    # This naturally separates near-degenerate QMajo from well-separated Majo.
    θs = range(-pi / 2, pi / 2, length = nθ)
    best_score = -Inf
    best_pair = (u0, v0)

    for θ in θs
        c = cos(θ)
        s = sin(θ)

        u = c * u0 + s * v0
        v = -s * u0 + c * v0
        u = phase_fix(u)
        v = phase_fix(v)
        u ./= norm(u)
        v ./= norm(v)

        # Force states to be real (take real parts and renormalize).
        u_real = complex.(real.(u), 0.0)
        v_real = complex.(real.(v), 0.0)
        u_real ./= norm(u_real)
        v_real ./= norm(v_real)

        ρu = longitudinal_density(u_real, srad)
        ρv = longitudinal_density(v_real, srad)

        # Objective: maximize localization (IPR) of both real states.
        ipr = sum(abs2, ρu) + sum(abs2, ρv)
        score = ipr

        if score > best_score
            best_score = score
            x = collect(1:length(ρu))
            μu = sum(x .* ρu) / sum(ρu)
            μv = sum(x .* ρv) / sum(ρv)
            best_pair = μu <= μv ? (u_real, v_real) : (v_real, u_real)
        end
    end

    return best_pair
end

function calc_wfs(name::String)
    system = systems[name]
    @unpack params_wire = system
    @unpack Φs, Bs, χ, outdir = system.calc_params
    ω = 0.0 + 1e-3im

    # Output path
    path = "$(outdir)/wfs/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params_wire = build(params_wire)
    
    h, _ = build_barrier(hSC, params_wire, χ, pref = 100)

    xs = Bs
    srad = 1
    if params_wire isa Params
        xs = Φs
        srad = Int(round(system.params_wire.R / system.params_wire.a0))
    end

    Ψs = map(xs) do x
        try
            kw = (; ω, Φ = x)
            if params_wire isa Params_Partial
                kw = (; ω, B = x)
            end
            _, Ψ = spectrum(h(; kw...), solver = ES.ShiftInvert(ES.ArnoldiMethod(nev = 2), 0.0))
            ΨL, ΨR = rotate_majorana_pair(Ψ[:, 1], Ψ[:, 2], srad)
            ΨLr = longitudinal_density(ΨL, srad)
            ΨRr = longitudinal_density(ΨR, srad)
            return (ΨLr, ΨRr)
        catch e
            @warn "Error calculating wavefunction at x=$x: $e"
            nsites = Int(size(h, 1) ÷ (4 * srad))
            return fill(NaN, nsites), fill(NaN, nsites)
        end
    end

    Psis = Dict(
        name => Ψs[i] for (i, name) in enumerate(["Majo", "QMajo"])
    )
 
    return Results(
        system = system, 
        Psis = Psis, 
        path = path
        )
end