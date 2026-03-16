function build(params_wire::Union{Params, Params_Partial})
    if params_wire isa Params
        hSM, hSC, params_wire = build_cyl(params_wire)
    elseif params_wire isa Params_Partial
        hSM, hSC, params_wire = build_partial(params_wire)
    end
    return hSM, hSC, params_wire
end
function greens_softwire(params_wire::Union{Params, Params_Partial} , χ, Vdis = 0)
    hSM, hSC, params_wire = build(params_wire)
    hstep, L = build_barrier(hSC, params_wire, χ)
    hstep = build_disorder(hstep, Vdis)
    gSC = hSC |> greenfunction(GS.Schur(boundary = 0))
    g = hstep |> attach(gSC; region = r -> r[1] == L) |> greenfunction()
    return g, L
end