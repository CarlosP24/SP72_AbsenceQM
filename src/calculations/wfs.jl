function sum_majo(Ψ, srad, N)
    Ψmatrix = reshape(Ψ, 4, srad, N)
    Ψintrad = dropdims(sum(Ψmatrix, dims = 2), dims = 2)
    return dropdims(sum(abs2.(Ψintrad), dims = 1), dims = 1)
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
        srad = round(system.params_wire.R / system.params_wire.a0)
    end

    Ψs = pfunction(
        (x) -> try
            kw = (; ω, Φ = x)
            if params_wire isa Params_Partial
                kw = (; ω, B = x)
            end
            ϵ, Ψ = spectrum(h(; kw...), solver = ES.ShiftInvert(ES.ArnoldiMethod(nev = 2), 0.0))
            Ψ1 = Ψ[:, 1]
            Ψ2 = Ψ[:, 2]

            ΨL = Ψ1 + Ψ2
            ΨR = Ψ1 - Ψ2

            ΨL2 = sum_majo(ΨL, srad, N)
            ΨR2 = sum_majo(ΨR, srad, N)

            return ΨL2, ΨR2
        catch e
            @warn "Error calculating wavefunction at x=$x: $e"
            return fill(NaN, size(h, 1))
        end,
        [xs]
    )

    Psis = Dict(
        name => Ψs[i] for (i, name) in enumerate(["Majo", "QMajo"])
    )
 
    return Results(
        system = system, 
        Psis = Psis, 
        path = path
        )
end

