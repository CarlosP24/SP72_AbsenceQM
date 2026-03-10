function greens_softwire(params_wire::Params)
    hSM, hSC, params_wire = build_cyl(params_wire)
    hstep, L = build_barrier(hSC, params_wire)
    gSC = hSC |> greenfunction(GS.Schur(boundary = 0))
    g = hstep |> attach(gSC; region = r -> r[1] == L) |> greenfunction()
    return g
end