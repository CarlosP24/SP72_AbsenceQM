function calc_PD_mu_flux(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack μrng, Φrng, outdir = calc_params
    
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
        [μrng, Φrng];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end