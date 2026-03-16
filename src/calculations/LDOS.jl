function calc_LDOS(name::String)
    system = systems[name]

    if system.params_wire isa Params_Partial
        res = calc_LDOS_B(name)
        return res
    end

    @unpack χrng, ωrng, Φs, Vdis, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_softwire(system.params_wire, last(χrng), Vdis)
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)

    LDOS = pfunction(
        (χ, ω, Φ) -> try
            ρ(ω; ω, Φ, χ, Z = 0) |> sum
        catch e
            @warn "Error calculating LDOS at (Φ=$Φ, ω=$ω, χ=$χ): $e"
            NaN
        end,
        [χrng, ωrng, Φs];
    )

    LDOS = Dict(
        name => LDOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    return Results(
        system = system,
        LDOS = LDOS,
        path = path,
    )
end

function calc_LDOS_B(name::String)
    system = systems[name]
    @unpack χrng, ωrng, Bs, Vdis, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_softwire(system.params_wire, last(χrng), Vdis)
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)

    LDOS = pfunction(
        (χ, ω, B) -> try
            ρ(ω; ω, B, χ) |> sum
        catch e
            @warn "Error calculating LDOS at (B=$B, ω=$ω, χ=$χ): $e"
            NaN
        end,
        [χrng, ωrng, Bs];
    )

    LDOS = Dict(
        name => LDOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    return Results(
        system = system,
        LDOS = LDOS,
        path = path,
    )
end

