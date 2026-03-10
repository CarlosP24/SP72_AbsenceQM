function calc_DOS(name::String)
    system = systems[name]
    @unpack Φrng, ωrng, Zs, outdir = system.calc_params

    # Output path
    path = "$(outdir)/DOS/$(name).jld2"
    mkpath(dirname(path))

    g = greens_softwire(system.params_wire)

    DOS = pfunction(
        (Φ, ω, Z) -> try
            rho = ldos(g(ω; ω, Φ, Z), kernel = I)[] |> sum
        catch e
            @warn "Error calculating DOS at (Φ=$Φ, ω=$ω, Z=$Z): $e"
            NaN
        end,
        [Φrng, ωrng, Zs];
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