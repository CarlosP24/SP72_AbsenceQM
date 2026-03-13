function calc_LDOS(name::String)
    system = systems[name]

    if system.params_wire isa Params_Partial
        res = calc_LDOS_B(name)
        return res
    end

    @unpack χrng, ωrng, Φs, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_softwire(system.params_wire, last(χrng))
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
    @unpack χrng, ωrng, Bs, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_softwire(system.params_wire, last(χrng))
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

function calc_LDOS_dis(name::String)
    system = systems[name]

    if system.params_wire isa Params_Partial
        res = calc_LDOS_B_dis(name)
        return res
    end

    @unpack χrng, ωrng, Φs, uni, Nn, NR, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS_dis/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_diswire(system.params_wire, uni, Nn, last(χrng))
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)

    LDOS = pfunction(
        (χ, ω, Φ, N) -> try
            ρ(ω; ω, Φ, χ, Z = 0) |> sum
        catch e
            @warn "Error calculating LDOS at (Φ=$Φ, ω=$ω, χ=$χ): $e"
            NaN
        end,
        [χrng, ωrng, Φs, 1:NR];
    )
    LDOS = sum(LDOS, dims = 4) ./ NR
    LDOS = Dict(
        name => LDOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    return Results(
        system = system,
        LDOS = LDOS,
        path = path,
    )
end

function calc_LDOS_B_dis(name::String)
    system = systems[name]
    @unpack χrng, ωrng, Bs, Nn, uni, NR, outdir = system.calc_params

    # Output path
    path = "$(outdir)/LDOS_dis/$(name).jld2"
    mkpath(dirname(path))

    g, _ = greens_diswire(system.params_wire, uni, Nn, last(χrng))
    ρ = ldos(g[region = r -> r[1] == 0]; kernel = I)

    LDOS = pfunction(
        (χ, ω, B, N) -> try
            ρ(ω; ω, B, χ) |> sum
        catch e
            @warn "Error calculating LDOS at (B=$B, ω=$ω, χ=$χ): $e"
            NaN
        end,
        [χrng, ωrng, Bs, 1:NR];
    )
    LDOS = sum(LDOS, dims = 4) ./ NR
    LDOS = Dict(
        name => LDOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )

    return Results(
        system = system,
        LDOS = LDOS,
        path = path,
    )
end