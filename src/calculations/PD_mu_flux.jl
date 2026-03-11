function calc_PD_mu_flux(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack μrng, Φrng_PD, outdir = calc_params
    
    # Output path
    path = "$(outdir)/PD_mu_flux/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params = build_cyl(params_wire)

    PD = pfunction(
        (μ, Φ) -> try 
            pfaffian(hSC(; ω = 1e-3im, μ = μ, Φ = Φ, Z = 0), SA[0])
        catch e 
            @warn "Error calculating PD at (μ=$μ, Φ=$Φ): $e"
            NaN
        end,
        [μrng, Φrng_PD];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end

function calc_PD_flux(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack Φrng_PD, outdir = calc_params

    # Output path
    path = "$(outdir)/PD_flux/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params = build_cyl(params_wire)

    PD = pfunction(
        (Φ) -> try 
            pfaffian(hSC(; ω = 1e-3im, Φ = Φ, Z = 0), SA[0])
        catch e 
            @warn "Error calculating PD at (Φ=$Φ): $e"
            NaN
        end,
        [Φrng_PD];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end

function calc_PD_mu_B(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack μrngP, Brng, outdir = calc_params
    
    # Output path
    path = "$(outdir)/PD_mu_B/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params = build_partial(params_wire)

    PD = pfunction(
        (μ, B) -> try 
            pfaffian(hSC(; ω = 1e-3im, μ = μ, B = B, Z = 0), SA[0])
        catch e 
            @warn "Error calculating PD at (μ=$μ, B=$B): $e"
            NaN
        end,
        [μrngP, Brng];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end