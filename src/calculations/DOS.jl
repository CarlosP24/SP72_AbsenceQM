function calc_DOS(name::String)
    system = systems[name]
    if system.params_wire isa Params_Partial
        res = calc_DOS_B(name)
        return res
    end

    @unpack Φrng_DOS, ωrng, Zs, NDOS, χ, outdir = system.calc_params
    # Output path
    path = "$(outdir)/DOS/$(name).jld2"
    mkpath(dirname(path))

    g, L = greens_softwire(system.params_wire, χ)
    a0 = system.params_wire.a0
    N = round(Int, L / a0)
    step = max(1, round(Int, N / NDOS))
    positions = [x * a0 for x in 0:step:N]
    ρ = ldos(g[region = r -> r[1] in Set(positions)]; kernel = I)

    DOS = pfunction(
        (Φ, ω, Z) -> try
            ρ(ω; ω, Φ, Z) |> sum
        catch e
            @warn "Error calculating DOS at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [Φrng_DOS, ωrng, Zs];
    )

    DOS = Dict(
        Z => DOS[:, :, i] for (i, Z) in enumerate(Zs)
    )

    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end

function calc_DOS_chi(name::String)
    system = systems[name]

    @unpack χrng, ωrng, Φs, NDOS, outdir = system.calc_params    # Output path
    path = "$(outdir)/DOS_chi/$(name).jld2"
    mkpath(dirname(path))

    g, L = greens_softwire(system.params_wire, last(χrng))
    a0 = system.params_wire.a0
    N = round(Int, L / a0)
    step = max(1, round(Int, N / NDOS))
    positions = [x * a0 for x in 0:step:N]
    ρ = ldos(g[region = r -> r[1] in Set(positions)]; kernel = I)

    DOS = pfunction(
        (χ, ω, Φ) -> try
            ρ(ω; χ, ω, Φ) |> sum
        catch e
            @warn "Error calculating DOS at (Φ=$Φ, ω=$ω, χ=$χ): $e"
            NaN
        end,
        [χrng, ωrng, Φs];
    )

    DOS = Dict(
        name => DOS[:, :, i] for (i, name) in enumerate(["Majo", "QMajo"])
    )


    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end

function calc_DOS_B(name::String)
    system = systems[name]
    @unpack Brng, ωrng, NDOS, χ, outdir = system.calc_params
    # Output path
    path = "$(outdir)/DOS/$(name).jld2"
    mkpath(dirname(path))

    g, L = greens_softwire(system.params_wire, χ)
    a0 = system.params_wire.a0
    N = round(Int, L / a0)
    step = max(1, round(Int, N / NDOS))
    positions = [x * a0 for x in 0:step:N]
    ρ = ldos(g[region = r -> r[1] in Set(positions)]; kernel = I)

    DOS = pfunction(
        (B, ω) -> try
            ρ(ω; ω, B) |> sum
        catch e
            @warn "Error calculating DOS at (B=$B, ω=$ω): $e"
            NaN
        end,
        [Brng, ωrng];
    )
        
    return Results(
        system = system,
        DOS = DOS,
        path = path,
    )
end