function get_preα(params_wire)
    @unpack R, Vmin, Vmax = params_wire
    return α -> R * α / ((Vmax - Vmin))
end
function calc_PD_mu_alpha(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack αrng, μrng, outdir = calc_params
    # Output path
    path = "$(outdir)/PD_mu_alpha/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params = build_cyl(params_wire)

    fpα = get_preα(params_wire)
    preαrng = fpα.(αrng)

    PD = pfunction(
        (μ, preα) -> try 
            pfaffian(hSC(; ω = 1e-3im, μ = μ, preα = preα, Φ = 0.501, Z = 0), SA[0])
        catch e 
            @warn "Error calculating PD at (μ=$μ, preα=$preα): $e"
            NaN
        end,
        [μrng, preαrng];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end

function calc_PD_mu_alpha_Z(name::String)
    system = systems[name]
    @unpack params_wire, calc_params = system
    @unpack αrng, μrng, Zs, outdir = calc_params
    # Output path
    path = "$(outdir)/PD_mu_alphaZ/$(name).jld2"
    mkpath(dirname(path))

    hSM, hSC, params = build_cyl(params_wire)

    fpα = get_preα(params_wire)
    preαrng = fpα.(αrng)

    PD = pfunction(
        (μ, preα) -> try 
            Q = pfaffian(hSC(; ω = 1e-3im, μ = μ, preα = preα, Φ = 0.501, Z = 0), SA[0])
            Q *= prod(Z -> pfaffian(hSC(; ω = 1e-3im, μ = μ, preα = preα, Φ = 0.501, Z = Z), hSC(; ω = 1e-3im, μ = μ, preα = preα, Φ = 0.501, Z = -Z), SA[0]), Zs; init = 1)
        catch e 
            @warn "Error calculating PD at (μ=$μ, preα=$preα, Z=$Z): $e"
            NaN
        end,
        [μrng, preαrng];
    )

    return Results(
        system = system,
        PD = PD,
        path = path,
    )
end