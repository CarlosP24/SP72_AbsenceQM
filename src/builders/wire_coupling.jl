function build_coupling(params_wire::Params; τ = 1)
    @unpack ħ2ome, m0, preα, a0, Vmax, Vmin, Vexponent, α, R = params_wire

    t = ħ2ome/(2m0*a0^2)

    phop(r, dr) = -t * σ0τz * ifelse(iszero(dr[1]), r[2]/sqrt(r[2]^2 - 0.25*dr[2]^2), 1)
    
    dϕ(ρ, v0, v1) = - (Vexponent/R) * (v1 - v0) * (ρ/R)^(Vexponent - 1)
    rashbahop(r, dr, α, preα, Vmin, Vmax) = (α + preα * dϕ(r[2], Vmax, Vmin)) * (im * dr[1] / (2 * a0^2)) * σyτz

    return @hopping((r, dr; τ = τ, α = α, preα = preα, Vmin = Vmin, Vmax = Vmax) -> τ * phop(r, dr) + rashbahop(r, dr, α, preα, Vmin, Vmax); range = a0)
end